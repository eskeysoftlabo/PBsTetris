# PBsTetris

PS5向けESOアドオン。UIは日本語。DDS画像は必ず `.addon` と `.txt` の両マニフェストへ記載する。ファイルをZIPへ入れるだけでは不十分。これはPBsJankenのPS5実機で確認済みの不具合から得たルール。

配布前に scripts/package.py --check と tests/run.lua を実行する。ゲームパッドの入力レイヤーを画面外に残さない。対戦中のポーズや画面閉じで有利にならないよう扱う。コンソール実機未検証の点を明示する。LibGroupBroadcastのプロトコルIDは公開前に予約する。
