object frmTemp1D: TfrmTemp1D
  Left = 0
  Top = 0
  Caption = 'Temperatur1D '#8211' explizite 1D-W'#228'rmeleitung'
  ClientHeight = 780
  ClientWidth = 1200
  Color = clBtnFace
  Constraints.MinHeight = 760
  Constraints.MinWidth = 960
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlSettings: TPanel
    Left = 0
    Top = 0
    Width = 300
    Height = 757
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object lblHeader: TLabel
      AlignWithMargins = True
      Left = 12
      Top = 12
      Width = 276
      Height = 25
      Margins.Left = 12
      Margins.Top = 12
      Margins.Right = 12
      Margins.Bottom = 4
      Align = alTop
      Caption = 'Modelleinstellungen'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object gbMaterial: TGroupBox
      AlignWithMargins = True
      Left = 12
      Top = 45
      Width = 276
      Height = 92
      Margins.Left = 12
      Margins.Top = 4
      Margins.Right = 12
      Margins.Bottom = 4
      Align = alTop
      Caption = ' Material '
      TabOrder = 0
      object lblTlf: TLabel
        Left = 12
        Top = 60
        Width = 134
        Height = 15
        Caption = 'Leitf'#228'higkeit a (mm'#178'/s)'
      end
      object cbMaterial: TComboBox
        Left = 12
        Top = 24
        Width = 252
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        OnChange = cbMaterialChange
      end
      object nbTlf: TNumberBox
        Left = 180
        Top = 56
        Width = 84
        Height = 23
        Mode = nbmFloat
        TabOrder = 1
        OnChangeValue = nbTlfChangeValue
      end
    end
    object gbGrid: TGroupBox
      AlignWithMargins = True
      Left = 12
      Top = 145
      Width = 276
      Height = 92
      Margins.Left = 12
      Margins.Top = 4
      Margins.Right = 12
      Margins.Bottom = 4
      Align = alTop
      Caption = ' Gitter '
      TabOrder = 1
      object lblNodes: TLabel
        Left = 12
        Top = 28
        Width = 83
        Height = 15
        Caption = 'Anzahl Knoten'
      end
      object lblDx: TLabel
        Left = 12
        Top = 60
        Width = 128
        Height = 15
        Caption = 'Knotenabstand dx (cm)'
      end
      object nbNodes: TNumberBox
        Left = 180
        Top = 24
        Width = 84
        Height = 23
        Mode = nbmInteger
        TabOrder = 0
        OnChangeValue = ParamChanged
      end
      object nbDx: TNumberBox
        Left = 180
        Top = 56
        Width = 84
        Height = 23
        Mode = nbmFloat
        TabOrder = 1
        OnChangeValue = ParamChanged
      end
    end
    object gbBoundary: TGroupBox
      AlignWithMargins = True
      Left = 12
      Top = 245
      Width = 276
      Height = 124
      Margins.Left = 12
      Margins.Top = 4
      Margins.Right = 12
      Margins.Bottom = 4
      Align = alTop
      Caption = ' Start- und Randbedingungen '
      TabOrder = 2
      object lblTinit: TLabel
        Left = 12
        Top = 28
        Width = 121
        Height = 15
        Caption = 'Starttemperatur ('#176'C)'
      end
      object lblAmplitude: TLabel
        Left = 12
        Top = 60
        Width = 135
        Height = 15
        Caption = 'Amplitude links A (K)'
      end
      object lblPeriod: TLabel
        Left = 12
        Top = 92
        Width = 112
        Height = 15
        Caption = 'Periode links P (h)'
      end
      object nbTinit: TNumberBox
        Left = 180
        Top = 24
        Width = 84
        Height = 23
        Mode = nbmFloat
        TabOrder = 0
        OnChangeValue = ParamChanged
      end
      object nbAmplitude: TNumberBox
        Left = 180
        Top = 56
        Width = 84
        Height = 23
        Mode = nbmFloat
        TabOrder = 1
        OnChangeValue = ParamChanged
      end
      object nbPeriod: TNumberBox
        Left = 180
        Top = 88
        Width = 84
        Height = 23
        Mode = nbmFloat
        TabOrder = 2
        OnChangeValue = ParamChanged
      end
    end
    object gbTime: TGroupBox
      AlignWithMargins = True
      Left = 12
      Top = 377
      Width = 276
      Height = 124
      Margins.Left = 12
      Margins.Top = 4
      Margins.Right = 12
      Margins.Bottom = 4
      Align = alTop
      Caption = ' Zeit '
      TabOrder = 3
      object lblDt: TLabel
        Left = 12
        Top = 28
        Width = 111
        Height = 15
        Caption = 'Zeitschritt dt (min)'
      end
      object lblSteps: TLabel
        Left = 12
        Top = 60
        Width = 105
        Height = 15
        Caption = 'Schritte pro Klick'
      end
      object nbDt: TNumberBox
        Left = 180
        Top = 24
        Width = 84
        Height = 23
        Mode = nbmFloat
        TabOrder = 0
        OnChangeValue = ParamChanged
      end
      object nbSteps: TNumberBox
        Left = 180
        Top = 56
        Width = 84
        Height = 23
        Mode = nbmInteger
        TabOrder = 1
      end
      object cbAutoSubstep: TCheckBox
        Left = 12
        Top = 92
        Width = 252
        Height = 19
        Caption = 'Stabilit'#228't sichern (Unterschritte)'
        TabOrder = 2
        OnClick = ParamChanged
      end
    end
    object lblStability: TLabel
      AlignWithMargins = True
      Left = 12
      Top = 513
      Width = 276
      Height = 44
      Margins.Left = 12
      Margins.Top = 8
      Margins.Right = 12
      Align = alTop
      AutoSize = False
      WordWrap = True
    end
    object pnlButtons: TPanel
      Left = 0
      Top = 637
      Width = 300
      Height = 120
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 4
      object lblStyle: TLabel
        Left = 12
        Top = 92
        Width = 35
        Height = 15
        Caption = 'Design'
      end
      object btStart: TButton
        Left = 12
        Top = 4
        Width = 124
        Height = 34
        Caption = 'Start'
        TabOrder = 0
        OnClick = btStartClick
      end
      object btEinzelschritt: TButton
        Left = 140
        Top = 4
        Width = 124
        Height = 34
        Caption = 'Weiter'
        TabOrder = 1
        OnClick = btEinzelschrittClick
      end
      object btExport: TButton
        Left = 12
        Top = 46
        Width = 252
        Height = 30
        Caption = 'Zeitreihen als CSV exportieren...'
        TabOrder = 2
        OnClick = btExportClick
      end
      object cbStyle: TComboBox
        Left = 64
        Top = 88
        Width = 200
        Height = 23
        Style = csDropDownList
        TabOrder = 3
        OnChange = cbStyleChange
      end
    end
  end
  object pnlMain: TPanel
    Left = 300
    Top = 0
    Width = 900
    Height = 757
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object pnlSystem: TPanel
      AlignWithMargins = True
      Left = 4
      Top = 12
      Width = 884
      Height = 140
      Margins.Left = 4
      Margins.Top = 12
      Margins.Right = 12
      Margins.Bottom = 8
      Align = alTop
      BevelOuter = bvNone
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 0
      object pbSystem: TPaintBox
        Left = 0
        Top = 0
        Width = 884
        Height = 140
        Align = alClient
        OnPaint = pbSystemPaint
      end
    end
    object PageControl1: TPageControl
      AlignWithMargins = True
      Left = 4
      Top = 160
      Width = 884
      Height = 585
      Margins.Left = 4
      Margins.Top = 0
      Margins.Right = 12
      Margins.Bottom = 12
      ActivePage = tsTime
      Align = alClient
      TabOrder = 1
      object tsTime: TTabSheet
        Caption = 'Zeitverlauf'
        object ChartTime: TChart
          Left = 0
          Top = 0
          Width = 876
          Height = 555
          BackWall.Brush.Style = bsClear
          Legend.Alignment = laBottom
          Legend.CheckBoxes = True
          Legend.FontSeriesColor = True
          Title.Text.Strings = (
            'Temperaturschwingungen')
          View3D = False
          Align = alClient
          BevelOuter = bvNone
          Color = clWhite
          TabOrder = 0
          DefaultCanvas = 'TGDIPlusCanvas'
          ColorPaletteIndex = 13
        end
      end
      object tsProfile: TTabSheet
        Caption = 'Tiefenprofil'
        object ChartProfile: TChart
          Left = 0
          Top = 0
          Width = 876
          Height = 555
          BackWall.Brush.Style = bsClear
          Legend.Alignment = laBottom
          Legend.FontSeriesColor = True
          Title.Text.Strings = (
            'Tiefenprofil')
          View3D = False
          Align = alClient
          BevelOuter = bvNone
          Color = clWhite
          TabOrder = 0
          DefaultCanvas = 'TGDIPlusCanvas'
          ColorPaletteIndex = 13
        end
      end
      object tsInfo: TTabSheet
        Caption = 'Info'
        object Memo1: TMemo
          AlignWithMargins = True
          Left = 8
          Top = 8
          Width = 860
          Height = 539
          Margins.Left = 8
          Margins.Top = 8
          Margins.Right = 8
          Margins.Bottom = 8
          Align = alClient
          BorderStyle = bsNone
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Consolas'
          Font.Style = []
          ParentColor = True
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 757
    Width = 1200
    Height = 23
    Panels = <
      item
        Width = 220
      end
      item
        Width = 140
      end
      item
        Width = 50
      end>
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'csv'
    FileName = 'temperatur1d.csv'
    Filter = 'CSV-Dateien (*.csv)|*.csv|Alle Dateien (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Zeitreihen exportieren'
    Left = 1120
    Top = 24
  end
end
