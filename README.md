# FastFile

**High-performance text file editor for large files — Delphi 7 / Win32**

> Version: `2.1.6.68`  
> Developer: Hamden Vogel  
> Copyright © 2025–2026. All rights reserved.

---

## Table of Contents

1. [Overview](#overview)
2. [Key design principles](#key-design-principles)
3. [Building the project](#building-the-project)
4. [Project structure](#project-structure)
5. [Core units reference](#core-units-reference)
6. [Threading model](#threading-model)
7. [File indexing and MMF](#file-indexing-and-mmf)
8. [Atomic write pattern](#atomic-write-pattern)
9. [Segmented heavy operations](#segmented-heavy-operations)
10. [Session history journal](#session-history-journal)
11. [Compare / Merge and diff engine](#compare--merge-and-diff-engine)
12. [Internationalization](#internationalization)
13. [Files on disk](#files-on-disk)
14. [INI configuration keys (ASkin.ini)](#ini-configuration-keys-askinini)
15. [Async log](#async-log)
16. [ConsumerAI integration](#consumerai-integration)
17. [Third-party libraries](#third-party-libraries)
18. [Global constants (UnConsts)](#global-constants-unconsts)

---

## Overview

FastFile is a **viewer and line editor** designed for very large plain-text files (tested above 14 GB on 32-bit Windows). It never loads the full file into memory: instead it builds a compact **line-offset index** (`temp.txt`) on first open and uses **Memory-Mapped File** windows for all subsequent reads. All heavy operations run in background threads and write atomically to a temporary file before replacing the original.

---

## Key design principles

| Principle | Implementation |
|-----------|---------------|
| **No full load** | Line index (`temp.txt`, 20 bytes/line) + `TMMFReader` sliding windows |
| **Atomic writes** | Temp file `ff_<tag>_<tick>_<tid>.tmp` → `RenameFile` |
| **Non-blocking UI** | All I/O on worker threads; progress via `Synchronize` / `PostMessage` |
| **Single instance** | `CreateFileMapping("MyACMap")` mutex in `FastFile.dpr` |
| **Segmented ops** | Optional chunked Replace All / batch delete (~250 k lines/segment) |
| **Undo / Redo** | `TUndoRecord` stack in `MainUnit` (op, line, old/new content) |
| **11-language i18n** | Runtime lookup tables in `uI18n`; language persisted in `ASkin.ini` |
| **Append-only journal** | Per-file edit history in `FastFileSessionHistory\*.log` |

---

## Building the project

- **IDE:** Delphi 7 (Win32, 32-bit)
- **Main project file:** `FastFile.dpr`
- **Output directory:** `Build\`
- **Required packages:** AlphaControls (`.bpl` / `.dcp` in `Bpl\` / `Dcp\`); MidasLib (linked statically, eliminates `midas.dll` dependency)
- **Third-party source:** `FastMM4-master\`, `FastCode.Libraries-0.6.4\` — must be present before compilation
- **Resources:** compiled via `files.rc` / `folders.rc` into `FastFile.res`

### Build steps

1. Open `FastFile.dpr` in Delphi 7.
2. Ensure `Bpl\` and `Dcp\` paths are in the library search path.
3. Compile. The output `FastFile.exe` goes to `Build\`.
4. On first run, the application self-extracts `ASkin.ini`, `Skins\`, `folders.xml`, `files.xml`, `texture.bmp`, and `logo.bmp` from embedded resources into the same folder as the exe.

---

## Project structure

```
Src\
├── FastFile.dpr          — Application entry point, single-instance mutex
├── UnConsts.pas          — All global constants (file names, version, limits)
├── MainUnit.pas          — Main form (frmMain): UI, menus, ListView, filter, undo/redo
├── UnDM.pas              — TDataModule1: TsSkinManager + TClientDataSet; resource extraction
├── UnUtils.pas           — General utilities: I/O, dialogs, extractResource, GetTmpDir
├── uSmoothLoading.pas    — Loading overlay form + ALL heavy-operation worker threads
├── uMMF.pas              — TMMFReader: Memory-Mapped File with sliding windows
├── uLineEditor.pas       — Modal dialog: single-line edit (insert/edit/delete/duplicate)
├── uDeltaEditor.pas      — Modal dialog: delta list editor for merge
├── uCompareMergeUI.pas   — Compare/Merge form + THistoryReloadThread
├── uLineDiffCore.pas     — LCS DP diff engine for two TStringList instances
├── uFileSessionHistory.pas — Append-only session journal per data file
├── uI18n.pas             — Internationalization (11 languages, runtime lookup)
├── uTextEncoding.pas     — UTF-8 / UTF-16 / ANSI helpers for Delphi 7 ANSI VCL
├── MruHelper.pas         — MRU popup component (persists to .ini)
├── ThreadFileLog.pas     — Async file logger via 1-thread pool
├── ThreadUtilities.pas   — Generic TThreadPool base
├── UnConsumerAI.pas      — ConsumerAI.exe launcher (non-freezing CreateProcess loop)
├── UnConsumerDialog.pas  — ConsumerAI UI panel
├── uExportDialog.pas     — Export dialog
├── uFindReplace.pas      — Find & Replace dialog
├── UnFormAboutFF.pas     — About / version history screen
├── UnSearch.pas          — Find-in-files form
├── unSplitView.pas       — Split view form
├── FolderMon.pas         — Directory watcher (ReadDirectoryChangesW)
├── StopWatch.pas         — High-resolution timer (QueryPerformanceCounter)
├── DSiWin32.pas          — Win32 utility library (third-party)
├── FastMM4-master\       — FastMM4 memory manager
├── FastCode.Libraries-*\ — FastCode RTL replacements
├── Build\                — Compiled output (exe, ini, xml, bitmaps, Skins\)
├── RegressionTests\      — Regression test suite
└── ARQUITETURA_TECNICA_FASTFILE.md — Full technical architecture document
```

---

## Core units reference

### `MainUnit.pas`

Main form `frmMain`. Responsibilities:

- **`TListView` (OwnerData / virtual mode):** items fetched on demand via `OnData` → index lookup in `temp.txt` → `TMMFReader` → `uTextEncoding` decode.
- **`TPageControl`:** tab 0 = Read File, tab 1 = Split File, tab 2 = Exported Lines.
- **Filter (`TFilterMatchMode`):** `fmmContains`, `fmmPrefix`, `fmmRegex`. A bitset over all indexed lines marks which lines pass; `TFilterThread` builds it (Int64 arithmetic to stay within 32-bit limits).
- **Tail/Follow:** timer detects file growth → `TailAppendNewLines` reads delta in 64 MiB chunks to append index records without full re-read.
- **Undo/Redo:** `TUndoRecord` stack (`Op: Integer`, `Line: Int64`, `OldContent/NewContent: String`).
- **`chkSegmentedHeavyOps`:** persists to `ASkin.ini → SegmentHeavyOps`; syncs popup/menu on change.

### `uSmoothLoading.pas`

Central hub for all async operations. Contains:

- `TfrmSmoothLoadingForm` — animated semi-transparent overlay (`TPaintBox` progress bar, fade-in, `WM_APP+77`).
- `TfrmSmoothLoading` — orchestrator thread that creates the correct worker.
- All worker thread classes (see [Threading model](#threading-model)).

### `uMMF.pas` — `TMMFReader`

```
CreateFile(GENERIC_READ, FILE_SHARE_READ|WRITE)
→ CreateFileMapping(PAGE_READONLY)
→ MapViewOfFile(FILE_MAP_READ, aligned offset)
```

`EnsureView(AbsOffset, MinBytes)` remaps the window when the requested offset falls outside the current view, always aligning the mapping offset to `SYSTEM_INFO.dwAllocationGranularity` (typically 64 KB).  
`PtrAt` returns a direct pointer + `Contiguous` byte count.  
`ReadBytes` copies safely across window boundaries.

### `uFileSessionHistory.pas`

Append-only journal, one file per data file opened. Thread-safe via `GFFHistLock: TCriticalSection`.

- **Path:** `<exe>\FastFileSessionHistory\ffhist_<FNV1a-32>_<basename>.log`
- **FNV-1a 32-bit hash** over the lowercased absolute path (collision-resistant naming).
- **Record format:** `<timestamp>|<op>|<line>|<old_excerpt>|<new_excerpt>` (pipes inside fields replaced with space).

### `uLineDiffCore.pas`

`FFBuildLineDiffRows(Left, Right, AMaxDim, ADiff)`:

- Trims matching **prefix** and **suffix** lines in O(n) before entering DP.
- Bounded LCS DP matrix (`AMaxDim × AMaxDim`).
- Output: list of `PFFDiffRow` records with `TFFDiffKind` (`ffdkEqual`, `ffdkDelete`, `ffdkInsert`, `ffdkChange`).

---

## Threading model

All worker threads follow the same lifecycle: show overlay → do work → atomic rename → reload index → hide overlay.

| Thread | Operation | Temp file tag |
|--------|-----------|--------------|
| `TReadFileThread` | Index file, populate ListView | writes `temp.txt` directly |
| `TEditFileThread` | Insert / Edit / Delete / Duplicate line | `edit` |
| `TMergeDeltaThread` | Apply `.delta` patch to source file | `mrgd` + `temp_merge.txt` |
| `TReplaceAllThread` | Global replace (normal or segmented) | `rall` / `rseg` |
| `TExportFileThread` | Export selected lines to file or clipboard | `exp` |
| `TSplitFileThread` | Split file by line ranges | direct output files |
| `TSplitEqualPartsThread` | Split file into N equal-size parts (LF-aligned) | direct output files |
| `TMergeFilesThread` | Merge two files at byte offset or line range | `mrg` |
| `THistoryReloadThread` | Reload session journal for Compare/Merge UI | — |

### Temp file naming

```pascal
'ff_' + Tag + '_' + IntToStr(GetTickCount) + '_' + IntToStr(GetCurrentThreadId) + '.tmp'
```

Created in `ExtractFilePath(ParamStr(0))` (exe folder).

### Thread → UI communication

- **`Synchronize`:** progress updates for short operations.
- **`PostMessage(WM_APP+77)`** and **`PostMessage(WM_FF_HIST_PROGRESS_FLUSH)`:** coalesced progress for long operations (avoids flooding `Application.ProcessMessages`).
- **`MsgWaitForMultipleObjects(QS_ALLINPUT, 5 ms)`** + `Sleep(2 ms)`: yield inside worker loops to keep UI responsive without busy-wait.
- `SyncApply` in `THistoryReloadThread`: batches UI updates in slices of 12 items to prevent stall.

---

## File indexing and MMF

### Index record layout (`temp.txt`, `INDEX_RECORD_SIZE = 20` bytes)

| Offset | Size | Type | Content |
|--------|------|------|---------|
| 0 | 8 | Int64 | Byte offset of line start in source file |
| 8 | 8 | Int64 | Byte length of line |
| 16 | 4 | DWORD | Flags / reserved |

`TReadFileThread` scans the source file via `TMMFReader`, emitting one record per `#10` delimiter.

On `OnData` (ListView virtual mode): `LineIndex × 20` → seek in `temp.txt` → read record → `TMMFReader.ReadBytes(offset, length)` → `DisplayTextFromFileBytes(raw, encoding)` → display.

---

## Atomic write pattern

Used by every thread that modifies a file:

```
1. Open  ff_<tag>_<tick>_<tid>.tmp  for write  (OUT_BUFFER_SIZE = 64 KB buffer)
2. Read source via TMMFReader (does not lock the original)
3. Write transformed content to temp file
4. SUCCESS → RenameFile(tmp, original)   ← atomic on NTFS
5. FAILURE → DeleteFile(tmp)             ← original intact
6. Launch TReadFileThread to rebuild index
```

`UnBufferedTextWriter` provides the 64 KB buffered writer used in steps 1–3.

---

## Segmented heavy operations

Controlled by **`SegmentHeavyOps`** (`ASkin.ini`). Off by default. Activated via the **"Line-segmented processing for heavy operations"** checkbox in the main toolbar.

### Replace All — segmented mode (`TReplaceAllThread.TrySegmentedReplace`)

1. Reads `temp.txt` to get total line count.
2. Divides into segments of `FLinesPerSegment` lines (default **250,000**).
3. For each segment: creates an inner `TEditFileThread` (`FreeOnTerminate=False`) → writes `ff_rseg_<n>_*.tmp`.
4. Concatenates all segment temps into `ff_rall_*.tmp`.
5. Atomic rename → original file updated.
6. Cleans up segment temps.

Limit: `REPLACE_ALL_MATCH_LIMIT = 5,000,000` substitutions across the whole file (safety guard).

### Batch delete — segmented mode (`TrySegmentedBatchDelete`)

Same segmentation strategy: for each segment, writes only the **lines to keep** (inverse of selected), concatenates, atomic rename. Falls back to classic `DeleteFromStream` if index is missing or the file has only one segment.

---

## Session history journal

```
FastFileSessionHistory\
    ffhist_<FNV1a-32-hex>_<basename>.log
```

Each line in the log:

```
2026-04-25 14:30:00|EDT|42|old text excerpt|new text excerpt
```

Operations logged: `INS`, `EDT`, `DEL`, `RPLALL`.

Read back by `THistoryReloadThread` in `uCompareMergeUI`: scans the tail of the journal (256 KiB progress granularity), filters to the currently open file, colorizes entries by operation type, displays in `lvHistFile`.

---

## Compare / Merge and diff engine

`TfrmCompareMerge` (`uCompareMergeUI.pas`) has two tabs:

- **History tab:** `lvHistFile` (journal entries colored by INS/EDT/DEL/RPLALL) + `mmoJournal` (raw journal preview).
- **Diff tab:** two virtual `TListView` (`lvLeft` / `lvRight`) showing `TFFDiffRow` records. Sync-scroll via `tmrSync`. Context menus show "Apply left→right" / "Apply right→left" **only on changed lines** (`ffdkChange`, `ffdkInsert`, `ffdkDelete`).

Merging: `TEditFileThread.RunEditWait` is called per changed line. `TouchHistoryIfSameFile` triggers a ListView + journal reload if the edited file is the one open in the main form. `WM_SETREDRAW` prevents flickering during batch apply.

---

## Internationalization

`uI18n.pas` supports **11 languages** resolved at runtime:

```
en | pt-BR | pt-PT | es | fr | de | it | pl | ro | hu | cs
```

Two lookup tables per language (key-based and English-text-based), stored as sorted `TStringList` for O(log n) binary search (`FastIndexOfName`).

```pascal
Tr('key', 'Default text')   // explicit key lookup
TrText('Default text')      // English text as key (most common)
ApplyTranslationsToForm(AForm)  // iterates all components recursively
```

Language code stored in `ASkin.ini → Language` (e.g. `pt-BR`). Changed via Options menu → persisted immediately.

---

## Files on disk

All paths relative to `ExtractFilePath(Application.ExeName)` unless noted.

### Always present after first run

| File / Folder | Constant | Description |
|--------------|----------|-------------|
| `ASkin.ini` | `ASKIN_INI` | Main configuration (skin, language, window position, flags) |
| `Skins\` | `FOLDERSKIN` | AlphaControls skin theme files |
| `texture.bmp` | `TEXTURE` | Skin texture bitmap |
| `logo.bmp` | `LOGO` | Logo shown on loading overlay |
| `folders.xml` | `XMLFOLDERS` | TClientDataSet — folder data |
| `files.xml` | `XMLFILES` | TClientDataSet — file metadata |

### Created at runtime

| File | Constant | Description |
|------|----------|-------------|
| `temp.txt` | `TEMPFILE` | Line-offset index (20 bytes/line). Rebuilt on every file open. |
| `mru_files.ini` | — | Recent files list |
| `mru_location.ini` | — | MRU for the location field (25 items) |
| `mru_content.ini` | — | MRU for the search/content field (25 items) |
| `ff_*.tmp` | — | Atomic operation temporaries; cleaned up after each operation |
| `FastFileSessionHistory\ffhist_*.log` | — | Session edit journals (one per data file) |
| `Log_FastFile<ddmmyyyyhhnn>.txt` | — | Async error log (written by `LogAsync`) |
| `<name>.delta` | — | Delta patch file saved by the Delta Editor |
| `extensionFiles.txt` | — | Extension list for open-file dialogs |
| `ConsumerAI.exe` | `CONSUMERAI` | External AI process (Python, optional) |

---

## INI configuration keys (ASkin.ini)

Section: `[FastFile]`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `SkinDirectory` | String | `<exe>\Skins` | Path to AlphaControls skin folder |
| `SkinName` | String | `Notes Plastic` | Active theme name |
| `SkinActive` | 0 / 1 | `1` | Enable / disable skinning |
| `Top` | Integer | — | Main window Y position |
| `Left` | Integer | — | Main window X position |
| `Language` | String | `pt-BR` | Active language code |
| `SegmentHeavyOps` | 0 / 1 | `0` | Enable segmented Replace All and batch delete |

Read/written via `sStoreUtils.ReadIniInteger` / `WriteIniStr` (AlphaControls).

---

## Async log

`ThreadFileLog.pas` — `LogAsync(FileName, Text)`:

```
GlobalLogThread (TThreadFileLog, lazy init)
  └── TThreadPool (1 worker thread)
        └── HandleLogRequest → LogToFile (AssignFile / Append / Writeln / CloseFile)
```

Log file name pattern: `Log_FastFile<ddmmyyyyhhnn>.txt` (e.g. `Log_FastFile25042026_1430.txt`).  
Written to the current working directory (usually the exe folder).  
Called from `uMMF` on mapping errors and from thread exception handlers.

---

## ConsumerAI integration

`TConsumerAI` (`UnConsumerAI.pas`) launches `ConsumerAI.exe` via `CreateProcess` (`SW_HIDE`):

```
ConsumerAI.exe -file "<path>" -rp -prompt
```

`ExecuteWithoutFreezing` polls `GetExitCodeProcess` in a loop with `Application.ProcessMessages` + `Sleep(50)` to avoid UI freeze while waiting. Communication is entirely via command-line arguments and files on disk.

Own logs: `ConsumerAI_startup.log`, `ConsumerAI_LanceDB_startup.log` (written by the Python process).

---

## Third-party libraries

| Library | Location | Purpose |
|---------|----------|---------|
| **FastMM4** | `FastMM4-master\FastMM4.pas` | High-performance memory manager. Replaces the default Delphi allocator. `ReportMemoryLeaksOnShutdown=True` in DEBUG builds. |
| **FastCode** | `FastCode.Libraries-0.6.4\FastCode.pas` | Optimized RTL replacements (`Move`, `FillChar`, `Pos`, etc.). |
| **AlphaControls** | `Bpl\`, `Dcp\` | Visual component suite with runtime skinning (`TsSkinManager`, `sPanel`, `sListView`, `acTitleBar`, …). |
| **DSiWin32** | `DSiWin32.pas` | Win32 wrappers (processes, registry, services, events). |
| **MidasLib** | linked statically | Eliminates `midas.dll` dependency for `TClientDataSet`. |

---

## Global constants (UnConsts)

```pascal
APPLICATION_NAME              = 'FastFile'
APPLICATION_VERSION           = '2.1.6.68'
ASKIN_INI                     = 'ASkin.ini'
XMLFOLDERS                    = 'folders.xml'
XMLFILES                      = 'files.xml'
CONSUMERAI                    = 'ConsumerAI.exe'
TEXTURE                       = 'texture.bmp'
LOGO                          = 'logo.bmp'
FOLDERSKIN                    = 'Skins'
TEMPFILE                      = 'temp.txt'
CHUNKFILE                     = 'chunk.txt'
OUT_BUFFER_SIZE               = 65536        // 64 KB I/O buffer
INDEX_RECORD_SIZE             = 20           // bytes per record in temp.txt
SIZEPARTFILE                  = 25000000     // 25 MB default split part size
MAX_FILESIZE_MEMORY_LIMIT_BYTES = 15958207655 // ~14.86 GB safety ceiling
```

---

## See also

- [ARQUITETURA_TECNICA_FASTFILE.md](ARQUITETURA_TECNICA_FASTFILE.md) — full technical architecture document (PT-BR)
- [CHANGELOG_IMPLEMENTACOES.md](CHANGELOG_IMPLEMENTACOES.md) — implementation changelog (v2.1.6.x series)
- [ARQUIVOS_EXTERNOS_FASTFILE.md](ARQUIVOS_EXTERNOS_FASTFILE.md) — external files and resources reference
- [DOC_COMPARAR_MESCLAR_HISTORICO_PASSO_A_PASSO.md](DOC_COMPARAR_MESCLAR_HISTORICO_PASSO_A_PASSO.md) — Compare/Merge step-by-step guide
