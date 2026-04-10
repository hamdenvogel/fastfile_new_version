unit UnitPopupScaling;
{$I sDefs.inc}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, sRadioButton,
  {$IFDEF DELPHI7UP} Types, {$ENDIF}
  ComCtrls, sTrackBar, sLabel, sSkinProvider, Buttons, sSpeedButton,
  sPanel, ImgList, acAlphaImageList,
  sBevel, ExtCtrls;


type
  TFormPopupScaling = class(TForm)
    sSkinProvider1: TsSkinProvider;
    sPanel1: TsPanel;
    sTrackBar1: TsTrackBar;
    sLabel1: TsLabel;
    sLabel2: TsLabel;
    sSpeedButton1: TsSpeedButton;
    sSpeedButton3: TsSpeedButton;
    sCharImageList1: TsCharImageList;
    sBevel1: TsBevel;
    procedure sTrackBar1UserChanged(Sender: TObject);
    procedure sSpeedButton1Click(Sender: TObject);
    procedure sTrackBar1UserChange(Sender: TObject);
    procedure MakeSelected(Btn: TsSpeedButton; Selected: boolean);
    procedure ClosePopup(AnimationAllowed: boolean = False);
    procedure FormShow(Sender: TObject);
    procedure sTrackBar1SkinPaint(Sender: TObject; Canvas: TCanvas);
  public
  end;

var
  FormPopupScaling: TFormPopupScaling;

implementation

{$R *.dfm}

uses acntUtils, sGraphUtils, acAlphaHints, sCommonData, sSkinManager, sConst, MainUnit, sVclUtils, acntTypes,
  UnDM, uI18n;

const
  ArrowArray: array [0..3] of integer = (96, 120, 144, 192);


procedure TFormPopupScaling.ClosePopup(AnimationAllowed: boolean = False);
begin
  if not AnimationAllowed then begin
    sSkinProvider1.AllowAnimation := False; // Quick hiding
    Close;
    sSkinProvider1.AllowAnimation := True;
    Application.ProcessMessages;
  end
  else
    Close;
end;


procedure TFormPopupScaling.FormShow(Sender: TObject);
begin
  sTrackBar1.Position := GetPPI(frmMain.sSkinProvider1.SkinData);
  sSpeedButton1.Caption := TrText('Auto scaling');
  sSpeedButton3.Caption := TrText('Custom PixelsPerInch value') + ': ' + IntToStr(sTrackBar1.Position);
end;


procedure TFormPopupScaling.MakeSelected(Btn: TsSpeedButton; Selected: boolean);
begin
  if Selected then begin
    Btn.Font.Style := [fsBold];
    Btn.ImageIndex := 0;
  end
  else begin
    Btn.Font.Style := [];
    Btn.ImageIndex := 1;
  end;
end;


procedure TFormPopupScaling.sSpeedButton1Click(Sender: TObject);
var
  Mode: integer;
begin
  Mode := TsSpeedButton(Sender).Tag;
  case Mode of
    0: begin // Use Delphi VCL auto scaling
      // Hiding of popup window
      ClosePopup;
      DataModule1.sSkinManager1.Options.ScaleMode := smVCL;
      frmMain.SpeedBtnPPI.Caption := 'Auto PPI: ' + IntToStr(GetPPI(frmMain.sSkinProvider1.SkinData));
    end;
    2: begin // Custom
      sTrackBar1.Position := GetPPI(frmMain.sSkinProvider1.SkinData);
      DataModule1.sSkinManager1.Options.PixelsPerInch := sTrackBar1.Position;
      frmMain.SpeedBtnPPI.Caption := 'Custom PPI: ' + IntToStr(sTrackBar1.Position);
{      if Win32MajorVersion >= 10 then begin
//        ClosePopup;
//        Application.ProcessMessages;
        DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
//        Visible := True;
      end
      else}
        DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
    end;
  end;
//  if Win32MajorVersion >= 10 then
//    sTrackBar1.Enabled := (Mode <> 0);

  MakeSelected(sSpeedButton1, Mode = 0);
  MakeSelected(sSpeedButton3, Mode = 2);
end;


procedure TFormPopupScaling.sTrackBar1SkinPaint(Sender: TObject; Canvas: TCanvas);
var
  R, chR: TRect;
  i, aSize: integer;
  TickSize: TSize;
  C: TColor;

  procedure PaintArrow(Value: integer);
  var
    x: integer;
  begin
    x := chR.Left + WidthOf(chR) * (Value - sTrackBar1.Min) div (sTrackBar1.Max - sTrackBar1.Min + 3) + 3;
    R.Right := x + aSize;
    R.Left := x - aSize;
    DrawArrow(Canvas.Handle, C, C, R, asTop, 0, 0, aSize, arsSolid1);
  end;

begin
  chR := sTrackBar1.ChannelRect;
  TickSize := MkSize(ScaleInt(1, sTrackBar1.SkinData), ScaleInt(4, sTrackBar1.SkinData));
  aSize := sTrackBar1.SkinData.CommonSkinData.ArrowSize;
  R.Top := chR.Bottom + sTrackBar1.SkinData.CommonSkinData.Spacing;
  R.Bottom := R.Top + aSize * 2;
  C := GetFontColor(sPanel1, sPanel1.SkinData.SkinIndex, sPanel1.SkinData.SkinManager);
  for i := 0 to Length(ArrowArray) - 1 do
    PaintArrow(ArrowArray[i]);
end;


procedure TFormPopupScaling.sTrackBar1UserChange(Sender: TObject);
var
  i: integer;
begin
  // Hint showing
  if Visible then begin
    for i := 0 to Length(ArrowArray) - 1 do
      if (sTrackBar1.Position <> ArrowArray[i]) and (abs(sTrackBar1.Position - ArrowArray[i]) < 3) then begin
        sTrackBar1.Position := ArrowArray[i];
        Break
      end;

    frmMain.sAlphaHints1.Animated := False;
    frmMain.sAlphaHints1.DefaultMousePos := mpLeftBottom;
  end;
end;


procedure TFormPopupScaling.sTrackBar1UserChanged(Sender: TObject);
begin
  // Hiding of popup window
  ClosePopup;
  if DataModule1.sSkinManager1.Options.ScaleMode <> smCustomPPI then begin
    DataModule1.sSkinManager1.Options.PixelsPerInch := GetPPI(frmMain.sSkinProvider1.SkinData);
    DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
    Application.ProcessMessages;
  end;
  MakeSelected(sSpeedButton1, False);
  MakeSelected(sSpeedButton3, True);
  frmMain.SpeedBtnPPI.Caption := 'Custom PPI: ' + IntToStr(sTrackBar1.Position);
  sSpeedButton3.Caption := 'Custom PixelsPerInch value: ' + IntToStr(sTrackBar1.Position);
  if Animated then
    SetPPIAnimated(sTrackBar1.Position)
  else
    DataModule1.sSkinManager1.Options.PixelsPerInch := sTrackBar1.Position;
end;

end.
