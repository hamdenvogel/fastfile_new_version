object frmDeltaEditor: TfrmDeltaEditor
  Left = 200
  Top = 120
  Width = 628
  Height = 448
  Caption = 'Delta File Editor'
  ClientHeight = 420
  ClientWidth = 620
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnShow = FormShow
  OnResize = FormResize
  OnKeyDown = FormKeyDown
  object lblLineNum: TLabel
    Left = 16
    Top = 16
    Width = 70
    Height = 13
    Caption = 'Line Number:'
  end
  object lblContent: TLabel
    Left = 16
    Top = 48
    Width = 43
    Height = 13
    Caption = 'Content:'
  end
  object edtLineNum: TEdit
    Left = 100
    Top = 12
    Width = 100
    Height = 21
    TabOrder = 0
  end
  object edtContent: TEdit
    Left = 100
    Top = 44
    Width = 400
    Height = 21
    TabOrder = 1
  end
  object btnAdd: TButton
    Left = 505
    Top = 10
    Width = 105
    Height = 25
    Caption = 'Add/Update'
    TabOrder = 2
    OnClick = btnAddClick
  end
  object btnDelete: TButton
    Left = 505
    Top = 42
    Width = 105
    Height = 25
    Caption = 'Delete'
    TabOrder = 3
    OnClick = btnDeleteClick
  end
  object lvDelta: TListView
    Left = 8
    Top = 80
    Width = 604
    Height = 280
    TabOrder = 4
    Columns = <
      item
        Caption = 'Line Number'
        Width = 100
      end
      item
        Caption = 'Content'
        Width = 480
      end>
    MultiSelect = True
    RowSelect = True
    ViewStyle = vsReport
    OnSelectItem = lvDeltaSelectItem
  end
  object btnCopy: TButton
    Left = 8
    Top = 376
    Width = 75
    Height = 25
    Caption = 'Copy'
    TabOrder = 5
    OnClick = btnCopyClick
  end
  object btnConfirm: TButton
    Left = 420
    Top = 376
    Width = 75
    Height = 25
    Caption = 'Merge'
    ModalResult = 1
    TabOrder = 6
  end
  object btnCancel: TButton
    Left = 520
    Top = 376
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 7
  end
end
