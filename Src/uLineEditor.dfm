object frmLineEditor: TfrmLineEditor
  Left = 452
  Top = 236
  BorderStyle = bsDialog
  Caption = 'File Line Editor'
  ClientHeight = 310
  ClientWidth = 356
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 60
    Height = 13
    Caption = 'Operation:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 16
    Top = 64
    Width = 76
    Height = 13
    Caption = 'Line Number:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label3: TLabel
    Left = 16
    Top = 112
    Width = 49
    Height = 13
    Caption = 'Content:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Bevel1: TBevel
    Left = 16
    Top = 264
    Width = 321
    Height = 2
  end
  object cbOperation: TComboBox
    Left = 16
    Top = 32
    Width = 321
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
    OnChange = cbOperationChange
  end
  object edtLineNumber: TEdit
    Left = 16
    Top = 80
    Width = 121
    Height = 21
    TabOrder = 1
  end
  object mmContent: TMemo
    Left = 16
    Top = 128
    Width = 321
    Height = 121
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object btnConfirm: TButton
    Left = 176
    Top = 276
    Width = 75
    Height = 25
    Caption = 'Confirm'
    Default = True
    TabOrder = 3
    OnClick = btnConfirmClick
  end
  object btnCancel: TButton
    Left = 262
    Top = 276
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 4
    OnClick = btnCancelClick
  end
end
