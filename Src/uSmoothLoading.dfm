object frmSmoothLoadingForm: TfrmSmoothLoadingForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'frmSmoothLoading'
  ClientHeight = 480
  ClientWidth = 640
  Color = 2631710
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWhite
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  WindowState = wsMaximized
  OnPaint = FormPaint
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlContainer: TPanel
    Left = 150
    Top = 80
    Width = 340
    Height = 360
    BevelOuter = bvNone
    Color = 3946026
    ParentBackground = False
    TabOrder = 0
    object imgLogo: TImage
      Left = 0
      Top = 0
      Width = 340
      Height = 180
      Align = alTop
      Center = True
      Stretch = True
      Transparent = True
    end
    object lblMessage: TLabel
      Left = 0
      Top = 180
      Width = 340
      Height = 25
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'Processando...'
      Color = 3946026
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16773350
      Font.Height = -16
      Font.Name = 'Segoe UI Semilight'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object lblDetail: TLabel
      Left = 0
      Top = 205
      Width = 340
      Height = 44
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Color = 3946026
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15263976
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      WordWrap = True
    end
    object pbProgressBar: TPaintBox
      Left = 60
      Top = 290
      Width = 220
      Height = 4
      OnPaint = pbProgressBarPaint
    end
  end
  object tmrAnimation: TTimer
    Enabled = False
    Interval = 15
    OnTimer = tmrAnimationTimer
    Left = 24
    Top = 24
  end
end
