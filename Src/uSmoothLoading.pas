unit uSmoothLoading;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, DateUtils, Math, ClipBrd, CommCtrl,
  uLineEditor, uMMF;

type
  TfrmSmoothLoadingForm = class(TForm)
    pnlContainer: TPanel;
    imgLogo: TImage;
    lblMessage: TLabel;
    lblDetail: TLabel;
    tmrAnimation: TTimer;
    pbProgressBar: TPaintBox;
    procedure tmrAnimationTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure pbProgressBarPaint(Sender: TObject);
  private
    FCurrentProgress: Double;
    FTargetProgress: Integer;
    FIsDeterminate: Boolean;
    FLastPaintedProgress: Double;
    FBackgroundBmp: TBitmap;
    // Fade-in suave ao exibir
    FFadeInActive: Boolean;
    FFadeStartTick: Cardinal;
    FFadeDurationMS: Cardinal;
    FFadeStartAlpha: Byte;
    FFadeEndAlpha: Byte;
    procedure BuildBackground;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure ApplySmoothProgress(Percent: Integer);
    procedure WMSmoothProgress(var Msg: TMessage); message WM_APP + 77;
    procedure CenterContainer;
    procedure RoundControl(Control: TWinControl; Radius: Integer);
    procedure LoadLogo;
    procedure ForceFullScreen; // Novo método para garantir o tamanho
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
      // Operações centralizadas (threads agora ficam nesta unit)
end;



type
  TSmoothLoadingMode = (slmReadFile, slmEditFile, slmExportLines);

  // Thread controladora: esta é a "TfrmSmoothLoading" solicitada
  TfrmSmoothLoading = class(TThread)
  private
    FMode: TSmoothLoadingMode;
    FFileName: String;
    FOp: TOperationType;
    FLineNum: Int64;
    FTxt: String;
    FParams: String;
    FSaveToFile: Boolean;
    FOutFileName: String;

    FMessageText: String;

    procedure SyncShow;
    procedure SyncHide;
  protected
    procedure Execute; override;
  public
    constructor Create; reintroduce;

    // API pública (mantém compatibilidade com o projeto)
    class procedure ShowLoading(const MessageText: String); overload;
    { AStayOnTop=False: overlay nao WS_EX_TOPMOST (Alt+Tab / outras apps menos "presas" durante carga longa). }
    class procedure ShowLoading(const MessageText: String; AStayOnTop: Boolean); overload;
    { AOwner=form modal (ex. compare/merge): overlay como filho logico do form evita bloqueio da fila de mensagens. }
    class procedure ShowLoading(AOwner: TComponent; const MessageText: String; AStayOnTop: Boolean = True); overload;
    class procedure HideLoading;
    class procedure UpdateProgress(Percent: Integer);
    { Chamada a partir de threads de trabalho: PostMessage (nao bloqueia a worker na UI).
      UpdateProgress usa SendMessage fora da main ? util para outras threads; esta API evita
      acumular Synchronize na fila do Application durante cargas longas (ex.: historico merge). }
    class procedure PostProgressFromWorker(Percent: Integer);
    class procedure UpdateProgressWithDetail(Percent: Integer; const Detail: string);
  end;

const
  //INFO_FILE_TIME = 'Filename: %s. Time to read: %s millisecs. Total lines: %d. Total Characters: %d';
  INFO_FILE_TIME = 'Time to read: %s millisecs. Total lines: %d.';
  INFO_EDIT_TIME = 'Time to execute that operation: %s millisecs.';

  OUT_BUFFER_SIZE   = 65536;
  INDEX_RECORD_SIZE = 20;

type
  TStopWatch = class
  private
    fFrequency : TLargeInteger;
    fStartCount, fStopCount : TLargeInteger;
    procedure SetTickStamp(var lInt : TLargeInteger);
    function  GetElapsedMilliseconds: TLargeInteger;
  public
    function    FormatMillisecondsToDateTime(const ms: integer): string;
    constructor Create(const startOnCreate : boolean = false);
    procedure   Start;
    procedure   Stop;
    property    ElapsedMilliseconds : TLargeInteger read GetElapsedMilliseconds;
  end;

type
  TReadFileThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    fileName: string;
    FTotalSize: Int64;
    FBytesRead: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    totalLines: Int64;
    totalCharacters: Int64;

    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    function TimerResult: string;
    procedure FinishThreadExecution;
    procedure SyncProgress;
  protected
    procedure Execute; override;
  public
    constructor Create(const CreateSuspended: Boolean; const AFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

  TDeltaEntry = record
    LineNumber: Int64;
    NewText: String;
  end;
  TDeltaArray = array of TDeltaEntry;

  TMergeDeltaThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    FFileName: String;
    FDeltaFileName: String;
    FTotalSize: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure FinishThread;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName, ADeltaFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

  TEditFileThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    FFileName: String;
    FOperation: TOperationType;
    FTargetLine: Int64;
    FContent: String;
    FOldLineText: String;
    FTotalSize: Int64;
    FBytesProcessed: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    { Ultimo progresso sincronizado em mil-esimos (0..1000); mais passos que % inteiro. }
    FLastProgressThousandths: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    FQuietFinish: Boolean;
      FIsRawContent: Boolean;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure FinishThread;    
  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName: String; const Op: TOperationType; const LineNum: Int64; const Txt: String;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True;
    const AFreeOnTerminate: Boolean = True; const AQuietFinish: Boolean = False; const AIsRawContent: Boolean = False);
    destructor Destroy; override;
    property EditSucceeded: Boolean read FSuccess;
    property EditErrorMsg: String read FErrorMsg;
    class function RunEditWait(const AFileName: String; const Op: TOperationType;
      const LineNum: Int64; const Txt: String; const AIsRawContent: Boolean = False): Boolean;
  end;

  TExportFileThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    FLineParams: String;
    FSaveToFile: Boolean;
    FOutputFileName: String;
    FSourceFileName: String;
    FTotalLines: Int64;
    FResultList: TStringList;
    FPercent: Integer;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncClipboard;
    procedure SyncFinish;
    function ParseLines(const Input: String): TList;

  protected
    procedure Execute; override;
  public
    constructor Create(const ALineParams: String; const ASaveToFile: Boolean; const AOutputFileName: String;
    const ASourceFileName: String; const ATotalLines: Int64;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

  TReplaceAllThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    FFileName: String;
    FFindText: String;
    FReplaceText: String;
    FCaseSensitive: Boolean;
    FWholeWord: Boolean;
    FTotalSize: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    FReplacedCount: Int64;
    FReplacedCountSync: Int64;
    FReplaceLimitHit: Boolean;
    FDetailSync: string;
    FSegmented: Boolean;
    FIndexFileName: string;
    FLinesPerSegment: Integer;
    FOutputOverride: string;
    FSilent: Boolean;
    function TrySegmentedReplace: Boolean;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure FinishThread;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName, AFindText, AReplaceText: String;
      const ACaseSensitive, AWholeWord: Boolean;
      const AutoHide: Boolean = True; const ShowUI: Boolean = True;
      const ASegmented: Boolean = False; const AIndexFileName: string = '';
      const ALinesPerSegment: Integer = 250000;
      const AOutputOverride: string = '';
      const ASilent: Boolean = False;
      const AFreeOnTerminate: Boolean = True);
    destructor Destroy; override;
    property ReplacedTotal: Int64 read FReplacedCountSync;
    property OperationSucceeded: Boolean read FSuccess;
    property LastErrorMsg: string read FErrorMsg;
  end;

  TSplitEntry = record
    ID: Integer;
    FileName: String;
    SourceLine: Int64;
    TargetLine: Int64;
  end;
  TSplitEntryArray = array of TSplitEntry;

  TSplitFileThread = class(TThread)
  private
    FShowLoadingUI: Boolean;
    FAutoHide: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    FOriginalFileName: String;
    FOutputDir: String;
    FEntries: TSplitEntryArray;
    FEntryCount: Integer;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTimerResult: String;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOriginalFileName: String; const AOutputDir: String; const AEntries: TSplitEntryArray; const AEntryCount: Integer);
    destructor Destroy; override;
  end;

  TMergeFilesThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FDestinationFileName: String;
    FSourceFileName: String;
    FInsertOffset: Int64;
    FFromLine: Int64;
    FToLine: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure FinishThread;
  protected
    procedure Execute; override;
  public
    constructor Create(const ADestinationFileName, ASourceFileName: String;
      const AInsertOffset: Int64; const AutoHide: Boolean = True;
      const ShowUI: Boolean = True; const AFromLine: Int64 = 0;
      const AToLine: Int64 = 0);
    destructor Destroy; override;
  end;

  { Divide arquivo em N partes com tamanho aproximadamente igual em bytes,
    ajustando limites para nunca cortar linhas (delimitador LF #10). }
  TSplitEqualPartsThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FSourceFileName: String;
    FPartCount: Integer;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FSuccessOutputDir: String;
    FSuccessFirstPath: String;
    FSuccessLastPath: String;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASourceFileName: String; const APartCount: Integer;
      const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

function PosBMH(const SubStr, S: string): Integer;

{ Line-aligned segments + merge + atomic rename. Returns False if index missing
  or a single segment (caller uses classic in-place deletes). Returns True with
  AErrorMsg set on handled failure or empty on success. }
function TrySegmentedBatchDelete(const FileName, IndexFileName: string;
  const LinesToDelete1Based: array of Int64; LinesPerSegment: Integer;
  out AErrorMsg: string): Boolean;

var
  frmSmoothLoading: TfrmSmoothLoadingForm;
  FastWordWrapAtivo: Boolean;
  FastWordWrapMaxChars: Integer;

implementation

{$R *.dfm}

uses
  MainUnit, UnBufferedTextWriter, ThreadFileLog, uI18n, UnUtils, uFileSessionHistory;

const
  REPLACE_ALL_MATCH_LIMIT = 5000000;
  { QS_ALLINPUT (WinUser): acordar MsgWait quando ha mensagens para Synchronize / pintura. }
  cQS_ALLINPUT_FOR_WAIT = $04FF;

function NewFastFileTemp(const Tag: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'ff_' + Tag + '_' + IntToStr(GetTickCount) + '_' + IntToStr(GetCurrentThreadId) + '.tmp';
end;

procedure ShowMessage(const Msg: string); overload;
begin
  Dialogs.ShowMessage(TrText(Msg));
end;

function MessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer; overload;
begin
  Result := Dialogs.MessageDlg(TrText(Msg), DlgType, Buttons, HelpCtx);
end;

{ ============================================================================ }
{ StopWatch }
{ ============================================================================ }

constructor TStopWatch.Create(const startOnCreate: boolean);
begin
  inherited Create;
  QueryPerformanceFrequency(fFrequency);
  if startOnCreate then Start;
end;

function TStopWatch.FormatMillisecondsToDateTime(const ms: integer): string;
var
  dt: TDateTime;
begin
  dt := ms / MSecsPerSec / SecsPerDay;
  Result := Format('%s', [FormatDateTime('hh:nn:ss.z', Frac(dt))]);
end;

function TStopWatch.GetElapsedMilliseconds: TLargeInteger;
begin
  Result := (MSecsPerSec * (fStopCount - fStartCount)) div fFrequency;
end;

procedure TStopWatch.SetTickStamp(var lInt: TLargeInteger);
begin
  QueryPerformanceCounter(lInt);
end;

procedure TStopWatch.Start;
begin
  SetTickStamp(fStartCount);
end;

procedure TStopWatch.Stop;
begin
  SetTickStamp(fStopCount);
end;

{ ============================================================================ }
{ TfrmSmoothLoading - operações públicas }
{ ============================================================================ }


{ ============================================================================ }
{ TfrmSmoothLoading (THREAD CONTROLADORA) }
{ ============================================================================ }

constructor TfrmSmoothLoading.Create;
begin
  inherited Create(True); // CreateSuspended = True
  FreeOnTerminate := True;
  Priority := tpNormal;
end;

procedure TfrmSmoothLoading.SyncShow;
begin
  // Reusa a API pública (mantém singleton do form)
  TfrmSmoothLoading.ShowLoading(FMessageText);
end;

procedure TfrmSmoothLoading.SyncHide;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TfrmSmoothLoading.Execute;
var
  Worker: TThread;
begin
  // Mostra overlay (VCL via main thread)
  Synchronize(SyncShow);

  Worker := nil;
  try
    case FMode of
      slmReadFile:
        Worker := TReadFileThread.Create(True, FFileName, False, true);
      slmEditFile:
        Worker := TEditFileThread.Create(FFileName, FOp, FLineNum, FTxt, False);
      slmExportLines:
        if Assigned(frmMain) then
          Worker := TExportFileThread.Create(FParams, FSaveToFile, FOutFileName,
            frmMain.edtFileName.Text, frmMain.IndexFileLineCount, False);
    end;

    if Assigned(Worker) then
    begin
      Worker.FreeOnTerminate := False;
      Worker.Resume;
      Worker.WaitFor;
      Worker.Free;
    end;
  finally
    // Fecha overlay (VCL via main thread)
    Synchronize(SyncHide);
  end;
end;

{ ============================================================================ }
{ THREAD 1: LEITURA }
{ ============================================================================ }

constructor TReadFileThread.Create(const CreateSuspended: Boolean; const AFileName: String; const AutoHide: Boolean; const ShowUI: Boolean);
begin
  inherited Create(CreateSuspended);
  FWordWrap := FastWordWrapAtivo;
  FMaxChars := FastWordWrapMaxChars;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FreeOnTerminate := True;
  fileName := AFileName;

  if FShowLoadingUI then
  begin
    FLoadingMsg := 'Reading file...';
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;

  sw := TStopWatch.Create;
  sw.Start;
end;

destructor TReadFileThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TReadFileThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TReadFileThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TReadFileThread.SyncSetProgress;
begin
  TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TReadFileThread.SyncProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FPercentToSync);
end;

procedure TReadFileThread.Execute;
function ForceDeleteFile(const FileName: string): Boolean;
var
  RetryCount: Integer;
begin
  Result := False;
  if not FileExists(FileName) then
  begin
    Result := True;
    Exit;
  end;
  for RetryCount := 1 to 5 do
  begin
    if DeleteFile(FileName) then
    begin
      Result := True;
      Break;
    end;
    Sleep(200);
  end;
  if not Result then
    Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');
end;
var
  MMF: TMMFReader;
  P: PByte;
  Contiguous: Cardinal;
  AbsOffset: Int64;
  i: Integer;
  IndexWriter: TBufferedTextWriter;
  IndexFileName: string;
  NewPercent: Integer;
begin
  inherited;
  totalLines := 0;
  totalCharacters := 0;
  FBytesRead := 0;
  FCurrentPercent := 0;
  IndexFileName := ExtractFilePath(ParamStr(0)) + 'temp.txt';

  MMF := nil;
  IndexWriter := nil;
  try
    if Assigned(frmMain) then
      Synchronize(frmMain.CloseFileStreams);

    ForceDeleteFile(IndexFileName);

    MMF := TMMFReader.Create(fileName);
    FTotalSize := MMF.FileSize;
    IndexWriter := TBufferedTextWriter.Create(IndexFileName, 8 * 1024 * 1024);

    if FTotalSize > 0 then IndexWriter.WriteOffsetDirect(1);

    AbsOffset := 0;
    while (AbsOffset < FTotalSize) and (not Terminated) do
    begin
      P := MMF.PtrAt(AbsOffset, 1, Contiguous);
      if (P = nil) or (Contiguous = 0) then Break;  
      
      if FastWordWrapAtivo and (FastWordWrapMaxChars > 10) then
      begin
        for i := 0 to Contiguous - 1 do
        begin
          if PAnsiChar(P)^ = #10 then
          begin
            Inc(totalLines);
            IndexWriter.WriteOffsetDirect(AbsOffset + i + 2);
            CharCount := 0;
            
            // Progress Bar Restore
            if (totalLines and $7FF = 0) then 
            begin
              NewPercent := Round(((AbsOffset + i) * 100) / FTotalSize);
              if NewPercent > FCurrentPercent then
              begin
                FCurrentPercent := NewPercent; FPercentToSync := FCurrentPercent;
                Synchronize(SyncProgress); 
              end;
            end;
          end
          else if CharCount >= FastWordWrapMaxChars then
          begin
            Inc(totalLines);
            // SINAL DE CONTINUACAO (Offset Negativo para ListView1Data ler depois!)
            IndexWriter.WriteOffsetDirect( - (AbsOffset + i + 1) );
            CharCount := 0;
          end
          else 
            Inc(CharCount);
          Inc(P);
        end;
      end
      else
      begin
        for i := 0 to Contiguous - 1 do
        begin
          if PAnsiChar(P)^ = #10 then
          begin
            Inc(totalLines);
            IndexWriter.WriteOffsetDirect(AbsOffset + i + 2);
            
            // Progress Bar Restore
            if (totalLines and $7FF = 0) then 
            begin
              NewPercent := Round(((AbsOffset + i) * 100) / FTotalSize);
              if NewPercent > FCurrentPercent then
              begin
                FCurrentPercent := NewPercent; FPercentToSync := FCurrentPercent;
                Synchronize(SyncProgress); 
              end;
            end;
          end;
          Inc(P);
        end;
      end;

      AbsOffset := AbsOffset + Contiguous;
    end;
  finally
    if Assigned(IndexWriter) then FreeAndNil(IndexWriter);
    if Assigned(MMF) then FreeAndNil(MMF);
    Synchronize(Self.FinishThreadExecution);
  end;
end;

procedure TReadFileThread.FinishThreadExecution;
var
  ActualLineCount: Int64;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    Synchronize(SyncHideLoading);
  if FTotalSize > 0 then
    ActualLineCount := totalLines + 1
  else
    ActualLineCount := 0;
  if Assigned(frmMain) then
    frmMain.finishFileNameRead(Format(INFO_FILE_TIME, [TimerResult, ActualLineCount]), ActualLineCount, totalCharacters);
end;

function TReadFileThread.TimerResult: string;
begin
  Result := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
end;

{ ============================================================================ }
{ THREAD 2: EDIÇÃO }
{ ============================================================================ }

constructor TEditFileThread.Create(const AFileName: String; const Op: TOperationType; const LineNum: Int64; const Txt: String;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True;
    const AFreeOnTerminate: Boolean = True; const AQuietFinish: Boolean = False; const AIsRawContent: Boolean = False);
begin
  inherited Create(True);
  FreeOnTerminate := AFreeOnTerminate;
  FFileName := AFileName;
  FOperation := Op;
  FTargetLine := LineNum;
  FContent := Txt;
  FOldLineText := '';
  FQuietFinish := AQuietFinish;
  FIsRawContent := AIsRawContent;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    case FOperation of
      otInsert: FLoadingMsg := 'Editing file (insert)...';
      otReplace: FLoadingMsg := 'Editing file (replace)...';
      otDelete: FLoadingMsg := 'Editing file (delete)...';
    else
      FLoadingMsg := 'Editing file...';
    end;
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TEditFileThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TEditFileThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TEditFileThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TEditFileThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TEditFileThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TEditFileThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  ShowMessage('Error: ' + FErrorMsg);
end;

procedure TEditFileThread.FinishThread;
var
  TimeStr: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    if (Trim(FFileName) <> '') and FileExists(FFileName) then
    begin
      case FOperation of
        otInsert:
          FFHistoryAppendLineOp(FFileName, 'INS', FTargetLine, '', FContent);
        otDelete:
          FFHistoryAppendLineOp(FFileName, 'DEL', FTargetLine, FOldLineText, '');
        otEdit, otReplace:
          FFHistoryAppendLineOp(FFileName, 'EDT', FTargetLine, FOldLineText, FContent);
      end;
    end;
    if not FQuietFinish then
    begin
      TimeStr := Format(INFO_EDIT_TIME, [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
      if Assigned(frmMain) then
      begin
        frmMain.mmTimer.Lines.Add(TimeStr);
        //Recarrega o arquivo após editar, para atualizar os dados
        frmMain.RefreshFile;
      end;
    end;
  end
  else
  begin
    if not FQuietFinish then
    begin
      if FErrorMsg <> '' then
        ShowMessage('Error: ' + FErrorMsg)
      else
        ShowMessage('Operation failed or cancelled.');
    end;
  end;
end;

class function TEditFileThread.RunEditWait(const AFileName: String; const Op: TOperationType;
  const LineNum: Int64; const Txt: String; const AIsRawContent: Boolean = False): Boolean;
var
  Th: TEditFileThread;
  H: THandle;
  wr: DWORD;
  ha: array[0..0] of THandle;
  bWaitAll: LongBool;
begin
  Th := TEditFileThread.Create(AFileName, Op, LineNum, Txt, True, False, False, True, AIsRawContent);
  try
    { MsgWaitForMultipleObjects(1,...): MsgWaitForSingleObject nao e' export em todas as user32 (macro C). }
    H := 0;
    bWaitAll := False;
    while True do
    begin
      if H = 0 then
        H := Th.Handle;
      if H <> 0 then
      begin
        ha[0] := H;
        wr := MsgWaitForMultipleObjects(1, ha, bWaitAll, 80, cQS_ALLINPUT_FOR_WAIT);
        if wr = WAIT_OBJECT_0 then
          Break;
        if wr = WAIT_FAILED then
        begin
          wr := WaitForSingleObject(H, 0);
          if wr = WAIT_OBJECT_0 then
            Break;
        end;
      end;
      Application.ProcessMessages;
      { Delphi 7: ProcessMessages nao despacha TThread.Synchronize; FinishThread e'
        enfileirado aqui ? esgotar a fila (varios Synchronize seguidos). }
      while CheckSynchronize do;
      if H = 0 then
        Sleep(2);
    end;
    Result := Th.EditSucceeded;
  finally
    Th.Free;
  end;
end;

procedure TEditFileThread.Execute;
function ForceDeleteFile(const FileName: string): Boolean;
var RetryCount: Integer;
begin
  Result := False;
  if not FileExists(FileName) then begin Result := True; Exit; end;
  for RetryCount := 1 to 5 do begin
    if DeleteFile(FileName) then begin Result := True; Break; end;
    Sleep(200);
  end;
  if not Result then
    Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');
end;
var
  MMF: TMMFReader;
  DestWriter: TBufferedTextWriter;
  P, PLineStart: PAnsiChar;
  Contiguous: Cardinal;
  AbsOffset: Int64;
  CurrentLine: Int64;
  NewPercent: Integer;
  NewTh: Integer;
  ThScaled: Int64;
  i, LineLen: Integer;
  FinalErr: string;
  RawOld: string;
begin
  inherited;
  if Assigned(frmMain) then
    Synchronize(frmMain.CloseFileStreams);
  FTempFileName := NewFastFileTemp('edit');
  ForceDeleteFile(FTempFileName);

  MMF := nil;
  DestWriter := nil;
  try
    try
    MMF := TMMFReader.Create(FFileName);
    FTotalSize := MMF.FileSize;
    if not VolumeHasMinFreeBytes(FFileName, FTotalSize + 64 * 1024 * 1024) then
    begin
      FErrorMsg := TrText('Not enough free disk space to complete this operation safely.');
      raise Exception.Create(FErrorMsg);
    end;
    DestWriter := TBufferedTextWriter.Create(FTempFileName, 16 * 1024 * 1024);
    CurrentLine := 1;
    AbsOffset := 0;
    FCurrentPercent := 0;
    FLastProgressThousandths := -100;

    while (AbsOffset < FTotalSize) and (not Terminated) do
    begin
      P := PAnsiChar(MMF.PtrAt(AbsOffset, 1, Contiguous));
      if (P = nil) or (Contiguous = 0) then Break;

      PLineStart := P;

      for i := 0 to Contiguous - 1 do
      begin
        if P^ = #10 then
        begin
          LineLen := (P - PLineStart) + 1;

          if (CurrentLine = FTargetLine) then
          begin
            case FOperation of
              otInsert: begin
                if FIsRawContent then DestWriter.WriteLine(string(FContent)) else DestWriter.WriteLine(AnsiToUTF8(string(FContent)));
                DestWriter.WriteRaw(PLineStart, LineLen);
              end;
              otEdit, otReplace: begin
                SetLength(RawOld, LineLen);
                if LineLen > 0 then
                  Move(PLineStart^, RawOld[1], LineLen);
                FOldLineText := string(RawOld);
                while (Length(FOldLineText) > 0) and
                  (FOldLineText[Length(FOldLineText)] in [#10, #13]) do
                  SetLength(FOldLineText, Length(FOldLineText) - 1);
                if FIsRawContent then DestWriter.WriteLine(string(FContent)) else DestWriter.WriteLine(AnsiToUTF8(string(FContent)));
              end;
              otDelete: begin
                SetLength(RawOld, LineLen);
                if LineLen > 0 then
                  Move(PLineStart^, RawOld[1], LineLen);
                FOldLineText := string(RawOld);
                while (Length(FOldLineText) > 0) and
                  (FOldLineText[Length(FOldLineText)] in [#10, #13]) do
                  SetLength(FOldLineText, Length(FOldLineText) - 1);
              end;
            end;
          end
          else
            DestWriter.WriteRaw(PLineStart, LineLen);

          Inc(CurrentLine);
          PLineStart := P + 1;
        end;
        Inc(P);
      end;

      AbsOffset := AbsOffset + Contiguous;

      if FTotalSize > 0 then
      begin
        ThScaled := (AbsOffset * 1000) div FTotalSize;
        if ThScaled > 1000 then ThScaled := 1000;
        NewTh := Integer(ThScaled);
        { ~0,4% de ficheiro por passo: mais suave que saltos de 1% em ficheiros grandes. }
        if (NewTh >= FLastProgressThousandths + 4) or (NewTh >= 1000) then
        begin
          FLastProgressThousandths := NewTh;
          NewPercent := NewTh div 10;
          if NewPercent > 100 then NewPercent := 100;
          FCurrentPercent := NewPercent;
          FPercentToSync := FCurrentPercent;
          if FShowLoadingUI then
            Synchronize(SyncProgress)
          else if Assigned(frmSmoothLoading) then
            { Merge/RunEditWait na main: evita Synchronize + fila; PostMessage nao bloqueia a worker. }
            TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
        end;
      end;
    end;

    FreeAndNil(DestWriter);
    FreeAndNil(MMF);

    FSuccess := TryRenameTempOverTarget(FTempFileName, FFileName, FinalErr);
    if not FSuccess then
      FErrorMsg := FinalErr;

  except
    on E: Exception do begin
      FErrorMsg := E.Message;
      LogAsync(Format('Log_FastFile%s.txt', [FormatDateTime('ddmmyyyyhhnn', Now)]), '[EditFileThread] ' + E.Message);
      if Assigned(MMF) then MMF.Free;
      if Assigned(DestWriter) then DestWriter.Free;
    end;
  end;
  finally
    if (FTempFileName <> '') and FileExists(FTempFileName) then
      ForceDeleteFile(FTempFileName);
  end;
  Synchronize(FinishThread);
end;

{ ============================================================================ }
{ TMergeDeltaThread: MERGE MULTIPLE LINES (DELTA) }
{ ============================================================================ }

constructor TMergeDeltaThread.Create(const AFileName, ADeltaFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FFileName := AFileName;
  FDeltaFileName := ADeltaFileName;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    FLoadingMsg := 'Merging ...';
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

procedure TMergeDeltaThread.Execute;
function ForceDeleteFile(const FileName: string): Boolean;
var
  DelName: string;
  Retry: Integer;
begin
  Result := False;
  if not FileExists(FileName) then begin Result := True; Exit; end;
  DelName := FileName + '.' + FormatDateTime('hhmmss', Now) + '.del';

  for Retry := 1 to 20 do
  begin
    if RenameFile(FileName, DelName) then
    begin
      DeleteFile(DelName);
      Result := True;
      Break;
    end
    else if DeleteFile(FileName) then
    begin
      Result := True;
      Break;
    end;
    Sleep(500);
  end;
end;

var
  MMF: TMMFReader;
  DestWriter: TBufferedTextWriter;
  P, PLineStart: PAnsiChar;
  Contiguous: Cardinal;
  AbsOffset: Int64;
  CurrentLine: Int64;
  NewPercent: Integer;
  i, LineLen: Integer;
  DeltaLines: TStringList;
  DeltaArr: TDeltaArray;
  DeltaCount, dIndex: Integer;
  ColonPos: Integer;
  sLine: String;
  LineNum: Int64;
  LineText: String;
begin
  inherited;
  if Assigned(frmMain) then
    Synchronize(frmMain.CloseFileStreams);
  FTempFileName := NewFastFileTemp('merge');
  ForceDeleteFile(FTempFileName);

  DeltaLines := TStringList.Create;
  DeltaCount := 0;
  SetLength(DeltaArr, 0);
  try
    if FileExists(FDeltaFileName) then
    begin
      DeltaLines.LoadFromFile(FDeltaFileName);
      SetLength(DeltaArr, DeltaLines.Count);
      for i := 0 to DeltaLines.Count - 1 do
      begin
        sLine := Trim(DeltaLines[i]);
        if sLine = '' then Continue;

        ColonPos := PosBMH(':', sLine);
        if ColonPos > 0 then
        begin
          LineNum := StrToInt64Def(Trim(Copy(sLine, 1, ColonPos - 1)), -1);
          if LineNum > 0 then
          begin
            LineText := Copy(sLine, ColonPos + 1, Length(sLine));
            if (Length(LineText) > 0) and (LineText[1] = ' ') then
              LineText := Copy(LineText, 2, Length(LineText));

            DeltaArr[DeltaCount].LineNumber := LineNum;
            DeltaArr[DeltaCount].NewText := LineText;
            Inc(DeltaCount);
          end;
        end;
      end;
      SetLength(DeltaArr, DeltaCount);
      for i := 0 to DeltaCount - 2 do
      begin
        for dIndex := i + 1 to DeltaCount - 1 do
        begin
          if DeltaArr[i].LineNumber > DeltaArr[dIndex].LineNumber then
          begin
            LineNum := DeltaArr[i].LineNumber;
            LineText := DeltaArr[i].NewText;
            DeltaArr[i] := DeltaArr[dIndex];
            DeltaArr[dIndex].LineNumber := LineNum;
            DeltaArr[dIndex].NewText := LineText;
          end;
        end;
      end;
    end
    else
    begin
      FErrorMsg := 'Delta file not found: ' + FDeltaFileName;
      FSuccess := False;
      Synchronize(SyncError);
      Exit;
    end;
  finally
    FreeAndNil(DeltaLines);
  end;

  MMF := nil;
  DestWriter := nil;
  MMF := TMMFReader.Create(FFileName);
  DestWriter := TBufferedTextWriter.Create(FTempFileName, 16 * 1024 * 1024);
  try
    try
      FTotalSize := MMF.FileSize;
      if not VolumeHasMinFreeBytes(FFileName, FTotalSize + 64 * 1024 * 1024) then
        raise Exception.Create(TrText('Not enough free disk space to complete this operation safely.'));
      CurrentLine := 1;
      AbsOffset := 0;
      FCurrentPercent := 0;
      dIndex := 0;

      while (AbsOffset < FTotalSize) and (not Terminated) do
      begin
        P := PAnsiChar(MMF.PtrAt(AbsOffset, 1, Contiguous));
        if (P = nil) or (Contiguous = 0) then Break;

        PLineStart := P;

        for i := 0 to Contiguous - 1 do
        begin
          if P^ = #10 then
          begin
            LineLen := (P - PLineStart) + 1;

            if (dIndex < DeltaCount) and (CurrentLine = DeltaArr[dIndex].LineNumber) then
            begin
              DestWriter.WriteLine(AnsiToUtf8(DeltaArr[dIndex].NewText));
              Inc(dIndex);
            end
            else
              DestWriter.WriteRaw(PLineStart, LineLen);

            Inc(CurrentLine);
            PLineStart := P + 1;
          end;
          Inc(P);
        end;

        AbsOffset := AbsOffset + Contiguous;

        if FTotalSize > 0 then
        begin
          NewPercent := Round((AbsOffset * 100) / FTotalSize);
          if NewPercent > FCurrentPercent then
          begin
            FCurrentPercent := NewPercent;
            FPercentToSync := FCurrentPercent;
            Synchronize(SyncProgress);
          end;
        end;
      end;

      while dIndex < DeltaCount do
      begin
        while CurrentLine < DeltaArr[dIndex].LineNumber do
        begin
          DestWriter.WriteLine('');
          Inc(CurrentLine);
        end;
        DestWriter.WriteLine(AnsiToUtf8(DeltaArr[dIndex].NewText));
        Inc(CurrentLine);
        Inc(dIndex);
      end;

      FreeAndNil(DestWriter);
      FreeAndNil(MMF);

      if not TryRenameTempOverTarget(FTempFileName, FFileName, FErrorMsg) then
        raise Exception.Create(FErrorMsg);

      FSuccess := True;
    except
      on E: Exception do
      begin
        FErrorMsg := E.Message;
        LogAsync(Format('Log_FastFile%s.txt', [FormatDateTime('ddmmyyyyhhnn', Now)]), '[MergeDeltaThread] ' + E.Message);
        if Assigned(MMF) then FreeAndNil(MMF);
        if Assigned(DestWriter) then FreeAndNil(DestWriter);
        Synchronize(SyncError);
      end;
    end;
  finally
    FreeAndNil(DestWriter);
    FreeAndNil(MMF);
    if (FTempFileName <> '') and FileExists(FTempFileName) then
      ForceDeleteFile(FTempFileName);
  end;
  Synchronize(FinishThread);
end;

destructor TMergeDeltaThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TMergeDeltaThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TMergeDeltaThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TMergeDeltaThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TMergeDeltaThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TMergeDeltaThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  ShowMessage('Merge Error: ' + FErrorMsg);
end;

procedure TMergeDeltaThread.FinishThread;
var
  TimeStr: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    TimeStr := Format('Merge completed in: %s millisecs.', [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
    if Assigned(frmMain) then
    begin
      frmMain.mmTimer.Lines.Add(TimeStr);
      frmMain.RefreshFile;
    end;
  end;
end;

function SortDeltaLines(Item1, Item2: Pointer): Integer;
var
  L1: Int64;
  L2: Int64;
begin
  L1 := TDeltaEntry(Item1^).LineNumber;
  L2 := TDeltaEntry(Item2^).LineNumber;
  if L1 < L2 then Result := -1
  else if L1 > L2 then Result := 1
  else Result := 0;
end;

{ ============================================================================ }
{ THREAD 3: EXPORTAÇÃO }
{ ============================================================================ }

constructor TExportFileThread.Create(const ALineParams: String; const ASaveToFile: Boolean; const AOutputFileName: String;
    const ASourceFileName: String; const ATotalLines: Int64;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True);
begin
  inherited Create(False);
  FAutoHide := AutoHide;
  FreeOnTerminate := True;
  FLineParams := ALineParams;
  FSaveToFile := ASaveToFile;
  FOutputFileName := AOutputFileName;
  FSourceFileName := ASourceFileName;
  FTotalLines := ATotalLines;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    if FSaveToFile then
      FLoadingMsg := 'Exporting lines to file...'
    else
      FLoadingMsg := 'Exporting lines...';
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FResultList := TStringList.Create;
end;

destructor TExportFileThread.Destroy;
begin
  FResultList.Free;
  inherited;
end;

procedure TExportFileThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TExportFileThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TExportFileThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TExportFileThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercent;
  SyncSetProgress;
end;

procedure TExportFileThread.SyncClipboard;
begin                                                         
  Clipboard.AsText := FResultList.Text;
end;

procedure TExportFileThread.SyncFinish;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  if FSaveToFile then
    ShowMessage('Export finished! File saved to: ' + FOutputFileName)
  else
    ShowMessage('Export finished! Lines copied to clipboard.');
end;

function TExportFileThread.ParseLines(const Input: String): TList;
var
  S: String;
  i, j: Integer;
  Parts, Range: TStringList;
  V1, V2: Int64;
begin
  Result := TList.Create;
  Parts := TStringList.Create;
  Range := TStringList.Create;
  try
    S := StringReplace(Input, ' ', '', [rfReplaceAll]);
    S := StringReplace(S, ';', ',', [rfReplaceAll]);
    Parts.Delimiter := ',';
    Parts.DelimitedText := S;

    for i := 0 to Parts.Count - 1 do
    begin
      if PosBMH('-', Parts[i]) > 0 then
      begin
        Range.Delimiter := '-';
        Range.DelimitedText := Parts[i];
        if Range.Count = 2 then
        begin
          V1 := StrToInt64Def(Range[0], 0);
          V2 := StrToInt64Def(Range[1], 0);
          for j := Min(V1, V2) to Max(V1, V2) do
            if j > 0 then Result.Add(Pointer(j));
        end;
      end
      else if Trim(Parts[i]) <> '' then
        Result.Add(Pointer(StrToInt64Def(Parts[i], 0)));
    end;
  finally
    Parts.Free;
    Range.Free;
  end;
end;

procedure TExportFileThread.Execute;
const
  INDEX_REC_SIZE = 20;
  MAX_LINE_LEN = 2 * 1024 * 1024;
var
  TargetLines: TList;
  i: Integer;
  LineNum: Int64;
  DestWriter: TBufferedTextWriter;
  MMF: TMMFReader;
  IdxStream: TFileStream;
  IndexFileName: String;
  OffsetStr: AnsiString;
  StartOffset, EndOffset, ReadPos: Int64;
  FSize: Int64;
  LineLength: Integer;
  Buffer: AnsiString;
  P: PByte;
  Contiguous: Cardinal;
begin
  TargetLines := ParseLines(FLineParams);
  DestWriter := nil;
  MMF := nil;
  IdxStream := nil;
  IndexFileName := ExtractFilePath(ParamStr(0)) + 'temp.txt';
  try
    try
      MMF := TMMFReader.Create(FSourceFileName);
      IdxStream := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);
      FSize := MMF.FileSize;
      SetLength(OffsetStr, 18);

      if FSaveToFile then
        DestWriter := TBufferedTextWriter.Create(FOutputFileName, 4 * 1024 * 1024);

      for i := 0 to TargetLines.Count - 1 do
      begin
        if Terminated then Break;
        LineNum := Int64(TargetLines[i]);
        if (LineNum < 1) or (LineNum > FTotalLines) then Continue;

        IdxStream.Seek(Int64(LineNum - 1) * INDEX_REC_SIZE, soFromBeginning);
        IdxStream.Read(Pointer(OffsetStr)^, 18);
        StartOffset := StrToInt64Def(Trim(string(OffsetStr)), -1);
        if StartOffset = -1 then
        begin
          if FSaveToFile then
            DestWriter.WriteLine('')
          else
            FResultList.Add('');
          Continue;
        end;
        StartOffset := Abs(StartOffset);

        if (Int64(LineNum) * INDEX_REC_SIZE) < IdxStream.Size then
        begin
          IdxStream.Seek(Int64(LineNum) * INDEX_REC_SIZE, soFromBeginning);
          IdxStream.Read(Pointer(OffsetStr)^, 18);
          EndOffset := StrToInt64Def(Trim(string(OffsetStr)), FSize + 1);
        end
        else
          EndOffset := FSize + 1;
        EndOffset := Abs(EndOffset);

        LineLength := EndOffset - StartOffset;
        if LineLength <= 0 then
        begin
          if FSaveToFile then
            DestWriter.WriteLine('')
          else
            FResultList.Add('');
          Continue;
        end;
        if LineLength > MAX_LINE_LEN then LineLength := MAX_LINE_LEN;

        ReadPos := StartOffset - 1;
        SetLength(Buffer, LineLength);
        P := MMF.PtrAt(ReadPos, LineLength, Contiguous);
        if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then
          Move(P^, Pointer(Buffer)^, LineLength)
        else
          MMF.ReadBytes(ReadPos, Pointer(Buffer)^, LineLength);

        while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do
          SetLength(Buffer, Length(Buffer) - 1);

        if FSaveToFile then
          DestWriter.WriteLine(Buffer)
        else
          FResultList.Add(string(Buffer));

        if TargetLines.Count > 0 then
          FPercent := Round(((i + 1) / TargetLines.Count) * 100)
        else
          FPercent := 100;
        Synchronize(SyncProgress);
      end;

      if (not FSaveToFile) then
        Synchronize(SyncClipboard);

      Synchronize(SyncFinish);
    except
      on E: Exception do
        LogAsync(Format('Log_FastFile%s.txt', [FormatDateTime('ddmmyyyyhhnn', Now)]),
          '[ExportFileThread] ' + E.Message);
    end;
  finally
    if Assigned(DestWriter) then FreeAndNil(DestWriter);
    FreeAndNil(IdxStream);
    FreeAndNil(MMF);
    TargetLines.Free;
  end;
end;


{ ===== Anti-flicker helpers ===== }

constructor TfrmSmoothLoadingForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBackgroundBmp := TBitmap.Create;
  FLastPaintedProgress := -1;
  // Fade-in padrão (ms)
  FFadeInActive := False;
  FFadeDurationMS := 1200;
  FFadeStartAlpha := 20;
  FFadeEndAlpha := 230; // mantém o visual atual
end;

destructor TfrmSmoothLoadingForm.Destroy;
begin
  FreeAndNil(FBackgroundBmp);
  inherited Destroy;
end;

procedure TfrmSmoothLoadingForm.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  // Evita o "apagão" de fundo (flicker) antes do repaint
  Msg.Result := 1;
end;

procedure TfrmSmoothLoadingForm.ApplySmoothProgress(Percent: Integer);
var
  R: TRect;
begin
  FIsDeterminate := True;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  { Alvo apenas: o tmrAnimation interpola FCurrentProgress -> FTargetProgress (preenchimento suave). }
  if Percent + 0.5 < FCurrentProgress then
    FCurrentProgress := Percent;
  FTargetProgress := Percent;
  if Assigned(tmrAnimation) and (not tmrAnimation.Enabled) then
    tmrAnimation.Enabled := True;
  if Assigned(pnlContainer) and Assigned(pbProgressBar) and HandleAllocated then
  begin
    R := pbProgressBar.BoundsRect;
    OffsetRect(R, pnlContainer.Left, pnlContainer.Top);
    InvalidateRect(Handle, @R, False);
  end
  else if Assigned(pbProgressBar) then
    pbProgressBar.Invalidate;
end;

procedure TfrmSmoothLoadingForm.WMSmoothProgress(var Msg: TMessage);
begin
  { Um passo por mensagem: fundir com PeekMessage fazia a barra saltar directo
    para o ultimo % quando a fila encheia durante trabalho CPU na worker. }
  ApplySmoothProgress(Integer(Msg.WParam));
  Msg.Result := 0;
end;

procedure TfrmSmoothLoadingForm.BuildBackground;
var
  Row: Integer;
  px: Int64;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;

  FBackgroundBmp.PixelFormat := pf24bit;
  FBackgroundBmp.Width := ClientWidth;
  FBackgroundBmp.Height := ClientHeight;

  { Evitar milhoes de LineTo (fullscreen HD+): primeira pintura do overlay parecia "travar". }
  px := Int64(ClientWidth) * Int64(ClientHeight);
  if px > 600000 then
  begin
    FBackgroundBmp.Canvas.Brush.Color := RGB(20, 30, 50);
    FBackgroundBmp.Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
    Exit;
  end;

  // Gradiente de fundo (desenhado 1x e cacheado)
  for Row := 0 to ClientHeight do
  begin
    FBackgroundBmp.Canvas.Pen.Color := RGB(20 + MulDiv(Row, 10, ClientHeight),
                                           30 + MulDiv(Row, 15, ClientHeight),
                                           50 + MulDiv(Row, 30, ClientHeight));
    FBackgroundBmp.Canvas.MoveTo(0, Row);
    FBackgroundBmp.Canvas.LineTo(ClientWidth, Row);
  end;
end;



procedure TfrmSmoothLoadingForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
    // WS_EX_COMPOSITED removido: causava flicker com AlphaBlend/atualização por timer
end;

procedure TfrmSmoothLoadingForm.ForceFullScreen;
begin
  // Força o formulário a ocupar a área total do monitor principal
  Self.Left := 0;
  Self.Top := 0;
  Self.Width := Screen.Width;
  Self.Height := Screen.Height;
end;

procedure TfrmSmoothLoadingForm.pbProgressBarPaint(Sender: TObject);
var
  W, H, BarW: Integer;
begin
  W := pbProgressBar.Width;
  H := pbProgressBar.Height;
  pbProgressBar.Canvas.Brush.Color := $00504C3C;
  pbProgressBar.Canvas.FillRect(Rect(0, 0, W, H));
  BarW := Round((W * FCurrentProgress) / 100);
  pbProgressBar.Canvas.Brush.Color := $00FFDB80;
  pbProgressBar.Canvas.FillRect(Rect(0, 0, BarW, H));
end;

class procedure TfrmSmoothLoading.ShowLoading(const MessageText: String);
begin
  ShowLoading(nil, MessageText, True);
end;

class procedure TfrmSmoothLoading.ShowLoading(const MessageText: String; AStayOnTop: Boolean);
begin
  ShowLoading(nil, MessageText, AStayOnTop);
end;

class procedure TfrmSmoothLoading.ShowLoading(AOwner: TComponent; const MessageText: String; AStayOnTop: Boolean);
begin
  if not Assigned(frmSmoothLoading) then
  begin
    if AOwner <> nil then
      frmSmoothLoading := TfrmSmoothLoadingForm.Create(AOwner)
    else
      frmSmoothLoading := TfrmSmoothLoadingForm.Create(Application);
  end;

  // 1. Overlay: sem owner (app) = opaco (barra fiavel em carga na main). Com owner
  //    (ex. merge modal) = layered para logo BMP transparente / visual habitual.
  if AOwner <> nil then
  begin
    frmSmoothLoading.AlphaBlend := True;
    frmSmoothLoading.AlphaBlendValue := 230;
    frmSmoothLoading.FFadeInActive := False;
  end
  else
  begin
    frmSmoothLoading.AlphaBlend := False;
    frmSmoothLoading.FFadeInActive := False;
  end;
  frmSmoothLoading.FIsDeterminate := True;
  frmSmoothLoading.FCurrentProgress := 0;
  frmSmoothLoading.FTargetProgress := 0;
  frmSmoothLoading.lblMessage.Caption := MessageText;
  if Assigned(frmSmoothLoading.lblDetail) then
  begin
    frmSmoothLoading.lblDetail.Caption := '';
    frmSmoothLoading.lblDetail.Visible := False;
  end;

  if AStayOnTop then
    frmSmoothLoading.FormStyle := fsStayOnTop
  else
    frmSmoothLoading.FormStyle := fsNormal;

  // 2) Força fullscreen antes de mostrar
  frmSmoothLoading.ForceFullScreen;

  frmSmoothLoading.Show;
  
  // 3. Posicionamento e arredondamento
  frmSmoothLoading.CenterContainer;
  frmSmoothLoading.RoundControl(frmSmoothLoading.pnlContainer, 50);

  frmSmoothLoading.FLastPaintedProgress := -1;
  frmSmoothLoading.tmrAnimation.Enabled := True;
  frmSmoothLoading.lblMessage.Font.Color := $00FFF0E6;
  
  // Força o Windows a processar a exibição imediatamente
  Application.ProcessMessages;
  if (not AStayOnTop) and frmSmoothLoading.HandleAllocated then
    frmSmoothLoading.BringToFront;
  if Assigned(frmSmoothLoading.imgLogo) then
    frmSmoothLoading.imgLogo.Invalidate;
end;

procedure TfrmSmoothLoadingForm.tmrAnimationTimer(Sender: TObject);
var
  Elapsed: Cardinal;
  NewAlpha: Integer;
begin
  if FFadeInActive and AlphaBlend then
  begin
    Elapsed := GetTickCount - FFadeStartTick;
    if (FFadeDurationMS = 0) then
      NewAlpha := FFadeEndAlpha
    else
      NewAlpha := FFadeStartAlpha +
        Round((FFadeEndAlpha - FFadeStartAlpha) * (Elapsed / FFadeDurationMS));

    if NewAlpha >= FFadeEndAlpha then
    begin
      AlphaBlendValue := FFadeEndAlpha;
      FFadeInActive := False;
    end
    else if NewAlpha <= 1 then
      AlphaBlendValue := 2
    else
      AlphaBlendValue := Byte(NewAlpha);
  end;

  if not FIsDeterminate then
  begin
    FCurrentProgress := FCurrentProgress + 1.5;
    if FCurrentProgress > 100 then
      FCurrentProgress := 0;
  end
  else
  begin
    if Abs(FCurrentProgress - FTargetProgress) > 0.1 then
      FCurrentProgress := FCurrentProgress + (FTargetProgress - FCurrentProgress) * 0.15
    else if Abs(FCurrentProgress - FTargetProgress) > 0.001 then
    begin
      FCurrentProgress := FTargetProgress;
      FLastPaintedProgress := FCurrentProgress;
      if Assigned(pbProgressBar) then
        pbProgressBar.Invalidate;
    end
    else
      FCurrentProgress := FTargetProgress;
  end;

  if (not FIsDeterminate) or (Abs(FCurrentProgress - FTargetProgress) > 0.1) then
  begin
    if Abs(FLastPaintedProgress - FCurrentProgress) > 0.15 then
    begin
      FLastPaintedProgress := FCurrentProgress;
      if Assigned(pbProgressBar) then
        pbProgressBar.Invalidate;
    end;
    if not FIsDeterminate then
    begin
      if Assigned(pbProgressBar) then
        pbProgressBar.Invalidate;
    end;
  end;
end;

class procedure TfrmSmoothLoading.UpdateProgress(Percent: Integer);
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  { Fora da main thread: PostMessage pode ser tratado em lote antes do
    paint visivel. SendMessage forca o proc. da janela na main thread ja
    aqui (bloqueia a worker ate pintar). }
  if GetCurrentThreadId = MainThreadID then
    frmSmoothLoading.ApplySmoothProgress(Percent)
  else if frmSmoothLoading.HandleAllocated then
    SendMessage(frmSmoothLoading.Handle, WM_APP + 77, WPARAM(Percent), 0);
end;

class procedure TfrmSmoothLoading.PostProgressFromWorker(Percent: Integer);
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  if GetCurrentThreadId = MainThreadID then
    frmSmoothLoading.ApplySmoothProgress(Percent)
  else if frmSmoothLoading.HandleAllocated then
    PostMessage(frmSmoothLoading.Handle, WM_APP + 77, WPARAM(Percent), 0);
end;

class procedure TfrmSmoothLoading.UpdateProgressWithDetail(Percent: Integer; const Detail: string);
begin
  UpdateProgress(Percent);
  if Assigned(frmSmoothLoading) and Assigned(frmSmoothLoading.lblDetail) then
  begin
    frmSmoothLoading.lblDetail.Caption := Detail;
    frmSmoothLoading.lblDetail.Visible := Trim(Detail) <> '';
  end;
end;

procedure TfrmSmoothLoadingForm.FormPaint(Sender: TObject);
begin
  { Antes: gradiente linha-a-linha no Canvas a cada WM_PAINT (fullscreen = UI "congelada"). }
  if (ClientWidth > 0) and (ClientHeight > 0) then
  begin
    if (FBackgroundBmp.Width <> ClientWidth) or (FBackgroundBmp.Height <> ClientHeight) then
      BuildBackground;
    if (FBackgroundBmp.Width = ClientWidth) and (FBackgroundBmp.Height = ClientHeight) then
      Canvas.Draw(0, 0, FBackgroundBmp)
    else
    begin
      Canvas.Brush.Color := RGB(20, 30, 50);
      Canvas.FillRect(ClientRect);
    end;
  end;
end;

procedure TfrmSmoothLoadingForm.CenterContainer;
begin
  if Assigned(pnlContainer) then
  begin
    pnlContainer.Left := (Self.ClientWidth - pnlContainer.Width) div 2;
    pnlContainer.Top := (Self.ClientHeight - pnlContainer.Height) div 2;
  end;
end;

procedure TfrmSmoothLoadingForm.RoundControl(Control: TWinControl; Radius: Integer);
var Rgn: HRGN;
begin
  Rgn := CreateRoundRectRgn(0, 0, Control.Width + 1, Control.Height + 1, Radius, Radius);
  SetWindowRgn(Control.Handle, Rgn, True);
end;

procedure TfrmSmoothLoadingForm.LoadLogo;
var PathLogo: String;
begin
  PathLogo := ExtractFilePath(Application.ExeName) + 'logo.bmp';
  if FileExists(PathLogo) then imgLogo.Picture.LoadFromFile(PathLogo);
end;

class procedure TfrmSmoothLoading.HideLoading;
begin
  if Assigned(frmSmoothLoading) then
  begin
    frmSmoothLoading.tmrAnimation.Enabled := False;
    FreeAndNil(frmSmoothLoading);
  end;
end;

procedure TfrmSmoothLoadingForm.FormShow(Sender: TObject);
begin
  ApplyTranslationsToForm(Self);
  // Reforça o tamanho total
  Self.BoundsRect := Screen.DesktopRect;
  LoadLogo;
  CenterContainer;
  // Dá um "toque" no Windows para pintar o fundo
  Self.Repaint;
end;

procedure TfrmSmoothLoadingForm.FormResize(Sender: TObject);
begin
  CenterContainer;
  // Não chamamos Repaint aqui para evitar loops, Invalidate é suficiente
  Invalidate;
end;

{ ============================================================================ }
{ PosBMH: Boyer-Moore-Horspool                                                }
{ ============================================================================ }

function PosBMH(const SubStr, S: string): Integer;
var
  Shift: array[0..255] of Integer;
  SubLen, SLen, i, j: Integer;
  b: Byte;
begin
  Result := 0;
  SubLen := Length(SubStr);
  SLen := Length(S);
  if (SubLen = 0) or (SLen = 0) or (SubLen > SLen) then Exit;

  // Fast path: single char
  if SubLen = 1 then
  begin
    b := Byte(SubStr[1]);
    for i := 1 to SLen do
      if Byte(S[i]) = b then
      begin
        Result := i;
        Exit;
      end;
    Exit;
  end;

  // Build shift table
  for i := 0 to 255 do
    Shift[i] := SubLen;
  for i := 1 to SubLen - 1 do
    Shift[Byte(SubStr[i])] := SubLen - i;

  // Search
  i := SubLen;
  while i <= SLen do
  begin
    j := SubLen;
    while (j > 0) and (S[i - SubLen + j] = SubStr[j]) do
      Dec(j);
    if j = 0 then
    begin
      Result := i - SubLen + 1;
      Exit;
    end;
    Inc(i, Shift[Byte(S[i])]);
  end;
end;

{ ============================================================================ }
{ TReplaceAllThread: FIND & REPLACE ALL                                        }
{ ============================================================================ }

constructor TReplaceAllThread.Create(const AFileName, AFindText, AReplaceText: String;
  const ACaseSensitive, AWholeWord: Boolean;
  const AutoHide: Boolean; const ShowUI: Boolean;
  const ASegmented: Boolean; const AIndexFileName: string;
  const ALinesPerSegment: Integer;
  const AOutputOverride: string;
  const ASilent: Boolean;
  const AFreeOnTerminate: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := AFreeOnTerminate;
  FFileName := AFileName;
  FFindText := AFindText;
  FReplaceText := AReplaceText;
  FCaseSensitive := ACaseSensitive;
  FWholeWord := AWholeWord;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FSegmented := ASegmented;
  FIndexFileName := AIndexFileName;
  if ALinesPerSegment < 5000 then
    FLinesPerSegment := 5000
  else
    FLinesPerSegment := ALinesPerSegment;
  FOutputOverride := AOutputOverride;
  FSilent := ASilent;
  FReplacedCount := 0;
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('Replacing (streaming to temp file)...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  FReplaceLimitHit := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TReplaceAllThread.Destroy;
begin
  if Assigned(sw) then sw.Free;
  inherited;
end;

procedure TReplaceAllThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TReplaceAllThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TReplaceAllThread.SyncSetProgress;
begin
  TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TReplaceAllThread.SyncProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgressWithDetail(FPercentToSync, FDetailSync);
end;

procedure TReplaceAllThread.SyncError;
begin
  if (FErrorMsg <> '') and (not FSilent) then
    MessageDlg(TrText('[ReplaceAll] Error: ') + FErrorMsg, mtError, [mbOK], 0);
end;

procedure TReplaceAllThread.FinishThread;
var
  TimerStr: String;
begin
  if FShowLoadingUI then
  begin
    if FAutoHide then
      TfrmSmoothLoading.HideLoading;
  end;

  if FSuccess then
  begin
    if (Trim(FFileName) <> '') then
      FFHistoryAppendReplaceAll(FFileName, FReplacedCountSync, FReplaceLimitHit,
        Copy(FFindText, 1, 200), Copy(FReplaceText, 1, 200));
    sw.Stop;
    TimerStr := Format('Replace All completed. %d replacement(s). Time: %s ms.',
      [FReplacedCountSync, IntToStr(sw.ElapsedMilliseconds)]);
    if Assigned(frmMain) and (not FSilent) then
    begin
      frmMain.mmTimer.Lines.Add(TimerStr);
      frmMain.RefreshFile;
    end;
  end
  else if FReplaceLimitHit and (FErrorMsg <> '') then
  begin
    if not FSilent then
      MessageDlg(FErrorMsg, mtWarning, [mbOK], 0);
  end
  else if (not FSuccess) and (FErrorMsg <> '') then
  begin
    if not FSilent then
      MessageDlg(TrText('[ReplaceAll] ') + FErrorMsg, mtError, [mbOK], 0);
  end;
end;

function ReadIndexLineStart1Based(Idx: TFileStream; LineIdx0: Int64): Int64;
var
  OffsetStr: AnsiString;
begin
  Result := -1;
  if (not Assigned(Idx)) or (LineIdx0 < 0) then Exit;
  Idx.Seek(LineIdx0 * INDEX_RECORD_SIZE, soFromBeginning);
  SetLength(OffsetStr, 18);
  if Idx.Read(Pointer(OffsetStr)^, 18) < 18 then Exit;
  Result := StrToInt64Def(Trim(string(OffsetStr)), -1);
end;

procedure CopyFileRangeToFile(const SourcePath: string; Start0, Len: Int64; const DestPath: string);
var
  FS, FD: TFileStream;
  Buf: array[0..65535] of Byte;
  Rem: Int64;
  n, r: Integer;
begin
  FS := TFileStream.Create(SourcePath, fmOpenRead or fmShareDenyNone);
  try
    FD := TFileStream.Create(DestPath, fmCreate);
    try
      FS.Position := Start0;
      Rem := Len;
      while Rem > 0 do
      begin
        if Rem > SizeOf(Buf) then
          n := SizeOf(Buf)
        else
          n := Integer(Rem);
        r := FS.Read(Buf, n);
        if r <= 0 then Break;
        FD.WriteBuffer(Buf, r);
        Dec(Rem, r);
      end;
    finally
      FD.Free;
    end;
  finally
    FS.Free;
  end;
end;

procedure AppendFileToStream(Dest: TFileStream; const FilePath: string);
var
  S: TFileStream;
begin
  S := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
  try
    Dest.CopyFrom(S, S.Size);
  finally
    S.Free;
  end;
end;

function LineInSortedInt64Array(const A: array of Int64; V: Int64): Boolean;
var
  L, H, M: Integer;
begin
  L := Low(A);
  H := High(A);
  if H < L then
  begin
    Result := False;
    Exit;
  end;
  while L <= H do
  begin
    M := (L + H) shr 1;
    if A[M] = V then
    begin
      Result := True;
      Exit;
    end;
    if A[M] < V then
      L := M + 1
    else
      H := M - 1;
  end;
  Result := False;
end;

procedure CopyStreamRangeBytes(Src: TFileStream; Dest: TFileStream; Len: Int64);
var
  Buf: array[0..65535] of Byte;
  Rem: Int64;
  n, r: Integer;
begin
  Rem := Len;
  while Rem > 0 do
  begin
    if Rem > SizeOf(Buf) then
      n := SizeOf(Buf)
    else
      n := Integer(Rem);
    r := Src.Read(Buf, n);
    if r <= 0 then
      Break;
    Dest.WriteBuffer(Buf, r);
    Dec(Rem, r);
  end;
end;

procedure WriteSegmentKeepLines(Idx: TFileStream; Src: TFileStream;
  TotalLines: Int64; LineStart, LineEnd: Int64;
  const LinesToDelete: array of Int64; const DestPath: string;
  out ALocalErr: string);
var
  OutF: TFileStream;
  L0: Int64;
  Line1: Int64;
  Start1, Next1: Int64;
  Len0: Int64;
  Start0: Int64;
begin
  ALocalErr := '';
  OutF := TFileStream.Create(DestPath, fmCreate);
  try
    L0 := LineStart;
    while L0 <= LineEnd do
    begin
      Line1 := L0 + 1;
      if LineInSortedInt64Array(LinesToDelete, Line1) then
      begin
        Inc(L0);
        Continue;
      end;
      Start1 := ReadIndexLineStart1Based(Idx, L0);
      if Start1 < 1 then
      begin
        ALocalErr := TrText('Segmented replace: invalid line index in temp.txt.');
        Exit;
      end;
      if L0 + 1 < TotalLines then
        Next1 := ReadIndexLineStart1Based(Idx, L0 + 1)
      else
        Next1 := Src.Size + 1;
      Len0 := Next1 - Start1;
      if Len0 <= 0 then
      begin
        ALocalErr := TrText('Segmented replace: invalid line index in temp.txt.');
        Exit;
      end;
      Start0 := Start1 - 1;
      Src.Position := Start0;
      CopyStreamRangeBytes(Src, OutF, Len0);
      Inc(L0);
    end;
  finally
    OutF.Free;
  end;
end;

function TrySegmentedBatchDelete(const FileName, IndexFileName: string;
  const LinesToDelete1Based: array of Int64; LinesPerSegment: Integer;
  out AErrorMsg: string): Boolean;
var
  Idx, Src, Merge: TFileStream;
  TotalLines: Int64;
  TotalParts: Int64;
  LineStart, LineEnd: Int64;
  SegOut, FTempMerge: string;
  FinalErr: string;
  LocalErr: string;
  Aborted: Boolean;
begin
  Result := False;
  AErrorMsg := '';
  if (IndexFileName = '') or (not FileExists(IndexFileName)) then
    Exit;
  if High(LinesToDelete1Based) < Low(LinesToDelete1Based) then
    Exit;
  if LinesPerSegment < 5000 then
    LinesPerSegment := 5000;

  Idx := nil;
  Src := nil;
  Merge := nil;
  FTempMerge := '';
  try
    Idx := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);
    Src := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      TotalLines := Idx.Size div INDEX_RECORD_SIZE;
      if TotalLines < 2 then
        Exit;

      TotalParts := (TotalLines + LinesPerSegment - 1) div LinesPerSegment;
      if TotalParts <= 1 then
        Exit;

      if not VolumeHasMinFreeBytes(FileName, Src.Size + 64 * 1024 * 1024) then
      begin
        AErrorMsg := TrText('Not enough free disk space to complete this operation safely.');
        Result := True;
        Exit;
      end;

      FTempMerge := NewFastFileTemp('bdel');
      UnUtils.ForceDeleteFile(FTempMerge);
      Merge := TFileStream.Create(FTempMerge, fmCreate);
      Aborted := False;
      try
        LineStart := 0;
        while LineStart < TotalLines do
        begin
          LineEnd := LineStart + LinesPerSegment - 1;
          if LineEnd >= TotalLines then
            LineEnd := TotalLines - 1;

          SegOut := NewFastFileTemp('dseg_out');
          UnUtils.ForceDeleteFile(SegOut);
          try
            WriteSegmentKeepLines(Idx, Src, TotalLines, LineStart, LineEnd,
              LinesToDelete1Based, SegOut, LocalErr);
            if LocalErr <> '' then
            begin
              AErrorMsg := LocalErr;
              Aborted := True;
              Break;
            end;
            AppendFileToStream(Merge, SegOut);
          finally
            UnUtils.ForceDeleteFile(SegOut);
          end;

          LineStart := LineEnd + 1;
        end;
      finally
        FreeAndNil(Merge);
      end;

      if Aborted then
      begin
        UnUtils.ForceDeleteFile(FTempMerge);
        Result := True;
        Exit;
      end;
    finally
      FreeAndNil(Idx);
      FreeAndNil(Src);
    end;

    if not UnUtils.TryRenameTempOverTarget(FTempMerge, FileName, FinalErr) then
      AErrorMsg := FinalErr
    else
      AErrorMsg := '';
    Result := True;
  except
    on E: Exception do
    begin
      AErrorMsg := E.Message;
      Result := True;
      FreeAndNil(Merge);
      FreeAndNil(Idx);
      FreeAndNil(Src);
      if FTempMerge <> '' then
        UnUtils.ForceDeleteFile(FTempMerge);
    end;
  end;
end;

function TReplaceAllThread.TrySegmentedReplace: Boolean;
var
  Idx, Src: TFileStream;
  Merge: TFileStream;
  TotalLines: Int64;
  TotalParts: Int64;
  PartI: Integer;
  LineStart, LineEnd: Int64;
  Start1, Next1: Int64;
  Len0: Int64;
  Start0: Int64;
  SegIn, SegOut: string;
  Inner: TReplaceAllThread;
  FinalErr: string;
  Pct: Integer;
begin
  Result := False;
  if (FIndexFileName = '') or (not FileExists(FIndexFileName)) then Exit;

  Idx := nil;
  Src := nil;
  Merge := nil;
  FSuccess := True;
  try
    Idx := TFileStream.Create(FIndexFileName, fmOpenRead or fmShareDenyNone);
    Src := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
    TotalLines := Idx.Size div INDEX_RECORD_SIZE;
    if TotalLines < 2 then Exit;

    TotalParts := (TotalLines + FLinesPerSegment - 1) div FLinesPerSegment;
    if TotalParts <= 1 then Exit;

    if not VolumeHasMinFreeBytes(FFileName, Src.Size + 64 * 1024 * 1024) then
    begin
      FErrorMsg := TrText('Not enough free disk space to complete this operation safely.');
      FSuccess := False;
      FReplacedCountSync := 0;
      Synchronize(FinishThread);
      Result := True;
      Exit;
    end;

    FTempFileName := NewFastFileTemp('replace');
    ForceDeleteFile(FTempFileName);
    Merge := TFileStream.Create(FTempFileName, fmCreate);
    try
      FReplacedCount := 0;
      FCurrentPercent := 0;

      PartI := 0;
      LineStart := 0;
      while LineStart < TotalLines do
      begin
        if Terminated then Break;

        LineEnd := LineStart + FLinesPerSegment - 1;
        if LineEnd >= TotalLines then
          LineEnd := TotalLines - 1;

        Start1 := ReadIndexLineStart1Based(Idx, LineStart);
        if Start1 < 1 then
        begin
          FErrorMsg := TrText('Segmented replace: invalid line index in temp.txt.');
          FSuccess := False;
          Break;
        end;

        if LineEnd + 1 < TotalLines then
          Next1 := ReadIndexLineStart1Based(Idx, LineEnd + 1)
        else
          Next1 := Src.Size + 1;

        Len0 := Next1 - Start1;
        if Len0 <= 0 then
        begin
          Inc(PartI);
          LineStart := LineEnd + 1;
          Continue;
        end;

        Start0 := Start1 - 1;
        SegIn := NewFastFileTemp('rseg_in');
        SegOut := NewFastFileTemp('rseg_out');
        ForceDeleteFile(SegIn);
        ForceDeleteFile(SegOut);

        try
          CopyFileRangeToFile(FFileName, Start0, Len0, SegIn);

          Inner := TReplaceAllThread.Create(SegIn, FFindText, FReplaceText,
            FCaseSensitive, FWholeWord, False, False,
            False, '', FLinesPerSegment, SegOut, True, False);
          Inner.WaitFor;
          try
            if not Inner.OperationSucceeded then
            begin
              FSuccess := False;
              if Inner.LastErrorMsg <> '' then
                FErrorMsg := Inner.LastErrorMsg
              else
                FErrorMsg := TrText('[ReplaceAll] Segmented part failed.');
              Break;
            end;
            Inc(FReplacedCount, Inner.ReplacedTotal);
            if FReplacedCount >= REPLACE_ALL_MATCH_LIMIT then
            begin
              FReplaceLimitHit := True;
              FErrorMsg := Format(TrText('Replace-all stopped at the safety limit of %d matches. The file was not modified.'),
                [REPLACE_ALL_MATCH_LIMIT]);
              FSuccess := False;
              Break;
            end;
            if not FileExists(SegOut) then
            begin
              FErrorMsg := TrText('[ReplaceAll] Segmented output missing.');
              FSuccess := False;
              Break;
            end;
            AppendFileToStream(Merge, SegOut);
          finally
            Inner.Free;
          end;
        finally
          ForceDeleteFile(SegIn);
          ForceDeleteFile(SegOut);
        end;

        Pct := Round(((PartI + 1) * 100.0) / TotalParts);
        if Pct > 100 then Pct := 100;
        FPercentToSync := Pct;
        FDetailSync := TrText('Segment') + ' ' + IntToStr(PartI + 1) + '/' + IntToStr(TotalParts) + #13#10 +
          IntToStr(FReplacedCount) + ' ' + TrText('replacements');
        if FShowLoadingUI then
          Synchronize(SyncProgress);

        Inc(PartI);
        LineStart := LineEnd + 1;
      end;
    finally
      FreeAndNil(Merge);
    end;

    FreeAndNil(Idx);
    FreeAndNil(Src);

    if Terminated then
    begin
      FSuccess := False;
      FErrorMsg := TrText('Operation cancelled.');
      ForceDeleteFile(FTempFileName);
      FReplacedCountSync := FReplacedCount;
      Synchronize(FinishThread);
      Result := True;
      Exit;
    end;

    if FReplaceLimitHit or (not FSuccess) then
    begin
      ForceDeleteFile(FTempFileName);
      FReplacedCountSync := FReplacedCount;
      Synchronize(FinishThread);
      Result := True;
      Exit;
    end;

    FReplacedCountSync := FReplacedCount;
    FSuccess := TryRenameTempOverTarget(FTempFileName, FFileName, FinalErr);
    if not FSuccess then
      FErrorMsg := FinalErr;
    Synchronize(FinishThread);
    Result := True;
  except
    on E: Exception do
    begin
      FErrorMsg := E.Message;
      FSuccess := False;
      FReplacedCountSync := FReplacedCount;
      FreeAndNil(Merge);
      FreeAndNil(Idx);
      FreeAndNil(Src);
      ForceDeleteFile(FTempFileName);
      Synchronize(FinishThread);
      Result := True;
    end;
  end;
end;

procedure TReplaceAllThread.Execute;
const
  BUF_SIZE = 1024 * 1024; // 1 MB por bloco de leitura

  function ForceDeleteFile(const FileName: string): Boolean;
  var RetryCount: Integer;
  begin
    Result := False;
    if not FileExists(FileName) then begin Result := True; Exit; end;
    for RetryCount := 1 to 5 do begin
      if DeleteFile(FileName) then begin Result := True; Break; end;
      Sleep(200);
    end;
    if not Result then
      Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');
  end;

  function IsWordBoundaryChar(Ch: Byte): Boolean;
  begin
    Result := not (AnsiChar(Ch) in ['A'..'Z', 'a'..'z', '0'..'9', '_']);
  end;

type
  TShiftTable = array[0..255] of Integer;

var
  MMF: TMMFReader;
  DestWriter: TBufferedTextWriter;
  FileSize: Int64;
  NeedLen: Integer;

  // BMH tables
  Shift: TShiftTable;
  Up: array[0..255] of Byte;
  Pat: array of Byte;
  PatU: array of Byte;

  // Buffers
  BufRaw: array of Byte;
  WorkBuf: array of Byte;
  Tail: array of Byte;
  TailLen: Integer;

  // Positions
  CurPos: Int64;
  WritePos: Int64;
  BytesRead: Integer;
  ReadSize: Integer;

  // Replace text bytes
  ReplaceBytes: AnsiString;

  // Progress
  NewPercent: Integer;
  LastProgressPos: Int64;

  procedure BuildUpTable;
  var i: Integer; c: AnsiChar;
  begin
    for i := 0 to 255 do
    begin
      c := AnsiChar(i);
      CharUpperBuffA(@c, 1);
      Up[i] := Byte(c);
    end;
  end;

  procedure BuildPatternBytes;
  var i: Integer; b: Byte;
  begin
    SetLength(Pat, NeedLen);
    SetLength(PatU, NeedLen);
    for i := 0 to NeedLen - 1 do
    begin
      b := Byte(AnsiChar(FFindText[i + 1]));
      Pat[i] := b;
      PatU[i] := Up[b];
    end;
  end;

  procedure BuildShiftTable;
  var i: Integer; b: Byte;
  begin
    for i := 0 to 255 do
      Shift[i] := NeedLen;
    for i := 0 to NeedLen - 2 do
    begin
      if FCaseSensitive then
        b := Pat[i]
      else
        b := PatU[i];
      Shift[b] := (NeedLen - 1) - i;
    end;
  end;

  function BMH_FindFirst(const Buf: PByte; const BufLen: Integer; const AStartIndex: Integer): Integer;
  var
    i, j, baseIdx: Integer;
    tb: Byte;
  begin
    Result := -1;
    if (NeedLen <= 0) or (BufLen < NeedLen) then Exit;
    i := AStartIndex + (NeedLen - 1);
    while i < BufLen do
    begin
      j := NeedLen - 1;
      if FCaseSensitive then
      begin
        while (j >= 0) do
        begin
          baseIdx := i - ((NeedLen - 1) - j);
          if PByteArray(Buf)^[baseIdx] <> PByteArray(Pat)^[j] then Break;
          Dec(j);
        end;
      end
      else
      begin
        while (j >= 0) do
        begin
          baseIdx := i - ((NeedLen - 1) - j);
          if Up[PByteArray(Buf)^[baseIdx]] <> PByteArray(PatU)^[j] then Break;
          Dec(j);
        end;
      end;
      if j < 0 then
      begin
        Result := i - (NeedLen - 1);
        Exit;
      end;
      if FCaseSensitive then
        tb := PByteArray(Buf)^[i]
      else
        tb := Up[PByteArray(Buf)^[i]];
      Inc(i, Shift[tb]);
    end;
  end;

  procedure WriteFromSource(FromPos, Count: Int64);
  var
    P: PByte;
    Cont: Cardinal;
    ToWrite: Integer;
  begin
    while Count > 0 do
    begin
      P := MMF.PtrAt(FromPos, 1, Cont);
      if P = nil then Exit;
      if Int64(Cont) > Count then ToWrite := Integer(Count)
      else ToWrite := Integer(Cont);
      DestWriter.WriteRaw(P, ToWrite);
      Inc(FromPos, ToWrite);
      Dec(Count, ToWrite);
    end;
  end;

  procedure UpdateProgressAt(AbsPos: Int64);
  begin
    if FileSize <= 0 then Exit;
    NewPercent := Round((AbsPos * 100.0) / FileSize);
    if NewPercent > 100 then NewPercent := 100;
    if NewPercent > FCurrentPercent then
      FCurrentPercent := NewPercent;
    FPercentToSync := FCurrentPercent;
    FDetailSync := UnUtils.FormatNumber(AbsPos) + ' / ' + UnUtils.FormatNumber(FileSize) + ' B' + #13#10 +
      IntToStr(FReplacedCount) + ' ' + TrText('replacements');
    if FShowLoadingUI then
      Synchronize(SyncProgress);
  end;

var
  FoundIdx: Integer;
  FoundBaseAbs: Int64;
  MatchAbsPos: Int64;
  SearchFrom: Integer;
  WorkLen: Integer;
  CanReplace: Boolean;
  ByteBefore, ByteAfter: Byte;
  MatchBufIdx: Integer;
  FinalErr: string;
begin
  inherited;
  if FSegmented and (FOutputOverride = '') and (FIndexFileName <> '') and FileExists(FIndexFileName) then
  begin
    if TrySegmentedReplace then
      Exit;
  end;

  FTempFileName := NewFastFileTemp('replace');
  ForceDeleteFile(FTempFileName);

  MMF := nil;
  DestWriter := nil;
  try
    try
    MMF := TMMFReader.Create(FFileName);
    FileSize := MMF.FileSize;
    FTotalSize := FileSize;
    if not VolumeHasMinFreeBytes(FFileName, FileSize + 64 * 1024 * 1024) then
    begin
      FErrorMsg := TrText('Not enough free disk space to complete this operation safely.');
      raise Exception.Create(FErrorMsg);
    end;
    DestWriter := TBufferedTextWriter.Create(FTempFileName, 16 * 1024 * 1024);

    FCurrentPercent := 0;
    NeedLen := Length(FFindText);
    ReplaceBytes := AnsiString(FReplaceText);
    WritePos := 0;

    if (NeedLen <= 0) or (FileSize = 0) then
    begin
      WriteFromSource(0, FileSize);
      FreeAndNil(DestWriter);
      FreeAndNil(MMF);
      FReplacedCountSync := 0;
      if FOutputOverride <> '' then
        FSuccess := TryRenameTempOverTarget(FTempFileName, FOutputOverride, FinalErr)
      else
        FSuccess := TryRenameTempOverTarget(FTempFileName, FFileName, FinalErr);
      if not FSuccess then
        FErrorMsg := FinalErr;
      Synchronize(FinishThread);
      Exit;
    end;

    BuildUpTable;
    BuildPatternBytes;
    BuildShiftTable;

    SetLength(BufRaw, BUF_SIZE);
    TailLen := 0;
    SetLength(Tail, 0);
    CurPos := 0;
    LastProgressPos := 0;

    while (not Terminated) and (CurPos < FileSize) do
    begin
      ReadSize := BUF_SIZE;
      if CurPos + ReadSize > FileSize then
        ReadSize := Integer(FileSize - CurPos);
      if ReadSize <= 0 then Break;

      BytesRead := Integer(MMF.ReadBytes(CurPos, BufRaw[0], Cardinal(ReadSize)));
      if BytesRead <= 0 then Break;

      if TailLen > 0 then
      begin
        SetLength(WorkBuf, TailLen + BytesRead);
        Move(Tail[0], WorkBuf[0], TailLen);
        Move(BufRaw[0], WorkBuf[TailLen], BytesRead);
        FoundBaseAbs := CurPos - Int64(TailLen);
      end
      else
      begin
        SetLength(WorkBuf, BytesRead);
        Move(BufRaw[0], WorkBuf[0], BytesRead);
        FoundBaseAbs := CurPos;
      end;

      WorkLen := Length(WorkBuf);
      SearchFrom := 0;

      while SearchFrom <= WorkLen - NeedLen do
      begin
        if Terminated then Break;

        FoundIdx := BMH_FindFirst(@WorkBuf[0], WorkLen, SearchFrom);
        if FoundIdx < 0 then Break;

        MatchAbsPos := FoundBaseAbs + Int64(FoundIdx);
        MatchBufIdx := FoundIdx;

        CanReplace := True;
        if FWholeWord then
        begin
          if MatchBufIdx > 0 then
          begin
            ByteBefore := WorkBuf[MatchBufIdx - 1];
            if not IsWordBoundaryChar(ByteBefore) then CanReplace := False;
          end
          else if MatchAbsPos > 0 then
          begin
            MMF.ReadBytes(MatchAbsPos - 1, ByteBefore, 1);
            if not IsWordBoundaryChar(ByteBefore) then CanReplace := False;
          end;
          if CanReplace then
          begin
            if MatchBufIdx + NeedLen < WorkLen then
            begin
              ByteAfter := WorkBuf[MatchBufIdx + NeedLen];
              if not IsWordBoundaryChar(ByteAfter) then CanReplace := False;
            end
            else if MatchAbsPos + NeedLen < FileSize then
            begin
              MMF.ReadBytes(MatchAbsPos + NeedLen, ByteAfter, 1);
              if not IsWordBoundaryChar(ByteAfter) then CanReplace := False;
            end;
          end;
        end;

        if CanReplace then
        begin
          if MatchAbsPos > WritePos then
            WriteFromSource(WritePos, MatchAbsPos - WritePos);
          if Length(ReplaceBytes) > 0 then
            DestWriter.WriteRaw(PAnsiChar(ReplaceBytes), Length(ReplaceBytes));
          WritePos := MatchAbsPos + Int64(NeedLen);
          SearchFrom := FoundIdx + NeedLen;
          Inc(FReplacedCount);
          if FReplacedCount >= REPLACE_ALL_MATCH_LIMIT then
          begin
            FReplaceLimitHit := True;
            Break;
          end;
        end
        else
        begin
          SearchFrom := FoundIdx + 1;
        end;
      end;

      if FReplaceLimitHit then
        Break;

      CurPos := CurPos + Int64(BytesRead);

      if NeedLen > 1 then
      begin
        TailLen := NeedLen - 1;
        if TailLen > WorkLen then TailLen := WorkLen;
        SetLength(Tail, TailLen);
        if TailLen > 0 then
          Move(WorkBuf[WorkLen - TailLen], Tail[0], TailLen);
      end
      else
      begin
        TailLen := 0;
        SetLength(Tail, 0);
      end;

      if (CurPos - LastProgressPos >= 1024 * 1024) or (CurPos >= FileSize) then
      begin
        UpdateProgressAt(CurPos);
        LastProgressPos := CurPos;
      end;
    end;

    if Terminated or FReplaceLimitHit then
    begin
      FreeAndNil(DestWriter);
      FreeAndNil(MMF);
      ForceDeleteFile(FTempFileName);
      FReplacedCountSync := FReplacedCount;
      if FReplaceLimitHit then
        FErrorMsg := Format(TrText('Replace-all stopped at the safety limit of %d matches. The file was not modified.'),
          [REPLACE_ALL_MATCH_LIMIT])
      else if Terminated then
        FErrorMsg := TrText('Operation cancelled.');
      FSuccess := False;
      Synchronize(FinishThread);
      Exit;
    end;

    if WritePos < FileSize then
      WriteFromSource(WritePos, FileSize - WritePos);

    FreeAndNil(DestWriter);
    FreeAndNil(MMF);

    FReplacedCountSync := FReplacedCount;
    if FOutputOverride <> '' then
      FSuccess := TryRenameTempOverTarget(FTempFileName, FOutputOverride, FinalErr)
    else
      FSuccess := TryRenameTempOverTarget(FTempFileName, FFileName, FinalErr);
    if not FSuccess then
      FErrorMsg := FinalErr;
  except
    on E: Exception do begin
      FErrorMsg := E.Message;
      LogAsync(Format('Log_FastFile%s.txt', [FormatDateTime('ddmmyyyyhhnn', Now)]),
        '[ReplaceAllThread] ' + E.Message);
      if Assigned(MMF) then MMF.Free;
      if Assigned(DestWriter) then DestWriter.Free;
    end;
  end;
  finally
    if (FTempFileName <> '') and FileExists(FTempFileName) then
      ForceDeleteFile(FTempFileName);
  end;
  Synchronize(FinishThread);
end;

{ ============================================================================ }
{ THREAD: SPLIT FILE                                                           }
{ ============================================================================ }

constructor TSplitFileThread.Create(const AOriginalFileName: String; const AOutputDir: String; const AEntries: TSplitEntryArray; const AEntryCount: Integer);
var
  i: Integer;
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FOriginalFileName := AOriginalFileName;
  FOutputDir := AOutputDir;
  FEntryCount := AEntryCount;
  SetLength(FEntries, FEntryCount);
  for i := 0 to FEntryCount - 1 do
    FEntries[i] := AEntries[i];
  FAutoHide := True;
  FShowLoadingUI := True;
  FLoadingMsg := 'Splitting file...';
  FProgressToSet := 0;
  Synchronize(SyncShowLoading);
  Synchronize(SyncSetProgress);
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TSplitFileThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TSplitFileThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TSplitFileThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TSplitFileThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TSplitFileThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TSplitFileThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  ShowMessage('Split Error: ' + FErrorMsg);
end;

procedure TSplitFileThread.SyncFinish;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  if FSuccess then
    ShowMessage(Format('Split completed. %d file(s) created in %s.', [FEntryCount, FTimerResult]));
end;

procedure TSplitFileThread.Execute;
const
  INDEX_REC_SIZE = 20;
  MAX_LINE_LEN = 2 * 1024 * 1024;
var
  MMF: TMMFReader;
  IdxStream: TFileStream;
  W: TBufferedTextWriter;
  e, LineIdx: Integer;
  OffsetStr: AnsiString;
  StartOffset, EndOffset, ReadPos: Int64;
  FSize: Int64;
  LineLength: Integer;
  Buffer: AnsiString;
  P: PByte;
  Contiguous: Cardinal;
  TotalLines, DoneLines: Int64;
  NewPercent: Integer;
  OutputPath, IndexFileName: String;
begin
  inherited;
  MMF := nil;
  IdxStream := nil;

  IndexFileName := ExtractFilePath(ParamStr(0)) + 'temp.txt';

  try
    try
      MMF := TMMFReader.Create(FOriginalFileName);
      IdxStream := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);
      FSize := MMF.FileSize;
      SetLength(OffsetStr, 18);

      TotalLines := 0;
      for e := 0 to FEntryCount - 1 do
        TotalLines := TotalLines + (FEntries[e].TargetLine - FEntries[e].SourceLine + 1);
      DoneLines := 0;
      FCurrentPercent := 0;

      for e := 0 to FEntryCount - 1 do
      begin
        if Terminated then Break;
        OutputPath := FOutputDir + FEntries[e].FileName;
        W := TBufferedTextWriter.Create(OutputPath, 4 * 1024 * 1024);
        try
          for LineIdx := FEntries[e].SourceLine to FEntries[e].TargetLine do
          begin
            if Terminated then Break;

            IdxStream.Seek(Int64(LineIdx) * INDEX_REC_SIZE, soFromBeginning);
            IdxStream.Read(Pointer(OffsetStr)^, 18);
            StartOffset := StrToInt64Def(Trim(string(OffsetStr)), -1);
            if StartOffset = -1 then
            begin
              W.WriteLine('');
              Inc(DoneLines);
              Continue;
            end;

            if (Int64(LineIdx + 1) * INDEX_REC_SIZE) < IdxStream.Size then
            begin
              IdxStream.Seek(Int64(LineIdx + 1) * INDEX_REC_SIZE, soFromBeginning);
              IdxStream.Read(Pointer(OffsetStr)^, 18);
              EndOffset := StrToInt64Def(Trim(string(OffsetStr)), FSize + 1);
            end
            else
              EndOffset := FSize + 1;

            LineLength := EndOffset - StartOffset;
            if LineLength <= 0 then
            begin
              W.WriteLine('');
              Inc(DoneLines);
              Continue;
            end;
            if LineLength > MAX_LINE_LEN then LineLength := MAX_LINE_LEN;

            ReadPos := StartOffset - 1;
            SetLength(Buffer, LineLength);

            P := MMF.PtrAt(ReadPos, LineLength, Contiguous);
            if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then
              Move(P^, Pointer(Buffer)^, LineLength)
            else
              MMF.ReadBytes(ReadPos, Pointer(Buffer)^, LineLength);

            while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do
              SetLength(Buffer, Length(Buffer) - 1);

            W.WriteLine(Buffer);
            Inc(DoneLines);

            if (DoneLines and 1023) = 0 then
            begin
              if TotalLines > 0 then
              begin
                NewPercent := Round((DoneLines * 100) / TotalLines);
                if NewPercent > FCurrentPercent then
                begin
                  FCurrentPercent := NewPercent;
                  FPercentToSync := FCurrentPercent;
                  Synchronize(SyncProgress);
                end;
              end;
            end;
          end;
        finally
          FreeAndNil(W);
        end;
      end;

      FSuccess := True;
    except
      on E: Exception do begin
        FErrorMsg := E.Message;
        LogAsync(Format('Log_FastFile%s.txt', [FormatDateTime('ddmmyyyyhhnn', Now)]),
          '[SplitFileThread] ' + E.Message);
        Synchronize(SyncError);
      end;
    end;
  finally
    FreeAndNil(IdxStream);
    FreeAndNil(MMF);
  end;
  FTimerResult := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
  Synchronize(SyncFinish);
end;

{ ============================================================================ }
{ THREAD: MERGE FILES                                                          }
{ ============================================================================ }

constructor TMergeFilesThread.Create(const ADestinationFileName,
  ASourceFileName: String; const AInsertOffset: Int64;
  const AutoHide: Boolean = True; const ShowUI: Boolean = True; const AFromLine: Int64 = 0;
  const AToLine: Int64 = 0);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FDestinationFileName := ADestinationFileName;
  FSourceFileName := ASourceFileName;
  FInsertOffset := AInsertOffset;
  FFromLine := AFromLine;
  FToLine := AToLine;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('Mesclando arquivos...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TMergeFilesThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TMergeFilesThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TMergeFilesThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TMergeFilesThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TMergeFilesThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TMergeFilesThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  ShowMessage(TrText('Erro ao mesclar arquivos: ') + FErrorMsg);
end;

procedure TMergeFilesThread.FinishThread;
var
  TimeStr: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    TimeStr := Format(TrText('Mesclagem de arquivos conclu?da em: %s milissegundos.'),
      [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
    if Assigned(frmMain) then
    begin
      frmMain.mmTimer.Lines.Add(TimeStr);
      frmMain.RefreshFile;
    end;
  end;
end;

procedure TMergeFilesThread.Execute;
const
  BUF_SIZE = 4 * 1024 * 1024;
  LINE_COUNTER_BUF_SIZE = 64 * 1024;

function ForceDeleteFile(const FileName: string): Boolean;
var
  RetryCount: Integer;
begin
  Result := False;
  if not FileExists(FileName) then begin Result := True; Exit; end;
  for RetryCount := 1 to 10 do
  begin
    if DeleteFile(FileName) then
    begin
      Result := True;
      Break;
    end;
    Sleep(200);
  end;
  if not Result then
    Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');
end;

procedure CopyRangeWithProgress(AInput, AOutput: TFileStream;
  const AStartPos, ACount: Int64; var AProcessed, ATotal: Int64);
var
  Buffer: array of Byte;
  Remaining, ToRead: Int64;
  ReadBytes: Integer;
  NewPercent: Integer;
begin
  if ACount <= 0 then Exit;
  SetLength(Buffer, BUF_SIZE);
  Remaining := ACount;
  AInput.Seek(AStartPos, soFromBeginning);

  while (Remaining > 0) and (not Terminated) do
  begin
    ToRead := Remaining;
    if ToRead > BUF_SIZE then
      ToRead := BUF_SIZE;

    ReadBytes := AInput.Read(Buffer[0], Integer(ToRead));
    if ReadBytes <= 0 then Break;

    AOutput.WriteBuffer(Buffer[0], ReadBytes);

    Dec(Remaining, ReadBytes);
    Inc(AProcessed, ReadBytes);

    if ATotal > 0 then
    begin
      NewPercent := Round((AProcessed * 100.0) / ATotal);
      if NewPercent > 100 then NewPercent := 100;
      if NewPercent > FCurrentPercent then
      begin
        FCurrentPercent := NewPercent;
        FPercentToSync := FCurrentPercent;
        Synchronize(SyncProgress);
      end;
    end;
  end;
end;

{ Encontra o offset de byte para uma linha espec?fica no arquivo de origem }
function GetSourceLineOffset(AStreamr: TFileStream; const ALine1Based: Int64): Int64;
var
  Buffer: array[0..LINE_COUNTER_BUF_SIZE - 1] of AnsiChar;
  BytesRead: Integer;
  CurrentLine: Int64;
  i: Integer;
  Offset: Int64;
begin
  Result := -1;
  if ALine1Based < 1 then Exit;
  if ALine1Based = 1 then
  begin
    Result := 0;
    Exit;
  end;

  CurrentLine := 1;
  Offset := 0;
  AStreamr.Seek(0, soFromBeginning);

  while True do
  begin
    BytesRead := AStreamr.Read(Buffer[0], LINE_COUNTER_BUF_SIZE);
    if BytesRead <= 0 then
      Break;

    for i := 0 to BytesRead - 1 do
    begin
      if Buffer[i] = #10 then { LF (linha nova no Unix/Linux) ou CR+LF (Windows) }
      begin
        Inc(CurrentLine);
        if CurrentLine = ALine1Based then
        begin
          Result := Offset + i + 1; { Pr?xima posi??o ap?s a quebra de linha }
          Exit;
        end;
      end;
    end;
    Inc(Offset, BytesRead);
  end;

  { Se chegou ao final do arquivo sem encontrar a linha }
  if CurrentLine >= ALine1Based then
    Result := Offset;
end;

var
  SrcStream, DstStream, OutStream: TFileStream;
  DstSize, SrcSize: Int64;
  SrcStartOffset, SrcEndOffset, SrcRangeSize: Int64;
  Processed, TotalToProcess: Int64;
begin
  inherited;
  FTempFileName := ExtractFilePath(ParamStr(0)) + 'temp_merge_files.txt';
  ForceDeleteFile(FTempFileName);

  SrcStream := nil;
  DstStream := nil;
  OutStream := nil;
  try
    try
      SrcStream := TFileStream.Create(FSourceFileName, fmOpenRead or fmShareDenyNone);
      DstStream := TFileStream.Create(FDestinationFileName, fmOpenRead or fmShareDenyNone);
      OutStream := TFileStream.Create(FTempFileName, fmCreate);

      DstSize := DstStream.Size;
      SrcSize := SrcStream.Size;
      
      { Processa modo de intervalo de linhas }
      if (FFromLine > 0) and (FToLine > 0) and (FFromLine <= FToLine) then
      begin
        SrcStartOffset := GetSourceLineOffset(SrcStream, FFromLine);
        SrcEndOffset := GetSourceLineOffset(SrcStream, FToLine + 1);
        
        if SrcEndOffset <= 0 then
          SrcEndOffset := SrcSize; { Se ToLine for a ?ltima linha, usa o tamanho do arquivo }
        
        if SrcStartOffset < 0 then
          raise Exception.Create('Could not find source start line.');
        
        SrcRangeSize := SrcEndOffset - SrcStartOffset;
        if SrcRangeSize < 0 then
          SrcRangeSize := 0;
      end
      else
      begin
        { Modo normal: copia todo o arquivo de origem }
        SrcStartOffset := 0;
        SrcRangeSize := SrcSize;
      end;

      if FInsertOffset < 0 then FInsertOffset := 0;
      if FInsertOffset > DstSize then FInsertOffset := DstSize;

      Processed := 0;
      TotalToProcess := DstSize + SrcRangeSize;
      FCurrentPercent := 0;

      CopyRangeWithProgress(DstStream, OutStream, 0, FInsertOffset,
        Processed, TotalToProcess);
      CopyRangeWithProgress(SrcStream, OutStream, SrcStartOffset, SrcRangeSize,
        Processed, TotalToProcess);
      CopyRangeWithProgress(DstStream, OutStream, FInsertOffset,
        DstSize - FInsertOffset, Processed, TotalToProcess);

      FreeAndNil(OutStream);
      FreeAndNil(DstStream);
      FreeAndNil(SrcStream);

      if not ForceDeleteFile(FDestinationFileName) then
        raise Exception.Create('N?o foi poss?vel substituir o arquivo de destino.');

      if not RenameFile(FTempFileName, FDestinationFileName) then
        raise Exception.Create('N?o foi poss?vel finalizar a opera??o de renomea??o do arquivo mesclado.');

      FSuccess := True;
    except
      on E: Exception do
      begin
        FErrorMsg := E.Message;
        LogAsync(Format('Log_FastFile%s.txt', [FormatDateTime('ddmmyyyyhhnn', Now)]),
          '[Thread de Mesclagem de Arquivos] ' + E.Message);
        if Assigned(OutStream) then FreeAndNil(OutStream);
        if Assigned(DstStream) then FreeAndNil(DstStream);
        if Assigned(SrcStream) then FreeAndNil(SrcStream);
        Synchronize(SyncError);
      end;
    end;
  finally
    if Assigned(OutStream) then FreeAndNil(OutStream);
    if Assigned(DstStream) then FreeAndNil(DstStream);
    if Assigned(SrcStream) then FreeAndNil(SrcStream);
  end;
  Synchronize(FinishThread);
end;

{ ============================================================================ }
{ THREAD: SPLIT FILE INTO EQUAL PARTS (byte targets + LF boundaries)           }
{ ============================================================================ }

constructor TSplitEqualPartsThread.Create(const ASourceFileName: String;
  const APartCount: Integer; const AutoHide: Boolean = True;
  const ShowUI: Boolean = True);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSourceFileName := ASourceFileName;
  FPartCount := APartCount;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('Splitting file into equal parts...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  FSuccessOutputDir := '';
  FSuccessFirstPath := '';
  FSuccessLastPath := '';
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TSplitEqualPartsThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TSplitEqualPartsThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TSplitEqualPartsThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TSplitEqualPartsThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TSplitEqualPartsThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TSplitEqualPartsThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
end;

procedure TSplitEqualPartsThread.SyncFinish;
var
  TimeStr: String;
  Msg: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    TimeStr := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
    Msg := Format(TrText('SplitEqualParts.SuccessFormat'),
      [FPartCount, FSuccessOutputDir, FSuccessFirstPath, FSuccessLastPath, TimeStr]);
    Dialogs.ShowMessage(Msg);
    if Assigned(frmMain) then
      frmMain.mmTimer.Lines.Add(Format(TrText('SplitEqualParts.LogSummary'),
        [FPartCount, FSuccessOutputDir]));
  end
  else if FErrorMsg <> '' then
    Dialogs.ShowMessage(Format(TrText('SplitEqualParts.FailureFormat'), [FErrorMsg]))
  else
    Dialogs.ShowMessage(TrText('SplitEqualParts.CancelledOrIncomplete'));
end;

procedure TSplitEqualPartsThread.Execute;
const
  BUF_SIZE = 4 * 1024 * 1024;
  SCAN_BUF = 256 * 1024;

function ForceDeleteLocal(const FileName: string): Boolean;
var
  RetryCount: Integer;
begin
  Result := False;
  if not FileExists(FileName) then begin Result := True; Exit; end;
  for RetryCount := 1 to 10 do
  begin
    if DeleteFile(FileName) then
    begin
      Result := True;
      Break;
    end;
    Sleep(200);
  end;
end;

function OutputPartPath(const PartIndex1Based: Integer): String;
var
  DirPath, BaseName, ExtPart: String;
begin
  DirPath := ExtractFilePath(FSourceFileName);
  BaseName := ExtractFileName(FSourceFileName);
  ExtPart := ExtractFileExt(BaseName);
  BaseName := ChangeFileExt(BaseName, '');
  Result := IncludeTrailingPathDelimiter(DirPath) + BaseName +
    Format('.part%.3d', [PartIndex1Based]) + ExtPart;
end;

{ Primeiro LF em ou apos MinPos; retorna S se nao houver LF ate o fim. }
function FindLFEndAfter(InStr: TFileStream; const FileSize, MinPos: Int64): Int64;
var
  Buffer: array[0..SCAN_BUF - 1] of AnsiChar;
  BytesRead: Integer;
  Pos, StartRead: Int64;
  i: Integer;
begin
  Result := FileSize;
  if MinPos >= FileSize then Exit;

  Pos := MinPos;
  InStr.Seek(Pos, soFromBeginning);

  while Pos < FileSize do
  begin
    StartRead := Pos;
    BytesRead := InStr.Read(Buffer[0], SCAN_BUF);
    if BytesRead <= 0 then Break;

    for i := 0 to BytesRead - 1 do
    begin
      if Buffer[i] = #10 then
      begin
        Result := StartRead + i + 1;
        Exit;
      end;
    end;
    Inc(Pos, BytesRead);
  end;
end;

procedure CopyRangeProgress(InStr, OutStr: TFileStream; const StartPos, ByteCount: Int64;
  var Processed, TotalWork: Int64);
var
  Buffer: array of Byte;
  Remaining, ToRead: Int64;
  ReadBytes: Integer;
  NewPercent: Integer;
begin
  if ByteCount <= 0 then Exit;
  SetLength(Buffer, BUF_SIZE);
  Remaining := ByteCount;
  InStr.Seek(StartPos, soFromBeginning);

  while (Remaining > 0) and (not Terminated) do
  begin
    ToRead := Remaining;
    if ToRead > BUF_SIZE then
      ToRead := BUF_SIZE;

    ReadBytes := InStr.Read(Buffer[0], Integer(ToRead));
    if ReadBytes <= 0 then Break;

    OutStr.WriteBuffer(Buffer[0], ReadBytes);
    Dec(Remaining, ReadBytes);
    Inc(Processed, ReadBytes);

    if TotalWork > 0 then
    begin
      NewPercent := Round((Processed * 100.0) / TotalWork);
      if NewPercent > 100 then NewPercent := 100;
      if NewPercent > FCurrentPercent then
      begin
        FCurrentPercent := NewPercent;
        FPercentToSync := FCurrentPercent;
        Synchronize(SyncProgress);
      end;
    end;
  end;
end;

var
  InStream, OutStream: TFileStream;
  FileSize: Int64;
  Boundaries: array of Int64;
  k: Integer;
  ideal, prev, b: Int64;
  Processed, TotalWork: Int64;
  PartPath: String;
begin
  inherited;
  InStream := nil;
  OutStream := nil;
  SetLength(Boundaries, FPartCount + 1);

  try
    try
      InStream := TFileStream.Create(FSourceFileName, fmOpenRead or fmShareDenyNone);
      FileSize := InStream.Size;
      if FileSize <= 0 then
        raise Exception.Create(TrText('Source file is empty.'));

      Boundaries[0] := 0;
      Boundaries[FPartCount] := FileSize;
      prev := 0;
      FCurrentPercent := 0;

      for k := 1 to FPartCount - 1 do
      begin
        if Terminated then Exit;
        ideal := (Int64(k) * FileSize) div Int64(FPartCount);
        if ideal <= prev then
          ideal := prev + 1;
        if ideal >= FileSize then
          raise Exception.Create(TrText('Could not compute split boundaries: file too small for the requested number of parts.'));

        b := FindLFEndAfter(InStream, FileSize, ideal);
        while (b <= prev) and (b < FileSize) do
          b := FindLFEndAfter(InStream, FileSize, prev + 1);

        if b <= prev then
          raise Exception.Create(TrText('Could not compute split boundaries: not enough line breaks for the requested number of parts.'));

        Boundaries[k] := b;
        prev := b;
      end;

      if Boundaries[FPartCount - 1] >= FileSize then
        raise Exception.Create(TrText('Could not compute split boundaries: last part would be empty.'));

      TotalWork := FileSize;
      Processed := 0;

      for k := 0 to FPartCount - 1 do
      begin
        if Terminated then Exit;
        PartPath := OutputPartPath(k + 1);
        ForceDeleteLocal(PartPath);
        OutStream := TFileStream.Create(PartPath, fmCreate);
        try
          CopyRangeProgress(InStream, OutStream, Boundaries[k],
            Boundaries[k + 1] - Boundaries[k], Processed, TotalWork);
        finally
          FreeAndNil(OutStream);
        end;
      end;

      if (FileSize > 0) and (FCurrentPercent < 100) then
      begin
        FCurrentPercent := 100;
        FPercentToSync := 100;
        Synchronize(SyncProgress);
      end;

      FSuccessOutputDir := IncludeTrailingPathDelimiter(ExtractFilePath(FSourceFileName));
      FSuccessFirstPath := OutputPartPath(1);
      FSuccessLastPath := OutputPartPath(FPartCount);

      FreeAndNil(InStream);
      FSuccess := True;
    except
      on E: Exception do
      begin
        FErrorMsg := E.Message;
        LogAsync(Format('Log_FastFile%s.txt', [FormatDateTime('ddmmyyyyhhnn', Now)]),
          '[SplitEqualPartsThread] ' + E.Message);
        if Assigned(OutStream) then FreeAndNil(OutStream);
        if Assigned(InStream) then FreeAndNil(InStream);
        Synchronize(SyncError);
      end;
    end;
  finally
    if Assigned(OutStream) then FreeAndNil(OutStream);
    if Assigned(InStream) then FreeAndNil(InStream);
  end;
  Synchronize(SyncFinish);
end;

end.
