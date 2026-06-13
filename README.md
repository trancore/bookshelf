# Bookshelf

Android 向けのローカル PDF 本棚アプリです。端末内の PDF をインポートし、表紙サムネイル付きのライブラリで管理してリーダーで閲覧できます。  
このアプリはバイブコーディングによって作られています。

**対応プラットフォーム:** Android のみ（実機またはエミュレータ）

## 主な機能

### ライブラリ

- ローカル PDF のインポート（ファイルピッカー）
- フォルダ指定による PDF の一括読み込み（サブフォルダ内も含む）
- デフォルトフォルダからの一括追加
- 他アプリからの PDF 共有受信（`receive_sharing_intent`）
- インポート元フォルダごとの本棚表示（フォルダ単位の棚・背表紙プレビュー）
- フォルダ階層のブラウズ（サブフォルダへのドリルダウン）
- 本棚 / リスト表示の切り替え
- 表紙サムネイルと読書進捗バー
- タイトル・ファイル名での検索
- タグの付与とフィルタ
- 並び替え（名前順 A→Z / Z→A、最近開いた順、追加日の新しい順 / 古い順）
- 長押しメニュー（タイトル編集、タグ追加、最初から読む、削除）
- 複数選択と一括削除
- 重複ファイルのスキップ、フォルダ読み込み時の進捗表示

### 自動同期

デフォルト PDF フォルダを設定している場合:

- アプリ起動時にフォルダをスキャンし、新しい PDF をバックグラウンドで取り込み
- アプリがバックグラウンドから復帰したときも同様に差分同期
- 前回スキャン結果をキャッシュし、変更がない場合はスキップ
- 同期中はライブラリ画面上部にバナーを表示

### PDF リーダー

- スワイプによるページ送り（1 ページずつ全画面表示）
- タップで UI の表示 / 非表示（没入モード）
- ページナビゲーション（ページ番号・横スクロールのページ一覧）
- 最後に読んだページの保存と再開（500ms デバウンスで保存）
- めくり方向（左開き / 右開き）
- 背景色（白・グレー・ダーク・セピア）とページ余白
- リーダー内オプションシート（設定と同じ項目をその場で変更）

### 設定

- デフォルト PDF フォルダ（一括読み込み・自動同期用）
- 本棚 / リスト表示、並び順
- リーダー表示オプション（めくり方向、背景色、余白、続きから読む、ページナビ）
- テーマ（システム / ライト / ダーク）

## 前提環境

| 項目    | 内容                                           |
| ------- | ---------------------------------------------- |
| Flutter | stable チャンネル                              |
| Dart    | SDK `^3.12.0`（`pubspec.yaml` 参照）           |
| Android | SDK（compileSdk 36）、Java / Kotlin 17         |
| 端末    | エミュレータまたは USB デバッグ可能な実機      |

```bash
flutter doctor
```

## セットアップ

リポジトリのルートで次を実行します。

```bash
flutter pub get
dart run build_runner build
dart tool/patch_plugins_built_in_kotlin.dart
flutter pub run pdfrx:remove_wasm_modules
```

| コマンド | 目的 |
| --- | --- |
| `build_runner` | Drift のコード生成（`database.g.dart`） |
| `patch_plugins_built_in_kotlin.dart` | AGP 9 Built-in Kotlin 向けのプラグイン差し替え |
| `pdfrx:remove_wasm_modules` | Android ビルド用に不要な PDFium WASM（約 4MB）を除外 |

`flutter pub get` で依存を入れ直した場合は、**Kotlin パッチと WASM 除外を再度実行**してください。

起動時は `main.dart` で `pdfrxFlutterInitialize` を呼び出し、PDFium を初期化します（追加の手順は不要です）。

## 実行

```bash
flutter devices    # 接続デバイス確認
flutter run        # デバッグ実行
# flutter run -d <device_id>
```

## リリースビルド

```bash
flutter pub run pdfrx:remove_wasm_modules
flutter build apk --release
```

WASM を戻す場合（Web 対応など）:

```bash
flutter pub run pdfrx:remove_wasm_modules -- --revert
```

## 権限とストレージ

- ストレージの広範な読み取り権限は**要求しません**
- PDF の選択は Android の Storage Access Framework（`file_picker` / SAF）経由
- インポートした PDF はアプリ専用ディレクトリへコピーして管理
- SAF 経由のファイルは `saf` パッケージで読み取り、必要に応じて一時ファイルへ展開

## データの保存場所

| 種類           | パス / 保存先                         |
| -------------- | ------------------------------------- |
| PDF 本体       | アプリ `documents/books/`             |
| サムネイル     | アプリ `cache/thumbnails/`            |
| メタデータ     | アプリ `documents/bookshelf.sqlite`   |
| 同期キャッシュ | SharedPreferences（最終スキャン結果） |
| 設定           | SharedPreferences                     |

SQLite には各 PDF の `sourcePath`（元パス）と `sourceTreeRootPath`（取り込み元フォルダのルート）を保持し、ライブラリのフォルダ階層表示に利用します。

## プロジェクト構成

```
lib/
  main.dart              # pdfrx 初期化、ProviderScope
  app.dart               # MaterialApp.router、同期・共有リスナー
  core/
    providers/           # Riverpod（アプリ、ライブラリ、同期、設定）
    router/              # go_router（/ /folder /settings /reader/:bookId）
    theme/
    utils/
  data/
    db/                  # Drift (SQLite) — Books, Tags, BookTags
    models/              # 設定、並び順、同期状態、読書進捗など
    repositories/        # ライブラリ、設定、同期キャッシュ
    services/            # インポート、サムネイル、フォルダスキャン、SAF、同期
  features/
    library/             # 本棚・フォルダ閲覧・検索・タグ・選択・同期バナー
    reader/              # PDF リーダー、ページ送り、オプションシート
    settings/            # 設定画面
    import/              # 共有 Intent、インポート進捗 UI
android/
  gradle/plugin_overrides/   # Built-in Kotlin 向けプラグイン override
tool/
  patch_plugins_built_in_kotlin.dart
```

## 技術スタック

- **UI / 状態管理:** Flutter, Riverpod, go_router
- **永続化:** Drift (SQLite), SharedPreferences（設定・同期キャッシュ）
- **PDF:** pdfrx（表示・サムネイル、内部で pdfium_flutter を利用）
- **ファイル:** file_picker, saf, receive_sharing_intent, path_provider

## 今後の拡張候補

- ピンチズーム
- PDF 本文の全文検索
- 注釈・ハイライト
- クラウド同期
- iOS / デスクトップ対応
