object AboutBox: TAboutBox
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'AboutBox'
  ClientHeight = 187
  ClientWidth = 249
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clYellow
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = [fsBold]
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    249
    187)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 3
    Height = 13
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 8
    Top = 168
    Width = 75
    Height = 11
    Cursor = crHandPoint
    Anchors = [akLeft, akBottom]
    Caption = 'Official Thread'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -9
    Font.Name = 'Tahoma'
    Font.Style = [fsBold, fsUnderline]
    ParentFont = False
    OnClick = Label2Click
    OnMouseEnter = Label2MouseEnter
    OnMouseLeave = Label2MouseLeave
  end
end
