unit uLineEditor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TOperationType = (otInsert, otReplace, otEdit, otDelete, otDuplicate);

  TfrmLineEditor = class(TForm)
    Label1: TLabel;
    cbOperation: TComboBox;
    Label2: TLabel;
    edtLineNumber: TEdit;
    Label3: TLabel;
    mmContent: TMemo;
    btnConfirm: TButton;
    btnCancel: TButton;
    Bevel1: TBevel;
    procedure cbOperationChange(Sender: TObject);
    procedure btnConfirmClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
  public
    class function Execute(var Op: TOperationType; var LineNum: Int64; var TextContent: String): Boolean;
  end;

var
  frmLineEditor: TfrmLineEditor;

implementation

uses
  uTextEncoding, uI18n;

{$R *.dfm}

procedure ShowMessage(const Msg: string); overload;
begin
  Dialogs.ShowMessage(TrText(Msg));
end;

const
  { UTF-8 (octetos) para MessageBoxW — evita MessageBoxA / code page no titulo e textos acentuados }
  u8ConfirmCap: AnsiString = #$43#$6F#$6E#$66#$69#$72#$6D#$61#$C3#$A7#$C3#$A3#$6F; { Confirmação }
  u8ConfirmQ: AnsiString = #$43#$6F#$6E#$66#$69#$72#$6D#$61#$20#$61#$20#$6F#$70#$65#$72#$61#$C3#$A7#$C3#$A3#$6F#$3F; { Confirma a operação? }
  u8Operacao: AnsiString = #$4F#$70#$65#$72#$61#$C3#$A7#$C3#$A3#$6F; { Operação }
  u8Deseja: AnsiString = #$44#$65#$73#$65#$6A#$61#$20#$63#$6F#$6E#$74#$69#$6E#$75#$61#$72#$3F; { Deseja continuar? }

class function TfrmLineEditor.Execute(var Op: TOperationType;
  var LineNum: Int64; var TextContent: String): Boolean;
var
  InitialOp: TOperationType;
  InitialText, TempText: String;
begin
  Result := False;
  frmLineEditor := TfrmLineEditor.Create(nil);
  try
    ApplyTranslationsToForm(frmLineEditor);
    InitialOp := Op;
    InitialText := TextContent;
    InitialText := StringReplace(InitialText, #13, '', [rfReplaceAll]);
    InitialText := StringReplace(InitialText, #10, '', [rfReplaceAll]);

    frmLineEditor.cbOperation.Items.Clear;
    frmLineEditor.cbOperation.Items.Add(TrText('Delete Line'));
    frmLineEditor.cbOperation.Items.Add(TrText('Duplicate Line'));
    frmLineEditor.cbOperation.Items.Add(TrText('Edit Line'));
    frmLineEditor.cbOperation.Items.Add(TrText('Insert Line'));

    case Op of
      otDelete:    frmLineEditor.cbOperation.ItemIndex := 0;
      otDuplicate: frmLineEditor.cbOperation.ItemIndex := 1;
      otEdit:      frmLineEditor.cbOperation.ItemIndex := 2;
      otInsert:    frmLineEditor.cbOperation.ItemIndex := 3;
    else
      frmLineEditor.cbOperation.ItemIndex := 2;
    end;
    
    frmLineEditor.cbOperationChange(nil); 
    
    if LineNum > 0 then
      frmLineEditor.edtLineNumber.Text := IntToStr(LineNum)
    else
      frmLineEditor.edtLineNumber.Text := '';
      
    frmLineEditor.mmContent.Text := TextContent;
    
    if frmLineEditor.ShowModal = mrOk then
    begin
      case frmLineEditor.cbOperation.ItemIndex of
        0: Op := otDelete;
        1: Op := otDuplicate;
        2: Op := otEdit;
        3: Op := otInsert;
      end;
      
      LineNum := StrToInt64Def(frmLineEditor.edtLineNumber.Text, 0);
      
      { RIGOROUS CLEANUP: Remove ALL #13 and #10 characters }
      TempText := frmLineEditor.mmContent.Text;
      TempText := StringReplace(TempText, #13, '', [rfReplaceAll]);
      TempText := StringReplace(TempText, #10, '', [rfReplaceAll]);
      TextContent := TempText;

      { Duplicate = Insert the same content at the next line }
      if Op = otDuplicate then
      begin
        Op := otInsert;
        Inc(LineNum);
        { TextContent already holds the original line content }
      end;
      
      if (InitialOp = otEdit) and (Op = otEdit) and (TextContent = InitialText) then
      begin
        Result := False;
        Exit;
      end;
      Result := True;
    end;
  finally
    FreeAndNil(frmLineEditor);
  end;
end;

procedure TfrmLineEditor.cbOperationChange(Sender: TObject);
begin
  { Delete (0) and Duplicate (1) do not need the user to edit the content }
  mmContent.Enabled := (cbOperation.ItemIndex in [2, 3]);
  if not mmContent.Enabled then
    mmContent.Color := clBtnFace
  else
    mmContent.Color := clWindow;
end;

procedure TfrmLineEditor.btnConfirmClick(Sender: TObject);
var
  OpText, MsgText: string;
begin
  if Trim(edtLineNumber.Text) = '' then
  begin
    ShowMessage('Line Number is required.');
    Exit;
  end;
  case cbOperation.ItemIndex of
    0: OpText := TrText('Delete Line');
    1: OpText := TrText('Duplicate Line');
    2: OpText := TrText('Edit Line');
    3: OpText := TrText('Insert Line');
  else
    OpText := TrText('Operation');
  end;
  MsgText := TrText('Confirm the operation?') + #13#10#13#10 +
             OpText + #13#10 +
             TrText('Line: ') + Trim(edtLineNumber.Text) + #13#10#13#10 +
             TrText('Do you want to continue?');
  if Dialogs.MessageDlg(MsgText, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  ModalResult := mrOk;
end;

procedure TfrmLineEditor.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
