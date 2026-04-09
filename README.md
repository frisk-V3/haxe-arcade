# Haxe Shooting Game

A simple browser shooting game written in Haxe and transpiled to JavaScript.

## 構成

 * `src/Main.hx`: ゲーム本体とエントリーポイント
 * `build.hxml`: Haxe ビルド設定（JS 出力）
 * `index.html`: ブラウザでゲームを起動する HTML

## ビルドと起動

1. `haxe build.hxml`
2. `xdg-open index.html` または `python3 -m http.server 8000`

ブラウザで `index.html` を開くとゲームが起動します。

## 操作方法

 * `←` / `→` / `A` / `D` : 移動
 * `Space` : シュート
