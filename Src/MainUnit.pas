unit MainUnit;
{$I sDefs.inc}
{$I DELPHIAREA.INC}
//{$DEFINE TESTTIME}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, ExtCtrls, ExtDlgs, ComCtrls, StdCtrls,
  FileCtrl, ImgList, Buttons, Menus, Mask, ActnList, StdActns, ToolWin, CheckLst, StopWatch, CommCtrl, Math, ClipBrd, ShellAPI, // XPMan,
  DB, Grids, DBGrids, DBCtrls, DSiWin32,
  DBClient, MidasLib,
  {$IFNDEF DELPHI5} Types, {$ENDIF}
  {$IFDEF DELPHI_XE2} UITypes, {$ENDIF}

  sSkinProvider, sSkinManager, sPanel, sScrollBox, sStatusBar, sGauge, sCheckbox, acImage, sBevel, sSpeedButton, sBitBtn, sSpinEdit, sComboBox,
  sDialogs, sMemo, sLabel, sComboBoxes, acTitleBar, sMaskEdit, sCustomComboEdit, sTooledit, acPageScroller, acntTypes, sTrackBar,
  sEdit, acMagn, sListBox, sComboEdit, acProgressBar, sButton, acAlphaImageList, acAlphaHints, acPNG, sPageControl, sSplitter, sGroupBox, acFloatCtrls,
  SyncObjs, UnitInt64List, IniFiles,
  UntFields, FindFile, MruHelper, UnConsts, UnConsumerDialog, uSmoothLoading, uDeltaEditor, uLineEditor, uExportDialog,
  uFindReplace, sListView, RichEdit;

type
  PAnsiCharMap = ^TAnsiCharMap;
  TAnsiCharMap = array[AnsiChar] of AnsiChar;

type
  TIntegerArray = array of Int64;

type
  TMergeFilesMode = (mfmBeginning, mfmAfterLine, mfmEnd, mfmLineRange);

type                                                                                    
  TFilterMatchMode = (fmmContains, fmmPrefix, fmmRegex);

type
  tpPositionStream = (psMiddleOfFile,psEndOfFile);
type
  tpLineEdit = (tpListViewLineEdit, tpCheckListBoxLineEdit);
type    
  TMouseWheelDirection = (mwdUp, mwdDown);
type
  TModifierKey = ssShift..ssCtrl;
  TModifierKeyState = set of TModifierKey;
type
  // Enum to define the icon position
  // "ia" prefix stands for Icon Alignment
  TIconAlignment = (iaLeft, iaRight);

const
  INFO_FILE_TIME = 'Filename: %s. Time to read: %s millisecs. Total lines: %d. Total Characters: %d';
  INFO_EDIT_TIME = 'Time to execute that operation: %s millisecs.';
  
  OUT_BUFFER_SIZE = 65536; // 64KB Buffer for high performance I/O
  INDEX_RECORD_SIZE = 20; 

const
  W_64: Word = 64; {Width of thumbnail in ICON view mode}
  H_64: Word = 64; {Height of thumbnail size}
  CheckWidth: Word = 14; {Width of check mark box}
  CheckHeight: Word = 14; {Height of checkmark}
  CheckBiasTop: Word = 2; {This aligns the checkbox to be in centered}
  CheckBiasLeft: Word = 3; {In the row of the list item display}
  MAX_LINE_LEN_DISPLAY = 256 * 1024; // 256 KB por linha na vista (linhas enormes nao travam a UI)

  { Windows Language ID constants (Delphi 7 compatibility) }
  LANG_PORTUGUESE = $16;
  LANG_SPANISH = $0A;
  LANG_FRENCH = $0C;
  LANG_GERMAN = $07;
  LANG_ITALIAN = $10;
  LANG_POLISH = $15;
  LANG_ROMANIAN = $18;
  LANG_HUNGARIAN = $0E;
  LANG_CZECH = $05;
  
  SUBLANG_PORTUGUESE = 2;
  SUBLANG_PORTUGUESE_BRAZILIAN = 1;

type
  TFFByteArray = array[0..$7FFFFFF] of Byte;
  PFFByteArray = ^TFFByteArray;

  TInt64DynArray = array of Int64;

  { Undo / Redo record }
  PUndoRecord = ^TUndoRecord;
  TUndoRecord = record
    Op: Integer;        // 0=Insert, 1=Edit, 2=Delete (maps to TOperationType)
    Line: Int64;
    OldContent: String; // conteudo antes da operacao
    NewContent: String; // conteudo depois da operacao
  end;

type
  ThvCriticalSection = class(TCriticalSection)
  private
    // see
    // http://delphitools.info/2011/11/30/fixing-tcriticalsection/
    // for an explanation why this should speed up execution on multi core systems
    FDummy: array[0..95] of Byte;
  public
    constructor Create;
  end;

type
  TProgressThread = class(TThread)
  private
    FTickEvent: THandle;
    cs: ThvCriticalSection;
    procedure FinishThreadExecution;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  end;

type
  TCheckBoxThread = class(TThread)
  private
    fHeaderCheckboxChecked: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const CreateSuspended: Boolean; const bHeaderCheckboxChecked: Boolean = True);
    destructor Destroy; override;
  end;

(* type
  TPostLineThread = class(TThread)
  private
    sw: TStopWatch;
    fProgressThread: TProgressThread;
  function TimerResult: string;
    procedure FinishThreadExecution;
  protected
    procedure Execute; override;
  public
    constructor Create(const CreateSuspended: Boolean);
    destructor Destroy; override;
  end;  *)

(*type
  TDeleteLineThread = class(TThread)
  private
    sw: TStopWatch;
    fProgressThread: TProgressThread;
  function TimerResult: string;
    procedure FinishThreadExecution;
  protected
    procedure Execute; override;
  public
    constructor Create(const CreateSuspended: Boolean);
    destructor Destroy; override;
  end; *)

type
  TCheckListBox = class(CheckLst.TCheckListBox)
  protected
    function DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

type
  TEdit = class(StdCtrls.TEdit)
  private
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
    procedure CMExit(var Message: TCMExit);   message CM_EXIT;
  end;

type
  TDBGrid = class(DBGrids.TDBGrid)
  private
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
  end;

type
  TMergeFilesDialogForm = class(TForm)
  private
    FSourceEdit: TsFilenameEdit;
    FSourceEditDefaultColor: TColor;
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    procedure HighlightDroppedSource;
  public
    procedure SetSourceEdit(const AEdit: TsFilenameEdit);
    procedure EnableFileDrop(const AEnabled: Boolean);
  end;

type
    TfrmMain = class(TForm)
    ImageList32: TsAlphaImageList;
    sAlphaImageList1: TsAlphaImageList;

    N1: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    A1: TMenuItem;
    S1: TMenuItem;
    S2: TMenuItem;
    Exit2: TMenuItem;
    File1: TMenuItem;
    Exit1: TMenuItem;
    About1: TMenuItem;
    Hints2: TMenuItem;
    Custom1: TMenuItem;
    Skinned3: TMenuItem;
    Skinned1: TMenuItem;
    Enabled1: TMenuItem;
    Skinned2: TMenuItem;
    Enabled2: TMenuItem;
    Disabled1: TMenuItem;
    Standard2: TMenuItem;
    Standard3: TMenuItem;
    Hintskind1: TMenuItem;
    Customhints1: TMenuItem;
    Skinnedhints1: TMenuItem;
    Hintsshowing1: TMenuItem;
    Builtinskins1: TMenuItem;
    Externalskins1: TMenuItem;
    Standarddlgsamples1: TMenuItem;
    miSelectSkindialog1: TMenuItem;

    ActionSkinned: TAction;
    ActionEnabled: TAction;
    ActionHintsStd: TAction;
    ActionCloseForm: TAction;
    ActionAnimation: TAction;
    ActionHintsCustom: TAction;
    ActionHintsDisable: TAction;
    ActionHintsSkinned: TAction;

    sStatusBar1: TsStatusBar;
    MainMenu1: TMainMenu;

    sMenuTab: TsTabSheet;
    sTabSheet2: TsTabSheet;
    sTabSheet3: TsTabSheet;

    sSpeedButton9:  TsSpeedButton;
    btnShowTabFindFile: TsSpeedButton;
    btnSplash: TsSpeedButton;
    sSpeedButton1:  TsSpeedButton;
    sSpeedButton5:  TsSpeedButton;
    btnClose: TsSpeedButton;
    sSpeedButton3:  TsSpeedButton;
    sSpeedButton6:  TsSpeedButton;
    sPanel2: TsPanel;
    sPanel6: TsPanel;
    sPanel3: TsPanel;
    sPanel5: TsPanel;
    PanelToolButtons: TsPanel;

    sSkinProvider1: TsSkinProvider;
    PopupMenu1: TPopupMenu;
    MainActionList: TActionList;
    ActionClose: TWindowClose;
    sMagnifier1: TsMagnifier;
    sPageControl1: TsPageControl;
    PopupDialogs: TPopupMenu;
    sTitleBar1: TsTitleBar;
    sImage1: TsImage;
    sPageScroller1: TsPageScroller;
    sAlphaHints1: TsAlphaHints;
    sVirtualImageList1: TsVirtualImageList;
    CharImageList16: TsCharImageList;
    C1: TMenuItem;
    sWebLabel9: TsWebLabel;
    sWebLabel10: TsWebLabel;
    sWebLabel11: TsWebLabel;
    sWebLabel12: TsWebLabel;
    sFloatSample: TsFloatButtons;
    sFloatSampleClose: TsFloatButtons;
    sSpeedButton7: TsSpeedButton;
    sSpeedButton10: TsSpeedButton;
    CharImageList32: TsCharImageList;
    sStickyLabel9:  TsStickyLabel;
    sStickyLabel10: TsStickyLabel;
    sStickyLabel11: TsStickyLabel;
    sStickyLabel12: TsStickyLabel;
    PopupPPIMenu: TPopupMenu;
    N71: TMenuItem;
    N81: TMenuItem;
    N82: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    N13: TMenuItem;
    N14: TMenuItem;
    N15: TMenuItem;
    N16: TMenuItem;
    N17: TMenuItem;
    N18: TMenuItem;
    N21: TMenuItem;
    N22: TMenuItem;
    N23: TMenuItem;
    N24: TMenuItem;
    N25: TMenuItem;
    N31: TMenuItem;
    sSpeedButton11: TsSpeedButton;
    btnShowTabReadFile: TsSpeedButton;
    ActionReadFile: TAction;
    N2: TMenuItem;
    mnSelectSkin: TMenuItem;
    mnRandomSkin: TMenuItem;
    N6: TMenuItem;
    mnShowHints: TMenuItem;
    N7: TMenuItem;
    ActionSelectSkin: TAction;
    ActionRandomSkin: TAction;
    ActionShowHints: TAction;
    pgMain: TsPageControl;
    tabReadFile: TsTabSheet;
    pnlTop: TsPanel;
    pnlMain: TsPanel;
    sSplitter1: TsSplitter;
    pnlFileButtons: TsPanel;
    tabSplitFile: TsTabSheet;
    ProgressImages: TImageList;
    pnlTop1: TsPanel;
    sPanel8: TsPanel;
    sSplitter4: TsSplitter;
    pnlCheck: TsPanel;
    splPnlCheck: TsSplitter;
    chCheckedAll: TsCheckBox;
    edtFileName: TsFilenameEdit;
    ImageList1: TImageList;
    sSpeedButton13: TsSpeedButton;
    popupmenuListView: TPopupMenu;
    ActionCheckBoxesListView: TAction;
    ActionExportToClipBrd: TAction;
    ActionExportToFile: TAction;
    pnlCenter: TsPanel;
    splListview: TsSplitter;
    ActionSearch: TAction;
    sPanel1: TsPanel;
    SpeedBtnPPI: TsSpeedButton;
    sSkinSelector1: TsSkinSelector;
    sSpeedButton14: TsSpeedButton;
    sSpeedButton15: TsSpeedButton;
    sSpeedButton16: TsSpeedButton;
    R1: TMenuItem;
    M1: TMenuItem;
    Button1: TButton;
    Button2: TButton;
    tabExportedLines: TsTabSheet;
    sPanel14: TsPanel;
    pnlExportedLines: TsPanel;
    sPanel16: TsPanel;
    memoExportedLines: TsMemo;
    sSpeedButton18: TsSpeedButton;
    sSplitter9: TsSplitter;
    sSpeedButton19: TsSpeedButton;
    sBitBtn2: TsBitBtn;
    sButton1: TsButton;
    btnReturnRead: TsBitBtn;
    ActionDelete: TAction;
    sSplitter12: TsSplitter;
    Button3: TButton;
    progressBar: TsProgressBar;
    Image1: TImage;
    sButton2: TsButton;
    sButton3: TsButton;
    btnEmptyInputFile: TsSpeedButton;
    ActionWrite: TAction;
    sListBox1: TsListBox;
    pnlFile: TsPanel;
    sPanel10: TsPanel;
    btnSaveChunkFile: TsSpeedButton;
    sSpeedButton22: TsSpeedButton;
    sSplitter16: TsSplitter;
    sPanel12: TsPanel;
    dbgFile: TDBGrid;
    dsFile: TDataSource;
    DBNavigator1: TDBNavigator;
    sSpeedButton2: TsSpeedButton;
    sSpeedButton20: TsSpeedButton;
    clFiles: TClientDataSet;
    clFilesID: TIntegerField;
    clFilesFilename: TStringField;
    clFilesFileSize: TStringField;
    clFilesSourceLine: TStringField;
    clFilesTargetLine: TStringField;
    dsFiles: TDataSource;
    pnlTopButtons: TsPanel;
    edtSearch: TEdit;
    btnSearch: TsSpeedButton;
    btnUp: TsSpeedButton;
    btnDown: TsSpeedButton;
    edtGoToLine: TsComboEdit;
    lblTimeDesc: TsLabel;
    lblInfoFileTime: TsLabel;
    sPageControl2: TsPageControl;
    sTabSheet4: TsTabSheet;
    sTabSheet5: TsTabSheet;
    sPageScroller2: TsPageScroller;
    pnlButtons: TsPanel;
    sSpeedButton38: TsSpeedButton;
    sPanel7: TsPanel;
    btnRead: TsSpeedButton;
    btnClear: TsSpeedButton;
    btnDeleteLines: TsSpeedButton;
    btnSplitFiles: TsSpeedButton;
    btnMergeMultipleLines: TsSpeedButton;
    btnEditFile: TsSpeedButton;
    btnCheckBoxes: TsSpeedButton;
    btnExport: TsSpeedButton;
    btnReturn: TsSpeedButton;
    pnlLoading: TsPanel;
    ProgressImagePanelFile: TPanel;
    ProgressImageFile: TImage;
    PopupMenu2: TPopupMenu;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem23: TMenuItem;
    pgcSplitFiles: TsPageControl;
    tabSplitByLines: TsTabSheet;
    tabSplitByFiles: TsTabSheet;
    ActionSplitFile: TAction;
    pnlSplitMain: TsPanel;
    gbxInfoFileSplit: TsGroupBox;
    lblFileName: TsLabel;
    lblFileNameValue: TsLabel;
    lblFileDtCreation: TsLabel;
    lblFileDtCreationValue: TsLabel;
    lblTotalCharacters: TsLabel;
    lblTotalLines: TsLabel;
    lblTotalLinesValue: TsLabel;
    lblTotalCharactersValue: TsLabel;
    pnlSplitByLines: TsPanel;
    gbxSplitByLines: TsGroupBox;
    lblFromSplitByLine: TsLabel;
    lblToSplitByLine: TsLabel;
    btnExecuteSplitFileByLines: TsSpeedButton;
    spnFromSplitByLine: TsSpinEdit;
    spnToSplitByLine: TsSpinEdit;
    edtOutputSplitByLineText: TsFilenameEdit;
    pnlSplitByFiles: TsPanel;
    gbxSplitByFiles: TsGroupBox;
    sSplitter24: TsSplitter;
    pnlGridSplitFile: TsPanel;
    dbgFiles: TDBGrid;
    pnlTopSplitFile: TsPanel;
    sSplitter23: TsSplitter;
    pnlTrackBarSplitFile: TsPanel;
    trkFiles: TsTrackBar;
    pnlTrackBarValueSplitFile: TsPanel;
    lblTrackBarFileInfoSplitFile: TsLabel;
    lblTrackBarFileValueSplitFile: TsLabel;
    pnlExecuteButtonSplitFile: TsPanel;
    btnExecuteSplitFileByFiles: TsSpeedButton;
    ActionClear: TAction;
    tabFindFiles: TsTabSheet;
    ProgressImageTimer: TTimer;
    FindFile: TFindFile;
    PopupMenu: TPopupMenu;
    OpenFileItem: TMenuItem;
    OpenFileLocationItem: TMenuItem;
    dsFoldersExclude: TDataSource;
    StatusBar: TStatusBar;
    pnlBottomFindFiles: TsPanel;
    pnlLeftFindFiles: TsPanel;
    pnlMain2FindFile: TsPanel;
    sSplitter2: TsSplitter;
    pnlButtonFindFile: TsPanel;
    FindButton: TButton;
    pnlButtonStopFindFile: TsPanel;
    StopButton: TButton;
    pnlMainFindFile: TsPanel;
    Threaded: TCheckBox;
    ProgressImagePanel: TPanel;
    ProgressImage: TImage;
    pgFindFiles: TPageControl;
    tabFindFilesName: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    FileName: TEdit;
    Location: TEdit;
    Subfolders: TCheckBox;
    Phrase: TEdit;
    CaseSenstitive: TCheckBox;
    WholeWord: TCheckBox;
    Negate: TCheckBox;
    tabFoldersExclude: TTabSheet;
    pnlFoldersExcludeMain: TPanel;
    Splitter1: TSplitter;
    pnlFoldersExcludeTop: TPanel;
    dbgFoldersExclude: TDBGrid;
    pnlFoldersExcludeBottom: TPanel;
    btnSaveFoldersExclude: TButton;
    btnDeleteFoldersExclude: TButton;
    TabSheet3: TTabSheet;
    PageControl1: TPageControl;
    TabSheet4: TTabSheet;
    CreatedBeforeDate: TDateTimePicker;
    CreatedAfterDate: TDateTimePicker;
    CreatedBeforeTime: TDateTimePicker;
    CreatedAfterTime: TDateTimePicker;
    CBD: TCheckBox;
    CBT: TCheckBox;
    CAD: TCheckBox;
    CAT: TCheckBox;
    TabSheet5: TTabSheet;
    ModifiedBeforeDate: TDateTimePicker;
    ModifiedAfterDate: TDateTimePicker;
    ModifiedBeforeTime: TDateTimePicker;
    ModifiedAfterTime: TDateTimePicker;
    MBD: TCheckBox;
    MBT: TCheckBox;
    MAD: TCheckBox;
    MAT: TCheckBox;
    TabSheet6: TTabSheet;
    AccessedBeforeDate: TDateTimePicker;
    AccessedAfterDate: TDateTimePicker;
    AccessedBeforeTime: TDateTimePicker;
    AccessedAfterTime: TDateTimePicker;
    ABD: TCheckBox;
    ABT: TCheckBox;
    AAD: TCheckBox;
    AAT: TCheckBox;
    TabSheet2: TTabSheet;
    Attributes: TGroupBox;
    System: TCheckBox;
    Hidden: TCheckBox;
    Readonly: TCheckBox;
    Archive: TCheckBox;
    Directory: TCheckBox;
    Compressed: TCheckBox;
    Encrypted: TCheckBox;
    Offline: TCheckBox;
    SparseFile: TCheckBox;
    ReparsePoint: TCheckBox;
    Temporary: TCheckBox;
    Device: TCheckBox;
    Normal: TCheckBox;
    NotContentIndexed: TCheckBox;
    Virtual: TCheckBox;
    FileSize: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    SizeMaxEdit: TEdit;
    SizeMinEdit: TEdit;
    SizeMin: TUpDown;
    SizeMax: TUpDown;
    SizeMinUnit: TComboBox;
    SizeMaxUnit: TComboBox;
    sSplitter3: TsSplitter;
    FoundFiles: TsListView;
    sSplitter6: TsSplitter;
    pnlFilesExcludeTop: TsPanel;
    dbgFilesExclude: TDBGrid;
    dsFilesExclude: TDataSource;
    clFilesExclude: TClientDataSet;
    clFilesExcludeFile: TStringField;
    clFilesExcludeStatus: TBooleanField;
    clFilesExcludeFileExclude: TStringField;
    clFolders: TClientDataSet;
    clFoldersFolder: TStringField;
    btnImportExtensionFiles: TsButton;
    btnImportListFiles: TsButton;
    btnSaveFilesExclude: TButton;
    btnDeleteFilesExclude: TButton;
    pnlFoldersButton: TsPanel;
    pnlFilesButton: TsPanel;
    dbnFolders: TDBNavigator;
    dbnFiles: TDBNavigator;
    sButton4: TsButton;
    btnConsumerAI: TsSpeedButton;
    btnHelp: TsSpeedButton;
    mmTimer: TsMemo;
    ListView1: TListView;
    ScrollBarVertical: TScrollBar;
    ScrollBarHorizontal: TScrollBar;
    SaveDialog1: TSaveDialog;
    tmrTail: TTimer;
    pnlReadToolbarOptions: TsPanel;
    chkWordWrap: TCheckBox;
    chkSegmentedHeavyOps: TsCheckBox;
    comboViewEncoding: TComboBox;
    comboZoom: TComboBox;
    comboLanguage: TComboBox;

    procedure FormCreate                (Sender: TObject);
    procedure FormShow                  (Sender: TObject);
    procedure sSpeedButton1Click        (Sender: TObject);
    procedure SkinMenuClick             (Sender: TObject);
    procedure ActionSkinnedExecute      (Sender: TObject);
    procedure ActionCloseExecute        (Sender: TObject);
    procedure ActionAnimationExecute    (Sender: TObject);

    procedure ActionHintsSkinnedExecute (Sender: TObject);
    procedure ActionHintsCustomExecute  (Sender: TObject);
    procedure ActionHintsDisableExecute (Sender: TObject);
    procedure ActionHintsStdExecute     (Sender: TObject);

    procedure miOpenDialog1Click        (Sender: TObject);
    procedure miSaveDialog1Click        (Sender: TObject);
    procedure miOpenPictureDialog1Click (Sender: TObject);
    procedure miSavePictureDialog1Click (Sender: TObject);
    procedure miColorDialog1Click       (Sender: TObject);
    procedure miPrintDialog1Click       (Sender: TObject);
    procedure miPrinterSetupDialog1Click(Sender: TObject);
    procedure miFindDialog1Click        (Sender: TObject);
    procedure miReplaceDialog1Click     (Sender: TObject);
    procedure miAlphaColorDialog1Click  (Sender: TObject);
    procedure sMagnifier1DblClick       (Sender: TObject);
    procedure ActionCloseFormExecute    (Sender: TObject);
    procedure sSpeedButton5Click        (Sender: TObject);
    procedure btnCloseClick        (Sender: TObject);
    procedure sTitleBar1Items0Click     (Sender: TObject);
    procedure sSpeedButton9Click        (Sender: TObject);
    procedure miSysDialogsClick         (Sender: TObject);
    procedure sTitleBar1Items10Click    (Sender: TObject);
    procedure sSkinManager1BeforeChange (Sender: TObject);
    procedure sTitleBar1Items13Click    (Sender: TObject);
    procedure sSkinManager1ScaleChanged (Sender: TObject);
    procedure sTitleBar1Items4Click     (Sender: TObject);
    procedure C1Click                   (Sender: TObject);
    procedure sBitBtn1Click             (Sender: TObject);
    procedure sSpeedButton7Click        (Sender: TObject);
    procedure sSpeedButton10Click       (Sender: TObject);
    procedure sFloatSampleCloseItems0Click(Sender: TObject);
    procedure sFloatSampleItems0MouseEnter(Sender: TObject);
    procedure sFloatSampleItems0MouseLeave(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sStatusBar1DrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
    procedure sSkinManager1GetPopupItemData(Item: TMenuItem; State: TOwnerDrawState; ItemData: TacMenuItemData);
    procedure sAlphaHints1ShowHint(var HintStr: string; var CanShow: Boolean; var HintInfo: THintInfo; var Frame: TFrame);
    procedure sSkinManager1GetMenuExtraLineData(FirstItem: TMenuItem; var SkinSection, Caption: string; var Glyph: TBitmap; var LineVisible: Boolean);
    procedure sMagnifier1GetSourceCoords(var ATopLeft: TPoint);
    procedure sSkinManager1FontChanged(Sender: TObject; const DefOldFontName, FontName: string);
    procedure sBitBtn1GetColoring(Sender: TObject; State: Integer; var Coloring: TacColoring);
    procedure sFloatSampleCloseItems0MouseLeave(Sender: TObject);
    procedure N71Click(Sender: TObject);
    procedure sTitleBar1Items15Click(Sender: TObject);
    procedure SpeedBtnPPIClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure btnShowTabReadFileClick(Sender: TObject);
    procedure miVersionHistoryClick(Sender: TObject);
    procedure ActionReadFileExecute(Sender: TObject);
    procedure ActionSelectSkinExecute(Sender: TObject);
    procedure mnSelectSkinClick(Sender: TObject);
    procedure ActionRandomSkinExecute(Sender: TObject);
    procedure btnSplashClick(Sender: TObject);
    procedure mnRandomSkinClick(Sender: TObject);
    procedure ActionShowHintsExecute(Sender: TObject);
    procedure mnShowHintsClick(Sender: TObject);
    procedure btnReturnReadClick(Sender: TObject);
    procedure chkWordWrapClick(Sender: TObject);
    procedure chkSegmentedHeavyOpsClick(Sender: TObject);
    procedure comboViewEncodingChange(Sender: TObject);
    procedure comboZoomChange(Sender: TObject);
    procedure comboLanguageChange(Sender: TObject);
    //procedure fListViewDblClick(Sender: TObject);
    procedure FormMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ScrollBarVerticalChange(Sender: TObject);
    procedure ScrollBarVerticalScroll(Sender: TObject;
      ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure ScrollBarHorizontalChange(Sender: TObject);
    procedure ScrollBarHorizontalScroll(Sender: TObject;
      ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure ListView1Resize(Sender: TObject);
    //procedure ListView1_Data(Sender: TObject; Item: TListItem);
    function getLineContentsFromLineIndex(const iLine: int64): string;
    procedure FormDestroy(Sender: TObject);
    procedure chCheckedAllClick(Sender: TObject);
    procedure ActionCheckBoxesListViewExecute(Sender: TObject);
    procedure tbCheckBoxClick(Sender: TObject);
    procedure tbExportToClipBrdClick(Sender: TObject);
    procedure tbExportToFileClick(Sender: TObject);
    procedure ActionExportToClipBrdExecute(Sender: TObject);
    procedure ActionExportToFileExecute(Sender: TObject);
    procedure CheckListBox1ClickCheck(Sender: TObject);
    procedure CheckListBox1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CheckListBox1DblClick(Sender: TObject);
    procedure CheckListBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CheckListBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure CheckListBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ToolButton37Click(Sender: TObject);
    procedure ActionSearchExecute(Sender: TObject);
    procedure sComboEdit1ButtonClick(Sender: TObject);
    procedure sBitBtn2Click(Sender: TObject);
    procedure sBitBtn3Click(Sender: TObject);
    procedure edtGoToLineButtonClick(Sender: TObject);
    procedure CheckListBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; DrawState: TOwnerDrawState);
    { Area de texto para wrap no TCheckListBox (modo Select): largura = ClientWidth, nao ItemRect. }
    function CheckListBoxWordWrapTextRect(CLB: TCheckListBox; const ItemRect: TRect): TRect;
    procedure R1Click(Sender: TObject);
    procedure M1Click(Sender: TObject);
    procedure btnReturnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnReadClick(Sender: TObject);
    procedure edtFileNameKeyPress(Sender: TObject; var Key: Char);
    procedure sSpeedButton18Click(Sender: TObject);
    procedure sSpeedButton19Click(Sender: TObject);
    procedure edtSearchKeyPress(Sender: TObject; var Key: Char);
    procedure btnShowSearchPanelClick(Sender: TObject);
    procedure btnCheckBoxesClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnDeleteLinesClick(Sender: TObject);
    procedure AboutOpening(Sender: TObject);
    procedure ActionDeleteExecute(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure sButton3Click(Sender: TObject);
    procedure btnEmptyInputFileClick(Sender: TObject);
    procedure ActionWriteExecute(Sender: TObject);
    procedure sListBox1Click(Sender: TObject);
    procedure sListBox1Exit(Sender: TObject);
    procedure btnMergeFileClick(Sender: TObject);
    procedure dbgFileDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure btnSearchClick(Sender: TObject);
    procedure btnExecuteSplitFileByLinesClick(Sender: TObject);
    procedure btnExecuteSplitFileByFilesClick(Sender: TObject);
    procedure trkFilesChange(Sender: TObject);
    procedure dbgFilesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure pgMainCloseBtnClick(Sender: TComponent; TabIndex: Integer;
      var CanClose: Boolean; var Action: TacCloseAction);
    procedure MenuItem2Click(Sender: TObject);
    procedure ActionSplitFileExecute(Sender: TObject);
    procedure btnSplitFilesClick(Sender: TObject);
    procedure btnMergeMultipleLinesClick(Sender: TObject);
    procedure tabSplitFileShow(Sender: TObject);
    procedure ActionClearExecute(Sender: TObject);
    procedure FindButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure FindFileSearchBegin(Sender: TObject);
    procedure FindFileSearchFinish(Sender: TObject);
    procedure FindFileFolderChange(Sender: TObject; const Folder: String;
      var IgnoreFolder: TFolderIgnore);
    procedure FindFileFileMatch(Sender: TObject;
      const FileInfo: TFileDetails);
    procedure FoundFilesColumnClick(Sender: TObject; Column: TListColumn);
    procedure FoundFilesCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure FoundFilesDblClick(Sender: TObject);
    procedure OpenFileItemClick(Sender: TObject);
    procedure OpenFileLocationItemClick(Sender: TObject);
    procedure PopupMenuPopup(Sender: TObject);
    procedure CBDClick(Sender: TObject);
    procedure CBTClick(Sender: TObject);
    procedure CADClick(Sender: TObject);
    procedure CATClick(Sender: TObject);
    procedure MBDClick(Sender: TObject);
    procedure MBTClick(Sender: TObject);
    procedure MADClick(Sender: TObject);
    procedure MATClick(Sender: TObject);
    procedure ABDClick(Sender: TObject);
    procedure ABTClick(Sender: TObject);
    procedure AADClick(Sender: TObject);
    procedure AATClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ProgressImageTimerTimer(Sender: TObject);
    procedure btnSaveFoldersExcludeClick(Sender: TObject);
    procedure btnDeleteFoldersExcludeClick(Sender: TObject);
    procedure btnShowTabFindFileClick(Sender: TObject);
    procedure tabFindFilesShow(Sender: TObject);
    procedure dbgFilesExcludeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dbgFoldersExcludeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnImportExtensionFilesClick(Sender: TObject);
    procedure btnImportListFilesClick(Sender: TObject);
    procedure btnSaveFilesExcludeClick(Sender: TObject);
    procedure btnDeleteFilesExcludeClick(Sender: TObject);
    procedure dbnFoldersClick(Sender: TObject; Button: TNavigateBtn);
    procedure dbnFilesClick(Sender: TObject; Button: TNavigateBtn);
    procedure sButton4Click(Sender: TObject);
    procedure sStatusBar1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure sStatusBar1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnConsumerAIClick(Sender: TObject);
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure ListView1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ListView1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure btnEditFileClick(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure tmrTailTimer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BtnHelpClick(Sender: TObject);
  private
    Offset: Int64;
    ItemCount: Int64;
    VisibleItems: Int64;
    FSourceFileStream: TFileStream;
    FIndexFileStream: TFileStream;
    ListEdit: TEdit;
    listBoxIndex: Integer;
    goToLineSelected: Int64;
    Folders: Integer;
    StartTime: DWord;
    SortedColumn: Integer;
    Descending: Boolean;
    // Variable to store the current alignment state
    FCurrentIconAlignment: TIconAlignment;
    //vertical selection
    FHasSelection: Boolean;
    FIsDragging: Boolean;     
    FBlockStartPoint: TPoint; 
    FBlockEndPoint: TPoint;   
    
    FCharWidth: Integer;
    FLineHeight: Integer;
    
    // HOOK PARA O DESENHO
    FOldListViewWndProc: TWndMethod;

    // ==== BUSCA (nao bloqueia UI) ====
    FFindText: string;
    FFindCaseSensitive: Boolean;
    FFindAutoRetry: Boolean;
    FLastFindDirection: Integer;
    FLastFoundLine: Integer;
    FLastFoundFilePos: Int64;
    FLastFoundCol: Integer;
    FLastFoundMatchLen: Integer;
    FFindThread: TThread;
    FFindSearchId: Integer;   // generation counter to discard stale results

    { StatusBar cache }
    FLastStatusLine: Int64;
    FLastStatusCount: Int64;
    FTrLineColFormat: string;
    FTrLineColZero: string;
    FTrLinesFormat: string;
    FTrDetectedOnFile: string;
    FTrListViewUses: string;
    FTrNoRereadDefault: string;
    FTrNoRereadForced: string;
    FTrDefaultViewSuffix: string;
    { Tamanho inicial da fonte da ListView (pt) para percentagem no painel Zoom (Ctrl+roda). }
    FListViewZoomBaseFontSize: Integer;
    FUpdatingZoomCombo: Boolean;
    { Historico curto de zoom via roda (mostra no combo sem apagar itens existentes). }
    FZoomWheelHistory: TStringList;
    FLastZoomComboUpdateTick: DWORD;
    { Shift+click na checklist: ancora da ultima linha marcada (1-based em Items.Objects). }
    FChecklistAnchorLine: Int64;
    FUpdatingChecklistChecks: Boolean;

    { Encoding Detection }
    FDetectedEncoding: String;
    { Modo somente leitura (sessao): bloqueia escrita no ficheiro aberto na aba Read. }
    FFileSessionReadOnly: Boolean;
    FMenuReadOnlyItem: TMenuItem;
    FPopupLVReadOnlyItem: TMenuItem;
    FMenuSegmentedHeavyOpsItem: TMenuItem;
    FPopupLVSegmentedHeavyOpsItem: TMenuItem;
    { Itens extra no Tools (title bar / PopupMenu1), antes do separador final. }
    FToolsExtrasSep: TMenuItem;
    FToolsExtrasWordWrap: TMenuItem;
    FToolsExtrasReadOnly: TMenuItem;
    FToolsExtrasSegmented: TMenuItem;
    FToolsExtrasTail: TMenuItem;
    FToolsExtrasFilter: TMenuItem;
    FToolsExtrasExportFiltered: TMenuItem;
    FToolsExtrasToggleBookmark: TMenuItem;
    FToolsExtrasNextBookmark: TMenuItem;
    FToolsExtrasPrevBookmark: TMenuItem;
    FToolsExtrasClearBookmarks: TMenuItem;
    FUpdatingViewEncodingCombo: Boolean;
    FUpdatingLanguageCombo: Boolean;
    FApplyingLanguage: Boolean;
    FLanguageAppliedOnce: Boolean;
    { Popup do ListView: reconstruido lazily na primeira abertura apos troca de idioma. }
    FListViewPopupDirty: Boolean;
    { WM_COMMAND na status bar (pai do combo): CBN_CLOSEUP atualiza a lista mesmo se OnChange nao disparar (skin / mesmo item). }
    FOldStatusBarWndProcForCombo: TWndMethod;
    FHookedStatusBarForViewEncoding: Boolean;

    { Undo / Redo }
    FUndoStack: TList;
    FRedoStack: TList;

    { Tail / Follow Mode }
    FTailActive: Boolean;
    FTailLastFileSize: Int64;
    FTailLastLineCount: Int64;

    { Filter / Grep Visual }
    FFilterActive: Boolean;
    FFilterBits: PFFByteArray;    // bitset: 1 bit per line
    FFilterBitsSize: Integer;     // bytes allocated for FFilterBits
    FFilteredCount: Int64;        // number of lines that passed filter
    FFilterTotalLines: Int64;     // total lines when filter was applied
    FFilterJumpTable: TInt64DynArray; // jump table: every 1024th filtered line -> real line index
    FFilterThread: TThread;
    FFilterText: String;
    { Ctrl+F com filtro: saltar ocorrencias fora do bitset ate um maximo (evita loop infinito). }
    FFilterFindSkips: Integer;
    { Evita executar o mesmo atalho duas vezes (Form KeyPreview + controle focado). }
    FHandlingReadShortcut: Boolean;

    { Bookmarks }
    FBookmarks: TList;  // sorted list of real line indices (stored as Pointer)

    { Recent Files }
    FRecentFiles: TStringList;
    FRecentFilesIni: String;
    FpmRecentFiles: TPopupMenu;

    // Line content cache (avoids repeated file seeks for same page)
    FCacheOffset: Int64;
    FCacheLines: array of String;
    FCacheCount: Integer;

    { Word wrap visual (sem reindexar): altura da linha via SmallImages + DrawText na coluna Content }
    FFastVisualWordWrap: Boolean;
    FWordWrapRowImages: TImageList;
    { Bitmap icons loaded from Resources\trichviewicons for menu bindings. }
    FMenuBitmapImages: TImageList;
    FMenuIconIndexByName: TStringList;
    { Dynamic AI side panel shown beside the ListView. }
    FConsumerAIPanel: TsPanel;
    FConsumerAIHeaderPanel: TsPanel;
    FConsumerAIExportButton: TsSpeedButton;
    FConsumerAIClearButton: TsSpeedButton;
    FConsumerAIRestartButton: TsSpeedButton;
    FConsumerAICloseButton: TsSpeedButton;
    FConsumerAITitleLabel: TsLabel;
    FConsumerAIMemo: TRichEdit;
    FConsumerAIPopupMenu: TPopupMenu;
    FConsumerAIPopupSelectAllItem: TMenuItem;
    FConsumerAIPopupCopyItem: TMenuItem;
    FConsumerAIPopupExportItem: TMenuItem;
    FConsumerAIInputPanel: TsPanel;
    FConsumerAIOptionsPanel: TsPanel;
    FConsumerAIInputEdit: TEdit;
    FConsumerAISendButton: TsSpeedButton;
    FConsumerAIStatusLabel: TsLabel;
    FConsumerAIStdInWrite: THandle;
    FConsumerAIStdOutRead: THandle;
    FConsumerAIProcessInfo: TProcessInformation;
    FConsumerAIReaderThread: TThread;
    FConsumerAIProcessRunning: Boolean;
    FConsumerAIActiveFileName: string;
    FConsumerAILastPrompt: string;
    FToolbarOverflowButton: TsSpeedButton;
    FToolbarOverflowPopup: TPopupMenu;
    { CM_RECREATEWND adiado se Word Wrap OFF foi aplicado com ListView oculta (modo checklist). }
    FDeferredListViewRecreateForRowHeight: Boolean;
    { Evita enfileirar refreshes duplicados da checklist (Ctrl+W / word-wrap no modo Select). }
    FChecklistRefreshPending: Boolean;
    { Snapshot do ficheiro no disco apos leitura (detetar alteracao externa antes de gravar). }
    FOpenDiskSnapValid: Boolean;
    FOpenDiskSnapPath: string;
    FOpenDiskSnapSize: Int64;
    FOpenDiskSnapWrite: TFileTime;

    { Cached popup menu items for ListView context menu state sync. }
    FPopupLVSelectItem: TMenuItem;
    FPopupLVWordWrapItem: TMenuItem;

    function EffectiveDisplayEncoding: string;
    procedure ApplyViewEncodingRefresh;
    procedure HookedStatusBarWndProcForCombo(var Message: TMessage);
    procedure HookedListViewWndProc(var Message: TMessage);
    { Ctrl + roda do rato sobre a ListView: zoom da fonte (menos = scroll up, mais = scroll down). }
    procedure ApplyListViewWheelZoom(const WheelDelta: Integer);
    procedure RememberWheelZoomInCombo(const APct: Integer; const AForce: Boolean = False);
    procedure DrawSelectionRect;
    procedure InvalidateLineCache;
    procedure EnsureLineCacheForPage;
    procedure UpdateListViewWordWrapUi;
    procedure ApplyWordWrapRowHeight;
    procedure UpdateExternalScrollBarsForWordWrap;
    procedure DrawFindHighlightForListCell(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; const SubItemIndex: Integer);
    // Helpers
    procedure SelectListViewItem(const Idx: Integer);
    procedure OpenFileStreams(const AFileName: String);

    function GetRowIndexAt(X, Y: Integer): Integer;
    procedure CalculateFontMetrics;
    { Altura de linha da ListView (com ou sem word wrap visual) para o modo Select / TCheckListBox. }
    function ListViewVisualRowHeight: Integer;
    //vertical selection
    procedure CopyVerticalSelectionToClipboard;
    function IsClickInFirstColumn(X: Integer): Boolean;
    procedure CopyMultiSelectionToClipboard;
    { Indice 0-based da linha no ficheiro: sem filtro = Offset+RowIdx; com filtro = FilteredIndexToReal(RowIdx). }
    function FileLineIndexFromListRow(const RowIdx: Integer): Integer;
    procedure CopyFileLineToClipboard(const LineIdx: Integer);
    procedure CopyChecklistVerticalSelectionToClipboard;
    procedure CopyCheckedChecklistLinesToClipboard;
    procedure CopyListViewFocusedLineToClipboard;
    procedure ListEditKeyPress(Sender: TObject; var Key: Char); 
    procedure ShowTab(const tabSheet: TsTabSheet(*; const showOtherTabs: Boolean = False*));
    procedure HideTabs(const showOtherTabs: Boolean = False);
    procedure InitializeLanguage;
    procedure ApplyCurrentLanguage;
    procedure RefreshLanguageRuntimeCache;
    procedure SyncLanguageComboWithCurrent;
    procedure LocalizeMenuItem(const AComponentName, ATranslationKey, ADefaultCaption: string);
    procedure LocalizeTopToolbar;
    procedure BuildMenuBitmapImageList;
    procedure ApplySkinRelatedPopupMenuIcons;
    procedure EnsureToolsPopupFastFileExtras;
    procedure EnsureToolsPopupBookmarkExtras;
    procedure UpdateToolsPopupFastFileExtrasCaptions;
    function ResolveMenuBitmapDir: string;
    function MenuIconIndex(const AFileName: string; const AFallbackIndex: Integer = -1): Integer;
    procedure EnsureConsumerAIPanel;
    procedure ShowConsumerAIPanel;
    procedure HideConsumerAIPanel;
    procedure ConsumerAIClearClick(Sender: TObject);
    procedure ConsumerAIExportClick(Sender: TObject);
    procedure ConsumerAIRestartClick(Sender: TObject);
    procedure ConsumerAICloseClick(Sender: TObject);
    procedure ConsumerAISendClick(Sender: TObject);
    procedure ConsumerAIOptionButtonClick(Sender: TObject);
    procedure ClearConsumerAIOptionButtons;
    procedure RebuildConsumerAIOptionButtons(const ACsv: string);
    procedure UpdateConsumerAIInputPanelHeight;
    procedure ConsumerAIPopupSelectAllClick(Sender: TObject);
    procedure ConsumerAIPopupCopyClick(Sender: TObject);
    procedure ConsumerAIPopupExportClick(Sender: TObject);
    procedure ConsumerAIPopupPopup(Sender: TObject);
    function ExtractConsumerAIOptionsFromPrompt(const APrompt: string): string;
    function ShouldSuppressConsumerAIOutput(const AText: string): Boolean;
    procedure ConsumerAIInputChange(Sender: TObject);
    procedure ConsumerAIInputKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AppendConsumerAITranscript(const AText: string);
    procedure AppendConsumerAITranscriptEx(const AKind, AText: string);
    procedure TrimConsumerAITranscript;
    procedure SetConsumerAIStatus(const AText: string);
    procedure HandleConsumerAIProtocolLine(const ALine: string);
    function ResolveConsumerAIScriptPath: string;
    function ResolveConsumerAILogPath: string;
    procedure LogConsumerAIDebug(const AText: string);
    procedure StartConsumerAIProcess;
    procedure StopConsumerAIProcess;
    function ConsumerAIWriteLine(const AText: string): Boolean;
    procedure BuildToolbarOverflowMenu;
    procedure ToolbarOverflowButtonClick(Sender: TObject);
    procedure ToolbarOverflowItemClick(Sender: TObject);
    procedure ToolbarOverflowPopup(Sender: TObject);
    procedure BuildListViewPopupMenu;
    procedure popupmenuListViewPopup(Sender: TObject);
    // Helper procedure to update text and alignment
    procedure UpdateStatusBar(const TextMsg: string; Alignment: TIconAlignment);
    function StatusBarPanelRectByWidths(const Index: Integer): TRect;
    procedure LayoutLanguageCombo;
    procedure LayoutViewEncodingCombo;
    procedure LayoutZoomCombo;
    procedure ApplyListViewZoomPercent(const APct: Integer);
    procedure UpdateInfoPanels;
    procedure UpdateListViewZoomStatusPanel;
    procedure ExecutePanelIndexOne;
    function BuildLoadedFileDetailsText: string;
    // Logic to generate the modal form dynamically
    procedure ShowDetailsPopup(const TextContent: string);    
    procedure DetailsPopupKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    // Event handler for the dynamic "Copy" button
    procedure OnDynamicCopyClick(Sender: TObject);
    { Atalhos do painel Read (F1 Help + FormKeyDown + modo Select com checklist). }
    procedure FocusPrimaryReadView;
    function IsReadPanelShortcutKey(const Key: Word; const Shift: TShiftState): Boolean;
    procedure ApplyReadPanelKey(var Key: Word; Shift: TShiftState);
    { Adia showChecked apos word-wrap no modo Select (evita reentrancia / travamento). }
    procedure WMRefreshChecklist(var Msg: TMessage); message WM_USER + 201;

    { Find }
    procedure DoFindDialog;
    procedure DoFindReplace;
    procedure DoGotoLine;
    procedure DoGotoByteOffset;
    function Line0BasedForFileByte1Based(const Byte1Based: Int64): Int64;
    procedure StartFindFromPos(const AStartPos: Int64; const ADirection: Integer);
    procedure FindThreadDone(const AFound: Boolean; const ALineIndex: Integer; const AFilePos: Int64; const ASearchId: Integer; const AErrorMsg: string);
    procedure UpdateFindSearchProgress(const BytesDone, TotalBytes: Int64);
    procedure CaptureOpenFileDiskSnapshot;
    procedure InvalidateOpenFileDiskSnapshot;
    function EnsureOpenFileNotStaleForMutate: Boolean;
    function EnsureWritableSession: Boolean;
    procedure ApplySessionReadOnlyUi;
    function GetLineStartOffset(LineIndex: Int64): Int64;
    function BlendColors(const BaseColor, OverlayColor: TColor; const Alpha: Byte): TColor;
    function WrapLongTokensForDisplay(const AText: string; const MaxChars: Integer): string;
    { Quebra texto por largura em pixels (owner-draw onde DT_WORDBREAK falha). }
    function WrapPlainTextToPixelWidth(const ACanvas: TCanvas; const AText: string;
      const AMaxWidth: Integer): string;
    { ListView OwnerData: Item.Selected / cdsSelected no custom draw podem ficar incorretos }
    function ListViewItemIndexIsSelected(const ALv: TCustomListView; const AIndex: Integer): Boolean;
    procedure ListView1AdvancedCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; Stage: TCustomDrawStage;
      var DefaultDraw: Boolean);
    procedure ListView1AdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; Stage: TCustomDrawStage;
      var DefaultDraw: Boolean);

    { Encoding Detection (BOM) }
    function DetectFileEncoding(const AFileName: String): String;

    { Undo / Redo }
    procedure PushUndo(const AOp: TOperationType; const ALine: Int64; const AContent: String);
    procedure DoUndo;
    procedure DoRedo;
    procedure ClearUndoRedo;
    procedure RecordForUndo(const AOp: TOperationType; const ALine: Int64; const AContent: String);

    { Tail / Follow Mode }
    procedure ToggleTailMode;
    procedure TailAppendNewLines;

    { Filter / Grep Visual }
    procedure DoFilterDialog;
    procedure StartFilter(const AText: String; ACaseSensitive: Boolean;
      const AMatchMode: TFilterMatchMode = fmmContains);
    procedure ClearFilter;
    procedure FilterThreadDone;
    procedure FinishFilterThreadFailed(const AMsg: string);
    procedure UpdateFilterBuildProgress(const LinesDone, TotalLines: Int64);
    function FilteredIndexToReal(FilteredIdx: Int64): Int64;
    function FilteredIndexForRealLine(const RealLine: Int64): Int64;
    procedure SyncScrollBarsForFilterMode;

    { Bookmarks }
    procedure ToggleBookmark(RealLineIndex: Integer);
    function IsBookmarked(RealLineIndex: Integer): Boolean;
    function BookmarkIndexOf(RealLineIndex: Integer): Integer;
    procedure GotoNextBookmark;
    procedure GotoPrevBookmark;
    procedure ClearAllBookmarks;

    { Help }
    procedure ShowHelpDialog;
    procedure FormHelpKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    { Main menu tradicional (File/Edit/Options/Help) com atalhos do Help(F1). }
    procedure BuildClassicMainMenu;
    procedure AdjustListViewColumnsWidth;
    procedure EnsureReadTabVisible;
    procedure miOpenFileClick(Sender: TObject);
    procedure miRecentFilesClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miFindClick(Sender: TObject);
    procedure miFindReplaceClick(Sender: TObject);
    procedure miGotoLineClick(Sender: TObject);
    procedure miGotoByteOffsetClick(Sender: TObject);
    procedure miUndoClick(Sender: TObject);
    procedure miRedoClick(Sender: TObject);
    procedure miCopyClick(Sender: TObject);
    procedure miShowReadTabClick(Sender: TObject);
    procedure miReadLoadClick(Sender: TObject);
    procedure miToggleWordWrapClick(Sender: TObject);
    procedure miToggleTailClick(Sender: TObject);
    procedure miFilterClick(Sender: TObject);
    procedure miExportFilteredClick(Sender: TObject);
    procedure miToggleBookmarkClick(Sender: TObject);
    procedure miNextBookmarkClick(Sender: TObject);
    procedure miPrevBookmarkClick(Sender: TObject);
    procedure miClearBookmarksClick(Sender: TObject);
    procedure miToggleReadOnlyClick(Sender: TObject);
    procedure miToggleSegmentedHeavyOpsClick(Sender: TObject);
    procedure miSelectClick(Sender: TObject);
    procedure miZoomListViewInClick(Sender: TObject);
    procedure miZoomListViewOutClick(Sender: TObject);
    procedure miSplitFilesClick(Sender: TObject);
    procedure miMergeLinesClick(Sender: TObject);
    procedure miMergeFilesClick(Sender: TObject);
    procedure miCompareMergeHistoryClick(Sender: TObject);
    procedure miFindInFilesClick(Sender: TObject);
    procedure miInsertLineClick(Sender: TObject);
    procedure miDuplicateLineClick(Sender: TObject);
    procedure miEditLineClick(Sender: TObject);
    procedure miDeleteLinesClick(Sender: TObject);
    procedure miExportClick(Sender: TObject);
    procedure miClearClick(Sender: TObject);
    procedure miConsumerAIClick(Sender: TObject);
    { Dicas de teclado nos botoes da barra Read / pnlButtons (atalhos em FormKeyDown). }
    procedure SetupToolbarKeyboardHints;
    function BuildSimpleComponentHint(const AControl: TControl): string;
    function CountLinesInFile(const AFileName: String): Int64;
    function ShowMergeFilesDialog(out ASourceFile: String;
      out AMergeMode: TMergeFilesMode; out ALineNumber: Int64;
      out AFromLine: Int64; out AToLine: Int64): Boolean;
    function ShowSplitEqualPartsDialog(out ASourceFile: String;
      out APartCount: Integer): Boolean;
    procedure miSplitEqualPartsClick(Sender: TObject);
    function TryGetLineStartOffset(const ALine1Based: Int64;
      out AOffset0Based: Int64): Boolean;

    { Recent Files }
    procedure AddToRecentFiles(const AFileName: String);
    procedure ShowRecentFilesMenu;
    procedure RecentFileClick(Sender: TObject);
    procedure LoadRecentFiles;
    procedure SaveRecentFiles;
  public
    DoNotUpdate: boolean;
    CustomMagnifierSource: boolean;
    PressedBtn: TObject;
    FShowHoriz: Boolean;
    FShowVert: Boolean;
    function GetLineContent(LineIndex: Integer): String;
    procedure Loaded; override;
    procedure ChangeControlsLayout(NewBidiMode: TBidiMode);
    procedure GenerateSkinsList;
    function FormatMillisecondsToDateTime(const ms: integer): string;
    procedure setAllCheckBoxes(const bCheckAll: Boolean = True);
    procedure SetAllCheckBoxesToTrue;
    procedure SetAllCheckBoxesToFalse;
    function ListviewIsEmpty: Boolean;
    { Total de linhas do ficheiro indexado (temp.txt); nao confundir com Items.Count do ListView virtual. }
    function IndexFileLineCount: Int64;
    procedure EmptyObjects;
    function LineExists(const aLine: integer): Boolean;
    function getLineFromOffSet(const _offSet: Int64): string;
    function getNextCtrlLineFeedPositionFromOffSet(const fFileName: string; const _offSet: Int64): Int64;
    procedure SetChecked(const bChecked: Boolean = True);
    procedure DrawCheckMark(const ListViewX: TListView; Item: TListItem; Checked: Boolean);
    procedure GetCheckBias(var XBias, YBias, BiasTop, BiasLeft: Integer);
    procedure setCheckedLines(const index: Int64);
    procedure setUnCheckedLines(const index: Int64);
    procedure BeginRead;
    procedure EndRead;
    procedure ShowProgress;
    procedure HideProgress;
    procedure DoShowPanelReadFile;
    procedure DoSelectSkin;
    procedure DoRandomSkin;
    procedure DoShowHints;
    function getDataFromListViewToExport: TInt64List;
    procedure exportToClipBoard;
    procedure showChecked;
    function checkedLineExists(const icheckedLine: Int64): Boolean;
    function isLineChecked(const iLine: Int64): Boolean;
    procedure showCheckBoxes;
    function existsCheckedRows(const int64List: TInt64List): Boolean;
    procedure gotoLine(const iLine: Int64);
    function foundLineExists(const ifoundLine: Int64): Boolean;
    procedure changeBidiMode;
    procedure DoRead;
    procedure splitFirstFile(const fFileName: string; const position: Int64);
    procedure addNewContentsFromPositionStringStream(const fFileName: string; const text: string; const position: Int64);
    procedure addNewContentsFromPositionFileStream(fFileName: string; const position: Int64);
    procedure DeleteFromStream(DestFilename: string; Start, Length: Int64);
    procedure SetDragAndDropOnSystemsWIthUAC(Wnd : HWND; IsEnabled : boolean);
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    procedure ListViewOnDataNil;
    procedure showLineEditForm(const AlineEdit: tpLineEdit);
    (* function getTempFileName(const fileName: string): String;
    function getTempFilePath(const fileName: string): String; *)
    procedure SplitFile(const ffilename: String; const silentMode: Boolean = False);
    procedure MergeFile(const ffilename: String; const silentMode: Boolean = False);
    function totalMergeFiles(const ffilename: string): Integer;
    procedure showInfoStatus(const status: string);
    procedure btnPostLine2Click(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    //procedure splitFileByLines(const newTextFileName: string; const sourceLine: Int64; targetLine: Int64; const splittedFileName: string = '');
    function newFileName(const ffileName: String): String;
    function fileIsEmpty: Boolean;
    procedure tableTempFiles(const totalFiles: Integer);
    procedure insertExcludeFile;
    procedure deleteExcludeFile;
    procedure insertFolderFile;
    procedure deleteFolderFile;
    procedure saveFolderFile;
    procedure saveExcludeFile;
    function excludeExtensionFilesList: TStringList;
    procedure finishFileNameRead(const timer: string; const LineCount: Int64; const CharactersCount: Int64);
    procedure CloseFileStreams;
    procedure editFile(const AInitialOp: TOperationType = otEdit);
    procedure exportFile;
    procedure ExportFilteredResults;
    procedure RefreshFile;

  end;

var
  IniName:    string;          // Form positions and skin name are saved in Ini
  Loading:    boolean;
  frmMain:   TfrmMain;
  Animated:   boolean = True;
  AppLoading: boolean = False; // Prevent of frame animating while app is in loading
  FormShowed: boolean = False; // This variable used in a first form initialization
  // in the OnShow event. Used for preventing of repeated init after each form recreating.
  // Form.OnShow event is processed after each switching to skinned or non-skinned mode.
  numberLine: Int64;
  bSetBoldFont: Boolean;
  fProgressThread: TProgressThread;
  fScrollPos: integer;
  totalLines: Int64;
  totalCharacters: Int64;
  FCheckedLines: TInt64List;
  FFoundLines: TInt64List;
  MaxOffset: Int64;
  memoLineEdit: TMemo;
  strLineEdit: string;
  isChecked: Boolean;
  bCancelOperation: Boolean;
  fFileName: string;
  FCheckListBox: TCheckListBox;
  isAllChecked: Boolean;
  pnlLeftPosition: integer;
  splLeftPosition: integer;
  frm: TForm;
  lineEdit: tpLineEdit = tpListViewLineEdit;
  lineNumberTempFile: Integer;
  creationTime: TDateTime;
  mru_location: TMruHelper;
  mru_content: TMruHelper;

implementation

uses
  sMaskData, sStyleSimply, sSkinProps, sMessages, sStoreUtils, sGraphUtils, acPopupController,
  sVclUtils, acntUtils, sConst, acSelectSkin, sCommonData, sSkinMenus, sCalculator, UnitPopupScaling,
  acAnimation, UnUtils, StrUtils, UnDM, UnSplash, UnFormAboutFF, Biblioteca, uTextEncoding, uI18n,
  ComObj, ActiveX, uCompareMergeUI;

{$R *.DFM}

const
  { Glifo de zoom da lista: mesmo que ImageList1 (design-time), p.ex. índice 91 (lupa). }
  IMAGELIST_IDX_ZOOM_LIST = 91;
  FF_MENU_BMP_ZOOM_LIST = '__ff_zoom_list.bmp';
  { Fundo e barra de realce para linhas com marcador (ListView + checklist). }
  FF_BOOKMARK_ROW_BG = $00F0FAFF;
  FF_BOOKMARK_STRIPE = $0058B4FF;

procedure ShowMessage(const Msg: string); overload;
begin
  Dialogs.ShowMessage(TrText(Msg));
end;

function MessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer; overload;
begin
  Result := Dialogs.MessageDlg(TrText(Msg), DlgType, Buttons, HelpCtx);
end;

procedure TfrmMain.chkSegmentedHeavyOpsClick(Sender: TObject);
var
  Chk: Boolean;
begin
  Chk := Assigned(chkSegmentedHeavyOps) and chkSegmentedHeavyOps.Checked;
  sStoreUtils.WriteIniStr(APPLICATION_NAME, 'SegmentHeavyOps', iff(Chk, '1', '0'), IniName);
  if Assigned(FMenuSegmentedHeavyOpsItem) then
    FMenuSegmentedHeavyOpsItem.Checked := Chk;
  if Assigned(FPopupLVSegmentedHeavyOpsItem) then
    FPopupLVSegmentedHeavyOpsItem.Checked := Chk;
  if Assigned(FToolsExtrasSegmented) then
    FToolsExtrasSegmented.Checked := Chk;
end;

procedure TfrmMain.chkWordWrapClick(Sender: TObject);
begin
  if not Assigned(ListView1) then Exit;
  { Word wrap VISUAL: nao reindexa o arquivo (FastWordWrapAtivo permanece False). }
  FFastVisualWordWrap := chkWordWrap.Checked;
  FastWordWrapAtivo := False;
  UpdateListViewWordWrapUi;
  InvalidateLineCache;
  { Modo Select: ListView fica invisivel — Refresh corrompe comctl; so recalcular checklist.
    PostMessage evita reentrancia (showChecked + SetFocus + paint) no mesmo stack. }
  if isChecked then
  begin
    if not FChecklistRefreshPending then
    begin
      FChecklistRefreshPending := True;
      PostMessage(Handle, WM_USER + 201, 0, 0);
    end;
  end
  else if ListView1.Visible then
  begin
    ListView1.Refresh;
    ListView1.Invalidate;
  end;
  SyncScrollBarsForFilterMode;
  if Assigned(FToolsExtrasWordWrap) then
    FToolsExtrasWordWrap.Checked := Assigned(chkWordWrap) and chkWordWrap.Checked;
end;

function TfrmMain.EffectiveDisplayEncoding: string;
begin
  if (not Assigned(comboViewEncoding)) or (comboViewEncoding.ItemIndex < 0) then
  begin
    Result := FDetectedEncoding;
    Exit;
  end;
  case comboViewEncoding.ItemIndex of
    0: Result := FDetectedEncoding; { DEFAULT = detected (BOM / heuristics) }
    1: Result := 'UTF-8';
    2: Result := 'ANSI';
    3: Result := 'UTF-16 LE';
    4: Result := 'UTF-16 BE';
  else
    Result := FDetectedEncoding;
  end;
end;

procedure TfrmMain.ApplyViewEncodingRefresh;
begin
  InvalidateLineCache;
  if Assigned(ListView1) then
    ListView1.Refresh;
  UpdateInfoPanels;
end;

procedure TfrmMain.HookedStatusBarWndProcForCombo(var Message: TMessage);
const
  CBN_CLOSEUP = 8;
begin
  if Assigned(FOldStatusBarWndProcForCombo) then
    FOldStatusBarWndProcForCombo(Message);

  if (Message.Msg = WM_COMMAND) and Assigned(comboViewEncoding) and
     (HWND(Message.LParam) = comboViewEncoding.Handle) and (not FUpdatingViewEncodingCombo) then
  begin
    case Word(Message.WParam shr 16) of
      CBN_CLOSEUP:
        ApplyViewEncodingRefresh;
    end;
  end;
end;

procedure TfrmMain.comboViewEncodingChange(Sender: TObject);
begin
  if FUpdatingViewEncodingCombo then Exit;
  ApplyViewEncodingRefresh;
end;


{ ============================================================================ }
{ TFindInFileThread - busca background usando TFileStream (sem MMF)            }
{ ============================================================================ }
type
  TFindInFileThread = class(TThread)
  private
    FOwner: TfrmMain;
    FFileName: string;
    FIndexFileName: string;
    FNeedle: AnsiString;
    FNeedleUpper: AnsiString;
    FCaseSensitive: Boolean;
    FStartPos: Int64;
    FDirection: Integer;
    FFound: Boolean;
    FFoundLine: Integer;
    FFoundPos: Int64;
    FSearchId: Integer;
    FErrorMsg: string;
    FLastFindProgressPos: Int64;
    FProgBytes: Int64;
    FProgTotal: Int64;
    procedure NotifyOwner;
    procedure SyncFindBytesProgress;
    function OffsetToLineIndex(AIndexStream: TFileStream; const APos1Based: Int64): Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TfrmMain; const AFileName, AIndexFileName: string;
      const ANeedle: string; ACaseSensitive: Boolean; const AStartPos: Int64;
      const ADirection: Integer; const ASearchId: Integer);
  end;

  TFilterThread = class(TThread)
  private
    FOwner: TfrmMain;
    FFileName: string;
    FIndexFileName: string;
    FNeedle: AnsiString;
    FCaseSensitive: Boolean;
    FMatchMode: TFilterMatchMode;
    FTotalLines: Int64;
    FBits: PFFByteArray;
    FBitsSize: Integer;
    FFilteredCount: Int64;
    FJumpTable: TInt64DynArray;
    FProgLines: Int64;
    FProgTotalLines: Int64;
    FAbortMsg: string;
    procedure NotifyOwner;
    procedure SyncFilterProgress;
    procedure SyncFilterFailed;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TfrmMain; const AFileName, AIndexFileName: string;
      const ANeedle: string; ACaseSensitive: Boolean; ATotalLines: Int64;
      AMatchMode: TFilterMatchMode);
    destructor Destroy; override;
  end;

  TConsumerAIReaderThread = class(TThread)
  private
    FOwner: TfrmMain;
    FReadHandle: THandle;
    FPendingLine: string;
    procedure DispatchLine;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TfrmMain; AReadHandle: THandle);
  end;

function GetAttributeStatus(CB: TCheckBox): TFileAttributeStatus;
begin
  case CB.State of
    cbUnchecked: Result := fsUnset;
    cbChecked: Result := fsSet;
  else
    Result := fsIgnore;
  end;
end;

constructor TConsumerAIReaderThread.Create(AOwner: TfrmMain; AReadHandle: THandle);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;
  FReadHandle := AReadHandle;
end;

procedure TConsumerAIReaderThread.DispatchLine;
begin
  if Assigned(FOwner) then
    FOwner.HandleConsumerAIProtocolLine(FPendingLine);
end;

procedure TConsumerAIReaderThread.Execute;
var
  Buffer: AnsiString;
  Ch: AnsiChar;
  BytesRead: DWORD;
  BytesAvail: DWORD;
  IdleCount: Integer;
  function Utf8AnsiToAcp(const S: AnsiString): string;
  var
    WLen: Integer;
    ALen: Integer;
    W: WideString;
    A: AnsiString;
  begin
    Result := string(S);
    if S = '' then Exit;

    WLen := MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(S), Length(S), nil, 0);
    if WLen <= 0 then Exit;

    SetLength(W, WLen);
    if MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(S), Length(S), PWideChar(W), WLen) <= 0 then Exit;

    ALen := WideCharToMultiByte(CP_ACP, 0, PWideChar(W), Length(W), nil, 0, nil, nil);
    if ALen <= 0 then
    begin
      Result := string(W);
      Exit;
    end;

    SetLength(A, ALen);
    WideCharToMultiByte(CP_ACP, 0, PWideChar(W), Length(W), PAnsiChar(A), ALen, nil, nil);
    Result := string(A);
  end;
begin
  Buffer := '';
  IdleCount := 0;
  while not Terminated do
  begin
    if (FReadHandle = 0) or (FReadHandle = INVALID_HANDLE_VALUE) then
      Break;

    { Check if data is available before blocking on ReadFile }
    BytesAvail := 0;
    if not PeekNamedPipe(FReadHandle, nil, 0, nil, @BytesAvail, nil) then
      Break; { pipe was closed/broken }

    if BytesAvail = 0 then
    begin
      { No data available: Python may be waiting for input (prompt has no trailing LF) }
      if Buffer <> '' then
      begin
        Inc(IdleCount);
        if IdleCount >= 3 then  { 3 x 100ms = 300ms idle -> dispatch as prompt line }
        begin
          while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#13, #10]) do
            Delete(Buffer, Length(Buffer), 1);
          if Buffer <> '' then
          begin
            FPendingLine := Utf8AnsiToAcp(Buffer);
            Buffer := '';
            Synchronize(DispatchLine);
          end;
          IdleCount := 0;
        end;
      end
      else
        IdleCount := 0;
      Sleep(100);
      Continue;
    end;

    IdleCount := 0;
    if (not Windows.ReadFile(FReadHandle, Ch, 1, BytesRead, nil)) or (BytesRead = 0) then
      Break;

    if Ch = #10 then
    begin
      while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#13, #10]) do
        Delete(Buffer, Length(Buffer), 1);
      FPendingLine := Utf8AnsiToAcp(Buffer);
      Synchronize(DispatchLine);
      Buffer := '';
      IdleCount := 0;
    end
    else
      Buffer := Buffer + Ch;
  end;

  if (not Terminated) and (Buffer <> '') then
  begin
    while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#13, #10]) do
      Delete(Buffer, Length(Buffer), 1);
    FPendingLine := Utf8AnsiToAcp(Buffer);
    Synchronize(DispatchLine);
  end;
end;

procedure TfrmMain.C1Click(Sender: TObject);
begin
  TsCalculator.Create(Self).Execute;
end;
           
procedure TfrmMain.ChangeControlsLayout(NewBidiMode: TBidiMode);
begin // Changing layout of controls when BidiMode is changed
  ReflectControls(Self, True);
end;

procedure TfrmMain.LocalizeMenuItem(const AComponentName, ATranslationKey,
  ADefaultCaption: string);
var
  C: TComponent;
begin
  C := FindComponent(AComponentName);
  if (C <> nil) and (C is TMenuItem) then
    TMenuItem(C).Caption := Tr(ATranslationKey, ADefaultCaption);
end;

procedure TfrmMain.LocalizeTopToolbar;
begin
  { Tab caption in the page control }
  if Assigned(sTabSheet2) then
    sTabSheet2.Caption := Tr('toolbar.top_toolbar_tab', 'Top toolbar');
  { Top toolbar speed buttons }
  if Assigned(btnShowTabFindFile) then
    btnShowTabFindFile.Caption := Tr('toolbar.find_files', 'Find Files');
  if Assigned(btnSplash) then
    btnSplash.Caption := Tr('toolbar.about_fastfile', 'About FastFile');
  if Assigned(sSpeedButton9) then
    sSpeedButton9.Caption := Tr('toolbar.select_skin', 'Select'#13#10'skin');
  if Assigned(sSpeedButton10) then
    sSpeedButton10.Caption := Tr('toolbar.change_bidimode', 'Change'#13#10'BidiMode');
  if Assigned(btnClose) then
    btnClose.Caption := Tr('toolbar.close', 'Close');
  if Assigned(chkWordWrap) then
    chkWordWrap.Caption := Tr('toolbar.word_wrap_on', 'Word Wrap (ON)');
  if Assigned(chkSegmentedHeavyOps) then
  begin
    chkSegmentedHeavyOps.Caption := TrText('Line-segmented processing for heavy operations (off by default)');
    chkSegmentedHeavyOps.Hint := TrText(
      'When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.');
  end;
  { TsTitleBar: About and Tools items }
  if Assigned(sTitleBar1) and (sTitleBar1.Items.Count > 1) then
  begin
    sTitleBar1.Items[0].Caption := Tr('titlebar.about', 'About');
    sTitleBar1.Items[1].Caption := Tr('titlebar.tools', 'Tools');
  end;
  if Assigned(sSkinProvider1) then
    sSkinProvider1.SysSubMenu.Caption := TrText('Dialogs');
  { PopupMenu1 items (Tools dropdown) — direct field access, sem FindComponent. }
  if Assigned(mnSelectSkin)     then mnSelectSkin.Caption     := Tr('popup.select_skin',       'Select Skin');
  if Assigned(mnRandomSkin)     then mnRandomSkin.Caption     := Tr('popup.random_skin',       'Random Skin');
  if Assigned(mnShowHints)      then mnShowHints.Caption      := Tr('popup.show_hints',        'Show Hints');
  { PopupDialogs items — direct field access. }
  if Assigned(miSelectSkindialog1) then miSelectSkindialog1.Caption := Tr('popup.selectskin_dialog', 'SelectSkin dialog');
  if Assigned(R1) then R1.Caption := Tr('popup.random_skin',    'Random Skin');
  if Assigned(M1) then M1.Caption := Tr('popup.magnifier',      'Magnifier');
  if Assigned(C1) then C1.Caption := Tr('popup.calculator',     'Calculator');
  { Status bar controls }
  if Assigned(SpeedBtnPPI)    then SpeedBtnPPI.Caption               := TrText('Change scaling');
  if Assigned(sSkinSelector1) then sSkinSelector1.BoundLabel.Caption := TrText('Skin name:');
  { --- ListView1 column headers ------------------------------------------- }
  if Assigned(ListView1) and (ListView1.Columns.Count >= 2) then
  begin
    ListView1.Columns[0].Caption := TrText('Line #');
    ListView1.Columns[1].Caption := TrText('Content');
  end;
  { --- FoundFiles result columns ------------------------------------------ }
  if Assigned(FoundFiles) and (FoundFiles.Columns.Count >= 4) then
  begin
    FoundFiles.Columns[0].Caption := TrText('Name');
    FoundFiles.Columns[1].Caption := TrText('Location');
    FoundFiles.Columns[2].Caption := TrText('Size');
    FoundFiles.Columns[3].Caption := TrText('Modified');
  end;
  { --- Main page-control tab captions ------------------------------------- }
  if Assigned(tabReadFile)      then tabReadFile.Caption      := TrText('Read File');
  if Assigned(tabSplitFile)     then tabSplitFile.Caption     := TrText('Split File');
  if Assigned(tabExportedLines) then tabExportedLines.Caption := TrText('Exported Lines');
  if Assigned(tabFindFiles)     then tabFindFiles.Caption     := TrText('Find Files');
  { --- Ribbon tab captions ------------------------------------------------ }
  if Assigned(sTabSheet4) then sTabSheet4.Caption := TrText('Add-ons');
  if Assigned(sTabSheet5) then sTabSheet5.Caption := TrText('File toolbar');
  { --- Sub-tab captions --------------------------------------------------- }
  if Assigned(tabSplitByLines)   then tabSplitByLines.Caption   := TrText('Split By Lines');
  if Assigned(tabSplitByFiles)   then tabSplitByFiles.Caption   := TrText('Split By Files');
  if Assigned(tabFindFilesName)  then tabFindFilesName.Caption  := TrText('Name && Location');
  if Assigned(tabFoldersExclude) then tabFoldersExclude.Caption := TrText('Folders exclude');
  { --- Add-ons popup (PopupMenu2) ----------------------------------------- }
  if Assigned(MenuItem2)  then MenuItem2.Caption  := Tr('popup.listview.read',             'Read');
  if Assigned(MenuItem3)  then MenuItem3.Caption  := Tr('popup.listview.split_files',      'Split Files');
  if Assigned(MenuItem4)  then MenuItem4.Caption  := Tr('popup.listview.show_checkboxes',  'Show CheckBoxes');
  if Assigned(MenuItem16) then MenuItem16.Caption := Tr('popup.listview.write',            'Write');
  if Assigned(MenuItem6)  then MenuItem6.Caption  := Tr('popup.listview.delete_lines',     'Delete Lines');
  if Assigned(MenuItem5)  then MenuItem5.Caption  := Tr('popup.listview.clear',            'Clear');
  if Assigned(MenuItem17) then MenuItem17.Caption := Tr('popup.listview.export_clipboard', 'Export to ClipBoard');
  { --- Tools popup (PopupMenu1) previously untranslated items ------------- }
  if Assigned(Skinned2)        then Skinned2.Caption        := TrText('Active');
  if Assigned(ActionAnimation) then ActionAnimation.Caption := TrText('Allow animation');
  if Assigned(ActionCloseForm) then ActionCloseForm.Caption := TrText('Exit');
  { --- Find Files tab: labels and checkboxes ------------------------------ }
  if Assigned(Label1)         then Label1.Caption         := TrText('File Name (Separate multiple names with semicolon):');
  if Assigned(Label2)         then Label2.Caption         := TrText('Location (Separate multiple directories with semicolon):');
  if Assigned(Label3)         then Label3.Caption         := TrText('Content:');
  if Assigned(Subfolders)     then Subfolders.Caption     := TrText('Include subfolders');
  if Assigned(CaseSenstitive) then CaseSenstitive.Caption := TrText('Case Sensitive');
  if Assigned(WholeWord)      then WholeWord.Caption      := TrText('Whole Word');
  if Assigned(Negate)         then Negate.Caption         := TrText('Excluded');
  if Assigned(Threaded)       then Threaded.Caption       := TrText('Threaded Search');
  if Assigned(FindButton)     then FindButton.Caption     := TrText('Find');
  if Assigned(StopButton)     then StopButton.Caption     := TrText('Stop');
  { --- Split By Lines components ------------------------------------------ }
  if Assigned(gbxSplitByLines)            then gbxSplitByLines.Caption            := TrText('Generating new file by source and target lines');
  if Assigned(lblFromSplitByLine)         then lblFromSplitByLine.Caption         := TrText('From:');
  if Assigned(lblToSplitByLine)           then lblToSplitByLine.Caption           := TrText('To:');
  if Assigned(btnExecuteSplitFileByLines) then btnExecuteSplitFileByLines.Caption := TrText('Execute');
  if Assigned(edtOutputSplitByLineText)   then edtOutputSplitByLineText.BoundLabel.Caption := TrText('Output FileName:');
  { --- Split By Files components ------------------------------------------ }
  if Assigned(gbxSplitByFiles)              then gbxSplitByFiles.Caption              := TrText('Generating splitted files - max 100');
  if Assigned(btnExecuteSplitFileByFiles)   then btnExecuteSplitFileByFiles.Caption   := TrText('Execute');
  if Assigned(lblTrackBarFileInfoSplitFile) then lblTrackBarFileInfoSplitFile.Caption := TrText('Files:');
  { --- Split File info panel ---------------------------------------------- }
  if Assigned(gbxInfoFileSplit)   then gbxInfoFileSplit.Caption   := TrText('File Info');
  if Assigned(lblFileName)        then lblFileName.Caption        := TrText('File name:');
  if Assigned(lblFileDtCreation)  then lblFileDtCreation.Caption  := TrText('Creation Date:');
  if Assigned(lblTotalCharacters) then lblTotalCharacters.Caption := TrText('Total characters:');
  if Assigned(lblTotalLines)      then lblTotalLines.Caption      := TrText('Total lines:');
  { --- Exported Lines tab buttons ----------------------------------------- }
  if Assigned(sSpeedButton18) then sSpeedButton18.Caption := TrText('Return');
  if Assigned(sSpeedButton19) then sSpeedButton19.Caption := TrText('Copy');
  { --- tabFindFiles: Date && Time sub-tab captions ------------------------ }
  if Assigned(TabSheet3) then TabSheet3.Caption := TrText('Date && Time');
  if Assigned(TabSheet4) then TabSheet4.Caption := TrText('Created');
  if Assigned(TabSheet5) then TabSheet5.Caption := TrText('Modified');
  if Assigned(TabSheet6) then TabSheet6.Caption := TrText('Accessed');
  if Assigned(TabSheet2) then TabSheet2.Caption := TrText('Size && Attributes');
  { --- Date && Time: checkboxes (shared key across Created/Modified/Accessed) }
  if Assigned(CBD) then CBD.Caption := TrText('Before Date:');
  if Assigned(CBT) then CBT.Caption := TrText('Before Time:');
  if Assigned(CAD) then CAD.Caption := TrText('After Date:');
  if Assigned(CAT) then CAT.Caption := TrText('After Time:');
  if Assigned(MBD) then MBD.Caption := TrText('Before Date:');
  if Assigned(MBT) then MBT.Caption := TrText('Before Time:');
  if Assigned(MAD) then MAD.Caption := TrText('After Date:');
  if Assigned(MAT) then MAT.Caption := TrText('After Time:');
  if Assigned(ABD) then ABD.Caption := TrText('Before Date:');
  if Assigned(ABT) then ABT.Caption := TrText('Before Time:');
  if Assigned(AAD) then AAD.Caption := TrText('After Date:');
  if Assigned(AAT) then AAT.Caption := TrText('After Time:');
  { --- Size && Attributes: FileSize group box and labels ------------------ }
  if Assigned(FileSize)  then FileSize.Caption  := ' ' + TrText('Size') + ' ';
  if Assigned(Label10)   then Label10.Caption   := TrText('At Most:');
  if Assigned(Label11)   then Label11.Caption   := TrText('At Least:');
  { --- Size && Attributes: Attributes group box and checkboxes ------------ }
  if Assigned(Attributes)         then Attributes.Caption         := ' ' + TrText('Attributes') + ' ';
  if Assigned(System)             then System.Caption             := TrText('System');
  if Assigned(Hidden)             then Hidden.Caption             := TrText('Hidden');
  if Assigned(Readonly)           then Readonly.Caption           := TrText('Readonly');
  if Assigned(Archive)            then Archive.Caption            := TrText('Archive');
  if Assigned(Directory)          then Directory.Caption          := TrText('Directory');
  if Assigned(Compressed)         then Compressed.Caption         := TrText('Compressed');
  if Assigned(Encrypted)          then Encrypted.Caption          := TrText('Encrypted');
  if Assigned(Offline)            then Offline.Caption            := TrText('Offline');
  if Assigned(SparseFile)         then SparseFile.Caption         := TrText('Sparse File');
  if Assigned(ReparsePoint)       then ReparsePoint.Caption       := TrText('Reparse Point');
  if Assigned(Temporary)          then Temporary.Caption          := TrText('Temporary');
  if Assigned(Device)             then Device.Caption             := TrText('Device');
  if Assigned(Normal)             then Normal.Caption             := TrText('Normal');
  if Assigned(NotContentIndexed)  then NotContentIndexed.Caption  := TrText('Not Content Indexed');
  if Assigned(Virtual)            then Virtual.Caption            := TrText('Virtual');
  { --- Folders Exclude tab: grid column headers and buttons --------------- }
  if Assigned(dbgFoldersExclude) and (dbgFoldersExclude.Columns.Count >= 1) then
    dbgFoldersExclude.Columns[0].Title.Caption := TrText('Folders');
  if Assigned(btnSaveFoldersExclude)   then btnSaveFoldersExclude.Caption   := TrText('Insert from prompt');
  if Assigned(btnDeleteFoldersExclude) then btnDeleteFoldersExclude.Caption := TrText('Delete');
  if Assigned(dbgFilesExclude) and (dbgFilesExclude.Columns.Count >= 1) then
    dbgFilesExclude.Columns[0].Title.Caption := TrText('Files');
  if Assigned(btnSaveFilesExclude)   then btnSaveFilesExclude.Caption   := TrText('Insert from prompt');
  if Assigned(btnDeleteFilesExclude) then btnDeleteFilesExclude.Caption := TrText('Delete');
  if Assigned(btnImportExtensionFiles) then btnImportExtensionFiles.Caption := TrText('Import file extensions');
  if Assigned(btnImportListFiles)      then btnImportListFiles.Caption      := TrText('Import');
end;

function TfrmMain.ResolveMenuBitmapDir: string;
const
  MENU_BITMAP_SUBPATH_HOT16 = 'Images\\ImagesII\\glyphspro\\glyphspro\\16x16\\hot\\';
  MENU_BITMAP_SUBPATH_TRICH16 = 'Resources\\trichviewicons\\bitmaps\\normal\\16x16\\';
  MENU_BITMAP_SUBPATH_TRICH32 = 'Resources\\trichviewicons\\bitmaps\\normal\\32x32\\';
var
  BasePath: string;
  SearchRoot: string;
  I: Integer;
  function ResolveFromSubPath(const ARootPath, ASubPath: string): string;
  var
    Candidate: string;
  begin
    Result := '';
    Candidate := ExpandFileName(IncludeTrailingPathDelimiter(ARootPath) + ASubPath);
    if DirectoryExists(Candidate) then
      Result := IncludeTrailingPathDelimiter(Candidate);
  end;
begin
  Result := '';
  BasePath := ExtractFilePath(Application.ExeName);

  { Prefer glyphspro hot 16x16 and search from exe folder up through parent folders.
    This supports running from Src, project root, or bin folders. }
  SearchRoot := ExcludeTrailingPathDelimiter(BasePath);
  for I := 0 to 6 do
  begin
    Result := ResolveFromSubPath(SearchRoot, MENU_BITMAP_SUBPATH_HOT16);
    if Result <> '' then Exit;

    Result := ResolveFromSubPath(SearchRoot, MENU_BITMAP_SUBPATH_TRICH16);
    if Result <> '' then Exit;

    Result := ResolveFromSubPath(SearchRoot, MENU_BITMAP_SUBPATH_TRICH32);
    if Result <> '' then Exit;

    SearchRoot := ExtractFileDir(SearchRoot);
    if SearchRoot = '' then Break;
  end;
end;

procedure TfrmMain.BuildMenuBitmapImageList;
var
  IconDir: string;
  SearchRec: TSearchRec;
  Bmp: TBitmap;
  SizedBmp: TBitmap;
  ZoomSrc: TBitmap;
  ZoomSized: TBitmap;
  FileNames: TStringList;
  I: Integer;
  FilePath: string;
begin
  if not Assigned(FMenuBitmapImages) then
  begin
    FMenuBitmapImages := TImageList.Create(Self);
    FMenuBitmapImages.Width := 16;
    FMenuBitmapImages.Height := 16;
    FMenuBitmapImages.Masked := True;
  end
  else
  begin
    FMenuBitmapImages.Width := 16;
    FMenuBitmapImages.Height := 16;
    FMenuBitmapImages.Clear;
  end;

  if not Assigned(FMenuIconIndexByName) then
  begin
    FMenuIconIndexByName := TStringList.Create;
    FMenuIconIndexByName.CaseSensitive := False;
    FMenuIconIndexByName.Sorted := False;
    FMenuIconIndexByName.Duplicates := dupIgnore;
    FMenuIconIndexByName.NameValueSeparator := '=';
  end
  else
    FMenuIconIndexByName.Clear;

  IconDir := ResolveMenuBitmapDir;
  if IconDir = '' then
    Exit;

  FileNames := TStringList.Create;
  try
    if FindFirst(IconDir + '*.bmp', faAnyFile, SearchRec) = 0 then
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then
          FileNames.Add(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;

    FileNames.Sort;
    for I := 0 to FileNames.Count - 1 do
    begin
      FilePath := IconDir + FileNames[I];
      Bmp := TBitmap.Create;
      SizedBmp := TBitmap.Create;
      try
        Bmp.LoadFromFile(FilePath);
        SizedBmp.PixelFormat := pf24bit;
        SizedBmp.Width := FMenuBitmapImages.Width;
        SizedBmp.Height := FMenuBitmapImages.Height;
        SizedBmp.Canvas.Brush.Color := clFuchsia;
        SizedBmp.Canvas.FillRect(Rect(0, 0, SizedBmp.Width, SizedBmp.Height));
        SetStretchBltMode(SizedBmp.Canvas.Handle, HALFTONE);
        StretchBlt(
          SizedBmp.Canvas.Handle,
          0, 0, SizedBmp.Width, SizedBmp.Height,
          Bmp.Canvas.Handle,
          0, 0, Bmp.Width, Bmp.Height,
          SRCCOPY
        );

        FMenuBitmapImages.AddMasked(SizedBmp, clFuchsia);
        FMenuIconIndexByName.Values[LowerCase(FileNames[I])] := IntToStr(FMenuBitmapImages.Count - 1);
      finally
        SizedBmp.Free;
        Bmp.Free;
      end;
    end;
  finally
    FileNames.Free;
  end;

  { Ícone de zoom da lista: copia ImageList1[IMAGELIST_IDX_ZOOM_LIST] para FMenuBitmapImages
    (o menu usa esta lista, não ImageList1 diretamente). }
  if Assigned(ImageList1) and (ImageList1.Count > IMAGELIST_IDX_ZOOM_LIST) then
  begin
    ZoomSrc := TBitmap.Create;
    ZoomSized := TBitmap.Create;
    try
      ZoomSrc.Width := ImageList1.Width;
      ZoomSrc.Height := ImageList1.Height;
      ZoomSrc.PixelFormat := pf24bit;
      ZoomSrc.Canvas.Brush.Color := clFuchsia;
      ZoomSrc.Canvas.FillRect(Rect(0, 0, ZoomSrc.Width, ZoomSrc.Height));
      ImageList1.Draw(ZoomSrc.Canvas, 0, 0, IMAGELIST_IDX_ZOOM_LIST);
      ZoomSized.PixelFormat := pf24bit;
      ZoomSized.Width := FMenuBitmapImages.Width;
      ZoomSized.Height := FMenuBitmapImages.Height;
      ZoomSized.Canvas.Brush.Color := clFuchsia;
      ZoomSized.Canvas.FillRect(Rect(0, 0, ZoomSized.Width, ZoomSized.Height));
      SetStretchBltMode(ZoomSized.Canvas.Handle, HALFTONE);
      StretchBlt(
        ZoomSized.Canvas.Handle,
        0, 0, ZoomSized.Width, ZoomSized.Height,
        ZoomSrc.Canvas.Handle,
        0, 0, ZoomSrc.Width, ZoomSrc.Height,
        SRCCOPY
      );
      FMenuBitmapImages.AddMasked(ZoomSized, clFuchsia);
      FMenuIconIndexByName.Values[LowerCase(FF_MENU_BMP_ZOOM_LIST)] :=
        IntToStr(FMenuBitmapImages.Count - 1);
    finally
      ZoomSized.Free;
      ZoomSrc.Free;
    end;
  end;

  MainMenu1.Images := FMenuBitmapImages;
  popupmenuListView.Images := FMenuBitmapImages;
  if Assigned(PopupMenu1) then
  begin
    if FMenuBitmapImages.Count > 0 then
      PopupMenu1.Images := FMenuBitmapImages
    else
      PopupMenu1.Images := CharImageList16;
  end;
  if Assigned(PopupDialogs) then
  begin
    if FMenuBitmapImages.Count > 0 then
      PopupDialogs.Images := FMenuBitmapImages
    else
      PopupDialogs.Images := CharImageList16;
  end;
  ApplySkinRelatedPopupMenuIcons;
end;

procedure TfrmMain.ApplySkinRelatedPopupMenuIcons;
begin
  if not Assigned(FMenuBitmapImages) or (FMenuBitmapImages.Count = 0) then Exit;
  if Assigned(mnSelectSkin) then
    mnSelectSkin.ImageIndex := MenuIconIndex('open.bmp', 3);
  if Assigned(mnRandomSkin) then
    mnRandomSkin.ImageIndex := MenuIconIndex('box closed.bmp', 32);
  if Assigned(mnShowHints) then
    mnShowHints.ImageIndex := MenuIconIndex('help.bmp', 20);
  if Assigned(Exit2) then
    Exit2.ImageIndex := MenuIconIndex('exit.bmp', 10);
  if Assigned(miSelectSkindialog1) then
    miSelectSkindialog1.ImageIndex := MenuIconIndex('open.bmp', 3);
  if Assigned(R1) then
    R1.ImageIndex := MenuIconIndex('box closed.bmp', 32);
  if Assigned(M1) then
    M1.ImageIndex := MenuIconIndex('search.bmp', 12);
  if Assigned(C1) then
    C1.ImageIndex := MenuIconIndex('tools.bmp', 6);
end;

procedure TfrmMain.EnsureToolsPopupFastFileExtras;
begin
  if not Assigned(PopupMenu1) or not Assigned(N6) then Exit;
  if Assigned(FToolsExtrasSep) then Exit;

  { Inserir sempre em N6.MenuIndex: cada insercao empurra N6 para baixo; ordem final
    de cima para baixo = ultimo inserido primeiro. Queremos: sep, WW, RO, seg, tail, filtro, export, N6. }
  FToolsExtrasExportFiltered := TMenuItem.Create(Self);
  FToolsExtrasExportFiltered.Caption := TrText('E&xport filtered results');
  FToolsExtrasExportFiltered.OnClick := miExportFilteredClick;
  FToolsExtrasExportFiltered.ShortCut := ShortCut(Ord('L'), [ssCtrl, ssShift]);
  FToolsExtrasExportFiltered.ImageIndex := MenuIconIndex('save as.bmp', 11);
  PopupMenu1.Items.Insert(N6.MenuIndex, FToolsExtrasExportFiltered);

  FToolsExtrasFilter := TMenuItem.Create(Self);
  FToolsExtrasFilter.Caption := TrText('Fil&ter / Grep');
  FToolsExtrasFilter.OnClick := miFilterClick;
  FToolsExtrasFilter.ShortCut := ShortCut(Ord('L'), [ssCtrl]);
  FToolsExtrasFilter.ImageIndex := MenuIconIndex('find.bmp', 4);
  PopupMenu1.Items.Insert(N6.MenuIndex, FToolsExtrasFilter);

  FToolsExtrasTail := TMenuItem.Create(Self);
  FToolsExtrasTail.Caption := TrText('Tail / &Follow mode');
  FToolsExtrasTail.OnClick := miToggleTailClick;
  FToolsExtrasTail.ShortCut := ShortCut(Ord('T'), [ssCtrl]);
  FToolsExtrasTail.ImageIndex := MenuIconIndex('forward.bmp', 2);
  PopupMenu1.Items.Insert(N6.MenuIndex, FToolsExtrasTail);

  FToolsExtrasSegmented := TMenuItem.Create(Self);
  FToolsExtrasSegmented.Caption := TrText('Line-segmented &mode (heavy ops)');
  FToolsExtrasSegmented.OnClick := miToggleSegmentedHeavyOpsClick;
  FToolsExtrasSegmented.ImageIndex := MenuIconIndex('grid split cells.bmp', 19);
  PopupMenu1.Items.Insert(N6.MenuIndex, FToolsExtrasSegmented);

  FToolsExtrasReadOnly := TMenuItem.Create(Self);
  FToolsExtrasReadOnly.Caption := TrText('Read-only &session');
  FToolsExtrasReadOnly.OnClick := miToggleReadOnlyClick;
  FToolsExtrasReadOnly.ShortCut := ShortCut(Ord('R'), [ssCtrl, ssAlt]);
  FToolsExtrasReadOnly.ImageIndex := MenuIconIndex('box closed.bmp', 32);
  PopupMenu1.Items.Insert(N6.MenuIndex, FToolsExtrasReadOnly);

  FToolsExtrasWordWrap := TMenuItem.Create(Self);
  FToolsExtrasWordWrap.Caption := TrText('&Word wrap');
  FToolsExtrasWordWrap.OnClick := miToggleWordWrapClick;
  FToolsExtrasWordWrap.ShortCut := ShortCut(Ord('W'), [ssCtrl]);
  FToolsExtrasWordWrap.ImageIndex := MenuIconIndex('word wrap.bmp', 11);
  PopupMenu1.Items.Insert(N6.MenuIndex, FToolsExtrasWordWrap);

  FToolsExtrasSep := TMenuItem.Create(Self);
  FToolsExtrasSep.Caption := '-';
  PopupMenu1.Items.Insert(N6.MenuIndex, FToolsExtrasSep);
end;

procedure TfrmMain.EnsureToolsPopupBookmarkExtras;
begin
  if not Assigned(PopupMenu1) or not Assigned(FToolsExtrasReadOnly) or not Assigned(FToolsExtrasWordWrap) then Exit;
  if Assigned(FToolsExtrasToggleBookmark) then Exit;

  { Ordem visual do bloco: Sep, WW, Toggle, Next, Prev, Clear, RO, ... (inserir antes de RO). }
  FToolsExtrasToggleBookmark := TMenuItem.Create(Self);
  FToolsExtrasToggleBookmark.Caption := TrText('&Toggle bookmark');
  FToolsExtrasToggleBookmark.OnClick := miToggleBookmarkClick;
  FToolsExtrasToggleBookmark.ShortCut := ShortCut(Ord('B'), [ssCtrl]);
  FToolsExtrasToggleBookmark.ImageIndex := MenuIconIndex('pushpin.bmp', 31);
  PopupMenu1.Items.Insert(FToolsExtrasReadOnly.MenuIndex, FToolsExtrasToggleBookmark);

  FToolsExtrasNextBookmark := TMenuItem.Create(Self);
  FToolsExtrasNextBookmark.Caption := TrText('&Next bookmark');
  FToolsExtrasNextBookmark.OnClick := miNextBookmarkClick;
  FToolsExtrasNextBookmark.ShortCut := ShortCut(VK_F2, []);
  FToolsExtrasNextBookmark.ImageIndex := MenuIconIndex('pushpin.bmp', 31);
  PopupMenu1.Items.Insert(FToolsExtrasReadOnly.MenuIndex, FToolsExtrasNextBookmark);

  FToolsExtrasPrevBookmark := TMenuItem.Create(Self);
  FToolsExtrasPrevBookmark.Caption := TrText('Pr&evious bookmark');
  FToolsExtrasPrevBookmark.OnClick := miPrevBookmarkClick;
  FToolsExtrasPrevBookmark.ShortCut := ShortCut(VK_F2, [ssShift]);
  FToolsExtrasPrevBookmark.ImageIndex := MenuIconIndex('pushpin.bmp', 31);
  PopupMenu1.Items.Insert(FToolsExtrasReadOnly.MenuIndex, FToolsExtrasPrevBookmark);

  FToolsExtrasClearBookmarks := TMenuItem.Create(Self);
  FToolsExtrasClearBookmarks.Caption := TrText('Clear a&ll bookmarks');
  FToolsExtrasClearBookmarks.OnClick := miClearBookmarksClick;
  FToolsExtrasClearBookmarks.ShortCut := ShortCut(Ord('B'), [ssCtrl, ssShift]);
  FToolsExtrasClearBookmarks.ImageIndex := MenuIconIndex('pushpin.bmp', 31);
  PopupMenu1.Items.Insert(FToolsExtrasReadOnly.MenuIndex, FToolsExtrasClearBookmarks);
end;

procedure TfrmMain.UpdateToolsPopupFastFileExtrasCaptions;
begin
  if Assigned(FToolsExtrasSep) then
    FToolsExtrasSep.Caption := '-';
  if Assigned(FToolsExtrasWordWrap) then
    FToolsExtrasWordWrap.Caption := TrText('&Word wrap');
  if Assigned(FToolsExtrasReadOnly) then
    FToolsExtrasReadOnly.Caption := TrText('Read-only &session');
  if Assigned(FToolsExtrasSegmented) then
    FToolsExtrasSegmented.Caption := TrText('Line-segmented &mode (heavy ops)');
  if Assigned(FToolsExtrasTail) then
    FToolsExtrasTail.Caption := TrText('Tail / &Follow mode');
  if Assigned(FToolsExtrasFilter) then
    FToolsExtrasFilter.Caption := TrText('Fil&ter / Grep');
  if Assigned(FToolsExtrasExportFiltered) then
    FToolsExtrasExportFiltered.Caption := TrText('E&xport filtered results');
  if Assigned(FToolsExtrasToggleBookmark) then
    FToolsExtrasToggleBookmark.Caption := TrText('&Toggle bookmark');
  if Assigned(FToolsExtrasNextBookmark) then
    FToolsExtrasNextBookmark.Caption := TrText('&Next bookmark');
  if Assigned(FToolsExtrasPrevBookmark) then
    FToolsExtrasPrevBookmark.Caption := TrText('Pr&evious bookmark');
  if Assigned(FToolsExtrasClearBookmarks) then
    FToolsExtrasClearBookmarks.Caption := TrText('Clear a&ll bookmarks');
end;

function TfrmMain.MenuIconIndex(const AFileName: string; const AFallbackIndex: Integer = -1): Integer;
begin
  Result := AFallbackIndex;
  if Assigned(FMenuIconIndexByName) then
    Result := StrToIntDef(FMenuIconIndexByName.Values[LowerCase(AFileName)], AFallbackIndex);
end;

procedure TfrmMain.EnsureConsumerAIPanel;
var
  TargetParent: TWinControl;
  InputHost: TsPanel;
begin
  if Assigned(FConsumerAIPanel) then
    Exit;

  if Assigned(pnlCenter) then
    TargetParent := pnlCenter
  else
    TargetParent := pnlMain;

  TargetParent.DisableAlign;
  try
    FConsumerAIPanel := TsPanel.Create(Self);
    FConsumerAIPanel.Parent := TargetParent;
    FConsumerAIPanel.Align := alRight;
    FConsumerAIPanel.Width := 360;
    FConsumerAIPanel.BevelOuter := bvNone;
    FConsumerAIPanel.Caption := '';
    FConsumerAIPanel.Visible := False;
    FConsumerAIPanel.DoubleBuffered := True;

    FConsumerAIHeaderPanel := TsPanel.Create(Self);
    FConsumerAIHeaderPanel.Parent := FConsumerAIPanel;
    FConsumerAIHeaderPanel.Align := alTop;
    FConsumerAIHeaderPanel.Height := 34;
    FConsumerAIHeaderPanel.Caption := '';
    FConsumerAIHeaderPanel.Alignment := taLeftJustify;
    FConsumerAIHeaderPanel.BevelOuter := bvNone;

    { Close first occupies far-right position with alRight; fixes overflow bug }
    FConsumerAICloseButton := TsSpeedButton.Create(Self);
    FConsumerAICloseButton.Parent := FConsumerAIHeaderPanel;
    FConsumerAICloseButton.Align := alRight;
    FConsumerAICloseButton.Width := 60;
    FConsumerAICloseButton.Caption := TrText('Close');
    FConsumerAICloseButton.OnClick := ConsumerAICloseClick;

    FConsumerAIExportButton := TsSpeedButton.Create(Self);
    FConsumerAIExportButton.Parent := FConsumerAIHeaderPanel;
    FConsumerAIExportButton.Align := alRight;
    FConsumerAIExportButton.Width := 96;
    FConsumerAIExportButton.Caption := TrText('Export transcript');
    FConsumerAIExportButton.OnClick := ConsumerAIExportClick;

    FConsumerAIClearButton := TsSpeedButton.Create(Self);
    FConsumerAIClearButton.Parent := FConsumerAIHeaderPanel;
    FConsumerAIClearButton.Align := alRight;
    FConsumerAIClearButton.Width := 86;
    FConsumerAIClearButton.Caption := TrText('Clear transcript');
    FConsumerAIClearButton.OnClick := ConsumerAIClearClick;

    FConsumerAIRestartButton := TsSpeedButton.Create(Self);
    FConsumerAIRestartButton.Parent := FConsumerAIHeaderPanel;
    FConsumerAIRestartButton.Align := alRight;
    FConsumerAIRestartButton.Width := 88;
    FConsumerAIRestartButton.Caption := TrText('Restart session');
    FConsumerAIRestartButton.OnClick := ConsumerAIRestartClick;

    { Left area intentionally kept without title text }
    FConsumerAITitleLabel := TsLabel.Create(Self);
    FConsumerAITitleLabel.Parent := FConsumerAIHeaderPanel;
    FConsumerAITitleLabel.Align := alClient;
    FConsumerAITitleLabel.Caption := '';
    FConsumerAITitleLabel.Layout := tlCenter;
    FConsumerAITitleLabel.Transparent := True;

    FConsumerAIMemo := TRichEdit.Create(Self);
    FConsumerAIMemo.Parent := FConsumerAIPanel;
    FConsumerAIMemo.Align := alClient;
    FConsumerAIMemo.ReadOnly := True;
    FConsumerAIMemo.ScrollBars := ssVertical;
    FConsumerAIMemo.WordWrap := True;
    FConsumerAIMemo.HideScrollBars := False;
    FConsumerAIMemo.WantReturns := False;
    FConsumerAIMemo.WantTabs := False;
    FConsumerAIMemo.Font.Name := 'Consolas';
    FConsumerAIMemo.Font.Size := 9;
    FConsumerAIMemo.HideSelection := False;
    FConsumerAIMemo.Lines.Text :=
      TrText('AI workspace panel.') + sLineBreak + sLineBreak +
      TrText('Click the Consumer AI button to start an inter-application session.');

    FConsumerAIPopupMenu := TPopupMenu.Create(Self);
    FConsumerAIPopupMenu.OnPopup := ConsumerAIPopupPopup;

    FConsumerAIPopupSelectAllItem := TMenuItem.Create(FConsumerAIPopupMenu);
    FConsumerAIPopupSelectAllItem.Caption := TrText('Select all');
    FConsumerAIPopupSelectAllItem.OnClick := ConsumerAIPopupSelectAllClick;
    FConsumerAIPopupMenu.Items.Add(FConsumerAIPopupSelectAllItem);

    FConsumerAIPopupCopyItem := TMenuItem.Create(FConsumerAIPopupMenu);
    FConsumerAIPopupCopyItem.Caption := TrText('Copy');
    FConsumerAIPopupCopyItem.OnClick := ConsumerAIPopupCopyClick;
    FConsumerAIPopupMenu.Items.Add(FConsumerAIPopupCopyItem);

    FConsumerAIPopupMenu.Items.Add(TMenuItem.Create(FConsumerAIPopupMenu));
    FConsumerAIPopupMenu.Items[FConsumerAIPopupMenu.Items.Count - 1].Caption := '-';

    FConsumerAIPopupExportItem := TMenuItem.Create(FConsumerAIPopupMenu);
    FConsumerAIPopupExportItem.Caption := TrText('Export transcript');
    FConsumerAIPopupExportItem.OnClick := ConsumerAIPopupExportClick;
    FConsumerAIPopupMenu.Items.Add(FConsumerAIPopupExportItem);

    FConsumerAIMemo.PopupMenu := FConsumerAIPopupMenu;

    FConsumerAIInputPanel := TsPanel.Create(Self);
    FConsumerAIInputPanel.Parent := FConsumerAIPanel;
    FConsumerAIInputPanel.Align := alBottom;
    FConsumerAIInputPanel.Height := 64;
    FConsumerAIInputPanel.BevelOuter := bvNone;
    FConsumerAIInputPanel.Caption := '';

    FConsumerAIStatusLabel := TsLabel.Create(Self);
    FConsumerAIStatusLabel.Parent := FConsumerAIInputPanel;
    FConsumerAIStatusLabel.Align := alTop;
    FConsumerAIStatusLabel.Height := 18;
    FConsumerAIStatusLabel.Caption := TrText('Disconnected');

    FConsumerAIOptionsPanel := TsPanel.Create(Self);
    FConsumerAIOptionsPanel.Parent := FConsumerAIInputPanel;
    FConsumerAIOptionsPanel.Align := alTop;
    FConsumerAIOptionsPanel.Height := 0;
    FConsumerAIOptionsPanel.BevelOuter := bvNone;
    FConsumerAIOptionsPanel.Caption := '';
    FConsumerAIOptionsPanel.Visible := False;

    InputHost := TsPanel.Create(Self);
    InputHost.Parent := FConsumerAIInputPanel;
    InputHost.Align := alBottom;
    InputHost.Height := 36;
    InputHost.BevelOuter := bvNone;
    InputHost.Caption := '';

    FConsumerAISendButton := TsSpeedButton.Create(Self);
    FConsumerAISendButton.Parent := InputHost;
    FConsumerAISendButton.Align := alRight;
    FConsumerAISendButton.Width := 70;
    FConsumerAISendButton.Caption := TrText('Send');
    FConsumerAISendButton.Enabled := False;
    FConsumerAISendButton.OnClick := ConsumerAISendClick;

    FConsumerAIInputEdit := TEdit.Create(Self);
    FConsumerAIInputEdit.Parent := InputHost;
    FConsumerAIInputEdit.Align := alClient;
    FConsumerAIInputEdit.Text := '';
    FConsumerAIInputEdit.Enabled := False;
    FConsumerAIInputEdit.OnKeyDown := ConsumerAIInputKeyDown;
    FConsumerAIInputEdit.OnChange := ConsumerAIInputChange;

    if Assigned(splListview) then
    begin
      if splListview.Parent <> TargetParent then
        splListview.Parent := TargetParent;
      splListview.Align := alRight;
      splListview.Width := 4;
      splListview.MinSize := 220;
      splListview.Visible := False;
      splListview.AutoSnap := False;
    end;
  finally
    TargetParent.EnableAlign;
  end;
end;

procedure TfrmMain.ShowConsumerAIPanel;
var
  TargetParent: TWinControl;
begin
  EnsureConsumerAIPanel;

  if not Assigned(FConsumerAIPanel) then Exit;
  if FConsumerAIPanel.Visible then Exit;

  if Assigned(FConsumerAIPanel.Parent) then
    TargetParent := FConsumerAIPanel.Parent
  else if Assigned(pnlCenter) then
    TargetParent := pnlCenter
  else
    TargetParent := pnlMain;

  TargetParent.DisableAlign;
  if Assigned(ListView1) and ListView1.HandleAllocated then
    ListView1.Perform(WM_SETREDRAW, 0, 0);
  if TargetParent.HandleAllocated then
    SendMessage(TargetParent.Handle, WM_SETREDRAW, 0, 0);
  try

  if Assigned(FConsumerAITitleLabel) then
    FConsumerAITitleLabel.Caption := '';
  if Assigned(FConsumerAIExportButton) then
    FConsumerAIExportButton.Caption := TrText('Export transcript');
  if Assigned(FConsumerAIClearButton) then
    FConsumerAIClearButton.Caption := TrText('Clear transcript');
  if Assigned(FConsumerAIRestartButton) then
    FConsumerAIRestartButton.Caption := TrText('Restart session');
  if Assigned(FConsumerAICloseButton) then
    FConsumerAICloseButton.Caption := TrText('Close');
  if Assigned(FConsumerAIPopupSelectAllItem) then
    FConsumerAIPopupSelectAllItem.Caption := TrText('Select all');
  if Assigned(FConsumerAIPopupCopyItem) then
    FConsumerAIPopupCopyItem.Caption := TrText('Copy');
  if Assigned(FConsumerAIPopupExportItem) then
    FConsumerAIPopupExportItem.Caption := TrText('Export transcript');
  if Assigned(FConsumerAISendButton) then
    FConsumerAISendButton.Caption := TrText('Send');
  if Assigned(FConsumerAIStatusLabel) then
    FConsumerAIStatusLabel.Caption := TrText('Disconnected');

    FConsumerAIPanel.Visible := True;

  if Assigned(splListview) then
  begin
    splListview.Visible := True;
    splListview.BringToFront;
  end;
  finally
    if TargetParent.HandleAllocated then
      SendMessage(TargetParent.Handle, WM_SETREDRAW, 1, 0);
    if Assigned(ListView1) and ListView1.HandleAllocated then
    begin
      ListView1.Perform(WM_SETREDRAW, 1, 0);
      RedrawWindow(ListView1.Handle, nil, 0,
        RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_UPDATENOW);
    end;
    TargetParent.EnableAlign;
    if TargetParent.HandleAllocated then
      RedrawWindow(TargetParent.Handle, nil, 0,
        RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_UPDATENOW);
  end;
end;

procedure TfrmMain.HideConsumerAIPanel;
var
  TargetParent: TWinControl;
begin
  if not Assigned(FConsumerAIPanel) then Exit;

  if Assigned(FConsumerAIPanel.Parent) then
    TargetParent := FConsumerAIPanel.Parent
  else if Assigned(pnlCenter) then
    TargetParent := pnlCenter
  else
    TargetParent := pnlMain;

  TargetParent.DisableAlign;
  if Assigned(ListView1) and ListView1.HandleAllocated then
    ListView1.Perform(WM_SETREDRAW, 0, 0);
  if TargetParent.HandleAllocated then
    SendMessage(TargetParent.Handle, WM_SETREDRAW, 0, 0);
  try
    FConsumerAIPanel.Visible := False;
    if Assigned(splListview) then
      splListview.Visible := False;
  finally
    if TargetParent.HandleAllocated then
      SendMessage(TargetParent.Handle, WM_SETREDRAW, 1, 0);
    if Assigned(ListView1) and ListView1.HandleAllocated then
    begin
      ListView1.Perform(WM_SETREDRAW, 1, 0);
      RedrawWindow(ListView1.Handle, nil, 0,
        RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_UPDATENOW);
    end;
    TargetParent.EnableAlign;
    if TargetParent.HandleAllocated then
      RedrawWindow(TargetParent.Handle, nil, 0,
        RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_UPDATENOW);
  end;
end;

procedure TfrmMain.ConsumerAICloseClick(Sender: TObject);
begin
  StopConsumerAIProcess;
  HideConsumerAIPanel;
end;

procedure TfrmMain.ConsumerAIClearClick(Sender: TObject);
begin
  if Assigned(FConsumerAIMemo) then
    FConsumerAIMemo.Clear;
  ClearConsumerAIOptionButtons;
  AppendConsumerAITranscriptEx('STATUS', TrText('Transcript cleared'));
end;

procedure TfrmMain.ConsumerAIExportClick(Sender: TObject);
var
  SD: TSaveDialog;
  SL: TStringList;
begin
  if (not Assigned(FConsumerAIMemo)) or (Trim(FConsumerAIMemo.Text) = '') then
  begin
    AppendConsumerAITranscriptEx('STATUS', TrText('Nothing to export'));
    Exit;
  end;

  SD := TSaveDialog.Create(nil);
  try
    SD.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    SD.DefaultExt := 'txt';
    SD.FileName := 'consumer_ai_transcript_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt';
    if SD.Execute then
    begin
      { TRichEdit.Lines.SaveToFile writes RTF payload; export plain text explicitly. }
      SL := TStringList.Create;
      try
        SL.Text := FConsumerAIMemo.Text;
        SL.SaveToFile(SD.FileName);
      finally
        SL.Free;
      end;
      AppendConsumerAITranscriptEx('STATUS', TrText('Transcript exported to: ') + SD.FileName);
    end;
  finally
    SD.Free;
  end;
end;

procedure TfrmMain.ConsumerAIRestartClick(Sender: TObject);
begin
  StopConsumerAIProcess;
  StartConsumerAIProcess;
end;

procedure TfrmMain.UpdateConsumerAIInputPanelHeight;
const
  BASE_H = 64;
  OPTIONS_EXTRA = 30;
begin
  if not Assigned(FConsumerAIInputPanel) then Exit;
  if Assigned(FConsumerAIOptionsPanel) and FConsumerAIOptionsPanel.Visible and
     (FConsumerAIOptionsPanel.ControlCount > 0) then
    FConsumerAIInputPanel.Height := BASE_H + OPTIONS_EXTRA
  else
    FConsumerAIInputPanel.Height := BASE_H;
end;

procedure TfrmMain.ClearConsumerAIOptionButtons;
var
  I: Integer;
begin
  if not Assigned(FConsumerAIOptionsPanel) then Exit;
  for I := FConsumerAIOptionsPanel.ControlCount - 1 downto 0 do
    FConsumerAIOptionsPanel.Controls[I].Free;
  FConsumerAIOptionsPanel.Height := 0;
  FConsumerAIOptionsPanel.Visible := False;
  UpdateConsumerAIInputPanelHeight;
end;

procedure TfrmMain.RebuildConsumerAIOptionButtons(const ACsv: string);
var
  S, Part: string;
  P: Integer;
  X, BtnW: Integer;
  Btn: TsSpeedButton;
  Bmp: TBitmap;
  Tok: string;
begin
  EnsureConsumerAIPanel;
  ClearConsumerAIOptionButtons;
  S := Trim(ACsv);
  if S = '' then Exit;

  Bmp := TBitmap.Create;
  try
    if Assigned(FConsumerAIInputEdit) then
      Bmp.Canvas.Font.Assign(FConsumerAIInputEdit.Font)
    else if Assigned(FConsumerAIPanel) then
      Bmp.Canvas.Font.Assign(FConsumerAIPanel.Font);
    X := 4;
    FConsumerAIOptionsPanel.Visible := True;
    FConsumerAIOptionsPanel.Height := 30;

    while S <> '' do
    begin
      P := Pos(',', S);
      if P > 0 then
      begin
        Part := Trim(Copy(S, 1, P - 1));
        Delete(S, 1, P);
      end
      else
      begin
        Part := Trim(S);
        S := '';
      end;
      Tok := Part;
      if Tok = '' then Continue;

      Btn := TsSpeedButton.Create(Self);
      Btn.Parent := FConsumerAIOptionsPanel;
      Btn.Flat := True;
      Btn.Caption := Tok;
      Btn.Hint := Tok;
      Btn.ShowHint := False;
      Btn.Height := 22;
      BtnW := Bmp.Canvas.TextWidth(Tok) + 16;
      if BtnW < 32 then BtnW := 32;
      if BtnW > 100 then BtnW := 100;
      Btn.Width := BtnW;
      Btn.Left := X;
      Btn.Top := 4;
      Btn.OnClick := ConsumerAIOptionButtonClick;
      Inc(X, Btn.Width + 4);
    end;
  finally
    Bmp.Free;
  end;

  if FConsumerAIOptionsPanel.ControlCount = 0 then
    ClearConsumerAIOptionButtons
  else
    UpdateConsumerAIInputPanelHeight;
end;

procedure TfrmMain.ConsumerAIOptionButtonClick(Sender: TObject);
var
  S: string;
begin
  if not (Sender is TsSpeedButton) then Exit;
  S := Trim(TsSpeedButton(Sender).Hint);
  if S = '' then
    S := Trim(TsSpeedButton(Sender).Caption);
  if not ConsumerAIWriteLine(S) then Exit;
  AppendConsumerAITranscriptEx('YOU', S);
  ClearConsumerAIOptionButtons;
  if Assigned(FConsumerAIInputEdit) then
  begin
    FConsumerAIInputEdit.Text := '';
    FConsumerAIInputEdit.Enabled := False;
  end;
  if Assigned(FConsumerAISendButton) then
    FConsumerAISendButton.Enabled := False;
  SetConsumerAIStatus(TrText('Waiting for Python...'));
end;

procedure TfrmMain.ConsumerAISendClick(Sender: TObject);
var
  TextToSend: string;
begin
  if not Assigned(FConsumerAIInputEdit) then Exit;

  TextToSend := FConsumerAIInputEdit.Text;
  if ConsumerAIWriteLine(TextToSend) then
  begin
    if TextToSend = '' then
      AppendConsumerAITranscriptEx('YOU', '[ENTER]')
    else
      AppendConsumerAITranscriptEx('YOU', TextToSend);
    ClearConsumerAIOptionButtons;
    UpdateConsumerAIInputPanelHeight;
    FConsumerAIInputEdit.Text := '';
    FConsumerAIInputEdit.Enabled := False;
    if Assigned(FConsumerAISendButton) then
      FConsumerAISendButton.Enabled := False;
    SetConsumerAIStatus(TrText('Waiting for Python...'));
  end;
end;

procedure TfrmMain.ConsumerAIPopupSelectAllClick(Sender: TObject);
begin
  if not Assigned(FConsumerAIMemo) then Exit;
  FConsumerAIMemo.SelectAll;
  FConsumerAIMemo.SetFocus;
end;

procedure TfrmMain.ConsumerAIPopupCopyClick(Sender: TObject);
begin
  if not Assigned(FConsumerAIMemo) then Exit;
  FConsumerAIMemo.CopyToClipboard;
end;

procedure TfrmMain.ConsumerAIPopupExportClick(Sender: TObject);
begin
  ConsumerAIExportClick(Sender);
end;

procedure TfrmMain.ConsumerAIPopupPopup(Sender: TObject);
begin
  if Assigned(FConsumerAIPopupCopyItem) and Assigned(FConsumerAIMemo) then
    FConsumerAIPopupCopyItem.Enabled := FConsumerAIMemo.SelLength > 0;
  if Assigned(FConsumerAIPopupSelectAllItem) and Assigned(FConsumerAIMemo) then
    FConsumerAIPopupSelectAllItem.Enabled := FConsumerAIMemo.GetTextLen > 0;
  if Assigned(FConsumerAIPopupExportItem) and Assigned(FConsumerAIMemo) then
    FConsumerAIPopupExportItem.Enabled := Trim(FConsumerAIMemo.Text) <> '';
end;

procedure TfrmMain.ConsumerAIInputKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) then
  begin
    Key := 0;
    ConsumerAISendClick(Sender);
  end;
end;

function TfrmMain.ExtractConsumerAIOptionsFromPrompt(const APrompt: string): string;
var
  Tokens: TStringList;
  Parts: TStringList;
  S, GroupText: string;
  I, J, K: Integer;
  RangeStart, RangeEnd, RangeValue: Integer;

  function IsOptionNoiseWord(const T: string): Boolean;
  begin
    { Mesma ideia do SKIP_WORDS em ConsumerAI_LanceDB._extract_options_from_prompt:
      tokens que aparecem dentro de grupos (...) mas nao sao atalhos. }
    Result :=
      (T = 'or') or (T = 'to') or (T = 'and') or (T = 'exit') or (T = 'return') or
      (T = 'yes') or (T = 'no') or (T = 'menu') or (T = 'prev') or (T = 'press') or
      (T = 'enter') or (T = 'try') or (T = 'again') or (T = 'current') or (T = 'end') or
      (T = 'back');
  end;

  procedure AddToken(const ARaw: string);
  var
    T: string;
    P: Integer;
    IsValid: Boolean;
  begin
    T := LowerCase(Trim(ARaw));
    T := StringReplace(T, '"', '', [rfReplaceAll]);
    T := StringReplace(T, '''', '', [rfReplaceAll]);

    while (Length(T) > 0) and not (T[1] in ['0'..'9', 'a'..'z']) do
      Delete(T, 1, 1);
    while (Length(T) > 0) and not (T[Length(T)] in ['0'..'9', 'a'..'z']) do
      Delete(T, Length(T), 1);

    if (T = '') or (Length(T) > 5) then Exit;
    if IsOptionNoiseWord(T) then Exit;

    IsValid := True;
    for P := 1 to Length(T) do
      if not (T[P] in ['0'..'9', 'a'..'z']) then
      begin
        IsValid := False;
        Break;
      end;

    if IsValid and (Tokens.IndexOf(T) < 0) then
      Tokens.Add(T);
  end;

  procedure AddLeadingToken(const ARaw: string);
  var
    RawText: string;
    P: Integer;
    T: string;
  begin
    RawText := Trim(ARaw);
    if RawText = '' then Exit;
    if RawText[1] in ['''', '"'] then Exit;

    T := '';
    for P := 1 to Length(RawText) do
    begin
      if RawText[P] in ['0'..'9', 'a'..'z', 'A'..'Z'] then
        T := T + RawText[P]
      else
        Break;
    end;

    if T <> '' then
      AddToken(T);
  end;

begin
  Result := '';
  Tokens := TStringList.Create;
  Parts := TStringList.Create;
  try
    Tokens.Sorted := False;
    Tokens.Duplicates := dupIgnore;

    S := APrompt;
    I := 1;
    while I <= Length(S) do
    begin
      if S[I] = '(' then
      begin
        J := I + 1;
        while (J <= Length(S)) and (S[J] <> ')') do
          Inc(J);

        if (J <= Length(S)) and (J > I + 1) then
        begin
          GroupText := Copy(S, I + 1, J - I - 1);

          if (J < Length(S)) and (S[I + 1] in ['0'..'9', 'a'..'z', 'A'..'Z']) and
             (S[J + 1] in ['a'..'z', 'A'..'Z']) and (Length(GroupText) = 1) then
            AddToken(GroupText);

          if (Pos('/', GroupText) > 0) or (Pos(',', GroupText) > 0) then
          begin
            Parts.Clear;
            Parts.Delimiter := '/';
            Parts.DelimitedText := StringReplace(GroupText, ',', '/', [rfReplaceAll]);
            for K := 0 to Parts.Count - 1 do
            begin
              AddToken(Parts[K]);
              AddLeadingToken(Parts[K]);
            end;
          end
          else
          begin
            // Numeric range shortcut, e.g. (1-6) => 1,2,3,4,5,6
            Parts.Clear;
            Parts.Delimiter := '-';
            Parts.DelimitedText := GroupText;
            if Parts.Count = 2 then
            begin
              RangeStart := StrToIntDef(Trim(Parts[0]), -1);
              RangeEnd := StrToIntDef(Trim(Parts[1]), -1);
              if (RangeStart >= 0) and (RangeEnd >= RangeStart) and ((RangeEnd - RangeStart) <= 30) then
              begin
                for RangeValue := RangeStart to RangeEnd do
                  AddToken(IntToStr(RangeValue));
              end;
            end;
          end;

          K := 1;
          while K <= Length(GroupText) - 2 do
          begin
            if (GroupText[K] = '''') and (GroupText[K + 2] = '''') then
            begin
              AddToken(GroupText[K + 1]);
              Inc(K, 3);
              Continue;
            end;
            Inc(K);
          end;

          I := J;
        end;
      end;
      Inc(I);
    end;

    { Padrao (x)palavra — letra entre parenteses seguida de letra (ex.: (v)iew, (r)eplace). }
    I := 1;
    while I + 3 <= Length(S) do
    begin
      if (S[I] = '(') and (S[I + 1] in ['a'..'z', 'A'..'Z']) and (S[I + 2] = ')') and
         (S[I + 3] in ['a'..'z', 'A'..'Z']) then
      begin
        AddToken(S[I + 1]);
        Inc(I, 3);
      end
      else
        Inc(I);
    end;

    for I := 0 to Tokens.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + Tokens[I];
    end;
  finally
    Parts.Free;
    Tokens.Free;
  end;
end;

function TfrmMain.ShouldSuppressConsumerAIOutput(const AText: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(AText));
  Result :=
    (L = '') or
    (Pos('initializing fastfile ai', L) = 1) or
    (Pos('fastfile ai - version', L) = 1) or
    (L = 'fastfile ai') or
    (Pos('version:', L) = 1) or
    (Pos('copyright:', L) = 1) or
    (Pos('preparing temporary file', L) > 0) or
    (Pos('creates a working temporary file', L) > 0) or
    (Pos('automatic cleanup is enabled:', L) > 0);
end;


procedure TfrmMain.ConsumerAIInputChange(Sender: TObject);
begin
  if Assigned(FConsumerAISendButton) and Assigned(FConsumerAIInputEdit) then
    FConsumerAISendButton.Enabled := (Trim(FConsumerAIInputEdit.Text) <> '')
      and FConsumerAIInputEdit.Enabled;
end;

procedure TfrmMain.AppendConsumerAITranscript(const AText: string);
begin
  AppendConsumerAITranscriptEx('INFO', AText);
end;

procedure TfrmMain.TrimConsumerAITranscript;
var
  Extra: Integer;
  MaxLines: Integer;
  TrimTo: Integer;
begin
  MaxLines := sStoreUtils.ReadIniInteger(APPLICATION_NAME,
    'ConsumerAITranscriptMaxLines', 3000, IniName);
  TrimTo := sStoreUtils.ReadIniInteger(APPLICATION_NAME,
    'ConsumerAITranscriptTrimTo', 2600, IniName);

  if MaxLines < 200 then
    MaxLines := 200;
  if TrimTo < 100 then
    TrimTo := 100;
  if TrimTo >= MaxLines then
    TrimTo := MaxLines - 50;

  if (not Assigned(FConsumerAIMemo)) or (FConsumerAIMemo.Lines.Count <= MaxLines) then
    Exit;

  Extra := FConsumerAIMemo.Lines.Count - TrimTo;
  while Extra > 0 do
  begin
    FConsumerAIMemo.Lines.Delete(0);
    Dec(Extra);
  end;
end;

procedure TfrmMain.AppendConsumerAITranscriptEx(const AKind, AText: string);
var
  Stamp: string;
  KindText: string;
  LineText: string;
  KindColor: TColor;
begin
  EnsureConsumerAIPanel;
  if not Assigned(FConsumerAIMemo) then Exit;

  Stamp := FormatDateTime('hh:nn:ss', Now);
  KindText := UpperCase(Trim(AKind));
  if KindText = '' then
    KindText := 'INFO';
  LineText := '[' + Stamp + '] [' + KindText + '] ' + AText;

  KindColor := clWindowText;
  if KindText = 'ERROR' then
    KindColor := clRed
  else if KindText = 'PROMPT' then
    KindColor := clNavy
  else if KindText = 'STATUS' then
    KindColor := clTeal
  else if KindText = 'YOU' then
    KindColor := clPurple
  else if KindText = 'PY' then
    KindColor := clBlack;

  FConsumerAIMemo.Lines.BeginUpdate;
  try
    FConsumerAIMemo.SelStart := Length(FConsumerAIMemo.Text);
    FConsumerAIMemo.SelLength := 0;
    FConsumerAIMemo.SelAttributes.Color := KindColor;
    FConsumerAIMemo.SelText := LineText + sLineBreak;
    FConsumerAIMemo.SelAttributes.Color := clWindowText;
    TrimConsumerAITranscript;
    FConsumerAIMemo.SelStart := Length(FConsumerAIMemo.Text);
    FConsumerAIMemo.Perform(EM_SCROLLCARET, 0, 0);
  finally
    FConsumerAIMemo.Lines.EndUpdate;
  end;
end;

procedure TfrmMain.SetConsumerAIStatus(const AText: string);
begin
  if Assigned(FConsumerAIStatusLabel) then
    FConsumerAIStatusLabel.Caption := AText;
  if Assigned(FConsumerAITitleLabel) then
    FConsumerAITitleLabel.Caption := '';
end;

procedure TfrmMain.HandleConsumerAIProtocolLine(const ALine: string);
const
  BRIDGE_PREFIX = 'FFBRIDGE|';
var
  PrefixPos: Integer;
  Rest: string;
  SepPos: Integer;
  Kind: string;
  Payload: string;
  LocalizedLine: string;
  VersionPos: Integer;
  InferredOptions: string;

  procedure ApplyPromptUI(const APrompt: string; const AAppendPrompt: Boolean);
  var
    WorkPrompt: string;
  begin
    WorkPrompt := Trim(APrompt);
    if WorkPrompt = '' then
      WorkPrompt := Trim(FConsumerAILastPrompt);

    if WorkPrompt <> '' then
      FConsumerAILastPrompt := WorkPrompt;

    if AAppendPrompt and (WorkPrompt <> '') then
      AppendConsumerAITranscriptEx('PROMPT', WorkPrompt);

    SetConsumerAIStatus(TrText('Awaiting input'));
    if Assigned(FConsumerAIInputEdit) then
    begin
      FConsumerAIInputEdit.Enabled := True;
      FConsumerAIInputEdit.SetFocus;
    end;
  end;

begin
  LogConsumerAIDebug('RECV | ' + ALine);

  LocalizedLine := ALine;
  if Pos('Starting Consumer AI FastFile', LocalizedLine) = 1 then
    LocalizedLine := Tr('consumer_ai.initializing', 'Initializing FastFile AI...')
  else if Pos('Initializing FastFile AI', LocalizedLine) = 1 then
    LocalizedLine := Tr('consumer_ai.initializing', 'Initializing FastFile AI...')
  else if Pos('Consumer AI FastFile', LocalizedLine) = 1 then
  begin
    VersionPos := Pos(' - Version ', LocalizedLine);
    if VersionPos > 0 then
      LocalizedLine := Tr('consumer_ai.program_version_prefix', 'FastFile AI - Version ') +
        Copy(LocalizedLine, VersionPos + Length(' - Version '), MaxInt);
  end;

  PrefixPos := Pos(BRIDGE_PREFIX, LocalizedLine);
  if PrefixPos > 0 then
  begin
    if PrefixPos > 1 then
      AppendConsumerAITranscriptEx('PY', Trim(Copy(LocalizedLine, 1, PrefixPos - 1)));

    Rest := Copy(LocalizedLine, PrefixPos + Length(BRIDGE_PREFIX), MaxInt);
    SepPos := Pos('|', Rest);
    if SepPos > 0 then
    begin
      Kind := UpperCase(Copy(Rest, 1, SepPos - 1));
      Payload := Copy(Rest, SepPos + 1, MaxInt);
    end
    else
    begin
      Kind := 'OUTPUT';
      Payload := Rest;
    end;

    if Kind = 'OUTPUT' then
    begin
      { Nao inferir botoes a partir de OUTPUT: o Rich envia muitas linhas (tabelas/painéis)
        com parenteses e numeros; isso disparava RebuildConsumerAIOptionButtons com listas
        erraticas ou competia com FFBRIDGE|OPTIONS| enviado logo apos por bridge_input. }
      if not ShouldSuppressConsumerAIOutput(Payload) then
        AppendConsumerAITranscriptEx('PY', Payload);
      Exit;
    end;

    if Kind = 'OPTIONS' then
    begin
      { Python bridge_input emite OPTIONS antes do PROMPT (lista dinamica, ex.: y,n,idk,q). }
      RebuildConsumerAIOptionButtons(Payload);
      Exit;
    end;

    if Kind = 'PROMPT' then
    begin
      if Trim(Payload) = '' then
        Payload := FConsumerAILastPrompt;
      InferredOptions := ExtractConsumerAIOptionsFromPrompt(Payload);
      ApplyPromptUI(Payload, True);
      { Se nao veio linha OPTIONS (ou veio vazia), inferir botoes a partir do texto do prompt. }
      if (not Assigned(FConsumerAIOptionsPanel)) or (not FConsumerAIOptionsPanel.Visible) or
         (FConsumerAIOptionsPanel.ControlCount = 0) then
      begin
        if InferredOptions <> '' then
          RebuildConsumerAIOptionButtons(InferredOptions);
      end;
      { Send button enabled by OnChange when user types }
      Exit;
    end;

    if Kind = 'STATUS' then
    begin
      if Payload <> '' then
      begin
        if (Pos('mode enabled', LowerCase(Payload)) > 0) then
          Payload := Tr('consumer_ai.connected', 'FastFile AI connected');
        SetConsumerAIStatus(Payload);
      end;
      Exit;
    end;

    if Kind = 'ERROR' then
    begin
      AppendConsumerAITranscriptEx('ERROR', Payload);
      SetConsumerAIStatus(TrText('Error'));
      Exit;
    end;
  end;

  InferredOptions := ExtractConsumerAIOptionsFromPrompt(LocalizedLine);
  if InferredOptions <> '' then
  begin
    ApplyPromptUI(LocalizedLine, False);
    RebuildConsumerAIOptionButtons(InferredOptions);
  end;

  if (LocalizedLine <> '') and (not ShouldSuppressConsumerAIOutput(LocalizedLine)) then
    AppendConsumerAITranscriptEx('PY', LocalizedLine);
end;

function TfrmMain.ResolveConsumerAIScriptPath: string;
begin
  Result := '';
  Result := ExpandFileName(ExtractFilePath(Application.ExeName) + 'ConsumerAI.exe');
  if not FileExists(Result) then
    Result := '';
end;

function TfrmMain.ResolveConsumerAILogPath: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'ConsumerAI_Session_Debug.log';
end;

procedure TfrmMain.LogConsumerAIDebug(const AText: string);
begin
  { Session debug log intentionally disabled to avoid creating ConsumerAI_Session_Debug.log. }
end;

function TfrmMain.ConsumerAIWriteLine(const AText: string): Boolean;
var
  Data: UTF8String;
  BytesWritten: DWORD;
begin
  Result := False;
  if (not FConsumerAIProcessRunning) or (FConsumerAIStdInWrite = 0) or
     (FConsumerAIStdInWrite = INVALID_HANDLE_VALUE) then Exit;

  Data := UTF8Encode(AText + #10);
  Result := Windows.WriteFile(FConsumerAIStdInWrite, Pointer(Data)^,
    Length(Data), BytesWritten, nil) and (BytesWritten = DWORD(Length(Data)));
  if Result then
    LogConsumerAIDebug('SEND | ' + AText)
  else
    LogConsumerAIDebug('SEND_ERROR | Failed to write to stdin pipe');
end;

procedure TfrmMain.StartConsumerAIProcess;
var
  Security: TSecurityAttributes;
  StdOutWrite: THandle;
  StdInRead: THandle;
  StartupInfo: TStartupInfo;
  ScriptPath: string;
  WorkingDir: string;
  FileName: string;
  CommandLine: string;
  Created: Boolean;
  LastErr: DWORD;
begin
  EnsureConsumerAIPanel;

  FileName := Trim(edtFileName.Text);
  if (FileName = '') or (not FileExists(FileName)) then
  begin
    SetConsumerAIStatus(TrText('No valid source file'));
    ShowMessage(TrText('Select a valid input file before starting Consumer AI.'));
    Exit;
  end;

  if FConsumerAIProcessRunning then
    StopConsumerAIProcess;

  ScriptPath := ResolveConsumerAIScriptPath;
  if ScriptPath = '' then
  begin
    SetConsumerAIStatus(TrText('Executable not found'));
    AppendConsumerAITranscriptEx('ERROR', TrText('FastFile AI engine not found.'));
    Exit;
  end;

  if Assigned(FConsumerAIMemo) then
    FConsumerAIMemo.Clear;

  AppendConsumerAITranscriptEx('STATUS', Tr('consumer_ai.starting_session', 'Starting FastFile AI inter-application session...'));
  SetConsumerAIStatus(TrText('Starting...'));
  if Assigned(FConsumerAIInputEdit) then
    FConsumerAIInputEdit.Enabled := False;
  if Assigned(FConsumerAISendButton) then
    FConsumerAISendButton.Enabled := False;
  if Assigned(FConsumerAIInputPanel) then FConsumerAIInputPanel.Height := 64;

  FillChar(Security, SizeOf(Security), 0);
  Security.nLength := SizeOf(Security);
  Security.bInheritHandle := True;

  StdOutWrite := 0;
  StdInRead := 0;
  FConsumerAIStdOutRead := 0;
  FConsumerAIStdInWrite := 0;
  FillChar(FConsumerAIProcessInfo, SizeOf(FConsumerAIProcessInfo), 0);

  if not CreatePipe(FConsumerAIStdOutRead, StdOutWrite, @Security, 0) then
  begin
    SetConsumerAIStatus(TrText('Pipe error'));
    AppendConsumerAITranscriptEx('ERROR', TrText('Could not create stdout pipe.'));
    Exit;
  end;
  SetHandleInformation(FConsumerAIStdOutRead, HANDLE_FLAG_INHERIT, 0);

  if not CreatePipe(StdInRead, FConsumerAIStdInWrite, @Security, 0) then
  begin
    CloseHandle(FConsumerAIStdOutRead);
    FConsumerAIStdOutRead := 0;
    SetConsumerAIStatus(TrText('Pipe error'));
    AppendConsumerAITranscriptEx('ERROR', TrText('Could not create stdin pipe.'));
    Exit;
  end;
  SetHandleInformation(FConsumerAIStdInWrite, HANDLE_FLAG_INHERIT, 0);

  FillChar(StartupInfo, SizeOf(StartupInfo), 0);
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  StartupInfo.wShowWindow := SW_HIDE;
  StartupInfo.hStdInput := StdInRead;
  StartupInfo.hStdOutput := StdOutWrite;
  StartupInfo.hStdError := StdOutWrite;

  WorkingDir := ExtractFilePath(ScriptPath);
  CommandLine := '"' + ScriptPath + '" -file "' + FileName + '" -rp -prompt --bridge';
  LogConsumerAIDebug('START | File=' + FileName);
  LogConsumerAIDebug('EXE | ' + ScriptPath);
  LogConsumerAIDebug('CMD_TRY | ' + CommandLine);

  { Garante modo bridge no Python mesmo se --bridge nao chegar em sys.argv (alguns launchers).
    ConsumerAI_LanceDB usa FF_FASTFILE_BRIDGE para ativar FFBRIDGE|OPTIONS|PROMPT e botoes no painel. }
  SetEnvironmentVariable('FF_FASTFILE_BRIDGE', '1');
  try
    Created := CreateProcess(nil, PChar(CommandLine), nil, nil, True,
      CREATE_NO_WINDOW, nil, PChar(WorkingDir), StartupInfo, FConsumerAIProcessInfo);
  finally
    SetEnvironmentVariable('FF_FASTFILE_BRIDGE', nil);
  end;

  if not Created then
  begin
    LastErr := GetLastError;
    LogConsumerAIDebug('CREATEPROCESS_FAIL | exe | LastError=' + IntToStr(LastErr) + ' | ' + SysErrorMessage(LastErr));
    // Legacy script mode (disabled):
    // CommandLine := 'py -3 -X utf8 "' + ScriptPath + '" -file "' + FileName + '" -rp -prompt --bridge';
  end;

  CloseHandle(StdOutWrite);
  CloseHandle(StdInRead);

  if not Created then
  begin
    if FConsumerAIStdOutRead <> 0 then
    begin
      CloseHandle(FConsumerAIStdOutRead);
      FConsumerAIStdOutRead := 0;
    end;
    if FConsumerAIStdInWrite <> 0 then
    begin
      CloseHandle(FConsumerAIStdInWrite);
      FConsumerAIStdInWrite := 0;
    end;
    SetConsumerAIStatus(TrText('Launch error'));
    AppendConsumerAITranscriptEx('ERROR', TrText('Could not start FastFile AI engine.'));
    LastErr := GetLastError;
    LogConsumerAIDebug('CREATEPROCESS_FAIL | LastError=' + IntToStr(LastErr) + ' | ' + SysErrorMessage(LastErr));
    Exit;
  end;

  FConsumerAIProcessRunning := True;
  FConsumerAIActiveFileName := FileName;
  FConsumerAILastPrompt := '';
  FConsumerAIReaderThread := TConsumerAIReaderThread.Create(Self, FConsumerAIStdOutRead);
  LogConsumerAIDebug('PROCESS_STARTED | PID=' + IntToStr(FConsumerAIProcessInfo.dwProcessId));
  SetConsumerAIStatus(TrText('Connected'));
end;

procedure TfrmMain.StopConsumerAIProcess;
begin
  if not FConsumerAIProcessRunning and (not Assigned(FConsumerAIReaderThread)) then
    Exit;

  LogConsumerAIDebug('STOP | Requested');

  if FConsumerAIProcessRunning then
    ConsumerAIWriteLine('exit');

  if FConsumerAIProcessInfo.hProcess <> 0 then
  begin
    if WaitForSingleObject(FConsumerAIProcessInfo.hProcess, 1500) = WAIT_TIMEOUT then
      TerminateProcess(FConsumerAIProcessInfo.hProcess, 0);
  end;

  if FConsumerAIStdInWrite <> 0 then
  begin
    CloseHandle(FConsumerAIStdInWrite);
    FConsumerAIStdInWrite := 0;
  end;

  if FConsumerAIStdOutRead <> 0 then
  begin
    CloseHandle(FConsumerAIStdOutRead);
    FConsumerAIStdOutRead := 0;
  end;

  if Assigned(FConsumerAIReaderThread) then
  begin
    FConsumerAIReaderThread.Terminate;
    FConsumerAIReaderThread.WaitFor;
    FreeAndNil(FConsumerAIReaderThread);
  end;

  if FConsumerAIProcessInfo.hThread <> 0 then
  begin
    CloseHandle(FConsumerAIProcessInfo.hThread);
    FConsumerAIProcessInfo.hThread := 0;
  end;
  if FConsumerAIProcessInfo.hProcess <> 0 then
  begin
    CloseHandle(FConsumerAIProcessInfo.hProcess);
    FConsumerAIProcessInfo.hProcess := 0;
  end;

  FConsumerAIProcessRunning := False;
  FConsumerAIActiveFileName := '';
  FConsumerAILastPrompt := '';
  ClearConsumerAIOptionButtons;
  if Assigned(FConsumerAIInputEdit) then
    FConsumerAIInputEdit.Enabled := False;
  if Assigned(FConsumerAISendButton) then
    FConsumerAISendButton.Enabled := False;
  UpdateConsumerAIInputPanelHeight;
  SetConsumerAIStatus(TrText('Disconnected'));
  LogConsumerAIDebug('STOP | Completed');
end;

procedure TfrmMain.ToolbarOverflowItemClick(Sender: TObject);
var
  Btn: TsSpeedButton;
begin
  if not (Sender is TMenuItem) then Exit;
  Btn := TsSpeedButton(Pointer(TMenuItem(Sender).Tag));
  if Assigned(Btn) and Assigned(Btn.OnClick) and Btn.Enabled then
    Btn.OnClick(Btn);
end;

procedure TfrmMain.ToolbarOverflowPopup(Sender: TObject);
var
  I: Integer;
  Item: TMenuItem;
  Btn: TsSpeedButton;
begin
  if not Assigned(FToolbarOverflowPopup) then Exit;
  for I := 0 to FToolbarOverflowPopup.Items.Count - 1 do
  begin
    Item := FToolbarOverflowPopup.Items[I];
    Btn := TsSpeedButton(Pointer(Item.Tag));
    if Assigned(Btn) then
    begin
      Item.Enabled := Btn.Enabled;
      Item.Caption := StringReplace(Btn.Caption, #13#10, '  ', [rfReplaceAll]);
    end;
  end;
end;

procedure TfrmMain.ToolbarOverflowButtonClick(Sender: TObject);
var
  P: TPoint;
begin
  if not Assigned(FToolbarOverflowPopup) or not Assigned(FToolbarOverflowButton) then Exit;
  P := FToolbarOverflowButton.ClientToScreen(Point(0, FToolbarOverflowButton.Height));
  FToolbarOverflowPopup.Popup(P.X, P.Y);
end;

procedure TfrmMain.BuildToolbarOverflowMenu;
  procedure AddOverflowItem(const AButton: TsSpeedButton);
  var
    Item: TMenuItem;
  begin
    if not Assigned(AButton) then Exit;
    Item := TMenuItem.Create(FToolbarOverflowPopup);
    Item.Caption := StringReplace(AButton.Caption, #13#10, '  ', [rfReplaceAll]);
    Item.Tag := Integer(AButton);
    Item.OnClick := ToolbarOverflowItemClick;
    FToolbarOverflowPopup.Items.Add(Item);
    AButton.Visible := False;
  end;
begin
  if not Assigned(pnlButtons) then Exit;

  if not Assigned(FToolbarOverflowPopup) then
  begin
    FToolbarOverflowPopup := TPopupMenu.Create(Self);
    FToolbarOverflowPopup.OnPopup := ToolbarOverflowPopup;
    if Assigned(FMenuBitmapImages) and (FMenuBitmapImages.Count > 0) then
      FToolbarOverflowPopup.Images := FMenuBitmapImages
    else
      FToolbarOverflowPopup.Images := CharImageList16;
  end;

  FToolbarOverflowPopup.Items.Clear;

  { Keep the primary actions visible and move secondary actions under "...". }
  AddOverflowItem(btnClear);
  AddOverflowItem(btnMergeMultipleLines);
  AddOverflowItem(btnSplitFiles);
  AddOverflowItem(btnEditFile);
  AddOverflowItem(btnDeleteLines);

  if not Assigned(FToolbarOverflowButton) then
  begin
    FToolbarOverflowButton := TsSpeedButton.Create(Self);
    FToolbarOverflowButton.Parent := pnlButtons;
    FToolbarOverflowButton.Align := alLeft;
    FToolbarOverflowButton.Width := 90;
    FToolbarOverflowButton.Flat := True;
    FToolbarOverflowButton.Spacing := 8;
    FToolbarOverflowButton.AllowAllUp := True;
    FToolbarOverflowButton.GroupIndex := 1;
    FToolbarOverflowButton.SkinData.SkinSection := 'TOOLBUTTON';
    FToolbarOverflowButton.Images := ImageList32;
    FToolbarOverflowButton.ImageIndex := 24;
    FToolbarOverflowButton.Reflected := True;
    FToolbarOverflowButton.OnClick := ToolbarOverflowButtonClick;
  end;

  FToolbarOverflowButton.Caption := '...' + #13#10 + TrText('More');
  FToolbarOverflowButton.Visible := (FToolbarOverflowPopup.Items.Count > 0);
end;

procedure TfrmMain.BuildListViewPopupMenu;
  function AddItem(const ACaption: string; AOnClick: TNotifyEvent;
    const AShortcut: TShortCut = 0; const AImageIndex: Integer = -1): TMenuItem;
  begin
    Result := TMenuItem.Create(popupmenuListView);
    Result.Caption := ACaption;
    if Assigned(AOnClick) then
      Result.OnClick := AOnClick;
    if AShortcut <> 0 then
      Result.ShortCut := AShortcut;
    if AImageIndex >= 0 then
      Result.ImageIndex := AImageIndex;
    popupmenuListView.Items.Add(Result);
  end;
  procedure AddSep;
  begin
    AddItem('-', nil);
  end;
begin
  if not Assigned(popupmenuListView) then Exit;
  if Assigned(FMenuBitmapImages) and (FMenuBitmapImages.Count > 0) then
    popupmenuListView.Images := FMenuBitmapImages
  else
    popupmenuListView.Images := CharImageList16;

  popupmenuListView.Items.Clear;
  FPopupLVSelectItem   := nil;
  FPopupLVWordWrapItem := nil;
  FPopupLVReadOnlyItem := nil;
  FPopupLVSegmentedHeavyOpsItem := nil;
  popupmenuListView.OnPopup := popupmenuListViewPopup;

  { --- Edit group --- }
  AddItem(TrText('&Find...'),            miFindClick,        ShortCut(Ord('F'), [ssCtrl]), MenuIconIndex('search.bmp', 12));
  AddItem(TrText('Find and &Replace...'),miFindReplaceClick, ShortCut(Ord('H'), [ssCtrl]), MenuIconIndex('search and replace.bmp', 12));
  AddItem(TrText('&Go to line...'),      miGotoLineClick,    ShortCut(Ord('G'), [ssCtrl]),  MenuIconIndex('goto line.bmp', 7));
  AddItem(TrText('&Go to byte offset...'), miGotoByteOffsetClick, ShortCut(Ord('G'), [ssCtrl, ssShift]), MenuIconIndex('goto line.bmp', 7));
  AddSep;
  AddItem(TrText('Copy selection'),      miCopyClick,        ShortCut(Ord('C'), [ssCtrl]),  MenuIconIndex('copy.bmp', 9));
  AddSep;
  AddItem(TrText('Undo'),                miUndoClick,        ShortCut(Ord('Z'), [ssCtrl]), MenuIconIndex('undo.bmp', 24));
  AddItem(TrText('Redo'),                miRedoClick,        ShortCut(Ord('Y'), [ssCtrl]), MenuIconIndex('redo.bmp', 24));

  { --- View (word wrap + select + zoom + bookmarks) --- }
  AddSep;
  FPopupLVWordWrapItem :=
    AddItem(TrText('&Word wrap'),         miToggleWordWrapClick, ShortCut(Ord('W'), [ssCtrl]), MenuIconIndex('word wrap.bmp', 11));
  FPopupLVSelectItem :=
    AddItem(TrText('S&elect (checkbox list)'), miSelectClick,
      ShortCut(Ord('S'), [ssCtrl, ssShift]), MenuIconIndex('select all.bmp', 10));
  AddItem(TrText('Zoom &in (list)'), miZoomListViewInClick, ShortCut(VK_ADD, [ssCtrl]),
    MenuIconIndex(FF_MENU_BMP_ZOOM_LIST, MenuIconIndex('forward.bmp', 2)));
  AddItem(TrText('Zoom o&ut (list)'), miZoomListViewOutClick, ShortCut(VK_SUBTRACT, [ssCtrl]),
    MenuIconIndex(FF_MENU_BMP_ZOOM_LIST, MenuIconIndex('forward.bmp', 2)));
  AddSep;
  AddItem(TrText('&Toggle bookmark'), miToggleBookmarkClick, ShortCut(Ord('B'), [ssCtrl]), MenuIconIndex('pushpin.bmp', 31));
  AddItem(TrText('&Next bookmark'), miNextBookmarkClick, ShortCut(VK_F2, []), MenuIconIndex('pushpin.bmp', 31));
  AddItem(TrText('Pr&evious bookmark'), miPrevBookmarkClick, ShortCut(VK_F2, [ssShift]), MenuIconIndex('pushpin.bmp', 31));
  AddItem(TrText('Clear a&ll bookmarks'), miClearBookmarksClick, ShortCut(Ord('B'), [ssCtrl, ssShift]), MenuIconIndex('pushpin.bmp', 31));

  { --- Options / session --- }
  AddSep;
  FPopupLVReadOnlyItem :=
    AddItem(TrText('Read-only &session'), miToggleReadOnlyClick, ShortCut(Ord('R'), [ssCtrl, ssAlt]), MenuIconIndex('box closed.bmp', 32));
  FPopupLVSegmentedHeavyOpsItem :=
    AddItem(TrText('Line-segmented &mode (heavy ops)'), miToggleSegmentedHeavyOpsClick, 0, MenuIconIndex('grid split cells.bmp', 19));
  AddItem(TrText('Tail / &Follow mode'),   miToggleTailClick,   ShortCut(Ord('T'), [ssCtrl]),   MenuIconIndex('forward.bmp', 2));
  AddItem(TrText('Fil&ter / Grep'),       miFilterClick,         ShortCut(Ord('L'), [ssCtrl]),  MenuIconIndex('find.bmp', 4));
  AddItem(TrText('E&xport filtered results'), miExportFilteredClick, ShortCut(Ord('L'), [ssCtrl, ssShift]), MenuIconIndex('save as.bmp', 11));
  AddSep;
  AddItem(TrText('Compare / merge + &history...'), miCompareMergeHistoryClick,
    ShortCut(Ord('H'), [ssCtrl, ssShift]), MenuIconIndex('grid merge cells.bmp', 22));
  AddItem(TrText('&Insert line'),   miInsertLineClick,  ShortCut(Ord('I'), [ssCtrl, ssShift]), MenuIconIndex('plus.bmp', 17));
  AddItem(TrText('D&uplicate line'), miDuplicateLineClick, ShortCut(Ord('U'), [ssCtrl, ssShift]), MenuIconIndex('plus.bmp', 17));
  AddItem(TrText('&Edit line'),     miEditLineClick,    ShortCut(Ord('E'), [ssCtrl, ssShift]), MenuIconIndex('edit.bmp', 17));
  AddItem(TrText('&Delete line'),   miDeleteLinesClick, ShortCut(Ord('D'), [ssCtrl, ssShift]), MenuIconIndex('delete.bmp', 16));
  AddSep;
  AddItem(TrText('Exp&ort'),        miExportClick,      ShortCut(Ord('O'), [ssCtrl, ssShift]), MenuIconIndex('save as.bmp', 11));
  AddItem(TrText('&Clear'),         miClearClick,       ShortCut(Ord('X'), [ssCtrl, ssShift]), MenuIconIndex('clear.bmp', 12));
end;

procedure TfrmMain.popupmenuListViewPopup(Sender: TObject);
begin
  { Sync "Select (checkbox list)" checked state with current mode. }
  if Assigned(FPopupLVSelectItem) then
    FPopupLVSelectItem.Checked := isChecked;
  { Sync "Word wrap" checked state. }
  if Assigned(FPopupLVWordWrapItem) then
    FPopupLVWordWrapItem.Checked := Assigned(chkWordWrap) and chkWordWrap.Checked;
  if Assigned(FPopupLVReadOnlyItem) then
    FPopupLVReadOnlyItem.Checked := FFileSessionReadOnly;
  if Assigned(FPopupLVSegmentedHeavyOpsItem) then
    FPopupLVSegmentedHeavyOpsItem.Checked := Assigned(chkSegmentedHeavyOps) and chkSegmentedHeavyOps.Checked;
end;

procedure TfrmMain.RefreshLanguageRuntimeCache;
begin
  FTrLineColFormat := TrText('Line: %d  Col: %d');
  FTrLineColZero := TrText('Line: 0  Col: 0');
  FTrLinesFormat := TrText('Lines: %d');
  FTrDetectedOnFile := TrText('Detected on file: ');
  FTrListViewUses := TrText('List view uses: ');
  FTrNoRereadDefault := TrText('Does not re-read file. DEFAULT = BOM/heuristics.');
  FTrNoRereadForced := TrText('Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.');
  FTrDefaultViewSuffix := TrText(' (DEFAULT view)');
end;

procedure TfrmMain.ApplyCurrentLanguage;
var
  EncIdx: Integer;
  E0, E1, E2, E3, E4: string;
  NeedRebuildEncodingItems: Boolean;
  FreezeRedraw: Boolean;
begin
  if FApplyingLanguage then Exit;

  FApplyingLanguage := True;
  { Only freeze redraws after the first language apply (runtime language
    change). During FormCreate the first call skips freeze to avoid grey-flash
    and the synchronous RedrawWindow stall at startup. }
  FreezeRedraw := FLanguageAppliedOnce and HandleAllocated;
  if FreezeRedraw then
    SendMessage(Handle, WM_SETREDRAW, 0, 0);
  try
    BuildMenuBitmapImageList;
    EnsureToolsPopupFastFileExtras;
    EnsureToolsPopupBookmarkExtras;
    UpdateToolsPopupFastFileExtrasCaptions;
    RefreshLanguageRuntimeCache;
    FLastStatusLine := -1;
    FLastStatusCount := -1;

    if Assigned(comboViewEncoding) then
    begin
      EncIdx := comboViewEncoding.ItemIndex;
      E0 := TrText('View: DEFAULT (detected)');
      E1 := TrText('View: UTF-8');
      E2 := TrText('View: ANSI (raw / system)');
      E3 := TrText('View: UTF-16 LE');
      E4 := TrText('View: UTF-16 BE');

      NeedRebuildEncodingItems := (comboViewEncoding.Items.Count <> 5)
        or (comboViewEncoding.Items[0] <> E0)
        or (comboViewEncoding.Items[1] <> E1)
        or (comboViewEncoding.Items[2] <> E2)
        or (comboViewEncoding.Items[3] <> E3)
        or (comboViewEncoding.Items[4] <> E4);

      FUpdatingViewEncodingCombo := True;
      try
        if NeedRebuildEncodingItems then
        begin
          comboViewEncoding.Items.BeginUpdate;
          try
            comboViewEncoding.Items.Clear;
            comboViewEncoding.Items.Add(E0);
            comboViewEncoding.Items.Add(E1);
            comboViewEncoding.Items.Add(E2);
            comboViewEncoding.Items.Add(E3);
            comboViewEncoding.Items.Add(E4);
          finally
            comboViewEncoding.Items.EndUpdate;
          end;
        end;

        if EncIdx < 0 then EncIdx := 0;
        if EncIdx >= comboViewEncoding.Items.Count then
          EncIdx := comboViewEncoding.Items.Count - 1;
        comboViewEncoding.ItemIndex := EncIdx;
      finally
        FUpdatingViewEncodingCombo := False;
      end;
    end;

    SetupToolbarKeyboardHints;
    LocalizeTopToolbar;
    BuildToolbarOverflowMenu;
    BuildClassicMainMenu;
    { ListView popup: sempre reconstroi aqui. Construir dentro do OnPopup (lazy) causa
      fontes menores na primeira exibicao porque o AlphaSkins aplica metricas antes
      dos itens existirem. O custo (~18 TMenuItem) e negligivel. }
    BuildListViewPopupMenu;
    SyncLanguageComboWithCurrent;
    { No startup nao ha arquivo carregado; esses paineist sao atualizados em FormShow. }
    if FLanguageAppliedOnce then
    begin
      UpdateInfoPanels;
      UpdateListViewZoomStatusPanel;
    end;
  finally
    if FreezeRedraw then
    begin
      SendMessage(Handle, WM_SETREDRAW, 1, 0);
      { RDW_FRAME: invalida a area nao-cliente (menu bar, borda).
        RDW_ERASE: limpa o fundo antes de repintar para nao sobrepor texto antigo.
        RDW_UPDATENOW: forca pintura sincrona (sem esperar proxima mensagem WM_PAINT). }
      RedrawWindow(Handle, nil, 0,
        RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_UPDATENOW);
      { DrawMenuBar DEPOIS de reabilitar o redraw, para o Windows realmente redesenhar o menu bar. }
      DrawMenuBar(Handle);
    end;
    FLanguageAppliedOnce := True;
    FApplyingLanguage := False;
  end;
end;

procedure TfrmMain.InitializeLanguage;
var
  LangCode: string;
  WinLangID: Word;
  Primary: Word;
  Sub: Word;
begin
  LangCode := sStoreUtils.ReadIniString(APPLICATION_NAME, 'Language', IniName);
  if Trim(LangCode) = '' then
  begin
    WinLangID := GetUserDefaultLangID;
    { Delphi 7 compatible extraction (Windows LANGID layout):
      low 10 bits = primary language, high 6 bits = sublanguage. }
    Primary := (WinLangID and $03FF);
    Sub := (WinLangID shr 10);

    case Primary of
      LANG_PORTUGUESE:
        begin
          if Sub = SUBLANG_PORTUGUESE_BRAZILIAN then
            LangCode := 'pt-br'
          else
            LangCode := 'pt-PT';
        end;
      LANG_SPANISH:   LangCode := 'es';
      LANG_FRENCH:    LangCode := 'fr';
      LANG_GERMAN:    LangCode := 'de';
      LANG_ITALIAN:   LangCode := 'it';
      LANG_POLISH:    LangCode := 'pl';
      LANG_ROMANIAN:  LangCode := 'ro';
      LANG_HUNGARIAN: LangCode := 'hu';
      LANG_CZECH:     LangCode := 'cs';
    else
      LangCode := 'en';
    end;
  end;
  SetCurrentLanguage(AppLanguageFromCode(LangCode));
end;

procedure TfrmMain.SyncLanguageComboWithCurrent;
begin
  if not Assigned(comboLanguage) then Exit;

  FUpdatingLanguageCombo := True;
  try
    comboLanguage.Items.BeginUpdate;
    try
      comboLanguage.Items.Clear;
      comboLanguage.Items.Add(Tr('language.option.english', 'English'));
      comboLanguage.Items.Add(Tr('language.option.portuguese_brazil', 'Portuguese (Brazil)'));
      comboLanguage.Items.Add(Tr('language.option.spanish', 'Spanish'));
      comboLanguage.Items.Add(Tr('language.option.french', 'French'));
      comboLanguage.Items.Add(Tr('language.option.german', 'German'));
      comboLanguage.Items.Add(Tr('language.option.italian', 'Italian'));
      comboLanguage.Items.Add(Tr('language.option.polish', 'Polish'));
      comboLanguage.Items.Add(Tr('language.option.portuguese_portugal', 'Portuguese (Portugal)'));
      comboLanguage.Items.Add(Tr('language.option.romanian', 'Romanian'));
      comboLanguage.Items.Add(Tr('language.option.hungarian', 'Hungarian'));
      comboLanguage.Items.Add(Tr('language.option.czech', 'Czech'));
    finally
      comboLanguage.Items.EndUpdate;
    end;

    comboLanguage.Hint := Tr('language.combo.hint', 'Application language');

    case GetCurrentLanguage of
      alPortuguese:   comboLanguage.ItemIndex := 1;
      alSpanish:      comboLanguage.ItemIndex := 2;
      alFrench:       comboLanguage.ItemIndex := 3;
      alGerman:       comboLanguage.ItemIndex := 4;
      alItalian:      comboLanguage.ItemIndex := 5;
      alPolish:       comboLanguage.ItemIndex := 6;
      alPortuguesePT: comboLanguage.ItemIndex := 7;
      alRomanian:     comboLanguage.ItemIndex := 8;
      alHungarian:    comboLanguage.ItemIndex := 9;
      alCzech:        comboLanguage.ItemIndex := 10;
    else
      comboLanguage.ItemIndex := 0;
    end;
  finally
    FUpdatingLanguageCombo := False;
  end;
end;

procedure TfrmMain.comboLanguageChange(Sender: TObject);
var
  NewLang: TAppLanguage;
begin
  if FUpdatingLanguageCombo then Exit;
  if not Assigned(comboLanguage) then Exit;

  case comboLanguage.ItemIndex of
    1:  NewLang := alPortuguese;
    2:  NewLang := alSpanish;
    3:  NewLang := alFrench;
    4:  NewLang := alGerman;
    5:  NewLang := alItalian;
    6:  NewLang := alPolish;
    7:  NewLang := alPortuguesePT;
    8:  NewLang := alRomanian;
    9:  NewLang := alHungarian;
    10: NewLang := alCzech;
  else
    NewLang := alEnglish;
  end;

  if NewLang = GetCurrentLanguage then Exit;

  SetCurrentLanguage(NewLang);

  sStoreUtils.WriteIniStr(APPLICATION_NAME, 'Language', AppLanguageCode(GetCurrentLanguage), IniName);
  ApplyCurrentLanguage;
  UpdateStatusBar(Tr('status.system_ready', 'System Ready'), iaRight);
end;

procedure TfrmMain.FormShow(Sender: TObject);
(* var
  value: WideString; *)
begin
  //AppLoading := True;
  // Open the first framebar item (TBarPanel_AppStyle)
  //sFrameBar1.OpenItem(0, False {Without animation});
  // Example of access to the frame (click on spdBtn_CurrSkin)
  //TBarPanel_AppStyle(sFrameBar1.Items[0].Frame).spdBtn_CurrSkin.OnClick(TBarPanel_AppStyle(sFrameBar1.Items[0].Frame).spdBtn_CurrSkin);
  // Searching of available skins
 (* AppLoading := False;
  value := 'enter';
  SendMessage(edit1.Handle, EM_SETCUEBANNER, 1, LPARAM (PWideChar(value)));  *)
  //memoInfo.Color := $00D8FEFC;
  UpdateStatusBar(Tr('status.system_ready', 'System Ready'), iaRight);
  FormResize(Self);
  LayoutLanguageCombo;
  LayoutViewEncodingCombo;
  LayoutZoomCombo;
  if Assigned(chkWordWrap) then
  begin
    FFastVisualWordWrap := chkWordWrap.Checked;
    FastWordWrapAtivo := False;
    UpdateListViewWordWrapUi;
  end;
  if Assigned(chkSegmentedHeavyOps) then
  begin
    chkSegmentedHeavyOps.Checked :=
      sStoreUtils.ReadIniInteger(APPLICATION_NAME, 'SegmentHeavyOps', 0, IniName) = 1;
    { FormCreate ja chamou ApplyCurrentLanguage antes do INI aplicar ao checkbox; re-sincroniza menus. }
    chkSegmentedHeavyOpsClick(chkSegmentedHeavyOps);
  end;
  UpdateListViewZoomStatusPanel;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  t: integer;
  s: string;
  folderXMLFile: string;
  folderFile: string;
  iPage: Integer;
begin
  Self.Caption := Format('%s %s', [APPLICATION_NAME, UnUtils.GetDisplayVersion(False)]);
  KeyPreview := True;
  sStatusBar1.Panels[5].Text := UnUtils.LoadConfig();
  //About.CloseStyle := svcaCollapse;
  IniName := ExtractFilePath(Application.ExeName) + ASKIN_INI;
  InitializeLanguage;
  if not acDirExists(DataModule1.sSkinManager1.SkinDirectory) then
    DataModule1.sSkinManager1.SkinDirectory := ExtractFilePath(Application.ExeName) + 'Skins';
{$IFNDEF DISABLEPREVIEWMODE}
  if (ParamCount > 0) and (ParamStr(1) = s_PreviewKey) then begin
//    ActionAnimation.Execute; // If called from the SkinEditor for a skin preview (Skin Edit mode)
    DataModule1.sSkinManager1.Effects.DiscoloredGlyphs := True;
  end;
{$ENDIF}
  // Load skin data if exists in Ini
  s := sStoreUtils.ReadIniString(APPLICATION_NAME, 'SkinDirectory', IniName); // Skin directory is stored?
  if s <> '' then
    DataModule1.sSkinManager1.SkinDirectory := s;

  s := sStoreUtils.ReadIniString(APPLICATION_NAME, 'SkinName', IniName); // Skin name is stored?
  if s <> '' then
    DataModule1.sSkinManager1.SkinName := s;

  BuildMenuBitmapImageList;

  t := sStoreUtils.ReadIniInteger(APPLICATION_NAME, 'SkinActive', 1, IniName); // Skin is active? Default value is 1 (True)
//  Application.HintPause := 800; // Define own hint pause
//  Application.HintShortPause := 0;
  DataModule1.sSkinManager1.Active := (t = 1);
  if not DataModule1.sSkinManager1.Active then
    ActionSkinned.Execute;

  //HideTabsInPageCtrl(pgMain);
  pgMain.Visible := False;
  if sTitleBar1.Items.Count > 7 then
  begin
    sTitleBar1.Items[6].Caption := APPLICATION_NAME;
    sTitleBar1.Items[7].Caption := UnUtils.GetDisplayVersion(False);
  end;
  WindowState := wsMaximized;
  ProgressImagePanelFile.DoubleBuffered := True;
  ProgressImages.GetBitmap(0, ProgressImageFile.Picture.Bitmap);
  FShowHoriz := False; // show the horiz scrollbar
  FShowVert := False; // hide vert scrollbar
  ActionClear.Execute;
  DragAcceptFiles(Handle, True); // Windows XP
  SetDragAndDropOnSystemsWithUAC(Handle, True); // Windows 7
  (*if Assigned(textFile) then FreeAndNil(textFile);
  try
    textFile := TGpHugeFileStream.Create(ExtractFilePath(Application.ExeName) + TEMPFILE, accWrite);
  finally
    FreeAndNil(textFile);
  end; *)
  ListEdit := TEdit.Create(self) ;
  ListEdit.Visible := false;
  ListEdit.Ctl3D := false;
  ListEdit.BorderStyle := tborderstyle(bsNone);
  ListEdit.Parent := sListBox1;
  ListEdit.Width := sListBox1.ClientWidth;
  ListEdit.OnKeyPress := ListEditKeyPress;

  CreatedBeforeDate.Date := Date;
  CreatedBeforeDate.Time := 0;
  CreatedAfterDate.Date := Date;
  CreatedAfterDate.Time := 0;
  CreatedBeforeTime.Time := Time;
  CreatedBeforeTime.Date := 0;
  CreatedAfterTime.Time := Time;
  CreatedAfterTime.Date := 0;
  ModifiedBeforeDate.Date := Date;
  ModifiedBeforeDate.Time := 0;
  ModifiedAfterDate.Date := Date;
  ModifiedAfterDate.Time := 0;
  ModifiedBeforeTime.Time := Time;
  ModifiedBeforeTime.Date := 0;
  ModifiedAfterTime.Time := Time;
  ModifiedAfterTime.Date := 0;
  AccessedBeforeDate.Date := Date;
  AccessedBeforeDate.Time := 0;
  AccessedAfterDate.Date := Date;
  AccessedAfterDate.Time := 0;
  AccessedBeforeTime.Time := Time;
  AccessedBeforeTime.Date := 0;
  AccessedAfterTime.Time := Time;
  AccessedAfterTime.Date := 0;
  {$IFDEF COMPILER4_UP}
  ProgressImagePanel.DoubleBuffered := True;
  {$ENDIF}
  ProgressImages.GetBitmap(0, ProgressImage.Picture.Bitmap);
  for iPage := 0 to pgMain.PageCount - 1 do
      pgMain.Pages[iPage].TabVisible := False;

  folderXMLFile := ExtractFilePath(Application.ExeName) + XMLFOLDERS;
  if FileExists(folderXMLFile) then
  begin
    clFolders.LoadFromFile(folderXMLFile);
    clFolders.IndexFieldNames := 'Folder';
  end;

  folderFile := ExtractFilePath(Application.ExeName) + XMLFILES;
  if FileExists(folderFile) then
  begin
    clFilesExclude.LoadFromFile(folderFile);
    clFilesExclude.IndexFieldNames := 'File';
  end;

  mru_location := TMruHelper.Create(Location, ExtractFilePath(Application.ExeName) + 'mru_location.ini', 25);
  mru_location.DebounceInterval := 150;
  mru_location.MaxItems := 25;

  mru_content := TMruHelper.Create(Phrase, ExtractFilePath(Application.ExeName) + 'mru_content.ini', 25);
  mru_content.DebounceInterval := 150;
  mru_content.MaxItems := 25;

  if Assigned(ListView1) then
  begin
    ListView1.OwnerData := True;
    ListView1.ViewStyle := vsReport;
    ListView1.GridLines := True;
    ListView1.ReadOnly := True;
    ListView1.RowSelect := True;
    ListView1.MultiSelect := True; // habilita selecao multipla (Ctrl+clique)
    ListView1.HideSelection := False; // keep selection visible even without focus
    
    // ATIVA DOUBLE BUFFERING
    ListView1.DoubleBuffered := True;
    
    ListView1.Font.Name := 'Courier New';
    ListView1.Font.Size := 10;
    
    // HOOK
    FOldListViewWndProc := ListView1.WindowProc;
    ListView1.WindowProc := HookedListViewWndProc;

    // Wire custom draw for search highlighting and bookmarks
    ListView1.OnAdvancedCustomDrawSubItem := ListView1AdvancedCustomDrawSubItem;
    ListView1.OnAdvancedCustomDrawItem := ListView1AdvancedCustomDrawItem;

    FWordWrapRowImages := nil;
    FFastVisualWordWrap := False;
    FDeferredListViewRecreateForRowHeight := False;
    FChecklistRefreshPending := False;
    if Assigned(comboViewEncoding) then
    begin
      comboViewEncoding.ItemIndex := 0;
      comboViewEncoding.Enabled := False;
    end;
    if Assigned(comboZoom) then
    begin
      comboZoom.Items.Clear;
      comboZoom.Items.Add('50%');
      comboZoom.Items.Add('75%');
      comboZoom.Items.Add('100%');
      comboZoom.Items.Add('125%');
      comboZoom.Items.Add('150%');
      comboZoom.Items.Add('200%');
      comboZoom.ItemIndex := 2;
      comboZoom.Enabled := True;
    end;
  end;

  { Combo "View encoding" na status bar: hook do pai para CBN_CLOSEUP (skins / reescolher mesmo item). }
  FHookedStatusBarForViewEncoding := False;
  if Assigned(sStatusBar1) and Assigned(comboViewEncoding) then
  begin
    FOldStatusBarWndProcForCombo := sStatusBar1.WindowProc;
    sStatusBar1.WindowProc := HookedStatusBarWndProcForCombo;
    FHookedStatusBarForViewEncoding := True;
  end;

  // === New features init ===
  FCacheCount := 0;
  FCacheOffset := -1;
  FUndoStack := TList.Create;
  FRedoStack := TList.Create;
  FDetectedEncoding := 'ANSI';
  FLastStatusLine := -1;
  FLastStatusCount := -1;
  FUpdatingZoomCombo := False;
  FChecklistAnchorLine := -1;
  FUpdatingChecklistChecks := False;
  FZoomWheelHistory := TStringList.Create;
  FLastZoomComboUpdateTick := 0;
  FTailActive := False;
  FFileSessionReadOnly := False;
  FMenuReadOnlyItem := nil;
  FPopupLVReadOnlyItem := nil;
  FFilterActive := False;
  FFilterBits := nil;
  FFilterBitsSize := 0;
  FFilterThread := nil;
  FFilterFindSkips := 0;
  FBookmarks := TList.Create;
  FFindText := '';
  FFindThread := nil;
  FFindSearchId := 0;
  FLastFoundLine := -1;
  FLastFoundFilePos := 0;
  FLastFoundCol := 0;
  FLastFoundMatchLen := 0;

  // === Recent Files init ===
  FRecentFilesIni := ExtractFilePath(Application.ExeName) + 'mru_files.ini';
  FRecentFiles := TStringList.Create;
  FpmRecentFiles := TPopupMenu.Create(Self);
  LoadRecentFiles;

  CalculateFontMetrics;
  ApplyCurrentLanguage;
  LayoutLanguageCombo;
  LayoutViewEncodingCombo;
  LayoutZoomCombo;
end;

procedure TfrmMain.SetupToolbarKeyboardHints;
  { Caption em duas linhas (texto + atalho); hint acrescenta o atalho se ja houver descricao.
    TsSpeedButton tem Caption; TControl base nao. }
  procedure SetBtn(ABtn: TsSpeedButton; const ABaseCaption, AShortcut: string);
  var
    Tail: string;
  begin
    if not Assigned(ABtn) then Exit;
    Tail := TrText('Shortcut: ') + AShortcut;
    ABtn.Caption := TrText(ABaseCaption) + #13#10 + AShortcut;
    ABtn.ShowHint := True;
    ABtn.Hint := Tail;
  end;
begin
  SetBtn(btnShowTabReadFile, 'Read', 'Ctrl+1');
  SetBtn(btnRead, 'Read', 'F5');
  SetBtn(btnSplitFiles, 'Split Files', 'Ctrl+Shift+K');
  SetBtn(btnMergeMultipleLines, 'Merge lines', 'Ctrl+Shift+M');
  SetBtn(btnCheckBoxes, 'Select', 'Ctrl+Shift+S');
  SetBtn(btnClear, 'Clear', 'Ctrl+Shift+X');
  SetBtn(btnEditFile, 'Edit', 'Ctrl+Shift+E');
  { Ctrl+Shift+D abre o line editor em Delete Line; o botao continua exclusao em lote (ActionDelete). }
  SetBtn(btnDeleteLines, 'Delete lines (batch)', '');
  SetBtn(btnExport, 'Export', 'Ctrl+Shift+O');
  SetBtn(btnReturn, 'Close', 'Ctrl+Shift+W');
  SetBtn(btnConsumerAI, 'AI', 'Ctrl+Shift+A');
  if Assigned(btnHelp) then
    SetBtn(btnHelp, 'Help', 'F1');
end;

procedure TfrmMain.miOpenFileClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  with TOpenDialog.Create(nil) do
  try
    Filter := 'All files (*.*)|*.*';
    Options := [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing];
    if Execute then
      edtFileName.Text := FileName;
  finally
    Free;
  end;
end;

procedure TfrmMain.EnsureReadTabVisible;
begin
  if (not Assigned(pgMain)) or (not Assigned(tabReadFile)) then Exit;
  { Se a aba Read foi fechada (pgMainCloseBtnClick/HideTabs), reabrir e tornar visivel.
    So evita recarregar quando ja esta efetivamente ativa e visivel. }
  if (not pgMain.Visible)
    or (pgMain.ActivePage <> tabReadFile)
    or (not tabReadFile.TabVisible) then
    DoShowPanelReadFile;
end;

procedure TfrmMain.miRecentFilesClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  ShowRecentFilesMenu;
end;

procedure TfrmMain.miExitClick(Sender: TObject);
begin
  if Assigned(ActionCloseForm) then
    ActionCloseForm.Execute
  else
    Close;
end;

procedure TfrmMain.miFindClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  DoFindDialog;
end;

procedure TfrmMain.miFindReplaceClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  DoFindReplace;
end;

procedure TfrmMain.miGotoLineClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  DoGotoLine;
end;

procedure TfrmMain.miGotoByteOffsetClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  DoGotoByteOffset;
end;

procedure TfrmMain.miUndoClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  DoUndo;
end;

procedure TfrmMain.miRedoClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  DoRedo;
end;

procedure TfrmMain.miCopyClick(Sender: TObject);
var
  Line1Based: Integer;
begin
  EnsureReadTabVisible;
  if Assigned(FCheckListBox) and FCheckListBox.Visible and
     (Screen.ActiveControl = FCheckListBox) then
  begin
    if FHasSelection then
    begin
      CopyChecklistVerticalSelectionToClipboard;
      Exit;
    end;
    if existsCheckedRows(FCheckedLines) then
      CopyCheckedChecklistLinesToClipboard
    else if (FCheckListBox.ItemIndex >= 0) and
            (FCheckListBox.ItemIndex < FCheckListBox.Items.Count) then
    begin
      Line1Based := Integer(FCheckListBox.Items.Objects[FCheckListBox.ItemIndex]);
      if Line1Based > 0 then
        CopyFileLineToClipboard(Line1Based - 1);
    end;
    Exit;
  end;
  if Assigned(ListView1) and ((Screen.ActiveControl = ListView1) or ListView1.Focused) then
  begin
    if FHasSelection then
      CopyVerticalSelectionToClipboard
    else if ListView1.SelCount > 0 then
      CopyMultiSelectionToClipboard
    else if (ListView1.ItemIndex >= 0) and (not ListviewIsEmpty) and Assigned(FSourceFileStream) then
      CopyListViewFocusedLineToClipboard;
  end;
end;

procedure TfrmMain.miShowReadTabClick(Sender: TObject);
begin
  EnsureReadTabVisible;
end;

procedure TfrmMain.miReadLoadClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnRead) and btnRead.Enabled then
    btnReadClick(btnRead);
end;

procedure TfrmMain.miToggleWordWrapClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if not Assigned(chkWordWrap) then Exit;
  chkWordWrap.Checked := not chkWordWrap.Checked;
  chkWordWrapClick(chkWordWrap);
end;

procedure TfrmMain.miToggleTailClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  ToggleTailMode;
end;

procedure TfrmMain.miFilterClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  DoFilterDialog;
end;

procedure TfrmMain.miExportFilteredClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  ExportFilteredResults;
end;

procedure TfrmMain.miToggleBookmarkClick(Sender: TObject);
var
  RL: Int64;
  SavedCheckIdx: Integer;
  Line1Based: Integer;
begin
  EnsureReadTabVisible;
  if isChecked and Assigned(FCheckListBox) and (FCheckListBox.ItemIndex >= 0) then
  begin
    SavedCheckIdx := FCheckListBox.ItemIndex;
    Line1Based := Integer(FCheckListBox.Items.Objects[SavedCheckIdx]);
    if Line1Based <= 0 then Exit;
    ToggleBookmark(Line1Based - 1);
    showChecked;
    if (SavedCheckIdx >= 0) and (SavedCheckIdx < FCheckListBox.Items.Count) then
      FCheckListBox.ItemIndex := SavedCheckIdx;
    Exit;
  end;
  if ListView1.ItemIndex < 0 then Exit;
  if FFilterActive then
  begin
    RL := FilteredIndexToReal(ListView1.ItemIndex);
    if RL < 0 then Exit;
    ToggleBookmark(Integer(RL));
  end
  else
    ToggleBookmark(Integer(Offset + ListView1.ItemIndex));
end;

procedure TfrmMain.miNextBookmarkClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  GotoNextBookmark;
end;

procedure TfrmMain.miPrevBookmarkClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  GotoPrevBookmark;
end;

procedure TfrmMain.miClearBookmarksClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  ClearAllBookmarks;
end;

procedure TfrmMain.miSelectClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnCheckBoxes) and btnCheckBoxes.Enabled then
    btnCheckBoxesClick(btnCheckBoxes);
end;

procedure TfrmMain.miZoomListViewInClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  ApplyListViewWheelZoom(-120);
end;

procedure TfrmMain.miZoomListViewOutClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  ApplyListViewWheelZoom(120);
end;

procedure TfrmMain.miSplitFilesClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnSplitFiles) and btnSplitFiles.Enabled then
    btnSplitFilesClick(btnSplitFiles);
end;

procedure TfrmMain.miMergeLinesClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnMergeMultipleLines) and btnMergeMultipleLines.Enabled then
    btnMergeMultipleLinesClick(btnMergeMultipleLines);
end;

procedure TMergeFilesDialogForm.SetSourceEdit(const AEdit: TsFilenameEdit);
begin
  FSourceEdit := AEdit;
  if Assigned(FSourceEdit) then
    FSourceEditDefaultColor := FSourceEdit.Color;
end;

procedure TMergeFilesDialogForm.EnableFileDrop(const AEnabled: Boolean);
begin
  HandleNeeded;
  DragAcceptFiles(Handle, AEnabled);
end;

procedure TMergeFilesDialogForm.HighlightDroppedSource;
begin
  if not Assigned(FSourceEdit) then Exit;
  FSourceEdit.Color := $00E6FFE6;
  FSourceEdit.Invalidate;
end;

procedure TMergeFilesDialogForm.WMDropFiles(var Msg: TWMDropFiles);
var
  FileNameBuffer: array[0..MAX_PATH] of Char;
begin
  try
    if DragQueryFile(Msg.Drop, $FFFFFFFF, nil, 0) > 0 then
    begin
      FillChar(FileNameBuffer, SizeOf(FileNameBuffer), 0);
      DragQueryFile(Msg.Drop, 0, FileNameBuffer, MAX_PATH);
      if Assigned(FSourceEdit) then
      begin
        FSourceEdit.Text := Trim(FileNameBuffer);
        HighlightDroppedSource;
      end;
    end;
  finally
    DragFinish(Msg.Drop);
  end;
  Msg.Result := 0;
end;

function TfrmMain.CountLinesInFile(const AFileName: String): Int64;
const
  BUF_SIZE = 64 * 1024;
var
  F: TFileStream;
  Buffer: array[0..BUF_SIZE - 1] of AnsiChar;
  BytesRead: Integer;
  i: Integer;
begin
  Result := 0;
  if not FileExists(AFileName) then Exit;

  F := nil;
  try
    try
      F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
      while True do
      begin
        BytesRead := F.Read(Buffer[0], BUF_SIZE);
        if BytesRead <= 0 then Break;

        for i := 0 to BytesRead - 1 do
        begin
          if Buffer[i] = #10 then { LF - indica fim de linha }
            Inc(Result);
        end;
      end;
      
      { Se o arquivo não termina com quebra de linha, incrementa para contar a última linha }
      if (Result = 0) and (F.Size > 0) then
        Result := 1;
    except
      Result := -1; { Erro ao ler o arquivo }
    end;
  finally
    if Assigned(F) then
      F.Free;
  end;
end;

function TfrmMain.ShowMergeFilesDialog(out ASourceFile: String;
  out AMergeMode: TMergeFilesMode; out ALineNumber: Int64; 
  out AFromLine: Int64; out AToLine: Int64): Boolean;
var
  Frm: TMergeFilesDialogForm;
  LblDest, LblSource, LblLine, LblInfo: TLabel;
  LblFromLine, LblToLine: TLabel;
  EdtDest: TEdit;
  EdtSource: TsFilenameEdit;
  EdtFromLine, EdtToLine: TEdit;
  RgMode: TRadioGroup;
  ChkLineRange: TsCheckBox;
  SpnLine: TsSpinEdit;
  BtnOk, BtnCancel: TButton;
  SourceLineCount: Int64;
begin
  Result := False;
  ASourceFile := '';
  AMergeMode := mfmBeginning;
  ALineNumber := 1;
  AFromLine := 1;
  AToLine := 1;
  EdtSource := nil;

  Frm := TMergeFilesDialogForm.CreateNew(Self);
  try
    Frm.Caption := TrText('Merge files');
    Frm.Position := poScreenCenter;
    Frm.BorderStyle := bsDialog;
    Frm.ClientWidth := 640;
    Frm.ClientHeight := 500;

    LblDest := TLabel.Create(Frm);
    LblDest.Parent := Frm;
    LblDest.Left := 16;
    LblDest.Top := 16;
    LblDest.Caption := TrText('Destination file (current):');

    EdtDest := TEdit.Create(Frm);
    EdtDest.Parent := Frm;
    EdtDest.Left := 16;
    EdtDest.Top := 36;
    EdtDest.Width := Frm.ClientWidth - 32;
    EdtDest.ReadOnly := True;
    EdtDest.Text := Trim(edtFileName.Text);

    LblSource := TLabel.Create(Frm);
    LblSource.Parent := Frm;
    LblSource.Left := 16;
    LblSource.Top := 72;
    LblSource.Caption := TrText('Source file (type path or use picker):');

    EdtSource := TsFilenameEdit.Create(Frm);
    EdtSource.Parent := Frm;
    EdtSource.Left := 16;
    EdtSource.Top := 92;
    EdtSource.Width := Frm.ClientWidth - 32;
    EdtSource.DialogKind := dkOpen;
    EdtSource.Filter := TrText('All files (*.*)|*.*');
    Frm.SetSourceEdit(EdtSource);
    Frm.EnableFileDrop(True);

    { Checkbox para habilitar modo de copiar intervalo de linhas }
    ChkLineRange := TsCheckBox.Create(Frm);
    ChkLineRange.Parent := Frm;
    ChkLineRange.Left := 16;
    ChkLineRange.Top := 132;
    ChkLineRange.Width := Frm.ClientWidth - 32;
    ChkLineRange.Caption := TrText('Copiar apenas um intervalo específico de linhas do arquivo de origem');
    ChkLineRange.Checked := False;

    { Label e campo "Da linha" }
    LblFromLine := TLabel.Create(Frm);
    LblFromLine.Parent := Frm;
    LblFromLine.Left := 32;
    LblFromLine.Top := 156;
    LblFromLine.Caption := TrText('Da linha:');
    LblFromLine.Visible := False;

    EdtFromLine := TEdit.Create(Frm);
    EdtFromLine.Parent := Frm;
    EdtFromLine.Left := 32;
    EdtFromLine.Top := 172;
    EdtFromLine.Width := 100;
    EdtFromLine.Text := '1';
    EdtFromLine.Visible := False;

    { Label e campo "Até a linha" }
    LblToLine := TLabel.Create(Frm);
    LblToLine.Parent := Frm;
    LblToLine.Left := 160;
    LblToLine.Top := 156;
    LblToLine.Caption := TrText('Até a linha:');
    LblToLine.Visible := False;

    EdtToLine := TEdit.Create(Frm);
    EdtToLine.Parent := Frm;
    EdtToLine.Left := 160;
    EdtToLine.Top := 172;
    EdtToLine.Width := 100;
    EdtToLine.Text := '1';
    EdtToLine.Visible := False;

    RgMode := TRadioGroup.Create(Frm);
    RgMode.Parent := Frm;
    RgMode.Left := 16;
    RgMode.Top := 210;
    RgMode.Width := Frm.ClientWidth - 32;
    RgMode.Height := 120;
    RgMode.Caption := TrText('Merge mode');
    RgMode.Items.Add(TrText('Insert source at beginning (first line).'));
    RgMode.Items.Add(TrText('Insert source after destination line:'));
    RgMode.Items.Add(TrText('Insert source at end of destination file.'));
    RgMode.ItemIndex := 0;

    LblLine := TLabel.Create(Frm);
    LblLine.Parent := Frm;
    LblLine.Left := 32;
    LblLine.Top := 336;
    LblLine.Caption := TrText('Line number (valid range: 1..totalLines-1):');

    SpnLine := TsSpinEdit.Create(Frm);
    SpnLine.Parent := Frm;
    SpnLine.Left := 32;
    SpnLine.Top := 352;
    SpnLine.Width := 120;
    SpnLine.MinValue := 1;
    SpnLine.MaxValue := Max(1, totalLines - 1);
    SpnLine.Value := 1;

    LblInfo := TLabel.Create(Frm);
    LblInfo.Parent := Frm;
    LblInfo.Left := 16;
    LblInfo.Top := 390;
    LblInfo.Width := Frm.ClientWidth - 32;
    LblInfo.Caption := TrText('Tip: press ESC to cancel.') + ' ' +
      TrText('You can drag and drop the source file into this window.');

    BtnOk := TButton.Create(Frm);
    BtnOk.Parent := Frm;
    BtnOk.Left := Frm.ClientWidth - 190;
    BtnOk.Top := Frm.ClientHeight - 42;
    BtnOk.Width := 80;
    BtnOk.Caption := TrText('Confirm');
    BtnOk.ModalResult := mrOk;
    BtnOk.Default := True;

    BtnCancel := TButton.Create(Frm);
    BtnCancel.Parent := Frm;
    BtnCancel.Left := Frm.ClientWidth - 100;
    BtnCancel.Top := Frm.ClientHeight - 42;
    BtnCancel.Width := 80;
    BtnCancel.Caption := TrText('Cancel');
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;

    if Frm.ShowModal <> mrOk then
      Exit;

    { Validação e extração dos valores }
    ASourceFile := Trim(EdtSource.Text);
    
    { Se modo de intervalo de linhas está habilitado }
    if ChkLineRange.Checked then
    begin
      try
        { Valida se os campos não estão vazios }
        if Trim(EdtFromLine.Text) = '' then
        begin
          ShowMessage(TrText('Erro: "Da linha" não pode estar vazia.'));
          Exit;
        end;
        if Trim(EdtToLine.Text) = '' then
        begin
          ShowMessage(TrText('Erro: "Até a linha" não pode estar vazia.'));
          Exit;
        end;

        { Valida se são números válidos }
        if not TryStrToInt64(Trim(EdtFromLine.Text), AFromLine) then
        begin
          ShowMessage(TrText('Erro: "Da linha" deve ser um número válido.'));
          Exit;
        end;
        if not TryStrToInt64(Trim(EdtToLine.Text), AToLine) then
        begin
          ShowMessage(TrText('Erro: "Até a linha" deve ser um número válido.'));
          Exit;
        end;

        { Valida se os números são positivos e no mínimo 1 }
        if AFromLine < 1 then
        begin
          ShowMessage(TrText('Erro: "Da linha" deve ser pelo menos 1.'));
          Exit;
        end;
        if AToLine < 1 then
        begin
          ShowMessage(TrText('Erro: "Até a linha" deve ser pelo menos 1.'));
          Exit;
        end;

        { Valida se FromLine <= ToLine (não pode ser do maior para o menor) }
        if AFromLine > AToLine then
        begin
          ShowMessage(Format(TrText('Erro: "Da linha" (%d) não pode ser maior que "Até a linha" (%d).'),
            [AFromLine, AToLine]));
          Exit;
        end;

        { Valida se as linhas existem no arquivo de origem }
        if ASourceFile <> '' then
        begin
          if not FileExists(ASourceFile) then
          begin
            ShowMessage(Format(TrText('Erro: Arquivo de origem não encontrado: %s'), [ASourceFile]));
            Exit;
          end;

          { Conta o total de linhas no arquivo de origem }
          SourceLineCount := CountLinesInFile(ASourceFile);
          if SourceLineCount < 0 then
          begin
            ShowMessage(TrText('Erro: Não foi possível ler o arquivo de origem para validar o total de linhas.'));
            Exit;
          end;

          if AFromLine > SourceLineCount then
          begin
            ShowMessage(Format(TrText('Erro: "Da linha" (%d) excede o total de linhas no arquivo de origem (%d).'),
              [AFromLine, SourceLineCount]));
            Exit;
          end;

          if AToLine > SourceLineCount then
          begin
            ShowMessage(Format(TrText('Erro: "Até a linha" (%d) excede o total de linhas no arquivo de origem (%d).'),
              [AToLine, SourceLineCount]));
            Exit;
          end;
        end;

        AMergeMode := mfmLineRange;
        Result := True;
      except
        on E: Exception do
        begin
          ShowMessage(TrText('Erro ao validar o intervalo de linhas: ') + E.Message);
          Exit;
        end;
      end;
    end
    else
    begin
      case RgMode.ItemIndex of
        1: AMergeMode := mfmAfterLine;
        2: AMergeMode := mfmEnd;
      else
        AMergeMode := mfmBeginning;
      end;
      ALineNumber := SpnLine.Value;
      Result := True;
    end;
  finally
    if Assigned(EdtSource) then
      EdtSource.Color := Frm.FSourceEditDefaultColor;
    Frm.EnableFileDrop(False);
    Frm.Free;
  end;
end;

function TfrmMain.ShowSplitEqualPartsDialog(out ASourceFile: String;
  out APartCount: Integer): Boolean;
const
  SPLIT_PARTS_MIN = 2;
  SPLIT_PARTS_MAX = 1000;
var
  Frm: TMergeFilesDialogForm;
  LblSource, LblParts, LblHint: TLabel;
  EdtSource: TsFilenameEdit;
  SpnParts: TsSpinEdit;
  BtnOk, BtnCancel: TButton;
  CurFile: String;
begin
  Result := False;
  ASourceFile := '';
  APartCount := SPLIT_PARTS_MIN;
  EdtSource := nil;

  Frm := TMergeFilesDialogForm.CreateNew(Self);
  try
    Frm.Caption := TrText('Split file into equal parts');
    Frm.Position := poScreenCenter;
    Frm.BorderStyle := bsDialog;
    Frm.ClientWidth := 620;
    Frm.ClientHeight := 440;

    LblSource := TLabel.Create(Frm);
    LblSource.Parent := Frm;
    LblSource.Left := 16;
    LblSource.Top := 16;
    LblSource.Caption := TrText('Source file to split (path or picker):');

    EdtSource := TsFilenameEdit.Create(Frm);
    EdtSource.Parent := Frm;
    EdtSource.Left := 16;
    EdtSource.Top := 36;
    EdtSource.Width := Frm.ClientWidth - 32;
    EdtSource.DialogKind := dkOpen;
    EdtSource.Filter := TrText('All files (*.*)|*.*');
    CurFile := Trim(edtFileName.Text);
    if (CurFile <> '') and (CurFile <> SELECTTEXT) then
      EdtSource.Text := CurFile;
    Frm.SetSourceEdit(EdtSource);
    Frm.EnableFileDrop(True);

    LblParts := TLabel.Create(Frm);
    LblParts.Parent := Frm;
    LblParts.Left := 16;
    LblParts.Top := 80;
    LblParts.Caption := TrText('Number of parts (2..1000):');

    SpnParts := TsSpinEdit.Create(Frm);
    SpnParts.Parent := Frm;
    SpnParts.Left := 16;
    SpnParts.Top := 100;
    SpnParts.Width := 120;
    SpnParts.MinValue := SPLIT_PARTS_MIN;
    SpnParts.MaxValue := SPLIT_PARTS_MAX;
    SpnParts.Value := SPLIT_PARTS_MIN;

    LblHint := TLabel.Create(Frm);
    LblHint.Parent := Frm;
    LblHint.Left := 16;
    LblHint.Top := 132;
    LblHint.Width := Frm.ClientWidth - 32;
    LblHint.Height := 168;
    LblHint.AutoSize := False;
    LblHint.WordWrap := True;
    LblHint.Alignment := taLeftJustify;
    LblHint.Caption := TrText('Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.');

    BtnOk := TButton.Create(Frm);
    BtnOk.Parent := Frm;
    BtnOk.Left := Frm.ClientWidth - 190;
    BtnOk.Top := Frm.ClientHeight - 48;
    BtnOk.Width := 80;
    BtnOk.Caption := TrText('Confirm');
    BtnOk.ModalResult := mrOk;
    BtnOk.Default := True;

    BtnCancel := TButton.Create(Frm);
    BtnCancel.Parent := Frm;
    BtnCancel.Left := Frm.ClientWidth - 100;
    BtnCancel.Top := Frm.ClientHeight - 48;
    BtnCancel.Width := 80;
    BtnCancel.Caption := TrText('Cancel');
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;

    if Frm.ShowModal <> mrOk then
      Exit;

    ASourceFile := Trim(EdtSource.Text);
    APartCount := Integer(SpnParts.Value);
    if (APartCount < SPLIT_PARTS_MIN) or (APartCount > SPLIT_PARTS_MAX) then
    begin
      ShowMessage(Format(TrText('Number of parts must be between %d and %d.'),
        [SPLIT_PARTS_MIN, SPLIT_PARTS_MAX]));
      Exit;
    end;

    Result := True;
  finally
    if Assigned(EdtSource) then
      EdtSource.Color := Frm.FSourceEditDefaultColor;
    Frm.EnableFileDrop(False);
    Frm.Free;
  end;
end;

procedure TfrmMain.miSplitEqualPartsClick(Sender: TObject);
var
  SourceFile: String;
  PartCount: Integer;
  LineCount: Int64;
  Fs: TFileStream;
  CurOpen: String;
begin
  EnsureReadTabVisible;

  if not ShowSplitEqualPartsDialog(SourceFile, PartCount) then
    Exit;

  if SourceFile = '' then
  begin
    ShowMessage(TrText('Source file is required.'));
    Exit;
  end;

  if not FileExists(SourceFile) then
  begin
    ShowMessage(TrText('Source file not found.'));
    Exit;
  end;

  try
    Fs := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyNone);
    try
      if Fs.Size <= 0 then
      begin
        ShowMessage(TrText('Source file is empty.'));
        Exit;
      end;
    finally
      Fs.Free;
    end;
  except
    on E: Exception do
    begin
      ShowMessage(TrText('Could not open source file: ') + E.Message);
      Exit;
    end;
  end;

  LineCount := CountLinesInFile(SourceFile);
  if LineCount < 0 then
  begin
    ShowMessage(TrText('Could not count lines in the source file.'));
    Exit;
  end;

  if LineCount < PartCount then
  begin
    ShowMessage(Format(TrText('Not enough lines in the file for this many parts (lines: %d, parts: %d).'),
      [LineCount, PartCount]));
    Exit;
  end;

  CurOpen := Trim(edtFileName.Text);
  if (CurOpen <> '') and (CurOpen <> SELECTTEXT) and
     SameText(ExpandFileName(SourceFile), ExpandFileName(CurOpen)) then
  begin
    if not EnsureWritableSession then Exit;
    CloseFileStreams;
  end;

  TSplitEqualPartsThread.Create(SourceFile, PartCount);
end;

function TfrmMain.TryGetLineStartOffset(const ALine1Based: Int64;
  out AOffset0Based: Int64): Boolean;
const
  INDEX_REC_SIZE = 20;
var
  IndexFileName: String;
  IdxStream: TFileStream;
  OffsetStr: AnsiString;
  RawOffset: Int64;
begin
  Result := False;
  AOffset0Based := -1;

  if ALine1Based < 1 then Exit;

  IndexFileName := ExtractFilePath(Application.ExeName) + TEMPFILE;
  if not FileExists(IndexFileName) then Exit;

  IdxStream := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);
  try
    if (ALine1Based - 1) * INDEX_REC_SIZE >= IdxStream.Size then Exit;

    SetLength(OffsetStr, 18);
    FillChar(Pointer(OffsetStr)^, 18, 0);
    IdxStream.Seek((ALine1Based - 1) * INDEX_REC_SIZE, soFromBeginning);
    IdxStream.Read(Pointer(OffsetStr)^, 18);

    RawOffset := StrToInt64Def(Trim(string(OffsetStr)), -1);
    if RawOffset <= 0 then Exit;

    AOffset0Based := Abs(RawOffset) - 1;
    Result := AOffset0Based >= 0;
  finally
    IdxStream.Free;
  end;
end;

procedure TfrmMain.miCompareMergeHistoryClick(Sender: TObject);
begin
  if TfrmCompareMerge.ExecuteModal(Self, Trim(edtFileName.Text), Trim(edtFileName.Text)) then
    RefreshFile;
end;

procedure TfrmMain.miMergeFilesClick(Sender: TObject);
var
  DestFileName, SourceFileName: String;
  MergeMode: TMergeFilesMode;
  InsertAfterLine: Int64;
  FromLine, ToLine: Int64;
  InsertOffset: Int64;
  Fs: TFileStream;
begin
  EnsureReadTabVisible;

  DestFileName := Trim(edtFileName.Text);
  if (DestFileName = '') or (DestFileName = SELECTTEXT) then
  begin
    ShowMessage(TrText('Please select/read the destination file first.'));
    Exit;
  end;

  if not FileExists(DestFileName) then
  begin
    ShowMessage(TrText('Destination file not found.'));
    Exit;
  end;

  if not EnsureWritableSession then Exit;

  if not ShowMergeFilesDialog(SourceFileName, MergeMode, InsertAfterLine, FromLine, ToLine) then
    Exit;

  if SourceFileName = '' then
  begin
    ShowMessage(TrText('Source file is required.'));
    Exit;
  end;

  if not FileExists(SourceFileName) then
  begin
    ShowMessage(TrText('Source file not found.'));
    Exit;
  end;

  if SameText(ExpandFileName(SourceFileName), ExpandFileName(DestFileName)) then
  begin
    ShowMessage(TrText('Source and destination files must be different.'));
    Exit;
  end;

  try
    try
      Fs := TFileStream.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
    finally
      FreeAndNil(Fs);
    end;
  except
    on E: Exception do
    begin
      ShowMessage(TrText('Could not open source file: ') + E.Message);
      Exit;
    end;
  end;

  try
    try
      Fs := TFileStream.Create(DestFileName, fmOpenReadWrite or fmShareDenyNone);
    finally
      FreeAndNil(Fs);
    end;  
  except
    on E: Exception do
    begin
      ShowMessage(TrText('Destination file is in use by another process: ') + E.Message);
      Exit;
    end;
  end;

  case MergeMode of
    mfmBeginning:
      InsertOffset := 0;
    mfmEnd:
      InsertOffset := UnUtils.GetFileSize(DestFileName);
    mfmLineRange:
      begin
        { Modo de copiar intervalo de linhas do arquivo de origem }
        { Neste modo, o offset será tratado como -1 para indicar o modo especial }
        { e as linhas FromLine e ToLine serão passadas ao thread }
        InsertOffset := 0; { Será ignorado no thread para este modo }
      end;
  else
    begin
      if totalLines < 2 then
      begin
        ShowMessage(TrText('Destination file must have at least 2 lines for insertion by line.'));
        Exit;
      end;
      if (InsertAfterLine < 1) or (InsertAfterLine > (totalLines - 1)) then
      begin
        ShowMessage(Format(TrText('Invalid line. Use a value from %d to %d.'),
          [1, totalLines - 1]));
        Exit;
      end;
      if not TryGetLineStartOffset(InsertAfterLine + 1, InsertOffset) then
      begin
        ShowMessage(TrText('Could not resolve insertion position. Read destination file again and retry.'));
        Exit;
      end;
    end;
  end;

  { Evita lock do proprio app (streams usados para visualizacao/leitura). }
  CloseFileStreams;
  
  { Se modo é intervalo de linhas, passa as linhas ao thread }
  if MergeMode = mfmLineRange then
    TMergeFilesThread.Create(DestFileName, SourceFileName, 0, True, True, FromLine, ToLine)
  else
    TMergeFilesThread.Create(DestFileName, SourceFileName, InsertOffset);
end;

procedure TfrmMain.miFindInFilesClick(Sender: TObject);
begin
  { Nao chamar EnsureReadTabVisible: evita abrir/focar a aba Read junto com Find in Files. }
  if Assigned(btnShowTabFindFile) and btnShowTabFindFile.Enabled then
    btnShowTabFindFileClick(btnShowTabFindFile);
end;

procedure TfrmMain.miInsertLineClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnEditFile) and btnEditFile.Enabled then
    editFile(otInsert);
end;

procedure TfrmMain.miDuplicateLineClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnEditFile) and btnEditFile.Enabled then
    editFile(otDuplicate);
end;

procedure TfrmMain.miEditLineClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnEditFile) and btnEditFile.Enabled then
    editFile(otEdit);
end;

procedure TfrmMain.miDeleteLinesClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnEditFile) and btnEditFile.Enabled then
    editFile(otDelete);
end;

procedure TfrmMain.miExportClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnExport) and btnExport.Enabled then
    btnExportClick(btnExport);
end;

procedure TfrmMain.miClearClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnClear) and btnClear.Enabled then
    btnClearClick(btnClear);
end;

procedure TfrmMain.miConsumerAIClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if Assigned(btnConsumerAI) and btnConsumerAI.Enabled then
    btnConsumerAIClick(btnConsumerAI);
end;

procedure TfrmMain.BuildClassicMainMenu;
  function AddItem(AParent: TMenuItem; const ACaption: string; AOnClick: TNotifyEvent;
    const AShortcut: TShortCut = 0; const AImageIndex: Integer = -1): TMenuItem;
  begin
    Result := TMenuItem.Create(MainMenu1);
    Result.Caption := ACaption;
    if Assigned(AOnClick) then
      Result.OnClick := AOnClick;
    if AShortcut <> 0 then
      Result.ShortCut := AShortcut;
    if AImageIndex >= 0 then
      Result.ImageIndex := AImageIndex;
    AParent.Add(Result);
  end;

  procedure AddSeparator(AParent: TMenuItem);
  begin
    AddItem(AParent, '-', nil);
  end;
var
  MFile, MEdit, MView, MOptions, MHelp: TMenuItem;
begin
  if not Assigned(MainMenu1) then Exit;
  { D7: TMenuItem nao tem BeginUpdate/EndUpdate nesta hierarquia. }
  MainMenu1.Items.Clear;
  if Assigned(FMenuBitmapImages) and (FMenuBitmapImages.Count > 0) then
    MainMenu1.Images := FMenuBitmapImages
  else
    MainMenu1.Images := CharImageList16;
  Self.Menu := MainMenu1;

    MFile := AddItem(MainMenu1.Items, TrText('&File'), nil, 0, MenuIconIndex('open.bmp', 3));
    AddItem(MFile, TrText('&Open file...'), miOpenFileClick, ShortCut(Ord('O'), [ssCtrl]), MenuIconIndex('open.bmp', 3));
    AddItem(MFile, TrText('&Recent files'), miRecentFilesClick, ShortCut(Ord('R'), [ssCtrl]), MenuIconIndex('box closed.bmp', 32));
    AddItem(MFile, TrText('Read &tab'), miShowReadTabClick, ShortCut(Ord('1'), [ssCtrl]), MenuIconIndex('normal view.bmp', 1));
    AddItem(MFile, TrText('Read / &Load'), miReadLoadClick, ShortCut(VK_F5, []), MenuIconIndex('normal view.bmp', 14));
    AddSeparator(MFile);
    AddItem(MFile, TrText('E&xit'), miExitClick, ActionCloseForm.ShortCut, MenuIconIndex('exit.bmp', 10));

    MEdit := AddItem(MainMenu1.Items, TrText('&Edit'), nil, 0, MenuIconIndex('edit.bmp', 12));
    AddItem(MEdit, TrText('&Find...'), miFindClick, ShortCut(Ord('F'), [ssCtrl]), MenuIconIndex('search.bmp', 12));
    AddItem(MEdit, TrText('Find in &Files...'), miFindInFilesClick, ShortCut(Ord('F'), [ssCtrl, ssShift]), MenuIconIndex('search.bmp', 12));
    AddItem(MEdit, TrText('Find and &Replace...'), miFindReplaceClick, ShortCut(Ord('H'), [ssCtrl]), MenuIconIndex('search and replace.bmp', 12));
    AddItem(MEdit, TrText('&Go to line...'), miGotoLineClick, ShortCut(Ord('G'), [ssCtrl]), MenuIconIndex('goto line.bmp', 7));
    AddItem(MEdit, TrText('&Go to byte offset...'), miGotoByteOffsetClick, ShortCut(Ord('G'), [ssCtrl, ssShift]), MenuIconIndex('goto line.bmp', 7));
    AddSeparator(MEdit);
    AddItem(MEdit, TrText('Undo'), miUndoClick, ShortCut(Ord('Z'), [ssCtrl]), MenuIconIndex('undo.bmp', 24));
    AddItem(MEdit, TrText('Redo'), miRedoClick, ShortCut(Ord('Y'), [ssCtrl]), MenuIconIndex('redo.bmp', 24));
    AddSeparator(MEdit);
    AddItem(MEdit, TrText('Copy selection'), miCopyClick, ShortCut(Ord('C'), [ssCtrl]), MenuIconIndex('copy.bmp', 9));

    MView := AddItem(MainMenu1.Items, TrText('&View'), nil, 0, MenuIconIndex('normal view.bmp', 1));
    AddItem(MView, TrText('&Word wrap'), miToggleWordWrapClick, ShortCut(Ord('W'), [ssCtrl]), MenuIconIndex('word wrap.bmp', 11));
    AddItem(MView, TrText('S&elect (checkbox list)'), miSelectClick, ShortCut(Ord('S'), [ssCtrl, ssShift]), MenuIconIndex('select all.bmp', 10));
    AddSeparator(MView);
    AddItem(MView, TrText('Zoom &in (list)'), miZoomListViewInClick, ShortCut(VK_ADD, [ssCtrl]),
      MenuIconIndex(FF_MENU_BMP_ZOOM_LIST, MenuIconIndex('forward.bmp', 2)));
    AddItem(MView, TrText('Zoom o&ut (list)'), miZoomListViewOutClick, ShortCut(VK_SUBTRACT, [ssCtrl]),
      MenuIconIndex(FF_MENU_BMP_ZOOM_LIST, MenuIconIndex('forward.bmp', 2)));
    AddSeparator(MView);
    AddItem(MView, TrText('&Toggle bookmark'), miToggleBookmarkClick, ShortCut(Ord('B'), [ssCtrl]), MenuIconIndex('pushpin.bmp', 31));
    AddItem(MView, TrText('&Next bookmark'), miNextBookmarkClick, ShortCut(VK_F2, []), MenuIconIndex('pushpin.bmp', 31));
    AddItem(MView, TrText('Pr&evious bookmark'), miPrevBookmarkClick, ShortCut(VK_F2, [ssShift]), MenuIconIndex('pushpin.bmp', 31));
    AddItem(MView, TrText('Clear a&ll bookmarks'), miClearBookmarksClick, ShortCut(Ord('B'), [ssCtrl, ssShift]), MenuIconIndex('pushpin.bmp', 31));

    MOptions := AddItem(MainMenu1.Items, TrText('&Options'), nil, 0, MenuIconIndex('tools.bmp', 6));
    FMenuReadOnlyItem :=
      AddItem(MOptions, TrText('Read-only &session'), miToggleReadOnlyClick,
        ShortCut(Ord('R'), [ssCtrl, ssAlt]), MenuIconIndex('box closed.bmp', 32));
    FMenuReadOnlyItem.Checked := FFileSessionReadOnly;
    FMenuSegmentedHeavyOpsItem :=
      AddItem(MOptions, TrText('Line-segmented &mode (heavy ops)'), miToggleSegmentedHeavyOpsClick, 0,
        MenuIconIndex('grid split cells.bmp', 19));
    if Assigned(FMenuSegmentedHeavyOpsItem) then
      FMenuSegmentedHeavyOpsItem.Checked := Assigned(chkSegmentedHeavyOps) and chkSegmentedHeavyOps.Checked;
    AddItem(MOptions, TrText('Tail / &Follow mode'), miToggleTailClick, ShortCut(Ord('T'), [ssCtrl]), MenuIconIndex('forward.bmp', 2));
    AddItem(MOptions, TrText('Fil&ter / Grep'), miFilterClick, ShortCut(Ord('L'), [ssCtrl]), MenuIconIndex('find.bmp', 4));
    AddItem(MOptions, TrText('E&xport filtered results'), miExportFilteredClick, ShortCut(Ord('L'), [ssCtrl, ssShift]), MenuIconIndex('save as.bmp', 11));
    AddSeparator(MOptions);
    AddItem(MOptions, TrText('Spl&it Files'), miSplitFilesClick, ShortCut(Ord('K'), [ssCtrl, ssShift]), MenuIconIndex('grid split cells.bmp', 19));
    AddItem(MOptions, TrText('&Merge lines'), miMergeLinesClick, ShortCut(Ord('M'), [ssCtrl, ssShift]), MenuIconIndex('grid merge cells.bmp', 22));
    AddItem(MOptions, TrText('Merge &files...'), miMergeFilesClick,
      ShortCut(Ord('J'), [ssCtrl, ssShift]), MenuIconIndex('grid.bmp', 22));
    AddItem(MOptions, TrText('Compare / merge + &history...'), miCompareMergeHistoryClick,
      ShortCut(Ord('H'), [ssCtrl, ssShift]), MenuIconIndex('grid merge cells.bmp', 22));
    AddItem(MOptions, TrText('Split file into e&qual parts...'), miSplitEqualPartsClick,
      ShortCut(Ord('P'), [ssCtrl, ssShift]), MenuIconIndex('grid split cells.bmp', 19));
    AddItem(MOptions, TrText('&Insert line'), miInsertLineClick, ShortCut(Ord('I'), [ssCtrl, ssShift]), MenuIconIndex('plus.bmp', 17));
    AddItem(MOptions, TrText('D&uplicate line'), miDuplicateLineClick, ShortCut(Ord('U'), [ssCtrl, ssShift]), MenuIconIndex('plus.bmp', 17));
    AddItem(MOptions, TrText('&Edit line'), miEditLineClick, ShortCut(Ord('E'), [ssCtrl, ssShift]), MenuIconIndex('edit.bmp', 17));
    AddItem(MOptions, TrText('&Delete line'), miDeleteLinesClick, ShortCut(Ord('D'), [ssCtrl, ssShift]), MenuIconIndex('delete.bmp', 16));
    AddItem(MOptions, TrText('Exp&ort'), miExportClick, ShortCut(Ord('O'), [ssCtrl, ssShift]), MenuIconIndex('save as.bmp', 11));
    AddItem(MOptions, TrText('&Clear'), miClearClick, ShortCut(Ord('X'), [ssCtrl, ssShift]), MenuIconIndex('clear.bmp', 12));
    AddItem(MOptions, TrText('&AI (Consumer)'), miConsumerAIClick, ShortCut(Ord('A'), [ssCtrl, ssShift]), MenuIconIndex('report.bmp', 21));

    MHelp := AddItem(MainMenu1.Items, TrText('&Help'), nil, 0, MenuIconIndex('help.bmp', 20));
    AddItem(MHelp, TrText('&Help / Shortcuts'), BtnHelpClick, ShortCut(VK_F1, []), MenuIconIndex('help.bmp', 20));
    AddSeparator(MHelp);
    AddItem(MHelp, TrText('&Version History'), miVersionHistoryClick, 0, MenuIconIndex('history.bmp', 18));
    AddSeparator(MHelp);
    AddItem(MHelp, TrText('&More info / Splash...'), About1Click, 0, MenuIconIndex('information.bmp', 18));
    AddItem(MHelp, TrText('&About FastFile'), btnSplashClick, 0, MenuIconIndex('help.bmp', 18));
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    if not IsZoomed(Handle) then
      try // Save window position in Ini-file if it's possible
        sStoreUtils.WriteIniStr(APPLICATION_NAME, 'Top', IntToStr(Top), IniName);
      finally
        sStoreUtils.WriteIniStr(APPLICATION_NAME, 'Left', IntToStr(Left), IniName);
      end;
    // Save skin data if exists in Ini
    sStoreUtils.WriteIniStr(APPLICATION_NAME, 'SkinDirectory', DataModule1.sSkinManager1.SkinDirectory, IniName);      // Skin directory
    sStoreUtils.WriteIniStr(APPLICATION_NAME, 'SkinName',      DataModule1.sSkinManager1.SkinName, IniName);           // Skin name
    sStoreUtils.WriteIniStr(APPLICATION_NAME, 'SkinActive', iff(DataModule1.sSkinManager1.Active, '1', '0'), IniName); // Skin activity
    if Assigned(chkSegmentedHeavyOps) then
      sStoreUtils.WriteIniStr(APPLICATION_NAME, 'SegmentHeavyOps',
        iff(chkSegmentedHeavyOps.Checked, '1', '0'), IniName);
    ResetLastError;
    // Check if custom skin has been defined in the "Menus" frame
    if sSkinMenus.CustomMenuFont <> nil then
      FreeAndNil(sSkinMenus.CustomMenuFont);
  finally
    ActionClear.Execute;
  end;

  //It´s necessary to empty the temp file because we are no longer use it anymore.
  (*if Assigned(textFile) then FreeAndNil(textFile);
  try
    textFile := TGpHugeFileStream.Create(ExtractFilePath(Application.ExeName) + TEMPFILE, accWrite);
  finally
    FreeAndNil(textFile);
  end; *)
  UnUtils.ForceDeleteFile(ExtractFilePath(Application.ExeName) + TEMPFILE);
end;

procedure TfrmMain.sFloatSampleCloseItems0Click(Sender: TObject);
begin
  Enabled := False;
  // Watermark may be configured in the "MainForm.sFloatSample" component
  if sMessageDlg(TrText('Hide the watermark?'), mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    sFloatSampleClose.Items[0].Visible := False;
    sFloatSample.Items[0].Visible := False;
  end;
  Enabled := True;
end;

procedure TfrmMain.sFloatSampleCloseItems0MouseLeave(Sender: TObject);
begin
  if not sFloatSample.Items[0].IsUnderMouse then // If not active
    sFloatSampleClose.Items[0].Visible := False;
end;

procedure TfrmMain.sFloatSampleItems0MouseEnter(Sender: TObject);
begin
  sFloatSampleClose.Items[0].Visible := True;
end;

procedure TfrmMain.sFloatSampleItems0MouseLeave(Sender: TObject);
begin
  if not sFloatSampleClose.Items[0].IsUnderMouse then // If not active
    sFloatSampleClose.Items[0].Visible := False;
end;

procedure TfrmMain.sSpeedButton10Click(Sender: TObject);
begin
  changeBidiMode;
end;

procedure TfrmMain.sSpeedButton1Click(Sender: TObject);
begin
  ActionAnimation.Execute;
end;

procedure TfrmMain.SkinMenuClick(Sender: TObject);
begin
  DataModule1.sSkinManager1.SkinName := DelChars(TMenuItem(Sender).Caption, '&');
end;

procedure TfrmMain.GenerateSkinsList;
var
  i: integer;
  mi: TMenuItem;
  sl: TacStringList;
begin
  // Menu update
  Builtinskins1.Clear;
  // Build-in skins list
  for i := 0 to DataModule1.sSkinManager1.InternalSkins.Count - 1 do begin
    mi := TMenuItem.Create(Application);
    mi.Caption := DataModule1.sSkinManager1.InternalSkins[i].Name;
    if mi.Caption = DataModule1.sSkinManager1.SkinName then
      mi.Checked := True;

    mi.OnClick := SkinMenuClick;
    mi.RadioItem := True;
    Builtinskins1.Add(mi);
  end;
  // External skins list
  Externalskins1.Clear;
  sl := TacStringList.Create;
  DataModule1.sSkinManager1.GetExternalSkinNames(sl);
  if sl.Count > 0 then begin
    sl.Sort;
    for i := 0 to sl.Count - 1 do begin
      mi := TMenuItem.Create(Application);
      mi.Caption := sl[i];
      if mi.Caption = DataModule1.sSkinManager1.SkinName then begin
        mi.Checked := True;
        mi.Default := True;
      end;
      mi.OnClick := SkinMenuClick;
      mi.RadioItem := True;
      if (i <> 0) and (i mod 20 = 0) then
        mi.Break := mbBreak;

      Externalskins1.Add(mi);
    end;
  end;
  FreeAndNil(sl);
end;

procedure TfrmMain.Loaded;
begin
  // Parameters of scaling
  if DataModule1.sSkinManager1.Options.ScaleMode <> smVCL then
    Scaled := False; // Standard VCL scaling should be disabled before standard "Loaded" or in design-time

  inherited;
end;

procedure TfrmMain.sSkinManager1GetMenuExtraLineData(FirstItem: TMenuItem; var SkinSection, Caption: string; var Glyph: TBitmap; var LineVisible: Boolean);
var
  iGlyphSize: integer;

  function GetSectionTextColor: TColor; // Get text color for colorizing of glyph received from CharImageList
  var
    Ndx: integer;
  begin
    Ndx := DataModule1.sSkinManager1.GetSkinIndex(SkinSection);
    if Ndx >= 0 then
      Result := sSkinProvider1.SkinData.CommonSkinData.gd[Ndx].Props[0].FontColor.Color
    else
      Result := clBlack;
  end;

begin
  LineVisible := True; // External line is visible
  iGlyphSize := ScaleInt(22, sSkinProvider1.SkinData);
  if (sSkinProvider1.SystemMenu.Items[0].Name = s_SkinSelectItemName) and // If item is a first subitem of 'Available skins' (in system menu)
       (sSkinProvider1.SystemMenu.Items[0].Count > 8) and // Height of popup-menu should be higher then extra-line width...
         (FirstItem = sSkinProvider1.SystemMenu.Items[0].Items[0]) then begin
    Caption := sSkinProvider1.SystemMenu.Items[0].Caption;
    Glyph := CharImageList16.CreateBitmap32Color(7, iGlyphSize, iGlyphSize, GetSectionTextColor, iGlyphSize);
  end
  else
    if (Externalskins1.Count > 8) and (FirstItem = Externalskins1.Items[0]) then begin
      Caption := Externalskins1.Caption;
      Glyph := CharImageList16.CreateBitmap32Color(7, iGlyphSize, iGlyphSize, GetSectionTextColor, iGlyphSize);
    end
    else
      if (FirstItem = PopupMenu1.Items[0]) then begin
        Caption := Tr('titlebar.tools', 'Tools');
        Glyph := CharImageList16.CreateBitmap32Color(33, iGlyphSize, iGlyphSize, GetSectionTextColor, iGlyphSize);
      end
      else
        (*if (FirstItem = miSysDialogs) then begin
          Caption := 'Most sys dialogs are skinned';
          Glyph := CharImageList16.CreateBitmap32Color(34, iGlyphSize, iGlyphSize, GetSectionTextColor, iGlyphSize);
        end
        else
          LineVisible := False;   *)
        Caption := Tr('titlebar.tools', 'Tools');
          Glyph := CharImageList16.CreateBitmap32Color(34, iGlyphSize, iGlyphSize, GetSectionTextColor, iGlyphSize);
end;

procedure TfrmMain.ActionSkinnedExecute(Sender: TObject);
begin
(*  ActionSkinned.Checked := not ActionSkinned.Checked;
  sSkinManager1.Active := ActionSkinned.Checked;
  if CurrentFrame <> nil then
    CurrentFrame.SkinActiveChanged; *)
end;

procedure TfrmMain.ActionHintsDisableExecute(Sender: TObject);
begin
  if not ActionHintsDisable.Checked then begin
    ActionHintsDisable.Checked := True;
    ActionHintsCustom.Checked := False;
    ActionHintsSkinned.Checked := False;
    ActionHintsStd.Checked := False;
    ShowHint := False;
  end;
end;

procedure TfrmMain.ActionCloseExecute(Sender: TObject);
begin
  Close
end;   

procedure TfrmMain.ActionAnimationExecute(Sender: TObject);
begin
  Animated := not ActionAnimation.Checked; // Saving option in variable
  ActionAnimation.Checked := Animated;
  if Animated then begin
    sSpeedButton1.Caption := TrText('Stop') + #13#10 + TrText('animation');
    sSpeedButton1.ImageIndex := 0;
  end
  else begin
    sSpeedButton1.Caption := TrText('Allow') + #13#10 + TrText('animation');
    sSpeedButton1.ImageIndex := 1;
  end;
  DataModule1.sSkinManager1.Effects.AllowAnimation := Animated; // Control all animation
end;

procedure TfrmMain.ActionHintsSkinnedExecute(Sender: TObject);
begin
  if not ActionHintsSkinned.Checked then begin
    ActionHintsSkinned.Checked := True;
    ActionHintsCustom.Checked  := False;
    ActionHintsDisable.Checked := False;
    ActionHintsStd.Checked     := False;
    sAlphaHints1.UseSkinData   := True;
    ShowHint := True;
    sAlphaHints1.Active := not ActionHintsStd.Checked;
  end;
end;

procedure TfrmMain.ActionHintsCustomExecute(Sender: TObject);
begin
  if not ActionHintsCustom.Checked then begin
    ActionHintsCustom.Checked  := True;
    ActionHintsSkinned.Checked := False;
    ActionHintsDisable.Checked := False;
    ActionHintsStd.Checked     := False;
    sAlphaHints1.UseSkinData   := False;
    ShowHint := True;
    sAlphaHints1.Active := not ActionHintsStd.Checked;
  end;
end;

procedure TfrmMain.miOpenDialog1Click(Sender: TObject);
begin
  with TOpenDialog.Create(Self) do begin
    Execute;
    Free;
  end;
end;

procedure TfrmMain.miSaveDialog1Click(Sender: TObject);
begin
  with TSaveDialog.Create(Self) do begin
    Execute;
    Free;
  end;
end;

procedure TfrmMain.miOpenPictureDialog1Click(Sender: TObject);
begin
  with TOpenPictureDialog.Create(Self) do begin
    Execute;
    Free;
  end;
end;

procedure TfrmMain.miSavePictureDialog1Click(Sender: TObject);
begin
  with TSavePictureDialog.Create(Self) do begin
    Execute;
    Free;
  end;
end;

procedure TfrmMain.miColorDialog1Click(Sender: TObject);
begin
  with TColorDialog.Create(Self) do begin
    Execute;
    Free;
  end;
end;

procedure TfrmMain.miPrintDialog1Click(Sender: TObject);
begin
  with TPrintDialog.Create(Self) do begin
    Execute;
    Free;
  end;
end;

procedure TfrmMain.miPrinterSetupDialog1Click(Sender: TObject);
begin
  with TPrinterSetupDialog.Create(Self) do begin
    Execute;
    Free;
  end;
end;

procedure TfrmMain.miFindDialog1Click(Sender: TObject);
begin
  TFindDialog.Create(Self).Execute;
end;

procedure TfrmMain.miReplaceDialog1Click(Sender: TObject);
begin
  TReplaceDialog.Create(Self).Execute;
end;

procedure TfrmMain.miAlphaColorDialog1Click(Sender: TObject);
begin
  with TsColorDialog.Create(Self) do begin
    UseAlpha := True; // Enable support of Alpha channell
    Color := TColor($9900FF00);
    Execute;
    Free;
  end;
end;

procedure TfrmMain.sMagnifier1DblClick(Sender: TObject);
begin
  sMagnifier1.Hide
end;

procedure TfrmMain.sMagnifier1GetSourceCoords(var ATopLeft: TPoint);
begin
  if CustomMagnifierSource then begin
    ATopLeft := acMousePos; // Current coords of mouse cursor
    if Assigned(acMagnForm) then begin // If magnifier window is created
      dec(ATopLeft.X, acMagnForm.Width  div (sMagnifier1.Scaling * 2)); // Offset a position for showing in the magnifier center
      dec(ATopLeft.Y, acMagnForm.Height div (sMagnifier1.Scaling * 2));
    end;
  end;
end;

procedure TfrmMain.SpeedBtnPPIClick(Sender: TObject);
var
  p: TPoint;
begin
  if FormPopupScaling = nil then
    FormPopupScaling := TFormPopupScaling.Create(Self);

  p := SpeedBtnPPI.ClientToScreen(Point(0, SpeedBtnPPI.Height));
  ShowPopupForm(FormPopupScaling, p);
end;

procedure TfrmMain.ActionCloseFormExecute(Sender: TObject);
begin
  Close
end;

procedure TfrmMain.ActionHintsStdExecute(Sender: TObject);
begin
  if not ActionHintsStd.Checked then begin
    ActionHintsStd.Checked     := True;
    ActionHintsSkinned.Checked := False;
    ActionHintsDisable.Checked := False;
    ActionHintsCustom.Checked  := False;
    sAlphaHints1.UseSkinData   := False;
    ShowHint := True;
    // Remove temporary hint windows if exists, when switched to std hints
    if sAlphaHints1.NewWindow <> nil then
      FreeAndNil(sAlphaHints1.NewWindow);

    if sAlphaHints1.AnimWindow <> nil then
      FreeAndNil(sAlphaHints1.AnimWindow);

    sAlphaHints1.Active := not ActionHintsStd.Checked;
  end;
end;

procedure TfrmMain.sSpeedButton5Click(Sender: TObject);
begin
  DataModule1.sSkinManager1.BeginUpdate;
  DataModule1.sSkinManager1.ExtendedBorders := not DataModule1.sSkinManager1.ExtendedBorders;
  DataModule1.sSkinManager1.EndUpdate(True, False);
end;

procedure TfrmMain.sSpeedButton7Click(Sender: TObject);
begin
  //About.Opened := not About.Opened;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  Self.Close;
end;

// -----------------------------------------------------------------------------
// EVENT: OnDrawPanel (Handles the custom rendering)
// -----------------------------------------------------------------------------
procedure TfrmMain.sStatusBar1DrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
var
  TextContent: String;
  IconIndex, Spacing, LeftMargin: Integer;
  IconY, TextY: Integer;
  IconWidth, TextWidth: Integer;
begin
  // We only want to custom draw the first panel (Index 0)
  if Panel.Index = 0 then
  begin
    // 1. Clear the panel background
    StatusBar.Canvas.FillRect(Rect);

    // 2. Initial Configuration
    TextContent := Panel.Text;
    IconIndex := 24;      // Index of the image in the ImageList
    Spacing := 6;        // Spacing between icon and text (pixels)
    LeftMargin := 4;     // Small padding from the panel's left border

    // Set Canvas properties
    StatusBar.Canvas.Brush.Style := bsClear; // Transparent text background

    // Get Dimensions
    IconWidth := ImageList1.Width;
    TextWidth := StatusBar.Canvas.TextWidth(TextContent);

    // 3. Calculate Vertical Centering
    // Formula: Top + ((TotalHeight - ObjectHeight) / 2)
    IconY := Rect.Top + ((Rect.Bottom - Rect.Top - ImageList1.Height) div 2);
    TextY := Rect.Top + ((Rect.Bottom - Rect.Top - StatusBar.Canvas.TextHeight(TextContent)) div 2);

    // 4. Rendering Logic based on Alignment
    case FCurrentIconAlignment of

      // CASE A: ICON ON THE LEFT (Icon -> Text)
      iaLeft:
      begin
        // Draw Icon at the start
        ImageList1.Draw(StatusBar.Canvas, Rect.Left + LeftMargin, IconY, IconIndex);

        // Draw Text after the Icon
        StatusBar.Canvas.TextOut(Rect.Left + LeftMargin + IconWidth + Spacing, TextY, TextContent);
      end;

      // CASE B: ICON ON THE RIGHT (Text -> Icon)
      iaRight:
      begin
        // Draw Text at the start
        StatusBar.Canvas.TextOut(Rect.Left + LeftMargin, TextY, TextContent);

        // Draw Icon after the Text
        ImageList1.Draw(StatusBar.Canvas, Rect.Left + LeftMargin + TextWidth + Spacing, IconY, IconIndex);
      end;
    end;
  end
  else if Panel.Index = 1 then begin // Paint glyph on a status panel
    StatusBar.Canvas.Font.Color := DataModule1.sSkinManager1.Palette[pcLabelText];
    SetImagesPPI(CharImageList16, GetPPI(sStatusBar1.SkinData));
    CharImageList16.Draw(StatusBar.Canvas, Rect.Left + 2, Rect.Top + 4, 25);
  end
  else if Panel.Index = 3 then begin // Paint glyph on a status panel
    StatusBar.Canvas.Font.Color := DataModule1.sSkinManager1.Palette[pcLabelText];
    SetImagesPPI(CharImageList16, GetPPI(sStatusBar1.SkinData));
    CharImageList16.Draw(StatusBar.Canvas, Rect.Left + 2, Rect.Top + 4, 30);
  end;
end;

procedure TfrmMain.sTitleBar1Items0Click(Sender: TObject);
begin
  //sSplitView1.Opened := not sSplitView1.Opened;
end;

procedure TfrmMain.sSkinManager1GetPopupItemData(Item: TMenuItem; State: TOwnerDrawState; ItemData: TacMenuItemData);
begin
  // Example of custom font in menu items
  if (Item = Builtinskins1) (* or (Item = miAlphaColordialog1)  *)then begin
    ItemData.Font.Style := [fsBold];
    ItemData.Font.Size := ItemData.Font.Size + 2;
  end;
end;

procedure TfrmMain.sSkinManager1ScaleChanged(Sender: TObject);
begin
  sSkinManager1FontChanged(DataModule1.sSkinManager1, '', '');
  LayoutViewEncodingCombo;
end;

procedure TfrmMain.sTitleBar1Items10Click(Sender: TObject);
begin
  sMagnifier1.Execute;
end;

procedure TfrmMain.sTitleBar1Items13Click(Sender: TObject);
const
  PPIArray: array [0..4] of integer = (48, 96, 120, 144, 192);
begin
//  DataModule1.sSkinManager1.Options.PixelsPerInch := PPIArray[TacTitleBarItem(Sender).Tag];
//  DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
  SetPPIAnimated(PPIArray[TacTitleBarItem(Sender).Tag]);
end;

procedure TfrmMain.sTitleBar1Items15Click(Sender: TObject);
begin
  DataModule1.sSkinManager1.BeginUpdate;
  DataModule1.sSkinManager1.HueOffset := TacTitleBarItem(Sender).Tag;
  DataModule1.sSkinManager1.EndUpdate(True, False); // Repaint without animation
end;

procedure TfrmMain.sTitleBar1Items4Click(Sender: TObject);
begin
  sSkinProvider1.TitleIcon.Visible := not sSkinProvider1.TitleIcon.Visible; // Title icon
//  sTitleBar1.Items[4].Enabled := False;
end;

procedure TfrmMain.sSpeedButton9Click(Sender: TObject);
begin
  DoSelectSkin;
end;

procedure TfrmMain.miSysDialogsClick(Sender: TObject);
begin
 (* miSysDialogs.Checked := not miSysDialogs.Checked;
  if miSysDialogs.Checked then
    sSkinManager1.SkinningRules := sSkinManager1.SkinningRules + [srStdDialogs]
  else
    sSkinManager1.SkinningRules := sSkinManager1.SkinningRules - [srStdDialogs];  *)
end;

procedure TfrmMain.N71Click(Sender: TObject);
begin
  TMenuItem(Sender).Default := True;
  TMenuItem(Sender).Checked := True;
  SpeedBtnPPI.Caption := TrText('Custom PPI: ') + TMenuItem(Sender).Caption;
  if Animated then
    SetPPIAnimated(TMenuItem(Sender).Tag)
  else begin
    DataModule1.sSkinManager1.Options.PixelsPerInch := TMenuItem(Sender).Tag;
    DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
  end;
end;

procedure TfrmMain.PopupMenu1Popup(Sender: TObject);
begin
  if (Builtinskins1.Count = 0) and (Externalskins1.Count = 0) then begin
    GenerateSkinsList; // Generate a list of available skins form menu
    DataModule1.sSkinManager1.SkinableMenus.HookPopupMenu(PopupMenu1, DataModule1.sSkinManager1.Active);
  end;
  if Assigned(FToolsExtrasWordWrap) then
    FToolsExtrasWordWrap.Checked := Assigned(chkWordWrap) and chkWordWrap.Checked;
  if Assigned(FToolsExtrasReadOnly) then
    FToolsExtrasReadOnly.Checked := FFileSessionReadOnly;
  if Assigned(FToolsExtrasSegmented) then
    FToolsExtrasSegmented.Checked := Assigned(chkSegmentedHeavyOps) and chkSegmentedHeavyOps.Checked;
  if Assigned(FToolsExtrasTail) then
    FToolsExtrasTail.Checked := FTailActive;
  if Assigned(FToolsExtrasFilter) then
    FToolsExtrasFilter.Checked := FFilterActive;
end;

procedure ChangeHUE(sm: TsSkinManager; Value: integer; DoRepaint: boolean);
begin
  sm.BeginUpdate;
  sm.HueOffset := Value;
  sm.EndUpdate(DoRepaint, False {no animation});
end;

function TfrmMain.BuildSimpleComponentHint(const AControl: TControl): string;
var
  N: string;
begin
  Result := '';
  if not Assigned(AControl) then Exit;

  N := LowerCase(AControl.Name);

  { --- Read tab ----------------------------------------------------------- }
  if N = 'btnshowtabreadfile' then
    Result := TrText('Open the Read File tab.')
  else if N = 'edtfilename' then
    Result := TrText('Select the source file to read.')
  else if N = 'btnread' then
    Result := TrText('Read the selected file and load its lines.')
  else if N = 'edtsearch' then
    Result := TrText('Type text to search within loaded lines.')
  else if N = 'btnsearch' then
    Result := TrText('Search for the typed text in the loaded lines.')
  else if N = 'edtgotoline' then
    Result := TrText('Jump to a specific line number.')
  else if (N = 'btnup') or (N = 'btndown') then
    Result := TrText('Navigate quickly through loaded lines.')
  else if N = 'btncheckboxes' then
    Result := TrText('Switch to checkbox selection mode.')
  else if N = 'btneditfile' then
    Result := TrText('Edit selected lines in the file.')
  else if N = 'btndeletelines' then
    Result := TrText('Delete selected lines from the file.')
  else if N = 'btnexport' then
    Result := TrText('Export selected lines or results.')
  else if N = 'btnsplitfiles' then
    Result := TrText('Open split file tools.')
  else if N = 'btnmergemultiplelines' then
    Result := TrText('Merge multiple edited lines into the source file.')
  else if (N = 'btnreturn') or (N = 'btnreturnread') then
    Result := TrText('Close the current tab and return to main view.')

  { --- Find Files tab ----------------------------------------------------- }
  else if N = 'btnshowtabfindfile' then
    Result := TrText('Open the Find Files tab.')
  else if N = 'filename' then
    Result := TrText('Type file name patterns to search.')
  else if N = 'location' then
    Result := TrText('Type folders where files should be searched.')
  else if N = 'phrase' then
    Result := TrText('Type text content to find inside files.')
  else if N = 'findbutton' then
    Result := TrText('Start searching files with current filters.')
  else if N = 'stopbutton' then
    Result := TrText('Stop the current file search.')
  else if N = 'subfolders' then
    Result := TrText('Include subfolders in file search.')
  else if N = 'casesenstitive' then
    Result := TrText('Match uppercase and lowercase exactly.')
  else if N = 'wholeword' then
    Result := TrText('Match only whole words.')
  else if N = 'negate' then
    Result := TrText('Exclude files that match the entered text.')
  else if N = 'threaded' then
    Result := TrText('Run search in background threads.')
  else if N = 'foundfiles' then
    Result := TrText('List of files found by the current search.')

  { --- Split File tab ----------------------------------------------------- }
  else if N = 'spnfromsplitbyline' then
    Result := TrText('First line number to export.')
  else if N = 'spntosplitbyline' then
    Result := TrText('Last line number to export.')
  else if N = 'edtoutputsplitbylinetext' then
    Result := TrText('Choose output file name for split by lines.')
  else if N = 'btnexecutesplitfilebylines' then
    Result := TrText('Generate a file using the selected line range.')
  else if N = 'trkfiles' then
    Result := TrText('Set how many files should be generated.')
  else if N = 'btnexecutesplitfilebyfiles' then
    Result := TrText('Split source file into multiple files.')
  else if N = 'dbgfiles' then
    Result := TrText('List of generated files and ranges.')

  { --- Other important controls ------------------------------------------ }
  else if N = 'btnhelp' then
    Result := TrText('Show help and shortcuts.')
  else if Pos('btnclear', N) = 1 then
    Result := TrText('Clear the current input or results.')
  else if ((Pos('filename', N) > 0) or (Pos('file', N) > 0)) and (AControl is TCustomEdit) then
    Result := TrText('Type or choose the file path.')
  else if AControl is TCustomEdit then
    Result := TrText('Type a value here.')
  else if AControl is TCustomComboBox then
    Result := TrText('Choose an option from the list.')
  else if AControl is TCheckBox then
    Result := TrText('Check to enable this option.')
  else if AControl is TCustomListView then
    Result := TrText('List of lines and results.')
  else if AControl is TCustomListBox then
    Result := TrText('List of items.')
  else if AControl is TCustomGrid then
    Result := TrText('Table with results.')
  else if AControl is TTabSheet then
    Result := TrText('Tab content.')
  else if AControl is TLabel then
    Result := TrText('Information label.')
  else if AControl is TButtonControl then
    Result := TrText('Click to execute this action.')
  else if AControl is TPanel then
    Result := TrText('Information panel.');
end;

procedure TfrmMain.sAlphaHints1ShowHint(var HintStr: string; var CanShow: Boolean; var HintInfo: THintInfo; var Frame: TFrame);
var
  FriendlyHint: string;
begin
  if not Assigned(HintInfo.HintControl) then Exit;

  { Apenas para controles pequenos e quando nao ha Hint definido no componente. }
  if (HintInfo.HintControl.Height < 200) and (HintInfo.HintControl.Width < 400)
    and (Trim(HintStr) = '') then
  begin
    FriendlyHint := BuildSimpleComponentHint(HintInfo.HintControl);
    if FriendlyHint <> '' then
    begin
      HintStr := FriendlyHint;
      CanShow := True;
    end
    else
      CanShow := False;
  end;
end;

procedure TfrmMain.sBitBtn1Click(Sender: TObject);
begin
  //About.Close;
end;

procedure TfrmMain.sBitBtn1GetColoring(Sender: TObject; State: Integer; var Coloring: TacColoring);
begin
  Coloring.ColorGlyph := iff(State = 0, slBtnGreenText, slBtnGreenTextActive);
end;

procedure TfrmMain.sSkinManager1BeforeChange(Sender: TObject);
begin
  // Reset colorization
  DataModule1.sSkinManager1.FHueOffset  := 0;
  DataModule1.sSkinManager1.FSaturation := 0;
  DataModule1.sSkinManager1.FBrightness := 0;
end;

procedure TfrmMain.sSkinManager1FontChanged(Sender: TObject; const DefOldFontName, FontName: string);
begin
  sStatusBar1.Panels[4].Text := 'Font ' + Font.Name + '; ' + IntToStr(Font.Size) + 'px';
end;    

function TfrmMain.FormatMillisecondsToDateTime(const ms: integer): string;
var
  dt : TDateTime;
begin
  dt := ms / MSecsPerSec / SecsPerDay;
  result := Format('%s', [FormatDateTime('hh:nn:ss.z', Frac(dt))]);
end;

procedure TfrmMain.About1Click(Sender: TObject);
var
  SD: TSaveDialog;
  MR: Integer;
begin
  frmSplash := TfrmSplash.Create(nil);
  try
    frmSplash.BorderStyle := bsDialog;
    repeat
      MR := frmSplash.ShowModal;
      if MR = mrYes then begin
        Clipboard.AsText := frmSplash.memoLicense.Lines.Text;
        Application.MessageBox(PChar(TrText('Content copied to clipboard.')),
          'FastFile', MB_OK or MB_ICONINFORMATION);
      end else if MR = mrRetry then begin
        SD := TSaveDialog.Create(nil);
        try
          SD.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
          SD.DefaultExt := 'txt';
          SD.FileName := 'FastFile_License.txt';
          if SD.Execute then frmSplash.memoLicense.Lines.SaveToFile(SD.FileName);
        finally
          SD.Free;
        end;
      end;
    until (MR <> mrRetry) and (MR <> mrYes);
  finally
    FreeAndNil(frmSplash);
  end;
end;

procedure TfrmMain.miVersionHistoryClick(Sender: TObject);
const
  HISTORY =
    '======================================================='#13#10 +
    '  FastFile - Version History'#13#10 +
    '======================================================='#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.68  (2026-04-24)  (current)'#13#10 +
      '-------------------------------------------------------'#13#10 +
      '  Compare/Merge UI: Right-click popup rules refined:'#13#10 +
      '    equal (green) rows show Copy selection + Go to line only;'#13#10 +
      '    differing rows show only the appropriate Apply direction;'#13#10 +
      '  Compare/Merge UI: OwnerData fix - popup + custom draw now use'#13#10 +
      '    diff row source (no false-green rows / wrong menu on full-file diff);'#13#10 +
      '  i18n: "There is no difference between the files." accented'#13#10 +
      '    translations restored (11 languages);'#13#10 +
      '  UX: Esc closes the app when pgMain is hidden.'#13#10 +
      ''#13#10 +
      '-------------------------------------------------------'#13#10 +
      '  v2.1.6.67  (2026-04-22)'#13#10 +
      '-------------------------------------------------------'#13#10 +
      '  Apply Merge UI: Context menus with smart row selection;'#13#10 +
      '  Apply Merge UI: Fixed missing/truncated EOF lines bug;'#13#10 +
      '  Apply Merge UI: Fixed double-encoding charset issues;'#13#10 +
      '  Apply Merge UI: Suppressed listview flickering completely;'#13#10 +
      ''#13#10 +
      '-------------------------------------------------------'#13#10 +
      '  v2.1.6.66  (2026-04-20)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Apply Merge UI: Re-engineered O(N) backward flow'#13#10 +
    '    to avoid recursive padding loops & UI freezes;'#13#10 +
    '  Progress UI: Render throttle stops AlphaControls GDI'#13#10 +
    '    exhaustion (MemDC) on transparent overlay;'#13#10 +
    '  Overlay: Alpha-bitmap fix for SmoothLoading logo;'#13#10 +
    '  Safety: File streams release to avoid Sharing Violations.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.65  (2026-04-18)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  APPLICATION_VERSION + CHANGELOG + HISTORY + F1 help:'#13#10 +
    '    two new TrText help lines (11 langs) for session'#13#10 +
    '    history reload (progress phases + multitasking).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.64  (2026-04-18)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  uSmoothLoading: ShowLoading(msg, AStayOnTop); history'#13#10 +
    '    reload uses ShowLoading(..., False) + BringToFront;'#13#10 +
    '  uCompareMergeUI: HistPumpUIMessagesAndYield (PM + MsgWait),'#13#10 +
    '    SyncApply chunks 12/12, worker Sleep in char loops,'#13#10 +
    '    SetSmoothProgress Sleep(2); D7 MsgWait THandle var fix.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.63  (2026-04-18)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Session history reload: progress 0..54% worker (tail,'#13#10 +
    '    filter, preview, color scan) then 55..99% UI apply;'#13#10 +
    '    PostMessage flush throttle; tail progress every 256KB.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.62  (2026-04-16)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  uI18n AddCommonTranslationsCompareMerge: Set11 assigns'#13#10 +
    '    every Compare/Merge dialog TrText key in all 11 langs'#13#10 +
    '    (no English fallback for ES/FR/DE/IT/PL/RO/HU/CZ);'#13#10 +
    '    PT-BR mesclar wording; extras block unchanged; guide'#13#10 +
    '    DOC_COMPARAR_MESCLAR_HISTORICO_PASSO_A_PASSO.md;'#13#10 +
    '  CHANGELOG_IMPLEMENTACOES.md + UnConsts.APPLICATION_VERSION.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.61  (2026-04-15)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Compare/Merge + session history modal (uCompareMergeUI):'#13#10 +
    '    diff + history tabs, lvHistFile journal colors, ctx menus,'#13#10 +
    '    ExecuteModal->RefreshFile, TabSheetDiff/ui fixes; first'#13#10 +
    '    wave of 11-lang strings for preview/context (see .62).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.60  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Host bump: CHANGELOG + UnConsts + HISTORY sync (.58-.59'#13#10 +
    '    deliverables unchanged in entries below).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.59  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Status-bar file details: BuildLoadedFileDetailsText'#13#10 +
    '    (path, disk size, file times, lines/chars/max offset,'#13#10 +
    '    detected + list-view encoding, RO/WW/tail/segmented/'#13#10 +
    '    filter flags, list mode, status read summary);'#13#10 +
    '    ShowDetailsPopup 560x440, Tr(File details), ESC'#13#10 +
    '    (KeyPreview+DetailsPopupKeyDown), OK Default; i18n'#13#10 +
    '    for detail labels + Text copied to clipboard! (11 langs)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.58  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  View menu &View (Alt+V): Word wrap, Select, Zoom in/out'#13#10 +
    '    (Ctrl+Num+/-), bookmarks (from Options); Select removed'#13#10 +
    '    from Options; ListView popup View mirrors menu order;'#13#10 +
    '    Tools: EnsureToolsPopupBookmarkExtras between WW and RO;'#13#10 +
    '    i18n &View + zoom menu/help (11 langs); F1 Alt+V'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.57  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  i18n (11 langs): Line-segmented &mode (heavy ops) menu'#13#10 +
    '    caption; F1 help line Ctrl+Alt+R (read-only);'#13#10 +
    '    FastFile - Version History memo title; Dialogs submenu;'#13#10 +
    '    pt-PT Version History keys; title-bar Tools extra-line'#13#10 +
    '    uses Tr(titlebar.tools)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.56  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Shortcuts: Ctrl+Alt+R = read-only session; Ctrl+R ='#13#10 +
    '    recent files only; Ctrl+W = word wrap (Ctrl alone);'#13#10 +
    '  ListView popup: Tail + Export filtered + read-only icon;'#13#10 +
    '    Tools menu items carry same shortcuts as Options'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.55  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Title-bar Tools (PopupMenu1): dynamic FastFile block'#13#10 +
    '    (word wrap, read-only, segmented, tail, filter, export);'#13#10 +
    '    FMenuBitmapImages on PopupMenu1 + PopupDialogs + icon map;'#13#10 +
    '    segmented mode in Options + list popup + Tools; OnPopup sync'#13#10 +
    '  Removed menu entries: Allow animation, Change BidiMode'#13#10 +
    '    (demo + Tools; Bidi remains on toolbar); FormShow re-sync'#13#10 +
    '    segmented checkbox -> menu checkmarks'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.54  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Line-segmented batch delete (same checkbox as Replace All):'#13#10 +
    '    merge temp + atomic rename; hint updated (i18n)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.53  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Optional line-segmented Replace All (toolbar checkbox,'#13#10 +
    '    INI SegmentHeavyOps): temp parts by index, merge +'#13#10 +
    '    atomic rename; boundary-match caveat in confirm + hint'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.52  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Large-file safety: tail-append reads growth in 64MB'#13#10 +
    '    chunks (GetMem/Read Integer limit); filter bitset'#13#10 +
    '    refuses allocation > MaxInt lines; MMF PtrAt uses'#13#10 +
    '    PAnsiChar pointer math'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.51  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  i18n: Polish/Czech Find–Replace + Duplicate line'#13#10 +
    '    strings corrected (CP1250 letters)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.50  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Options + list popup: Duplicate line (after Insert) +'#13#10 +
    '    Ctrl+Shift+U; i18n menu caption D&uplicate line'#13#10 +
    '  Find & Replace dialog: button mnemonics (Alt+N/R/L/C)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.48–49  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Filter view: prefix / contains / VBScript regex + case Q;'#13#10 +
    '    filter build progress (lines); regex COM CoInit/Uninit on worker'#13#10 +
    '  Find: backward byte progress; Esc cancels in-flight search'#13#10 +
    '  Replace-all: streaming overlay (bytes + replacements); confirm text'#13#10 +
    '  Encoding combo [Save note]; line preview cap 256KB + dual-byte footer'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.47  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Session read-only toggle (Options + list popup):'#13#10 +
    '    guards edit / delete / merge-delta / merge-files /'#13#10 +
    '    split-by-files-lines + replace + undo-redo'#13#10 +
    '  • View encoding combo hint: default vs forced decode note'#13#10 +
    '  • Long line preview: truncation footer with total bytes'#13#10 +
    '  • i18n (11 langs) for new strings'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.46  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • CHANGELOG_IMPLEMENTACOES.md + APPLICATION_VERSION'#13#10 +
    '    (UnConsts) aligned with this in-app Version History'#13#10 +
    '  • i18n (11 langs): help memo rows (Ctrl+Shift+G /'#13#10 +
    '    Filter Ctrl+L / FILTER section note), filter status'#13#10 +
    '    (cleared / filtering / Filter n/N), Ready, line-not-'#13#10 +
    '    in-filter message; PL accelerator on Go to byte offset'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.45  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Filter / Grep: after typing needle, MessageDlg picks'#13#10 +
    '    line-prefix match vs contains-anywhere (view only)'#13#10 +
    '  • TFilterThread: FMatchMode (fmmContains / fmmPrefix);'#13#10 +
    '    StartFilter passes mode from DoFilterDialog'#13#10 +
    '  • gotoLine: Application.MessageBox uses TrText when'#13#10 +
    '    requested real line is absent from active filter'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.44  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Go to byte offset: 1-based file byte (+ $ hex);'#13#10 +
    '    Line0BasedForFileByte1Based binary search on index'#13#10 +
    '  • Edit menu + ListView popup item + Ctrl+Shift+G;'#13#10 +
    '    GetLineStartOffset parameter widened to Int64'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.43  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • About FastFile: Developed by + Hamden Vogel; Contact'#13#10 +
    '    email label (i18n); Build time: TrText; lblDevelopedBy,'#13#10 +
    '    taller pnlTop / pnlGNU layout (UnFormAboutFF)'#13#10 +
    '  • Help (F1): removed trailing Delphi 7 tagline from'#13#10 +
    '    HELP_TEXT; placeholders replaced with TrText rows'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.42  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • i18n: stale-file prompt, find progress, disk/rename/'#13#10 +
    '    replace-all safety messages and UnUtils atomic-save'#13#10 +
    '    errors translated in all 11 application languages'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.41  (2026-04-11)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Read tab: snapshot size+mtime after load; invalidate'#13#10 +
    '    on close streams so external edits are detectable'#13#10 +
    '  • EnsureOpenFileNotStaleForMutate before edit / replace /'#13#10 +
    '    replace-all / merge-delta / undo-redo mutating paths'#13#10 +
    '  • Find in file: status bar shows byte progress'#13#10 +
    '    (Searching ... / total) during TFindInFileThread'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.40  (2026-04-11)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • UnUtils: GetFileSizeAndWriteTime, SameFileSizeAndWriteTime,'#13#10 +
    '    TryRenameTempOverTarget (temp + retries + backup rename),'#13#10 +
    '    VolumeHasMinFreeBytes via kernel32 GetDiskFreeSpaceExA'#13#10 +
    '  • uSmoothLoading: disk free check before heavy writer'#13#10 +
    '    threads; atomic finalize rename; REPLACE_ALL_MATCH_LIMIT'#13#10 +
    '    (5M) with cancel / limit-hit paths; TMergeDeltaThread'#13#10 +
    '    try/except/finally structure fix (D7 compile)'#13#10 +
    '  • RegressionTests: test_snapshot_logic.py + README note'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.39  (2026-04-10)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Split into equal parts - finish UX + i18n:'#13#10 +
    '    Dialogs.ShowMessage summaries (success / failure /'#13#10 +
    '    interrupted) via SplitEqualParts.* Format strings,'#13#10 +
    '    all 11 languages; mmTimer log line (parts + folder)'#13#10 +
    '  • Split-equal modal: larger client height, hint label'#13#10 +
    '    with WordWrap + fixed height + left alignment'#13#10 +
    '  • Menu accelerators PT/ES/PT-PT/RO: &iguais / &iguales /'#13#10 +
    '    &egale (fixes duplicate leading i in captions)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.38  (2026-04-10)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Split-equal algorithm: approximate equal byte targets'#13#10 +
    '    snapped to next LF (no trailing half-lines); outputs'#13#10 +
    '    <name>.partNNN<ext> beside source; overwrite guard'#13#10 +
    '  • Pre-checks: empty file, open/share test, CountLinesInFile'#13#10 +
    '    >= part count, CloseFileStreams when splitting the'#13#10 +
    '    file currently open in Read tab'#13#10 +
    '  • SpinEdit value -> Integer(SpnParts.Value) (D7 type fix)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.37  (2026-04-10)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • New TSplitEqualPartsThread (`uSmoothLoading`):'#13#10 +
    '    background split with TfrmSmoothLoading progress'#13#10 +
    '  • Options menu + runtime modal (merge-style shell):'#13#10 +
    '    source TsFilenameEdit + parts 2..1000 + i18n labels'#13#10 +
    '  • Initial uI18n keys for dialog, loading text, errors'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.36  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Merge-lines delta modal (`uDeltaEditor`): layout'#13#10 +
    '    uses real button widths so Content never overlaps'#13#10 +
    '    Add/Update; BringToFront after resize/show; wider'#13#10 +
    '    Add/Update + Delete buttons'#13#10 +
    '  • ConsumerAI_LanceDB: large row-spec fetch uses temp'#13#10 +
    '    table + JOIN instead of huge IN(...) lists'#13#10 +
    '  • Bridge merge tokens: SQL fetch cap presets, page'#13#10 +
    '    size presets in pagination, INSERT position 0'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.35  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI_LanceDB query loop: single SELECT/WITH'#13#10 +
    '    without LIMIT prompts for max rows (memory cap)'#13#10 +
    '    with optional full-SELECT DB pagination/export'#13#10 +
    '    when the cap is hit'#13#10 +
    '  • `paginate_results` extended with `sql_derived_select`'#13#10 +
    '    (LIMIT/OFFSET on arbitrary subquery) + COPY export'#13#10 +
    '  • Paginated row text truncated at PAGINATE_MAX_ROW_CHARS'#13#10 +
    '    to protect bridge/terminal buffers'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.34  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI_LanceDB search & replace: COUNT(*) instead'#13#10 +
    '    of loading all matches; preview capped at 10 rows'#13#10 +
    '  • Paginated match view uses DuckDB WHERE + LIMIT/OFFSET'#13#10 +
    '    (`sql_where`) + filtered COPY export'#13#10 +
    '  • `replace_in_table` counts matches via SQL (no giant DF)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.33  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI_LanceDB bridge: interactive pagination'#13#10 +
    '    (`BRIDGE_MERGE_PAGINATE` + optional page-number'#13#10 +
    '    buttons); paginate prompt uses page-size presets'#13#10 +
    '  • Shared helpers `_build_search_where_clause`,'#13#10 +
    '    `export_sql_filtered_to_txt`, doc updates in'#13#10 +
    '    `BRIDGE_DELPHI_INPUT_MAP`'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.32  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI panel cleanup after UI experiments:'#13#10 +
    '    manual input flow kept as the single active path'#13#10 +
    '  • Awaiting-input layout tuned with taller input row'#13#10 +
    '    and stable input/status sizing in Delphi panel'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.31  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Prompt protocol hardening in Delphi bridge:'#13#10 +
    '    empty PROMPT falls back to last valid prompt'#13#10 +
    '  • Bridge transcript/status flow cleaned up and noisy'#13#10 +
    '    diagnostic lines removed from runtime flow'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.30  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI stdout reader now flushes partial'#13#10 +
    '    prompt text without trailing LF via PeekNamedPipe'#13#10 +
    '  • Fixes Python input(...) prompts waiting on stdin'#13#10 +
    '    before Delphi receives prompt metadata'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.29  (2026-04-05)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI_LanceDB bridge input updates:'#13#10 +
    '    BridgeConsole.input now routes through bridge_input'#13#10 +
    '  • Frozen-mode header prompt uses bridge-aware input'#13#10 +
    '    and option extraction improved for quoted tokens'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.28  (2026-04-05)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Delphi prompt pipeline refactor:'#13#10 +
    '    centralized ApplyPromptUI and prompt-state helpers'#13#10 +
    '  • Delphi 7 compatibility hardening for prompt parsing'#13#10 +
    '    and manual ConsumerAI input session handling'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.27  (2026-04-04)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI bridge groundwork in Delphi panel:'#13#10 +
    '    prompt metadata parsing and per-prompt state sync'#13#10 +
    '  • Manual prompt/response workflow prepared for'#13#10 +
    '    bridge-driven interaction inside the AI panel'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.26  (2026-04-04)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • AI panel header overflow fix:'#13#10 +
    '    close/export/clear/restart widths + title label'#13#10 +
    '    prevent overlap on right-aligned controls'#13#10 +
    '  • Send button now toggles by input content via'#13#10 +
    '    OnChange (empty input keeps Send disabled)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.25  (2026-04-03)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI migrated from direct Groq SDK'#13#10 +
    '    calls to AWS Lambda proxy (same session model as'#13#10 +
    '    ConsumerAI.py; no local API key in EXE)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.24  (2026-04-03)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • User-facing branding cleanup:'#13#10 +
    '    startup/status texts cleaned up'#13#10 +
    '  • ConsumerAI_Session_Debug.log writes disabled and'#13#10 +
    '    new i18n keys added for session status strings'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.23  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI onefile Windows hotfix:'#13#10 +
    '    removed PyInstaller --strip after it broke _ssl /'#13#10 +
    '    libssl runtime needed by Groq HTTPS requests'#13#10 +
    '  • Build revalidated with standalone EXE startup and'#13#10 +
    '    argparse help execution after packaging changes'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.22  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ConsumerAI onefile slimming pass:'#13#10 +
    '    pruned nonessential PyInstaller payloads while'#13#10 +
    '    keeping standalone distribution'#13#10 +
    '  • Excluded heavy optional ML/test stacks to cut EXE'#13#10 +
    '    size substantially and kept required pandas/pyarrow'#13#10 +
    '    startup dependencies for frozen mode'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.21  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Split by files thread bugfix: output path now uses'#13#10 +
    '    dedicated FOutputDir (source path no longer reused)'#13#10 +
    '  • Callers updated to pass source file and output dir'#13#10 +
    '    as separate parameters in split workflows'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.20  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Split by lines execution implemented with range'#13#10 +
    '    validation and output file name checks'#13#10 +
    '  • tabSplitFileShow now synchronizes spin limits with'#13#10 +
    '    current indexed line count'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.19  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • I/O micro-optimizations in indexed read paths:'#13#10 +
    '    reduced seek/read calls and lower heap allocations'#13#10 +
    '  • ListView data load path adjusted for faster response'#13#10 +
    '    on large files'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.18  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • New keyboard shortcuts for navigation:'#13#10 +
    '    Ctrl+Home = go top, Ctrl+End = go bottom'#13#10 +
    '  • Updated hints/help text to keep shortcut discoverability'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.17  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Split by files flow integrated in Src build:'#13#10 +
    '    btnExecuteSplitFileByFiles now launches TSplitFileThread'#13#10 +
    '  • Dataset validation and entry mapping added for batch'#13#10 +
    '    split execution'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.16  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • gotoLine visual selection hardening:'#13#10 +
    '    selection mark + ensure visible for virtual ListView'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.15  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Search UX update: btnSearch now executes direct lookup'#13#10 +
    '    from edtSearch text (no InputBox dependency)'#13#10 +
    '  • Enter key in search field now follows search action'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.14  (2026-04-01)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • AI panel i18n polish for Brazilian and European Portuguese'#13#10 +
    '    runtime texts:'#13#10 +
    '    normalized accents in ANSI-safe format (#nnn)'#13#10 +
    '  • Added explicit translation key for Send in all'#13#10 +
    '    supported languages and reapplied at panel show'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.13  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • AI quick action buttons repaint hotfix:'#13#10 +
    '    migrated to TsButton + forced realign/invalidate'#13#10 +
    '    to avoid overlapped captions before hover'#13#10 +
    '  • Transcript right-click popup added:'#13#10 +
    '    Select all / Copy / Export transcript'#13#10 +
    '  • AI panel strings fully localized through TrText'#13#10 +
    '    across all supported runtime languages'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.12  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Hotfix: resolved '#39'Control has no parent window'#39''#13#10 +
    '    by reordering dynamic control parenting sequence'#13#10 +
    '    (Parent assigned before handle-sensitive setup)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.11  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Flicker reduction when showing/hiding AI panel:'#13#10 +
    '    WM_SETREDRAW batching + DisableAlign/EnableAlign'#13#10 +
    '    around ListView/splitter/layout updates'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.10  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • New dynamic AI side panel opened by Consumer AI'#13#10 +
    '    button and split beside ListView using splListview'#13#10 +
    '  • Close button added to hide the panel on demand'#13#10 +
    '  • Select mode checklist now parents to pnlCenter so'#13#10 +
    '    it shares space correctly with the AI side panel'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.9  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Menu icon mapping fine-tuning:'#13#10 +
    '    - About FastFile now uses the same icon as Help'#13#10 +
    '    - Exit now uses Exit.bmp explicitly'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.8  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Menu and popup icons remapped to:'#13#10 +
    '    Images\\ImagesII\\glyphspro\\glyphspro\\16x16\\hot'#13#10 +
    '  • Semantic bind updated for main menu and shared'#13#10 +
    '    ListView/CheckListBox right-click popup'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.7  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Hotfix: invalid image size resolved by normalizing'#13#10 +
    '    loaded BMPs to 16x16 before adding to TImageList'#13#10 +
    '  • StretchBlt-based resize with clFuchsia mask preserved'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.6  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Runtime bitmap menu infrastructure added:'#13#10 +
    '    FMenuBitmapImages + FMenuIconIndexByName'#13#10 +
    '  • Dynamic icon lookup by file name with fallback indices'#13#10 +
    '  • ResolveMenuBitmapDir now searches parent folders and'#13#10 +
    '    supports runtime rebuild on ApplyCurrentLanguage'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.5  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Merge files: line-range copy mode enabled'#13#10 +
    '    (checkbox, From line / To line numeric inputs)'#13#10 +
    '  • 13 validation paths: empty fields, invalid number,'#13#10 +
    '    min value, range order, file not found,'#13#10 +
    '    line count exceeded, rename/replace failures'#13#10 +
    '  • CountLinesInFile() helper for pre-validation'#13#10 +
    '  • TMergeFilesThread extended: FFromLine/FToLine,'#13#10 +
    '    GetSourceLineOffset() skips to range start'#13#10 +
    '  • Full i18n: 19 keys x 11 languages (209 entries)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.4  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • comboViewEncoding added as child inside last'#13#10 +
    '    status bar panel (Notepad++ style)'#13#10 +
    '  • Options: DEFAULT (detected) / UTF-8 / ANSI /'#13#10 +
    '    UTF-16 LE / UTF-16 BE'#13#10 +
    '  • LayoutViewEncodingCombo repositions on resize,'#13#10 +
    '    show, and AlphaSkins skin change'#13#10 +
    '  • HookedStatusBarWndProcForCombo intercepts'#13#10 +
    '    CBN_CLOSEUP for skin compatibility'#13#10 +
    '  • Hint shows detected encoding + current view mode'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.3  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • New unit uTextEncoding.pas: BOM detection +'#13#10 +
    '    statistical heuristic across first 16 KB'#13#10 +
    '  • GetLineContent: UTF-8 to Unicode to CP_ACP'#13#10 +
    '    conversion for correct Delphi 7 ANSI rendering'#13#10 +
    '  • ANSI/Latin-1 fallback for non-UTF-8 files'#13#10 +
    '  • MessageBoxW in line editor for Portuguese diacritics'#13#10 +
    '    in ANSI host'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.2  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • uLineEditor: Yes/No confirmation dialog before'#13#10 +
    '    applying insert / edit / delete operations'#13#10 +
    '  • Dialog describes operation type and target line'#13#10 +
    '  • Default button is No (MB_DEFBUTTON2) to prevent'#13#10 +
    '    accidental line modifications'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.1  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Export fix: IndexFileLineCount (total indexed)'#13#10 +
    '    replaces virtual Items.Count as line limit'#13#10 +
    '  • Index offsets wrapped with Abs() for negative-'#13#10 +
    '    offset segment compatibility'#13#10 +
    '  • Export progress overlay synced to IndexFileLineCount'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.6  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Visual word wrap in Content column (DT_WORDBREAK)'#13#10 +
    '    without file re-index (FastWordWrapAtivo remains False)'#13#10 +
    '  • Row height enlarged via FWordWrapRowImages dummy'#13#10 +
    '    TImageList - no side effects on other columns'#13#10 +
    '  • Search highlight suspended in word-wrap draw mode'#13#10 +
    '    (conflicts with multi-line custom draw avoided)'#13#10 +
    '  • Ctrl+W shortcut toggles word wrap checkbox'#13#10 +
    '  • Ctrl+R: missing MRU path auto-removed from list'#13#10 +
    '    and mru_files.ini with friendly user message'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.9  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • New Merge files workflow (source into destination):'#13#10 +
    '    beginning, after destination line, or end of file'#13#10 +
    '  • Dedicated merge modal with validations, Confirm/Cancel,'#13#10 +
    '    ESC close, source picker, and in-window drag and drop'#13#10 +
    '  • Merge now runs in background thread with smooth loading'#13#10 +
    '    progress and automatic destination reload after finish'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.8  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Hotfix: removed false lock on destination file during'#13#10 +
    '    pre-validation (share mode adjusted)'#13#10 +
    '  • Hotfix: closes internal read streams before merge to'#13#10 +
    '    avoid self-lock from the main screen'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.7  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Hotfix: runtime merge modal now uses CreateNew to avoid'#13#10 +
    '    missing resource/DFM exception'#13#10 +
    '  • Drag and drop isolated to merge modal lifecycle only,'#13#10 +
    '    without impacting existing main-window drag and drop'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.6  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • About FastFile updated to use UnConsts metadata:'#13#10 +
    '    APPLICATION_NAME, APPLICATION_FULLNAME, and'#13#10 +
    '    APPLICATION_DEVELOPER'#13#10 +
    '  • About version line now shows architecture suffix:'#13#10 +
    '    vX.X.X.X  (32-bit/64-bit) based on runtime bitness'#13#10 +
    '  • Contact email added with mailto action and label'#13#10 +
    '    layout alignment fix (no overlap)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.5  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • About modal caption now uses same i18n key as'#13#10 +
    '    toolbar/menu (toolbar.about_fastfile)'#13#10 +
    '  • Splash / More info close button moved from hardcoded'#13#10 +
    '    text to TrText('#39'Close'#39')'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.4  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • ESC shortcut behavior improved: closes active tabs'#13#10 +
    '    (Read File / Find Files) when key is not consumed'#13#10 +
    '    by filter or selection context'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.3  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • AlphaHints fallback changed from technical component'#13#10 +
    '    names to user-friendly guidance text'#13#10 +
    '  • Centralized simple hint builder for generic controls'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.2  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Contextual hint coverage expanded for Read, Find Files,'#13#10 +
    '    and Split File areas'#13#10 +
    '  • Added/adjusted English and Portuguese hint entries for'#13#10 +
    '    controls and actions in these tabs'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.1  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Portuguese (Brazil) text review for accent/terminology consistency'#13#10 +
    '    across i18n entries and hint phrases'#13#10 +
    '  • English wording harmonized for Find/Search related labels'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.5  (2026-03-28)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Language pack updated:'#13#10 +
    '    removed Japanese; added Polish, Portuguese (Portugal),'#13#10 +
    '    Romanian, Hungarian, and Czech'#13#10 +
    '  • UI localization coverage expanded (menus, tabs, controls,'#13#10 +
    '    tabFindFiles, tabSplitByLines, toolbar captions)'#13#10 +
    '  • Runtime hardcoded captions moved to TrText (dialogs,'#13#10 +
    '    progress status, help/title captions, shortcut hints)'#13#10 +
    '  • Startup language now follows Windows default when INI'#13#10 +
    '    language is empty'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.4.3  (2026-03-28)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Romanian/Czech critical captions stabilized for Delphi 7'#13#10 +
    '    ANSI rendering (File/Options/Help and Find Files area)'#13#10 +
    '  • Added missing key mapping for Read toolbar caption'#13#10 +
    '    (btnShowTabReadFile)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.4.2  (2026-03-28)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Exact-key i18n fixes for TrText variants with trailing'#13#10 +
    '    spaces/punctuation (e.g., Shortcut: , Replaced on line )'#13#10 +
    '  • i18n initialization refactored into helper blocks to avoid'#13#10 +
    '    Delphi 7 local constants limits'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.4.1  (2026-03-27)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • French menu caption encoding cleaned up'#13#10 +
    '  • Syntax and char-code literal stabilization in translation'#13#10 +
    '    tables'#13#10 +
    '  • Full translation QA pass across menu/tab/button surfaces'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.4  (2026-03)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Internationalization framework (i18n):'#13#10 +
    '    English and Portuguese (Brazil)'#13#10 +
    '  • Dynamic main menu rebuild on language switch'#13#10 +
    '  • Language preference persisted to INI file'#13#10 +
    '  • Encoding combo: DEFAULT / UTF-8 / ANSI / UTF-16'#13#10 +
    '  • Zoom combo added to status bar'#13#10 +
    '  • Runtime language change without restart'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.3  (2026-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Smooth loading architecture (overlapped I/O thread)'#13#10 +
    '  • Word wrap with smooth horizontal scroll'#13#10 +
    '  • Bookmarks: toggle, next, previous, clear all'#13#10 +
    '  • Go to line dialog (Ctrl+G)'#13#10 +
    '  • Status bar: line / column / encoding panels'#13#10 +
    '  • Column-block selection mode'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.2  (2026-01)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Delta File Editor'#13#10 +
    '  • Export dialog (ranges and individual lines)'#13#10 +
    '  • Find in Files (Ctrl+Shift+F)'#13#10 +
    '  • Merge lines feature (Ctrl+Shift+M)'#13#10 +
    '  • AI Consumer integration'#13#10 +
    '  • Recent files list (Ctrl+R)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.1  (2025-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Find & Replace dialog (Ctrl+H)'#13#10 +
    '  • Insert / Edit / Delete line operations'#13#10 +
    '  • Batch delete with checkbox list (Ctrl+Shift+S)'#13#10 +
    '  • Split Files: by line count and by file size'#13#10 +
    '  • Tail / Follow mode (Ctrl+T)'#13#10 +
    '  • Filter / Grep mode (Ctrl+L)'#13#10 +
    '  • Undo / Redo (Ctrl+Z / Ctrl+Y)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.0  (2025-10)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Memory-Mapped File (MMF) backend for large files'#13#10 +
    '  • Multi-encoding detection: BOM/heuristics,'#13#10 +
    '    UTF-8, ANSI, UTF-16 LE/BE'#13#10 +
    '  • AlphaSkins theming support'#13#10 +
    '  • BidiMode support'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.0.0  (2025-08)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Virtual ListView for files exceeding physical'#13#10 +
    '    memory - O(1) scroll regardless of file size'#13#10 +
    '  • Drag & Drop file opening'#13#10 +
    '  • Line-number gutter'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v1.x  (2024 - 2025)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  • Initial release: FileReadThread component'#13#10 +
    '  • Basic indexed file reading with progress'#13#10 +
    '  • ANSI and basic text file support'#13#10 +
    ''#13#10 +
    '======================================================='#13#10;
var
  F: TForm;
  Memo: TMemo;
  BtnCopy, BtnExport, BtnClose: TButton;
  SD: TSaveDialog;
  MR, BtnW, TotalW, StartX: Integer;
begin
  F := TForm.Create(Self);
  try
    F.Caption := TrText('Version History');
    F.Position := poScreenCenter;
    F.Width := 560;
    F.Height := 520;
    F.BorderStyle := bsDialog;
    F.KeyPreview := True;

    Memo := TMemo.Create(F);
    Memo.Parent := F;
    Memo.Left := 8;
    Memo.Top := 8;
    Memo.Width := F.ClientWidth - 16;
    Memo.Height := F.ClientHeight - 56;
    Memo.Anchors := [akLeft, akTop, akRight, akBottom];
    Memo.ReadOnly := True;
    Memo.ScrollBars := ssBoth;
    Memo.WordWrap := False;
    Memo.Font.Name := 'Courier New';
    Memo.Font.Size := 9;
    Memo.Lines.Text := StringReplace(HISTORY,
      '  FastFile - Version History', '  FastFile - Version History', []);

    BtnW := 120;
    TotalW := BtnW * 3 + 16;
    StartX := (F.ClientWidth - TotalW) div 2;

    BtnCopy := TButton.Create(F);
    BtnCopy.Parent := F;
    BtnCopy.Caption := '&Copy';
    BtnCopy.Width := BtnW;
    BtnCopy.Height := 28;
    BtnCopy.Left := StartX;
    BtnCopy.Top := F.ClientHeight - 40;
    BtnCopy.Anchors := [akBottom];
    BtnCopy.ModalResult := mrYes;

    BtnExport := TButton.Create(F);
    BtnExport.Parent := F;
    BtnExport.Caption := '&Export...';
    BtnExport.Width := BtnW;
    BtnExport.Height := 28;
    BtnExport.Left := StartX + BtnW + 8;
    BtnExport.Top := F.ClientHeight - 40;
    BtnExport.Anchors := [akBottom];
    BtnExport.ModalResult := mrRetry;

    BtnClose := TButton.Create(F);
    BtnClose.Parent := F;
    BtnClose.Caption := TrText('Close');
    BtnClose.Width := BtnW;
    BtnClose.Height := 28;
    BtnClose.Left := StartX + (BtnW + 8) * 2;
    BtnClose.Top := F.ClientHeight - 40;
    BtnClose.Anchors := [akBottom];
    BtnClose.ModalResult := mrOk;
    BtnClose.Default := True;
    BtnClose.Cancel := True;
    F.OnKeyDown := FormHelpKeyDown;

    repeat
      MR := F.ShowModal;
      if MR = mrYes then begin
        Clipboard.AsText := Memo.Text;
        Application.MessageBox(PChar(TrText('Content copied to clipboard.')),
          'FastFile', MB_OK or MB_ICONINFORMATION);
      end else if MR = mrRetry then begin
        SD := TSaveDialog.Create(nil);
        try
          SD.Title := TrText('Version History');
          SD.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
          SD.DefaultExt := 'txt';
          SD.FileName := 'FastFile_VersionHistory.txt';
          if SD.Execute then Memo.Lines.SaveToFile(SD.FileName);
        finally
          SD.Free;
        end;
      end;
    until (MR <> mrRetry) and (MR <> mrYes);
  finally
    FreeAndNil(F);
  end;
end;

procedure TfrmMain.btnShowTabReadFileClick(Sender: TObject);
begin
  ActionReadFile.Execute;
end;

procedure TfrmMain.ActionReadFileExecute(Sender: TObject);
begin
  DoShowPanelReadFile;
end;

procedure TfrmMain.DoShowPanelReadFile;
begin
  ShowTab(tabReadFile);
  edtFileName.SetFocus;
end;

procedure TfrmMain.ActionSelectSkinExecute(Sender: TObject);
begin
  //  Enabled := False; // Form Blackout works if form is not Enabled TsSkinProvider.DisabledBlendValue is not 255
  SelectSkin(DataModule1.sSkinManager1); // Dialog showing
//  Enabled := True;
end;

procedure TfrmMain.DoSelectSkin;
begin
  ActionSelectSkin.Execute;
end;

procedure TfrmMain.mnSelectSkinClick(Sender: TObject);
begin
  DoSelectSkin;
end;

procedure TfrmMain.ActionRandomSkinExecute(Sender: TObject);
begin
  DataModule1.sSkinManager1.SkinName := DataModule1.sSkinManager1.GetRandomSkin;
  DataModule1.sSkinManager1.Active := True;
end;

procedure TfrmMain.DoRandomSkin;
begin
  ActionRandomSkin.Execute;
end;

procedure TfrmMain.btnSplashClick(Sender: TObject);
var
  FAbout: TfrmAboutFF;
  SD: TSaveDialog;
  MR: Integer;
begin
  FAbout := TfrmAboutFF.Create(nil);
  try
    repeat
      MR := FAbout.ShowModal;
      if MR = mrYes then begin
        Clipboard.AsText := FAbout.memoLicense.Lines.Text;
        Application.MessageBox(PChar(TrText('Content copied to clipboard.')),
          'FastFile', MB_OK or MB_ICONINFORMATION);
      end else if MR = mrRetry then begin
        SD := TSaveDialog.Create(nil);
        try
          SD.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
          SD.DefaultExt := 'txt';
          SD.FileName := 'FastFile_About.txt';
          if SD.Execute then FAbout.memoLicense.Lines.SaveToFile(SD.FileName);
        finally
          SD.Free;
        end;
      end;
    until (MR <> mrRetry) and (MR <> mrYes);
  finally
    FreeAndNil(FAbout);
  end;
end;

procedure TfrmMain.mnRandomSkinClick(Sender: TObject);
begin
  DoRandomSkin;
end;

procedure TfrmMain.ActionShowHintsExecute(Sender: TObject);
begin
  if not btnClose.Down then
    ActionHintsDisable.Execute // Enable hints
  else
    ActionHintsSkinned.Execute; // Disable hints
end;

procedure TfrmMain.DoShowHints;
begin
  ActionShowHints.Execute;
end;

procedure TfrmMain.mnShowHintsClick(Sender: TObject);
begin
  DoShowHints;
end;

procedure TfrmMain.ShowTab(const tabSheet: TsTabSheet(*; const showOtherTabs: Boolean = False*));
begin
  { Mantem abas ja abertas; apenas garante visibilidade/foco da nova aba. }
  if (pgMain.PageCount > 0) then
  begin
    tabSheet.TabVisible := True;
    pgMain.ActivePage := tabSheet;
  end;
  pgMain.Visible := True;
  pgMain.Style := tsButtons;
  pgMain.ShowCloseBtns := True;
end;

procedure TfrmMain.HideTabs(const showOtherTabs: Boolean = False);
var
  indexTabToHide: integer;
begin
  if not showOtherTabs then
    pgMain.Visible := False
  else
  begin
    indexTabToHide := pgMain.ActivePageIndex;
    pgMain.Pages[indexTabToHide].TabVisible := False;
  end;
  frmMain.PopupMenu := PopupMenu1;
end;

procedure TfrmMain.btnReturnReadClick(Sender: TObject);
begin
  HideTabs;
end;

{ ThvCriticalSection }

constructor ThvCriticalSection.Create;
begin
  inherited Create;
  fDummy[0] := 0; // keep the compiler from optimizing it away or complaining about it not being used
end;

{ TProgressThread }

constructor TProgressThread.Create(CreateSuspended: Boolean);
begin
  inherited;
  FreeOnTerminate := True;
  FTickEvent := CreateEvent(nil, True, False, nil);
  Synchronize(frmMain.ShowProgress);
  cs := ThvCriticalSection.Create;
end;

destructor TProgressThread.Destroy;
begin
  inherited;
  CloseHandle(FTickEvent);
  cs.Free;
end;

procedure TProgressThread.Execute;
begin
  cs.Enter;
  try
    while not Terminated do
      if WaitForSingleObject(FTickEvent, 100) = WAIT_TIMEOUT then
        Synchronize(frmMain.ShowProgress);
  finally
    cs.Leave;
  end;
end;

procedure TProgressThread.FinishThreadExecution;
begin
  Synchronize(frmMain.HideProgress);
  Terminate;
  SetEvent(FTickEvent);
end;

procedure TfrmMain.ShowProgress;
begin
  with pnlLoading do Visible := True;
  ProgressImages.Tag := (ProgressImages.Tag + 1) mod ProgressImages.Count;
  ProgressImages.GetBitmap(ProgressImages.Tag, ProgressImageFile.Picture.Bitmap);
  ProgressImageFile.Refresh;
end;

procedure TfrmMain.HideProgress;
begin
  pnlLoading.Visible := False;
end;

procedure TfrmMain.setAllCheckBoxes(const bCheckAll: Boolean);
(* var
  i: Integer; *)
begin
 (* if not Assigned(FLineIndexes) then Exit;
  if not Assigned(FCheckedLines) then FCheckedLines := TInt64List.Create;
  if bCheckAll then
  begin
    if Assigned(FCheckedLines) then FreeAndNil(FCheckedLines);
    FCheckedLines := TInt64List.Create;
    for i := 0 to FLineIndexes.Count do
    begin
      FCheckedLines.Add(i);
    end;
  end
  else
  begin
    if Assigned(FCheckedLines) then
    FreeAndNil(FCheckedLines);
  end;
  ListView1.Refresh;
  ListView1.Repaint;   *)
end;

procedure TfrmMain.SetAllCheckBoxesToFalse;
begin
  frmMain.setAllCheckBoxes(False);
end;

procedure TfrmMain.SetAllCheckBoxesToTrue;
begin
  frmMain.setAllCheckBoxes();
end;

function TfrmMain.IndexFileLineCount: Int64;
begin
  Result := totalLines;
end;

function TfrmMain.ListviewIsEmpty: Boolean;
begin
  Result := {(textFile = nil)} (totalLines = 0) and (totalCharacters = 0);
end;

procedure TfrmMain.EmptyObjects;
begin
  (*if Assigned(textFile) then
  begin
    ListView1.OnData := nil;
    //ListView1.Items.Clear;
    ListView1.Refresh;
    FreeAndNil(textFile);
  end;
  //It´s necessary to empty the temp file because we are no longer use it anymore.
  try
    textFile := TGpHugeFileStream.Create(ExtractFilePath(Application.ExeName) + TEMPFILE, accWrite);
  finally
    FreeAndNil(textFile);
  end; *)
  //ListView1.OnData := nil;
  //ListView1.Refresh;
  if Assigned(FCheckedLines) then FreeAndNil(FCheckedLines);
  if Assigned(FFoundLines) then FreeAndNil(FFoundLines);
  isChecked := False;
  isAllChecked := False;
  totalLines := 0;
  totalCharacters := 0;
  bSetBoldFont := False;
  bCancelOperation := False;
  fScrollPos := 0;
  if Assigned(FCheckListBox) then
    FreeAndNil(FCheckListBox);
  FUpdatingViewEncodingCombo := True;
  try
    if Assigned(comboViewEncoding) then
    begin
      comboViewEncoding.ItemIndex := 0;
      comboViewEncoding.Enabled := False;
    end;
  finally
    FUpdatingViewEncodingCombo := False;
  end;
  ScrollBarVerticalScroll(self, scPosition, fScrollPos);
  ScrollBarHorizontal.Position := 0;
  CloseFileStreams;
  ListView1.Refresh;
  UnUtils.TrimAppMemorySize;
  UnUtils.ActionComponent([progressBar, btnEmptyInputFile, pnlFile], acNotVisible);
  UnUtils.ActionComponent([btnClear, btnDeleteLines, btnSplitFiles, btnMergeMultipleLines, btnCheckBoxes, btnExport, btnEditFile], acNotEnabled);
  frmMain.PopupMenu := nil;
  frmMain.goToLineSelected := -1;
  lineNumberTempFile := 0;
  lblFileNameValue.Caption := '';
  lblTotalLinesValue.Caption := '';
  lblTotalCharactersValue.Caption := '';
  lblFileDtCreationValue.Caption := '';
  if clFiles.Active then clFiles.EmptyDataSet else clFiles.CreateDataSet;
  trkFiles.Position := 1;
  pgMain.ActivePage := tabReadFile;
  edtFileName.Clear;
  (* fFileName := '';
  sFileName.Text := '';
  edtSearch.Text := ''; *)
end;

function TfrmMain.LineExists(const aLine: integer): Boolean;
begin
  //Result := textFile.LineExists(aLine);
  Result := aLine <= totalLines;
end;

function TfrmMain.getLineFromOffSet(const _offSet: Int64): string;
var
  Stream: TFileStream;
  Buffer: array of AnsiChar;
  TempStr: string;
  i: integer;
  NxtChar: AnsiChar;
const
  MaxBufferSize = $F000;
begin
  if (fFileName = '') then
  begin
    Result := '';
    Exit;
  end;  

  Stream := TFileStream.Create(fFileName, fmOpenRead or fmShareDenyNone);
  try
    TempStr := '';
    Stream.Position := _offSet;
    if Stream.Position = 1 then Stream.Position := 0;
    
    while (Stream.Position > 2) do
    begin
      if Stream.Read(NxtChar, SizeOf(NxtChar)) = 0 then
      begin
        Result := '';
        Exit;
      end;
      if (NxtChar <> #10) then
        Stream.Position := Stream.Position - 2
      else
        Break;
    end;

    SetLength(Buffer, MaxBufferSize);
    Stream.Read(Buffer[0],MaxBufferSize);

    for i := Low(Buffer) to High(Buffer) do
    begin
      if Buffer[i] = #10 then
        Break;
      TempStr := TempStr + Buffer[i];
    end;

    Result := TempStr;
  finally
    FreeAndNil(Stream);
  end;
end;

{ TCheckBoxThread }

constructor TCheckBoxThread.Create(const CreateSuspended,
  bHeaderCheckboxChecked: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate := True;
  fHeaderCheckboxChecked := bHeaderCheckboxChecked;
end;

destructor TCheckBoxThread.Destroy;
begin
  inherited;
end;

procedure TCheckBoxThread.Execute;
begin
  inherited;
  if (fHeaderCheckboxChecked) then
    Synchronize(frmMain.SetAllCheckBoxesToTrue)
  else
    Synchronize(frmMain.SetAllCheckBoxesToFalse);
end;

procedure TfrmMain.FormMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = 27 then TForm(Sender).Close; //allow to close window by pressing "Esc" shortcut key...
end;

procedure TfrmMain.ScrollBarVerticalChange(Sender: TObject);
begin
  if Assigned(ListView1) and ListView1.Visible and (not isChecked) then
    ListView1.Refresh;
end;

procedure TfrmMain.ScrollBarVerticalScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
var
  MaxOffset, OldOffset: Int64;
  ScrollExtent: Int64;
begin
  { Filtro + ListView: barra vertical externa nao move a lista (desativada em SyncScrollBarsForFilterMode). }
  if FFilterActive and (not isChecked) then
  begin
    if Assigned(ListView1) then
      ListView1.Visible := not isChecked;
    showChecked;
    Exit;
  end;
  ListView1.Visible := not isChecked;
  { Filtro + Select (checklist): Offset e indice na lista filtrada; mesmo esquema de MaxOffset que o ficheiro completo. }
  if FFilterActive and isChecked then
  begin
    ScrollExtent := FFilteredCount;
    if ScrollExtent < 1 then ScrollExtent := 1;
    MaxOffset := ScrollExtent - VisibleItems + 1;
    if MaxOffset < 0 then MaxOffset := 0;
    if Offset > MaxOffset then Offset := MaxOffset;
  end
  else
  begin
    MaxOffset := ItemCount - VisibleItems + 1;
    ScrollExtent := ItemCount;
  end;
  OldOffset := Offset;
  case ScrollCode of
    scLineUp: begin
      if Offset > 0 then
        Offset := Offset - 1;
    end;
    scLineDown: begin
      if Offset < MaxOffset then
        Offset := Offset + 1;
    end;
    scPageUp: begin
      if Offset > VisibleItems then
        Offset := Offset - VisibleItems
      else
        Offset := 0;
    end;
    scPageDown: begin
      if (MaxOffset - Offset) > VisibleItems then
        Offset := Offset + VisibleItems
      else
        Offset := MaxOffset;
    end;
    scPosition, scTrack: begin
      Offset := Trunc((ScrollPos / ScrollBarVertical.Max) * MaxOffset);
      if Offset <> OldOffset then InvalidateLineCache;
      showChecked;
      Exit;
    end;
    scTop: begin
      Offset := 0;
      if Offset <> OldOffset then InvalidateLineCache;
      showChecked;
      Exit;
    end;
    scBottom: begin
      Offset := MaxOffset;
      if Offset <> OldOffset then InvalidateLineCache;
      showChecked;
      Exit;
    end;
    scEndScroll: begin
    end;
  end;
  if Offset <> OldOffset then InvalidateLineCache;
  if ScrollExtent < 1 then ScrollExtent := 1;
  if (Offset > 0) then
    ScrollPos := Trunc((Offset / ScrollExtent) * ScrollBarVertical.Max)
  else
    ScrollPos := 0;
  if Assigned(ListView1) and ListView1.Visible and (not isChecked) then
    ListView1.Refresh;
  showChecked;
end;

procedure TfrmMain.ScrollBarHorizontalChange(Sender: TObject);
begin
  if FFastVisualWordWrap then
  begin
    ScrollBarHorizontal.Position := 0;
    Exit;
  end;
  if Assigned(ListView1) and ListView1.Visible and (not isChecked) then
    ListView1.Refresh
  else if isChecked and Assigned(FCheckListBox) then
    FCheckListBox.Invalidate;
end;

procedure TfrmMain.ScrollBarHorizontalScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  if FFastVisualWordWrap then
  begin
    ScrollPos := 0;
    ScrollBarHorizontal.Position := 0;
    Exit;
  end;
  if Assigned(ListView1) and ListView1.Visible and (not isChecked) then
    ListView1.Refresh
  else if isChecked and Assigned(FCheckListBox) then
    FCheckListBox.Invalidate;
end;

procedure TfrmMain.ListView1Resize(Sender: TObject);
var
  VI, CH, RH: Integer;
const
  MinWrapRows = 4;
begin
  if not Assigned(ListView1) then Exit;
  AdjustListViewColumnsWidth;
  { Com ListView invisivel (modo Select) VisibleRowCount = 0: estimar pela altura do
    control / painel e altura de linha (wrap ou normal) para manter VisibleItems e Items.Count coerentes. }
  if ListView1.Visible and (not isChecked) then
  begin
    VI := ListView1.VisibleRowCount;
    if VI <= 0 then VI := 1;
  end
  else
  begin
    CH := ListView1.ClientHeight;
    if (CH < 20) and Assigned(pnlMain) then
      CH := pnlMain.ClientHeight;
    if CH < 20 then
      CH := 400;
    if FFastVisualWordWrap then
    begin
      if Assigned(FWordWrapRowImages) and (FWordWrapRowImages.Height > 0) then
        RH := FWordWrapRowImages.Height
      else
      begin
        CalculateFontMetrics;
        RH := Max(48, (Abs(FLineHeight) + 2) * MinWrapRows);
      end;
    end
    else
    begin
      CalculateFontMetrics;
      RH := Max(16, Abs(FLineHeight) + 2);
    end;
    if RH <= 0 then
      RH := 18;
    VI := CH div RH;
    if VI < 1 then
      VI := 1;
  end;
  VisibleItems := VI;
  if FFilterActive then
  begin
    if FFilteredCount < 1 then
      ListView1.Items.Count := 0
    else if FFilteredCount > MaxInt then
      ListView1.Items.Count := MaxInt
    else
      ListView1.Items.Count := Integer(FFilteredCount);
  end
  else
    ListView1.Items.Count := VisibleItems;
  InvalidateLineCache;
  { CheckListBox alClient: ao redimensionar, remede alturas com word wrap (largura muda). }
  if isChecked and Assigned(FCheckListBox) and FFastVisualWordWrap then
    FCheckListBox.Invalidate;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  StopConsumerAIProcess;
  DragAcceptFiles(Handle, False);
  mru_location.Free;
  mru_content.Free;
  if Assigned(ListView1) and Assigned(FOldListViewWndProc) then
    ListView1.WindowProc := FOldListViewWndProc;
  if FHookedStatusBarForViewEncoding and Assigned(sStatusBar1) then
  begin
    sStatusBar1.WindowProc := FOldStatusBarWndProcForCombo;
    FHookedStatusBarForViewEncoding := False;
  end;

  // === Cleanup new features ===
  if FTailActive then begin FTailActive := False; tmrTail.Enabled := False; end;
  if Assigned(FFilterThread) then begin TFilterThread(FFilterThread).Terminate; FFilterThread := nil; end;
  if Assigned(FFilterBits) then begin FreeMem(FFilterBits); FFilterBits := nil; end;
  FFilterActive := False;
  SetLength(FFilterJumpTable, 0);
  if Assigned(FFindThread) then begin FFindThread.Terminate; FFindThread := nil; end;
  ClearUndoRedo;
  FreeAndNil(FUndoStack);
  FreeAndNil(FRedoStack);
  FreeAndNil(FZoomWheelHistory);
  if Assigned(FBookmarks) then begin FBookmarks.Clear; FreeAndNil(FBookmarks); end;
  SaveRecentFiles;
  FreeAndNil(FRecentFiles);
  FreeAndNil(FMenuBitmapImages);
  FreeAndNil(FMenuIconIndexByName);

  CloseFileStreams;
end;

procedure TfrmMain.SetChecked(const bChecked: Boolean);
begin
  if (ListviewIsEmpty) then
  begin
    ListView1.Refresh;
    ListView1.Repaint;
  end
  else
  begin
    //It will be used a TChecklistbox instead a TListview.
    //ListView1.Checkboxes := isChecked;
    if not isChecked then
      if Assigned(FCheckedLines) then
        FreeAndNil(FCheckedLines);
    ListView1.Refresh;
    ListView1.Repaint;
  end;
  chCheckedAll.Enabled := bChecked;
end;

procedure TfrmMain.BeginRead;
var
  fSearch: string;
  fileSize: Int64;
begin
  fFileName := edtFileName.Text;
  fileSize := GetFileSize(edtFileName.Text);
  sStatusBar1.Panels[4].Text := 'Cache in disk';    
  sStatusBar1.Panels[4].Text := sStatusBar1.Panels[4].Text  + ' ' + FloatToStr(fileSize) + ' bytes';
  fSearch := edtSearch.Text;
  ActionClear.Execute;
  CloseFileStreams;
  TReadFileThread.Create(False, fFileName);
end;

procedure TfrmMain.EndRead;
begin
  UnUtils.ActionComponent([ListView1, ScrollBarVertical, ScrollBarHorizontal], acVisible);
  UnUtils.ActionComponent([btnRead, btnClear, btnDeleteLines, btnSplitFiles, btnMergeMultipleLines, btnCheckBoxes, btnExport, btnEditFile], acEnabled);
  ItemCount := totalLines;
  //ListView1.Items.Count := ItemCount;
  isChecked := False;
  isAllChecked := False;
  ScrollBarVertical.Position := 0;
  ScrollBarVerticalChange(Self);
  fScrollPos := 0;
  ScrollBarVerticalScroll(self, scPosition, fScrollPos);
  ScrollBarHorizontal.Position := 0;
  ApplySessionReadOnlyUi;
end;

(*procedure TMainForm.ListView1CustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Index: Int64;
  k: integer;
begin
  Index := StrToInt64Def(getNumberValue(Item.Caption), 0);
  if Assigned(FFoundLines) then
  begin
    for k := 0 to FFoundLines.Count - 1 do
      if (Index = FFoundLines.Items[k]) then
        Sender.Canvas.Font.Style := Sender.Canvas.Font.Style + [fsBold];
  end;

  if mainForm.goToLineSelected > -1 then
  begin
    if (mainForm.goToLineSelected = Index) then
      Sender.Canvas.Font.Style := Sender.Canvas.Font.Style + [fsBold];
  end;
end; *)

procedure TfrmMain.DrawCheckMark(const ListViewX: TListView;
  Item: TListItem; Checked: Boolean);
var
  TP1, TP2: TPoint;
  XBias, YBias: Integer;
  OldColor: TColor;
  BiasTop, BiasLeft: Integer;
  Rect1: TRect;
begin
  GetCheckBias(XBias, YBias, BiasTop, BiasLeft);
  OldColor := ListViewX.Canvas.Pen.Color;
  //TP1 := Item.GetPosition;
  TP1 := Point(Item.GetPosition.X, Item.GetPosition.Y - 50);
  if Checked then
    ListViewX.Canvas.Brush.Color := clBlack;
  Rect1.Left := Item.Left - CheckWidth - BiasLeft + 1 + XBias;
  Rect1.Top := Tp1.Y + BiasTop + 1 + YBias;
  Rect1.Right := Item.Left - BiasLeft - 1 + XBias;
  Rect1.Bottom := Tp1.Y + BiasTop + CheckHeight - 1 + YBias;
  ListViewX.Canvas.FillRect(Rect1);
  if Checked then
    ListViewX.Canvas.Brush.Color := clBlue
  else
    ListViewX.Canvas.Brush.Color := clBlack;
  ListViewX.Canvas.FrameRect(Rect1);
  ListViewX.Canvas.FrameRect(Rect(Rect1.Left - 1, Rect1.Top - 1,
    Rect1.Right + 1, Rect1.Bottom + 1));
  if Checked then
  begin
    ListViewX.Canvas.Pen.Color := clLime;
    TP2.X := Item.Left - BiasLeft - 2 + XBias;
    TP2.Y := Tp1.Y + BiasTop + 2 + YBias;
    ListViewX.Canvas.PenPos := TP2;
    ListViewX.Canvas.LineTo(Item.Left - BiasLeft - (CheckWidth div 2) +
      XBias, Tp1.Y + BiasTop + (CheckHeight - 2) + YBias);
    ListViewX.Canvas.LineTo(Item.Left - BiasLeft - (CheckWidth - 2) + XBias,
      Tp1.Y + BiasTop + (CheckHeight div 2) + YBias);
    TP2.X := Item.Left - BiasLeft - 2 - 1 + XBias;
    TP2.Y := Tp1.Y + BiasTop + 2 + YBias;
    ListViewX.Canvas.PenPos := TP2;
    ListViewX.Canvas.LineTo(Item.Left - BiasLeft - (CheckWidth div 2) - 1 + XBias,
      Tp1.Y + BiasTop + (CheckHeight - 2) + YBias);
    ListViewX.Canvas.LineTo(Item.Left - BiasLeft - (CheckWidth - 2) - 1 + XBias,
      Tp1.Y + BiasTop + (CheckHeight div 2) + YBias);
  end;
  ListViewX.Canvas.Brush.Color := ListViewX.Color;
  ListViewX.Canvas.Pen.Color := OldColor;
end;

procedure TfrmMain.GetCheckBias(var XBias, YBias, BiasTop, BiasLeft: Integer);
begin
  XBias := 0;
  YBias := H_64 - CheckHeight;
  BiasTop := CheckBiasTop;
  BiasLeft := CheckBiasLeft;
end;

procedure TfrmMain.ActionCheckBoxesListViewExecute(Sender: TObject);
begin
  showCheckBoxes;
end;

procedure TfrmMain.tbCheckBoxClick(Sender: TObject);
begin
  ActionCheckBoxesListView.Execute;
end;

procedure TfrmMain.tbExportToClipBrdClick(Sender: TObject);
begin
  ActionExportToClipBrd.Execute;
end;

procedure TfrmMain.tbExportToFileClick(Sender: TObject);
begin
  ActionExportToFile.Execute; 
end;

procedure TfrmMain.ActionExportToClipBrdExecute(Sender: TObject);
var
  Line1Based: Integer;
begin
  if ListviewIsEmpty then Exit;
  if isChecked and Assigned(FCheckListBox) and FCheckListBox.Visible then
  begin
      if FHasSelection then
        CopyChecklistVerticalSelectionToClipboard
      else if existsCheckedRows(FCheckedLines) then
      CopyCheckedChecklistLinesToClipboard
    else if (FCheckListBox.ItemIndex >= 0) and
            (FCheckListBox.ItemIndex < FCheckListBox.Items.Count) then
    begin
      Line1Based := Integer(FCheckListBox.Items.Objects[FCheckListBox.ItemIndex]);
      if Line1Based > 0 then
        CopyFileLineToClipboard(Line1Based - 1);
    end;
    Exit;
  end;
  exportToClipBoard;
end;

procedure TfrmMain.ActionExportToFileExecute(Sender: TObject);
begin
  if ListviewIsEmpty then Exit;
  //exportToFile;
end;

function TfrmMain.getDataFromListViewToExport: TInt64List;
begin
  Result := nil;
  try
    if Assigned(FFoundLines) then
    begin
      if (FFoundLines.Count > 0) then
        Result := FFoundLines
      else
      begin
        if Assigned(FCheckedLines) then
          Result := FCheckedLines;
       end;
    end
    else if Assigned(FCheckedLines) then Result := FCheckedLines;
    if Assigned(Result) then Result.SortUp;
  except
    Result := nil;
  end;
end;

procedure TfrmMain.setCheckedLines(const index: Int64);
begin
  if not Assigned(FCheckedLines) then FCheckedLines := TInt64List.Create;
  if FCheckedLines.IndexOf(index) = -1 then
    FCheckedLines.Add(index);
end;

procedure TfrmMain.setUnCheckedLines(const index: Int64);
var
  line: Int64;
begin
  if not Assigned(FCheckedLines) then FCheckedLines := TInt64List.Create;
  line := index;
  if FCheckedLines.IndexOf(line) > -1 then
  begin
    FCheckedLines.Remove(line);
    //ListView1.Refresh;
  end;
end;

procedure TfrmMain.chCheckedAllClick(Sender: TObject);
var
  i: Integer;
  idx: Integer;
begin
  isAllChecked := not isAllChecked;
  if Assigned(FCheckedLines) then FreeAndNil(FCheckedLines);
  if not isChecked then ActionCheckBoxesListView.Execute;
  if Assigned(FCheckListBox) then
  begin
    idx := FCheckListBox.ItemIndex;
    for i := 0 to FCheckListBox.Items.Count - 1 do
      FCheckListBox.Checked[i] := isAllChecked;
    if idx > -1 then
      FCheckListBox.ItemIndex := idx;
    FCheckListBox.SetFocus;
  end;

 (* if ListviewIsEmpty
  then Exit;
  if not Assigned(FCheckedLines) then FCheckedLines := TInt64List.Create;
  if Assigned(FCheckedLines) then FreeAndNil(FCheckedLines);
  FCheckedLines := TInt64List.Create;
  if chCheckedAll.Checked then
  begin
    for i := 0 to FLineIndexes.Count do
    begin
      FCheckedLines.Add(i);
    end;
  end
  else
  begin
    if Assigned(FCheckedLines) then
      FreeAndNil(FCheckedLines);
  end;
  ListView1.Refresh;
  ListView1.Repaint;  *)
end;

procedure TfrmMain.CheckListBox1ClickCheck(Sender: TObject);
var
  itemChecked: Integer;
  I: Integer;
  CurLine1Based: Int64;
  A64, B64, T64: Int64;
  A, B, L: Integer;
  IsNowChecked, ShiftDown: Boolean;
begin
  if not Assigned(FCheckListBox) then Exit;
  if FUpdatingChecklistChecks then Exit;
  if FCheckListBox.ItemIndex < 0 then Exit;

  CurLine1Based := Integer(FCheckListBox.Items.Objects[FCheckListBox.ItemIndex]);
  if CurLine1Based <= 0 then Exit;
  IsNowChecked := FCheckListBox.Checked[FCheckListBox.ItemIndex];
  ShiftDown := GetKeyState(VK_SHIFT) < 0;

  FUpdatingChecklistChecks := True;
  try
    if ShiftDown and (FChecklistAnchorLine > 0) then
    begin
      A64 := FChecklistAnchorLine;
      B64 := CurLine1Based;
      if A64 > B64 then
      begin
        T64 := A64; A64 := B64; B64 := T64;
      end;
      if A64 < 1 then A64 := 1;
      if B64 > High(Integer) then B64 := High(Integer);
      A := Integer(A64);
      B := Integer(B64);
      for L := A to B do
      begin
        if IsNowChecked then
          setCheckedLines(L)
        else
          setUnCheckedLines(L);
      end;
      { Re-sincroniza checks visiveis com o estado global FCheckedLines. }
      for I := 0 to FCheckListBox.Items.Count - 1 do
      begin
        itemChecked := Integer(FCheckListBox.Items.Objects[I]);
        FCheckListBox.Checked[I] := checkedLineExists(itemChecked);
      end;
    end
    else
    begin
      if IsNowChecked then
        setCheckedLines(CurLine1Based)
      else
        setUnCheckedLines(CurLine1Based);
    end;
  finally
    FUpdatingChecklistChecks := False;
  end;

  FChecklistAnchorLine := CurLine1Based;
end;

procedure TfrmMain.CheckListBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  CheckAreaRight: Integer;
begin
  if not Assigned(FCheckListBox) then Exit;
  CheckAreaRight := GetSystemMetrics(SM_CXMENUCHECK) + 8;

  if (Button = mbLeft) and ((ssCtrl in Shift) or (ssAlt in Shift)) and
     (X > CheckAreaRight) then
  begin
    FHasSelection := True;
    FIsDragging := True;
    SetCapture(FCheckListBox.Handle);
    if FCheckListBox.CanFocus then
      FCheckListBox.SetFocus;
    FBlockStartPoint := Point(X, Y);
    FBlockEndPoint := Point(X, Y);
    FCheckListBox.Invalidate;
    Exit;
  end;

  if FHasSelection then
  begin
    FHasSelection := False;
    FIsDragging := False;
    if GetCapture = FCheckListBox.Handle then
      ReleaseCapture;
    FCheckListBox.Invalidate;
  end;
end;

procedure TfrmMain.CheckListBox1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  CX, CY: Integer;
begin
  if FIsDragging and Assigned(FCheckListBox) then
  begin
    { Clamp do ponto de arrasto ao cliente: evita saltos de range quando o cursor sai do controle. }
    CX := X;
    CY := Y;
    if CX < 0 then CX := 0;
    if CY < 0 then CY := 0;
    if CX >= FCheckListBox.ClientWidth then CX := FCheckListBox.ClientWidth - 1;
    if CY >= FCheckListBox.ClientHeight then CY := FCheckListBox.ClientHeight - 1;
    FBlockEndPoint := Point(CX, CY);
    FCheckListBox.Invalidate;
  end;
end;

procedure TfrmMain.CheckListBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  CX, CY: Integer;
begin
  if FIsDragging and Assigned(FCheckListBox) then
  begin
    FIsDragging := False;
    if GetCapture = FCheckListBox.Handle then
      ReleaseCapture;
    { Fecha a selecao usando coordenadas limitadas ao cliente. }
    CX := X;
    CY := Y;
    if CX < 0 then CX := 0;
    if CY < 0 then CY := 0;
    if CX >= FCheckListBox.ClientWidth then CX := FCheckListBox.ClientWidth - 1;
    if CY >= FCheckListBox.ClientHeight then CY := FCheckListBox.ClientHeight - 1;
    FBlockEndPoint := Point(CX, CY);
    FCheckListBox.Invalidate;
  end;
  UpdateInfoPanels;
end;

procedure TfrmMain.showChecked;
var
  i: Integer;
  str: string;
  pageNumber: int64;
  DispIdx: Int64;
begin
  ListView1.Visible := not isChecked;
  { Ao voltar da checklist: primeiro CM_RECREATEWND (altura de linha apos SmallImages:=nil
    com LV oculta), depois ListView1Resize com VisibleRowCount valido. }
  if ListView1.Visible and Assigned(ListView1) then
  begin
    if FDeferredListViewRecreateForRowHeight and (not FFastVisualWordWrap)
      and ListView1.HandleAllocated then
    begin
      ListView1.Perform(WM_SETREDRAW, 0, 0);
      try
        ListView1.Perform(CM_RECREATEWND, 0, 0);
      finally
        ListView1.Perform(WM_SETREDRAW, 1, 0);
      end;
      FDeferredListViewRecreateForRowHeight := False;
    end;
    ListView1Resize(ListView1);
  end;
  if (isChecked) and Assigned(FCheckListBox) then
  begin
    FCheckListBox.OnDrawItem := CheckListBox1DrawItem;
    FCheckListBox.Style := lbOwnerDrawFixed;
    FCheckListBox.OnMeasureItem := nil;
    FCheckListBox.ItemHeight := ListViewVisualRowHeight;
    FCheckListBox.Items.BeginUpdate;
    if FCheckListBox.Items.Count > 0 then
      FCheckListBox.Clear;
    try
      { Mesma logica que ListView1Data: N visivel 1-based = Offset+(j+1); conteudo 0-based = Index-1.
        Antes: i=1..VisibleItems+1 e GetLineContent(Offset+i) deslocava +1 e mostrava uma linha a mais. }
      if (not FFilterActive) and Assigned(FSourceFileStream) then
        EnsureLineCacheForPage;
      for i := 0 to VisibleItems - 1 do
      begin
        if not Assigned(FSourceFileStream) then Break;
        if FFilterActive then
        begin
          pageNumber := FilteredIndexToReal(Offset + Int64(i));
          if pageNumber < 0 then Continue;
          DispIdx := pageNumber + 1;
          str := 'Line: ' + FormatFloat('#,', DispIdx) + '  ' +
            getLineContentsFromLineIndex(DispIdx - 1);
        end
        else
        begin
          DispIdx := Offset + (i + 1);
          str := 'Line: ' + FormatFloat('#,', DispIdx) + '  ' +
            getLineContentsFromLineIndex(DispIdx - 1);
        end;
        FCheckListBox.Items.AddObject(str, TObject(Integer(DispIdx)));
      end;
      if isAllChecked then
      begin
        for i := 0 to FCheckListBox.Items.Count - 1 do
          FCheckListBox.Checked[i] := True;
      end
      else if Assigned(FCheckedLines) then
      begin
        for i := 0 to FCheckListBox.Items.Count - 1 do
        begin
          { Numero 1-based em Objects (alinha com setCheckedLines); evita parse com '* Line:'. }
          pageNumber := Integer(FCheckListBox.Items.Objects[i]);
          if FCheckedLines.IndexOf(pageNumber) > -1 then
            FCheckListBox.Checked[i] := True;
        end;
      end;
      ShowScrollBar(FCheckListBox.Handle, SB_VERT, False);
      //FCheckListBox.Refresh;
    finally
      FCheckListBox.Items.EndUpdate;
    end;
    if FCheckListBox.CanFocus then
      FCheckListBox.SetFocus;
  end;
end;

function TfrmMain.checkedLineExists(const icheckedLine: Int64): Boolean;
begin
  Result := Assigned(FCheckedLines);
  if Result then
    Result := (FCheckedLines.IndexOf(icheckedLine) > -1);
end;

function TfrmMain.isLineChecked(const iLine: Int64): Boolean;
var
  i: Integer;
begin
  Result := False;
  if Assigned(FCheckedLines) then
  begin
    for i := 0 to FCheckedLines.Count - 1 do
    begin
      if (FCheckedLines.Items[i] = iLine) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

procedure TfrmMain.showCheckBoxes;
begin
  if ListviewIsEmpty then Exit;
  if ItemCount <= VisibleItems then Exit;
  isChecked := not isChecked;
  if Assigned(FCheckListBox) then FreeAndNil(FCheckListBox);
  if isChecked then
  begin
    if Assigned(pnlCenter) then
      FCheckListBox := TCheckListBox.Create(pnlCenter)
    else
      FCheckListBox := TCheckListBox.Create(pnlMain);
    if Assigned(pnlCenter) then
      FCheckListBox.Parent := pnlCenter
    else
      FCheckListBox.Parent := pnlMain;
    FCheckListBox.Font.Name := ListView1.Font.Name;
    FCheckListBox.Font.Size := ListView1.Font.Size;
    FCheckListBox.Font.Style := ListView1.Font.Style;
    FCheckListBox.Align := alClient;
    FCheckListBox.OnClickCheck := CheckListBox1ClickCheck;
    FCheckListBox.OnKeyDown := CheckListBox1KeyDown;
    FCheckListBox.OnDblClick := CheckListBox1DblClick;
    FCheckListBox.OnMouseDown := CheckListBox1MouseDown;
    FCheckListBox.OnMouseMove := CheckListBox1MouseMove;
    FCheckListBox.OnMouseUp := CheckListBox1MouseUp;
    FCheckListBox.OnDrawItem := CheckListBox1DrawItem;
    FCheckListBox.PopupMenu := popupmenuListView;
    FCheckListBox.Style := lbOwnerDrawFixed;
    FCheckListBox.OnMeasureItem := nil;
    FCheckListBox.ItemHeight := ListViewVisualRowHeight;
    FCheckListBox.TabStop := True;
    FCheckListBox.Visible := True;
  end;
  showChecked;
  if isChecked and Assigned(FCheckListBox) and FCheckListBox.CanFocus then
    FCheckListBox.SetFocus;
  SyncScrollBarsForFilterMode;
end;

procedure TfrmMain.exportToClipBoard;
var
  F: Tform;
  MSG: Tlabel;
  shape: TShape;
  progressBar: TProgressBar;
  nline : integer;
  totalLinesExport: integer;
  indx: integer;
  iLine: int64;
  strCurrentLine: string;
  fileSize: Int64;
  CheckVar: Boolean;
begin
  memoExportedLines.Clear;

  fileSize := UnUtils.GetFileSize(edtFileName.Text);
  if (fileSize > 400000000) and (isAllChecked) then //more than 50MB
    if MessageDlgCustom('The file contains more than 50MB. It may crash the application. Confirm?', mtConfirmation,
      [mbYes,mbNo],
      ['&Yes, Confirmed.',
      '&No, Abort this operation.'],
      CheckVar, False, nil)//nil = no custom font
      = mrNo then Exit;

  if isAllChecked then
    totalLinesExport := totalLines
  else
  begin
    if (not existsCheckedRows(FCheckedLines)) then
    begin
      if not isChecked then ActionCheckBoxesListView.Execute;
      Exit;
    end;
    totalLinesExport := FCheckedLines.Count - 1;
  end;

  strCurrentLine := '';
  nline := 1;

  F:= TForm.Create(Self);
  try
    try
      F.Position := poScreenCenter;
      F.Width := round(Application.MainForm.Width/5);
      F.Height := round(Application.MainForm.Height/4)-100;
      F.FormStyle   := fsNormal;
      F.BorderStyle := bsDialog;
      shape := TShape.Create(Self);
      shape.Parent := F;
      shape.Align := alClient;
      MSG:=  TLabel.Create(Self);
      MSG.Parent := F;
      MSG.Transparent := true;
      MSG.AutoSize := false;
      MSG.Width := F.Width;//100;
      MSG.Top := MSG.Top + 5;
      MSG.Alignment := Classes.taCenter;
      MSG.Font.Style := [fsBold];
      MSG.Font.Name := 'Tahoma';
      MSG.Font.Size := 10;
      Msg.Caption := TrText('Exporting');

      progressBar := TProgressBar.Create(Self);
      progressBar.Align := alBottom;
      progressBar.Top := MSG.Top + 14;
      progressBar.Height := 30;
      progressBar.parent := F;
      F.Show;
      progressBar.Position := 0;
      progressBar.Max := totalLinesExport;
      Application.ProcessMessages;
      Cursor := crSQLWait;
      if (isAllChecked) then
      begin
        try
          memoExportedLines.Lines.LoadFromFile(edtFileName.Text);
        except on E: Exception do
          UnUtils.MessageBox(TrText('Error'), E.Message);
        end;
      end
      else
      begin
        memoExportedLines.Lines.BeginUpdate;
        try
          for indx := 0 to FCheckedLines.Count - 1 do
          begin
            iLine := FCheckedLines.items[indx];
            if LineExists(iLine) then
            begin
              if (iLine > 0) then
              begin
                strCurrentLine := GetLineContent(iLine);
                memoExportedLines.Lines.Add(strCurrentLine);
                //if not AnsiEndsStr(#13#10, strCurrentLine) then
                //  strCurrentLine := strCurrentLine + #13#10;
                //strLine := strLine + strCurrentLine + #13#10;
                progressBar.Position := nline;
                Application.ProcessMessages;
                Inc(nline);
              end;
            end;
          end;
        finally
          memoExportedLines.Lines.EndUpdate;
        end;  
      end;  
    except on E: Exception do
      UnUtils.MessageBox(TrText('Error'), E.Message);
    end;
    ShowTab(tabExportedLines);
    UnUtils.MessageBox(TrText('Information'), TrText('Content exported to memo.'));
  finally
    Cursor := crDefault;
    F.Close;
    FreeAndNil(F);
  end;
end;

procedure TfrmMain.ToolButton37Click(Sender: TObject);
begin
  with TOpenDialog.Create(Self) do
  begin
    if not Execute then
    begin
      UnUtils.MessageBox(TrText('Information'), INVALIDFILENAME, 'OK');
      Exit;
    end;
    edtFileName.Text := FileName;
    Free;
  end;
end;

procedure TfrmMain.ActionSearchExecute(Sender: TObject);
begin
  if (edtSearch.Text = '') then
  begin
    UnUtils.MessageBox(TrText('Information'), TrText('Please enter a search word.'));
    Exit;
  end;
  if (ListviewIsEmpty) then DoRead;
end;

procedure TfrmMain.sComboEdit1ButtonClick(Sender: TObject);
begin
  UnUtils.MessageBox(TrText('Information'), TrText('It is under development.'));
end;

function TfrmMain.existsCheckedRows(const int64List: TInt64List): Boolean;
begin

  Result := Assigned(int64List);
  if Result then
  begin
    Result := int64List.Count > 0;
    int64List.SortUp;
  end;
  //if not Result then
  //  UnUtils.MessageBox('Information','Please check some rows first.');
end;

procedure TfrmMain.sBitBtn2Click(Sender: TObject);
var
  Check : Boolean;
begin
  Check := False;
  case MessageDlgCustom('It is a information. ', mtInformation,
    [mbOK], ['&Ok'], Check, True)
    of
    mrOk:
      begin
        ShowMessage('mrOk');
      end;  //mrYes (save & close)
  end;  //case
  if Check then
    ShowMessage('Ok, I will not show it again.');
end;

procedure TfrmMain.sBitBtn3Click(Sender: TObject);
var
  text: string;
  search: string;
  resp: integer;
begin
  text := 'Hamden Vogel developer';
  search := 'Vogel';
  resp := UnUtils.Search(search, text);
  ShowMessage('resp: ' + IntToStr(resp));
end;

{ TEdit }

procedure TEdit.CMEnter(var Message: TCMGotFocus);
begin
  inherited;
  Invalidate;
end;

procedure TEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  Invalidate;
end;

procedure TEdit.WMPaint(var Message: TWMPaint);
const
  cSearchWordText = 'Search';
var
 _rect: TRect;
 cnv: TCanvas;
begin
  inherited;
  if (not Focused) and (Caption = '') then
  begin
    cnv := TCanvas.Create;
    cnv.Handle := GetDC(Handle);
    try
      _rect := Rect(0, 0, Width, Height);
      cnv.Font := Font;
      cnv.Font.Color := clInactiveCaption;
      cnv.TextRect(_rect, 2, 2, cSearchWordText);
    finally
      ReleaseDC(Handle, cnv.Handle);
      cnv.Free;
    end;
  end;
end;

procedure TfrmMain.edtGoToLineButtonClick(Sender: TObject);
var
  numberLine: int64;
begin
  if ListviewIsEmpty then Exit;
  numberLine := StrToInt64Def(edtGoToLine.Text, 1);
  gotoLine(numberLine - 1);
  //showChecked;
end;

procedure TfrmMain.gotoLine(const iLine: Int64);
var
  TargetVisibleIdx: Integer;
  MaxOff: Int64;
  FIdx: Int64;
begin
  if ItemCount <= 0 then Exit;
  if FFilterActive then
  begin
    FIdx := FilteredIndexForRealLine(iLine);
    if FIdx < 0 then
    begin
      Application.MessageBox(
        PChar(TrText('This line is not in the current filter results.')),
        PChar(TrText('Ir para linha')), MB_OK or MB_ICONINFORMATION);
      Exit;
    end;
    Offset := 0;
    fScrollPos := 0;
    ScrollBarVertical.Position := 0;
    InvalidateLineCache;
    ListView1.Refresh;
    SelectListViewItem(Integer(FIdx));
    { Modo Select: reconstruir checklist e selecionar o item encontrado (FIdx = posicao filtrada). }
    if isChecked and Assigned(FCheckListBox) then
    begin
      showChecked;
      if (Integer(FIdx) >= 0) and (Integer(FIdx) < FCheckListBox.Items.Count) then
        FCheckListBox.ItemIndex := Integer(FIdx);
    end;
    frmMain.goToLineSelected := iLine + 1;
    UpdateInfoPanels;
    Exit;
  end;
  // Directly calculate the ideal Offset to place iLine ~4 rows from top
  if iLine > 4 then
    Offset := iLine - 4
  else
    Offset := 0;
  // Clamp Offset
  MaxOff := ItemCount - VisibleItems;
  if MaxOff < 0 then MaxOff := 0;
  if Offset > MaxOff then Offset := MaxOff;
  // Update scrollbar position
  if ItemCount > 0 then
    fScrollPos := Trunc((Offset / ItemCount) * ScrollBarVertical.Max)
  else
    fScrollPos := 0;
  ScrollBarVertical.Position := fScrollPos;
  InvalidateLineCache;
  ListView1.Refresh;
  // Select the target line
  TargetVisibleIdx := Integer(iLine - Offset);
  if (TargetVisibleIdx >= 0) and (TargetVisibleIdx < ListView1.Items.Count) then
    SelectListViewItem(TargetVisibleIdx)
  else
    SelectListViewItem(-1);
  frmMain.goToLineSelected := iLine + 1;
  UpdateInfoPanels;
  { Modo Select (sem filtro): reconstruir checklist e selecionar linha navegada. }
  if isChecked and Assigned(FCheckListBox) then
  begin
    showChecked;
    if (TargetVisibleIdx >= 0) and (TargetVisibleIdx < FCheckListBox.Items.Count) then
      FCheckListBox.ItemIndex := TargetVisibleIdx;
  end;
end;

function TfrmMain.CheckListBoxWordWrapTextRect(CLB: TCheckListBox;
  const ItemRect: TRect): TRect;
var
  L, CW, MaxR: Integer;
  Rc: TRect;
begin
  { Largura util: GetClientRect e mais fiavel que ClientWidth com skin/alinhamento. }
  if CLB.HandleAllocated and Windows.GetClientRect(CLB.Handle, Rc) then
    CW := Rc.Right - Rc.Left
  else
    CW := CLB.ClientWidth;
  if CW < 24 then
    CW := CLB.Width;
  if (CW < 24) and (CLB.Parent <> nil) then
    CW := CLB.Parent.ClientWidth - 8;
  if CW < 24 then
    CW := 24;
  L := GetSystemMetrics(SM_CXMENUCHECK) + 10;
  MaxR := CW - 6;
  if MaxR <= L then
    MaxR := CW - 1;
  if MaxR <= L then
    MaxR := L + 1;
  Result.Left := L;
  Result.Right := MaxR;
  Result.Top := ItemRect.Top + 2;
  Result.Bottom := ItemRect.Bottom - 2;
  if Result.Bottom <= Result.Top + 4 then
    Result.Bottom := ItemRect.Bottom;
  InflateRect(Result, -2, -2);
end;

procedure TfrmMain.CheckListBox1DrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; DrawState: TOwnerDrawState);
const
  { Evita WrapPlainTextToPixelWidth em linhas gigantes (congela UI no owner-draw). }
  MAX_CHECKLIST_WRAP_DRAW = 2000;
  CHECKBOX_SCALE_PCT = 85;
  CHECKBOX_LEFT_PAD = 2;
  CHECKBOX_TEXT_GAP = 6;
var
  Flags: Longint;
  pageNumber: Int64;
  RealLineIdx: Integer;
  CheckRect: TRect;
  CheckFlags: UINT;
  CheckW, CheckH: Integer;
  SelRect, ItemRect: TRect;
  SegTop, SegBottom, SegLeft, SegRight: Integer;
  S: string;
  R, RC: TRect;
  DrawFlags, CalcFlags: Cardinal;
  Bk, Fg: TColor;
  ItemH, TextH: Integer;
  CLB: TCheckListBox;
  R0: TRect;
begin
  if not (Control is TCheckListBox) then Exit;
  CLB := TCheckListBox(Control);

  CLB.Canvas.Font.Assign(CLB.Font);
  RealLineIdx := -1;
  if Assigned(FCheckListBox) and (Index >= 0) and (Index < FCheckListBox.Items.Count) then
  begin
    pageNumber := Integer(FCheckListBox.Items.Objects[Index]);
    RealLineIdx := Integer(pageNumber) - 1;
    if foundLineExists(RealLineIdx) then
      CLB.Canvas.Font.Style := CLB.Canvas.Font.Style + [fsBold];
  end;

  if odSelected in DrawState then
  begin
    Bk := clHighlight;
    Fg := clHighlightText;
  end
  else
  begin
    if (RealLineIdx >= 0) and IsBookmarked(RealLineIdx) then
      Bk := FF_BOOKMARK_ROW_BG
    else
      Bk := clWindow;
    Fg := clWindowText;
  end;

  CLB.Canvas.Brush.Style := bsSolid;
  CLB.Canvas.Brush.Color := Bk;
  { Preenche a faixa inteira da linha (incl. area do checkbox); o VCL redesenha o checkbox por cima. }
  CLB.Canvas.FillRect(Classes.Rect(0, Rect.Top, CLB.ClientWidth, Rect.Bottom));
  CLB.Canvas.Font.Color := Fg;

  { Em owner-draw, desenhar o checkbox explicitamente para evitar desaparecer ao pintar a linha toda. }
  CheckW := GetSystemMetrics(SM_CXMENUCHECK);
  CheckH := GetSystemMetrics(SM_CYMENUCHECK);
  CheckW := (CheckW * CHECKBOX_SCALE_PCT) div 100;
  CheckH := (CheckH * CHECKBOX_SCALE_PCT) div 100;
  if CheckW < 9 then CheckW := 9;
  if CheckH < 9 then CheckH := 9;
  CheckRect.Left := CHECKBOX_LEFT_PAD;
  CheckRect.Top := Rect.Top + ((Rect.Bottom - Rect.Top - CheckH) div 2);
  if CheckRect.Top < Rect.Top then
    CheckRect.Top := Rect.Top;
  CheckRect.Right := CheckRect.Left + CheckW;
  CheckRect.Bottom := CheckRect.Top + CheckH;

  CheckFlags := DFCS_BUTTONCHECK;
  if CLB.Checked[Index] then
    CheckFlags := CheckFlags or DFCS_CHECKED;
  if not CLB.Enabled then
    CheckFlags := CheckFlags or DFCS_INACTIVE;
  DrawFrameControl(CLB.Canvas.Handle, CheckRect, DFC_BUTTON, CheckFlags);

  if (not (odSelected in DrawState)) and (RealLineIdx >= 0) and IsBookmarked(RealLineIdx) then
  begin
    SegLeft := CheckRect.Right + 2;
    SegRight := SegLeft + 4;
    if SegRight > CLB.ClientWidth - 1 then
      SegRight := CLB.ClientWidth - 1;
    if SegRight > SegLeft then
    begin
      CLB.Canvas.Brush.Color := FF_BOOKMARK_STRIPE;
      CLB.Canvas.Pen.Style := psClear;
      CLB.Canvas.Rectangle(SegLeft, Rect.Top, SegRight, Rect.Bottom);
      CLB.Canvas.Pen.Style := psSolid;
    end;
  end;

  { Garante separacao visual entre checkbox e texto em todos os modos de desenho. }
  if Rect.Left < (CheckRect.Right + CHECKBOX_TEXT_GAP) then
    Rect.Left := CheckRect.Right + CHECKBOX_TEXT_GAP;

  if FFastVisualWordWrap then
  begin
    { Largura = area visivel do cliente (evita uma unica linha logica larga como a coluna 1200 da ListView). }
    R := CheckListBoxWordWrapTextRect(CLB, Rect);
    if R.Right <= R.Left then Exit;
    S := CLB.Items[Index];
    if Length(S) > MAX_CHECKLIST_WRAP_DRAW then
      S := Copy(S, 1, MAX_CHECKLIST_WRAP_DRAW) + '...';
    { DT_WORDBREAK no owner-draw do CheckListBox costuma nao quebrar; quebra manual por TextWidth. }
    S := WrapPlainTextToPixelWidth(CLB.Canvas, S, R.Right - R.Left);
    { Centralizar o bloco de texto na faixa (como DT_VCENTER na linha simples). }
    R0 := R;
    ItemH := R0.Bottom - R0.Top;
    { DT_WORDBREAK ajuda se ainda couber uma linha longa; CRLFs do wrap manual mantem-se. }
    DrawFlags := DT_LEFT or DT_TOP or DT_NOPREFIX or DT_EXPANDTABS or DT_WORDBREAK;
    DrawFlags := Cardinal(DrawTextBiDiModeFlags(Longint(DrawFlags)));
    RC := R0;
    CalcFlags := DrawFlags or DT_CALCRECT;
    Windows.DrawText(CLB.Canvas.Handle, PChar(S), Length(S), RC, CalcFlags);
    TextH := RC.Bottom - RC.Top;
    if TextH <= 0 then TextH := ItemH;
    R := R0;
    if TextH < ItemH then
      Inc(R.Top, (ItemH - TextH) div 2);
    if TextH > ItemH then
      R.Bottom := R0.Bottom
    else
      R.Bottom := R.Top + TextH;
    if R.Bottom > R0.Bottom then
      R.Bottom := R0.Bottom;
    Windows.DrawText(CLB.Canvas.Handle, PChar(S), Length(S), R, DrawFlags);
  end
  else
  begin
    Flags := DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);
    if not CLB.UseRightToLeftAlignment then
      Inc(Rect.Left, 2)
    else
      Dec(Rect.Right, 2);
    CLB.Canvas.Brush.Style := bsSolid;
    DrawText(CLB.Canvas.Handle, PChar(CLB.Items[Index]), Length(CLB.Items[Index]), Rect, Flags);
  end;

  if FHasSelection then
  begin
    SelRect := Classes.Rect(Min(FBlockStartPoint.X, FBlockEndPoint.X),
      Min(FBlockStartPoint.Y, FBlockEndPoint.Y),
      Max(FBlockStartPoint.X, FBlockEndPoint.X),
      Max(FBlockStartPoint.Y, FBlockEndPoint.Y));
    ItemRect := Classes.Rect(0, Rect.Top, CLB.ClientWidth, Rect.Bottom);
    if (SelRect.Right > SelRect.Left) and (SelRect.Bottom > SelRect.Top) and
       (SelRect.Left < ItemRect.Right) and (SelRect.Right > ItemRect.Left) and
       (SelRect.Top < ItemRect.Bottom) and (SelRect.Bottom > ItemRect.Top) then
    begin
      SegLeft := SelRect.Left;
      if SegLeft < ItemRect.Left then SegLeft := ItemRect.Left;
      SegRight := SelRect.Right;
      if SegRight > ItemRect.Right - 1 then SegRight := ItemRect.Right - 1;
      SegTop := SelRect.Top;
      if SegTop < ItemRect.Top then SegTop := ItemRect.Top;
      SegBottom := SelRect.Bottom;
      if SegBottom > ItemRect.Bottom - 1 then SegBottom := ItemRect.Bottom - 1;

      CLB.Canvas.Brush.Style := bsClear;
      CLB.Canvas.Pen.Color   := clHighlight;
      CLB.Canvas.Pen.Style   := psSolid;
      CLB.Canvas.Pen.Width   := 1;
      CLB.Canvas.Rectangle(SegLeft, SegTop, SegRight, SegBottom);
    end;
  end;
end;

(*
var
  k: integer;
begin
  //_Index := StrToInt64Def(getNumberValue(IntToStr(index)), 0);
  if Assigned(FFoundLines) then
  begin
    with (Control as TCheckListBox) do
    begin
      for k := 0 to FFoundLines.Count - 1 do
        if (Index = FFoundLines.Items[k]) then
          Canvas.Font.Style := Canvas.Font.Style + [fsBold];
    end;      
  end;
  *)

function TfrmMain.foundLineExists(const ifoundLine: Int64): Boolean;
begin
  Result := Assigned(FFoundLines);
  if Result then
    Result := (FFoundLines.IndexOf(ifoundLine) > -1);
end;

procedure TfrmMain.R1Click(Sender: TObject);
begin
  DoRandomSkin;
end;

procedure TfrmMain.M1Click(Sender: TObject);
begin
  sMagnifier1.Execute;
end;

procedure TfrmMain.changeBidiMode;
begin
  LockForms(DataModule1.sSkinManager1);
  if Application.BiDiMode = bdLeftToRight then begin
    Application.BiDiMode := bdRightToLeft;
    sSpeedButton10.ImageIndex := 1;
  end
  else begin
    Application.BiDiMode := bdLeftToRight;
    sSpeedButton10.ImageIndex := 0;
  end;
  ChangeControlsLayout(Application.BidiMode);
  DataModule1.sSkinManager1.RepaintForms;
end;

procedure TfrmMain.btnReturnClick(Sender: TObject);
begin
  HideTabs;
end;

procedure TfrmMain.DoRead;
begin
  if (edtFileName.Text = SELECTTEXT) or (edtFileName.Text = EmptyStr) then
  begin
    with TOpenDialog.Create(Self) do
    try
      begin
        if not Execute then
        begin
          //UnUtils.MessageBox('Information', INVALIDFILENAME, 'OK');
          Exit;
        end;
        edtFileName.Text := FileName;
      end;
    finally
      Free;
    end;
  end;
  if not(UnUtils.CheckFile(edtFileName.Text)) then
  begin
    UnUtils.MessageBox(TrText('Information'), INVALIDFILENAME, 'OK');
    Exit;
  end;
  BeginRead;
end;

procedure TfrmMain.addNewContentsFromPositionFileStream(fFileName: string;
  const position: Int64);
var
  fFileNameFirstPart: string;
  id: Integer;
  strmIn: TFileStream;
  strmOut: TFileStream;
  ext: String;
  f: TFileStream;
begin
  id := 1;
  fFileNameFirstPart := ChangeFileExt(fFileName,'.'+Format('%.03d',[id]));
  if not FileExists(fFileNameFirstPart) then Exit;
  strmOut := TFileStream.Create(fFileNameFirstPart,fmOpenReadWrite or fmShareDenyNone);
  try
    strmIn := TFileStream.Create(fFileName, fmOpenRead or fmShareDenyNone);
    try
      strmIn.Seek(position, soFromCurrent);
      strmOut.Seek(strmOut.Size, soFromBeginning);
      strmOut.CopyFrom(strmIn, strmIn.Size - strmIn.Position);
      //FlushFileBuffers(strmOut.Handle);
    finally
      FreeAndNil(strmIn);
    end;
  finally
    FreeAndNil(strmOut);
  end;
  ext := ExtractFileExt(fFileName);

  f := TFileStream.Create(fFileName, fmCreate);
  try
    f.Size:= 0;
  finally
    FreeAndNil(f);
  end;
  while not DeleteFile(fFileName) and not Application.Terminated and FileExists(fFileName) do
    Application.ProcessMessages;
  fFileName := ChangeFileExt(fFileNameFirstPart, ext);
  if not RenameFile(fFileNameFirstPart, fFileName) then RaiseLastWin32Error;
end;

procedure TfrmMain.addNewContentsFromPositionStringStream(const fFileName,
  text: string; const position: Int64);
var
  fFileNameFirstPart: string;
  id: Integer;
  src: TStringStream;
  strmOut: TFileStream;
begin
  id := 1;
  fFileNameFirstPart := ChangeFileExt(fFileName, '.' + Format('%.03d',[id]));
  if not FileExists(fFileNameFirstPart) then Exit;
  strmOut := TFileStream.Create(fFileNameFirstPart,fmOpenReadWrite or fmShareDenyNone);
  try
    src := TStringStream.Create(text);
    try
      strmOut.Seek(position, soFromCurrent);
      strmOut.CopyFrom(src, src.Size);
      //FlushFileBuffers(strmOut.Handle);
    finally
      FreeAndNil(src);
    end;
  finally
    FreeAndNil(strmOut);
  end;
end;

procedure TfrmMain.splitFirstFile(const fFileName: string;
  const position: Int64);
var
  strmIn, strmOut: TFileStream;
  id: Integer;
begin
  strmIn := TFileStream.Create(fFileName,fmOpenRead or fmShareDenyNone);
  try
    id := 1;
    strmOut := TFileStream.Create(ChangeFileExt(fFileName, '.' + Format('%.03d',[id])), fmCreate or fmShareDenyNone);
    try
      strmIn.Seek(0, soFromBeginning);
      strmOut.CopyFrom(strmIn, position);
      //FlushFileBuffers(strmOut.Handle);
    finally
      FreeAndNil(strmOut);
    end;
  finally
    FreeAndNil(strmIn);
  end;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
var
  str: string;
begin
  str := getLineFromOffSet(0);
  Clipboard.AsText := str;
end;

procedure TfrmMain.btnReadClick(Sender: TObject);
begin
  DoRead;
end;

procedure TfrmMain.edtFileNameKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    DoRead;
  end;
end;

procedure TfrmMain.sSpeedButton18Click(Sender: TObject);
const
  showOtherTabs: Boolean = True;
begin
  //ShowTab(tabReadFile);
  HideTabs(showOtherTabs);
end;

procedure TfrmMain.sSpeedButton19Click(Sender: TObject);
begin
  with memoExportedLines do
  begin
    CopyToClipboard;
    SelStart := Perform(EM_LINEINDEX, 0, 0);
    UnUtils.MessageBox(TrText('Information'), TrText('Contents copied to the clipboard. Just paste (CTRL+V).'));
    SelLength := 1;
    SelectAll;
  end;
end;

procedure TfrmMain.edtSearchKeyPress(Sender: TObject; var Key: Char);
begin
  if (key = #13) then btnSearchClick(Self);
end;

procedure TfrmMain.btnSearchClick(Sender: TObject);
var
  SearchText: string;
  StartPos, NextLineStart: Int64;
begin
  SearchText := Trim(edtSearch.Text);
  if SearchText = '' then Exit;
  if ListviewIsEmpty then Exit;

  // Set the search text (like Ctrl+F but without the input dialog)
  FFindText := SearchText;
  FFindCaseSensitive := False;

  // If we already have a previous find result, continue from the next position (like F3)
  if (FLastFoundLine >= 0) and (FLastFoundFilePos > 0) then
  begin
    StartPos := FLastFoundFilePos + 1;
    NextLineStart := GetLineStartOffset(FLastFoundLine + 1);
    if NextLineStart > 0 then
      if (NextLineStart - 1) > StartPos then StartPos := NextLineStart - 1;
    StartFindFromPos(StartPos, +1);
  end
  else
    StartFindFromPos(0, +1);
end;

procedure TfrmMain.btnShowSearchPanelClick(Sender: TObject);
begin
(*  pnlLeftOptions.Visible := not pnlLeftOptions.Visible;
  splLeftOptions.Visible := not splLeftOptions.Visible;
  pnlLeftOptions.Left := pnlLeftPosition;
  splLeftOptions.Left := splLeftPosition;  *)
end;

procedure TfrmMain.btnCheckBoxesClick(Sender: TObject);
begin
  ActionCheckBoxesListView.Execute;
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
begin
  exportFile;
end;

procedure TfrmMain.btnClearClick(Sender: TObject);
begin
  ActionClear.Execute;
end;

procedure TfrmMain.btnDeleteLinesClick(Sender: TObject);
begin
  ActionDelete.Execute;
end;

procedure TfrmMain.ActionDeleteExecute(Sender: TObject);
var
  ToDelete: TInt64List;
  FileName: string;
  FileSz: Int64;
  i, j, N, LineIdx0: Integer;
  Line1Based: Int64;
  StartOff, EndOff, LenDel: Int64;
  SegStart, SegLen: TInt64DynArray;
  ts, tl: Int64;
  DelArr: TInt64DynArray;
  IdxPath: string;
  SegOk: Boolean;
  SegErr: string;

  procedure SortSegDesc(ACount: Integer);
  var
    a, b: Integer;
  begin
    for a := 0 to ACount - 2 do
      for b := a + 1 to ACount - 1 do
        if SegStart[b] > SegStart[a] then
        begin
          ts := SegStart[a];
          SegStart[a] := SegStart[b];
          SegStart[b] := ts;
          tl := SegLen[a];
          SegLen[a] := SegLen[b];
          SegLen[b] := tl;
        end;
  end;

begin
  if ListviewIsEmpty then Exit;
  if not isChecked then
  begin
    showInfoStatus(DELETE_LINES_TIP);
    ActionCheckBoxesListView.Execute;
    Exit;
  end;

  ToDelete := TInt64List.Create;
  try
    if Assigned(FCheckListBox) then
    begin
      for i := 0 to FCheckListBox.Items.Count - 1 do
        if FCheckListBox.Checked[i] then
          ToDelete.Add(Integer(FCheckListBox.Items.Objects[i]));
    end;
    if ToDelete.Count = 0 then
    begin
      if Assigned(FCheckedLines) and (FCheckedLines.Count > 0) then
      begin
        for i := 0 to FCheckedLines.Count - 1 do
          ToDelete.Add(FCheckedLines.Items[i]);
      end;
    end;

    if ToDelete.Count = 0 then
    begin
      ShowMessage('Please check one or more lines first.');
      Exit;
    end;

    if not EnsureWritableSession then Exit;

    ToDelete.SortUp;
    i := 0;
    while i < ToDelete.Count - 1 do
      if ToDelete.Items[i] = ToDelete.Items[i + 1] then
        ToDelete.Delete(i + 1)
      else
        Inc(i);

    if ToDelete.IndexOf(totalLines) > -1 then
    begin
      ShowMessage(LASTLINE_NOT_SUPPORTED);
      Exit;
    end;

    FileName := edtFileName.Text;
    if (FileName = '') or (not FileExists(FileName)) then Exit;

    IdxPath := ExtractFilePath(ParamStr(0)) + 'temp.txt';
    if Assigned(chkSegmentedHeavyOps) and chkSegmentedHeavyOps.Checked then
    begin
      SetLength(DelArr, ToDelete.Count);
      for i := 0 to ToDelete.Count - 1 do
        DelArr[i] := ToDelete.Items[i];
      CloseFileStreams;
      SegOk := TrySegmentedBatchDelete(FileName, IdxPath, DelArr, 250000, SegErr);
      if SegOk then
      begin
        if SegErr <> '' then
          MessageDlg(SegErr, mtError, [mbOK], 0)
        else
          BeginRead;
        Exit;
      end;
      OpenFileStreams(FileName);
    end;

    if not Assigned(FIndexFileStream) or not Assigned(FSourceFileStream) then
      OpenFileStreams(FileName);
    if not Assigned(FIndexFileStream) or not Assigned(FSourceFileStream) then Exit;

    FileSz := FSourceFileStream.Size;
    N := ToDelete.Count;
    SetLength(SegStart, N);
    SetLength(SegLen, N);
    j := 0;
    for i := 0 to N - 1 do
    begin
      Line1Based := ToDelete.Items[i];
      if (Line1Based < 1) or (Line1Based > totalLines) then Continue;
      LineIdx0 := Integer(Line1Based) - 1;
      StartOff := GetLineStartOffset(LineIdx0);
      if StartOff < 0 then Continue;
      StartOff := Abs(StartOff);
      if Int64(LineIdx0) + 1 < totalLines then
      begin
        EndOff := GetLineStartOffset(LineIdx0 + 1);
        if EndOff < 0 then
          EndOff := FileSz + 1
        else
          EndOff := Abs(EndOff);
      end
      else
        EndOff := FileSz + 1;
      LenDel := EndOff - StartOff;
      if LenDel <= 0 then Continue;
      SegStart[j] := StartOff - 1;
      SegLen[j] := LenDel;
      Inc(j);
    end;

    if j = 0 then Exit;

    if j < N then
    begin
      SetLength(SegStart, j);
      SetLength(SegLen, j);
      N := j;
    end;

    SortSegDesc(N);

    CloseFileStreams;
    for i := 0 to N - 1 do
      DeleteFromStream(FileName, SegStart[i], SegLen[i]);

    BeginRead;
  finally
    ToDelete.Free;
  end;
end;

procedure TfrmMain.DeleteFromStream(DestFilename: string; Start,
  Length: Int64);
var
  Buffer: Pointer;
  BufferSize: Integer;
  BytesToRead: Int64;
  BytesRemaining: Int64;
  SourcePos, DestPos: Int64;
  stream: TFileStream;
begin
  stream := TFileStream.Create(DestFilename, fmOpenReadWrite);
  try
    SourcePos := Start+Length;
    DestPos := Start;
    BytesRemaining := Stream.Size-SourcePos;
    BufferSize := Min(BytesRemaining, $F000);
    GetMem(Buffer, BufferSize);
    try
      while BytesRemaining > 0 do begin
        BytesToRead := Min(BufferSize, BytesRemaining);
        Stream.Position := SourcePos;
        Stream.ReadBuffer(Buffer^, BytesToRead);
        Stream.Position := DestPos;
        Stream.WriteBuffer(Buffer^, BytesToRead);
        inc(SourcePos, BytesToRead);
        inc(DestPos, BytesToRead);
        dec(BytesRemaining, BytesToRead);
      end;
      Stream.Size := DestPos;
    finally
      FreeMem(Buffer);
    end;
  finally
    FlushFileBuffers(Stream.Handle);
    FreeAndNil(stream);
  end;
end;

procedure TfrmMain.AboutOpening(Sender: TObject);
begin
  //memoLicense.Color := clBtnFace;
end;

(*procedure TMainForm.ActionDeleteExecute(Sender: TObject);
var
  deleteLineThread: TDeleteLineThread;
begin
  showInfoStatus(DELETE_LINES_TIP);
  if not isChecked then
    ActionCheckBoxesListView.Execute
  else
  begin
    if Assigned(FCheckedLines) then
      if (FCheckedLines.Count > 0) then
      begin
        if (FCheckedLines.IndexOf(totalLines) > -1) then
        begin
          ShowMessage(LASTLINE_NOT_SUPPORTED);
          Exit;
        end;
      deleteLineThread := TDeleteLineThread.Create(False);
    end;
  end;
end; *)

(* Original
procedure TMainForm.ActionDeleteExecute(Sender: TObject);
var
  i: Integer;
  currentLineToDelete, currentOffSet, nextOffSet, lengthToDelete: Int64;
  totalLengthToDelete: Int64;
  sw: TStopWatch;
begin
  if not isChecked then ActionCheckBoxesListView.Execute;
  if Assigned(FCheckedLines) then
  begin
    FCheckedLines.SortUp;
    totalLengthToDelete := 0;
    sw := TStopWatch.Create;
    sw.Start;
    Application.ProcessMessages;
    ShowInfoMemo(STATUS_RUNNING);
    ShowStatus(STATUS_RUNNING);
    lblLoading.Height := 300;
    lblLoading.Font.Size := 14;
    lblLoading.Visible := True;
    lblLoading.BringToFront;
    Application.ProcessMessages;   
    try
      for i := 0 to FCheckedLines.Count - 1 do
      begin
        currentLineToDelete := FCheckedLines.items[i];
        currentOffSet := StrToIntDef(textFile.GetLineContent(currentLineToDelete), 0) - totalLengthToDelete;;
        nextOffSet := getNextCtrlLineFeedPositionFromOffSet(sFileName.Text, currentOffSet);
        lengthToDelete := nextOffSet - currentOffSet;
        totalLengthToDelete := totalLengthToDelete + lengthToDelete;
        DeleteFromStream(sFileName.Text, currentOffSet, lengthToDelete);
        Application.ProcessMessages;
      end;
      sw.stop;
      ShowInfoMemo(Format(TIME_TO_DELETELINES, [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]));
      ShowStatus(STATUS_OK);
      lblLoading.Visible := False;
      lblLoading.Height := 10;
      Application.ProcessMessages;
    finally
      FreeAndNil(sw);
    end;
    DoRead;
  end;
end;
*)

procedure TfrmMain.SetDragAndDropOnSystemsWIthUAC(Wnd: HWND;
  IsEnabled: boolean);
type
  TChangeWindowMessageFilter = function(Msg : Cardinal; Action : Word) : Bool; stdcall;
const
  Msg_Add = 1;
  WM_COPYGLOBALDATA = $49;
var
  DllHandle : THandle;
  ChangeWindowMessageFilter : TChangeWindowMessageFilter;
begin
  DllHandle := LoadLibrary('user32.dll');
  if DllHandle > 0 then
  begin
    ChangeWindowMessageFilter := GetProcAddress(DllHandle, 'ChangeWindowMessageFilter');
    if Assigned(ChangeWindowMessageFilter) then
    begin
      DragAcceptFiles(Wnd, IsEnabled);
      ChangeWindowMessageFilter(WM_DROPFILES, Msg_Add);
      ChangeWindowMessageFilter(WM_COPYGLOBALDATA, Msg_Add);
    end;
  end;
end;

procedure TfrmMain.WMDropFiles(var Msg: TWMDropFiles);
var
    DropH: HDROP;               // drop handle
    DroppedFileCount: Integer;  // number of files dropped
    FileNameLength: Integer;    // length of a dropped file name
    FileName: string;           // a dropped file name
    DropPoint: TPoint;          // point where files dropped
  begin
   inherited;
   // Store drop handle from the message
   DropH := Msg.Drop;
   try
     // Get count of files dropped
     DroppedFileCount := DragQueryFile(DropH, $FFFFFFFF, nil, 0);
     // Get name of each file dropped and process it
     FileNameLength := DragQueryFile(DropH, 0, nil, 0);
     // create string large enough to store file
     SetLength(FileName, FileNameLength);
     // get the file name
     DragQueryFile(DropH, 0, PChar(FileName), FileNameLength + 1);
     ShowTab(tabReadFile);
     //ShowMessage('dropped filename: ' + PChar(FileName));
     edtFileName.Text := PChar(FileName);
     DoRead;
     // Optional: Get point at which files were dropped
     DragQueryPoint(DropH, DropPoint);
     // ... do something with drop point here
   finally
     // Tidy up - release the drop handle
     // don't use DropH again after this
     DragFinish(DropH);
   end;
   // Note we handled message
   Msg.Result := 0;
end;

procedure TfrmMain.CheckListBox1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_DELETE then begin
    ActionDelete.Execute;
    Key := 0;
  end;

  { Navegacao nos limites da janela visivel: rolar Offset como faz a ListView virtual.
    A checklist carrega apenas VisibleItems itens; setas/PgUp/PgDn no limite precisam
    atualizar Offset e reconstruir a janela via showChecked. }
  if Assigned(FCheckListBox) and (Key in [VK_DOWN, VK_UP, VK_NEXT, VK_PRIOR]) then
  begin
    case Key of
      VK_DOWN:
        if FCheckListBox.ItemIndex >= FCheckListBox.Items.Count - 1 then
        begin
          { Seta abaixo no ultimo item visivel: rolar uma linha. }
          fScrollPos := ScrollBarVertical.Position;
          ScrollBarVerticalScroll(ScrollBarVertical, scLineDown, fScrollPos);
          FCheckListBox.ItemIndex := FCheckListBox.Items.Count - 1;
          UpdateInfoPanels;
          Key := 0;
        end;
      VK_UP:
        if FCheckListBox.ItemIndex <= 0 then
        begin
          { Seta acima no primeiro item visivel: rolar uma linha. }
          fScrollPos := ScrollBarVertical.Position;
          ScrollBarVerticalScroll(ScrollBarVertical, scLineUp, fScrollPos);
          FCheckListBox.ItemIndex := 0;
          UpdateInfoPanels;
          Key := 0;
        end;
      VK_NEXT:  { Page Down }
        if FCheckListBox.ItemIndex >= FCheckListBox.Items.Count - 1 then
        begin
          fScrollPos := ScrollBarVertical.Position;
          ScrollBarVerticalScroll(ScrollBarVertical, scPageDown, fScrollPos);
          FCheckListBox.ItemIndex := FCheckListBox.Items.Count - 1;
          UpdateInfoPanels;
          Key := 0;
        end;
      VK_PRIOR:  { Page Up }
        if FCheckListBox.ItemIndex <= 0 then
        begin
          fScrollPos := ScrollBarVertical.Position;
          ScrollBarVerticalScroll(ScrollBarVertical, scPageUp, fScrollPos);
          FCheckListBox.ItemIndex := 0;
          UpdateInfoPanels;
          Key := 0;
        end;
    end;
  end;

  { Todos os atalhos nomeados (Ctrl+X, F-keys etc.) ja sao roteados por
    FormKeyDown via KeyPreview=True — nao duplicar aqui.
    Para teclas de navegacao nao consumidas acima, atualizar os paineis. }
  if Key = 0 then Exit;
  UpdateInfoPanels;
end;

function TfrmMain.getNextCtrlLineFeedPositionFromOffSet(
  const fFileName: string; const _offSet: Int64): Int64;
var
  Stream: TFileStream;
  Buffer: array of AnsiChar;
  TempStr: string;
  i: integer;
  NxtChar: AnsiChar;
  pos: Integer;
const
  MaxBufferSize = $F000;
begin
  if (fFileName = '') then
  begin
    Result := 0;
    Exit;
  end;  
  pos := _offSet;
  Stream := TFileStream.Create(fFileName, fmOpenRead or fmShareDenyNone);
  try
    TempStr := '';
    Stream.Position := _offSet;
    
    while (Stream.Position > 2) do
    begin
      if Stream.Read(NxtChar, SizeOf(NxtChar)) = 0 then
      begin
        Result := pos;
        Exit;
      end;
      if (NxtChar <> #10) then
        Stream.Position := Stream.Position - 2
      else
        Break;
    end;

    SetLength(Buffer, MaxBufferSize);
    Stream.Read(Buffer[0],MaxBufferSize);

    for i := Low(Buffer) to High(Buffer) do
    begin
      if (Buffer[i] = #10) then
        Break;
      TempStr := TempStr + Buffer[i];
      Inc(pos);
    end;

    Result := pos + 1;
  finally
    FreeAndNil(Stream);
  end;
end;

procedure TfrmMain.Button3Click(Sender: TObject);
function GetNextWord(const Str, Find: string): string;
var
  i, k: integer;
  auxStr: string;
begin
  auxStr := Trim(Str);
  i := Pos(Find, Str);
  Result := Trim(Copy(str, i + length(Find), length(str)));
  k := Pos(' ', Result);
  if k > 0 then
    Result := Trim(Copy(Result, 1, k));
end;
(* var
  postLineThread: TPostLineThread; *)
var
  decimalPlaces: string;
  number: string;
  qtdeCasasDecimais: Integer;
begin
(*   postLineThread := TPostLineThread.Create(False);
  lblLoading.Height := 300;
  lblLoading.Font.Size := 14;
  lblLoading.Visible := True;
  lblLoading.BringToFront;
  Application.ProcessMessages; *)
  number := '0,00443765783338123';
  decimalPlaces := GetNextWord(number, ',');
  ShowMessage(decimalPlaces);
  qtdeCasasDecimais := length(decimalPlaces);
  ShowMessage(IntToStr(qtdeCasasDecimais));
end;

{ TPostLineThread }
(*
constructor TPostLineThread.Create(const CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate := True;
  sw := TStopWatch.Create;
  sw.Start;
  fProgressThread := TProgressThread.Create(False);
end;

destructor TPostLineThread.Destroy;
begin
  inherited;
  Synchronize(fProgressThread.FinishThreadExecution);
  FreeAndNil(sw);
end;

procedure TPostLineThread.Execute;
const
  TEMPFILE = 'temp2.txt';
var
  currentPos: int64;
begin
  inherited;
  try
    with mainForm do
    begin
      Synchronize(ListViewOnDataNil);
      Synchronize(ShowStatusRunning);
      currentPos := StrToInt64Def(textFile.GetLineContent(numberLine),1); //FLineIndexes.Items[numberLine-1];
      fFileName := edtFileName.Text;
      try
        updateFile(strLineEdit + #13#10, fFileName, currentPos);
      except on E:Exception do
        raise Exception.Create(E.Message);
      end;
      Application.ProcessMessages;
    end;
  finally
    Synchronize(Self.FinishThreadExecution);
  end;
end;

procedure TPostLineThread.FinishThreadExecution;
begin
  sw.Stop;
  mainForm.ShowInfoMemo(Format(TIME_TO_EDITLINES, [TimerResult]));
  mainForm.ShowStatusOK;
  Synchronize(mainForm.BeginRead);
end;

function TPostLineThread.TimerResult: string;
begin
  Result := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
end;
*)

procedure TfrmMain.ListViewOnDataNil;
begin
  ListView1.OnData := nil;
end;

{ TDeleteLineThread }
 (*
constructor TDeleteLineThread.Create(const CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate := True;
  sw := TStopWatch.Create;
  sw.Start;
  fProgressThread := TProgressThread.Create(False);
end;

destructor TDeleteLineThread.Destroy;
begin
  inherited;
  Synchronize(fProgressThread.FinishThreadExecution);
  FreeAndNil(sw);
end;

(*procedure TDeleteLineThread.Execute;
var
  i: Integer;
  currentLineToDelete, currentOffSet, nextOffSet, lengthToDelete: Int64;
  totalLengthToDelete: Int64;
begin
  inherited;
  try
    if Assigned(FCheckedLines) then
    begin
      with mainForm do
      begin
        Synchronize(ListViewOnDataNil);
        Synchronize(ShowStatusRunning);
        FCheckedLines.SortUp;
        totalLengthToDelete := 0;
        Application.ProcessMessages;

        for i := 0 to FCheckedLines.Count - 1 do
        begin
          currentLineToDelete := FCheckedLines.items[i];
          currentOffSet := StrToIntDef(textFileOffsetReader.GetLineContent(currentLineToDelete), 0) - totalLengthToDelete;

          nextOffSet := getNextCtrlLineFeedPositionFromOffSet(edtFileName.Text, currentOffSet);
          lengthToDelete := nextOffSet - currentOffSet;
          totalLengthToDelete := totalLengthToDelete + lengthToDelete;
          DeleteFromStream(edtFileName.Text, currentOffSet, lengthToDelete);
          Application.ProcessMessages;
        end;
      end;
    end;
  finally
    Synchronize(Self.FinishThreadExecution);
  end;
end; *)

(*procedure TDeleteLineThread.FinishThreadExecution;
begin
  sw.Stop;
  mainForm.showInfoStatus(Format(TIME_TO_DELETELINES, [TimerResult]));
  mainForm.lblInfoFileTime.Caption := mainForm.sStatusBar1.Panels[0].Text;
  mainForm.ShowStatusOK;
  Synchronize(mainForm.BeginRead);
end;

function TDeleteLineThread.TimerResult: string;
begin
  Result := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
end; *)

procedure TfrmMain.CheckListBox1DblClick(Sender: TObject);
begin
  // Mesmo comportamento do duplo-clique da ListView: abrir editor de linha padrao.
  editFile;
end;

procedure TfrmMain.showLineEditForm(const AlineEdit: tpLineEdit);
procedure showForm;
var
  pnl: TPanel;
  btnCopy: TButton;
  btnOK: TButton;
begin
  lineEdit := AlineEdit;
  frm := TForm.Create(nil);
  try
    frm.Width := round(Application.MainForm.Width/3);
    frm.Height := round(Application.MainForm.Height/3)-50;
    frm.Top  := round(Application.MainForm.Top/2);
    frm.Left := (Application.MainForm.Left * 2);
    frm.KeyPreview  := True;
    frm.FormStyle   := fsNormal;
    frm.BorderStyle := bsSizeable;
    frm.Position := poScreenCenter;
    frm.Caption := Format('Getting contents from line: %d', [numberLine]);
    memoLineEdit := TMemo.Create(nil);
    try
      memoLineEdit.Parent := frm;
      memoLineEdit.Align  := alClient;
      memoLineEdit.ScrollBars := ssVertical;
      pnl := TPanel.Create(frm);
      try
        pnl.Parent := frm;
        pnl.Left := 0;
        pnl.Top := (frm.Top - 1);
        pnl.Width := frm.Width;
        //pnl.Height := Round(Frm.Top/2);
        pnl.Align := alBottom;
        pnl.TabOrder := 0;
        pnl.Visible := True;
        pnl.Caption := EmptyStr;
        btnCopy := TButton.Create(pnl);
        btnOK := TButton.Create(pnl);
        try
          btnCopy.Parent := pnl;
          btnCopy.Left := 10;
          btnCopy.Top := btnCopy.Top + 5;
          btnCopy.Caption := TrText('Copy');
          btnCopy.Width := 120;
          btnCopy.ModalResult := mrCancel;
          btnOK.Parent := pnl;
          btnOK.Left := 220;
          btnOK.Top := btnCopy.Top;
          btnOK.Caption := TrText('Close');
          btnOK.Width := 120;
          btnOK.ModalResult := mrOk;//mrCancel;
          //frm.OnShow := FormMemoShow;
          frm.OnKeyDown := FormMemoKeyDown;
          btnCopy.OnClick := btnCopyClick;
          frm.ShowModal;
        finally
          FreeAndNil(btnCopy);
          FreeAndNil(btnOK);
        end;
      finally
        FreeAndNil(pnl);
      end;
    finally
      FreeAndNil(memoLineEdit);
    end;
  finally
    FreeAndNil(frm);
  end;
end;
var
  hts: THitTests;
  ListViewCursosPos: TPoint;
  selectedItem: TListItem;
begin
  case AlineEdit of
    tpListViewLineEdit:
    begin
      //get the cursor position related to listview
      ListViewCursosPos := ListView1.ScreenToClient(Mouse.CursorPos);
      //check if a double-click event was fired
      hts := ListView1.GetHitTestInfoAt(ListViewCursosPos.X, ListViewCursosPos.Y);
      //locate that fired item and return its related data
      if hts <= [htOnIcon, htOnItem, htOnLabel, htOnStateIcon] then
      begin
        selectedItem := ListView1.Selected;
        if not Assigned(selectedItem) then Exit;
        numberLine := StrToIntDef(UnUtils.GetStrAfterSubstr(':', selectedItem.Caption), 0);
        if numberLine = 0 then
          numberLine := StrToIntDef(UnUtils.extractText(selectedItem.Caption), 0);
        (* if (numberLine >= lineCounter) then
          ShowMessage(LASTLINE_NOT_SUPPORTED)
        else *)
        showForm;
      end;
    end;
    tpCheckListBoxLineEdit:
    begin
      if not Assigned(FCheckListBox) then Exit;
      numberLine := Integer(FCheckListBox.Items.Objects[FCheckListBox.ItemIndex]);
      (* if (numberLine >= lineCounter) then
        ShowMessage(LASTLINE_NOT_SUPPORTED)
      else *)
      showForm;
    end;
  end;
end;

(* function TMainForm.getTempFileName(const fileName: string): String;
begin
  Result := getTempFilePath(fileName) + ExtractFileExt(fileName);
end;

function TMainForm.getTempFilePath(const fileName: string): String;
var
  tempFileName: string;
begin
  tempFileName := ExtractFilePath(Application.ExeName) + TEMPFILE;
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(tempFileName) +
                         ExtractName(fileName) + TEMP);
end;
*)

procedure TfrmMain.sButton3Click(Sender: TObject);
begin
  case UnUtils.showForm('confirmation','Open file?') of
    mrYes: ShowMessage('mrYes');
    mrNo: ShowMessage('mrNo');
    mrCancel: ShowMessage('mrCancel');
  end;

(* var
  frm: TForm;
  lbl: TLabel;
  lblTemp: TLabel;
  btnYes, btnNo: TButton;
begin
  frm := TForm.Create(nil);
  try
    lbl := TLabel.Create(frm);
    lblTemp := TLabel.Create(frm);
    btnYes := TButton.Create(frm);
    btnNo := TButton.Create(frm);
    frm.BorderStyle := bsDialog;
    frm.Caption := TrText('Confirmation');
    frm.Width := 300;
    frm.Position := poScreenCenter;

    lbl.Parent := frm;
    lbl.Top := 8;
    lbl.Left := 8;
    lbl.Caption := TrText('Open file from parts ?');

    lblTemp.Parent := frm;
    lblTemp.Top := lbl.Top + lbl.Height + 8;
    lblTemp.Left := 8;
    lblTemp.Width := 200;

    btnYes.Parent := frm;
    btnYes.Caption := TrText('Yes');
    btnYes.Default := true;
    btnYes.ModalResult := mrYes;
    btnYes.Top := lblTemp.Top + lblTemp.Height + 8;
    btnYes.Left := lblTemp.Left + lblTemp.Width - btnYes.Width - btnNo.Width;

    btnNo.Parent := frm;
    btnNo.Caption := TrText('No');
    btnNo.Default := true;
    btnNo.ModalResult := mrNo;
    btnNo.Top := lblTemp.Top + lblTemp.Height + 8;
    btnNo.Left := lblTemp.Left + lblTemp.Width - btnYes.Width + 10;

    frm.ClientHeight := btnYes.Top + btnYes.Height + 8;
    frm.ClientWidth := lblTemp.Left + lblTemp.Width + 8;

    case frm.ShowModal of
      mrYes: ShowMessage('frm.ShowModal = mrYes');
      mrNo: ShowMessage('frm.ShowModal = mrNo');
    end;
  finally
    //ShowMessage(IntToStr(frm.ModalResult));
    frm.Free;
  end;
  *)
end;

procedure TfrmMain.btnEmptyInputFileClick(Sender: TObject);
begin
  edtFileName.Clear;
  fFileName := '';
  ActionClear.Execute;
  //loadFileInChunks;
end;

procedure TfrmMain.ActionWriteExecute(Sender: TObject);
begin
  SplitFile(edtFileName.Text);
end;

procedure TfrmMain.sListBox1Click(Sender: TObject);
var
  ii : integer;
  lRect: TRect;
begin
  ii := sListBox1.ItemIndex;
  listBoxIndex := ii;
  if ii = -1 then
  Exit;
  lRect := sListBox1.ItemRect(ii) ;
  ListEdit.Top := lRect.Top + 1;
  ListEdit.Left := lRect.Left + 1;
  ListEdit.Height := (lRect.Bottom - lRect.Top) + 1;
  ListEdit.Text := sListBox1.Items.Strings[ii];
  sListBox1.Selected[ii] := False;
  ListEdit.Visible := True;
  ListEdit.SelectAll;
  ListEdit.SetFocus;
end;

procedure TfrmMain.sListBox1Exit(Sender: TObject);
begin
  ListEdit.Visible := False;
end;

procedure TfrmMain.ListEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    sListBox1.Items.Strings[listBoxIndex] := ListEdit.Text;
    ListEdit.Visible := False;
    Key := #0;
  end;
end;

procedure TfrmMain.MergeFile(const ffilename: String; const silentMode: Boolean = False);
var
  StrmInput, StrmOutput: TFileStream;
  numberFile: Integer;
  NomeEnt, directory: String;
  sw: TStopWatch;
  newFilename: string;
  F: Tform;
  MSG: TLabel;
  shape: TShape;
  progressBar: TProgressBar;
  totalFiles: Integer;
begin
  numberFile:= 1;
  totalFiles := totalMergeFiles(ffilename);

  directory := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName) +
                         ExtractName(ffilename) + TEMP);

  if not DirectoryExists(directory) then
  begin
    ShowMessage(SELECTTEXT_TO_READ_BEFORE);
    Exit;
  end;

  (* if TextDataSet1.Active then
  begin
    TextDataSet1.Close;
    TextDataSet1.FileName := '';
  end; *)

  Application.ProcessMessages;

  F:= TForm.Create(Self);
  try
    F.Position := poScreenCenter;
    F.Width := round(Application.MainForm.Width/5);
    F.Height := round(Application.MainForm.Height/4)-100;
    F.FormStyle   := fsNormal;
    F.BorderStyle := bsDialog;
    shape := TShape.Create(Self);
    shape.Parent := F;
    shape.Align := alClient;
    MSG:=  TLabel.Create(Self);
    MSG.Parent := F;
    MSG.Transparent := true;
    MSG.AutoSize := false;
    MSG.Width := F.Width;//100;
    MSG.Top := MSG.Top + 5;
    MSG.Alignment := Classes.taCenter;
    MSG.Font.Style := [fsBold];
    MSG.Font.Name := 'Tahoma';
    MSG.Font.Size := 10;
    Msg.Caption := TrText('Writing');

    progressBar := TProgressBar.Create(Self);
    progressBar.Align := alBottom;
    progressBar.Top := MSG.Top + 14;
    progressBar.Height := 30;
    progressBar.parent := F;
    F.Show;
    progressBar.Position := 0;
    progressBar.Max := MAX_100_PERCENT;
    Application.ProcessMessages;
    Cursor := crSQLWait;

    sw := TStopWatch.Create;
    try
      sw.Start;
      //newFilename := IncludeTrailingPathDelimiter(ExtractFilePath(ffilename)) + ExtractName(ffilename)+ MERGED + ExtractFileExt(ffilename);
      newFilename := edtFileName.Text;
      StrmOutput := TFileStream.Create(newFilename, fmCreate);
      try
        while (True) and not (bCancelOperation) do
        begin
          NomeEnt := ChangeFileExt(IncludeTrailingPathDelimiter(directory) + ExtractFileName(ffilename), '.' + Format('%.03d',[numberFile]));

          if not FileExists(NomeEnt) then
            break;

          StrmInput := TFileStream.Create(NomeEnt, fmOpenRead or fmShareDenyNone);
          Application.ProcessMessages;
          try
            StrmOutput.Seek(0, soFromEnd);
            StrmOutput.CopyFrom(StrmInput, StrmInput.Size);
            progressBar.Position := Trunc((MAX_100_PERCENT * numberFile)/totalFiles);
            Application.ProcessMessages;
          finally
            FreeAndNil(StrmInput);
            //DeleteFile(NomeEnt);
          end;
          Inc(numberFile);
          Application.ProcessMessages;
        end;
      finally
        FreeAndNil(StrmOutput);
      end;
    finally
      sw.Stop;
      //showInfoStatus(Format('Saved file %s from %d temp files generated.', [ffilename, totalFiles]));
      showInfoStatus(Format(ELAPSEDTIME, [FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]));
      frmMain.lblInfoFileTime.Caption := frmMain.sStatusBar1.Panels[0].Text;
      FreeAndNil(sw);
    end;
  finally
    Cursor := crDefault;
    F.Close;
    FreeAndNil(F);
  end;
  (* if not silentMode then *)
    BeginRead;
  //if not silentMode then
  //  UnUtils.MessageBox('Information', Format('File generated: %s', [newFilename]));
end;

procedure TfrmMain.btnMergeFileClick(Sender: TObject);
begin
  MergeFile(edtFileName.Text);
end;

function TfrmMain.totalMergeFiles(const ffilename: string): Integer;
var
  NomeEnt, directory: String;
  numberFile: Integer;
begin
  Result := 0;
  numberFile := 1;
  directory := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName) +
                         ExtractName(ffilename) + TEMP);
  while (True) do
  begin
    NomeEnt := ChangeFileExt(IncludeTrailingPathDelimiter(directory) + ExtractFileName(ffilename), '.' + Format('%.03d', [numberFile]));
    if not FileExists(NomeEnt) then
      break;
    Inc(Result);  
    Inc(numberFile);
  end;
end;

{ TDBGrid }

procedure TDBGrid.WMVScroll(var Message: TWMVScroll);
(*
var
  i: integer; *)
begin
  if Message.ScrollCode = SB_THUMBTRACK then
    Message.ScrollCode := SB_THUMBPOSITION;

  (*case Message.ScrollCode of
    SB_LINEUP: i := Form1.TextDataSet1.RecNo;
    SB_LINEDOWN: i := Form1.TextDataSet1.RecNo;
    SB_PAGEUP: i := Form1.TextDataSet1.RecNo;
    SB_PAGEDOWN: i := Form1.TextDataSet1.RecNo;
  end; *)

  inherited;

  (*SB_LINEUP: FDataLink.MoveBy(-FDatalink.ActiveRecord - 1);
    SB_LINEDOWN: FDataLink.MoveBy(FDatalink.RecordCount -
    FDatalink.ActiveRecord);
    SB_PAGEUP: FDataLink.MoveBy(-VisibleRowCount);
    SB_PAGEDOWN: FDataLink.MoveBy(VisibleRowCount);*)  
end;

procedure TfrmMain.dbgFileDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
//var
  //R: TRect;
  //numberLine: Integer;
  //line: string;
begin
  (*if Column.Field = mainForm.TextDataSet1.FieldByName('Line') then
  begin
    dbgFile.Canvas.FillRect(Rect);
    if lineNumberTempFile > -1 then
        numberLine := mainForm.TextDataSet1.RecNo + lineNumberTempFile;
    line := Format('Line: %d  %s', [numberLine, mainForm.TextDataSet1.FieldByName('Line').AsString]);
    dbgFile.Canvas.TextOut(Rect.Left+10, Rect.Top+3, line);
  end; *)

  (* R := Rect;
  Dec(R.Bottom, 2);
  if Column.Field = mainForm.TextDataSet1.FieldByName('Line') then
  begin
    if not (gdSelected in State) then
      dbgFile.Canvas.FillRect(Rect)
    else
      dbgFile.Canvas.FillRect(Rect);
      if lineNumberTempFile > -1 then
        numberLine := mainForm.TextDataSet1.RecNo + lineNumberTempFile;
      line := Format('Line: %d  %s', [numberLine, mainForm.TextDataSet1.FieldByName('Line').AsString]);
    {Draw text in the field}
    DrawText(dbgFile.Canvas.Handle,
      PChar(line),
      Length(line), R,
      DT_WORDBREAK);
  end; *)
end;

procedure TfrmMain.showInfoStatus(const status: string);
begin
  sStatusBar1.Panels[0].Text := status;
end;

procedure TfrmMain.SplitFile(const ffilename: String; const silentMode: Boolean = False);
var
  tempFileName: string;
  tempFilePath: string;
  tempFileSplit: string;
  fileName: string;
  fSizeFile: int64;
  fSizePartFile: integer;
  sw: TStopWatch;
  StrmInput, StrmOutput: TFileStream;
  numberFile: Integer;
  totalLinesSplit: Int64;
  strLst: TStringList;
  //lastLine: string;
  //lastLineFromOriginalFileName: string;
  //positionOffset: Int64;
  //arFiles: array of integer;
  //textFileChunk: TGpHugeFileStream;
  textFileChunk: TInt64List;
  tempWriteFileName: string;
  //k: integer;
  chunkFileName: string;
  F: Tform;
  MSG: TLabel;
  shape: TShape;
  progressBar: TProgressBar;
  totalFiles: Integer;
  i: integer;
begin
  fileName := ffilename;
  tempFileName := ExtractFilePath(Application.ExeName) + TEMPFILE;
  (* tempWriteFileName := IncludeTrailingPathDelimiter(ExtractFilePath(tempFileName) +
                         ExtractName(fileName) + TEMP) + ExtractName(fileName) + TEMP + ExtractFileExt(fileName); *)
  tempFilePath := IncludeTrailingPathDelimiter(ExtractFilePath(tempFileName) +
                         ExtractName(fileName) + TEMP);
  tempWriteFileName := IncludeTrailingPathDelimiter(ExtractFilePath(tempFileName)) + ExtractName(fileName) + '-' + TEMPFILE;
  chunkFileName := IncludeTrailingPathDelimiter(ExtractFilePath(tempFileName)) + ExtractName(fileName) + '-' + CHUNKFILE;

  if not FileExists(tempFileName) then
  begin
    ShowMessage(SELECTTEXT_TO_READ_BEFORE);
    Exit;
  end;

  (* F := TFileStream.Create(tempWriteFileName, fmCreate);
    try
      F.Size:= 0;
    finally
      FreeAndNil(F);
    end;  *)

   (* if FileExists(tempWriteFileName) then
    begin
      F := TFileStream.Create(tempWriteFileName, fmCreate);
      try
        F.Size:= 0;
      finally
        FreeAndNil(F);
      end;
      while not DeleteFile(tempWriteFileName) and not Application.Terminated and FileExists(fFileName) do
        Application.ProcessMessages;
    end; *)
    //myShellCopyFile(Self.Handle, tempFileName, tempWriteFileName);
  if DirectoryExists(tempFilePath) then
    UnUtils.DeleteDirectory(tempFilePath);
  CreateDir(PChar(tempFilePath));
  fSizePartFile := SIZEPARTFILE;
  fSizeFile := UnUtils.GetFileSize(fileName);
  totalFiles := Round(fSizeFile/SIZEPARTFILE)+1;
  //ActionClear.Execute;
  numberFile := 1;

  F := TForm.Create(Self);
  try
    F.Position := poScreenCenter;
    F.Width := round(Application.MainForm.Width/5);
    F.Height := round(Application.MainForm.Height/4)-100;
    F.FormStyle   := fsNormal;
    F.BorderStyle := bsDialog;
    shape := TShape.Create(Self);
    shape.Parent := F;
    shape.Align := alClient;
    MSG:=  TLabel.Create(Self);
    MSG.Parent := F;
    MSG.Transparent := true;
    MSG.AutoSize := false;
    MSG.Width := F.Width;//100;
    MSG.Top := MSG.Top + 5;
    MSG.Alignment := Classes.taCenter;
    MSG.Font.Style := [fsBold];
    MSG.Font.Name := 'Tahoma';
    MSG.Font.Size := 10;
    Msg.Caption := TrText('Preparing editing');

    progressBar := TProgressBar.Create(Self);
    progressBar.Align := alBottom;
    progressBar.Top := MSG.Top + 14;
    progressBar.Height := 30;
    progressBar.parent := F;
    F.Show;
    progressBar.Position := 0;
    progressBar.Max := MAX_100_PERCENT;
    Application.ProcessMessages;
    Cursor := crSQLWait;

    sw := TStopWatch.Create;
    try
      sw.Start;
      StrmInput := TFileStream.Create(fileName, fmOpenRead or fmShareDenyNone);
      fSizeFile := StrmInput.Size;
      try
        while (StrmInput.Position < fSizeFile) and not (bCancelOperation) do
        begin
          tempFileSplit := ChangeFileExt(IncludeTrailingPathDelimiter(tempFilePath) + ExtractFileName(fileName), '.' + Format('%.03d', [numberFile]));
          StrmOutput  := TFileStream.Create(tempFileSplit, fmCreate);
          Application.ProcessMessages;
          try
            if fSizeFile - StrmInput.Position < fSizePartFile then
              fSizePartFile := fSizeFile - StrmInput.Position; 
            StrmOutput.CopyFrom(StrmInput, fSizePartFile);
            progressBar.Position := Trunc((MAX_100_PERCENT * numberFile)/totalFiles);
            Application.ProcessMessages;
          finally
            FreeAndNil(StrmOutput);
          end;
          Inc(numberFile);
          Application.ProcessMessages;
        end;
      finally
        FreeAndNil(StrmInput);
      end;

     textFileChunk := TInt64List.Create;
     try
       totalLinesSplit := 0;
       for i := 1 to numberFile - 1 do
       begin
          tempFileSplit := ChangeFileExt(IncludeTrailingPathDelimiter(tempFilePath) + ExtractFileName(fileName), '.' + Format('%.03d', [i]));
          strLst := TStringList.Create;
          try
            strLst.LoadFromFile(tempFileSplit);
            totalLinesSplit := totalLinesSplit + strLst.Count;
            textFileChunk.Add(totalLinesSplit);
          finally
            FreeAndNil(strLst);
          end;
       end;
       textFileChunk.SaveToFile(chunkFileName);
     finally
       FreeAndNil(textFileChunk);
     end;

     (* if not FileExists(fileName) then Exit; //this is not expected to happen!
      totalLinesSplit := 0;
      SetLength(arFiles, 0);
      if Assigned(textFile) then FreeAndNil(textFile);
      try
        textFile := TGpHugeFileStream.Create(fileName, accRead);
        //textFileChunk := TGpHugeFileStream.Create(tempWriteFileName, accWrite);
        textFileChunk := TInt64List.Create;
        for numberFile := 1 to totalParts do
        begin
          tempFileSplit := ChangeFileExt(tempFilePath + '\' + ExtractFileName(fileName), '.' + Format('%.03d', [numberFile]));
          strLst := TStringList.Create;
          try
            strLst.LoadFromFile(tempFileSplit);
            totalLinesSplit := totalLinesSplit + strLst.Count - 1;
            //textFileChunk.WriteLn(IntToStr(totalLinesSplit+1));
            textFileChunk.Add(totalLinesSplit+1);
            lastLine := strLst[strLst.Count - 1];
            lastLineFromOriginalFileName := (Trim(getLineFromOffSet(StrToInt64Def(textFile.GetLineContent(totalLinesSplit+1),1))));
            if (lastLine <> lastLineFromOriginalFileName) then
            begin
              strLst[strLst.Count - 1] := lastLineFromOriginalFileName;
              strLst.SaveToFile(tempFileSplit);
              SetLength(arFiles, length(arFiles)+1);
              arFiles[high(arFiles)] := numberFile;
            end;
          finally
            FreeAndNil(strLst);
          end;
        end;
        if length(arFiles) > 0 then
        begin
          for numberFile := low(arFiles)+1 to high(arFiles) do
          begin
            tempFileSplit := ChangeFileExt(tempFilePath+'\'+ExtractFileName(fileName),'.'+Format('%.03d',[arFiles[numberFile]]));
            strLst := TStringList.Create;
            try
              strLst.LoadFromFile(tempFileSplit);
              strLst.Delete(0);
              strLst.SaveToFile(tempFileSplit);
            finally
              FreeAndNil(strLst);
            end;
          end;
        end;
        textFileChunk.SaveToFile(chunkFileName); *)
       (* textFileChunk.Clear;
        textFileChunk.LoadFromFile(ExtractFilePath(Application.ExeName) + 'textFileChunk.txt');
         for k := 0 to textFileChunk.Count - 1 do
          sListBox1.Items.Add(inttostr(textFileChunk.items[k])); *)
     (* finally
        FreeAndNil(textFile);
        FreeAndNil(textFileChunk);
      end; *)      
    finally
      //SetLength(arFiles, 0);
      sw.Stop;
      //showInfoStatus(Format('Total generated files: %d of file %s', [totalFiles, fileName]));
      showInfoStatus(Format(ELAPSEDTIME, [FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]));
      frmMain.lblInfoFileTime.Caption := frmMain.sStatusBar1.Panels[0].Text;
      FreeAndNil(sw);
    end;
  finally
    Cursor := crDefault;
    F.Close;
    FreeAndNil(F);
  end;
end;

procedure TfrmMain.btnPostLine2Click(Sender: TObject);
begin
end;

(*procedure TMainForm.splitFileByLines(const newTextFileName: string;
  const sourceLine: Int64; targetLine: Int64; const splittedFileName: string = '');
var
  i: Integer;
  newTextFile: TGpHugeFileStream;
  newLine: string;
  F: Tform;
  MSG: TLabel;
  shape: TShape;
  progressBar: TProgressBar;
  sw: TStopWatch;
begin
  if fileIsEmpty then Exit;
  F:= TForm.Create(Self);
  try
    F.Position := poScreenCenter;
    F.Width := round(Application.MainForm.Width/5);
    F.Height := round(Application.MainForm.Height/4)-100;
    F.FormStyle   := fsNormal;
    F.BorderStyle := bsDialog;
    shape := TShape.Create(Self);
    shape.Parent := F;
    shape.Align := alClient;
    MSG:=  TLabel.Create(Self);
    MSG.Parent := F;
    MSG.Transparent := true;
    MSG.AutoSize := false;
    MSG.Width := F.Width;//100;
    MSG.Top := MSG.Top + 20;
    MSG.Alignment := Classes.taCenter;
    MSG.Font.Style := [fsBold];
    MSG.Font.Name := 'Tahoma';
    MSG.Font.Size := 12;
    if (splittedFileName <> '') then
      MSG.Caption := splittedFileName
    else
      Msg.Caption := TrText('Writing');

    progressBar := TProgressBar.Create(Self);
    progressBar.Align := alBottom;
    progressBar.Top := MSG.Top + 14;
    progressBar.Height := 30;
    progressBar.parent := F;
    F.Show;
    progressBar.Position := 0;
    progressBar.Max := MAX_100_PERCENT;
    Application.ProcessMessages;
    Cursor := crSQLWait;
    sw := TStopWatch.Create;
    try
      try
        sw.Start;
        newTextFile := TGpHugeFileStream.Create(newTextFileName, accWrite);
        for i := sourceLine to targetLine do
        begin
          newLine := textFileOffsetReader.getLineFromOffSet(StrToInt64Def(textFileOffsetReader.GetLineContent(i),1));
          newLine := newLine + #10;
          newTextFile.WriteLnWithoutCRLF(newLine);
          progressBar.Position := Trunc((MAX_100_PERCENT * i)/totalLines);
          Application.ProcessMessages;
        end;
      finally
        FreeAndNil(newTextFile);
      end;
      sw.Stop;
      showInfoStatus(Format(ELAPSEDTIME, [FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]));
      mainForm.lblInfoFileTime.Caption := mainForm.sStatusBar1.Panels[0].Text;
    finally
      FreeAndNil(sw);
    end;
  finally
    Cursor := crDefault;
    F.Close;
    FreeAndNil(F);
  end;
  if (splittedFileName = '') then
    UnUtils.MessageBox(TrText('Information'), TrText('File created:') + #13#10 + ExtractFileName(newTextFileName));
end; *)

(*procedure TMainForm.btnExecuteSplitFileByLinesClick(Sender: TObject);
var
  newTextFileName: string;
  sw: TStopWatch;
begin
  newTextFileName := newFileName(edtFileName.Text);
  edtOutputSplitByLineText.Text := newTextFileName;
  if fileIsEmpty then DoRead;
  sw := TStopWatch.Create;
  try
    sw.Start;
    splitFileByLines(newTextFileName, spnFromSplitByLine.Value, spnToSplitByLine.Value);
    sw.Stop;
    showInfoStatus(Format(ELAPSEDTIME, [FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]));
    mainForm.lblInfoFileTime.Caption := mainForm.sStatusBar1.Panels[0].Text;
  finally
    FreeAndNil(sw);
  end;
end;  *)

function TfrmMain.newFileName(const ffileName: String): String;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ffileName)) + ExtractName(ffileName) + '-' + 'copy' + ExtractFileExt(ffileName);
end;

function TfrmMain.fileIsEmpty: Boolean;
begin
  Result := (edtFileName.Text = SELECTTEXT) or (edtFileName.Text = EmptyStr) or not(UnUtils.CheckFile(edtFileName.Text)) or (ListviewIsEmpty);
end;

procedure TfrmMain.trkFilesChange(Sender: TObject);
begin
  lblTrackBarFileValueSplitFile.Caption := IntToStr(trkFiles.Position);
  tableTempFiles(trkFiles.Position);
end;

procedure TfrmMain.tableTempFiles(const totalFiles: Integer);
var
  i: integer;
  totalLinesPerFile: integer;
  lastTargetLine, targetLine: Int64;
begin
  if fileIsEmpty then Exit;
  if clFiles.Active then clFiles.EmptyDataSet else clFiles.CreateDataSet;
  totalLinesPerFile := Round(totalLines/totalFiles);
  lastTargetLine := 0;
  targetLine := 0;
  with clFiles do
  begin
    for i := 1 to totalFiles do
    begin
      if targetLine > totalLines then Break;
      Append;
      FieldByName('ID').AsInteger := i;
      FieldByName('FileName').AsString := Format('%s.%.03d-copy%s', [ExtractName(edtFileName.Text), i, ExtractFileExt(edtFileName.Text)]);
      case i of
        1: begin
             FieldByName('SourceLine').AsString := IntToStr(i);
             targetLine := totalLinesPerFile;
             FieldByName('TargetLine').AsString := IntToStr(targetLine);
           end;
        else
          begin
            FieldByName('SourceLine').AsString := IntToStr(lastTargetLine);
            targetLine := lastTargetLine + totalLinesPerFile;
            if i < totalFiles then
              FieldByName('TargetLine').AsString := IntToStr(targetLine)
            else
              FieldByName('TargetLine').AsString := IntToStr(totalLines);
          end;
      end; //end case
      lastTargetLine := targetLine + 1;
    end; //end for i := 1 to totalFiles do  
    if (State in [dsInsert, dsEdit]) then
    begin
      Post;
      First;
    end;
  end; //end with clFiles do  
end;

procedure TfrmMain.dbgFilesKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (shift = [ssCtrl]) and (key in [VK_DELETE]) then Abort;
end;

(*rocedure TMainForm.btnExecuteSplitFileByFilesClick(Sender: TObject);
const
  MESSAGE_FILENAME = 'Writing %d of %d';
var
  ffileName: string;
  sourceLine, targetLine: Int64;
  id: integer;
  sw: TStopWatch;
begin
  if fileIsEmpty then DoRead;
  ffileName := '';
  sourceLine := 0;
  targetLine := 0;
  sw := TStopWatch.Create;
  try
    sw.Start;
    with clFiles do
    begin
      if not Active then Exit;
      if IsEmpty then Exit;
      First;
      while not Eof do
      begin
        id := FieldByName('ID').AsInteger;
        ffileName := FieldByName('Filename').AsString;
        sourceLine := FieldByName('SourceLine').AsInteger;
        targetLine := FieldByName('TargetLine').AsInteger;
        splitFileByLines(ffileName, sourceLine, targetLine, Format(MESSAGE_FILENAME, [id, trkFiles.Position]));
        Application.ProcessMessages;
        Next;
      end; //end while not Eof do
    end; //end with clFiles do
    sw.Stop;
    showInfoStatus(Format(ELAPSEDTIME, [FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]));
    mainForm.lblInfoFileTime.Caption := mainForm.sStatusBar1.Panels[0].Text;
  finally
    FreeAndNil(sw);
  end;
  if not clFiles.IsEmpty then
    UnUtils.MessageBox(TrText('Information'), TrText('files generated successfully.'));
end; *)

procedure TfrmMain.SelectListViewItem(const Idx: Integer);
begin
  // Clear all previous selections (required when MultiSelect = True)
  ListView_SetItemState(ListView1.Handle, -1, 0, LVIS_SELECTED or LVIS_FOCUSED);
  if (Idx >= 0) and (Idx < ListView1.Items.Count) then
  begin
    ListView1.ItemIndex := Idx;
    ListView_SetItemState(ListView1.Handle, Idx, LVIS_SELECTED or LVIS_FOCUSED, LVIS_SELECTED or LVIS_FOCUSED);
    ListView_EnsureVisible(ListView1.Handle, Idx, False);
  end;
end;

procedure TfrmMain.InvalidateLineCache;
begin
  FCacheCount := 0;
end;

procedure TfrmMain.EnsureLineCacheForPage;
var
  I, Count: Integer;
begin
  Count := VisibleItems;
  if Count <= 0 then Count := 1;
  if (FCacheOffset = Offset) and (FCacheCount = Count) and (Length(FCacheLines) >= Count) then
    Exit; // cache is already valid for this page
  FCacheOffset := Offset;
  FCacheCount := Count;
  if Length(FCacheLines) < Count then
    SetLength(FCacheLines, Count);
  for I := 0 to Count - 1 do
    FCacheLines[I] := GetLineContent(Integer(Offset) + I);
end;

procedure TfrmMain.btnUpClick(Sender: TObject);
begin
  if ListviewIsEmpty then Exit;
  Offset := 0;
  fScrollPos := 0;
  ScrollBarVertical.Position := 0;
  ScrollBarHorizontal.Position := 0;
  InvalidateLineCache;
  if isChecked then
  begin
    showChecked;
    if Assigned(FCheckListBox) and (FCheckListBox.Items.Count > 0) then
    begin
      FCheckListBox.ItemIndex := 0;
      FCheckListBox.SetFocus;
    end;
    UpdateInfoPanels;
    Exit;
  end;
  ListView1.Refresh;
  SelectListViewItem(0);
  if ListView1.CanFocus then ListView1.SetFocus;
  UpdateInfoPanels;
end;

procedure TfrmMain.btnDownClick(Sender: TObject);
var
  MaxOff: Int64;
  LastVisIdx: Integer;
  ScrollExtent: Int64;
begin
  if ListviewIsEmpty then Exit;
  if isChecked then
  begin
    if FFilterActive then
    begin
      ScrollExtent := FFilteredCount;
      if ScrollExtent < 1 then ScrollExtent := 1;
    end
    else
    begin
      ScrollExtent := ItemCount;
      if ScrollExtent < 1 then ScrollExtent := 1;
    end;
    MaxOff := ScrollExtent - VisibleItems + 1;
    if MaxOff < 0 then MaxOff := 0;
    Offset := MaxOff;
    if ScrollExtent < 1 then ScrollExtent := 1;
    if Offset > 0 then
      fScrollPos := Trunc((Int64(Offset) / ScrollExtent) * ScrollBarVertical.Max)
    else
      fScrollPos := 0;
    ScrollBarVertical.Position := fScrollPos;
    ScrollBarHorizontal.Position := 0;
    InvalidateLineCache;
    showChecked;
    if Assigned(FCheckListBox) and (FCheckListBox.Items.Count > 0) then
    begin
      FCheckListBox.ItemIndex := FCheckListBox.Items.Count - 1;
      FCheckListBox.SetFocus;
    end;
    UpdateInfoPanels;
    Exit;
  end;
  if FFilterActive then
  begin
    Offset := 0;
    fScrollPos := 0;
    ScrollBarVertical.Position := 0;
    InvalidateLineCache;
    ListView1.Refresh;
    if (ListView1.Items.Count > 0) then
      SelectListViewItem(ListView1.Items.Count - 1)
    else
      SelectListViewItem(-1);
    if ListView1.CanFocus then ListView1.SetFocus;
    UpdateInfoPanels;
    Exit;
  end;
  if ItemCount <= VisibleItems then
  begin
    // All items fit on screen - select last item
    SelectListViewItem(Integer(ItemCount) - 1);
    if ListView1.CanFocus then ListView1.SetFocus;
    UpdateInfoPanels;
    Exit;
  end;
  MaxOff := ItemCount - VisibleItems;
  if MaxOff < 0 then MaxOff := 0;
  Offset := MaxOff;
  fScrollPos := ScrollBarVertical.Max;
  ScrollBarVertical.Position := fScrollPos;
  ScrollBarHorizontal.Position := 0;
  InvalidateLineCache;
  ListView1.Refresh;
  LastVisIdx := Integer(ItemCount - Offset) - 1;
  if LastVisIdx >= ListView1.Items.Count then
    LastVisIdx := ListView1.Items.Count - 1;
  if LastVisIdx < 0 then LastVisIdx := 0;
  SelectListViewItem(LastVisIdx);
  if ListView1.CanFocus then ListView1.SetFocus;
  UpdateInfoPanels;
end;
          
procedure TfrmMain.pgMainCloseBtnClick(Sender: TComponent;
  TabIndex: Integer; var CanClose: Boolean; var Action: TacCloseAction);
const
  showOtherTabs: Boolean = True;
begin
  case TabIndex of
    TAB_READ_FILE_INDEX:
    begin
      HideTabs;
      //ActionClear.Execute;
    end;
    else {TAB_SPLIT_FILE_INDEX, TAB_EXPORTED_LINES:}
    begin
      HideTabs(showOtherTabs);
    end;
  end;  
  Abort;
end;

procedure TfrmMain.MenuItem2Click(Sender: TObject);
begin
  DoRead;
end;

procedure TfrmMain.ActionSplitFileExecute(Sender: TObject);
const
  showOtherTabs: Boolean = True;
var
  lastAccessTime,
  lastModificationTime: TDateTime;
begin
  if fileIsEmpty then DoRead;
  ShowTab(tabSplitFile);
  lblFileNameValue.Caption := edtFileName.Text;
  lblTotalLinesValue.Caption := UnUtils.FormatNumber(totalLines);
  lblTotalCharactersValue.Caption := UnUtils.FormatNumber(totalCharacters);
  DSiWin32.DSiGetFileTimes(edtFileName.Text, creationTime, lastAccessTime, lastModificationTime);
  lblFileDtCreationValue.Caption := FormatDateTime('dd/mm/yyyy', creationTime); //DateToStr(creationTime);
end;

procedure TfrmMain.btnSplitFilesClick(Sender: TObject);
begin
  ActionSplitFile.Execute;
end;

procedure TfrmMain.btnMergeMultipleLinesClick(Sender: TObject);
var
  DeltaFile: String;
  AList: TStringList;
begin
  if Trim(edtFileName.Text) = '' then
  begin
    ShowMessage('Please select a file first.');
    Exit;
  end;
  if not FileExists(edtFileName.Text) then
  begin
    ShowMessage('File not found.');
    Exit;
  end;

  if not EnsureWritableSession then Exit;

  DeltaFile := ExtractFilePath(ParamStr(0)) + ChangeFileExt(ExtractFileName(edtFileName.Text), '.delta');

  AList := TStringList.Create;
  try
    if FileExists(DeltaFile) then
      AList.LoadFromFile(DeltaFile);

    if TfrmDeltaEditor.Execute(AList) then
    begin
      if AList.Count = 0 then
      begin
        ShowMessage('No lines entered. Operation cancelled.');
        Exit;
      end;

      AList.SaveToFile(DeltaFile);
      if not EnsureOpenFileNotStaleForMutate then Exit;
      TMergeDeltaThread.Create(edtFileName.Text, DeltaFile);
    end;
  finally
    AList.Free;
  end;
end;

procedure TfrmMain.tabSplitFileShow(Sender: TObject);
begin
  pgcSplitFiles.ActivePageIndex := 0;
  // Update split-by-lines spin edits range when entering the split tab
  if totalLines > 0 then
  begin
    spnFromSplitByLine.MinValue := 1;
    spnFromSplitByLine.MaxValue := totalLines;
    spnToSplitByLine.MinValue := 1;
    spnToSplitByLine.MaxValue := totalLines;
    if spnToSplitByLine.Value < 1 then spnToSplitByLine.Value := 1;
    if spnFromSplitByLine.Value < 1 then spnFromSplitByLine.Value := 1;
  end;
end;

procedure TfrmMain.btnExecuteSplitFileByFilesClick(Sender: TObject);
var
  Entries: TSplitEntryArray;
  Count: Integer;
begin
  if Trim(edtFileName.Text) = '' then begin ShowMessage('Please select a file.'); Exit; end;
  if not FileExists(edtFileName.Text) then begin ShowMessage('File not found.'); Exit; end;
  if not EnsureWritableSession then Exit;

  with clFiles do
  begin
    if not Active then Exit;
    if IsEmpty then Exit;

    // Validations
    First;
    while not Eof do
    begin
      if (Trim(FieldByName('SourceLine').AsString) = '') or
         (Trim(FieldByName('TargetLine').AsString) = '') then
      begin
        ShowMessage(Format('Line %d: SourceLine and TargetLine must not be empty.',
          [FieldByName('ID').AsInteger]));
        Exit;
      end;
      if FieldByName('SourceLine').AsInteger > FieldByName('TargetLine').AsInteger then
      begin
        ShowMessage(Format('Line %d: SourceLine (%s) must not be greater than TargetLine (%s).',
          [FieldByName('ID').AsInteger, FieldByName('SourceLine').AsString, FieldByName('TargetLine').AsString]));
        Exit;
      end;
      Next;
    end;

    Count := 0;
    SetLength(Entries, RecordCount);
    First;
    while not Eof do
    begin
      Entries[Count].ID := FieldByName('ID').AsInteger;
      Entries[Count].FileName := FieldByName('Filename').AsString;
      Entries[Count].SourceLine := FieldByName('SourceLine').AsInteger;
      Entries[Count].TargetLine := FieldByName('TargetLine').AsInteger;
      Inc(Count);
      Next;
    end;
    SetLength(Entries, Count);
  end;

  if Count > 0 then
    TSplitFileThread.Create(edtFileName.Text, ExtractFilePath(edtFileName.Text), Entries, Count);
end;

procedure TfrmMain.btnExecuteSplitFileByLinesClick(Sender: TObject);
var
  Entries: TSplitEntryArray;
  SourceLine, TargetLine: Int64;
  OutputFile, OutputDir, OutputName: string;
begin
  if Trim(edtFileName.Text) = '' then begin ShowMessage('Please select a file.'); Exit; end;
  if not FileExists(edtFileName.Text) then begin ShowMessage('File not found.'); Exit; end;
  if not EnsureWritableSession then Exit;

  SourceLine := spnFromSplitByLine.Value;
  TargetLine := spnToSplitByLine.Value;
  OutputFile := Trim(edtOutputSplitByLineText.Text);

  if SourceLine < 1 then begin ShowMessage('From line must be >= 1.'); Exit; end;
  if TargetLine < SourceLine then begin ShowMessage('To line must be >= From line.'); Exit; end;
  if OutputFile = '' then begin ShowMessage('Please specify an output filename.'); Exit; end;

  // Determine output directory and filename
  OutputDir := ExtractFilePath(OutputFile);
  OutputName := ExtractFileName(OutputFile);
  if OutputDir = '' then
    OutputDir := ExtractFilePath(edtFileName.Text);
  if OutputName = '' then
    OutputName := 'split_output.txt';

  // Use 0-based line indices for the thread (index file is 0-based)
  SetLength(Entries, 1);
  Entries[0].ID := 1;
  Entries[0].FileName := OutputName;
  Entries[0].SourceLine := SourceLine - 1;
  Entries[0].TargetLine := TargetLine - 1;

  TSplitFileThread.Create(edtFileName.Text, OutputDir, Entries, 1);
end;

procedure TfrmMain.ActionClearExecute(Sender: TObject);
begin
  EmptyObjects;
end;

procedure TfrmMain.FindButtonClick(Sender: TObject);
var
  fileList: TStringList;
  word, row: string;
begin
  // Sets FileFile properties
  FindFile.Threaded := Threaded.Checked;
  FindFile.FoldersExclude.Clear;
  //folders exclude
  with clFolders do
  begin
    DisableControls;
    try
      First;
      while not Eof do
      begin
        FindFile.FoldersExclude.Add(FieldByName('FOLDER').AsString);
        Next;
      end;
    finally
      EnableControls;
    end;
  end;

  // - Name & Location
  with FindFile.Criteria.Files do
  begin
    FileName := Self.FileName.Text;
    Location := Self.Location.Text;
    Subfolders := Self.Subfolders.Checked;
    fileList := TStringList.Create;
    word := '';
    row := '';
    with clFilesExclude do
    begin
      DisableControls;
      try
        //If IsEmpty then Exit;
        First;
        while not Eof do
        begin
          row := Trim(FieldByName('FileExclude').AsString);
          (*if (SmartPos('class', row) > 0)
          or (SmartPos('jar', row) > 0)
          or (SmartPos('dcu', row) > 0 )
          then*)
            word := word + row + #13#10;
          Next;
        end;
        First;
      finally
        EnableControls;
      end;
    end;  

    fileList.Text := word; 
    Filters.Assign(fileList);
  end;
  // - Containing Text
  with FindFile.Criteria.Content do
  begin
    Phrase := Self.Phrase.Text;
    Options := [];
    if Self.CaseSenstitive.Checked then
      Options := Options + [csoCaseSensitive];
    if Self.WholeWord.Checked then
      Options := Options + [csoWholeWord];
    if Self.Negate.Checked then
      Options := Options + [csoNegate];
  end;
  // - Attributes
  with FindFile.Criteria.Attributes do
  begin
    Archive := GetAttributeStatus(Self.Archive);
    Readonly := GetAttributeStatus(Self.Readonly);
    Hidden := GetAttributeStatus(Self.Hidden);
    System := GetAttributeStatus(Self.System);
    Directory := GetAttributeStatus(Self.Directory);
    Compressed := GetAttributeStatus(Self.Compressed);
    Encrypted := GetAttributeStatus(Self.Encrypted);
    Offline := GetAttributeStatus(Self.Offline);
    ReparsePoint := GetAttributeStatus(Self.ReparsePoint);
    SparseFile := GetAttributeStatus(Self.SparseFile);
    Temporary := GetAttributeStatus(Self.Temporary);
    Device := GetAttributeStatus(Self.Device);
    Normal := GetAttributeStatus(Self.Normal);
    Virtual := GetAttributeStatus(Self.Virtual);
    NotContentIndexed := GetAttributeStatus(Self.NotContentIndexed);
  end;
  // - Size ranges
  with FindFile.Criteria.Size do
  begin
    Min := Self.SizeMin.Position;
    case Self.SizeMinUnit.ItemIndex of
      1: Min := Min * 1024;
      2: Min := Min * 1024 * 1024;
      3: Min := Min * 1024 * 1024 * 1024;
    end;
    Max := Self.SizeMax.Position;
    case Self.SizeMaxUnit.ItemIndex of
      1: Max := Max * 1024;
      2: Max := Max * 1024 * 1024;
      3: Max := Max * 1024 * 1024 * 1024;
    end;
  end;
  // - TimeStamp ranges
  with FindFile.Criteria.TimeStamp do
  begin
    Clear;
    // Created on
    if Self.CBD.Checked then
      CreatedBefore := Self.CreatedBeforeDate.Date;
    if Self.CBT.Checked then
      CreatedBefore := CreatedBefore + Self.CreatedBeforeTime.Time;
    if Self.CAD.Checked then
      CreatedAfter := Self.CreatedAfterDate.Date;
    if Self.CAT.Checked then
      CreatedAfter := CreatedAfter + Self.CreatedAfterTime.Time;
    // Modified on
    if Self.MBD.Checked then
      ModifiedBefore := Self.ModifiedBeforeDate.Date;
    if Self.MBT.Checked then
      ModifiedBefore := ModifiedBefore + Self.ModifiedBeforeTime.Time;
    if Self.MAD.Checked then
      ModifiedAfter := Self.ModifiedAfterDate.Date;
    if Self.MAT.Checked then
      ModifiedAfter := ModifiedAfter + Self.ModifiedAfterTime.Time;
    // Accessed on
    if Self.ABD.Checked then
      AccessedBefore := Self.AccessedBeforeDate.Date;
    if Self.ABT.Checked then
      AccessedBefore := AccessedBefore + Self.AccessedBeforeTime.Time;
    if Self.AAD.Checked then
      AccessedAfter := Self.AccessedAfterDate.Date;
    if Self.AAT.Checked then
      AccessedAfter := AccessedAfter + Self.AccessedAfterTime.Time;
  end;
  // Begins search
  FindFile.Execute;
end;

procedure TfrmMain.StopButtonClick(Sender: TObject);
begin
  FindFile.Abort;
  StatusBar.SimpleText := 'Cancelling search, please wait...';
end;

procedure TfrmMain.FindFileSearchBegin(Sender: TObject);
begin
  Folders := 0;
  SortedColumn := -1;
  FoundFiles.SortType := stNone;
  FoundFiles.Items.BeginUpdate;
  FoundFiles.Items.Clear;
  FoundFiles.Items.EndUpdate;
  FindButton.Enabled := False;
  StopButton.Enabled := True;
  Threaded.Enabled := False;
  ProgressImagePanel.Visible := True;
  ProgressImageTimer.Enabled := True;
  StartTime := GetTickCount;
end;

procedure TfrmMain.FindFileSearchFinish(Sender: TObject);
begin
  StatusBar.SimpleText := Format('%d folder(s) searched and %d file(s) found - %.3f second(s)',
    [Folders, FoundFiles.Items.Count, (GetTickCount - StartTime) / 1000]);
  if FindFile.Aborted then
    StatusBar.SimpleText := 'Search cancelled - ' + StatusBar.SimpleText;
  ProgressImageTimer.Enabled := False;
  ProgressImagePanel.Visible := False;
  Threaded.Enabled := True;
  StopButton.Enabled := False;
  FindButton.Enabled := True;
end;

procedure TfrmMain.FindFileFolderChange(Sender: TObject;
  const Folder: String; var IgnoreFolder: TFolderIgnore);
begin
  Inc(Folders);
  StatusBar.SimpleText := Folder;
  if not FindFile.Threaded then
    Application.ProcessMessages;
end;

procedure TfrmMain.FindFileFileMatch(Sender: TObject;
  const FileInfo: TFileDetails);
begin
  with FoundFiles.Items.Add do
  begin
    Caption := FileInfo.Name;
    SubItems.Add(FileInfo.Location);
    if LongBool(FileInfo.Attributes and FILE_ATTRIBUTE_DIRECTORY) then
      SubItems.Add('Folder')
    else
      SubItems.Add(FormatFileSize(FileInfo.Size));
    SubItems.Add(DateTimeToStr(FileInfo.ModifiedTime));
  end;
  if not FindFile.Threaded then
    Application.ProcessMessages;
end;

procedure TfrmMain.FoundFilesColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  if not FindFile.Busy then
  begin
    TListView(Sender).SortType := stNone;
    if Column.Index <> SortedColumn then
    begin
      SortedColumn := Column.Index;
      Descending := False;
    end
    else
      Descending := not Descending;
    TListView(Sender).SortType := stText;
  end
  else
    MessageDlg('Cannot sort the list while a search is in progress.', mtWarning, [mbOK], 0);
end;

procedure TfrmMain.FoundFilesCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  if SortedColumn = 0 then
    Compare := CompareText(Item1.Caption, Item2.Caption)
  else if SortedColumn > 0 then
    Compare := CompareText(Item1.SubItems[SortedColumn-1],
                           Item2.SubItems[SortedColumn-1]);
  if Descending then Compare := -Compare;
end;

procedure TfrmMain.FoundFilesDblClick(Sender: TObject);
begin
  OpenFileItemClick(nil);
end;

procedure TfrmMain.OpenFileItemClick(Sender: TObject);
begin
  if FoundFiles.Selected <> nil then
    with FoundFiles.Selected do
      ShellExecute(0, 'Open', PChar(Caption), nil, PChar(SubItems[0]), SW_NORMAL);
end;

procedure TfrmMain.OpenFileLocationItemClick(Sender: TObject);
var
  Param: String;
begin
  if FoundFiles.Selected <> nil then
  begin
    with FoundFiles.Selected do
      Param := Format('/n,/select,"%s%s"', [SubItems[0], Caption]);
    ShellExecute(0, 'Open', 'explorer.exe', PChar(Param), nil, SW_NORMAL);
  end;
end;

procedure TfrmMain.PopupMenuPopup(Sender: TObject);
begin
  OpenFileItem.Enabled := (FoundFiles.Selected <> nil);
  OpenFileLocationItem.Enabled := (FoundFiles.Selected <> nil);
end;

procedure TfrmMain.CBDClick(Sender: TObject);
begin
  CreatedBeforeDate.Enabled := CBD.Checked;
end;

procedure TfrmMain.CBTClick(Sender: TObject);
begin
  CreatedBeforeTime.Enabled := CBT.Checked;
end;

procedure TfrmMain.CADClick(Sender: TObject);
begin
  CreatedAfterDate.Enabled := CAD.Checked;
end;

procedure TfrmMain.CATClick(Sender: TObject);
begin
  CreatedAfterTime.Enabled := CAT.Checked;
end;

procedure TfrmMain.MBDClick(Sender: TObject);
begin
  ModifiedBeforeDate.Enabled := MBD.Checked;
end;

procedure TfrmMain.MBTClick(Sender: TObject);
begin
  ModifiedBeforeTime.Enabled := MBT.Checked;
end;

procedure TfrmMain.MADClick(Sender: TObject);
begin
  ModifiedAfterDate.Enabled := MAD.Checked;
end;

procedure TfrmMain.MATClick(Sender: TObject);
begin
  ModifiedAfterTime.Enabled := MAT.Checked;
end;

procedure TfrmMain.ABDClick(Sender: TObject);
begin
  AccessedBeforeDate.Enabled := ABD.Checked;
end;

procedure TfrmMain.ABTClick(Sender: TObject);
begin
  AccessedBeforeTime.Enabled := ABT.Checked;
end;

procedure TfrmMain.AADClick(Sender: TObject);
begin
  AccessedAfterDate.Enabled := AAD.Checked
end;

procedure TfrmMain.AATClick(Sender: TObject);
begin
  AccessedAfterTime.Enabled := AAT.Checked;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FindFile.Busy then FindFile.Abort;
end;

procedure TfrmMain.ProgressImageTimerTimer(Sender: TObject);
begin
  ProgressImages.Tag := (ProgressImages.Tag + 1) mod ProgressImages.Count;
  ProgressImages.GetBitmap(ProgressImages.Tag, ProgressImage.Picture.Bitmap);
  ProgressImage.Refresh;
end;

procedure TfrmMain.btnSaveFoldersExcludeClick(Sender: TObject);
begin
  insertFolderFile;
end;

procedure TfrmMain.btnDeleteFoldersExcludeClick(Sender: TObject);
begin
  deleteFolderFile;
end;

procedure TfrmMain.btnShowTabFindFileClick(Sender: TObject);
const
  showOtherTabs: Boolean = False;
begin
  ShowTab(tabFindFiles);
  pgFindFiles.ActivePageIndex := TAB_FINDFILE_INDEX;
end;

procedure TfrmMain.tabFindFilesShow(Sender: TObject);
begin
  with FoundFiles do
  begin
    Columns[0].Width := 400;
    Columns[1].Width := 400;
    Columns[2].Width := 200;
    Columns[3].Width := 200;
  end;
end;

procedure TfrmMain.dbgFilesExcludeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (shift = [ssCtrl]) and (key in [VK_DELETE]) then Abort;
end;

procedure TfrmMain.dbgFoldersExcludeKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (shift = [ssCtrl]) and (key in [VK_DELETE]) then Abort;
end;

procedure TfrmMain.btnImportExtensionFilesClick(Sender: TObject);
var
  texto: string;
  res: TModalResult;
  listExample: string;
begin
  texto := '';
  listExample := '*.class'#13#10'*.jar'#13#10'*.metadata';
  res := ShowMemoForm(TrText('Importing file extensions to exclude from search'),
                      'Please enter a valid file list, one per line, example',
                      listExample,
                      texto);

  if res = mrYes then
    ShowMessage('Texto digitado: ' + sLineBreak + texto)
  else
    ShowMessage(TrText('Operation cancelled.'));
end;

procedure TfrmMain.btnImportListFilesClick(Sender: TObject);
var
  lista: TStringList;
  linha: Integer;
  conteudoLinha: string;
  arquivo: string;
begin
  with clFilesExclude do
  begin
    Open;
    DisableControls;
    try
      lista := TStringList.Create;
      try
        lista.LoadFromFile(ExtractFilePath(Application.ExeName) + 'extensionFiles.txt');
        for linha := 0 to lista.Count - 1 do
        begin
          conteudoLinha := lista.Strings[linha];
          arquivo := Trim(UnUtils.keepOnlyLetters(PAnsiChar(conteudoLinha)));
          arquivo := Format('*%s', [arquivo]);
          if not Locate('FileExclude', arquivo, []) then
          begin
            Append;
            FieldByName('File').AsString := conteudoLinha;
            FieldByName('FileExclude').AsString := arquivo;
            FieldByName('Status').AsBoolean := True;
          end;
        end;
      finally
        FreeAndNil(lista);
      end;
      if (State in [dsInsert, dsEdit]) then
      begin
        Post;
        SaveToFile(ExtractFilePath(Application.ExeName) + XMLFILES, dfXML);
        Close;
        Open;
      end;
      IndexFieldNames := 'File';
      if RecordCount > 0 then First;
    finally
      EnableControls;
    end;
  end;
end;

procedure TfrmMain.deleteExcludeFile;
begin
  if clFilesExclude.IsEmpty then Exit;
  if Application.MessageBox(PChar(TrText('It will be removed from the list. Confirm ?')),
    PChar(TrText('Delete confirmation')),
    MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON1) <> idYes then Exit;
  clFilesExclude.Delete;
  clFilesExclude.SaveToFile(ExtractFilePath(Application.ExeName) + XMLFILES, dfXML);
end;

procedure TfrmMain.insertExcludeFile;
var
  input, inputFile: AnsiString;
begin
  if not InputQuery(TrText('Extension files exclusion'), TrText('Please enter with file extension to exclude in the files search'), input) then Exit;
  if Trim(input) = '' then Exit;
  inputFile := Format('*.%s', [UnUtils.keepOnlyLetters(PAnsiChar(input))]);
  with clFilesExclude do
  begin
    DisableControls;
    try
      if not IsEmpty then if Locate('File', inputFile, []) then Exit;
      Append;
      FieldByName('File').AsString := inputFile;
      FieldByName('FileExclude').AsString := Format('*%s', [UnUtils.keepOnlyLetters(PAnsiChar(input))]);
      FieldByName('Status').AsBoolean := True;
      Post;
      SaveToFile(ExtractFilePath(Application.ExeName) + XMLFILES, dfXML);
      Close; 
      IndexFieldNames := 'File';
      Open;
      if RecordCount > 0 then First;
    finally
      EnableControls;
    end;
  end;
end;

procedure TfrmMain.btnSaveFilesExcludeClick(Sender: TObject);
begin
  insertExcludeFile;
end;

procedure TfrmMain.btnDeleteFilesExcludeClick(Sender: TObject);
begin
  deleteExcludeFile;
end;

procedure TfrmMain.deleteFolderFile;
begin
  if clFolders.IsEmpty then Exit;
  if Application.MessageBox(PChar(TrText('It will be removed from the list. Confirm ?')),
    PChar(TrText('Delete confirmation')),
    MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON1) <> idYes then Exit;
  clFolders.Delete;
  clFolders.SaveToFile(ExtractFilePath(Application.ExeName) + XMLFOLDERS, dfXML);
end;

procedure TfrmMain.insertFolderFile;
var
  input: AnsiString;
begin
  if not InputQuery(TrText('Folders exclusion'), TrText('Please enter with folder extension to exclude in the files search'), input) then Exit;
  input := Trim(input);
  if input = '' then Exit;
  with clFolders do
  begin
    DisableControls;
    try
      if not IsEmpty then if Locate('Folder', input, []) then Exit;
      Append;
      FieldByName('Folder').AsString := input;
      Post;
      SaveToFile(ExtractFilePath(Application.ExeName) + XMLFOLDERS, dfXML);
      Close;
      Open;
      IndexFieldNames := 'Folder';
      if RecordCount > 0 then First;
    finally
      EnableControls;
    end;
  end;
end;

procedure TfrmMain.dbnFoldersClick(Sender: TObject; Button: TNavigateBtn);
begin
  if Button = nbPost then
    saveFolderFile;
end;

procedure TfrmMain.saveExcludeFile;
var
  input: AnsiString;
begin
  with clFilesExclude do
  begin
    DisableControls;
    Edit;
    input := FieldByName('File').AsString;
    FieldByName('File').AsString := Format('*.%s', [UnUtils.keepOnlyLetters(PAnsiChar(input))]);
    FieldByName('FileExclude').AsString := Format('*%s', [UnUtils.keepOnlyLetters(PAnsiChar(input))]);
    FieldByName('Status').AsBoolean := True;
    Post;
    try
      SaveToFile(ExtractFilePath(Application.ExeName) + XMLFILES, dfXML);
      Close;
      Open;
      IndexFieldNames := 'File';
      if RecordCount > 0 then
      begin
        First;
        UnUtils.MessageBox(TrText('Information'), TrText('File saved with success.'));
      end;
    finally
      EnableControls;
    end;
  end;
end;

procedure TfrmMain.saveFolderFile;
begin
  with clFolders do
  begin
    DisableControls;
    try
      SaveToFile(ExtractFilePath(Application.ExeName) + XMLFOLDERS, dfXML);
      Close;
      Open;
      IndexFieldNames := 'Folder';
      if RecordCount > 0 then
      begin
        First;
        UnUtils.MessageBox(TrText('Information'), TrText('Folder saved with success.'));
      end;
    finally
      EnableControls;
    end;
  end;
end;

procedure TfrmMain.dbnFilesClick(Sender: TObject; Button: TNavigateBtn);
begin
  if Button = nbPost then
  begin 
    saveExcludeFile;
  end;
end;

function TfrmMain.excludeExtensionFilesList: TStringList;
begin
  Result := TStringList.Create;
  with clFilesExclude do
  begin
    DisableControls;
    try
      If IsEmpty then Exit;
      First;
      while not Eof do
      begin
        Result.Add(FieldByName('FileExclude').AsString);
        Next;
      end;
      First;
    finally
      EnableControls;
    end;
  end;
end;

procedure TfrmMain.sButton4Click(Sender: TObject);
begin
  PackFolder('C:\Hamden\Sistemas\Backend\delphi\delphi7\FastFile\Src-4-AlternativeVersion\Build\Skins', 'skins.bin');
end;

// -----------------------------------------------------------------------------
// HELPER PROCEDURE: Updates info panels (Line/Col, Lines, Encoding)
// -----------------------------------------------------------------------------
procedure TfrmMain.UpdateInfoPanels;
var
  SelLine: Int64;
  R: Int64;
begin
  if FTrLineColFormat = '' then
    RefreshLanguageRuntimeCache;

  // Panel 6: Line / Col
  if Assigned(ListView1) and (ListView1.ItemIndex >= 0) then
  begin
    if FFilterActive then
    begin
      R := FilteredIndexToReal(ListView1.ItemIndex);
      if R >= 0 then SelLine := R + 1 else SelLine := 0;
    end
    else
      SelLine := Offset + ListView1.ItemIndex + 1;
  end
  else
    SelLine := 0;
  if SelLine <> FLastStatusLine then
  begin
    FLastStatusLine := SelLine;
    if SelLine > 0 then
      sStatusBar1.Panels[6].Text := Format(FTrLineColFormat, [SelLine, 1])
    else
      sStatusBar1.Panels[6].Text := FTrLineColZero;
  end;
  // Panel 7: Total lines
  if totalLines <> FLastStatusCount then
  begin
    FLastStatusCount := totalLines;
    sStatusBar1.Panels[7].Text := Format(FTrLinesFormat, [totalLines]);
  end;
  { Painel 8: apenas o combo (sem texto duplicado); hint mostra deteccao + modo }
  if (sStatusBar1.Panels.Count > 8) then
  begin
    sStatusBar1.Panels[8].Text := '';
    if Assigned(comboViewEncoding) then
    begin
      if (comboViewEncoding.ItemIndex > 0) then
        comboViewEncoding.Hint :=
          FTrDetectedOnFile + FDetectedEncoding + #13#10 +
          FTrListViewUses + EffectiveDisplayEncoding + #13#10 +
          FTrNoRereadDefault + #13#10 +
          TrText('View encoding: forced (list decode only; file on disk unchanged).')
      else
        comboViewEncoding.Hint :=
          FTrDetectedOnFile + FDetectedEncoding + FTrDefaultViewSuffix + #13#10 +
          FTrNoRereadForced + #13#10 +
          TrText('View encoding: default (list follows detected BOM/heuristics).');
      comboViewEncoding.Hint := comboViewEncoding.Hint + #13#10 + TrText(
        '[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.');
    end;
  end;
end;

procedure TfrmMain.UpdateListViewZoomStatusPanel;
var
  Sz, Pct: Integer;
begin
  if (not Assigned(sStatusBar1)) or (not Assigned(ListView1)) then Exit;
  { Painel 9: zoom % (apos Line/Col, Lines e painel do combo de encoding). }
  if sStatusBar1.Panels.Count < 10 then Exit;
  Sz := ListView1.Font.Size;
  if Sz < 1 then Sz := 1;
  if FListViewZoomBaseFontSize <= 0 then
    FListViewZoomBaseFontSize := Sz;
  if FListViewZoomBaseFontSize < 1 then
    FListViewZoomBaseFontSize := 1;
  Pct := Round((100.0 * Sz) / FListViewZoomBaseFontSize);
  if Pct < 1 then Pct := 1;
  sStatusBar1.Panels[9].Text := '';
  if Assigned(comboZoom) then
    RememberWheelZoomInCombo(Pct, True);
end;

function TfrmMain.StatusBarPanelRectByWidths(const Index: Integer): TRect;
var
  I, L: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  if (Index < 0) or (not Assigned(sStatusBar1)) or (Index >= sStatusBar1.Panels.Count) then
    Exit;
  L := 0;
  for I := 0 to Index - 1 do
    Inc(L, sStatusBar1.Panels[I].Width);
  Result := Rect(L, 0, L + sStatusBar1.Panels[Index].Width, sStatusBar1.ClientHeight);
end;

procedure TfrmMain.LayoutViewEncodingCombo;
var
  R: TRect;
  M, H, Tp, Wc: Integer;
begin
  if (not Assigned(comboViewEncoding)) or (not Assigned(sStatusBar1)) then Exit;
  if sStatusBar1.Panels.Count <= 8 then Exit;
  H := sStatusBar1.ClientHeight;
  if H < 4 then Exit;
  R := StatusBarPanelRectByWidths(8);
  M := 3;
  Wc := (R.Right - R.Left) - 2 * M;
  if Wc < 40 then Wc := 40;
  Tp := Max(1, (H - comboViewEncoding.Height) div 2);
  comboViewEncoding.SetBounds(R.Left + M, Tp, Wc, comboViewEncoding.Height);
end;

procedure TfrmMain.LayoutLanguageCombo;
var
  R: TRect;
  M, H, Tp, Wc: Integer;
begin
  if (not Assigned(comboLanguage)) or (not Assigned(sStatusBar1)) then Exit;
  if sStatusBar1.Panels.Count <= 2 then Exit;
  H := sStatusBar1.ClientHeight;
  if H < 4 then Exit;
  R := StatusBarPanelRectByWidths(2);
  M := 3;
  Wc := (R.Right - R.Left) - 2 * M;
  if Wc < 60 then Wc := 60;
  Tp := Max(1, (H - comboLanguage.Height) div 2);
  comboLanguage.SetBounds(R.Left + M, Tp, Wc, comboLanguage.Height);
end;

procedure TfrmMain.LayoutZoomCombo;
var
  R: TRect;
  M, H, Tp, Wc: Integer;
begin
  if (not Assigned(comboZoom)) or (not Assigned(sStatusBar1)) then Exit;
  if sStatusBar1.Panels.Count <= 9 then Exit;
  H := sStatusBar1.ClientHeight;
  if H < 4 then Exit;
  R := StatusBarPanelRectByWidths(9);
  M := 3;
  Wc := (R.Right - R.Left) - 2 * M;
  if Wc < 40 then Wc := 40;
  Tp := Max(1, (H - comboZoom.Height) div 2);
  comboZoom.SetBounds(R.Left + M, Tp, Wc, comboZoom.Height);
end;

procedure TfrmMain.RememberWheelZoomInCombo(const APct: Integer; const AForce: Boolean = False);
const
  MAX_WHEEL_ZOOM_HISTORY = 5;
  WHEEL_ZOOM_COMBO_DEBOUNCE_MS = 45;
  MAX_COMBO_ITEMS = 40;
var
  S, TmpS: string;
  I, J, Idx, V1, V2: Integer;
  Keep: TStringList;
  NowTick: DWORD;

  function ZoomValue(const AText: string): Integer;
  var
    T: string;
  begin
    T := Trim(StringReplace(AText, '%', '', [rfReplaceAll]));
    Result := StrToIntDef(T, MaxInt);
  end;

begin
  if not Assigned(comboZoom) then Exit;
  if not Assigned(FZoomWheelHistory) then Exit;

  S := Format('%d%%', [APct]);

  I := FZoomWheelHistory.IndexOf(S);
  if I >= 0 then
    FZoomWheelHistory.Delete(I);
  FZoomWheelHistory.Insert(0, S);
  while FZoomWheelHistory.Count > MAX_WHEEL_ZOOM_HISTORY do
    FZoomWheelHistory.Delete(FZoomWheelHistory.Count - 1);

  NowTick := GetTickCount;
  if (not AForce) and ((NowTick - FLastZoomComboUpdateTick) < WHEEL_ZOOM_COMBO_DEBOUNCE_MS) then
  begin
    { Debounce: evita rebuild pesado a cada WM_MOUSEWHEEL, mas mantem selecao atual se existir. }
    Idx := comboZoom.Items.IndexOf(S);
    if Idx >= 0 then
    begin
      FUpdatingZoomCombo := True;
      try
        comboZoom.ItemIndex := Idx;
      finally
        FUpdatingZoomCombo := False;
      end;
    end;
    Exit;
  end;
  FLastZoomComboUpdateTick := NowTick;

  Keep := TStringList.Create;
  FUpdatingZoomCombo := True;
  try
    comboZoom.Items.BeginUpdate;
    try
      { Mantem os itens existentes (sem apagar) e injeta os ultimos 5 do scroll. }
      for I := 0 to comboZoom.Items.Count - 1 do
        if Keep.IndexOf(comboZoom.Items[I]) < 0 then
          Keep.Add(comboZoom.Items[I]);
      for I := 0 to FZoomWheelHistory.Count - 1 do
        if Keep.IndexOf(FZoomWheelHistory[I]) < 0 then
          Keep.Add(FZoomWheelHistory[I]);
      if Keep.IndexOf(S) < 0 then
        Keep.Add(S);

      { Ordenacao numerica total (todos os itens) para manter combo 100% ordenada. }
      for I := 0 to Keep.Count - 2 do
        for J := I + 1 to Keep.Count - 1 do
        begin
          V1 := ZoomValue(Keep[I]);
          V2 := ZoomValue(Keep[J]);
          if (V2 < V1) or ((V1 = V2) and (AnsiCompareText(Keep[J], Keep[I]) < 0)) then
          begin
            TmpS := Keep[I];
            Keep[I] := Keep[J];
            Keep[J] := TmpS;
          end;
        end;

      while Keep.Count > MAX_COMBO_ITEMS do
        Keep.Delete(Keep.Count - 1);

      comboZoom.Items.Assign(Keep);
      Idx := comboZoom.Items.IndexOf(S);
      if Idx >= 0 then
        comboZoom.ItemIndex := Idx;
    finally
      comboZoom.Items.EndUpdate;
    end;
  finally
    Keep.Free;
    FUpdatingZoomCombo := False;
  end;
end;

procedure TfrmMain.ApplyListViewZoomPercent(const APct: Integer);
const
  ZOOM_MIN_PERCENT = 50;
  ZOOM_MAX_PERCENT = 200;
  ZOOM_MIN_SIZE = 6;
  ZOOM_MAX_SIZE = 32;
var
  Pct, NewSize: Integer;
begin
  if not Assigned(ListView1) then Exit;
  if FListViewZoomBaseFontSize <= 0 then
    FListViewZoomBaseFontSize := Max(1, ListView1.Font.Size);

  Pct := APct;
  if Pct < ZOOM_MIN_PERCENT then Pct := ZOOM_MIN_PERCENT;
  if Pct > ZOOM_MAX_PERCENT then Pct := ZOOM_MAX_PERCENT;

  NewSize := Round((FListViewZoomBaseFontSize * Pct) / 100.0);
  if NewSize < ZOOM_MIN_SIZE then NewSize := ZOOM_MIN_SIZE;
  if NewSize > ZOOM_MAX_SIZE then NewSize := ZOOM_MAX_SIZE;
  if NewSize = ListView1.Font.Size then
  begin
    UpdateListViewZoomStatusPanel;
    Exit;
  end;

  ListView1.Font.Size := NewSize;
  CalculateFontMetrics;
  if FFastVisualWordWrap then
    UpdateListViewWordWrapUi
  else
  begin
    ListView1Resize(ListView1);
    InvalidateLineCache;
    if ListView1.HandleAllocated and ListView1.Visible and (not isChecked) then
    begin
      ListView1.Perform(WM_SETREDRAW, 0, 0);
      try
        ListView1.Perform(CM_RECREATEWND, 0, 0);
      finally
        ListView1.Perform(WM_SETREDRAW, 1, 0);
      end;
      FDeferredListViewRecreateForRowHeight := False;
    end
    else
      FDeferredListViewRecreateForRowHeight := True;
    ListView1.Invalidate;
  end;

  if isChecked and Assigned(FCheckListBox) then
  begin
    FCheckListBox.Font.Assign(ListView1.Font);
    FCheckListBox.ItemHeight := ListViewVisualRowHeight;
    FCheckListBox.Invalidate;
  end;
  UpdateInfoPanels;
  UpdateListViewZoomStatusPanel;
end;

procedure TfrmMain.comboZoomChange(Sender: TObject);
var
  S: string;
  Pct: Integer;
begin
  if FUpdatingZoomCombo then Exit;
  if not Assigned(comboZoom) then Exit;
  S := Trim(StringReplace(comboZoom.Text, '%', '', [rfReplaceAll]));
  Pct := StrToIntDef(S, 100);
  ApplyListViewZoomPercent(Pct);
end;

// -----------------------------------------------------------------------------
// HELPER PROCEDURE: Updates text and stores alignment preference
// -----------------------------------------------------------------------------
procedure TfrmMain.UpdateStatusBar(const TextMsg: string; Alignment: TIconAlignment);
begin
  // Store the alignment preference in the private variable
  FCurrentIconAlignment := Alignment;

  // Set the text of the first panel
  sStatusBar1.Panels[0].Text := TextMsg;

  // Force the StatusBar to repaint immediately to trigger OnDrawPanel
  sStatusBar1.Repaint;
end;

procedure TfrmMain.sStatusBar1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  R1: TRect;
  P: TPoint;
begin
  P := Point(X, Y);
  sStatusBar1.Perform(SB_GETRECT, 1, Integer(@R1));
  if PtInRect(R1, P) then
  begin
    sStatusBar1.Cursor := crHandPoint;
    Application.CancelHint;
  end
  else
  begin
    sStatusBar1.Cursor := crDefault;
    Application.CancelHint;
  end;
end;

procedure TfrmMain.sStatusBar1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R1: TRect;
  P: TPoint;
begin
  if Button <> mbLeft then Exit;
  P := Point(X, Y);

  sStatusBar1.Perform(SB_GETRECT, 1, Integer(@R1));
  if PtInRect(R1, P) then
    ExecutePanelIndexOne;
end;

function TfrmMain.BuildLoadedFileDetailsText: string;
var
  lastAccessTime, lastModificationTime: TDateTime;
  Sz: Int64;
  EncDisp, listModeLine: string;

  function Dt(const D: TDateTime): string;
  begin
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', D);
  end;

  function YN(const B: Boolean): string;
  begin
    if B then
      Result := TrText('Yes')
    else
      Result := TrText('No');
  end;

  procedure AddLine(const S: string);
  begin
    Result := Result + S + #13#10;
  end;

  procedure AddKV(const Name, Value: string);
  begin
    AddLine(Name + ' ' + Value);
  end;
begin
  Result := '';
  if fileIsEmpty then Exit;

  if UnUtils.CheckFile(Trim(edtFileName.Text)) then
  begin
    DSiWin32.DSiGetFileTimes(Trim(edtFileName.Text), creationTime, lastAccessTime, lastModificationTime);
    Sz := UnUtils.GetFileSize(Trim(edtFileName.Text));
    AddKV(TrText('File name:'), Trim(edtFileName.Text));
    AddKV(TrText('Size on disk:'), Format('%s %s', [UnUtils.FormatNumber(Sz), TrText('bytes')]));
    AddKV(TrText('Creation Date:'), Dt(creationTime));
    AddKV(TrText('Modified:'), Dt(lastModificationTime));
    AddKV(TrText('Last accessed:'), Dt(lastAccessTime));
    AddKV(TrText('Total lines:'), UnUtils.FormatNumber(totalLines));
    AddKV(TrText('Total characters:'), UnUtils.FormatNumber(totalCharacters));
    AddKV(TrText('Max indexed offset:'), UnUtils.FormatNumber(MaxOffset));
    AddKV(TrText('Detected encoding (file):'), FDetectedEncoding);
    EncDisp := '';
    if Assigned(comboViewEncoding) and (comboViewEncoding.ItemIndex >= 0) and
      (comboViewEncoding.ItemIndex < comboViewEncoding.Items.Count) then
      EncDisp := comboViewEncoding.Items[comboViewEncoding.ItemIndex];
    AddKV(TrText('View encoding (list):'), EncDisp);
    AddKV(TrText('Read-only session:'), YN(FFileSessionReadOnly));
    AddKV(TrText('Word wrap (visual):'), YN(Assigned(chkWordWrap) and chkWordWrap.Checked));
    AddKV(TrText('Tail / follow mode:'), YN(FTailActive));
    AddKV(TrText('Line-segmented mode:'), YN(Assigned(chkSegmentedHeavyOps) and chkSegmentedHeavyOps.Checked));
    AddKV(TrText('Filter / Grep active:'), YN(FFilterActive));
    if isChecked then
      listModeLine := TrText('List mode: checkbox list')
    else
      listModeLine := TrText('List mode: list view');
    AddLine(listModeLine);
    AddLine('');
    AddLine(TrText('Read summary (status):'));
    AddLine(lblInfoFileTime.Caption);
  end
  else
    AddKV(TrText('File name:'), Trim(edtFileName.Text));
end;

procedure TfrmMain.ExecutePanelIndexOne;
begin
  if fileIsEmpty then Exit;
  ShowDetailsPopup(BuildLoadedFileDetailsText);
end;

// -----------------------------------------------------------------------------
// EVENT HANDLER: Dynamic Copy Button
// -----------------------------------------------------------------------------
procedure TfrmMain.OnDynamicCopyClick(Sender: TObject);
var
  ParentForm: TCustomForm;
  TargetMemo: TMemo;
begin
  // 1. Identify the Form that owns the button clicked
  ParentForm := GetParentForm(Sender as TControl);

  // 2. Find the Memo component by its name (defined in creation)
  TargetMemo := TMemo(ParentForm.FindComponent('DetailMemo'));

  // 3. Copy text to Clipboard
  if Assigned(TargetMemo) then
  begin
    Clipboard.AsText := TargetMemo.Text;
    ShowMessage('Text copied to clipboard!');
  end;
end;

// -----------------------------------------------------------------------------
// LOGIC: Create and Show the Dynamic Modal Form
// -----------------------------------------------------------------------------
procedure TfrmMain.DetailsPopupKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    (Sender as TForm).ModalResult := mrCancel;
  end;
end;

procedure TfrmMain.ShowDetailsPopup(const TextContent: string);
var
  PopupForm: TForm;
  DetailMemo: TMemo;
  BtnCopy, BtnOK: TButton;
begin
  // 1. Create the Form
  PopupForm := TForm.Create(nil);
  try
    PopupForm.Caption := TrText('File details');
    PopupForm.Position := poScreenCenter;
    PopupForm.BorderStyle := bsDialog;
    PopupForm.KeyPreview := True;
    PopupForm.OnKeyDown := DetailsPopupKeyDown;
    PopupForm.Width := 560;
    PopupForm.Height := 440;

    // 2. Create the Memo (Text Display)
    DetailMemo := TMemo.Create(PopupForm);
    DetailMemo.Parent := PopupForm;
    DetailMemo.Name := 'DetailMemo'; // Crucial for FindComponent later
    DetailMemo.Text := TextContent;
    DetailMemo.ReadOnly := True;
    DetailMemo.ScrollBars := ssVertical;
    // Layout
    DetailMemo.Left := 10;
    DetailMemo.Top := 10;
    DetailMemo.Width := PopupForm.ClientWidth - 20;
    DetailMemo.Height := PopupForm.ClientHeight - 50;
    DetailMemo.Anchors := [akLeft, akTop, akRight, akBottom];

    // 3. Create "Copy" Button
    BtnCopy := TButton.Create(PopupForm);
    BtnCopy.Parent := PopupForm;
    BtnCopy.Caption := TrText('Copy');
    BtnCopy.Left := 10;
    BtnCopy.Top := PopupForm.ClientHeight - 35;
    BtnCopy.Anchors := [akLeft, akBottom];
    // Assign the event handler
    BtnCopy.OnClick := OnDynamicCopyClick;

    // 4. Create "OK" Button
    BtnOK := TButton.Create(PopupForm);
    BtnOK.Parent := PopupForm;
    BtnOK.Caption := TrText('OK');
    BtnOK.ModalResult := mrOk; // This automatically closes the modal
    BtnOK.Default := True;
    BtnOK.Left := PopupForm.ClientWidth - 85;
    BtnOK.Top := PopupForm.ClientHeight - 35;
    BtnOK.Anchors := [akRight, akBottom];

    // 5. Show Modal
    PopupForm.ShowModal;

  finally
    // Clean up memory
    PopupForm.Free;
  end;
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
begin
  if Assigned(frm) then
  begin
    frm.Height := 0;
    frm.Width := 0;
    frm.Top := -10000;
    strLineEdit := memoLineEdit.Text;
    //frm.Top := frm.Top + 300;
  end;
  Clipboard.AsText := strLineEdit;
  UnUtils.MessageBox(TrText('Information'), TrText('Contents copied to the clipboard. Just paste (CTRL+V).'));
end;

procedure TfrmMain.btnConsumerAIClick(Sender: TObject);
begin(*var
  DeployPath: String;
  Success: Boolean;
begin
  if ListviewIsEmpty then Exit;
  DeployPath := ExtractFilePath(Application.ExeName);
  // --- CALL THE HELPER ---
  // This line creates the modal, waits for user input, sets the hidden path, and runs the process.
  Success := TConsumerUIHelper.RequestInputAndExecute(edtFileName.Text, DeployPath);
  if Success then
    ShowMessage('Process finished successfully!')
  else
    ShowMessage('O processo foi cancelado ou ocorreu um erro.');  *)
  ShowConsumerAIPanel;
  if (not FConsumerAIProcessRunning) or
     (CompareText(Trim(FConsumerAIActiveFileName), Trim(edtFileName.Text)) <> 0) then
    StartConsumerAIProcess
  else if Assigned(FConsumerAIInputEdit) and FConsumerAIInputEdit.Enabled then
    FConsumerAIInputEdit.SetFocus;
end;

procedure TfrmMain.finishFileNameRead(const timer: string; const LineCount: Int64; const CharactersCount: Int64);
begin
  mmTimer.Lines.Add(timer);
  edtFileName.Text := fFileName;
  OpenFileStreams(fFileName);
  FDetectedEncoding := DetectFileEncoding(fFileName);
  FUpdatingViewEncodingCombo := True;
  try
    if Assigned(comboViewEncoding) then
    begin
      comboViewEncoding.ItemIndex := 0;
      comboViewEncoding.Enabled := True;
      comboViewEncoding.BringToFront;
      LayoutViewEncodingCombo;
    end;
  finally
    FUpdatingViewEncodingCombo := False;
  end;
  ClearUndoRedo;
  ClearAllBookmarks;
  if FTailActive then begin FTailActive := False; tmrTail.Enabled := False; end;
  if FFilterActive then ClearFilter;
  AddToRecentFiles(fFileName);
  FLastFoundLine := -1;
  FLastFoundFilePos := 0;
  InvalidateLineCache;
  ListView1.Items.Count := LineCount;
  totalLines := LineCount;
  ItemCount := totalLines;
  totalCharacters := CharactersCount;
  //ListView1.Items.Count := ItemCount;
  isChecked := False;
  isAllChecked := False;
  ScrollBarVertical.Position := 0;
  ScrollBarVerticalChange(Self);
  fScrollPos := 0;
  ScrollBarVerticalScroll(self, scPosition, fScrollPos);
  ScrollBarHorizontal.Position := 0;
  ListView1.Refresh;
  UnUtils.ActionComponent([btnClear, btnSplitFiles, btnMergeMultipleLines, btnCheckBoxes, btnExport, btnEditFile], acEnabled);
  //ListView1.Invalidate;
  UpdateInfoPanels;
  CaptureOpenFileDiskSnapshot;
end;

procedure TfrmMain.CloseFileStreams;
begin
  if Assigned(FSourceFileStream) then FreeAndNil(FSourceFileStream);
  if Assigned(FIndexFileStream) then FreeAndNil(FIndexFileStream);
  InvalidateOpenFileDiskSnapshot;
  InvalidateLineCache;
  ListView1.Items.Count := 0;
  ListView1.Invalidate;
  ApplySessionReadOnlyUi;
end;

function TfrmMain.GetLineContent(LineIndex: Integer): String;
var
  StartOffset, EndOffset: Int64;
  FullLineLen: Int64;
  LineLength: Integer;
  Buffer: AnsiString;
  OffsetBuf: array[0..39] of AnsiChar; // room for 2 index records (18+2 each)
  BytesToRead, BytesRead2: Integer;
  IdxPos: Int64;
  ReadCount: Integer;
begin
  Result := '';
  if (not Assigned(FIndexFileStream)) or (not Assigned(FSourceFileStream)) then Exit;

  try
    // Read both current and next index record in a single seek+read
    IdxPos := Int64(LineIndex) * INDEX_RECORD_SIZE;
    FIndexFileStream.Seek(IdxPos, soFromBeginning);

    // Try to read 2 records at once (current + next) to reduce seeks
    ReadCount := FIndexFileStream.Read(OffsetBuf, INDEX_RECORD_SIZE * 2);
    if ReadCount < 18 then Exit;

    // Parse start offset from first record
    SetString(Buffer, PAnsiChar(@OffsetBuf[0]), 18);
    StartOffset := StrToInt64Def(Trim(string(Buffer)), -1);
    if StartOffset = -1 then Exit;
    StartOffset := Abs(StartOffset);

    // Parse end offset from second record (if available)
    if ReadCount >= (INDEX_RECORD_SIZE + 18) then
    begin
      SetString(Buffer, PAnsiChar(@OffsetBuf[INDEX_RECORD_SIZE]), 18);
      EndOffset := StrToInt64Def(Trim(string(Buffer)), FSourceFileStream.Size + 1);
    end
    else
      EndOffset := FSourceFileStream.Size + 1;
      
    EndOffset := Abs(EndOffset);

    FullLineLen := EndOffset - StartOffset;
    if FullLineLen <= 0 then Exit;
    if FullLineLen > MAX_LINE_LEN_DISPLAY then
      LineLength := MAX_LINE_LEN_DISPLAY
    else
      LineLength := FullLineLen;

    FSourceFileStream.Seek(StartOffset - 1, soFromBeginning);
    SetLength(Buffer, LineLength);
    BytesRead2 := FSourceFileStream.Read(Pointer(Buffer)^, LineLength);

    while (BytesRead2 > 0) and (Buffer[BytesRead2] in [#10, #13]) do
      Dec(BytesRead2);

    SetLength(Buffer, BytesRead2);
    Result := DisplayTextFromFileBytes(Buffer, EffectiveDisplayEncoding);
    if FullLineLen > MAX_LINE_LEN_DISPLAY then
      Result := Result + ' ' + Format(TrText('[Line preview limited to %s bytes for performance; file line total %s bytes.]'),
        [UnUtils.FormatNumber(MAX_LINE_LEN_DISPLAY), UnUtils.FormatNumber(FullLineLen)]);
  except
    Result := '';
  end;
end;

procedure TfrmMain.OpenFileStreams(const AFileName: String);
var
  IndexFileName: String;
begin
  CloseFileStreams;
  IndexFileName := ExtractFilePath(ParamStr(0)) + 'temp.txt';

  if FileExists(AFileName) and FileExists(IndexFileName) then
  begin
    try
      FSourceFileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
      FIndexFileStream := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);
    except
      CloseFileStreams;
    end;
  end;
end;

function TfrmMain.getLineContentsFromLineIndex(
  const iLine: int64): string;
var
  CacheIdx: Integer;
begin
  // Try page cache first (avoids repeated file seeks for same page)
  CacheIdx := Integer(iLine - FCacheOffset);
  if (FCacheCount > 0) and (CacheIdx >= 0) and (CacheIdx < FCacheCount) and (CacheIdx < Length(FCacheLines)) then
    Result := FCacheLines[CacheIdx]
  else
    Result := GetLineContent(iLine);
  if (not FFastVisualWordWrap) and (ScrollBarHorizontal.Position > 1) then
    Result := Copy(Result, ScrollBarHorizontal.Position, Length(Result));
end;

(*procedure TMainForm.ListView1_Data(Sender: TObject; Item: TListItem);
var
  Index: Int64;
begin
  // Item.Index now represents an offset from an offset, adding them together
  // gives the true index
  Index := Offset + (Item.Index+1);
  Item.Caption := 'Line: ' +  FormatFloat('#,',Index) + '  ' + getLineContentsFromLineIndex(Index);
end; *)

procedure TfrmMain.ListView1Data(Sender: TObject; Item: TListItem);
var
  Index: Int64;
  RealLine: Int64;
  LineContent: string;
  S_WW: AnsiString;
begin
  if not Assigned(FSourceFileStream) then Exit;

  // Pre-populate page cache on first item request for this page
  if (not FFilterActive) and (Item.Index = 0) then
    EnsureLineCacheForPage;

  if FFilterActive then
  begin
    RealLine := FilteredIndexToReal(Item.Index);
    if RealLine < 0 then Exit;
    Index := RealLine + 1;
  end
  else
  begin
    Index := Offset + (Item.Index + 1);
    RealLine := Item.Index;
  end;

  // Pre-build line content and caption in one go
  LineContent := getLineContentsFromLineIndex(Index - 1);

  if (not FFastVisualWordWrap) and FastWordWrapAtivo and Assigned(FIndexFileStream) then
  begin
    FIndexFileStream.Seek(Int64(Index - 1) * 20, soFromBeginning);
    SetLength(S_WW, 18);
    FIndexFileStream.Read(Pointer(S_WW)^, 18);
    if StrToInt64Def(Trim(string(S_WW)), 0) < 0 then
      Item.Caption := ''
    else
      Item.Caption := 'Line: ' + FormatFloat('#,', Index);
    if Item.SubItems.Count = 0 then
      Item.SubItems.Add(LineContent)
    else
      Item.SubItems[0] := LineContent;
  end
  else
  begin
    Item.Caption := 'Line: ' + FormatFloat('#,', Index);
    if Item.SubItems.Count = 0 then
      Item.SubItems.Add(LineContent)
    else
      Item.SubItems[0] := LineContent;
  end;

  { Altura da linha no modo wrap visual: ListView usa altura do SmallImages }
  if FFastVisualWordWrap then
    Item.ImageIndex := 0
  else
    Item.ImageIndex := -1;
end;

procedure TfrmMain.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  i: Integer;
  ScrollCode: WPARAM;
  P: TPoint;
begin
  { Ctrl + roda: zoom na ListView se o rato estiver sobre ela (mesmo lista vazia). }
  if (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_MENU) >= 0) then
  begin
    if isChecked and Assigned(FCheckListBox) and FCheckListBox.Visible and FCheckListBox.HandleAllocated then
    begin
      P := FCheckListBox.ScreenToClient(MousePos);
      if PtInRect(FCheckListBox.ClientRect, P) then
      begin
        ApplyListViewWheelZoom(WheelDelta);
        Handled := True;
        Exit;
      end;
    end;
    if Assigned(ListView1) and ListView1.HandleAllocated then
    begin
      P := ListView1.ScreenToClient(MousePos);
      if PtInRect(ListView1.ClientRect, P) then
      begin
        ApplyListViewWheelZoom(WheelDelta);
        Handled := True;
        Exit;
      end;
    end;
    Handled := True;
    Exit;
  end;

  if (not Assigned(ListView1)) or (ListView1.Items.Count = 0) then
    Exit;

  // Bloqueia rolagem durante selecao vertical/drag e quando Alt estiver pressionado.
  if FIsDragging
    or (GetCapture <> 0)
    or (GetKeyState(VK_LBUTTON) < 0)
    or (GetKeyState(VK_MENU) < 0) then
  begin
    Handled := True;
    Exit;
  end;

  if WheelDelta < 0 then
    ScrollCode := SB_LINEDOWN
  else
    ScrollCode := SB_LINEUP;

  // Rola o ListView (3 linhas para ficar confortavel)
  for i := 1 to 3 do
    ListView1.Perform(WM_VSCROLL, ScrollCode, 0);

  { Com filtro na ListView (sem Select), a roda move so a lista; com Select+filtro, sincroniza a barra como no modo normal. }
  if not (FFilterActive and (not isChecked)) then
  begin
    if ScrollCode = SB_LINEDOWN then
    begin
      ScrollBarVertical.Position := ScrollBarVertical.Position + 1;
      ScrollBarVerticalScroll(Self, scLineDown, fScrollPos);
    end
    else
    begin
      ScrollBarVertical.Position := ScrollBarVertical.Position - 1;
      ScrollBarVerticalScroll(Self, scLineUp, fScrollPos);
    end;
  end;

  Handled := True;
end;



{ ============================================================================ }
// vertical selection (BLOCK SELECTION) - HOOK and implementation
{ ============================================================================ }

procedure TfrmMain.CalculateFontMetrics;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(ListView1.Font);
    FCharWidth := Bmp.Canvas.TextWidth('W');
    FLineHeight := Abs(Bmp.Canvas.Font.Height);
    
    // Ajuste de margem (padding) do ListView padrao do Windows
    if FLineHeight < 14 then FLineHeight := 14; 
    
    // Fallback de seguranca
    if FCharWidth <= 0 then FCharWidth := 8;
  finally
    Bmp.Free;
  end;
end;

function TfrmMain.ListViewVisualRowHeight: Integer;
const
  MinWrapRows = 4;
var
  FH: Integer;
begin
  Result := 20;
  if not Assigned(ListView1) then Exit;
  if FFastVisualWordWrap then
  begin
    { Mesma logica que ApplyWordWrapRowHeight (SmallImages.Height na ListView). }
    if Assigned(FWordWrapRowImages) and (FWordWrapRowImages.Height > 0) then
      Result := FWordWrapRowImages.Height
    else
    begin
      CalculateFontMetrics;
      Result := Max(48, (FLineHeight + 2) * MinWrapRows);
    end;
  end
  else
  begin
    CalculateFontMetrics;
    Result := Max(18, FLineHeight + 2);
  end;
  FH := Abs(ListView1.Font.Height);
  if FH <= 0 then FH := 16;
  { Garantir espaco minimo para checkbox + texto numa linha. }
  Result := Max(Result, FH + 6);
end;

// ===========================================================================
// *** copy vertical selection  to clipboard ***
// ===========================================================================
procedure TfrmMain.CopyVerticalSelectionToClipboard;
const
  { Margem ate o inicio do texto na subcoluna 1 (aprox. grid + padding do ListView). }
  COL1_LEFT_INSET = 5;
  { Linhas muito longas: media de largura evita milhoes de TextWidth em busca binaria. }
  LONG_LINE_THRESH = 80000;
var
  R: TRect;
  StartRowIdx, EndRowIdx: Integer;
  Col0Width, ScrollOffset: Integer;
  OriginX: Integer;
  SelLeft, SelRight: Integer;
  i, Tmp, TmpIdx, j: Integer;
  LineS, BlockS: string;
  ClipWide: WideString;
  Bmp: TBitmap;
  FirstIdx, LastIdx: Integer;
  HitX: Integer;
  dCharWidth: Double;
  PixelTextStart, PixelTextEnd: Integer;
  CopyLen, StartCharIdx, EndCharIdx: Integer;
  FirstLineNo, LastLineNo: Integer;

  function PrefixW(const Line: string; N: Integer): Integer;
  begin
    if N <= 0 then
      Result := 0
    else
      Result := Bmp.Canvas.TextWidth(Copy(Line, 1, N));
  end;

  { Inclusivo [SelL,SelR]: menor i com borda direita do prefixo >= SelL. }
  function FirstCharFromPixel(const Line: string; const SelL: Integer): Integer;
  var
    Lo, Hi, Mid, Lc: Integer;
  begin
    Lc := Length(Line);
    if Lc = 0 then
    begin
      Result := 1;
      Exit;
    end;
    if OriginX + PrefixW(Line, Lc) < SelL then
    begin
      Result := Lc + 1;
      Exit;
    end;
    Lo := 1;
    Hi := Lc;
    while Lo < Hi do
    begin
      Mid := (Lo + Hi) div 2;
      if OriginX + PrefixW(Line, Mid) < SelL then
        Lo := Mid + 1
      else
        Hi := Mid;
    end;
    Result := Lo;
  end;

  { Maior i com borda esquerda do caractere i <= SelR (intervalo inclusivo na direita). }
  function LastCharToPixel(const Line: string; const SelR: Integer): Integer;
  var
    Lo, Hi, Mid, Lc: Integer;
  begin
    Lc := Length(Line);
    Result := 0;
    if Lc = 0 then
      Exit;
    if OriginX > SelR then
      Exit;
    Lo := 1;
    Hi := Lc;
    while Lo < Hi do
    begin
      Mid := (Lo + Hi + 1) div 2;
      if OriginX + PrefixW(Line, Mid - 1) <= SelR then
        Lo := Mid
      else
        Hi := Mid - 1;
    end;
    Result := Lo;
  end;

begin
  if not FHasSelection then Exit;
  if ListviewIsEmpty then Exit;

  R.Left := Min(FBlockStartPoint.X, FBlockEndPoint.X);
  R.Right := Max(FBlockStartPoint.X, FBlockEndPoint.X);
  R.Top := Min(FBlockStartPoint.Y, FBlockEndPoint.Y);
  R.Bottom := Max(FBlockStartPoint.Y, FBlockEndPoint.Y);

  if R.Right <= R.Left then
    Inc(R.Right);

  HitX := 8;
  if ListView1.Columns.Count > 0 then
    HitX := ListView1.Columns[0].Width + 8;

  StartRowIdx := GetRowIndexAt(HitX, R.Top);
  EndRowIdx := GetRowIndexAt(HitX, R.Bottom - 1);

  if (StartRowIdx = -1) or (EndRowIdx = -1) then
  begin
    if ListView1.TopItem <> nil then
    begin
      if StartRowIdx = -1 then
        StartRowIdx := ListView1.TopItem.Index;
      if EndRowIdx = -1 then
        EndRowIdx := ListView1.Items.Count - 1;
    end;
  end;

  if StartRowIdx > EndRowIdx then
  begin
    Tmp := StartRowIdx;
    StartRowIdx := EndRowIdx;
    EndRowIdx := Tmp;
  end;

  if StartRowIdx < 0 then
    StartRowIdx := 0;
  if EndRowIdx >= ListView1.Items.Count then
    EndRowIdx := ListView1.Items.Count - 1;

  Col0Width := ListView1.Columns[0].Width;
  ScrollOffset := GetScrollPos(ListView1.Handle, SB_HORZ);
  OriginX := Col0Width + COL1_LEFT_INSET - ScrollOffset;

  SelLeft := R.Left;
  SelRight := R.Right;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(ListView1.Font);
    dCharWidth := Bmp.Canvas.TextWidth(StringOfChar('W', 100)) / 100.0;
    if dCharWidth < 1.0 then
      dCharWidth := 8.0;

    ClipWide := '';
    for i := StartRowIdx to EndRowIdx do
    begin
      TmpIdx := FileLineIndexFromListRow(i);
      if TmpIdx < 0 then
        LineS := ''
      else
      begin
        LineS := GetLineContent(TmpIdx);
        j := 1;
        while j <= Length(LineS) do
          if LineS[j] = #0 then
            Delete(LineS, j, 1)
          else
            Inc(j);
      end;

      if Length(LineS) > LONG_LINE_THRESH then
      begin
        PixelTextStart := (SelLeft + ScrollOffset) - Col0Width - COL1_LEFT_INSET;
        PixelTextEnd := (SelRight + ScrollOffset) - Col0Width - COL1_LEFT_INSET;
        if PixelTextStart < 0 then
          PixelTextStart := 0;
        if PixelTextEnd < 0 then
          PixelTextEnd := 0;
        StartCharIdx := Round(PixelTextStart / dCharWidth) + 1;
        EndCharIdx := Round(PixelTextEnd / dCharWidth) + 1;
        if StartCharIdx < 1 then
          StartCharIdx := 1;
        CopyLen := EndCharIdx - StartCharIdx;
        if CopyLen <= 0 then
          CopyLen := 1;
        if StartCharIdx > Length(LineS) then
          BlockS := StringOfChar(' ', CopyLen)
        else
        begin
          BlockS := Copy(LineS, StartCharIdx, CopyLen);
          if Length(BlockS) < CopyLen then
            BlockS := BlockS + StringOfChar(' ', CopyLen - Length(BlockS));
        end;
      end
      else
      begin
        FirstIdx := FirstCharFromPixel(LineS, SelLeft);
        LastIdx := LastCharToPixel(LineS, SelRight);
        if (FirstIdx > LastIdx) or (FirstIdx > Length(LineS)) or (LastIdx < 1) then
          BlockS := ''
        else
        begin
          if FirstIdx < 1 then
            FirstIdx := 1;
          if LastIdx > Length(LineS) then
            LastIdx := Length(LineS);
          BlockS := Copy(LineS, FirstIdx, LastIdx - FirstIdx + 1);
        end;
      end;

      if ClipWide <> '' then
        ClipWide := ClipWide + WideString(#13#10);
      ClipWide := ClipWide + WideString(BlockS);
    end;

    if ClipWide <> '' then
    begin
      ClipboardSetUnicodeText(ClipWide);
      FirstLineNo := FileLineIndexFromListRow(StartRowIdx) + 1;
      LastLineNo := FileLineIndexFromListRow(EndRowIdx) + 1;
      { Mesmo padrao de CopyListViewFocusedLineToClipboard / CopyMultiSelectionToClipboard (CP1252). }
      if StartRowIdx = EndRowIdx then
        ShowMessage(Format(
          'A selecao vertical (linha %d) foi copiada para a '#$E1'rea de transfer'#$EA'ncia.',
          [FirstLineNo]))
      else
        ShowMessage(Format(
          'Selecao vertical: linhas %d-%d copiadas para a '#$E1'rea de transfer'#$EA'ncia.',
          [FirstLineNo, LastLineNo]));
    end;
  finally
    Bmp.Free;
  end;
end;

procedure TfrmMain.DrawSelectionRect;
var
  L, T, W, H: Integer;
  R: TRect;
begin
  L := Min(FBlockStartPoint.X, FBlockEndPoint.X);
  T := Min(FBlockStartPoint.Y, FBlockEndPoint.Y);
  W := Abs(FBlockEndPoint.X - FBlockStartPoint.X);
  H := Abs(FBlockEndPoint.Y - FBlockStartPoint.Y);
  
  R := Rect(L, T, L + W, T + H);

  ListView1.Canvas.Brush.Style := bsClear;
  ListView1.Canvas.Pen.Color   := clHighlight;
  ListView1.Canvas.Pen.Style   := psSolid;
  ListView1.Canvas.Pen.Width   := 1;
  ListView1.Canvas.Pen.Mode    := pmCopy;

  ListView1.Canvas.Rectangle(R);
end;

// Helper: Usa API do Windows para descobrir o indice exato sob o mouse
// Isso corrige o erro de deslocamento causado por cabecalhos e scroll
function TfrmMain.GetRowIndexAt(X, Y: Integer): Integer;
var
  HitInfo: TLVHitTestInfo;
begin
  // Forca X para uma area segura (dentro da coluna 0 ou 1) para garantir o HitTest
  // Se clicarmos no "vazio" a direita, o HitTest falha, mas a linha ainda existe.
  // Entao usamos a coluna 0 (width aprox) para checar a linha.
  if ListView1.Columns.Count > 0 then
    HitInfo.pt.x := ListView1.Columns[0].Width + 5
  else
    HitInfo.pt.x := 20;
    
  HitInfo.pt.y := Y;
  HitInfo.flags := LVHT_ONITEM; // Queremos pegar o item
  
  Result := SendMessage(ListView1.Handle, LVM_HITTEST, 0, Longint(@HitInfo));
end;

procedure TfrmMain.ApplyListViewWheelZoom(const WheelDelta: Integer);
const
  WHEEL_ONE_NOTCH = 120;
  ZOOM_MIN_PERCENT = 50;
  ZOOM_MAX_PERCENT = 200;
var
  Step, Pct, EffectivePct: Integer;
begin
  if not Assigned(ListView1) then Exit;
  if FListViewZoomBaseFontSize <= 0 then
    FListViewZoomBaseFontSize := Max(1, ListView1.Font.Size);
  if WheelDelta = 0 then Exit;
  Step := WheelDelta div WHEEL_ONE_NOTCH;
  if Step = 0 then
    Step := Sign(WheelDelta);
  { Roda para cima (delta > 0 tipico) -> diminui zoom; para baixo -> aumenta. }
  Pct := Round((100.0 * ListView1.Font.Size) / FListViewZoomBaseFontSize);
  if Pct < ZOOM_MIN_PERCENT then Pct := ZOOM_MIN_PERCENT;
  if Pct > ZOOM_MAX_PERCENT then Pct := ZOOM_MAX_PERCENT;
  Pct := Pct - (Step * 5);
  ApplyListViewZoomPercent(Pct);
  EffectivePct := Round((100.0 * ListView1.Font.Size) / Max(1, FListViewZoomBaseFontSize));
  RememberWheelZoomInCombo(EffectivePct, True);
end;

procedure TfrmMain.HookedListViewWndProc(var Message: TMessage);
var
  WheelDelta: Integer;
  Keys: Word;
begin
  if Message.Msg = WM_MOUSEWHEEL then
  begin
    Keys := LoWord(Message.WParam);
    WheelDelta := SmallInt(HiWord(Message.WParam));
    if (((Keys and MK_CONTROL) <> 0) or (GetKeyState(VK_CONTROL) < 0)) and (WheelDelta <> 0) then
    begin
      ApplyListViewWheelZoom(WheelDelta);
      Message.Result := 1;
      Exit;
    end;
  end;

  if Assigned(FOldListViewWndProc) then
    FOldListViewWndProc(Message);

  if (Message.Msg = WM_PAINT) and (FHasSelection) then
  begin
    DrawSelectionRect;
  end;
end;

//vertical selection
procedure TfrmMain.ListView1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if FIsDragging then
  begin
    FBlockEndPoint := Point(X, Y);
    ListView1.Repaint; 
  end;
end;

//vertical selection
procedure TfrmMain.ListView1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FIsDragging then
  begin
    FIsDragging := False;
    ReleaseCapture; 
    FBlockEndPoint := Point(X, Y);
    ListView1.Repaint;
  end;
  UpdateInfoPanels;
end;

//vertical selection
procedure TfrmMain.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  { Todos os atalhos nomeados (Ctrl+X, F-keys etc.) ja sao roteados por
    FormKeyDown via KeyPreview=True. Aqui so atualizamos os paineis para
    teclas de navegacao (setas etc.) nao consumidas pelo Form. }
  if Key = 0 then Exit;
  UpdateInfoPanels;
end;

//vertical selection
procedure TfrmMain.ListView1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   // 1) NOVO: selecao multipla SOMENTE se (Ctrl) + clique na 1a coluna (Line #)
  if (Button = mbLeft) and (ssCtrl in Shift) and IsClickInFirstColumn(X) then
  begin
    // Se havia selecao vertical ativa, limpa para nao "misturar" modos
    if FHasSelection then
    begin
      FHasSelection := False;
      FIsDragging := False;
      if GetCapture = ListView1.Handle then ReleaseCapture;
      ListView1.Repaint;
    end;
    // Deixa o proprio ListView (MultiSelect=True) alternar selecao do item
    Exit;
  end;
  // 2) Selecao vertical (existente): Ctrl/Alt + arrastar em qualquer coluna (exceto o caso acima)
  if (Button = mbLeft) and ((ssCtrl in Shift) or (ssAlt in Shift)) then
  begin
    FHasSelection := True;
    FIsDragging := True;
    
    SetCapture(ListView1.Handle); 
    if ListView1.CanFocus then ListView1.SetFocus;
    
    FBlockStartPoint := Point(X, Y);
    FBlockEndPoint := Point(X, Y);
    // Para nao misturar com selecao multipla do ListView
    ListView1.Selected := nil; 
    ListView1.Repaint; 
  end
  else
  begin
    if FHasSelection then
    begin
      FHasSelection := False;
      FIsDragging := False;
      if GetCapture = ListView1.Handle then ReleaseCapture;
      ListView1.Repaint;
    end;
  end;
end;

function ModifierKeyState(Shift: TShiftState): TModifierKeyState;
const
  AllModifierKeys = [low(TModifierKey)..high(TModifierKey)];
begin
  Result := AllModifierKeys*Shift;
end;

function GenericMouseWheelCheckListBox(Handle: HWND; Shift: TShiftState; WheelDirection: TMouseWheelDirection): Boolean;
var
  i, ScrollCount, Direction: Integer;
  Paging: Boolean;
  idx: Integer;
begin
  // Ctrl + roda no modo checklist deve aplicar o mesmo zoom da ListView.
  if GetKeyState(VK_CONTROL) < 0 then
  begin
    if WheelDirection = mwdUp then
      frmMain.ApplyListViewWheelZoom(120)
    else
      frmMain.ApplyListViewWheelZoom(-120);
    Result := True;
    Exit;
  end;

  // Alt pressionado (ou durante arrasto): nao propagar wheel.
  if (GetKeyState(VK_MENU) < 0)
     or (GetKeyState(VK_LBUTTON) < 0) or (GetCapture <> 0) then
  begin
    Result := True; // marca como tratado para nao propagar
    Exit;
  end;

  if not Assigned(FCheckListBox) then Exit;
  idx := FCheckListBox.ItemIndex;
  Result := ModifierKeyState(Shift)=[];//only respond to un-modified wheel actions
  if Result then begin
    Paging := DWORD(Mouse.WheelScrollLines) = WHEEL_PAGESCROLL;
    ScrollCount := Mouse.WheelScrollLines;
    case WheelDirection of
    mwdUp:
      if Paging then
      begin
        Direction := SB_PAGEUP;
        ScrollCount := 1;
        (* mainForm.ScrollBarVertical.Position := mainForm.ScrollBarVertical.Position - 1;
        mainForm.ScrollBarVerticalScroll(mainForm, scPageUp, fScrollPos);
        mainForm.showChecked; *)
      end
      else
      begin
        Direction := SB_LINEUP;
        //if mainForm.ScrollBarVertical.Position = 0 then Exit;
        FCheckListBox.Items.BeginUpdate;
        try
          frmMain.ScrollBarVertical.Position := frmMain.ScrollBarVertical.Position - 1;
          frmMain.ScrollBarVerticalScroll(frmMain, scLineUp, fScrollPos);
        finally
          FCheckListBox.Items.EndUpdate;
        end;
        //mainForm.showChecked;
      end;
    mwdDown:
      if Paging then
      begin
        Direction := SB_PAGEDOWN;
        ScrollCount := 1;
        (* mainForm.ScrollBarVertical.Position := mainForm.ScrollBarVertical.Position + 1;
        mainForm.ScrollBarVerticalScroll(mainForm, scPageDown, fScrollPos);
        mainForm.showChecked; *)
      end
      else
      begin
        Direction := SB_LINEDOWN;
        FCheckListBox.Items.BeginUpdate;
        try
          frmMain.ScrollBarVertical.Position := frmMain.ScrollBarVertical.Position + 1;
          frmMain.ScrollBarVerticalScroll(frmMain, scLineDown, fScrollPos);
        finally
          FCheckListBox.Items.EndUpdate;
        end;  
       // mainForm.showChecked;
      end;
    end;
    FCheckListBox.ItemIndex := idx;
    FCheckListBox.Click;
    for i := 1 to ScrollCount do
    begin
      SendMessage(frmMain.ScrollBarVertical.Handle, WM_VSCROLL, Direction, 0);
    end;
  end;
end;

{ TCheckListBox }

constructor TCheckListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TCheckListBox.Destroy;
begin
  inherited Destroy;
end;

function TCheckListBox.DoMouseWheelDown(Shift: TShiftState;
  MousePos: TPoint): Boolean;
begin
  //don't call inherited
  Result := GenericMouseWheelCheckListBox(Handle, Shift, mwdDown);
end;

function TCheckListBox.DoMouseWheelUp(Shift: TShiftState;
  MousePos: TPoint): Boolean;
begin
  //don't call inherited
  Result := GenericMouseWheelCheckListBox(Handle, Shift, mwdUp);
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  AdjustListViewColumnsWidth;
  LayoutLanguageCombo;
  LayoutViewEncodingCombo;
  LayoutZoomCombo;
  if isChecked and Assigned(FCheckListBox) and FFastVisualWordWrap then
    FCheckListBox.Invalidate;
end;

procedure TfrmMain.AdjustListViewColumnsWidth;
var
  TotalW, Col0W, NewW: Integer;
const
  { Margem entre colunas / borda interna: evita Col0+Col1 > ClientWidth (scrollbar H sem necessidade). }
  COL_EDGE_MARGIN = 6;
begin
  // Coluna 0 (numeracao) permanece fixa; coluna 1 ocupa so o espaco util restante (nunca "sobra" largura).
  if (ListView1 = nil) or (ListView1.Columns.Count < 2) then Exit;

  TotalW := ListView1.ClientWidth;
  Col0W := ListView1.Columns[0].Width;
  NewW := TotalW - Col0W - COL_EDGE_MARGIN;
  if NewW < 1 then
    NewW := 1;
  ListView1.Columns[1].Width := NewW;
end;

procedure TfrmMain.editFile(const AInitialOp: TOperationType);
var
  Op: TOperationType;
  LineNum: Int64;
  LineIdx: Integer;
  CurrentContent, OriginalContent: String;
begin
  if ListviewIsEmpty then Exit;
  if not EnsureWritableSession then Exit;
  if isChecked and Assigned(FCheckListBox) then
  begin
    if FCheckListBox.ItemIndex < 0 then Exit;
    LineNum := Integer(FCheckListBox.Items.Objects[FCheckListBox.ItemIndex]);
    if LineNum < 1 then Exit;
    LineIdx := LineNum - 1;
  end
  else
  begin
    if ListView1.ItemIndex = -1 then Exit;
    LineIdx := FileLineIndexFromListRow(ListView1.ItemIndex);
    if LineIdx < 0 then Exit;
    LineNum := LineIdx + 1;
  end;

  // 1. Fetch Data (linha real no ficheiro; com filtro na ListView = FileLineIndexFromListRow)
  OriginalContent := GetLineContent(LineIdx);
  CurrentContent := OriginalContent; 
  
  Op := AInitialOp;
  
  // 2. Open Modal
  // If user clicks OK, but nothing changed, Execute returns FALSE (Optimization)
  if TfrmLineEditor.Execute(Op, LineNum, CurrentContent) then
  begin
    if not EnsureOpenFileNotStaleForMutate then Exit;
    CloseFileStreams;
    TEditFileThread.Create(edtFileName.Text, Op, LineNum, CurrentContent);
  end;
end;

procedure TfrmMain.btnEditFileClick(Sender: TObject);
begin
  editFile;
end;

procedure TfrmMain.ListView1DblClick(Sender: TObject);
begin
  editFile;
end;

procedure TfrmMain.exportFile;
var
  Params: String;
  SaveToFile: Boolean;
  OutFile: String;
begin
  if ListviewIsEmpty then Exit;
  if (existsCheckedRows(FCheckedLines)) then
  begin
    exportToClipBoard;
    Exit;
  end;

  if TfrmExportDialog.Execute(Params, SaveToFile) then
  begin
    OutFile := '';
    if SaveToFile then
    begin
      if not SaveDialog1.Execute then Exit;
      OutFile := SaveDialog1.FileName;
    end;
    TExportFileThread.Create(Params, SaveToFile, OutFile, edtFileName.Text, totalLines);
  end;
end;

procedure TfrmMain.ExportFilteredResults;
var
  Params: String;
  SaveToFile: Boolean;
  OutFile: String;
  I, RealIdx, j: Integer;
  LineS: string;
  ClipWide: WideString;
  SL: TStringList;
begin
  if not FFilterActive then
  begin
    ShowMessage('No active filter. Press Ctrl+L first.');
    Exit;
  end;
  if FFilteredCount <= 0 then
  begin
    ShowMessage('Filter has no results to export.');
    Exit;
  end;

  Params := '';
  if not TfrmExportDialog.Execute(Params, SaveToFile) then Exit;

  if SaveToFile then
  begin
    if not SaveDialog1.Execute then Exit;
    OutFile := SaveDialog1.FileName;
    SL := TStringList.Create;
    try
      SL.BeginUpdate;
      try
        for I := 0 to Integer(FFilteredCount) - 1 do
        begin
          RealIdx := Integer(FilteredIndexToReal(I));
          if RealIdx < 0 then Continue;
          LineS := GetLineContent(RealIdx);
          j := 1;
          while j <= Length(LineS) do
            if LineS[j] = #0 then
              Delete(LineS, j, 1)
            else
              Inc(j);
          SL.Add(LineS);
        end;
      finally
        SL.EndUpdate;
      end;
      SL.SaveToFile(OutFile);
    finally
      SL.Free;
    end;
    ShowMessage(Format('%d linhas filtradas exportadas para arquivo.', [FFilteredCount]));
  end
  else
  begin
    ClipWide := '';
    for I := 0 to Integer(FFilteredCount) - 1 do
    begin
      RealIdx := Integer(FilteredIndexToReal(I));
      if RealIdx < 0 then Continue;
      LineS := GetLineContent(RealIdx);
      j := 1;
      while j <= Length(LineS) do
        if LineS[j] = #0 then
          Delete(LineS, j, 1)
        else
          Inc(j);
      if ClipWide <> '' then
        ClipWide := ClipWide + WideString(#13#10);
      ClipWide := ClipWide + WideString(LineS);
    end;
    if ClipWide <> '' then
      ClipboardSetUnicodeText(ClipWide);
    ShowMessage(Format('%d linhas filtradas copiadas para a '#$E1'rea de transfer'#$EA'ncia.', [FFilteredCount]));
  end;
end;

procedure TfrmMain.CopyMultiSelectionToClipboard;
var
  Item: TListItem;
  CopiedCount: Integer;
  FirstFileLineIdx, LineIdx: Integer;
  LineS: string;
  ClipWide: WideString;
  j: Integer;
begin
  if (ListView1 = nil) or (ListView1.SelCount = 0) then Exit;

  CopiedCount := 0;
  FirstFileLineIdx := -1;
  ClipWide := '';

  Item := ListView1.Selected;
  while Item <> nil do
  begin
    LineIdx := FileLineIndexFromListRow(Item.Index);
    if LineIdx < 0 then
    begin
      Item := ListView1.GetNextItem(Item, sdAll, [isSelected]);
      Continue;
    end;

    if FirstFileLineIdx < 0 then
      FirstFileLineIdx := LineIdx;

    LineS := GetLineContent(LineIdx);
    j := 1;
    while j <= Length(LineS) do
      if LineS[j] = #0 then
        Delete(LineS, j, 1)
      else
        Inc(j);

    if ClipWide <> '' then
      ClipWide := ClipWide + WideString(#13#10);
    ClipWide := ClipWide + WideString(LineS);
    Inc(CopiedCount);

    Item := ListView1.GetNextItem(Item, sdAll, [isSelected]);
  end;

  if CopiedCount > 0 then
  begin
    ClipboardSetUnicodeText(ClipWide);
    if CopiedCount = 1 then
      { CP1252 via #$xx: acentos estaveis mesmo com fonte .pas em UTF-8 no D7 }
      ShowMessage(Format('A linha %d foi copiada para a '#$E1'rea de transfer'#$EA'ncia.',
        [FirstFileLineIdx + 1]))
    else
      ShowMessage(Format('%d linhas foram copiadas para a '#$E1'rea de transfer'#$EA'ncia.',
        [CopiedCount]));
  end;
end;

function TfrmMain.FileLineIndexFromListRow(const RowIdx: Integer): Integer;
var
  R: Int64;
begin
  Result := -1;
  if RowIdx < 0 then Exit;
  if FFilterActive then
  begin
    R := FilteredIndexToReal(RowIdx);
    if R < 0 then Exit;
    Result := Integer(R);
  end
  else
    Result := Integer(Offset + Int64(RowIdx));
end;

procedure TfrmMain.CopyFileLineToClipboard(const LineIdx: Integer);
var
  LineS: string;
  j: Integer;
begin
  if LineIdx < 0 then Exit;
  if not Assigned(FSourceFileStream) then Exit;

  LineS := GetLineContent(LineIdx);
  j := 1;
  while j <= Length(LineS) do
    if LineS[j] = #0 then
      Delete(LineS, j, 1)
    else
      Inc(j);

  ClipboardSetUnicodeText(WideString(LineS));
  ShowMessage(Format('A linha %d foi copiada para a '#$E1'rea de transfer'#$EA'ncia.', [LineIdx + 1]));
end;

procedure TfrmMain.CopyChecklistVerticalSelectionToClipboard;
const
  LONG_LINE_THRESH = 80000;
  CHECKBOX_SCALE_PCT = 85;
  CHECKBOX_LEFT_PAD  = 2;
  CHECKBOX_TEXT_GAP  = 6;
var
  StartRowIdx, EndRowIdx: Integer;
  SelLeft, SelRight: Integer;
  I, Tmp, Line1Based, LineIdx, j: Integer;
  FullStr, LineS, BlockS: string;
  ClipWide: WideString;
  Bmp: TBitmap;
  FirstIdx, LastIdx: Integer;
  dCharWidth: Double;
  PixelTextStart, PixelTextEnd: Integer;
  CopyLen, StartCharIdx, EndCharIdx: Integer;
  FirstLineNo, LastLineNo: Integer;
  OriginXBase, OriginX, CkW, PrefixLen: Integer;
  ItemH, TopIdx: Integer;
  SelTopY, SelBottomY: Integer;

  function PrefixW(const S: string; N: Integer): Integer;
  begin
    if N <= 0 then Result := 0
    else Result := Bmp.Canvas.TextWidth(Copy(S, 1, N));
  end;

  function FirstCharFromPixel(const S: string; const SelL: Integer): Integer;
  var
    Lo, Hi, Mid, Lc: Integer;
  begin
    Lc := Length(S);
    if Lc = 0 then begin Result := 1; Exit; end;
    if OriginX + PrefixW(S, Lc) < SelL then begin Result := Lc + 1; Exit; end;
    Lo := 1; Hi := Lc;
    while Lo < Hi do
    begin
      Mid := (Lo + Hi) div 2;
      if OriginX + PrefixW(S, Mid) < SelL then Lo := Mid + 1
      else Hi := Mid;
    end;
    Result := Lo;
  end;

  function LastCharToPixel(const S: string; const SelR: Integer): Integer;
  var
    Lo, Hi, Mid, Lc: Integer;
  begin
    Lc := Length(S); Result := 0;
    if Lc = 0 then Exit;
    if OriginX > SelR then Exit;
    Lo := 1; Hi := Lc;
    while Lo < Hi do
    begin
      Mid := (Lo + Hi + 1) div 2;
      if OriginX + PrefixW(S, Mid - 1) <= SelR then Lo := Mid
      else Hi := Mid - 1;
    end;
    Result := Lo;
  end;

begin
  if not FHasSelection then Exit;
  if not Assigned(FCheckListBox) or (FCheckListBox.Items.Count = 0) then Exit;

  { Mapeamento estrito da faixa vertical para linhas visiveis:
    TopIndex + Y div ItemHeight (faixa [Top,Bottom) evita incluir linha de cima na borda). }
  ItemH := Max(1, FCheckListBox.ItemHeight);
  TopIdx := FCheckListBox.TopIndex;
  SelTopY := Min(FBlockStartPoint.Y, FBlockEndPoint.Y);
  SelBottomY := Max(FBlockStartPoint.Y, FBlockEndPoint.Y);
  if SelTopY < 0 then SelTopY := 0;
  if SelBottomY < 1 then SelBottomY := 1;
  if SelTopY >= FCheckListBox.ClientHeight then SelTopY := FCheckListBox.ClientHeight - 1;
  if SelBottomY > FCheckListBox.ClientHeight then SelBottomY := FCheckListBox.ClientHeight;
  StartRowIdx := TopIdx + (SelTopY div ItemH);
  EndRowIdx   := TopIdx + ((SelBottomY - 1) div ItemH);
  if StartRowIdx > EndRowIdx then
  begin
    Tmp := StartRowIdx; StartRowIdx := EndRowIdx; EndRowIdx := Tmp;
  end;
  if StartRowIdx < 0 then StartRowIdx := 0;
  if EndRowIdx >= FCheckListBox.Items.Count then EndRowIdx := FCheckListBox.Items.Count - 1;

  SelLeft  := Min(FBlockStartPoint.X, FBlockEndPoint.X);
  SelRight := Max(FBlockStartPoint.X, FBlockEndPoint.X);
  { Ajuste fino: evita capturar 1 caractere extra a esquerda na checklist. }
  Inc(SelLeft);
  if SelRight <= SelLeft then Inc(SelRight);

  { OriginXBase = pixel de inicio do texto apos checkbox — identico ao CheckListBox1DrawItem. }
  CkW := GetSystemMetrics(SM_CXMENUCHECK);
  CkW := (CkW * CHECKBOX_SCALE_PCT) div 100;
  if CkW < 9 then CkW := 9;
  OriginXBase := CHECKBOX_LEFT_PAD + CkW + CHECKBOX_TEXT_GAP + 2;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FCheckListBox.Font);
    dCharWidth := Bmp.Canvas.TextWidth(StringOfChar('W', 100)) / 100.0;
    if dCharWidth < 1.0 then dCharWidth := 8.0;

    ClipWide := '';
    for I := StartRowIdx to EndRowIdx do
    begin
      Line1Based := Integer(FCheckListBox.Items.Objects[I]);
      FullStr    := FCheckListBox.Items[I];

      if Line1Based <= 0 then
      begin
        LineS    := '';
        PrefixLen := 0;
        OriginX  := OriginXBase;
      end
      else
      begin
        LineIdx := Line1Based - 1;
        { getLineContentsFromLineIndex — mesma funcao e scroll horizontal que showChecked usou. }
        LineS := getLineContentsFromLineIndex(LineIdx);
        j := 1;
        while j <= Length(LineS) do
          if LineS[j] = #0 then Delete(LineS, j, 1) else Inc(j);
        { PrefixLen derivado do item real — evita recomputar IsBookmarked ou FormatFloat. }
        PrefixLen := Length(FullStr) - Length(LineS);
        if PrefixLen < 0 then PrefixLen := 0;
        { OriginX por linha: OriginXBase + largura do prefixo em pixels.
          Identico a como CopyVerticalSelectionToClipboard usa Col0Width para separar colunas. }
        OriginX := OriginXBase + Bmp.Canvas.TextWidth(Copy(FullStr, 1, PrefixLen));
      end;

      { Busca binaria em LineS com OriginX por linha — identico a CopyVerticalSelectionToClipboard. }
      if Length(LineS) > LONG_LINE_THRESH then
      begin
        PixelTextStart := SelLeft  - OriginX;
        PixelTextEnd   := SelRight - OriginX;
        if PixelTextStart < 0 then PixelTextStart := 0;
        if PixelTextEnd   < 0 then PixelTextEnd   := 0;
        StartCharIdx := Round(PixelTextStart / dCharWidth) + 1;
        EndCharIdx   := Round(PixelTextEnd   / dCharWidth) + 1;
        if StartCharIdx < 1 then StartCharIdx := 1;
        CopyLen := EndCharIdx - StartCharIdx;
        if CopyLen <= 0 then CopyLen := 1;
        if StartCharIdx > Length(LineS) then
          BlockS := StringOfChar(' ', CopyLen)
        else
        begin
          BlockS := Copy(LineS, StartCharIdx, CopyLen);
          if Length(BlockS) < CopyLen then
            BlockS := BlockS + StringOfChar(' ', CopyLen - Length(BlockS));
        end;
      end
      else
      begin
        FirstIdx := FirstCharFromPixel(LineS, SelLeft);
        LastIdx  := LastCharToPixel(LineS, SelRight);
        if (FirstIdx > LastIdx) or (FirstIdx > Length(LineS)) or (LastIdx < 1) then
          BlockS := ''
        else
        begin
          if FirstIdx < 1 then FirstIdx := 1;
          if LastIdx > Length(LineS) then LastIdx := Length(LineS);
          BlockS := Copy(LineS, FirstIdx, LastIdx - FirstIdx + 1);
        end;
      end;

      if ClipWide <> '' then
        ClipWide := ClipWide + WideString(#13#10);
      ClipWide := ClipWide + WideString(BlockS);
    end;

    if ClipWide <> '' then
    begin
      ClipboardSetUnicodeText(ClipWide);
      FirstLineNo := Integer(FCheckListBox.Items.Objects[StartRowIdx]);
      LastLineNo  := Integer(FCheckListBox.Items.Objects[EndRowIdx]);
      if StartRowIdx = EndRowIdx then
        ShowMessage(Format(
          'A selecao vertical (linha %d) foi copiada para a '#$E1'rea de transfer'#$EA'ncia.',
          [FirstLineNo]))
      else
        ShowMessage(Format(
          'Selecao vertical: linhas %d-%d copiadas para a '#$E1'rea de transfer'#$EA'ncia.',
          [FirstLineNo, LastLineNo]));
    end;
  finally
    Bmp.Free;
  end;
end;

procedure TfrmMain.CopyCheckedChecklistLinesToClipboard;
var
  I, Line1Based, LineIdx, CopiedCount: Integer;
  LineS: string;
  ClipWide: WideString;
  j: Integer;
begin
  if not Assigned(FSourceFileStream) then Exit;

  ClipWide := '';
  CopiedCount := 0;

  { Preferir o estado global das linhas marcadas (inclui marcacoes fora da janela visivel). }
  if Assigned(FCheckedLines) and (FCheckedLines.Count > 0) then
  begin
    for I := 0 to FCheckedLines.Count - 1 do
    begin
      Line1Based := Integer(FCheckedLines.Items[I]);
      if Line1Based <= 0 then Continue;
      LineIdx := Line1Based - 1;
      if not LineExists(LineIdx) then Continue;

      LineS := GetLineContent(LineIdx);
      j := 1;
      while j <= Length(LineS) do
        if LineS[j] = #0 then
          Delete(LineS, j, 1)
        else
          Inc(j);

      if ClipWide <> '' then
        ClipWide := ClipWide + WideString(#13#10);
      ClipWide := ClipWide + WideString(LineS);
      Inc(CopiedCount);
    end;
  end
  else if Assigned(FCheckListBox) then
  begin
    { Fallback: somente itens marcados atualmente visiveis. }
    for I := 0 to FCheckListBox.Items.Count - 1 do
      if FCheckListBox.Checked[I] then
      begin
        Line1Based := Integer(FCheckListBox.Items.Objects[I]);
        if Line1Based <= 0 then Continue;
        LineIdx := Line1Based - 1;
        if not LineExists(LineIdx) then Continue;

        LineS := GetLineContent(LineIdx);
        j := 1;
        while j <= Length(LineS) do
          if LineS[j] = #0 then
            Delete(LineS, j, 1)
          else
            Inc(j);

        if ClipWide <> '' then
          ClipWide := ClipWide + WideString(#13#10);
        ClipWide := ClipWide + WideString(LineS);
        Inc(CopiedCount);
      end;
  end;

  if CopiedCount > 0 then
  begin
    ClipboardSetUnicodeText(ClipWide);
    if CopiedCount = 1 then
      ShowMessage('1 linha marcada foi copiada para a '#$E1'rea de transfer'#$EA'ncia.')
    else
      ShowMessage(Format('%d linhas marcadas foram copiadas para a '#$E1'rea de transfer'#$EA'ncia.', [CopiedCount]));
  end;
end;

procedure TfrmMain.CopyListViewFocusedLineToClipboard;
var
  RowIdx, LineIdx: Integer;
begin
  if (ListView1 = nil) or ListviewIsEmpty then Exit;
  RowIdx := ListView1.ItemIndex;
  if RowIdx < 0 then Exit;

  LineIdx := FileLineIndexFromListRow(RowIdx);
  if LineIdx < 0 then Exit;
  CopyFileLineToClipboard(LineIdx);
end;

function TfrmMain.IsClickInFirstColumn(X: Integer): Boolean;
var
  Col0Width, ScrollOffset: Integer;
  AbsX: Integer;
begin
  if (ListView1 = nil) or (ListView1.Columns.Count = 0) then
  begin
    Result := False;
    Exit;
  end;

  ScrollOffset := GetScrollPos(ListView1.Handle, SB_HORZ);
  AbsX := X + ScrollOffset;
  Col0Width := ListView1.Columns[0].Width;

  Result := AbsX <= Col0Width;
end;

procedure TfrmMain.RefreshFile;
begin
  BeginRead;
end;

procedure TfrmMain.UpdateFindSearchProgress(const BytesDone, TotalBytes: Int64);
begin
  if TotalBytes <= 0 then Exit;
  UpdateStatusBar(TrText('Searching') + ' ' + UnUtils.FormatNumber(BytesDone) + ' / ' +
    UnUtils.FormatNumber(TotalBytes) + ' B', iaRight);
end;

procedure TfrmMain.CaptureOpenFileDiskSnapshot;
var
  P: string;
begin
  FOpenDiskSnapValid := False;
  FOpenDiskSnapPath := '';
  FOpenDiskSnapSize := 0;
  FillChar(FOpenDiskSnapWrite, SizeOf(FOpenDiskSnapWrite), 0);
  P := Trim(edtFileName.Text);
  if (P = '') or SameText(P, SELECTTEXT) or (not FileExists(P)) then
    Exit;
  FOpenDiskSnapPath := ExpandFileName(P);
  UnUtils.GetFileSizeAndWriteTime(FOpenDiskSnapPath, FOpenDiskSnapSize, FOpenDiskSnapWrite);
  FOpenDiskSnapValid := True;
end;

procedure TfrmMain.InvalidateOpenFileDiskSnapshot;
begin
  FOpenDiskSnapValid := False;
  FOpenDiskSnapPath := '';
  FOpenDiskSnapSize := 0;
  FillChar(FOpenDiskSnapWrite, SizeOf(FOpenDiskSnapWrite), 0);
end;

function TfrmMain.EnsureOpenFileNotStaleForMutate: Boolean;
var
  P: string;
  R: Integer;
begin
  Result := True;
  if not FOpenDiskSnapValid then Exit;
  P := Trim(edtFileName.Text);
  if (P = '') or SameText(P, SELECTTEXT) or (not FileExists(P)) then Exit;
  if not SameText(ExpandFileName(P), FOpenDiskSnapPath) then Exit;
  if UnUtils.SameFileSizeAndWriteTime(P, FOpenDiskSnapSize, FOpenDiskSnapWrite) then Exit;

  R := Application.MessageBox(
    PChar(TrText('File changed on disk since load')),
    PChar(TrText('File changed on disk')),
    MB_YESNOCANCEL or MB_ICONWARNING);
  case R of
    IDYES:
      begin
        BeginRead;
        Result := False;
      end;
    IDNO:
      begin
        CaptureOpenFileDiskSnapshot;
        Result := True;
      end;
  else
    Result := False;
  end;
end;

function TfrmMain.EnsureWritableSession: Boolean;
begin
  Result := True;
  if not FFileSessionReadOnly then Exit;
  Application.MessageBox(
    PChar(TrText('Read-only session is enabled. Turn it off in Options to edit or save the file.')),
    PChar(TrText('Read-only')),
    MB_OK or MB_ICONINFORMATION);
  Result := False;
end;

procedure TfrmMain.ApplySessionReadOnlyUi;
begin
  if FFileSessionReadOnly and Assigned(FSourceFileStream) then
  begin
    if Assigned(btnEditFile) then btnEditFile.Enabled := False;
    if Assigned(btnDeleteLines) then btnDeleteLines.Enabled := False;
    if Assigned(btnMergeMultipleLines) then btnMergeMultipleLines.Enabled := False;
    if Assigned(btnSplitFiles) then btnSplitFiles.Enabled := False;
    UpdateStatusBar(TrText('Read-only session'), iaRight);
  end
  else if Assigned(FSourceFileStream) then
  begin
    UnUtils.ActionComponent([btnRead, btnClear, btnDeleteLines, btnSplitFiles, btnMergeMultipleLines,
      btnCheckBoxes, btnExport, btnEditFile], acEnabled);
  end;
end;

procedure TfrmMain.miToggleReadOnlyClick(Sender: TObject);
begin
  FFileSessionReadOnly := not FFileSessionReadOnly;
  if Assigned(FMenuReadOnlyItem) then
    FMenuReadOnlyItem.Checked := FFileSessionReadOnly;
  if Assigned(FPopupLVReadOnlyItem) then
    FPopupLVReadOnlyItem.Checked := FFileSessionReadOnly;
  if Assigned(FToolsExtrasReadOnly) then
    FToolsExtrasReadOnly.Checked := FFileSessionReadOnly;
  ApplySessionReadOnlyUi;
end;

procedure TfrmMain.miToggleSegmentedHeavyOpsClick(Sender: TObject);
begin
  EnsureReadTabVisible;
  if not Assigned(chkSegmentedHeavyOps) then Exit;
  chkSegmentedHeavyOps.Checked := not chkSegmentedHeavyOps.Checked;
  chkSegmentedHeavyOpsClick(chkSegmentedHeavyOps);
end;

{ ============================================================================ }
{ TFindInFileThread Implementation                                             }
{ ============================================================================ }

constructor TFindInFileThread.Create(AOwner: TfrmMain; const AFileName, AIndexFileName: string;
  const ANeedle: string; ACaseSensitive: Boolean; const AStartPos: Int64;
  const ADirection: Integer; const ASearchId: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  Priority := tpLower;
  FOwner := AOwner;
  FFileName := AFileName;
  FIndexFileName := AIndexFileName;
  FNeedle := AnsiString(ANeedle);
  FCaseSensitive := ACaseSensitive;
  FStartPos := AStartPos;
  FDirection := ADirection;
  FSearchId := ASearchId;
  FErrorMsg := '';
  if not FCaseSensitive then
    FNeedleUpper := AnsiString(AnsiUpperCase(string(FNeedle)))
  else
    FNeedleUpper := FNeedle;
  FFound := False;
  FFoundLine := -1;
  FFoundPos := -1;
  FLastFindProgressPos := -1;
  Resume;
end;

procedure TFindInFileThread.NotifyOwner;
begin
  FOwner.FindThreadDone(FFound, FFoundLine, FFoundPos, FSearchId, FErrorMsg);
end;

procedure TFindInFileThread.SyncFindBytesProgress;
begin
  if Assigned(FOwner) then
    FOwner.UpdateFindSearchProgress(FProgBytes, FProgTotal);
end;

function TFindInFileThread.OffsetToLineIndex(AIndexStream: TFileStream; const APos1Based: Int64): Integer;
var
  Lo, Hi, Mid: Integer;
  TotalLines: Integer;
  OffsetStr: AnsiString;
  MidOffset: Int64;
begin
  Result := -1;
  if not Assigned(AIndexStream) then Exit;
  TotalLines := AIndexStream.Size div INDEX_RECORD_SIZE;
  if TotalLines <= 0 then Exit;
  SetLength(OffsetStr, 18);
  Lo := 0;
  Hi := TotalLines - 1;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    AIndexStream.Seek(Int64(Mid) * INDEX_RECORD_SIZE, soFromBeginning);
    AIndexStream.Read(Pointer(OffsetStr)^, 18);
    MidOffset := StrToInt64Def(Trim(string(OffsetStr)), -1);
    if MidOffset = APos1Based then
    begin
      Result := Mid;
      Exit;
    end
    else if MidOffset < APos1Based then
      Lo := Mid + 1
    else
      Hi := Mid - 1;
  end;
  // Retorna a linha mais proxima (Hi e o maior indice cujo offset <= APos1Based)
  if Hi >= 0 then
    Result := Hi
  else
    Result := 0;
end;

procedure TFindInFileThread.Execute;
const
  BUF_SIZE = 1024 * 1024;
type
  TShiftTable = array[0..255] of Integer;
var
  SourceStream: TFileStream;
  Idx: TFileStream;
  FileSize: Int64;
  NeedLen: Integer;
  CurPos: Int64;
  ReadSize: Integer;
  BytesRead: Integer;
  BufRaw: array of Byte;
  WorkBuf: array of Byte;
  Tail: array of Byte;
  TailLen: Integer;
  Shift: TShiftTable;
  Up: array[0..255] of Byte;
  Pat: array of Byte;
  PatU: array of Byte;
  FoundBaseAbs: Int64;
  CandidateAbs: Int64;
  StartIndex: Integer;
  FoundIdx: Integer;
  I, J: Integer;
  C: AnsiChar;
  B, TB: Byte;
  BaseIdx: Integer;

  procedure BuildUpTable;
  var K: Integer; Ch: AnsiChar;
  begin
    for K := 0 to 255 do begin Ch := AnsiChar(K); CharUpperBuffA(@Ch, 1); Up[K] := Byte(Ch); end;
  end;

  procedure BuildPatternBytes;
  var K: Integer;
  begin
    SetLength(Pat, NeedLen);
    SetLength(PatU, NeedLen);
    for K := 0 to NeedLen - 1 do begin
      B := Byte(AnsiChar(FNeedle[K + 1]));
      Pat[K] := B;
      PatU[K] := Up[B];
    end;
  end;

  procedure BuildShiftTable;
  var K: Integer;
  begin
    for K := 0 to 255 do Shift[K] := NeedLen;
    for K := 0 to NeedLen - 2 do begin
      if FCaseSensitive then B := Pat[K] else B := PatU[K];
      Shift[B] := (NeedLen - 1) - K;
    end;
  end;

  function BMH_FindFirst(const Buf: PByte; const BufLen: Integer; const AStartIndex: Integer): Integer;
  var II, JJ, BaseI: Integer;
  begin
    Result := -1;
    if (NeedLen <= 0) or (BufLen < NeedLen) then Exit;
    II := AStartIndex + (NeedLen - 1);
    while II < BufLen do begin
      JJ := NeedLen - 1;
      if FCaseSensitive then begin
        while (JJ >= 0) do begin
          BaseI := II - ((NeedLen - 1) - JJ);
          if PFFByteArray(Buf)^[BaseI] <> PFFByteArray(Pat)^[JJ] then Break;
          Dec(JJ);
        end;
      end else begin
        while (JJ >= 0) do begin
          BaseI := II - ((NeedLen - 1) - JJ);
          if Up[PFFByteArray(Buf)^[BaseI]] <> PFFByteArray(PatU)^[JJ] then Break;
          Dec(JJ);
        end;
      end;
      if JJ < 0 then begin Result := II - (NeedLen - 1); Exit; end;
      if FCaseSensitive then TB := PFFByteArray(Buf)^[II]
      else TB := Up[PFFByteArray(Buf)^[II]];
      Inc(II, Shift[TB]);
    end;
  end;

begin
  SourceStream := nil;
  Idx := nil;
  try
    try
      if (FNeedle = '') then Exit;
      SourceStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
      FileSize := SourceStream.Size;
      Idx := TFileStream.Create(FIndexFileName, fmOpenRead or fmShareDenyNone);
    NeedLen := Length(FNeedle);
    if NeedLen <= 0 then Exit;
    if FStartPos < 0 then FStartPos := 0;
    if FStartPos > FileSize then FStartPos := FileSize;
    BuildUpTable;
    BuildPatternBytes;
    BuildShiftTable;
    SetLength(BufRaw, BUF_SIZE);

    if FDirection >= 0 then
    begin
      CurPos := FStartPos;
      TailLen := 0;
      SetLength(Tail, 0);
      while (not Terminated) and (CurPos < FileSize) and (not FFound) do
      begin
        ReadSize := BUF_SIZE;
        if CurPos + ReadSize > FileSize then ReadSize := Integer(FileSize - CurPos);
        if ReadSize <= 0 then Break;
        SourceStream.Seek(CurPos, soFromBeginning);
        BytesRead := SourceStream.Read(BufRaw[0], ReadSize);
        if BytesRead <= 0 then Break;
        if TailLen > 0 then begin
          SetLength(WorkBuf, TailLen + BytesRead);
          Move(Tail[0], WorkBuf[0], TailLen);
          Move(BufRaw[0], WorkBuf[TailLen], BytesRead);
          FoundBaseAbs := (CurPos - TailLen);
        end else begin
          SetLength(WorkBuf, BytesRead);
          Move(BufRaw[0], WorkBuf[0], BytesRead);
          FoundBaseAbs := CurPos;
        end;
        StartIndex := 0;
        if FoundBaseAbs < FStartPos then StartIndex := Integer(FStartPos - FoundBaseAbs);
        FoundIdx := BMH_FindFirst(@WorkBuf[0], Length(WorkBuf), StartIndex);
        if FoundIdx >= 0 then begin
          CandidateAbs := FoundBaseAbs + FoundIdx;
          FFoundPos := CandidateAbs;
          FFoundLine := OffsetToLineIndex(Idx, CandidateAbs + 1);
          FFound := True;
          Break;
        end;
        if NeedLen > 1 then begin
          TailLen := NeedLen - 1;
          if TailLen > Length(WorkBuf) then TailLen := Length(WorkBuf);
          SetLength(Tail, TailLen);
          if TailLen > 0 then Move(WorkBuf[Length(WorkBuf) - TailLen], Tail[0], TailLen);
        end         else begin TailLen := 0; SetLength(Tail, 0); end;
        CurPos := CurPos + BytesRead;
        if (FileSize > 0) and ((FLastFindProgressPos < 0) or (CurPos - FLastFindProgressPos >= 2 * 1024 * 1024) or (CurPos >= FileSize)) then
        begin
          FProgBytes := CurPos;
          FProgTotal := FileSize;
          FLastFindProgressPos := CurPos;
          if not Terminated then
            Synchronize(SyncFindBytesProgress);
        end;
      end;
    end
    else
    begin
      // backward: scan blocks in reverse, find last match before FStartPos
      FLastFindProgressPos := -1;
      CurPos := FStartPos;
      while (not Terminated) and (CurPos > 0) and (not FFound) do
      begin
        ReadSize := BUF_SIZE;
        if ReadSize > CurPos then ReadSize := Integer(CurPos);
        if ReadSize <= 0 then Break;
        SourceStream.Seek(CurPos - ReadSize, soFromBeginning);
        BytesRead := SourceStream.Read(BufRaw[0], ReadSize);
        if BytesRead <= 0 then Break;
        SetLength(WorkBuf, BytesRead);
        Move(BufRaw[0], WorkBuf[0], BytesRead);
        // scan forward to find last match before FStartPos
        FoundIdx := 0;
        CandidateAbs := -1;
        while True do begin
          J := BMH_FindFirst(@WorkBuf[0], Length(WorkBuf), FoundIdx);
          if J < 0 then Break;
          if (CurPos - ReadSize + J) < FStartPos then
            CandidateAbs := CurPos - ReadSize + J;
          FoundIdx := J + 1;
        end;
        if CandidateAbs >= 0 then begin
          FFoundPos := CandidateAbs;
          FFoundLine := OffsetToLineIndex(Idx, CandidateAbs + 1);
          FFound := True;
          Break;
        end;
        CurPos := CurPos - ReadSize;
        // overlap
        if (NeedLen > 1) and (CurPos > 0) then
          CurPos := CurPos + NeedLen - 1;
        if (FileSize > 0) and ((FLastFindProgressPos < 0) or
          ((FileSize - CurPos) - FLastFindProgressPos >= 2 * 1024 * 1024) or (CurPos <= 0)) then
        begin
          FProgBytes := FileSize - CurPos;
          if FProgBytes < 0 then FProgBytes := 0;
          if FProgBytes > FileSize then FProgBytes := FileSize;
          FProgTotal := FileSize;
          FLastFindProgressPos := FileSize - CurPos;
          if not Terminated then
            Synchronize(SyncFindBytesProgress);
        end;
      end;
    end;
    except
      on E: Exception do
        FErrorMsg := E.Message;
    end;
  finally
    if Assigned(Idx) then Idx.Free;
    if Assigned(SourceStream) then SourceStream.Free;
    if not Terminated then
      Synchronize(NotifyOwner);
  end;
end;

{ ============================================================================ }
{ TFilterThread Implementation                                                 }
{ ============================================================================ }

constructor TFilterThread.Create(AOwner: TfrmMain;
  const AFileName, AIndexFileName, ANeedle: string;
  ACaseSensitive: Boolean; ATotalLines: Int64; AMatchMode: TFilterMatchMode);
var
  BitsNeeded: Int64;
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FOwner := AOwner;
  FFileName := AFileName;
  FIndexFileName := AIndexFileName;
  FMatchMode := AMatchMode;
  if FMatchMode = fmmRegex then
    FNeedle := AnsiString(ANeedle)
  else if ACaseSensitive then
    FNeedle := AnsiString(ANeedle)
  else
    FNeedle := AnsiString(AnsiUpperCase(ANeedle));
  FCaseSensitive := ACaseSensitive;
  FTotalLines := ATotalLines;
  FFilteredCount := 0;
  FAbortMsg := '';
  BitsNeeded := (ATotalLines + 7) div 8;
  { GetMem size is Integer: avoid silent wrap on huge line counts. }
  if (ATotalLines > 0) and (BitsNeeded > MaxInt) then
  begin
    FBitsSize := 0;
    FBits := nil;
    FAbortMsg := TrText('Filter: line count too large for filter memory (32-bit limit).');
  end
  else begin
    FBitsSize := Integer(BitsNeeded);
    if FBitsSize > 0 then begin
      GetMem(FBits, FBitsSize);
      FillChar(FBits^, FBitsSize, 0);
    end else
      FBits := nil;
  end;
  Resume;
end;

destructor TFilterThread.Destroy;
begin
  if Assigned(FBits) then FreeMem(FBits);
  inherited;
end;

procedure TFilterThread.NotifyOwner;
begin
  // Transfer ownership of bitset and jump table to owner
  FOwner.FFilterBits := FBits;
  FOwner.FFilterBitsSize := FBitsSize;
  FOwner.FFilteredCount := FFilteredCount;
  FOwner.FFilterTotalLines := FTotalLines;
  FOwner.FFilterJumpTable := FJumpTable;
  FBits := nil; // prevent destructor from freeing
  FOwner.FilterThreadDone;
end;

procedure TFilterThread.SyncFilterProgress;
begin
  if Assigned(FOwner) then
    FOwner.UpdateFilterBuildProgress(FProgLines, FProgTotalLines);
end;

procedure TFilterThread.SyncFilterFailed;
begin
  if Assigned(FOwner) then
    FOwner.FinishFilterThreadFailed(FAbortMsg);
end;

procedure TFilterThread.Execute;
var
  SourceStream: TFileStream;
  IndexStream: TFileStream;
  OffsetStr: AnsiString;
  StartOffset, EndOffset, FSize: Int64;
  LineLength: Integer;
  Buffer: AnsiString;
  LineContent: AnsiString;
  I: Int64;
  MatchCount: Int64;
  JumpIdx: Integer;
  ByteIdx, BitIdx: Integer;
  NeedleLen: Integer;
  Matched: Boolean;
  RegObj: OleVariant;
  RegexReady: Boolean;
  ComNeedUninit: Boolean;
  ComHr: HRESULT;
begin
  SourceStream := nil;
  IndexStream := nil;
  RegexReady := False;
  ComNeedUninit := False;

  { VBScript.RegExp exige COM nesta thread (CreateOleObject falha com "CoInitialize not called"). }
  if FMatchMode = fmmRegex then
  begin
    ComHr := CoInitialize(nil);
    if (ComHr <> S_OK) and (ComHr <> S_FALSE) then
    begin
      FAbortMsg := TrText('Could not initialize COM for the regex filter.');
      Synchronize(SyncFilterFailed);
      Exit;
    end;
    ComNeedUninit := True;
  end;

  try
    if FMatchMode = fmmRegex then
    begin
      try
        RegObj := CreateOleObject('VBScript.RegExp');
        RegObj.Pattern := String(FNeedle);
        RegObj.Global := False;
        RegObj.IgnoreCase := not FCaseSensitive;
        RegObj.Multiline := True;
        RegexReady := True;
      except
        FAbortMsg := TrText('VBScript.RegExp is not available (invalid pattern or missing component).');
        Synchronize(SyncFilterFailed);
        Exit;
      end;
    end;

    if (FTotalLines > 0) and not Assigned(FBits) then
    begin
      if Trim(FAbortMsg) = '' then
        FAbortMsg := TrText('Filter: line count too large for filter memory (32-bit limit).');
      Synchronize(SyncFilterFailed);
      Exit;
    end;

    SourceStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
    IndexStream := TFileStream.Create(FIndexFileName, fmOpenRead or fmShareDenyNone);
    FSize := SourceStream.Size;
    SetLength(OffsetStr, 18);
    NeedleLen := Length(FNeedle);
    MatchCount := 0;
    JumpIdx := 0;
    SetLength(FJumpTable, (FTotalLines div 1024) + 2);
    FProgTotalLines := FTotalLines;

    I := 0;
    while (I < FTotalLines) and (not Terminated) do
    begin
      if (I and $1FFF) = 0 then
      begin
        FProgLines := I;
        if not Terminated then
          Synchronize(SyncFilterProgress);
      end;

      IndexStream.Seek(I * INDEX_RECORD_SIZE, soFromBeginning);
      IndexStream.Read(Pointer(OffsetStr)^, 18);
      StartOffset := StrToInt64Def(Trim(String(OffsetStr)), -1);
      if StartOffset < 1 then begin Inc(I); Continue; end;
      if ((I + 1) * INDEX_RECORD_SIZE) < IndexStream.Size then begin
        IndexStream.Seek((I + 1) * INDEX_RECORD_SIZE, soFromBeginning);
        IndexStream.Read(Pointer(OffsetStr)^, 18);
        EndOffset := StrToInt64Def(Trim(String(OffsetStr)), FSize + 1);
      end else
        EndOffset := FSize + 1;
      LineLength := EndOffset - StartOffset;
      if LineLength <= 0 then begin Inc(I); Continue; end;
      if LineLength > MAX_LINE_LEN_DISPLAY then LineLength := MAX_LINE_LEN_DISPLAY;
      SetLength(Buffer, LineLength);
      SourceStream.Seek(StartOffset - 1, soFromBeginning);
      SourceStream.Read(Pointer(Buffer)^, LineLength);
      while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do
        SetLength(Buffer, Length(Buffer) - 1);
      if FMatchMode = fmmRegex then
        LineContent := Buffer
      else if FCaseSensitive then
        LineContent := Buffer
      else
        LineContent := AnsiString(AnsiUpperCase(String(Buffer)));
      Matched := False;
      if NeedleLen > 0 then
      begin
        if FMatchMode = fmmRegex then
        begin
          if RegexReady then
          begin
            try
              Matched := RegObj.Test(WideString(String(Buffer)));
            except
              Matched := False;
            end;
          end;
        end
        else if FMatchMode = fmmPrefix then
        begin
          if Length(LineContent) >= NeedleLen then
          begin
            if FCaseSensitive then
              Matched := Copy(LineContent, 1, NeedleLen) = FNeedle
            else
              Matched := AnsiString(AnsiUpperCase(Copy(String(LineContent), 1, NeedleLen))) = FNeedle;
          end;
        end
        else
          Matched := Pos(FNeedle, LineContent) > 0;
      end;
      if Matched then begin
        ByteIdx := I div 8;
        BitIdx := I mod 8;
        FBits^[ByteIdx] := FBits^[ByteIdx] or (1 shl BitIdx);
        if (MatchCount mod 1024) = 0 then begin
          if JumpIdx >= Length(FJumpTable) then SetLength(FJumpTable, JumpIdx + 1024);
          FJumpTable[JumpIdx] := I;
          Inc(JumpIdx);
        end;
        Inc(MatchCount);
      end;
      Inc(I);
    end;
    FFilteredCount := MatchCount;
    SetLength(FJumpTable, JumpIdx);
    if not Terminated then Synchronize(NotifyOwner);
  finally
    if Assigned(IndexStream) then FreeAndNil(IndexStream);
    if Assigned(SourceStream) then FreeAndNil(SourceStream);
    if ComNeedUninit then
    begin
      CoUninitialize;
      ComNeedUninit := False;
    end;
  end;
end;

{ ============================================================================ }
{ Find / Search                                                                }
{ ============================================================================ }

function TfrmMain.GetLineStartOffset(LineIndex: Int64): Int64;
var
  OffsetBuf: array[0..19] of AnsiChar;
  S: AnsiString;
  BytesRead: Integer;
begin
  Result := -1;
  if (not Assigned(FIndexFileStream)) then Exit;
  try
    FIndexFileStream.Seek(Int64(LineIndex) * INDEX_RECORD_SIZE, soFromBeginning);
    BytesRead := FIndexFileStream.Read(OffsetBuf, 18);
    if BytesRead < 18 then Exit;
    SetString(S, PAnsiChar(@OffsetBuf[0]), 18);
    Result := StrToInt64Def(Trim(string(S)), -1);
  except
    Result := -1;
  end;
end;

function TfrmMain.BlendColors(const BaseColor, OverlayColor: TColor; const Alpha: Byte): TColor;
var
  Bc, Oc: Longint;
  br, bg, bb, orr, og, ob: Byte;
  r, g, b2: Integer;
begin
  Bc := ColorToRGB(BaseColor);
  Oc := ColorToRGB(OverlayColor);
  br := GetRValue(Bc); bg := GetGValue(Bc); bb := GetBValue(Bc);
  orr := GetRValue(Oc); og := GetGValue(Oc); ob := GetBValue(Oc);
  r := (Integer(br) * (255 - Alpha) + Integer(orr) * Alpha) div 255;
  g := (Integer(bg) * (255 - Alpha) + Integer(og) * Alpha) div 255;
  b2 := (Integer(bb) * (255 - Alpha) + Integer(ob) * Alpha) div 255;
  Result := RGB(Byte(r), Byte(g), Byte(b2));
end;

function TfrmMain.WrapLongTokensForDisplay(const AText: string; const MaxChars: Integer): string;
var
  I, L, StartPos, RunLen, ChunkPos: Integer;
  Ch: Char;
  Part: string;
begin
  if (MaxChars <= 1) or (AText = '') then
  begin
    Result := AText;
    Exit;
  end;

  Result := '';
  I := 1;
  L := Length(AText);
  while I <= L do
  begin
    Ch := AText[I];
    if (Ch = ' ') or (Ch = #9) then
    begin
      Result := Result + Ch;
      Inc(I);
      Continue;
    end;
    if (Ch = #13) or (Ch = #10) then
    begin
      Result := Result + Ch;
      Inc(I);
      Continue;
    end;

    StartPos := I;
    while I <= L do
    begin
      Ch := AText[I];
      if (Ch = ' ') or (Ch = #9) or (Ch = #13) or (Ch = #10) then Break;
      Inc(I);
    end;

    RunLen := I - StartPos;
    if RunLen <= MaxChars then
      Result := Result + Copy(AText, StartPos, RunLen)
    else
    begin
      Part := Copy(AText, StartPos, RunLen);
      ChunkPos := 1;
      while ChunkPos <= Length(Part) do
      begin
        Result := Result + Copy(Part, ChunkPos, MaxChars);
        Inc(ChunkPos, MaxChars);
        if ChunkPos <= Length(Part) then
          Result := Result + #13#10;
      end;
    end;
  end;
end;

function TfrmMain.WrapPlainTextToPixelWidth(const ACanvas: TCanvas; const AText: string;
  const AMaxWidth: Integer): string;
var
  CurLine: string;
  i: Integer;
  Word: string;

  procedure FlushLine;
  begin
    if CurLine = '' then Exit;
    if Result <> '' then Result := Result + #13#10;
    Result := Result + CurLine;
    CurLine := '';
  end;

  procedure AddWord(const W: string);
  var
    j, chunk: Integer;
    Test: string;
  begin
    if W = '' then Exit;
    if ACanvas.TextWidth(W) <= AMaxWidth then
    begin
      if CurLine = '' then
        CurLine := W
      else
      begin
        Test := CurLine + ' ' + W;
        if ACanvas.TextWidth(Test) <= AMaxWidth then
          CurLine := Test
        else
        begin
          FlushLine;
          CurLine := W;
        end;
      end;
      Exit;
    end;
    j := 1;
    while j <= Length(W) do
    begin
      chunk := 1;
      while (j + chunk - 1 <= Length(W)) and
        (ACanvas.TextWidth(Copy(W, j, chunk)) <= AMaxWidth) do
        Inc(chunk);
      Dec(chunk);
      if chunk < 1 then chunk := 1;
      if CurLine <> '' then FlushLine;
      CurLine := Copy(W, j, chunk);
      FlushLine;
      Inc(j, chunk);
    end;
  end;

begin
  Result := '';
  CurLine := '';
  if (AText = '') or (AMaxWidth < 4) then
  begin
    Result := AText;
    Exit;
  end;
  Word := '';
  i := 1;
  while i <= Length(AText) do
  begin
    if AText[i] in [#13, #10] then
    begin
      if Word <> '' then
      begin
        AddWord(Word);
        Word := '';
      end;
      FlushLine;
      while (i <= Length(AText)) and (AText[i] in [#13, #10]) do Inc(i);
      Continue;
    end;
    if AText[i] in [' ', #9] then
    begin
      if Word <> '' then
      begin
        AddWord(Word);
        Word := '';
      end;
      Inc(i);
      Continue;
    end;
    Word := Word + AText[i];
    Inc(i);
  end;
  if Word <> '' then AddWord(Word);
  FlushLine;
end;

function TfrmMain.ListViewItemIndexIsSelected(const ALv: TCustomListView; const AIndex: Integer): Boolean;
const
  LVM_GETITEMCOUNT_MSG = $1000 + 4;   { LVM_GETITEMCOUNT }
  LVM_GETITEMSTATE_MSG = $1000 + 44; { LVM_GETITEMSTATE }
var
  St: UINT;
  W: TWinControl;
  ItemCount: Integer;
begin
  Result := False;
  if ALv = nil then Exit;
  if (AIndex < 0) or (not ALv.HandleAllocated) then Exit;
  ItemCount := Integer(SendMessage(ALv.Handle, LVM_GETITEMCOUNT_MSG, 0, 0));
  if (ItemCount <= 0) or (AIndex >= ItemCount) then Exit;
  St := UINT(SendMessage(ALv.Handle, LVM_GETITEMSTATE_MSG, WPARAM(AIndex), LVIS_SELECTED));
  Result := (St and LVIS_SELECTED) <> 0;
  if not Result then Exit;
  W := ALv as TWinControl;
  { HideSelection existe em TListView, nao em TWinControl/TCustomListView }
  if (ALv is TListView) and TListView(ALv).HideSelection and (not W.Focused) then
    Result := False;
end;

procedure TfrmMain.DoFindDialog;
var
  S: string;
  Resp: Integer;
begin
  S := FFindText;
  if not InputQuery(TrText('Search'), TrText('Type the text to search:'), S) then Exit;
  S := Trim(S);
  if S = '' then Exit;
  FFindText := S;
  Resp := Application.MessageBox(
    PChar(TrText('Case sensitive search?') + #13#10 + TrText('(Yes = Case Sensitive / No = Ignore case)')),
    PChar(TrText('Search')), MB_YESNOCANCEL or MB_ICONQUESTION);
  if Resp = IDCANCEL then Exit;
  FFindCaseSensitive := (Resp = IDYES);
  if ListView1.ItemIndex >= 0 then
    StartFindFromPos(FLastFoundFilePos, +1)
  else
    StartFindFromPos(0, +1);
end;

procedure TfrmMain.DoFindReplace;
var
  Frm: TfrmFindReplace;
  Done: Boolean;
  FoundLine: Integer;
  FoundContent, NewContent: String;
  Op: TOperationType;
begin
  if Trim(edtFileName.Text) = '' then begin ShowMessage('Please select a file.'); Exit; end;
  if not FileExists(edtFileName.Text) then begin ShowMessage('File not found.'); Exit; end;

  Frm := TfrmFindReplace.Create(nil);
  try
    ApplyTranslationsToForm(Frm);
    Frm.edtFind.Text := FFindText;

    Done := False;
    while not Done do
    begin
      if Frm.ShowModal <> mrOk then
      begin
        Done := True;
        Break;
      end;

      case Frm.Action of
        fraFindNext:
        begin
          FFindText := Frm.GetFindText;
          FFindCaseSensitive := Frm.GetCaseSensitive;

          { No modo Select (checklist), ListView1.ItemIndex e obsoleto; usar FLastFoundLine. }
          if (ListView1.ItemIndex >= 0) or
             (isChecked and Assigned(FCheckListBox) and (FCheckListBox.ItemIndex >= 0)) then
            StartFindFromPos(FLastFoundFilePos + 1, +1)
          else
            StartFindFromPos(0, +1);
        end;

        fraReplace:
        begin
          if (FLastFoundLine >= 0) and (FLastFoundLine < totalLines) then
          begin
            FoundLine := FLastFoundLine + 1; // 1-based
            FoundContent := GetLineContent(FLastFoundLine);

            if Frm.GetCaseSensitive then
              NewContent := StringReplace(FoundContent, Frm.GetFindText, Frm.GetReplaceText, [])
            else
              NewContent := StringReplace(FoundContent, Frm.GetFindText, Frm.GetReplaceText, [rfIgnoreCase]);

            if NewContent <> FoundContent then
            begin
              if not EnsureWritableSession then Continue;
              if not EnsureOpenFileNotStaleForMutate then Continue;
              RecordForUndo(otEdit, FoundLine, FoundContent);
              CloseFileStreams;
              Op := otEdit;
              TEditFileThread.Create(edtFileName.Text, Op, FoundLine, NewContent);
              Frm.SetStatus(TrText('Replaced on line ') + IntToStr(FoundLine) + '.');
            end
            else
              Frm.SetStatus(TrText('No match on current line.'));
          end
          else
            Frm.SetStatus(TrText('No match selected. Use Find Next first.'));
        end;

        fraReplaceAll:
        begin
          if Application.MessageBox(
            PChar(TrText('Replace all occurrences of "') + Frm.GetFindText + '"?' + #13#10 + #13#10 +
              TrText('Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.') +
              iff(Assigned(chkSegmentedHeavyOps) and chkSegmentedHeavyOps.Checked,
                #13#10 + #13#10 + TrText('Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'),
                '') + #13#10 + #13#10 +
              TrText('Continue?')),
            PChar(TrText('Replace All')), MB_YESNO or MB_ICONQUESTION) = IDYES then
          begin
            if not EnsureWritableSession then Continue;
            if not EnsureOpenFileNotStaleForMutate then Continue;
            CloseFileStreams;
            TReplaceAllThread.Create(edtFileName.Text,
              Frm.GetFindText, Frm.GetReplaceText,
              Frm.GetCaseSensitive, Frm.GetWholeWord,
              True, True,
              Assigned(chkSegmentedHeavyOps) and chkSegmentedHeavyOps.Checked,
              ExtractFilePath(ParamStr(0)) + 'temp.txt',
              250000,
              '',
              False,
              True);
            Done := True;
          end;
        end;

        fraClosed:
          Done := True;
      end;
    end;
  finally
    Frm.Free;
    FocusPrimaryReadView;
  end;
end;

procedure TfrmMain.DoGotoLine;
var
  S: string;
  N: Integer;
begin
  S := '';
  if InputQuery(TrText('Ir para linha'), TrText('Numero da linha (1..') + IntToStr(totalLines) + '):', S) then
  begin
    N := StrToIntDef(Trim(S), -1);
    if (N >= 1) and (N <= totalLines) then
      gotoLine(N - 1);
  end;
end;

function TfrmMain.Line0BasedForFileByte1Based(const Byte1Based: Int64): Int64;
var
  SavePos: Int64;
  Lo, Hi, Mid: Int64;
  MidStart: Int64;
begin
  Result := -1;
  if (Byte1Based < 1) or (not Assigned(FIndexFileStream)) or (totalLines < 1) then Exit;
  SavePos := FIndexFileStream.Position;
  try
    Lo := 0;
    Hi := totalLines - 1;
    while Lo <= Hi do
    begin
      Mid := (Lo + Hi) div 2;
      MidStart := GetLineStartOffset(Mid);
      if MidStart < 1 then
      begin
        Result := -1;
        Break;
      end;
      if MidStart <= Byte1Based then
      begin
        Result := Mid;
        Lo := Mid + 1;
      end
      else
        Hi := Mid - 1;
    end;
  finally
    FIndexFileStream.Position := SavePos;
  end;
end;

procedure TfrmMain.DoGotoByteOffset;
var
  S: string;
  B, FileSize1: Int64;
  Line0: Int64;
begin
  S := '';
  if not Assigned(FIndexFileStream) or (totalLines < 1) then
  begin
    Application.MessageBox(PChar(TrText('Please read the file first.')),
      PChar(TrText('Go to byte offset')), MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if not InputQuery(TrText('Go to byte offset'),
    TrText('Byte position in file (1-based; $ prefix for hex):'), S) then Exit;
  S := Trim(S);
  if S = '' then
  begin
    Application.MessageBox(PChar(TrText('Invalid byte position.')),
      PChar(TrText('Go to byte offset')), MB_OK or MB_ICONWARNING);
    Exit;
  end;
  try
    B := StrToInt64(S);
  except
    Application.MessageBox(PChar(TrText('Invalid byte position.')),
      PChar(TrText('Go to byte offset')), MB_OK or MB_ICONWARNING);
    Exit;
  end;
  FileSize1 := 0;
  if Assigned(FSourceFileStream) then
    FileSize1 := FSourceFileStream.Size;
  if FileSize1 < 1 then
  begin
    Application.MessageBox(PChar(TrText('Please read the file first.')),
      PChar(TrText('Go to byte offset')), MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if (B < 1) or (B > FileSize1) then
  begin
    Application.MessageBox(PChar(TrText('Byte position is out of range for this file.')),
      PChar(TrText('Go to byte offset')), MB_OK or MB_ICONWARNING);
    Exit;
  end;
  Line0 := Line0BasedForFileByte1Based(B);
  if Line0 < 0 then
  begin
    Application.MessageBox(PChar(TrText('Could not resolve line for that byte position.')),
      PChar(TrText('Go to byte offset')), MB_OK or MB_ICONWARNING);
    Exit;
  end;
  gotoLine(Line0);
end;

procedure TfrmMain.StartFindFromPos(const AStartPos: Int64; const ADirection: Integer);
var
  IndexFileName: string;
begin
  FLastFindDirection := ADirection;
  FFindAutoRetry := False;
  FFilterFindSkips := 0;
  if Trim(FFindText) = '' then begin
    Application.MessageBox('Use Ctrl+F primeiro para definir o texto de busca.', 'Busca', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if Trim(edtFileName.Text) = '' then begin
    Application.MessageBox('Nenhum arquivo selecionado.', 'Busca', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if not FileExists(edtFileName.Text) then begin
    Application.MessageBox('Arquivo nao encontrado.', 'Busca', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  // Cancel any previous search thread (no WaitFor to avoid deadlock with Synchronize)
  if Assigned(FFindThread) then begin
    FFindThread.Terminate;
    FFindThread := nil;
  end;
  IndexFileName := ExtractFilePath(ParamStr(0)) + 'temp.txt';
  if not FileExists(IndexFileName) then begin
    Application.MessageBox('Arquivo de indice nao encontrado (temp.txt). Releia o arquivo primeiro.', 'Busca', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  Inc(FFindSearchId);
  UpdateStatusBar(TrText('Searching...'), iaRight);
  FFindThread := TFindInFileThread.Create(Self, edtFileName.Text, IndexFileName, FFindText, FFindCaseSensitive, AStartPos, ADirection, FFindSearchId);
end;

procedure TfrmMain.FindThreadDone(const AFound: Boolean; const ALineIndex: Integer; const AFilePos: Int64; const ASearchId: Integer; const AErrorMsg: string);
var
  LineStart: Int64;
begin
  // Discard stale results from a previous (cancelled) search
  if ASearchId <> FFindSearchId then Exit;
  FFindThread := nil;

  // Report thread errors
  if AErrorMsg <> '' then begin
    Application.MessageBox(PChar('Erro na busca: ' + AErrorMsg), 'Busca', MB_OK or MB_ICONERROR);
    UpdateStatusBar('Search error', iaRight);
    Exit;
  end;

  if not AFound then begin
    Application.MessageBox('Texto nao encontrado.', 'Busca', MB_OK or MB_ICONINFORMATION);
    FLastFoundFilePos := 0;
    UpdateStatusBar('Not found', iaRight);
    Exit;
  end;
  if (ALineIndex = FLastFoundLine) and (AFilePos = FLastFoundFilePos) and (not FFindAutoRetry) then begin
    FFindAutoRetry := True;
    if FLastFindDirection >= 0 then
      StartFindFromPos(AFilePos + 1, +1)
    else begin
      if AFilePos > 0 then StartFindFromPos(AFilePos - 1, -1)
      else StartFindFromPos(0, -1);
    end;
    Exit;
  end;
  if FFilterActive and (FilteredIndexForRealLine(ALineIndex) < 0) then begin
    Inc(FFilterFindSkips);
    if FFilterFindSkips > totalLines then begin
      FFilterFindSkips := 0;
      Application.MessageBox('Nenhuma ocorrencia encontrada entre as linhas do filtro atual.',
        'Busca', MB_OK or MB_ICONINFORMATION);
      UpdateStatusBar('Not found in filter', iaRight);
      Exit;
    end;
    if FLastFindDirection >= 0 then
      StartFindFromPos(AFilePos + 1, +1)
    else begin
      if AFilePos > 0 then StartFindFromPos(AFilePos - 1, -1)
      else StartFindFromPos(0, -1);
    end;
    Exit;
  end;
  FFilterFindSkips := 0;
  FLastFoundLine := ALineIndex;
  FLastFoundFilePos := AFilePos;
  // Calculate match column for highlighting
  LineStart := GetLineStartOffset(ALineIndex);
  if LineStart > 0 then begin
    FLastFoundCol := Integer(AFilePos - (LineStart - 1));
    FLastFoundMatchLen := Length(FFindText);
  end;
  if (ALineIndex >= 0) and (ALineIndex < totalLines) then
  begin
    gotoLine(ALineIndex);  { No modo Select: ja chama showChecked + define ItemIndex internamente. }
    if isChecked and Assigned(FCheckListBox) then
    begin
      if FCheckListBox.CanFocus then
        FCheckListBox.SetFocus;
    end
    else if ListView1.CanFocus then
      ListView1.SetFocus;
  end;
  CalculateFontMetrics;
  ListView1.Invalidate;
  UpdateStatusBar(Format('Found at line %d', [ALineIndex + 1]), iaRight);
end;

procedure TfrmMain.ApplyWordWrapRowHeight;
const
  MinWrapRows = 4;
var
  H: Integer;
  B: TBitmap;
begin
  if not Assigned(ListView1) then Exit;
  if FFastVisualWordWrap then
  begin
    FDeferredListViewRecreateForRowHeight := False;
    CalculateFontMetrics;
    H := Max(48, (Abs(FLineHeight) + 2) * MinWrapRows);
    if FWordWrapRowImages = nil then
      FWordWrapRowImages := TImageList.Create(Self);
    if (FWordWrapRowImages.Height <> H) or (FWordWrapRowImages.Count = 0) then
    begin
      FWordWrapRowImages.Clear;
      FWordWrapRowImages.Width := 1;
      FWordWrapRowImages.Height := H;
      B := TBitmap.Create;
      try
        B.Width := 1;
        B.Height := H;
        B.Canvas.Brush.Color := clWindow;
        B.Canvas.FillRect(Rect(0, 0, 1, H));
        FWordWrapRowImages.AddMasked(B, clWindow);
      finally
        B.Free;
      end;
    end;
    ListView1.SmallImages := FWordWrapRowImages;
  end
  else
  begin
    ListView1.SmallImages := nil;
    { Em alguns comctl32/Delphi 7 a altura nao volta so com SmallImages := nil.
      Recriar o handle forca o ListView a recalcular a altura padrao da linha.
      Evitar recriar com ListView oculta (modo checklist): pode deixar estado incoerente. }
    if ListView1.HandleAllocated and ListView1.Visible and (not isChecked) then
    begin
      ListView1.Perform(WM_SETREDRAW, 0, 0);
      try
        ListView1.Perform(CM_RECREATEWND, 0, 0);
      finally
        ListView1.Perform(WM_SETREDRAW, 1, 0);
      end;
      FDeferredListViewRecreateForRowHeight := False;
    end
    else
      FDeferredListViewRecreateForRowHeight := True;
  end;
end;

procedure TfrmMain.UpdateExternalScrollBarsForWordWrap;
begin
  if not Assigned(ScrollBarHorizontal) then Exit;

  if FFastVisualWordWrap then
  begin
    ScrollBarHorizontal.Position := 0;
    ScrollBarHorizontal.Enabled := False;
    ScrollBarHorizontal.Visible := False;
  end
  else
  begin
    ScrollBarHorizontal.Enabled := True;
    ScrollBarHorizontal.Visible := True;
  end;

  if Assigned(ScrollBarVertical) then
  begin
    if VisibleItems < 1 then
      VisibleItems := 1;
    ScrollBarVertical.LargeChange := VisibleItems;
    ScrollBarVertical.SmallChange := 1;
  end;
end;

procedure TfrmMain.UpdateListViewWordWrapUi;
begin
  if not Assigned(ListView1) then Exit;
  ApplyWordWrapRowHeight;
  ListView1Resize(ListView1);
  UpdateExternalScrollBarsForWordWrap;
  FormResize(Self);
end;

procedure TfrmMain.DrawFindHighlightForListCell(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; const SubItemIndex: Integer);
var
  R: TRect;
  S: String;
  LineStart: Int64;
  MatchStart, MatchLen: Integer;
  X, Y: Integer;
  Prefix, MatchText, Suffix: String;
  Canvas: TCanvas;
  BaseBk, HlBk: TColor;
  LineIdx: Integer;
begin
  if (Item = nil) or (FFindText = '') then Exit;
  LineIdx := FileLineIndexFromListRow(Item.Index);
  if LineIdx < 0 then Exit;
  if LineIdx <> FLastFoundLine then Exit;
  R := Rect(0, 0, 0, 0);
  if not ListView_GetSubItemRect(Sender.Handle, Item.Index, SubItemIndex, LVIR_LABEL, @R) then Exit;
  Canvas := Sender.Canvas;
  S := GetLineContent(LineIdx);
  LineStart := GetLineStartOffset(LineIdx);
  if LineStart < 0 then Exit;
  MatchStart := Integer(FLastFoundFilePos - (LineStart - 1));
  MatchLen := FLastFoundMatchLen;
  if MatchLen <= 0 then MatchLen := Length(FFindText);
  if MatchStart < 0 then MatchStart := 0;
  if MatchStart > Length(S) then Exit;
  if MatchStart + MatchLen > Length(S) then MatchLen := Length(S) - MatchStart;
  if cdsSelected in State then BaseBk := clHighlight else BaseBk := clWindow;
  if cdsSelected in State then HlBk := BlendColors(clHighlight, clInfoBk, 80) else HlBk := clInfoBk;
  Prefix := Copy(S, 1, MatchStart);
  MatchText := Copy(S, MatchStart + 1, MatchLen);
  Suffix := Copy(S, MatchStart + 1 + MatchLen, MaxInt);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BaseBk;
  Canvas.FillRect(R);
  if cdsSelected in State then Canvas.Font.Color := clHighlightText else Canvas.Font.Color := clWindowText;
  X := R.Left + 2;
  Y := R.Top + 1;
  Canvas.TextOut(X, Y, Prefix);
  Inc(X, Canvas.TextWidth(Prefix));
  Canvas.Brush.Color := HlBk;
  Canvas.FillRect(Rect(X, R.Top, X + Canvas.TextWidth(MatchText), R.Bottom));
  Canvas.TextOut(X, Y, MatchText);
  Inc(X, Canvas.TextWidth(MatchText));
  Canvas.Brush.Color := BaseBk;
  Canvas.TextOut(X, Y, Suffix);
end;

procedure TfrmMain.ListView1AdvancedCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  Stage: TCustomDrawStage; var DefaultDraw: Boolean);
var
  R: TRect;
  S: string;
  LineIdx: Integer;
  Col0W, Col1W: Integer;
  IsSel: Boolean;
  Bk, Fg: TColor;
  DrawFlags: UINT;
begin
  DefaultDraw := True;
  if (Stage <> cdPrePaint) then Exit;
  if (SubItem <> 1) then Exit;
  if (Item = nil) then Exit;

  if FFastVisualWordWrap then
  begin
    DefaultDraw := False;
    { Retangulo real da subcelula (como no highlight). DisplayRect+Columns[1].Width
      usa largura da coluna (ex. 1200px) e o wrap quase nao quebra - parece uma linha so. }
    if not ListView_GetSubItemRect(Sender.Handle, Item.Index, 1, LVIR_LABEL, @R) then
    begin
      R := Item.DisplayRect(drBounds);
      if ListView1.Columns.Count >= 2 then
      begin
        Col0W := ListView1.Columns[0].Width;
        Col1W := ListView1.Columns[1].Width;
      end
      else
      begin
        Col0W := 0;
        Col1W := R.Right - R.Left;
      end;
      R.Left := Col0W + 1;
      R.Right := R.Left + Col1W - 2;
    end;
    { Word wrap deve respeitar a area visivel do ListView (coluna pode ser mais larga que o cliente). }
    if R.Left < 0 then R.Left := 0;
    if R.Right > ListView1.ClientWidth - 1 then
      R.Right := ListView1.ClientWidth - 1;
    if R.Right <= R.Left + 4 then Exit;
    LineIdx := FileLineIndexFromListRow(Item.Index);
    if LineIdx < 0 then Exit;
    if Item.SubItems.Count > 0 then
      S := Item.SubItems[0]
    else
      S := GetLineContent(LineIdx);
    IsSel := ListViewItemIndexIsSelected(Sender, Item.Index);
    if IsSel then
    begin
      Bk := clHighlight;
      Fg := clHighlightText;
    end
    else
    begin
      Bk := clWindow;
      Fg := clWindowText;
      if IsBookmarked(LineIdx) then
        Bk := FF_BOOKMARK_ROW_BG;
    end;
    Sender.Canvas.Font.Assign(ListView1.Font);
    Sender.Canvas.Brush.Style := bsSolid;
    Sender.Canvas.Brush.Color := Bk;
    Sender.Canvas.FillRect(R);
    InflateRect(R, -3, -2);
    Sender.Canvas.Font.Color := Fg;
    { DT_WORDBREAK no custom draw da ListView e pouco fiavel; mesma quebra por pixels que no TCheckListBox. }
    if R.Right > R.Left then
      S := WrapPlainTextToPixelWidth(Sender.Canvas, S, R.Right - R.Left)
    else
      S := '';
    DrawFlags := DT_LEFT or DT_TOP or DT_NOPREFIX or DT_EXPANDTABS;
    DrawFlags := UINT(TWinControl(Sender).DrawTextBiDiModeFlags(Longint(DrawFlags)));
    Windows.DrawText(Sender.Canvas.Handle, PChar(S), Length(S), R, DrawFlags);
    Exit;
  end;

  if FileLineIndexFromListRow(Item.Index) <> FLastFoundLine then Exit;
  if (FFindText = '') then Exit;
  DrawFindHighlightForListCell(Sender, Item, State, SubItem);
  DefaultDraw := False;
end;

procedure TfrmMain.ListView1AdvancedCustomDrawItem(
  Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
  Stage: TCustomDrawStage; var DefaultDraw: Boolean);
var
  RealLine: Integer;
begin
  DefaultDraw := True;
  if Stage <> cdPrePaint then Exit;
  if Item = nil then Exit;

  if FFilterActive then
    RealLine := Integer(FilteredIndexToReal(Item.Index))
  else
    RealLine := Integer(Offset + Item.Index);
  { OwnerData: cdsSelected no State e instavel; usar LVM_GETITEMSTATE como no word wrap }
  if (RealLine >= 0) and IsBookmarked(RealLine) then
  begin
    if not ListViewItemIndexIsSelected(Sender, Item.Index) then
      Sender.Canvas.Brush.Color := FF_BOOKMARK_ROW_BG;
  end;
end;

{ ============================================================================ }
{ Encoding Detection                                                           }
{ ============================================================================ }

function TfrmMain.DetectFileEncoding(const AFileName: String): String;
var
  F: TFileStream;
  BOM: array[0..3] of Byte;
  BytesRead: Integer;
  Sample: AnsiString;
  SampleLen: Integer;
begin
  Result := 'ANSI';
  if not FileExists(AFileName) then Exit;
  try
    F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      BytesRead := F.Read(BOM, 4);
      if BytesRead >= 3 then
        if (BOM[0] = $EF) and (BOM[1] = $BB) and (BOM[2] = $BF) then begin Result := 'UTF-8 (BOM)'; Exit; end;
      if BytesRead >= 2 then begin
        if (BOM[0] = $FF) and (BOM[1] = $FE) then begin
          if (BytesRead >= 4) and (BOM[2] = $00) and (BOM[3] = $00) then Result := 'UTF-32 LE'
          else Result := 'UTF-16 LE';
          Exit;
        end;
        if (BOM[0] = $FE) and (BOM[1] = $FF) then begin Result := 'UTF-16 BE'; Exit; end;
      end;
      if BytesRead >= 4 then
        if (BOM[0] = $00) and (BOM[1] = $00) and (BOM[2] = $FE) and (BOM[3] = $FF) then begin Result := 'UTF-32 BE'; Exit; end;
      { Sem BOM: ANSI (CP1252 etc.) ou UTF-8; evitar assumir UTF-8 para todo ficheiro. }
      F.Position := 0;
      SampleLen := Min(F.Size, 16384);
      SetLength(Sample, SampleLen);
      if SampleLen > 0 then
        F.Read(Sample[1], SampleLen);
      if IsProbablyUtf8(Sample) then
        Result := 'UTF-8 (no BOM)'
      else
        Result := 'ANSI';
    finally
      F.Free;
    end;
  except
    Result := 'Unknown';
  end;
end;

{ ============================================================================ }
{ Undo / Redo                                                                  }
{ ============================================================================ }

procedure TfrmMain.ClearUndoRedo;
var
  I: Integer;
begin
  if Assigned(FUndoStack) then begin
    for I := 0 to FUndoStack.Count - 1 do Dispose(PUndoRecord(FUndoStack[I]));
    FUndoStack.Clear;
  end;
  if Assigned(FRedoStack) then begin
    for I := 0 to FRedoStack.Count - 1 do Dispose(PUndoRecord(FRedoStack[I]));
    FRedoStack.Clear;
  end;
end;

procedure TfrmMain.PushUndo(const AOp: TOperationType; const ALine: Int64; const AContent: String);
var
  P: PUndoRecord;
  I: Integer;
begin
  if not Assigned(FUndoStack) then FUndoStack := TList.Create;
  New(P);
  case AOp of
    otInsert: P^.Op := 0;
    otEdit:   P^.Op := 1;
    otDelete: P^.Op := 2;
  else P^.Op := 1;
  end;
  P^.Line := ALine;
  P^.OldContent := AContent;
  P^.NewContent := '';
  FUndoStack.Add(P);
  while FUndoStack.Count > 100 do begin
    Dispose(PUndoRecord(FUndoStack[0]));
    FUndoStack.Delete(0);
  end;
  if Assigned(FRedoStack) then begin
    for I := 0 to FRedoStack.Count - 1 do Dispose(PUndoRecord(FRedoStack[I]));
    FRedoStack.Clear;
  end;
end;

procedure TfrmMain.RecordForUndo(const AOp: TOperationType; const ALine: Int64; const AContent: String);
begin
  PushUndo(AOp, ALine, AContent);
end;

procedure TfrmMain.DoUndo;
var
  P, R: PUndoRecord;
  UndoOp: TOperationType;
  UndoLine: Int64;
  UndoContent: String;
begin
  if not Assigned(FUndoStack) or (FUndoStack.Count = 0) then begin
    UpdateStatusBar('Nothing to undo', iaRight);
    Exit;
  end;
  if not EnsureWritableSession then Exit;
  if not EnsureOpenFileNotStaleForMutate then Exit;
  P := PUndoRecord(FUndoStack[FUndoStack.Count - 1]);
  FUndoStack.Delete(FUndoStack.Count - 1);
  if not Assigned(FRedoStack) then FRedoStack := TList.Create;
  New(R);
  R^.Op := P^.Op;
  R^.Line := P^.Line;
  if (P^.Line >= 1) and (P^.Line <= totalLines) then
    R^.OldContent := GetLineContent(P^.Line - 1)
  else
    R^.OldContent := '';
  R^.NewContent := P^.OldContent;
  FRedoStack.Add(R);
  case P^.Op of
    0: begin UndoOp := otDelete; UndoLine := P^.Line; UndoContent := '';
         CloseFileStreams;
         TEditFileThread.Create(edtFileName.Text, UndoOp, UndoLine, UndoContent);
         UpdateStatusBar('Undo: delete line ' + IntToStr(UndoLine), iaRight);
       end;
    1: begin UndoOp := otEdit; UndoLine := P^.Line; UndoContent := P^.OldContent;
         CloseFileStreams;
         TEditFileThread.Create(edtFileName.Text, UndoOp, UndoLine, UndoContent);
         UpdateStatusBar('Undo: restore line ' + IntToStr(UndoLine), iaRight);
       end;
    2: begin UndoOp := otInsert; UndoLine := P^.Line; UndoContent := P^.OldContent;
         CloseFileStreams;
         TEditFileThread.Create(edtFileName.Text, UndoOp, UndoLine, UndoContent);
         UpdateStatusBar('Undo: insert line ' + IntToStr(UndoLine), iaRight);
       end;
  end;
  Dispose(P);
end;

procedure TfrmMain.DoRedo;
var
  P, U: PUndoRecord;
  RedoOp: TOperationType;
  RedoLine: Int64;
  RedoContent: String;
begin
  if not Assigned(FRedoStack) or (FRedoStack.Count = 0) then begin
    UpdateStatusBar('Nothing to redo', iaRight);
    Exit;
  end;
  if not EnsureWritableSession then Exit;
  if not EnsureOpenFileNotStaleForMutate then Exit;
  P := PUndoRecord(FRedoStack[FRedoStack.Count - 1]);
  FRedoStack.Delete(FRedoStack.Count - 1);
  if not Assigned(FUndoStack) then FUndoStack := TList.Create;
  New(U);
  U^.Op := P^.Op;
  U^.Line := P^.Line;
  if (P^.Line >= 1) and (P^.Line <= totalLines) then
    U^.OldContent := GetLineContent(P^.Line - 1)
  else
    U^.OldContent := '';
  U^.NewContent := P^.NewContent;
  FUndoStack.Add(U);
  case P^.Op of
    0: begin RedoOp := otInsert; RedoLine := P^.Line; RedoContent := P^.NewContent;
         CloseFileStreams;
         TEditFileThread.Create(edtFileName.Text, RedoOp, RedoLine, RedoContent);
         UpdateStatusBar('Redo: insert line ' + IntToStr(RedoLine), iaRight);
       end;
    1: begin RedoOp := otEdit; RedoLine := P^.Line; RedoContent := P^.NewContent;
         CloseFileStreams;
         TEditFileThread.Create(edtFileName.Text, RedoOp, RedoLine, RedoContent);
         UpdateStatusBar('Redo: edit line ' + IntToStr(RedoLine), iaRight);
       end;
    2: begin RedoOp := otDelete; RedoLine := P^.Line; RedoContent := '';
         CloseFileStreams;
         TEditFileThread.Create(edtFileName.Text, RedoOp, RedoLine, RedoContent);
         UpdateStatusBar('Redo: delete line ' + IntToStr(RedoLine), iaRight);
       end;
  end;
  Dispose(P);
end;

{ ============================================================================ }
{ Tail / Follow Mode                                                           }
{ ============================================================================ }

procedure TfrmMain.ToggleTailMode;
begin
  if FTailActive then begin
    FTailActive := False;
    tmrTail.Enabled := False;
    UpdateStatusBar('Tail OFF', iaRight);
    if Assigned(FToolsExtrasTail) then
      FToolsExtrasTail.Checked := False;
  end else begin
    if Trim(edtFileName.Text) = '' then begin ShowMessage('Please select a file first.'); Exit; end;
    if not FileExists(edtFileName.Text) then begin ShowMessage('File not found.'); Exit; end;
    if not Assigned(FSourceFileStream) then begin ShowMessage('Please read the file first.'); Exit; end;
    FTailLastFileSize := FSourceFileStream.Size;
    FTailLastLineCount := totalLines;
    FTailActive := True;
    tmrTail.Enabled := True;
    UpdateStatusBar('Tail ON', iaRight);
    if totalLines > 0 then
      gotoLine(totalLines - 1);
    if Assigned(FToolsExtrasTail) then
      FToolsExtrasTail.Checked := True;
  end;
end;

procedure TfrmMain.tmrTailTimer(Sender: TObject);
var
  hFile: THandle;
  SizeLow: DWORD;
  SizeHigh: DWORD;
  CurrentSize: Int64;
begin
  if not FTailActive then Exit;
  if Trim(edtFileName.Text) = '' then Exit;
  hFile := CreateFile(PChar(edtFileName.Text), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if hFile = INVALID_HANDLE_VALUE then Exit;
  try
    SizeLow := Windows.GetFileSize(hFile, @SizeHigh);
    if SizeLow = INVALID_FILE_SIZE then Exit;
    CurrentSize := Int64(SizeHigh) shl 32 or Int64(SizeLow);
  finally
    CloseHandle(hFile);
  end;
  if CurrentSize > FTailLastFileSize then
    TailAppendNewLines;
end;

procedure TfrmMain.TailAppendNewLines;
const
  { GetMem / TStream.Read use Integer count in Delphi 7; tail growth can be GB.
    Chunked read preserves correctness and avoids silent truncation / negative sizes. }
  MAX_TAIL_READ_CHUNK = 64 * 1024 * 1024;
var
  SourceFile: TFileStream;
  IndexFile: TFileStream;
  IndexPath: string;
  OldSize, NewSize: Int64;
  DeltaSize: Int64;
  ChunkOff: Int64;
  ChunkLeft: Int64;
  ChunkThis: Integer;
  Buffer: PAnsiChar;
  BytesRead: Integer;
  I: Integer;
  NewLines: Int64;
  AbsOffset: Int64;
  OffsetBuf: array[0..19] of AnsiChar;
  J, Digit: Integer;
  TempVal: Int64;
begin
  tmrTail.Enabled := False;
  try
    if not FileExists(edtFileName.Text) then Exit;
    IndexPath := ExtractFilePath(ParamStr(0)) + 'temp.txt';
    if not FileExists(IndexPath) then Exit;
    CloseFileStreams;
    SourceFile := nil;
    IndexFile := nil;
    Buffer := nil;
    try
      SourceFile := TFileStream.Create(edtFileName.Text, fmOpenRead or fmShareDenyNone);
      NewSize := SourceFile.Size;
      OldSize := FTailLastFileSize;
      if NewSize <= OldSize then begin
        FreeAndNil(SourceFile);
        OpenFileStreams(edtFileName.Text);
        FDetectedEncoding := DetectFileEncoding(edtFileName.Text);
        Exit;
      end;
      DeltaSize := NewSize - OldSize;
      IndexFile := TFileStream.Create(IndexPath, fmOpenReadWrite or fmShareDenyNone);
      IndexFile.Seek(0, soFromEnd);
      NewLines := 0;
      ChunkOff := 0;
      while ChunkOff < DeltaSize do
      begin
        ChunkLeft := DeltaSize - ChunkOff;
        if ChunkLeft > MAX_TAIL_READ_CHUNK then
          ChunkThis := MAX_TAIL_READ_CHUNK
        else
          ChunkThis := Integer(ChunkLeft);
        GetMem(Buffer, ChunkThis);
        try
          SourceFile.Seek(OldSize + ChunkOff, soFromBeginning);
          BytesRead := SourceFile.Read(Buffer^, ChunkThis);
          if BytesRead <= 0 then Break;
          for I := 0 to BytesRead - 1 do
          begin
            if Buffer[I] = #10 then begin
              Inc(NewLines);
              AbsOffset := OldSize + ChunkOff + I + 2;
              for J := 0 to 17 do OffsetBuf[J] := ' ';
              TempVal := AbsOffset;
              J := 17;
              repeat
                Digit := TempVal mod 10;
                OffsetBuf[J] := AnsiChar(Byte('0') + Digit);
                TempVal := TempVal div 10;
                Dec(J);
              until (TempVal = 0) or (J < 0);
              OffsetBuf[18] := #13;
              OffsetBuf[19] := #10;
              IndexFile.Write(OffsetBuf, 20);
            end;
          end;
          Inc(ChunkOff, BytesRead);
          if BytesRead < ChunkThis then Break;
        finally
          FreeMem(Buffer);
          Buffer := nil;
        end;
      end;
      FTailLastFileSize := NewSize;
      FTailLastLineCount := FTailLastLineCount + NewLines;
      totalLines := FTailLastLineCount;
      ItemCount := totalLines;
    finally
      if Assigned(IndexFile) then FreeAndNil(IndexFile);
      if Assigned(SourceFile) then FreeAndNil(SourceFile);
    end;
    OpenFileStreams(edtFileName.Text);
    FDetectedEncoding := DetectFileEncoding(edtFileName.Text);
    InvalidateLineCache;
    if Assigned(ListView1) then begin
      ListView1.Items.Count := FTailLastLineCount;
      ListView1.Invalidate;
      if FTailLastLineCount > 0 then
        gotoLine(FTailLastLineCount - 1);
    end;
  finally
    if FTailActive then tmrTail.Enabled := True;
  end;
end;

{ ============================================================================ }
{ Filter / Grep Visual                                                         }
{ ============================================================================ }

procedure TfrmMain.DoFilterDialog;
var
  S: string;
  Mode: TFilterMatchMode;
  Pick: Integer;
  CS: Boolean;
begin
  if FFilterActive then begin
    ClearFilter;
    UpdateStatusBar(TrText('Filter cleared.'), iaRight);
    Exit;
  end;
  S := FFilterText;
  if not InputQuery(TrText('Filter / Grep'), TrText('Show only lines matching (text or regex pattern):'), S) then Exit;
  S := Trim(S);
  if S = '' then Exit;
  Pick := MessageDlg(
    TrText('Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'),
    mtConfirmation, [mbYes, mbNo, mbOK, mbCancel], 0);
  if Pick = mrCancel then Exit;
  if Pick = mrYes then
    Mode := fmmPrefix
  else if Pick = mrNo then
    Mode := fmmContains
  else
    Mode := fmmRegex;

  CS := False;
  if Mode = fmmRegex then
  begin
    Pick := MessageDlg(
      TrText('Regular expression: match case? (Yes = case sensitive, No = ignore case)'),
      mtConfirmation, [mbYes, mbNo, mbCancel], 0);
    if Pick = mrCancel then Exit;
    CS := (Pick = mrYes);
  end;

  StartFilter(S, CS, Mode);
end;

procedure TfrmMain.StartFilter(const AText: String; ACaseSensitive: Boolean;
  const AMatchMode: TFilterMatchMode);
var
  IndexPath: String;
  FilterTotalLines: Int64;
begin
  if Trim(edtFileName.Text) = '' then begin ShowMessage('Please read a file first.'); Exit; end;
  if Assigned(FFilterThread) then begin
    TFilterThread(FFilterThread).Terminate;
    FFilterThread := nil;
  end;
  if Assigned(FFilterBits) then begin FreeMem(FFilterBits); FFilterBits := nil; end;
  FFilterActive := False;
  FFilteredCount := 0;
  SetLength(FFilterJumpTable, 0);
  IndexPath := ExtractFilePath(ParamStr(0)) + 'temp.txt';
  if not FileExists(IndexPath) then begin ShowMessage('Index file not found.'); Exit; end;
  if Assigned(FIndexFileStream) then
    FilterTotalLines := FIndexFileStream.Size div INDEX_RECORD_SIZE
  else begin ShowMessage('Please read the file first.'); Exit; end;
  if FilterTotalLines <= 0 then Exit;
  FFilterText := AText;
  UpdateStatusBar(TrText('Filtering...'), iaRight);
  FFilterThread := TFilterThread.Create(Self, edtFileName.Text, IndexPath, AText, ACaseSensitive, FilterTotalLines, AMatchMode);
end;

procedure TfrmMain.UpdateFilterBuildProgress(const LinesDone, TotalLines: Int64);
begin
  UpdateStatusBar(TrText('Filtering') + ' ' + UnUtils.FormatNumber(LinesDone) + ' / ' +
    UnUtils.FormatNumber(TotalLines) + ' ' + TrText('lines'), iaRight);
end;

procedure TfrmMain.FinishFilterThreadFailed(const AMsg: string);
begin
  FFilterThread := nil;
  if Assigned(FFilterBits) then begin FreeMem(FFilterBits); FFilterBits := nil; end;
  FFilterBitsSize := 0;
  FFilterActive := False;
  FFilteredCount := 0;
  FFilterTotalLines := 0;
  SetLength(FFilterJumpTable, 0);
  if Assigned(ListView1) and Assigned(FIndexFileStream) then begin
    ListView1Resize(ListView1);
    ListView1.Invalidate;
  end;
  UpdateInfoPanels;
  SyncScrollBarsForFilterMode;
  if isChecked then
    showChecked;
  if AMsg <> '' then
    Application.MessageBox(PChar(AMsg), PChar(TrText('Filter / Grep')), MB_OK or MB_ICONWARNING);
  UpdateStatusBar(TrText('Ready'), iaRight);
end;

procedure TfrmMain.FilterThreadDone;
begin
  FFilterThread := nil;
  FFilterActive := True;
  Offset := 0;
  fScrollPos := 0;
  ScrollBarVertical.Position := 0;
  if Assigned(ListView1) then begin
    if isChecked and Assigned(FCheckListBox) then
      showChecked
    else if ListView1.Visible and (not isChecked) then
      ListView1Resize(ListView1)
    else if FFilteredCount < 1 then
      ListView1.Items.Count := 0
    else if FFilteredCount > MaxInt then
      ListView1.Items.Count := MaxInt
    else
      ListView1.Items.Count := Integer(FFilteredCount);
    ListView1.Invalidate;
    if FFilteredCount > 0 then begin
      ListView1.Refresh;
      SelectListViewItem(0);
    end;
  end;
  UpdateStatusBar(Format(TrText('Filter: %d/%d'), [FFilteredCount, FFilterTotalLines]), iaRight);
  UpdateInfoPanels;
  SyncScrollBarsForFilterMode;
end;

procedure TfrmMain.ClearFilter;
begin
  if Assigned(FFilterThread) then begin
    TFilterThread(FFilterThread).Terminate;
    FFilterThread := nil;
  end;
  FFilterActive := False;
  FFilteredCount := 0;
  FFilterTotalLines := 0;
  SetLength(FFilterJumpTable, 0);
  if Assigned(FFilterBits) then begin FreeMem(FFilterBits); FFilterBits := nil; end;
  FFilterBitsSize := 0;
  { Sempre ListView1Resize: com Select ativo nao pode ficar Items.Count = linhas totais (quebra OwnerData / linhas em branco). }
  if Assigned(ListView1) and Assigned(FIndexFileStream) then begin
    ListView1Resize(ListView1);
    ListView1.Invalidate;
  end;
  UpdateStatusBar(TrText('Ready'), iaRight);
  UpdateInfoPanels;
  SyncScrollBarsForFilterMode;
  if isChecked then
    showChecked;
end;

procedure TfrmMain.SyncScrollBarsForFilterMode;
begin
  if not Assigned(ScrollBarVertical) then Exit;
  { Com filtro na ListView, a barra vertical externa nao esta ligada ao deslocamento (lista rola por si). }
  if FFilterActive and (not isChecked) then
    ScrollBarVertical.Enabled := False
  else
    ScrollBarVertical.Enabled := True;
end;

function TfrmMain.FilteredIndexToReal(FilteredIdx: Int64): Int64;
var
  JumpIdx: Integer;
  StartReal: Int64;
  Count: Int64;
  I: Int64;
  ByteIdx, BitIdx: Integer;
begin
  Result := -1;
  if not FFilterActive then Exit;
  if (FilteredIdx < 0) or (FilteredIdx >= FFilteredCount) then Exit;
  if not Assigned(FFilterBits) then Exit;
  JumpIdx := FilteredIdx div 1024;
  if (JumpIdx > 0) and (JumpIdx <= High(FFilterJumpTable)) then begin
    StartReal := FFilterJumpTable[JumpIdx];
    Count := Int64(JumpIdx) * 1024;
  end else begin
    StartReal := 0;
    Count := 0;
  end;
  I := StartReal;
  while I < FFilterTotalLines do begin
    ByteIdx := I div 8;
    BitIdx := I mod 8;
    if (FFilterBits^[ByteIdx] and (1 shl BitIdx)) <> 0 then begin
      if Count = FilteredIdx then begin Result := I; Exit; end;
      Inc(Count);
    end;
    Inc(I);
  end;
end;

function TfrmMain.FilteredIndexForRealLine(const RealLine: Int64): Int64;
var
  Lo, Hi, Mid: Int64;
  R: Int64;
begin
  Result := -1;
  if (not FFilterActive) or (FFilteredCount <= 0) then Exit;
  if (RealLine < 0) or (RealLine >= FFilterTotalLines) then Exit;
  Lo := 0;
  Hi := FFilteredCount - 1;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    R := FilteredIndexToReal(Mid);
    if R < 0 then Break;
    if R = RealLine then
    begin
      Result := Mid;
      Exit;
    end;
    if R < RealLine then
      Lo := Mid + 1
    else
      Hi := Mid - 1;
  end;
end;

{ ============================================================================ }
{ Bookmarks                                                                    }
{ ============================================================================ }

function TfrmMain.BookmarkIndexOf(RealLineIndex: Integer): Integer;
var
  Lo, Hi, Mid, Val: Integer;
begin
  Result := -1;
  if not Assigned(FBookmarks) then Exit;
  Lo := 0;
  Hi := FBookmarks.Count - 1;
  while Lo <= Hi do begin
    Mid := (Lo + Hi) div 2;
    Val := Integer(FBookmarks[Mid]);
    if Val = RealLineIndex then begin Result := Mid; Exit; end
    else if Val < RealLineIndex then Lo := Mid + 1
    else Hi := Mid - 1;
  end;
end;

function TfrmMain.IsBookmarked(RealLineIndex: Integer): Boolean;
begin
  Result := BookmarkIndexOf(RealLineIndex) >= 0;
end;

procedure TfrmMain.ToggleBookmark(RealLineIndex: Integer);
var
  Idx, Lo, Hi, Mid, Val: Integer;
begin
  if not Assigned(FBookmarks) then Exit;
  Idx := BookmarkIndexOf(RealLineIndex);
  if Idx >= 0 then
    FBookmarks.Delete(Idx)
  else begin
    if FBookmarks.Count >= 10000 then begin
      Application.MessageBox('Bookmark limit reached (10,000).', 'FastFile', MB_OK or MB_ICONWARNING);
      Exit;
    end;
    Lo := 0;
    Hi := FBookmarks.Count - 1;
    while Lo <= Hi do begin
      Mid := (Lo + Hi) div 2;
      Val := Integer(FBookmarks[Mid]);
      if Val < RealLineIndex then Lo := Mid + 1
      else Hi := Mid - 1;
    end;
    FBookmarks.Insert(Lo, Pointer(RealLineIndex));
  end;
  ListView1.Invalidate;
end;

procedure TfrmMain.GotoNextBookmark;
var
  CurIdx, I, RealLine, BkLine, TryBk: Integer;
  FIdx: Int64;
begin
  if not Assigned(FBookmarks) or (FBookmarks.Count = 0) then begin
    Application.MessageBox('No bookmarks set.', 'FastFile', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  { No modo Select, obter posicao atual da checklist, nao da ListView oculta. }
  if isChecked and Assigned(FCheckListBox) and (FCheckListBox.ItemIndex >= 0) then
  begin
    if FFilterActive then
      CurIdx := Integer(Offset) + FCheckListBox.ItemIndex  { indice filtrado }
    else
      CurIdx := FCheckListBox.ItemIndex;  { indice visivel (usado com Offset abaixo) }
  end
  else
    CurIdx := ListView1.ItemIndex;
  BkLine := -1;
  if FFilterActive then
  begin
    if CurIdx >= 0 then
      RealLine := Integer(FilteredIndexToReal(CurIdx))
    else
      RealLine := -1;
    for I := 0 to FBookmarks.Count - 1 do
    begin
      TryBk := Integer(FBookmarks[I]);
      if TryBk <= RealLine then Continue;
      if FilteredIndexForRealLine(TryBk) >= 0 then begin BkLine := TryBk; Break; end;
    end;
    if BkLine < 0 then
      for I := 0 to FBookmarks.Count - 1 do
      begin
        TryBk := Integer(FBookmarks[I]);
        if FilteredIndexForRealLine(TryBk) >= 0 then begin BkLine := TryBk; Break; end;
      end;
    if BkLine < 0 then
    begin
      Application.MessageBox('Nenhum marcador entre as linhas do filtro.', 'FastFile', MB_OK or MB_ICONINFORMATION);
      Exit;
    end;
    FIdx := FilteredIndexForRealLine(BkLine);
    if FIdx < 0 then Exit;
    Offset := 0;
    fScrollPos := 0;
    ScrollBarVertical.Position := 0;
    SelectListViewItem(Integer(FIdx));
    if isChecked and Assigned(FCheckListBox) then
    begin
      showChecked;
      if (Integer(FIdx) >= 0) and (Integer(FIdx) < FCheckListBox.Items.Count) then
        FCheckListBox.ItemIndex := Integer(FIdx);
      if FCheckListBox.CanFocus then FCheckListBox.SetFocus;
    end
    else if ListView1.CanFocus then
      ListView1.SetFocus;
    Exit;
  end;
  if CurIdx < 0 then CurIdx := -1;
  RealLine := Integer(Offset + CurIdx);
  for I := 0 to FBookmarks.Count - 1 do
    if Integer(FBookmarks[I]) > RealLine then begin BkLine := Integer(FBookmarks[I]); Break; end;
  if BkLine < 0 then BkLine := Integer(FBookmarks[0]);
  if (BkLine >= 0) and (BkLine < totalLines) then
    gotoLine(BkLine);  { gotoLine ja chama showChecked e define ItemIndex no modo Select }
  if isChecked and Assigned(FCheckListBox) then
  begin
    if FCheckListBox.CanFocus then FCheckListBox.SetFocus;
  end
  else if ListView1.CanFocus then
    ListView1.SetFocus;
end;

procedure TfrmMain.GotoPrevBookmark;
var
  CurIdx, I, RealLine, BkLine, TryBk: Integer;
  FIdx: Int64;
begin
  if not Assigned(FBookmarks) or (FBookmarks.Count = 0) then begin
    Application.MessageBox('No bookmarks set.', 'FastFile', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  { No modo Select, obter posicao atual da checklist, nao da ListView oculta. }
  if isChecked and Assigned(FCheckListBox) and (FCheckListBox.ItemIndex >= 0) then
  begin
    if FFilterActive then
      CurIdx := Integer(Offset) + FCheckListBox.ItemIndex
    else
      CurIdx := FCheckListBox.ItemIndex;
  end
  else
    CurIdx := ListView1.ItemIndex;
  BkLine := -1;
  if FFilterActive then
  begin
    if CurIdx >= 0 then
      RealLine := Integer(FilteredIndexToReal(CurIdx))
    else
      RealLine := MaxInt;
    for I := FBookmarks.Count - 1 downto 0 do
    begin
      TryBk := Integer(FBookmarks[I]);
      if TryBk >= RealLine then Continue;
      if FilteredIndexForRealLine(TryBk) >= 0 then begin BkLine := TryBk; Break; end;
    end;
    if BkLine < 0 then
      for I := FBookmarks.Count - 1 downto 0 do
      begin
        TryBk := Integer(FBookmarks[I]);
        if FilteredIndexForRealLine(TryBk) >= 0 then begin BkLine := TryBk; Break; end;
      end;
    if BkLine < 0 then
    begin
      Application.MessageBox('Nenhum marcador entre as linhas do filtro.', 'FastFile', MB_OK or MB_ICONINFORMATION);
      Exit;
    end;
    FIdx := FilteredIndexForRealLine(BkLine);
    if FIdx < 0 then Exit;
    Offset := 0;
    fScrollPos := 0;
    ScrollBarVertical.Position := 0;
    SelectListViewItem(Integer(FIdx));
    if isChecked and Assigned(FCheckListBox) then
    begin
      showChecked;
      if (Integer(FIdx) >= 0) and (Integer(FIdx) < FCheckListBox.Items.Count) then
        FCheckListBox.ItemIndex := Integer(FIdx);
      if FCheckListBox.CanFocus then FCheckListBox.SetFocus;
    end
    else if ListView1.CanFocus then
      ListView1.SetFocus;
    Exit;
  end;
  if CurIdx < 0 then CurIdx := MaxInt;
  RealLine := Integer(Offset + CurIdx);
  for I := FBookmarks.Count - 1 downto 0 do
    if Integer(FBookmarks[I]) < RealLine then begin BkLine := Integer(FBookmarks[I]); Break; end;
  if BkLine < 0 then BkLine := Integer(FBookmarks[FBookmarks.Count - 1]);
  if (BkLine >= 0) and (BkLine < totalLines) then
    gotoLine(BkLine);  { gotoLine ja chama showChecked e define ItemIndex no modo Select }
  if isChecked and Assigned(FCheckListBox) then
  begin
    if FCheckListBox.CanFocus then FCheckListBox.SetFocus;
  end
  else if ListView1.CanFocus then
    ListView1.SetFocus;
end;

procedure TfrmMain.ClearAllBookmarks;
begin
  if not Assigned(FBookmarks) then Exit;
  FBookmarks.Clear;
  ListView1.Invalidate;
  UpdateInfoPanels;
  { Atualizar prefixo '* Line:' nos itens da checklist (modo Select). }
  if isChecked then showChecked;
end;

{ ============================================================================ }
{ Recent Files                                                                 }
{ ============================================================================ }

procedure TfrmMain.LoadRecentFiles;
var
  Ini: TIniFile;
  I, Cnt: Integer;
begin
  FRecentFiles.Clear;
  if not FileExists(FRecentFilesIni) then Exit;
  Ini := TIniFile.Create(FRecentFilesIni);
  try
    Cnt := Ini.ReadInteger('RecentFiles', 'Count', 0);
    for I := 0 to Cnt - 1 do
      FRecentFiles.Add(Ini.ReadString('RecentFiles', 'File' + IntToStr(I), ''));
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.SaveRecentFiles;
var
  Ini: TIniFile;
  I: Integer;
begin
  if not Assigned(FRecentFiles) then Exit;
  Ini := TIniFile.Create(FRecentFilesIni);
  try
    Ini.EraseSection('RecentFiles');
    Ini.WriteInteger('RecentFiles', 'Count', FRecentFiles.Count);
    for I := 0 to FRecentFiles.Count - 1 do
      Ini.WriteString('RecentFiles', 'File' + IntToStr(I), FRecentFiles[I]);
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.AddToRecentFiles(const AFileName: String);
var
  Idx: Integer;
begin
  if not Assigned(FRecentFiles) then Exit;
  if Trim(AFileName) = '' then Exit;
  // Remove duplicate if exists
  Idx := FRecentFiles.IndexOf(AFileName);
  if Idx >= 0 then FRecentFiles.Delete(Idx);
  // Insert at top
  FRecentFiles.Insert(0, AFileName);
  // Limit to 25
  while FRecentFiles.Count > 25 do
    FRecentFiles.Delete(FRecentFiles.Count - 1);
  SaveRecentFiles;
end;

procedure TfrmMain.RecentFileClick(Sender: TObject);
var
  MI: TMenuItem;
  FilePath: string;
  Idx: Integer;
begin
  MI := Sender as TMenuItem;
  FilePath := MI.Hint; // Hint stores the unmodified file path
  if FileExists(FilePath) then
    edtFileName.Text := FilePath
  else
  begin
    Application.MessageBox(
      PChar('Este arquivo nao existe mais (foi movido ou excluido).' + #13#10#13#10 + FilePath),
      'FastFile', MB_OK or MB_ICONWARNING);
    if Assigned(FRecentFiles) then
    begin
      Idx := FRecentFiles.IndexOf(FilePath);
      if Idx >= 0 then
      begin
        FRecentFiles.Delete(Idx);
        SaveRecentFiles;
      end;
    end;
  end;
end;

procedure TfrmMain.ShowRecentFilesMenu;
var
  I: Integer;
  MI: TMenuItem;
  P: TPoint;
  Bmp: TBitmap;
  MinW: Integer;
  Cap: string;

  function PadCaptionToMinTextWidth(const S: string; MinPx: Integer): string;
  var
    Tw: Integer;
  begin
    Result := S;
    if MinPx <= 0 then Exit;
    Tw := Bmp.Canvas.TextWidth(Result);
    while Tw < MinPx do
    begin
      Result := Result + ' ';
      Tw := Bmp.Canvas.TextWidth(Result);
    end;
  end;

begin
  if not Assigned(FRecentFiles) or (FRecentFiles.Count = 0) then begin
    Application.MessageBox('No recent files.', 'FastFile', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Screen.MenuFont);
    if Assigned(edtFileName) and (edtFileName.Width > 0) then
      MinW := edtFileName.Width
    else
      MinW := 400;
    if MinW < 80 then
      MinW := 80;
    { Menu tem margens/check a esquerda; ajuste para aproximar a largura total ao edtFileName (D7: sem OwnerDraw no TMenuItem). }
    Dec(MinW, 52);
    if MinW < 50 then
      MinW := 50;

    FpmRecentFiles.Items.Clear;
    for I := 0 to FRecentFiles.Count - 1 do begin
      MI := TMenuItem.Create(FpmRecentFiles);
      Cap := StringReplace(FRecentFiles[I], '&', '&&', [rfReplaceAll]);
      MI.Caption := PadCaptionToMinTextWidth(Cap, MinW);
      MI.Hint := FRecentFiles[I]; // caminho original (RecentFileClick)
      MI.OnClick := RecentFileClick;
      FpmRecentFiles.Items.Add(MI);
    end;
  finally
    Bmp.Free;
  end;
  P := edtFileName.ClientToScreen(Point(0, edtFileName.Height));
  FpmRecentFiles.Popup(P.X, P.Y);
end;

{ ============================================================================ }
{ Help Dialog                                                                  }
{ ============================================================================ }

procedure TfrmMain.FormHelpKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    (Sender as TForm).ModalResult := mrCancel;
end;

procedure TfrmMain.BtnHelpClick(Sender: TObject);
begin
  ShowHelpDialog;
end;

procedure TfrmMain.ShowHelpDialog;
const
  CRLF = #13#10;
  SEP = '---------------------------------------------------------------';
  MK_HELP_GOTO_BYTE = '<<<FF_HELP_GOTO_BYTE>>>';
  MK_HELP_FILTER_ROW = '<<<FF_HELP_FILTER_ROW>>>';
  MK_HELP_FILTER_FEATURE = '<<<FF_HELP_FILTER_FEATURE>>>';
  MK_HELP_READONLY_ROW = '<<<FF_HELP_READONLY_ROW>>>';
  MK_HELP_MENUBAR_L1 = '<<<FF_HELP_MENUBAR_L1>>>';
  MK_HELP_MENUBAR_L2 = '<<<FF_HELP_MENUBAR_L2>>>';
  MK_HELP_VIEW_ZOOM_IN = '<<<FF_HELP_VIEW_ZOOM_IN>>>';
  MK_HELP_VIEW_ZOOM_OUT = '<<<FF_HELP_VIEW_ZOOM_OUT>>>';
  MK_HELP_COMPARE_MERGE = '<<<FF_HELP_COMPARE_MERGE>>>';
  MK_HELP_COMPARE_MERGE_RELOAD_1 = '<<<FF_HELP_COMPARE_MERGE_RELOAD_1>>>';
  MK_HELP_COMPARE_MERGE_RELOAD_2 = '<<<FF_HELP_COMPARE_MERGE_RELOAD_2>>>';
  HELP_TEXT =
    'HIGH PERFORMANCE FILE PROCESSOR  -  FastFile' + CRLF +
    'Version 2.0' + CRLF +
    SEP + CRLF + CRLF +
    'KEYBOARD SHORTCUTS' + CRLF +
    SEP + CRLF +
    MK_HELP_MENUBAR_L1 + CRLF +
    MK_HELP_MENUBAR_L2 + CRLF + CRLF +
    '  Ctrl+P ............. Open Options menu (dropdown)' + CRLF +
    '  Ctrl+O ............. Open file (browse)' + CRLF +
    '  Ctrl+R ............. Recent files list' + CRLF +
    MK_HELP_READONLY_ROW + CRLF +
    '  Ctrl+W ............. Toggle Word Wrap' + CRLF +
    '  Encoding combo ..... List view: how to decode bytes (UTF-8 / ANSI / UTF-16)' + CRLF +
    '  Ctrl+F ............. Find text' + CRLF +
    '  Ctrl+H ............. Find & Replace' + CRLF +
    '  F3 ................. Find next' + CRLF +
    '  Shift+F3 ........... Find previous' + CRLF +
    '  Ctrl+G ............. Go to line' + CRLF +
    MK_HELP_GOTO_BYTE + CRLF +
    '  Ctrl+Z ............. Undo last edit' + CRLF +
    '  Ctrl+Y ............. Redo' + CRLF +
    '  Ctrl+C ............. Copy selection to clipboard' + CRLF +
    '  Ctrl+T ............. Toggle Tail / Follow mode' + CRLF +
    '  Ctrl+Shift+L ....... Export filtered results (when filter is active)' + CRLF +
    '  Ctrl+B ............. Toggle bookmark on line' + CRLF +
    '  Shift+Home .......... Go to top of file' + CRLF +
    '  Shift+End ........... Go to bottom of file' + CRLF +
    '  F2 ................. Go to next bookmark' + CRLF +
    '  Shift+F2 ........... Go to previous bookmark' + CRLF +
    '  Ctrl+Shift+B ....... Clear all bookmarks' + CRLF +
    '  Esc ................ Cancel in-flight Find; else clear filter / selection' + CRLF +
    '  F1 ................. This help window' + CRLF +
    MK_HELP_FILTER_ROW + CRLF +
    '  Select (checkboxes)  Same shortcuts while the checklist has focus (btn Checkboxes)' + CRLF + CRLF +
    'READ PANEL & TOOLBAR (pnlButtons)' + CRLF +
    SEP + CRLF +
    '  Ctrl+1 ............. Show Read file tab (same as Read toolbar side)' + CRLF +
    '  F5 ................. Read / load file (main Read button)' + CRLF +
    '  Ctrl+Shift+X ....... Clear' + CRLF +
    '  Ctrl+Shift+F ....... Find in Files' + CRLF +
    '  Ctrl+Shift+K ....... Split Files' + CRLF +
    '  Ctrl+Shift+M ....... Merge lines' + CRLF +
    '  Ctrl+Shift+J ....... Merge files (insert source into destination)' + CRLF +
    MK_HELP_COMPARE_MERGE + CRLF +
    MK_HELP_COMPARE_MERGE_RELOAD_1 + CRLF +
    MK_HELP_COMPARE_MERGE_RELOAD_2 + CRLF +
    '  Ctrl+Shift+P ....... Split file into equal parts (LF-safe)' + CRLF +
    '  Ctrl+Shift+S ....... Select (checkbox list) (View menu)' + CRLF +
    MK_HELP_VIEW_ZOOM_IN + CRLF +
    MK_HELP_VIEW_ZOOM_OUT + CRLF +
    '  Ctrl+Shift+I ....... Insert line (line editor)' + CRLF +
    '  Ctrl+Shift+U ....... Duplicate line (line editor)' + CRLF +
    '  Ctrl+Shift+E ....... Edit line (line editor)' + CRLF +
    '  Ctrl+Shift+D ....... Delete line (line editor)' + CRLF +
    '  Ctrl+Shift+O ....... Export' + CRLF +
    '  Ctrl+Shift+W ....... Close (when Return button visible)' + CRLF +
    '  Ctrl+Shift+A ....... AI (Consumer)' + CRLF +
    '  (Hover toolbar buttons for the same shortcuts in hints.)' + CRLF + CRLF +
    '  Ctrl + mouse wheel . Zoom list font on ListView (up = smaller, down = larger)' + CRLF + CRLF +
    '  Double-click ....... Edit selected line' + CRLF +
    '  Drag & Drop ........ Drop a file to open it' + CRLF + CRLF +
    'FEATURES' + CRLF +
    SEP + CRLF + CRLF +
    '[1] FILE READING' + CRLF +
    '  High-performance file reader using buffered index.' + CRLF +
    '  Capable of handling files of several gigabytes.' + CRLF + CRLF +
    '[2] FIND & REPLACE  (Ctrl+F / Ctrl+H)' + CRLF +
    '  Background thread search (Boyer-Moore-Horspool).' + CRLF +
    '  Case sensitive/insensitive. F3/Shift+F3 navigation.' + CRLF +
    '  Esc cancels an in-flight Find; status bar shows bytes scanned / file size.' + CRLF +
    '  Ctrl+H opens Find & Replace dialog with Replace All.' + CRLF +
    '  In that dialog: Alt+N Find Next, Alt+R Replace, Alt+L Replace All, Alt+C Close.' + CRLF + CRLF +
    '[3] ENCODING DETECTION  (BOM)' + CRLF +
    '  Detects UTF-8, UTF-16 LE/BE, UTF-32 LE/BE, ANSI.' + CRLF + CRLF +
    '[4] UNDO / REDO  (Ctrl+Z / Ctrl+Y)' + CRLF +
    '  Records line edits for undo. Max 100 entries.' + CRLF + CRLF +
    '[5] TAIL / FOLLOW MODE  (Ctrl+T)' + CRLF +
    '  Real-time file monitoring (like tail -f).' + CRLF +
    '  500ms polling, incremental index append.' + CRLF + CRLF +
    '[6] FILTER / GREP' + CRLF +
    '  Background thread filter with bitset + jump table.' + CRLF +
    '  Minimal memory: ~1.25 MB for 10M lines.' + CRLF +
    MK_HELP_FILTER_FEATURE + CRLF + CRLF +
    '[7] BOOKMARKS  (Ctrl+B)' + CRLF +
    '  Toggle, navigate (F2/Shift+F2), clear all.' + CRLF +
    '  Soft row tint + thin accent bar (checkbox list); max 10,000.' + CRLF + CRLF +
    SEP;
var
  Frm: TForm;
  Memo: TMemo;
  Btn, BtnExport, BtnCopy: TButton;
  SD: TSaveDialog;
  MR: Integer;
  BtnW, TotalW, StartX: Integer;
  HelpBody: string;
begin
  Frm := TForm.Create(nil);
  try
    Frm.Caption := 'FastFile - Help & Feature Reference';
    Frm.Width := 620;
    Frm.Height := 560;
    Frm.Position := poScreenCenter;
    Frm.BorderStyle := bsDialog;
    Frm.KeyPreview := True;
    Frm.Color := clWhite;
    Frm.Font.Name := 'Segoe UI';
    Frm.Font.Size := 9;
    Memo := TMemo.Create(Frm);
    Memo.Parent := Frm;
    Memo.Left := 12;
    Memo.Top := 12;
    Memo.Width := Frm.ClientWidth - 24;
    Memo.Height := Frm.ClientHeight - 56;
    Memo.Anchors := [akLeft, akTop, akRight, akBottom];
    Memo.ReadOnly := True;
    Memo.ScrollBars := ssVertical;
    Memo.Font.Name := 'Consolas';
    Memo.Font.Size := 9;
    Memo.Font.Color := clBlack;
    Memo.Color := $00FAFAFA;
    Memo.WordWrap := True;
    HelpBody := HELP_TEXT;
    HelpBody := StringReplace(HelpBody, MK_HELP_GOTO_BYTE,
      '  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_FILTER_ROW,
      '  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_FILTER_FEATURE,
      '  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_READONLY_ROW,
      '  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_MENUBAR_L1,
      '  ' + 'Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_MENUBAR_L2,
      '  ' + 'Ctrl+ shortcuts are shown to the right of each menu command.', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_VIEW_ZOOM_IN,
      '  Ctrl+Num+ .......... Zoom in list font (View menu)', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_VIEW_ZOOM_OUT,
      '  Ctrl+Num- .......... Zoom out list font (View menu)', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_COMPARE_MERGE,
      '  Ctrl+Shift+H ....... Compare / merge + session history (two-file diff, journal)', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_COMPARE_MERGE_RELOAD_1,
      '  Session history Reload: a worker thread reads the journal tail, filters lines, loads the preview file and optional color scan; the progress bar covers that work first, then filling the memo and list on the UI thread.', [rfReplaceAll]);
    HelpBody := StringReplace(HelpBody, MK_HELP_COMPARE_MERGE_RELOAD_2,
      '  The loading overlay is not stay-on-top, and the UI yields often (including a short wait for queued input) so you can use Alt+Tab and other applications during a long reload.', [rfReplaceAll]);
    Memo.Text := HelpBody;
    BtnW := 120;
    TotalW := BtnW * 3 + 16;
    StartX := (Frm.ClientWidth - TotalW) div 2;
    BtnCopy := TButton.Create(Frm);
    BtnCopy.Parent := Frm;
    BtnCopy.Caption := '&Copy';
    BtnCopy.Width := BtnW;
    BtnCopy.Height := 28;
    BtnCopy.Left := StartX;
    BtnCopy.Top := Frm.ClientHeight - 40;
    BtnCopy.Anchors := [akBottom];
    BtnCopy.ModalResult := mrYes;
    BtnExport := TButton.Create(Frm);
    BtnExport.Parent := Frm;
    BtnExport.Caption := '&Export...';
    BtnExport.Width := BtnW;
    BtnExport.Height := 28;
    BtnExport.Left := StartX + BtnW + 8;
    BtnExport.Top := Frm.ClientHeight - 40;
    BtnExport.Anchors := [akBottom];
    BtnExport.ModalResult := mrRetry;
    Btn := TButton.Create(Frm);
    Btn.Parent := Frm;
    Btn.Caption := TrText('Close');
    Btn.Width := BtnW;
    Btn.Height := 28;
    Btn.Left := StartX + (BtnW + 8) * 2;
    Btn.Top := Frm.ClientHeight - 40;
    Btn.Anchors := [akBottom];
    Btn.ModalResult := mrOk;
    Btn.Default := True;
    Btn.Cancel := True;
    Frm.OnKeyDown := FormHelpKeyDown;
    repeat
      MR := Frm.ShowModal;
      if MR = mrYes then begin
        Clipboard.AsText := Memo.Text;
        Application.MessageBox(PChar(TrText('Content copied to clipboard.')), 'FastFile', MB_OK or MB_ICONINFORMATION);
      end else if MR = mrRetry then begin
        SD := TSaveDialog.Create(nil);
        try
          SD.Title := TrText('Export Help Content');
          SD.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
          SD.DefaultExt := 'txt';
          SD.FileName := 'FastFile_Help.txt';
          if SD.Execute then Memo.Lines.SaveToFile(SD.FileName);
        finally
          SD.Free;
        end;
      end;
    until (MR <> mrRetry) and (MR <> mrYes);
  finally
    Frm.Free;
    FocusPrimaryReadView;
  end;
end;

{ ============================================================================ }
{ ApplyReadPanelKey - atalhos do painel Read (Form KeyPreview + CheckListBox) }
{ ============================================================================ }

procedure TfrmMain.FocusPrimaryReadView;
begin
  if isChecked then
  begin
    if Assigned(FCheckListBox) and FCheckListBox.Visible and FCheckListBox.CanFocus then
      FCheckListBox.SetFocus;
  end
  else if Assigned(ListView1) and ListView1.Visible and ListView1.CanFocus then
    ListView1.SetFocus;
end;

function TfrmMain.IsReadPanelShortcutKey(const Key: Word; const Shift: TShiftState): Boolean;
begin
  Result := False;

  case Key of
    VK_F1, VK_F2, VK_F3, VK_F5, VK_HOME, VK_END, VK_ESCAPE:
      begin
        Result := True;
        Exit;
      end;
    VK_NUMPAD1:
      begin
        Result := (ssCtrl in Shift);
        Exit;
      end;
    Ord('1'):
      begin
        Result := (ssCtrl in Shift);
        Exit;
      end;
    { Virtual-key A..Z (VK_A..VK_Z): em KeyDown nao vem ASCII a..z.
      Nao usar Ord('a')..Ord('z') aqui: colide com VK_F1..VK_F12 no mesmo valor numerico. }
    Ord('A')..Ord('Z'):
      begin
        Result := (ssCtrl in Shift);
        Exit;
      end;
  end;
end;

procedure TfrmMain.ApplyReadPanelKey(var Key: Word; Shift: TShiftState);
var
  StartPos, LineStart, NextLineStart: Int64;
  CS: Boolean;
  BmRealLine: Int64;
  Line1Based: Integer;
  SavedCheckIdx: Integer;
begin
  if FHandlingReadShortcut then
  begin
    Key := 0;
    Exit;
  end;
  FHandlingReadShortcut := True;
  try
  { ESC: cancel background Find (antes de limpar filtro / selecao) }
  if (Key = VK_ESCAPE) and (Shift = []) and Assigned(FFindThread) then
  begin
    Inc(FFindSearchId);
    FFindThread.Terminate;
    FFindThread := nil;
    UpdateStatusBar(TrText('Search cancelled.'), iaRight);
    Key := 0;
    Exit;
  end;

  { Ctrl+1 / teclado numerico: mostrar separador Read file (btnShowTabReadFile) }
  if ((Key = Ord('1')) or (Key = VK_NUMPAD1)) and (Shift = [ssCtrl]) then begin
    if Assigned(btnShowTabReadFile) then btnShowTabReadFileClick(btnShowTabReadFile);
    Key := 0;
    Exit;
  end;

  { F5: Read / carregar ficheiro (btnRead) }
  if (Key = VK_F5) and (Shift = []) then begin
    if Assigned(btnRead) and btnRead.Enabled then btnReadClick(btnRead);
    Key := 0;
    Exit;
  end;

  { Ctrl+P: abrir menu Options (letra O = &Options na barra; Alt+O tambem) }
  if (Key = Ord('P')) and (Shift = [ssCtrl]) then begin
    EnsureReadTabVisible;
    PostMessage(Handle, WM_SYSCOMMAND, SC_KEYMENU, Ord('O'));
    Key := 0;
    Exit;
  end;

  { Barra pnlButtons: Ctrl+Shift+letra (sem Alt) }
  CS := (ssCtrl in Shift) and (ssShift in Shift) and not (ssAlt in Shift);
  if CS then begin
    case Key of
      Ord('X'), Ord('x'):
        begin
          if Assigned(btnClear) and btnClear.Enabled then btnClearClick(btnClear);
          Key := 0; Exit;
        end;
      Ord('K'), Ord('k'):
        begin
          if Assigned(btnSplitFiles) and btnSplitFiles.Enabled then btnSplitFilesClick(btnSplitFiles);
          Key := 0; Exit;
        end;
      Ord('M'), Ord('m'):
        begin
          if Assigned(btnMergeMultipleLines) and btnMergeMultipleLines.Enabled then btnMergeMultipleLinesClick(btnMergeMultipleLines);
          Key := 0; Exit;
        end;
      Ord('J'), Ord('j'):
        begin
          EnsureReadTabVisible;
          miMergeFilesClick(Self);
          Key := 0; Exit;
        end;
      Ord('P'), Ord('p'):
        begin
          EnsureReadTabVisible;
          miSplitEqualPartsClick(Self);
          Key := 0; Exit;
        end;
      Ord('S'), Ord('s'):
        begin
          if Assigned(btnCheckBoxes) and btnCheckBoxes.Enabled then btnCheckBoxesClick(btnCheckBoxes);
          Key := 0; Exit;
        end;
      Ord('I'), Ord('i'):
        begin
          if Assigned(btnEditFile) and btnEditFile.Enabled then editFile(otInsert);
          Key := 0; Exit;
        end;
      Ord('U'), Ord('u'):
        begin
          if Assigned(btnEditFile) and btnEditFile.Enabled then editFile(otDuplicate);
          Key := 0; Exit;
        end;
      Ord('E'), Ord('e'):
        begin
          if Assigned(btnEditFile) and btnEditFile.Enabled then editFile(otEdit);
          Key := 0; Exit;
        end;
      Ord('D'), Ord('d'):
        begin
          if Assigned(btnEditFile) and btnEditFile.Enabled then editFile(otDelete);
          Key := 0; Exit;
        end;
      Ord('O'), Ord('o'):
        begin
          if Assigned(btnExport) and btnExport.Enabled then btnExportClick(btnExport);
          Key := 0; Exit;
        end;
      Ord('W'), Ord('w'):
        begin
          if Assigned(btnReturn) and btnReturn.Enabled and btnReturn.Visible then btnReturnClick(btnReturn);
          Key := 0; Exit;
        end;
      Ord('A'), Ord('a'):
        begin
          if Assigned(btnConsumerAI) and btnConsumerAI.Enabled then btnConsumerAIClick(btnConsumerAI);
          Key := 0; Exit;
        end;
      Ord('H'), Ord('h'):
        begin
          EnsureReadTabVisible;
          miCompareMergeHistoryClick(Self);
          Key := 0; Exit;
        end;
    end;
  end;

  // Ctrl+O -> Abrir arquivo (Browse) [somente Ctrl puro, sem Shift/Alt]
  if (Key = Ord('O')) and (Shift = [ssCtrl]) then begin
    with TOpenDialog.Create(nil) do try
      Filter := 'All files (*.*)|*.*';
      Options := [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing];
      if Execute then edtFileName.Text := FileName;
    finally Free; end;
    Key := 0;
    Exit;
  end;

  { Ctrl+Alt+R -> sessao somente leitura (Ctrl+R fica para arquivos recentes) }
  if (Key = Ord('R')) and (Shift = [ssCtrl, ssAlt]) then begin
    miToggleReadOnlyClick(Self);
    Key := 0;
    Exit;
  end;

  // Ctrl+R -> Mostrar arquivos recentes [somente Ctrl, sem Shift/Alt]
  if (Key = Ord('R')) and (Shift = [ssCtrl]) then begin
    ShowRecentFilesMenu;
    Key := 0;
    Exit;
  end;

  // Ctrl+W -> Alternar Word Wrap (visual) [somente Ctrl]
  if (Key = Ord('W')) and (Shift = [ssCtrl]) then begin
    if Assigned(chkWordWrap) then begin
      chkWordWrap.Checked := not chkWordWrap.Checked;
      chkWordWrapClick(chkWordWrap);
    end;
    Key := 0;
    Exit;
  end;

  { Ctrl+Shift+F = Find in Files (antes de Ctrl+F, senao Shift cai em Find) }
  if (Key = Ord('F')) and (ssCtrl in Shift) and (ssShift in Shift) and not (ssAlt in Shift) then begin
    EnsureReadTabVisible;
    miFindInFilesClick(Self);
    Key := 0;
    Exit;
  end;

  // Ctrl+F -> Buscar
  if (Key = Ord('F')) and (ssCtrl in Shift) and not (ssShift in Shift) then begin
    EnsureReadTabVisible;
    FocusPrimaryReadView;
    DoFindDialog;
    Key := 0;
    Exit;
  end;

  // Ctrl+H -> Find & Replace
  if (Key = Ord('H')) and (ssCtrl in Shift) and not (ssShift in Shift) then begin
    EnsureReadTabVisible;
    FocusPrimaryReadView;
    DoFindReplace;
    Key := 0;
    Exit;
  end;

  // Ctrl+Shift+G -> Go to byte offset
  if (Key = Ord('G')) and (ssCtrl in Shift) and (ssShift in Shift) and not (ssAlt in Shift) then begin
    EnsureReadTabVisible;
    FocusPrimaryReadView;
    DoGotoByteOffset;
    Key := 0;
    Exit;
  end;

  // Ctrl+G -> Ir para linha
  if (Key = Ord('G')) and (ssCtrl in Shift) and not (ssShift in Shift) then begin
    EnsureReadTabVisible;
    FocusPrimaryReadView;
    DoGotoLine;
    Key := 0;
    Exit;
  end;

  // F3 / Shift+F3 -> Proximo / Anterior
  if (Key = VK_F3) then begin
    if ssShift in Shift then begin
      StartPos := FLastFoundFilePos - 1;
      LineStart := GetLineStartOffset(FLastFoundLine);
      if LineStart > 1 then StartPos := LineStart - 2;
      if StartPos < 0 then StartPos := 0;
      StartFindFromPos(StartPos, -1);
    end else begin
      StartPos := FLastFoundFilePos + 1;
      NextLineStart := GetLineStartOffset(FLastFoundLine + 1);
      if NextLineStart > 0 then
        if (NextLineStart - 1) > StartPos then StartPos := NextLineStart - 1;
      StartFindFromPos(StartPos, +1);
    end;
    Key := 0;
    Exit;
  end;

  // Ctrl+Z -> Undo
  if (Key = Ord('Z')) and (ssCtrl in Shift) and not (ssShift in Shift) then begin
    DoUndo;
    Key := 0;
    Exit;
  end;

  // Ctrl+Y -> Redo
  if (Key = Ord('Y')) and (ssCtrl in Shift) then begin
    DoRedo;
    Key := 0;
    Exit;
  end;

  // Ctrl+C -> copiar linha/selecao no painel de leitura (ListView e checklist)
  if (Key = Ord('C')) and (ssCtrl in Shift) then begin
    { Modo checklist (Select): copiar a linha focada, mantendo o mesmo comportamento base do ListView. }
    if (not (ssShift in Shift)) and Assigned(FCheckListBox) and FCheckListBox.Visible and
       (Screen.ActiveControl = FCheckListBox) then
    begin
      if existsCheckedRows(FCheckedLines) then
        CopyCheckedChecklistLinesToClipboard
      else if (FCheckListBox.ItemIndex >= 0) and
              (FCheckListBox.ItemIndex < FCheckListBox.Items.Count) then
      begin
        Line1Based := Integer(FCheckListBox.Items.Objects[FCheckListBox.ItemIndex]);
        if Line1Based > 0 then
          CopyFileLineToClipboard(Line1Based - 1);
      end;
      Key := 0;
      Exit;
    end;
    if Assigned(ListView1) and ((Screen.ActiveControl = ListView1) or ListView1.Focused) then
    begin
      if FHasSelection then
        CopyVerticalSelectionToClipboard
      else if ListView1.SelCount > 0 then
        CopyMultiSelectionToClipboard
      else if (ListView1.ItemIndex >= 0) and (not ListviewIsEmpty) and Assigned(FSourceFileStream) then
        CopyListViewFocusedLineToClipboard;
      Key := 0;
      Exit;
    end;
  end;

  // Ctrl+T -> Toggle Tail
  if (Key = Ord('T')) and (ssCtrl in Shift) then begin
    ToggleTailMode;
    Key := 0;
    Exit;
  end;

  { Ctrl+Shift+L = Export filtered (antes de Ctrl+L) }
  if (Key = Ord('L')) and (ssCtrl in Shift) and (ssShift in Shift) and not (ssAlt in Shift) then begin
    EnsureReadTabVisible;
    ExportFilteredResults;
    Key := 0;
    Exit;
  end;

  // Ctrl+L -> Filter / Grep
  if (Key = Ord('L')) and (Shift = [ssCtrl]) then begin
    EnsureReadTabVisible;
    DoFilterDialog;
    Key := 0;
    Exit;
  end;

  // Ctrl+B -> Toggle Bookmark (Ctrl+Shift+B -> Clear All)
  if (Key = Ord('B')) and (ssCtrl in Shift) then begin
    if ssShift in Shift then ClearAllBookmarks
    else begin
      if isChecked and Assigned(FCheckListBox) and (FCheckListBox.ItemIndex >= 0) then begin
        SavedCheckIdx := FCheckListBox.ItemIndex;
        Line1Based := Integer(FCheckListBox.Items.Objects[SavedCheckIdx]);
        if Line1Based > 0 then
        begin
          ToggleBookmark(Line1Based - 1);
          { Atualizar o prefixo '* Line:' na checklist apos alternar o marcador. }
          showChecked;
          if (SavedCheckIdx >= 0) and (SavedCheckIdx < FCheckListBox.Items.Count) then
            FCheckListBox.ItemIndex := SavedCheckIdx;
        end;
      end
      else if Assigned(ListView1) and (ListView1.ItemIndex >= 0) then begin
        if FFilterActive then begin
          BmRealLine := FilteredIndexToReal(ListView1.ItemIndex);
          if BmRealLine >= 0 then ToggleBookmark(Integer(BmRealLine));
        end else
          ToggleBookmark(Integer(Offset + ListView1.ItemIndex));
      end;
    end;
    Key := 0;
    Exit;
  end;

  // F2 -> Next Bookmark / Shift+F2 -> Previous Bookmark
  if (Key = VK_F2) then begin
    if ssShift in Shift then GotoPrevBookmark
    else GotoNextBookmark;
    Key := 0;
    Exit;
  end;

  { Shift+Home / Ctrl+Home -> inicio (lista, filtro ou checklist; btnUpClick define o foco) }
  if (Key = VK_HOME) and ((ssShift in Shift) or (ssCtrl in Shift)) and not (ssAlt in Shift) then begin
    btnUpClick(Self);
    Key := 0;
    Exit;
  end;

  if (Key = VK_END) and ((ssShift in Shift) or (ssCtrl in Shift)) and not (ssAlt in Shift) then begin
    btnDownClick(Self);
    Key := 0;
    Exit;
  end;

  // F1 -> Help
  if (Key = VK_F1) and (Shift = []) then begin
    ShowHelpDialog;
    Key := 0;
    Exit;
  end;

  // Esc -> Clear filter or vertical selection
  if (Key = VK_ESCAPE) and (Shift = []) then begin
    if FFilterActive then begin
      ClearFilter;
      UpdateStatusBar(TrText('Filter cleared.'), iaRight);
      Key := 0;
      Exit;
    end;
    if FHasSelection then begin
      FHasSelection := False;
      FIsDragging := False;
      if Assigned(ListView1) and ListView1.Visible then
        ListView1.Repaint;
      Key := 0;
      Exit;
    end;
  end;
  finally
    FHandlingReadShortcut := False;
  end;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
const
  showOtherTabs: Boolean = True;
begin
  { KeyPreview: o Form recebe antes do controle focado. Tratar atalhos do Help aqui
    tambem com foco em CheckList/ListView (antes havia Exit e Ctrl+F nao fazia nada). }
  if (Key <> 0) and IsReadPanelShortcutKey(Key, Shift) then
    ApplyReadPanelKey(Key, Shift);

  { ESC tambem fecha a aba ativa no pgMain quando nao foi consumido
    (ex.: sem filtro/sele??o no painel Read). }
  if (Key = VK_ESCAPE) and (Shift = []) and Assigned(pgMain) then
  begin
    if pgMain.Visible and (pgMain.PageCount > 0)
      and Assigned(pgMain.ActivePage) and pgMain.ActivePage.TabVisible then
    begin
      if pgMain.ActivePageIndex = TAB_READ_FILE_INDEX then
        HideTabs
      else
        HideTabs(showOtherTabs);
      Key := 0;
    end
    else if not pgMain.Visible then
    begin
      { Painel de abas oculto: ESC fecha a aplicacao (FormCloseQuery continua a aplicar). }
      Close;
      Key := 0;
    end;
  end;
end;

procedure TfrmMain.WMRefreshChecklist(var Msg: TMessage);
begin
  FChecklistRefreshPending := False;
  if isChecked then
    showChecked;
end;

end.


