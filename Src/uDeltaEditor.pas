unit uDeltaEditor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ClipBrd, uSmoothLoading;

type
  TfrmDeltaEditor = class(TForm)
    lblLineNum: TLabel;
    lblContent: TLabel;
    edtLineNum: TEdit;
    edtContent: TEdit;
    btnAdd: TButton;
    btnDelete: TButton;
    lvDelta: TListView;
    btnConfirm: TButton;
    btnCancel: TButton;
    btnCopy: TButton;
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure lvDeltaSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    function FindLineItem(LineNum: Int64): TListItem;
  public
    class function Execute(var AList: TStringList): Boolean;
  end;

var
  frmDeltaEditor: TfrmDeltaEditor;

implementation

uses
  Math, uI18n;

{$R *.dfm}

procedure ShowMessage(const Msg: string); overload;
begin
  Dialogs.ShowMessage(TrText(Msg));
end;

{ TfrmDeltaEditor }

class function TfrmDeltaEditor.Execute(var AList: TStringList): Boolean;
var
  frm: TfrmDeltaEditor;
  i, P: Integer;
  item: TListItem;
begin
  Result := False;
  frm := TfrmDeltaEditor.Create(nil);
  try
    ApplyTranslationsToForm(frm);
    for i := 0 to AList.Count - 1 do
    begin
      P := PosBMH(': ', AList[i]);
      if P > 0 then
      begin
        item := frm.lvDelta.Items.Add;
        item.Caption := Trim(Copy(AList[i], 1, P - 1));
        item.SubItems.Add(Copy(AList[i], P + 2, Length(AList[i])));
      end;
    end;

    if frm.ShowModal = mrOk then
    begin
      AList.Clear;
      for i := 0 to frm.lvDelta.Items.Count - 1 do
      begin
        AList.Add(frm.lvDelta.Items[i].Caption + ': ' + frm.lvDelta.Items[i].SubItems[0]);
      end;
      Result := True;
    end;
  finally
    frm.Free;
  end;
end;

function TfrmDeltaEditor.FindLineItem(LineNum: Int64): TListItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to lvDelta.Items.Count - 1 do
  begin
    if StrToInt64Def(lvDelta.Items[i].Caption, -1) = LineNum then
    begin
      Result := lvDelta.Items[i];
      Break;
    end;
  end;
end;

procedure TfrmDeltaEditor.btnAddClick(Sender: TObject);
var
  LineNum: Int64;
  item: TListItem;
begin
  if Trim(edtLineNum.Text) = '' then
  begin
    ShowMessage('Please enter a valid line number.');
    edtLineNum.SetFocus;
    Exit;
  end;

  LineNum := StrToInt64Def(edtLineNum.Text, -1);
  if LineNum <= 0 then
  begin
    ShowMessage('Line number must be greater than 0.');
    edtLineNum.SetFocus;
    Exit;
  end;

  // It is valid to update a line with an "empty text" as requested by user
  item := FindLineItem(LineNum);
  if not Assigned(item) then
  begin
    item := lvDelta.Items.Add;
    item.Caption := IntToStr(LineNum);
    item.SubItems.Add(edtContent.Text);
  end
  else
  begin
    item.SubItems[0] := edtContent.Text;
    ShowMessage('Line ' + IntToStr(LineNum) + ' updated successfully.');
  end;

  edtLineNum.Clear;
  edtContent.Clear;
  edtLineNum.SetFocus;
end;

procedure TfrmDeltaEditor.btnDeleteClick(Sender: TObject);
begin
  if Assigned(lvDelta.Selected) then
    lvDelta.Selected.Delete;
end;

procedure TfrmDeltaEditor.btnCopyClick(Sender: TObject);
var
  i: Integer;
  SL: TStringList;
begin
  if lvDelta.SelCount = 0 then
  begin
    ShowMessage('Please select a line first.');
    Exit;
  end;

  SL := TStringList.Create;
  try
    for i := 0 to lvDelta.Items.Count - 1 do
    begin
      if lvDelta.Items[i].Selected and (lvDelta.Items[i].SubItems.Count > 0) then
        SL.Add(lvDelta.Items[i].SubItems[0]);
    end;
    Clipboard.AsText := SL.Text;
    ShowMessage(IntToStr(SL.Count) + ' line(s) copied to clipboard.');
  finally
    SL.Free;
  end;
end;

procedure TfrmDeltaEditor.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmDeltaEditor.FormShow(Sender: TObject);
begin
  { Handle do ListView ja existe; ajusta colunas na primeira abertura }
  FormResize(Self);
  { Evita artefato de pintura (outro controle parecendo por baixo) ate redesenho completo }
  if Assigned(btnAdd) then
    btnAdd.BringToFront;
  if Assigned(btnDelete) then
    btnDelete.BringToFront;
end;

procedure TfrmDeltaEditor.FormResize(Sender: TObject);
const
  TOP_ROWS = 80;
  BOTTOM_AREA = 40;
  MARGIN = 8;
var
  cw, ch, WCol: Integer;
begin
  cw := ClientWidth;
  ch := ClientHeight;
  if cw < 200 then Exit;
  if ch < 200 then Exit;

  { Botoes a direita usando largura real — edtContent encerra antes deles (sem sobrepor) }
  if Assigned(btnAdd) then
  begin
    btnAdd.Left := cw - btnAdd.Width - MARGIN;
    if Assigned(btnDelete) then
    begin
      btnDelete.Width := btnAdd.Width;
      btnDelete.Left := btnAdd.Left;
    end;
  end;

  if Assigned(edtContent) and Assigned(btnAdd) then
    edtContent.Width := Max(80, btnAdd.Left - edtContent.Left - MARGIN);

  if Assigned(lvDelta) then
  begin
    lvDelta.SetBounds(MARGIN, TOP_ROWS, Max(10, cw - 2 * MARGIN),
      Max(10, ch - TOP_ROWS - BOTTOM_AREA - MARGIN));
    if lvDelta.HandleAllocated and (lvDelta.Columns.Count >= 2) then
    begin
      WCol := lvDelta.ClientWidth - lvDelta.Columns[0].Width - GetSystemMetrics(SM_CXVSCROLL) - 8;
      if WCol < 120 then
        WCol := 120;
      lvDelta.Columns[1].Width := WCol;
      lvDelta.Invalidate;
    end;
  end;

  if Assigned(btnCopy) then
  begin
    btnCopy.Left := MARGIN;
    btnCopy.Top := ch - BOTTOM_AREA + 6;
  end;
  if Assigned(btnCancel) then
  begin
    btnCancel.Left := cw - btnCancel.Width - MARGIN;
    btnCancel.Top := ch - BOTTOM_AREA + 6;
  end;
  if Assigned(btnConfirm) then
  begin
    btnConfirm.Left := btnCancel.Left - btnConfirm.Width - MARGIN;
    btnConfirm.Top := ch - BOTTOM_AREA + 6;
  end;

  if Assigned(btnAdd) then
    btnAdd.BringToFront;
  if Assigned(btnDelete) then
    btnDelete.BringToFront;
end;

procedure TfrmDeltaEditor.lvDeltaSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) and (lvDelta.SelCount = 1) then
  begin
    edtLineNum.Text := Item.Caption;
    if Item.SubItems.Count > 0 then
      edtContent.Text := Item.SubItems[0]
    else
      edtContent.Text := '';
  end;
end;

end.
