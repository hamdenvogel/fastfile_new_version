object frmExportDialog: TfrmExportDialog
  Left = 452
  Top = 302
  BorderStyle = bsDialog
  Caption = 'Export Lines'
  ClientHeight = 185
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblInstruction: TLabel
    Left = 16
    Top = 16
    Width = 252
    Height = 13
    Caption = 'Enter the lines to export (e.g. 1-4 or 1,4,10):'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblExample: TLabel
    Left = 16
    Top = 68
    Width = 310
    Height = 26
    AutoSize = False
    Caption = 
      'Delimiters: "-" for ranges, "," or ";" for specific lines.'#13'Space' +
      's are ignored.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object Bevel1: TBevel
    Left = 16
    Top = 136
    Width = 313
    Height = 2
  end
  object edtLines: TEdit
    Left = 16
    Top = 38
    Width = 313
    Height = 21
    TabOrder = 0
  end
  object chkSaveToFile: TCheckBox
    Left = 16
    Top = 104
    Width = 241
    Height = 17
    Caption = 'Save to text file instead of clipboard'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object btnConfirm: TButton
    Left = 174
    Top = 148
    Width = 75
    Height = 25
    Caption = 'Export'
    Default = True
    TabOrder = 2
    OnClick = btnConfirmClick
  end
  object btnCancel: TButton
    Left = 254
    Top = 148
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 3
    OnClick = btnCancelClick
  end
end
