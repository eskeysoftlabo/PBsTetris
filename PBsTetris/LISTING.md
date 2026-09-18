# Store listing copy

Text for the Bethesda.net / ZOS Console AddOn Uploader entry. Plain text, no markdown —
paste as-is. The **name** field is what the in-game add-on browser shows, so it must read
`PB's Tamriel de Tetris` there; `## Title` in the manifest does not reach that screen.

The Japanese font note is in both Overview and Description on purpose: it decides whether the
add-on is readable at all, and it belongs where somebody sees it before installing.

Group duels were withdrawn in 1.14.0 and are not described here. The listing says so once,
under the known limitations, for anyone who remembers them from an earlier version.

---

## Name

PB's Tamriel de Tetris

## Overview (JP)

石を積む落ちものパズルです。ゲームパッドのメインメニューから開いて、ひとりで遊べます。レベル
20からは20G。積み上がるほど雪が強くなり、ラインは払われるように消え、4ライン消しは金色に光り
ます。遊んでいるあいだのBGMは5種類から選べます。戦闘に入ると自動で閉じます。画面表示は日本語
なので、日本語フォントが必要です。

## Overview (EN)

A falling-block puzzle built out of stone. Open it from the gamepad main menu and play. Level
20 and up is 20G. The snow thickens as your stack climbs, cleared lines are swept away, and a
four-line clear burns gold. You can pick which of five in-game tracks plays while you are on
the board, and the whole thing closes itself the moment you enter combat. The interface is
Japanese and needs a Japanese font.

---

## Description (JP)

10列20行の盤面、ホールド、次の3ブロック、着地点表示。7種類が一巡するランダム方式とSRSの
回転補正、接地から0.5秒の猶予です。石の絵と雪の聖域の背景はこのアドオンのために描き起こ
しました。

■ 開き方

　　通常　　　メインメニューの「ヘルプ」と「オプション」のあいだ
　　　　　　　→「ゲームセンターPX」→「タムリエル de テトリス」
　　20G　　　 同じメニューの「タムリエル de テトリス（20G）」
　　コマンド　/pbt　（/pbt 20g で20G）

　開くと画面がいったん暗転してから盤面が現れます。暗転のあいだにブロックは落ちません。

■ 操作

　　方向キー 左右　　横移動（長押しで連続）
　　方向キー 下　　　ソフトドロップ　　1マス1点
　　方向キー 上　　　ハードドロップ　　1マス2点
　　決定　　　　　　 右回転
　　L1　　　　　　　 左回転
　　R1　　　　　　　 BGMの切り替え
　　戻る　　　　　　 一時停止。もう一度で閉じる

　ハードドロップとホールドは画面下のボタン表示からも使えます。ホールドは固定までに1回です。

　得点は1／2／3／4ライン同時消去で100／300／500／800×レベル。連続消去と4ライン消去の継続に
　ボーナスがあります。10ライン消すごとにレベルが上がり、落下は0.85秒から段階的に速くなります。

■ 20G

　レベル20（190ライン）で20Gに変わります。出現時・ホールド交換時・横移動と回転の成功直後に、
　その場から接地位置まで落ちます。接地して0.5秒で固定、移動や回転による猶予の延長は1ブロック
　につき15回までです。ハードドロップはその場で即固定します。

　TGMの20Gの挙動を参考にした実装で、回転はこのアドオンのSRSのままです。ARS・IRS・段位・
　レベル曲線の再現ではありません。

■ 演出

　・ラインは左から右へ払われるように消えます。4ライン同時消去は金色で、少し長く残ります。
　・レベルが上がると盤面に「レベル 5」と出て、ESOのレベルアップ音が鳴ります。20Gに入ると
　　そう併記します。
　・盤面が高くなるほど雪が強くなります。空の盤面ではちらつく程度、天井が近いと吹雪です。
　・ブロックの上を、ときどき斜めに光が走ります。

■ BGM

　R1または /pbt music で、遊んでいるあいだのBGMを次の5つから順に選べます。

　　BGM：切　　　　差し替えません（そのゾーンの曲のまま）
　　BGM：カード　　Tales of Tribute の曲
　　BGM：星座　　　チャンピオンポイント画面の曲
　　BGM：決闘　　　決闘の曲
　　BGM：終幕　　　クレジットの曲

　選んだ曲はアカウント共通で覚えます。一時停止や画面を閉じたときは、遊び始める前の状態へ
　戻します。他のアドオンやゲーム側が先に曲を差し替えていた場合は、それを奪いません。ESO本体
　の音量設定には触れません。効果音はESO内蔵のものを移動・回転・ホールド・固定・ライン消去・
　レベルアップ・開始・終了に当ててあります。/pbt sound で切れます。

■ 邪魔をしません

　戦闘に入ると自動で閉じます。コントローラーが外れたときも閉じます。チャット欄には何も書き
　ません。通信も一切しません。

■ 記録

　自己ベストの得点と最大消去ライン数をアカウント共通で保存します。通常の挑戦と、最初から
　20Gで始めたときの記録は別々です。盤面そのものはログアウトすると残りません。同じセッション
　のあいだなら、閉じた盤面は続きから再開します。

■ 日本語フォントについて

　画面の文字はすべて日本語です。日本語フォントを導入していないクライアントでは読めません。

■ 既知の制限

　Tスピンとパーフェクトクリアの専用ボーナスはありません。以前の版にあったグループ対戦は、
　他のアドオンとの通信IDの重複が分かったため休止しています。

必須ライブラリはありません。

## Description (EN)

A ten by twenty board, a hold slot, the next three pieces and a landing shadow. Seven-bag
randomiser, SRS kicks, half a second of lock delay. The stone and the snowed-in sanctuary
behind it were drawn for this add-on.

■ Opening it

　　Standard　 main menu, between Help and Options
　　　　　　　 -> Game Centre PX -> Tamriel de Tetris
　　20G　　　　the 20G entry in the same menu
　　Command　　/pbt　(/pbt 20g for 20G)

　The screen fades to black before the board appears. Nothing falls while it is dark.

■ Controls

　　D-pad left/right　　move (hold to repeat)
　　D-pad down　　　　　soft drop　　1 point a row
　　D-pad up　　　　　　hard drop　　2 points a row
　　Accept　　　　　　　rotate right
　　L1　　　　　　　　　rotate left
　　R1　　　　　　　　　change the music
　　Back　　　　　　　　pause, again to close

　Hard drop and hold are also on the button prompts along the bottom. Hold works once per
　piece until it locks.

　One, two, three or four lines score 100 / 300 / 500 / 800 times your level, with a bonus for
　clearing on consecutive pieces and for four-line clears back to back. Every ten lines raises
　the level and shortens the fall from its starting 0.85 seconds.

■ 20G

　At level 20 -- 190 lines -- the game changes to 20G. Pieces drop to the floor on spawn, on a
　hold swap, and immediately after any move or rotation that lands. They lock half a second
　after touching down, and a move or rotation buys more time only fifteen times per piece. A
　hard drop locks where it is.

　It follows TGM's 20G behaviour, but the rotation is still this add-on's SRS. It is not a
　reproduction of ARS, IRS, the grade system or TGM's level curve.

■ Effects

　- Cleared lines are swept away from left to right. A four-line clear burns gold and lingers
　  a moment longer.
　- A level up puts "レベル 5" on the board with the game's own level-up sound, and says 20G
　  alongside it when that is where you have arrived.
　- The snow thickens as your stack climbs: a few flakes over an empty board, a blizzard
　  near the ceiling.
　- Every so often a glint runs diagonally across the blocks.

■ Music

　R1, or /pbt music, cycles what plays while you are on the board:

　　off　　　　　　nothing is replaced; the zone keeps its own music
　　Tribute　　　　the Tales of Tribute music
　　Champion　　　 the Champion Points screen
　　Duel　　　　　 the duelling music
　　Credits　　　　the credits

　The choice is remembered account-wide. Pausing or closing the board puts the music back the
　way it was before you started, and if another add-on or the game had already taken the
　music over, this one leaves it alone rather than fighting for it. Your ESO volume settings
　are never touched. The sound effects are the game's own, on movement, rotation, hold, lock,
　line clears, level ups, the start and the end. /pbt sound turns them off.

■ It gets out of the way

　Entering combat closes the board. So does losing the controller. Nothing is ever written to
　your chat window, and nothing is sent over the network.

■ Records

　Your best score and your longest line count are saved account-wide, kept separately for
　standard games and for games started in 20G. The board itself does not survive a logout,
　though a game you closed resumes where you left it for the rest of the session.

■ About the Japanese font

　Everything on screen is Japanese, and a client without a Japanese font cannot render it.

■ Known limitations

　There are no dedicated T-spin or perfect-clear bonuses. The group duels of earlier versions
　are withdrawn for now: the id they talked on turned out to be shared with other add-ons.

No required libraries.
