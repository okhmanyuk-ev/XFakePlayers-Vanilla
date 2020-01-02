object Engine: TEngine
  Tag = 264
  Left = 0
  Top = 0
  ClientHeight = 269
  ClientWidth = 416
  Color = clBlack
  Constraints.MinHeight = 307
  Constraints.MinWidth = 432
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clYellow
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = [fsBold]
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ControlPanel: TPanel
    Left = 0
    Top = 244
    Width = 416
    Height = 25
    Align = alBottom
    BevelOuter = bvNone
    Color = -1
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      416
      25)
    object Label14: TLabel
      Left = 150
      Top = 6
      Width = 3
      Height = 13
    end
    object Start: TButton
      Left = 4
      Top = 4
      Width = 67
      Height = 17
      Caption = 'Start'
      TabOrder = 0
      OnClick = StartClick
    end
    object Stop: TButton
      Left = 77
      Top = 4
      Width = 67
      Height = 17
      Caption = 'Pause'
      Enabled = False
      TabOrder = 1
      OnClick = StopClick
    end
    object BAbout: TButton
      Left = 342
      Top = 4
      Width = 67
      Height = 17
      Anchors = [akTop, akRight]
      Caption = 'About'
      TabOrder = 2
      OnClick = BAboutClick
    end
  end
  object PageControl1: TPageControl
    Tag = 212
    Left = 0
    Top = 0
    Width = 416
    Height = 244
    ActivePage = TabSheet6
    Align = alClient
    TabOrder = 1
    object TabSheet6: TTabSheet
      Caption = 'General'
      ImageIndex = 5
      object PanelOptions: TPanel
        Left = 199
        Top = 0
        Width = 209
        Height = 216
        Align = alRight
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 0
        object Panel3: TPanel
          Left = 0
          Top = 17
          Width = 209
          Height = 75
          Align = alTop
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 0
          DesignSize = (
            209
            75)
          object MaxOnline: TSpinEdit
            Left = 127
            Top = 2
            Width = 79
            Height = 22
            Anchors = [akTop, akRight]
            Color = -1
            MaxValue = 999999
            MinValue = 0
            TabOrder = 0
            Value = 31
          end
          object MaxOnlineEnabled: TCheckBox
            Left = 6
            Top = 4
            Width = 93
            Height = 17
            Caption = 'Max Online:'
            TabOrder = 1
          end
          object DelayEnabled: TCheckBox
            Left = 6
            Top = 29
            Width = 83
            Height = 17
            Caption = 'Delay:'
            TabOrder = 2
          end
          object Delay: TSpinEdit
            Left = 127
            Top = 26
            Width = 79
            Height = 22
            Anchors = [akTop, akRight]
            Color = -1
            MaxValue = 999999
            MinValue = 1
            TabOrder = 3
            Value = 5000
          end
          object ListDelayEnabled: TCheckBox
            Left = 6
            Top = 54
            Width = 99
            Height = 17
            Caption = 'List Delay:'
            TabOrder = 4
          end
          object ListDelay: TSpinEdit
            Left = 127
            Top = 50
            Width = 79
            Height = 22
            Anchors = [akTop, akRight]
            Color = -1
            MaxValue = 999999
            MinValue = 1
            TabOrder = 5
            Value = 60000
          end
        end
        object Panel4: TPanel
          AlignWithMargins = True
          Left = 0
          Top = 95
          Width = 209
          Height = 71
          Margins.Left = 0
          Margins.Right = 0
          Align = alTop
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 1
          DesignSize = (
            209
            71)
          object Label18: TLabel
            Left = 8
            Top = 6
            Width = 54
            Height = 13
            Caption = 'Emulator:'
          end
          object Label19: TLabel
            Left = 8
            Top = 29
            Width = 35
            Height = 13
            Caption = 'Name:'
          end
          object Label20: TLabel
            Left = 8
            Top = 52
            Width = 35
            Height = 13
            Caption = 'Team:'
          end
          object Emulator: TComboBox
            Left = 70
            Top = 2
            Width = 136
            Height = 21
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Color = clBlack
            ItemIndex = 0
            TabOrder = 0
            Text = 'Random'
            Items.Strings = (
              'Random'
              'RevEmu'
              'AVSMP'
              'SteamEmu'
              'OldRevEmu')
          end
          object NickName: TComboBox
            Left = 70
            Top = 25
            Width = 136
            Height = 21
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Color = clBlack
            ItemIndex = 0
            TabOrder = 1
            Text = 'Random'
            OnSelect = BNameSelect
            Items.Strings = (
              'Random'
              'Random From List')
          end
          object Team: TComboBox
            Left = 70
            Top = 48
            Width = 136
            Height = 21
            Style = csDropDownList
            Anchors = [akTop, akRight]
            Color = clBlack
            ItemIndex = 0
            TabOrder = 2
            Text = 'Random'
            Items.Strings = (
              'Random'
              'Terrorist'
              'Counter-Terrorists'
              'Spectator')
          end
        end
        object Panel5: TPanel
          Left = 0
          Top = 169
          Width = 209
          Height = 47
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 10
          Align = alClient
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 2
          object LaunchAtStartup: TCheckBox
            Left = 6
            Top = 3
            Width = 139
            Height = 17
            Caption = 'Launch at startup'
            TabOrder = 0
          end
        end
        object Panel9: TPanel
          Left = 0
          Top = 0
          Width = 209
          Height = 17
          Margins.Left = 4
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alTop
          BevelOuter = bvNone
          Caption = 'Options'
          Color = clBlack
          ParentBackground = False
          TabOrder = 3
        end
      end
      object PanelServers: TPanel
        Left = 0
        Top = 0
        Width = 199
        Height = 216
        Align = alClient
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 1
        object Servers: TMemo
          AlignWithMargins = True
          Left = 2
          Top = 19
          Width = 195
          Height = 175
          Margins.Left = 2
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 2
          Align = alClient
          Color = clBlack
          ScrollBars = ssVertical
          TabOrder = 0
          WordWrap = False
          OnChange = ServersChange
        end
        object Panel8: TPanel
          Left = 0
          Top = 0
          Width = 199
          Height = 17
          Margins.Left = 4
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alTop
          BevelOuter = bvNone
          Caption = 'Servers'
          Color = clBlack
          ParentBackground = False
          TabOrder = 1
        end
        object ResolveIPAddressesForServers: TButton
          AlignWithMargins = True
          Left = 3
          Top = 199
          Width = 193
          Height = 14
          Align = alBottom
          Caption = 'resolve ip-addresses'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clYellow
          Font.Height = -9
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 2
          OnClick = ResolveIPAddressesForServersClick
        end
      end
    end
    object TabSheet7: TTabSheet
      Caption = 'Security'
      ImageIndex = 6
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 199
        Height = 216
        Align = alClient
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 0
        object Proxies: TMemo
          AlignWithMargins = True
          Left = 2
          Top = 19
          Width = 195
          Height = 175
          Margins.Left = 2
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 2
          Align = alClient
          Color = clBlack
          ScrollBars = ssVertical
          TabOrder = 0
          WordWrap = False
          OnChange = ProxiesChange
        end
        object Panel7: TPanel
          AlignWithMargins = True
          Left = 4
          Top = 0
          Width = 195
          Height = 17
          Margins.Left = 4
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alTop
          Alignment = taLeftJustify
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 1
          object ProxiesEnabled: TCheckBox
            AlignWithMargins = True
            Left = 4
            Top = 0
            Width = 191
            Height = 17
            Margins.Left = 4
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 0
            Align = alClient
            Caption = 'Proxies:'
            TabOrder = 0
          end
        end
        object ResolveIPAddressesForProxies: TButton
          AlignWithMargins = True
          Left = 3
          Top = 199
          Width = 193
          Height = 14
          Align = alBottom
          Caption = 'resolve ip-addresses'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clYellow
          Font.Height = -9
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 2
          OnClick = ResolveIPAddressesForProxiesClick
        end
      end
      object Panel10: TPanel
        Left = 199
        Top = 0
        Width = 209
        Height = 216
        Align = alRight
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 1
        object Panel14: TPanel
          AlignWithMargins = True
          Left = 4
          Top = 124
          Width = 205
          Height = 92
          Margins.Left = 4
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alClient
          Alignment = taLeftJustify
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 0
        end
        object Panel11: TPanel
          Left = 0
          Top = 0
          Width = 209
          Height = 17
          Margins.Left = 4
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alTop
          BevelOuter = bvNone
          Caption = 'Options'
          Color = clBlack
          ParentBackground = False
          TabOrder = 1
        end
        object Panel6: TPanel
          Left = 0
          Top = 17
          Width = 209
          Height = 107
          Align = alTop
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 2
          DesignSize = (
            209
            107)
          object Label5: TLabel
            Left = 6
            Top = 57
            Width = 49
            Height = 13
            Caption = 'Threads:'
          end
          object Label6: TLabel
            Left = 6
            Top = 81
            Width = 76
            Height = 13
            Caption = 'Check Period:'
          end
          object ProxyType: TRadioGroup
            Left = 0
            Top = 0
            Width = 209
            Height = 51
            Align = alTop
            Caption = 'Proxy Type'
            Ctl3D = False
            ItemIndex = 0
            Items.Strings = (
              'Socks5'
              'HLProxy')
            ParentCtl3D = False
            TabOrder = 0
            OnClick = ProxyTypeClick
          end
          object CheckThreads: TSpinEdit
            Left = 127
            Top = 53
            Width = 79
            Height = 22
            Anchors = [akTop, akRight]
            Color = -1
            MaxValue = 100
            MinValue = 1
            TabOrder = 1
            Value = 10
          end
          object CheckPeriod: TSpinEdit
            Left = 127
            Top = 77
            Width = 79
            Height = 22
            Anchors = [akTop, akRight]
            Color = -1
            MaxValue = 999999
            MinValue = 1000
            TabOrder = 2
            Value = 60000
          end
        end
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Advanced'
      ImageIndex = 6
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label12: TLabel
        Left = 218
        Top = 123
        Width = 7
        Height = 13
        Alignment = taRightJustify
        Caption = '1'
      end
      object Label11: TLabel
        Left = 8
        Top = 123
        Width = 38
        Height = 13
        Caption = 'Speed:'
      end
      object MoveSpeed: TTrackBar
        Left = 56
        Top = 122
        Width = 148
        Height = 17
        Margins.Left = 1
        Margins.Top = 1
        Margins.Right = 1
        Margins.Bottom = 1
        Min = 1
        ParentShowHint = False
        PageSize = 1
        Position = 1
        ShowHint = False
        TabOrder = 0
        ThumbLength = 15
        OnChange = MoveSpeedChange
      end
      object LogAI: TCheckBox
        Left = 8
        Top = 86
        Width = 91
        Height = 17
        Caption = 'Log AI'
        TabOrder = 1
      end
      object LogQCC: TCheckBox
        Left = 8
        Top = 3
        Width = 74
        Height = 17
        Caption = 'Log QCC'
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
      object LogStuffText: TCheckBox
        Left = 8
        Top = 20
        Width = 109
        Height = 17
        Caption = 'Log StuffText'
        TabOrder = 3
      end
      object LogDirector: TCheckBox
        Left = 8
        Top = 37
        Width = 107
        Height = 17
        Caption = 'Log Director'
        TabOrder = 4
      end
      object LogForwards: TCheckBox
        Left = 8
        Top = 53
        Width = 109
        Height = 17
        Caption = 'Log Forwards'
        TabOrder = 5
      end
      object LogSocks5: TCheckBox
        Left = 8
        Top = 69
        Width = 109
        Height = 17
        Caption = 'Log Socks5'
        TabOrder = 6
      end
      object AIEnabled: TCheckBox
        Left = 184
        Top = 2
        Width = 97
        Height = 17
        Caption = 'AI Enabled'
        Checked = True
        State = cbChecked
        TabOrder = 7
        OnClick = AI_EnabledClick
      end
      object DownloadWorld: TCheckBox
        Left = 184
        Top = 20
        Width = 115
        Height = 17
        Caption = 'Download World'
        Checked = True
        State = cbChecked
        TabOrder = 8
        OnClick = DownloadWorldClick
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'Flood'
      ImageIndex = 6
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Panel12: TPanel
        Left = 0
        Top = 0
        Width = 199
        Height = 216
        Align = alClient
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 0
        object Panel13: TPanel
          Left = 0
          Top = 0
          Width = 199
          Height = 105
          Align = alTop
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 0
          object Panel16: TPanel
            AlignWithMargins = True
            Left = 4
            Top = 0
            Width = 195
            Height = 17
            Margins.Left = 4
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 0
            Align = alTop
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Color = clBlack
            ParentBackground = False
            TabOrder = 0
            object LoopCommandsEnabled: TCheckBox
              AlignWithMargins = True
              Left = 4
              Top = 0
              Width = 191
              Height = 17
              Margins.Left = 4
              Margins.Top = 0
              Margins.Right = 0
              Margins.Bottom = 0
              Align = alClient
              Caption = 'Loop Commands:'
              TabOrder = 0
            end
          end
          object LoopCommands: TMemo
            AlignWithMargins = True
            Left = 2
            Top = 19
            Width = 195
            Height = 84
            Margins.Left = 2
            Margins.Top = 2
            Margins.Right = 2
            Margins.Bottom = 2
            Align = alClient
            Color = clBlack
            ScrollBars = ssVertical
            TabOrder = 1
            WordWrap = False
            OnChange = ServersChange
          end
        end
        object Panel15: TPanel
          Left = 0
          Top = 105
          Width = 199
          Height = 111
          Align = alClient
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 1
          object Panel17: TPanel
            AlignWithMargins = True
            Left = 4
            Top = 0
            Width = 195
            Height = 17
            Margins.Left = 4
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 0
            Align = alTop
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Color = clBlack
            ParentBackground = False
            TabOrder = 0
            object SignonCommandsEnabled: TCheckBox
              AlignWithMargins = True
              Left = 4
              Top = 0
              Width = 191
              Height = 17
              Margins.Left = 4
              Margins.Top = 0
              Margins.Right = 0
              Margins.Bottom = 0
              Align = alClient
              Caption = 'Signon Commands:'
              TabOrder = 0
            end
          end
          object SignonCommands: TMemo
            AlignWithMargins = True
            Left = 2
            Top = 19
            Width = 195
            Height = 90
            Margins.Left = 2
            Margins.Top = 2
            Margins.Right = 2
            Margins.Bottom = 2
            Align = alClient
            Color = clBlack
            ScrollBars = ssVertical
            TabOrder = 1
            WordWrap = False
            OnChange = ServersChange
          end
        end
      end
      object Panel18: TPanel
        Left = 199
        Top = 0
        Width = 209
        Height = 216
        Align = alRight
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 1
        object Panel19: TPanel
          Left = 0
          Top = 20
          Width = 209
          Height = 196
          Margins.Left = 4
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alClient
          Alignment = taLeftJustify
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 0
          object Panel21: TPanel
            Left = 0
            Top = 30
            Width = 209
            Height = 158
            Align = alTop
            BevelOuter = bvNone
            Color = clBlack
            ParentBackground = False
            TabOrder = 0
            DesignSize = (
              209
              158)
            object Label1: TLabel
              Left = 6
              Top = 55
              Width = 59
              Height = 13
              Caption = 'Voice Size:'
            end
            object Label3: TLabel
              Left = 6
              Top = 78
              Width = 69
              Height = 13
              Caption = 'Voice Count:'
            end
            object VoiceFloodEnabled: TCheckBox
              Left = 6
              Top = 2
              Width = 94
              Height = 17
              Caption = 'Voice Flood'
              TabOrder = 0
            end
            object RadioFloodEnabled: TCheckBox
              Left = 6
              Top = 116
              Width = 94
              Height = 17
              Anchors = [akLeft, akBottom]
              Caption = 'Radio Flood'
              TabOrder = 1
            end
            object VoiceFloodDelay: TSpinEdit
              Left = 135
              Top = 17
              Width = 71
              Height = 22
              Anchors = [akTop, akRight]
              Color = -1
              MaxValue = 999999
              MinValue = 1
              TabOrder = 2
              Value = 10000
            end
            object VoiceFloodDelayEnabled: TCheckBox
              Left = 6
              Top = 20
              Width = 123
              Height = 17
              Caption = 'Voice Flood Delay:'
              TabOrder = 3
            end
            object RadioFloodDelayEnabled: TCheckBox
              Left = 6
              Top = 134
              Width = 123
              Height = 17
              Anchors = [akLeft, akBottom]
              Caption = 'Radio Flood Delay:'
              TabOrder = 4
            end
            object RadioFloodDelay: TSpinEdit
              Left = 135
              Top = 131
              Width = 71
              Height = 22
              Anchors = [akLeft, akBottom]
              Color = -1
              MaxValue = 999999
              MinValue = 1
              TabOrder = 5
              Value = 10000
            end
            object VoiceSize: TSpinEdit
              Left = 135
              Top = 51
              Width = 71
              Height = 22
              Anchors = [akTop, akRight]
              Color = -1
              MaxValue = 999999
              MinValue = 1
              TabOrder = 6
              Value = 100
            end
            object VoiceCount: TSpinEdit
              Left = 135
              Top = 75
              Width = 71
              Height = 22
              Anchors = [akTop, akRight]
              Color = -1
              MaxValue = 999999
              MinValue = 1
              TabOrder = 7
              Value = 10
            end
          end
          object Panel22: TPanel
            Left = 0
            Top = 0
            Width = 209
            Height = 30
            Align = alTop
            BevelEdges = [beBottom]
            BevelKind = bkSoft
            BevelOuter = bvNone
            Color = clBlack
            ParentBackground = False
            TabOrder = 1
            DesignSize = (
              209
              28)
            object Label2: TLabel
              Left = 8
              Top = 6
              Width = 69
              Height = 13
              Caption = 'Loop Period:'
            end
            object LoopDelay: TSpinEdit
              Left = 135
              Top = 2
              Width = 71
              Height = 22
              Anchors = [akTop, akRight]
              Color = -1
              MaxValue = 999999
              MinValue = 1
              TabOrder = 0
              Value = 2500
            end
          end
        end
        object Panel20: TPanel
          Left = 0
          Top = 0
          Width = 209
          Height = 20
          Margins.Left = 4
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alTop
          BevelOuter = bvNone
          Caption = 'Options'
          Color = clBlack
          ParentBackground = False
          TabOrder = 1
        end
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Clients'
      ImageIndex = 4
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object EClients: TListView
        Left = 0
        Top = 0
        Width = 408
        Height = 196
        Align = alClient
        BorderStyle = bsNone
        Color = clBlack
        Columns = <
          item
            Caption = 'Name'
            Width = 100
          end
          item
            Caption = 'Address'
            Width = 150
          end
          item
            AutoSize = True
            Caption = 'Status'
          end>
        DoubleBuffered = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ReadOnly = True
        RowSelect = True
        ParentDoubleBuffered = False
        ParentFont = False
        ParentShowHint = False
        PopupMenu = PopupMenu1
        ShowColumnHeaders = False
        ShowHint = False
        TabOrder = 0
        ViewStyle = vsReport
      end
      object Panel1: TPanel
        Left = 0
        Top = 196
        Width = 408
        Height = 20
        Align = alBottom
        BevelEdges = [beTop]
        BevelKind = bkSoft
        BevelOuter = bvNone
        Color = -1
        ParentBackground = False
        TabOrder = 1
        Visible = False
        object Label4: TLabel
          Left = 150
          Top = 6
          Width = 3
          Height = 13
        end
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'Details'
      ImageIndex = 4
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object ChartTrafficPanel: TPanel
        Left = 0
        Top = 20
        Width = 408
        Height = 196
        Align = alClient
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 0
        object LabelTraffic: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 182
          Width = 3
          Height = 13
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 1
          Align = alBottom
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clYellow
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
      end
      object ChartControlPanel: TPanel
        Left = 0
        Top = 0
        Width = 408
        Height = 20
        Align = alTop
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 1
        object RadioButton1: TRadioButton
          AlignWithMargins = True
          Left = 220
          Top = 3
          Width = 68
          Height = 14
          Align = alLeft
          Caption = 'Entities'
          TabOrder = 0
          OnClick = RadioButton1Click
        end
        object RadioButton2: TRadioButton
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 63
          Height = 14
          Align = alLeft
          Caption = 'Traffic'
          Checked = True
          TabOrder = 1
          TabStop = True
          OnClick = RadioButton1Click
        end
        object RadioButton3: TRadioButton
          AlignWithMargins = True
          Left = 72
          Top = 3
          Width = 68
          Height = 14
          Align = alLeft
          Caption = 'Packets'
          TabOrder = 2
          OnClick = RadioButton1Click
        end
        object RadioButton4: TRadioButton
          AlignWithMargins = True
          Left = 146
          Top = 3
          Width = 68
          Height = 14
          Align = alLeft
          Caption = 'Frames'
          TabOrder = 3
          OnClick = RadioButton1Click
        end
      end
      object ChartFramesPanel: TPanel
        Left = 0
        Top = 20
        Width = 408
        Height = 196
        Align = alClient
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 4
        object LabelFrames: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 182
          Width = 3
          Height = 13
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 1
          Align = alBottom
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clYellow
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
      end
      object ChartEntitiesPanel: TPanel
        Left = 0
        Top = 20
        Width = 408
        Height = 196
        Align = alClient
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 2
        object LabelEntities: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 182
          Width = 3
          Height = 13
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 1
          Align = alBottom
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clYellow
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
      end
      object ChartPacketsPanel: TPanel
        Left = 0
        Top = 20
        Width = 408
        Height = 196
        Align = alClient
        BevelOuter = bvNone
        Color = clBlack
        ParentBackground = False
        TabOrder = 3
        object LabelPackets: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 182
          Width = 3
          Height = 13
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 1
          Align = alBottom
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clYellow
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Console'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object RichEdit1: TRichEdit
        Left = 0
        Top = 0
        Width = 408
        Height = 195
        Align = alClient
        BorderStyle = bsNone
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentColor = True
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        WantReturns = False
        WordWrap = False
        Zoom = 100
      end
      object Edit2: TEdit
        Left = 0
        Top = 195
        Width = 408
        Height = 21
        Align = alBottom
        ParentColor = True
        TabOrder = 1
        OnKeyDown = Edit2KeyDown
        OnKeyPress = Edit2KeyPress
      end
    end
  end
  object Frame: TTimer
    Interval = 50
    OnTimer = FrameTimer
    Left = 232
    Top = 216
  end
  object PopupMenu1: TPopupMenu
    OnPopup = PopupMenu1Popup
    Left = 172
    Top = 248
    object disconnect1: TMenuItem
      Caption = 'disconnect'
      OnClick = disconnect1Click
    end
    object kill1: TMenuItem
      Caption = 'kill'
      OnClick = kill1Click
    end
  end
end
