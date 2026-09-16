# 石の素材

生成ツール：imagegen。生成元：`art/stone-source.png`。本プロジェクト用に生成した独自の石彫り素材で、Skyrimのゲーム素材を抽出したものではありません。

プロンプト：
> Use case: stylized-concept. Asset type: one square stone material texture for a fantasy falling-block puzzle game UI. Primary request: a massive Nordic carved grey stone slab, evoking Skyrim's ancient burial halls, heavy weathered basalt with pale cold highlights, restrained engraved knotwork around the outer rim, subtle aged bronze inlay, no letters, no text, no logos. Orthographic straight-on view with a perfectly square slab filling the frame, front face mostly flat and quiet with tactile cracks and chipped bevels, suitable both as a dark game panel backdrop and a small square falling block texture tinted by code. Grayscale neutral stone face with soft top-left lighting, high-quality game concept material, no environment, no extra props, no symbols resembling writing. 1024x1024 square.

生成画像を `scripts/build_assets.py` で512角のDXT5 DDSに変換します。UIは同じ画像に色を付け、背景とブロックに使用します。両方のマニフェストに `assets/stone.dds` を列挙し、package.pyで検査します。

## 雪の聖域（1.1.0）

imagegenで新規生成した背景：`art/sanctuary-source.png`。雪を載せた古代北欧風の石柱、青白い月光、霧、遠くの雪山、両端の小さな篝火。中央を暗く静かに保ち、UIが読める構図を指定しています。文字・ロゴ・人物なし。

配布用は `assets/sanctuary.dds`、DXT5・2048×1024・12段階ミップ。両マニフェストに登録済み。

## 雪片（1.5.0）

`assets/flake.dds`、DXT5・64角・7段階ミップ。生成元PNGはありません。中心から外へ 2.2 乗で落ちる不透明度の白い丸を `scripts/build_assets.py` が直接描いています。画像編集の余地がなく、生成元を置いても同じ4行の写しにしかならないためです。色味は青寄りの白（235,244,255）で、UI側が個体ごとに不透明度を変えて使います。両マニフェストに登録済み。
