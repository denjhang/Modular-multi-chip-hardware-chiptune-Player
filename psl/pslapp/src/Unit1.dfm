object MainForm: TMainForm
  Left = 283
  Top = 629
  Width = 313
  Height = 116
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    305
    89)
  PixelsPerInch = 96
  TextHeight = 12
  object TimeLbl: TLabel
    Left = 152
    Top = 7
    Width = 40
    Height = 13
    Hint = #29694#22312
    Alignment = taCenter
    AutoSize = False
    Caption = '888:88'
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #65325#65331' '#12468#12471#12483#12463
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    Layout = tlCenter
  end
  object StopBtn: TSpeedButton
    Left = 32
    Top = 8
    Width = 24
    Height = 24
    Hint = #20572#27490
    Enabled = False
    Flat = True
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
    Font.Style = []
    Glyph.Data = {
      F6000000424DF600000000000000760000002800000010000000100000000100
      0400000000008000000000000000000000001000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
      8888888888888888888888888888888888888888888888888888888800000000
      8888888800000000888888880000000088888888000000008888888800000000
      8888888800000000888888880000000088888888000000008888888888888888
      8888888888888888888888888888888888888888888888888888}
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = StopBtnClick
  end
  object PlayBtn: TSpeedButton
    Left = 8
    Top = 8
    Width = 24
    Height = 24
    Hint = #20877#29983
    Flat = True
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
    Font.Style = []
    Glyph.Data = {
      F6000000424DF600000000000000760000002800000010000000100000000100
      0400000000008000000000000000000000001000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
      8888888888888888888888888888888888888888808888888888888880088888
      8888888880008888888888888000088888888888800000888888888880000088
      8888888880000888888888888000888888888888800888888888888880888888
      8888888888888888888888888888888888888888888888888888}
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = PlayBtnClick
  end
  object PrevBtn: TSpeedButton
    Left = 64
    Top = 8
    Width = 24
    Height = 24
    Hint = #21069#12398#12501#12449#12452#12523
    Flat = True
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
    Font.Style = []
    Glyph.Data = {
      F6000000424DF600000000000000760000002800000010000000100000000100
      0400000000008000000000000000000000001000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
      8888888888888888888888888888888888888888808888808888888880888800
      8888888880888000888888888088000088888888808000008888888880800000
      8888888880880000888888888088800088888888808888008888888880888880
      8888888888888888888888888888888888888888888888888888}
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = PrevBtnClick
  end
  object NextBtn: TSpeedButton
    Left = 88
    Top = 8
    Width = 24
    Height = 24
    Hint = #27425#12398#12501#12449#12452#12523
    Flat = True
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
    Font.Style = []
    Glyph.Data = {
      F6000000424DF600000000000000760000002800000010000000100000000100
      0400000000008000000000000000000000001000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
      8888888888888888888888888888888888888888088888088888888800888808
      8888888800088808888888880000880888888888000008088888888800000808
      8888888800008808888888880008880888888888008888088888888808888808
      8888888888888888888888888888888888888888888888888888}
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = NextBtnClick
  end
  object DevBtn: TSpeedButton
    Left = 120
    Top = 8
    Width = 24
    Height = 24
    Hint = #35373#23450
    Flat = True
    Glyph.Data = {
      F6000000424DF600000000000000760000002800000010000000100000000100
      0400000000008000000000000000000000001000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
      8888888888888888888888888888888888888888888888888888888888888888
      8888888888808888888888888080808888888888880008888888888888808888
      8888888888000888888888888080808888888888888088888888888888888888
      8888888888888888888888888888888888888888888888888888}
    ParentShowHint = False
    ShowHint = True
    OnClick = DevBtnClick
  end
  object EndTimeLbl: TLabel
    Left = 152
    Top = 21
    Width = 40
    Height = 13
    Hint = #32066#20102
    Alignment = taCenter
    AutoSize = False
    Caption = '888:88'
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #65325#65331' '#12468#12471#12483#12463
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    Layout = tlCenter
  end
  object Memo: TMemo
    Left = 200
    Top = 6
    Width = 97
    Height = 29
    Anchors = [akLeft, akTop, akRight]
    Ctl3D = False
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
    Font.Style = []
    Lines.Strings = (
      'Mem'
      'o')
    ParentCtl3D = False
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object ListView: TListView
    Left = 8
    Top = 40
    Width = 289
    Height = 41
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = #12501#12457#12523#12480
        MinWidth = 80
        Width = 96
      end
      item
        Caption = #12501#12449#12452#12523#21517
        MinWidth = 80
        Width = 128
      end
      item
        Caption = #24418#24335
        MinWidth = 40
        Width = 40
      end
      item
        Caption = #38899#28304
        MinWidth = 40
        Width = 40
      end>
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    PopupMenu = PopupMenu
    TabOrder = 0
    ViewStyle = vsReport
    OnAdvancedCustomDrawItem = ListViewAdvancedCustomDrawItem
    OnColumnClick = ListViewColumnClick
    OnDblClick = ListViewDblClick
    OnKeyDown = ListViewKeyDown
  end
  object PopupMenu: TPopupMenu
    Left = 80
    Top = 40
    object PMPlay: TMenuItem
      Caption = #20877#29983'(&P)'
      OnClick = ListViewDblClick
    end
    object PMStop: TMenuItem
      Caption = #20572#27490'(&S)'
      Enabled = False
      OnClick = StopBtnClick
    end
    object PMPrev: TMenuItem
      Caption = #21069#12398#12501#12449#12452#12523'(&B)'
      OnClick = PrevBtnClick
    end
    object PMNext: TMenuItem
      Caption = #27425#12398#12501#12449#12452#12523'(&N)'
      OnClick = NextBtnClick
    end
    object PMDev: TMenuItem
      Caption = #35373#23450'(&G)'
      OnClick = DevBtnClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object PMOpen: TMenuItem
      Caption = #12501#12449#12452#12523#12434#12522#12473#12488#12395#36861#21152'(&O)'
      OnClick = PMOpenClick
    end
    object PMFolder: TMenuItem
      Caption = #12501#12457#12523#12480#12434#12522#12473#12488#12395#36861#21152'(&F)'
      OnClick = PMFolderClick
    end
    object PMSelect: TMenuItem
      Caption = #20877#29983#20013#12398#12501#12449#12452#12523#12434#36984#25246'(&L)'
      OnClick = PMSelectClick
    end
    object PMExplorer: TMenuItem
      Caption = #12456#12463#12473#12503#12525#12540#12521#12391#20877#29983#20013#12398#12501#12449#12452#12523#12434#36984#25246'(&E)'
      OnClick = PMExplorerClick
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object PMDelete: TMenuItem
      Caption = #36984#25246#12375#12390#12356#12427#12501#12449#12452#12523#12434#12522#12473#12488#12363#12425#21066#38500'(&D)'
      OnClick = PMDeleteClick
    end
    object PMExist: TMenuItem
      Caption = #23384#22312#12375#12394#12356#12501#12449#12452#12523#12434#12522#12473#12488#12363#12425#21066#38500'(&I)'
      OnClick = PMExistClick
    end
    object PMDuplicate1: TMenuItem
      Caption = #21516#12376#12497#12473#12398#12501#12449#12452#12523#12434#12522#12473#12488#12363#12425#21066#38500'(&T)'
      OnClick = PMDuplicate1Click
    end
    object PMAllDelete: TMenuItem
      Caption = #12377#12409#12390#12398#12501#12449#12452#12523#12434#12522#12473#12488#12363#12425#21066#38500'(&A)'
      OnClick = PMAllDeleteClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object PMClose: TMenuItem
      Caption = #38281#12376#12427'(&X)'
    end
  end
  object OpenDlg: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofShareAware, ofEnableSizing, ofDontAddToRecent, ofForceShowHidden]
    Left = 32
    Top = 40
  end
end
