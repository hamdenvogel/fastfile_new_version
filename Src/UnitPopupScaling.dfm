object FormPopupScaling: TFormPopupScaling
  Left = 0
  Top = 0
  Width = 353
  Height = 144
  Caption = 'FormPopupScaling'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object sPanel1: TsPanel
    Left = 0
    Top = 0
    Width = 337
    Height = 105
    SkinData.SkinSection = 'MAINMENU'
    Align = alClient
    BorderWidth = 3
    DoubleBuffered = False
    TabOrder = 0
    object sLabel1: TsLabel
      Left = 28
      Top = 72
      Width = 14
      Height = 14
      Caption = '72'
    end
    object sLabel2: TsLabel
      Left = 295
      Top = 72
      Width = 21
      Height = 14
      Caption = '288'
    end
    object sSpeedButton1: TsSpeedButton
      Left = 4
      Top = 4
      Width = 329
      Height = 29
      Caption = 'Auto scaling'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      Margin = 8
      ParentFont = False
      OnClick = sSpeedButton1Click
      Align = alTop
      AnimatEvents = []
      SkinData.SkinSection = 'MENUITEM'
      Images = sCharImageList1
      Alignment = taLeftJustify
      TextAlignment = taLeftJustify
      ImageIndex = 0
    end
    object sSpeedButton3: TsSpeedButton
      Tag = 2
      Left = 4
      Top = 35
      Width = 329
      Height = 29
      Caption = 'Custom PixelsPerInch value'
      Margin = 8
      OnClick = sSpeedButton1Click
      Align = alTop
      AnimatEvents = []
      SkinData.SkinSection = 'MENUITEM'
      Images = sCharImageList1
      Alignment = taLeftJustify
      TextAlignment = taLeftJustify
      ImageIndex = 1
    end
    object sBevel1: TsBevel
      Left = 4
      Top = 33
      Width = 329
      Height = 2
      Align = alTop
      Shape = bsTopLine
    end
    object sTrackBar1: TsTrackBar
      Left = 48
      Top = 68
      Width = 241
      Height = 33
      Max = 288
      Min = 72
      PageSize = 24
      Position = 96
      TabOrder = 0
      TickStyle = tsNone
      PositionToolTip = ptTop
      OnSkinPaint = sTrackBar1SkinPaint
      OnUserChange = sTrackBar1UserChange
      OnUserChanged = sTrackBar1UserChanged
    end
  end
  object sSkinProvider1: TsSkinProvider
    AddedTitle.Font.Charset = DEFAULT_CHARSET
    AddedTitle.Font.Color = clNone
    AddedTitle.Font.Height = -13
    AddedTitle.Font.Name = 'Tahoma'
    AddedTitle.Font.Style = []
    SkinData.SkinSection = 'FORM'
    TitleButtons = <>
    Left = 280
    Top = 28
  end
  object sCharImageList1: TsCharImageList
    Height = 14
    Width = 16
    EmbeddedFonts = <
      item
        FontName = 'FontAwesome'
        FontData = {}
      end>
    Items = <
      item
        Char = 61452
      end
      item
        Char = 216
      end>
    Left = 248
    Top = 28
    Bitmap = {}
  end
end
