# 実装参照

- ESO公式UIソース：https://github.com/esoui/esoui
- ゲームパッドメインメニュー：https://github.com/esoui/esoui/blob/live/esoui/ingame/mainmenu/gamepad/zo_mainmenu_gamepad.lua
- 標準入力バインド：https://github.com/esoui/esoui/blob/live/esoui/ingame/globals/bindings.xml
- API文書：https://github.com/esoui/esoui/blob/live/ESOUIDocumentation.txt
- LibGroupBroadcast：既存PBsJankenで動作確認されたRegisterHandler（名前1引数）、DeclareProtocol、CreateNumericField、OnData、Finalize、Sendの形式を採用。

メニューの既存IDは変更せず、ZO_MENU_ENTRIESへ独自IDのエントリを挿入します。対人メニューはCancel登録直前にZO_PreHookで追加します。入力は公開Bindings.xmlとZO_ActionLayerFragmentを使用し、非公開IsKeyDownは使用しません。
