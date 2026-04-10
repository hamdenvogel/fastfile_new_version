program FastFile;

uses
  FastMM4 in 'FastMM4-master\FastMM4.pas',
  Fastcode in 'FastCode.Libraries-0.6.4\FastCode.pas',
  Windows,
  Forms,
  sDialogs,
  SysUtils,
  MainUnit in 'MainUnit.pas' {frmMain},
  UnUtils in 'UnUtils.pas',
  UnDM in 'UnDM.pas' {DataModule1: TDataModule},
  UnSplash in 'UnSplash.pas' {frmSplash},
  UnFormAboutFF in 'UnFormAboutFF.pas' {frmAboutFF},
  unHardwareInformation in 'unHardwareInformation.pas',
  unSplitView in 'unSplitView.pas' {frmSplitView},
  Biblioteca in 'Biblioteca.pas',
  MruHelper in 'MruHelper.pas',
  UnConsts in 'UnConsts.pas',
  UnConsumerAI in 'UnConsumerAI.pas',
  UnConsumerDialog in 'UnConsumerDialog.pas',
  uSmoothLoading in 'uSmoothLoading.pas' {frmSmoothLoadingForm},
  uDeltaEditor in 'uDeltaEditor.pas' {frmDeltaEditor};

const
  showDeveloperInfo: Boolean = True;
var
  //i: integer;
  Map: THandle;

{$R *.RES}
{$i sDefs.inc}

begin
  // Only one instance for your application.
  Map := CreateFileMapping($FFFFFFFF, nil, PAGE_READONLY, 0, 32, 'MyACMap');
  if Map = 0 then
  begin
    sShowMessage('Error memory allocation.');
    Halt;
  end
  else if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    sShowMessage('This application is already running');
    Halt;
  end; //End checking for one instance

  Application.Initialize;
  try
    // DataModule with TsSkinManager component should be created first
    //  if LoadProfilerDll then
    //    ShowProfileForm;
  {$IFDEF D2007}
    {$IFDEF DEBUG}
    ReportMemoryLeaksOnShutdown := True;
    {$ENDIF}
    Application.MainFormOnTaskBar := True;
  {$ENDIF}
    //  acAllowLatestCommonDialogs := True;
    Application.Title := 'FastFile';
    DataModule1 := TDataModule1.Create(Application);
    (*frmSplash := TfrmSplash.Create(Application);
    //frmSplash.lblInfo.Caption := UnUtils.LoadConfig(showDeveloperInfo);
    frmSplash.Show;
    // Here maybe placed any initialization or other code
    for i := 300 downto 1 do
    begin
      //fmSplash.sLabelFX2.Caption := 'This form will be shown for ' + IntToStr(i div 1000 + 1) + ' seconds...';
      Application.ProcessMessages;
      Sleep(1);
    end;  *)
    Application.CreateForm(TfrmMain, frmMain);
  finally
    // Closing Splash-Screen and freeing memory (this code maybe placed in other parts of application,                                      
    FreeAndNil(frmSplash); // for example - in Form1.OnShow event)
  end;
  Application.Run;
end.
