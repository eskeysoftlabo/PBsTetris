# 石と雪 — コロブチカ独自アレンジ

ロシア民謡Korobeiniki（コロブチカ）の旋律を用いた、本プロジェクト独自の合成音アレンジです。1.2.0では刻む弦、太鼓、スネア、厚い金管風の旋律を加え、速度と音の厚みを高めました。旧82 BPM版は比較用に保持しています。既存のゲーム音源・演奏録音・サンプル音源は使用していません。音声合成・和声・低音・打楽器・残響の実装は `scripts/build_music.py` にあります。

- 新音源 `stone-and-snow-epic.mp3` / `.wav`：約62.4秒、148 BPM、ニ短調、ステレオ。
- 原音：32kHz / 16bit WAV。試聴用：MP3。
- ブラウザで再生可能。ESOアドオンZIPには含めていません（任意ファイル再生APIがないため）。

旋律の参照：[Korobeinikiの伝承旋律の譜例](https://commons.wikimedia.org/wiki/File:Korobeiniki.svg)。特定の市販ゲームの編曲・録音を複製したものではありません。

APIの確認：[公式API文書](https://github.com/esoui/esoui/blob/live/ESOUIDocumentation.txt)、[公式内蔵効果音一覧](https://github.com/esoui/esoui/blob/live/esoui/libraries/globals/soundids.lua)。公開APIのPlaySoundは内蔵音の名前を受け取ります。任意音源の読み込みAPIや音程変更APIは確認できませんでした。
