unit uExportDialog;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmExportDialog = class(TForm)
    lblInstruction: TLabel;
    edtLines: TEdit;
    lblExample: TLabel;
    chkSaveToFile: TCheckBox;
    btnConfirm: TButton;
    btnCancel: TButton;
    Bevel1: TBevel;
    procedure btnConfirmClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  public
    class function Execute(var Input: String; var SaveToFile: Boolean): Boolean;
  end;

implementation

uses
  uI18n;

{$R *.dfm}

procedure ShowMessage(const Msg: string); overload;
begin
  Dialogs.ShowMessage(TrText(Msg));
end;

class function TfrmExportDialog.Execute(var Input: String; var SaveToFile: Boolean): Boolean;
var
  frm: TfrmExportDialog;
begin
  Result := False;
  frm := TfrmExportDialog.Create(nil);
  try
    ApplyTranslationsToForm(frm);
    if frm.ShowModal = mrOk then
    begin
      Input := frm.edtLines.Text;
      SaveToFile := frm.chkSaveToFile.Checked;
      Result := True;
    end;
  finally
    frm.Free;
  end;
end;

procedure TfrmExportDialog.btnConfirmClick(Sender: TObject);
begin
  if Trim(edtLines.Text) = '' then
  begin
    ShowMessage('Line parameters are required.');
    edtLines.SetFocus;
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TfrmExportDialog.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
