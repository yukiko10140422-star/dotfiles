# Global Rules

## 言語
- ユーザーとのやりとりは常に日本語で行う
- コミットメッセージも日本語で書く

## セッション管理
- セッション開始時: プロジェクトの CLAUDE.md を読み、ルール・進捗・前回の状態を確認する
- セッション終了時: CLAUDE.md や進捗ドキュメントに指示があれば更新してから終了する

## Git ワークフロー
- commit 前にビルド確認（`npx next build` 等）を行い、エラーがないことを確認する
- commit 後は push まで自動で行う（毎回確認不要）
- バージョン変更を伴う commit 時は `gh release create` で GitHub Release を作成する

## 安全ルール
- .env ファイルは絶対にコミットしない
- ファイル削除や破壊的操作は事前に確認を取る

## MCP サーバー（グローバル設定）

以下の MCP サーバーがグローバル（`~/.claude/.mcp.json`）に設定済み。
環境変数が未設定のサーバーは接続時にエラーになるため、初回利用時にオーナーへ確認すること。

### 設定不要（そのまま使える）
| サーバー | 用途 | 必要なツール |
|---------|------|-------------|
| serena | コード解析・ナビゲーション | uvx (uv) |
| context7 | ライブラリドキュメント検索 | npx (Node.js) |
| playwright | ブラウザ自動操作・テスト | npx (Node.js) |
| github | GitHub操作（ビルトインMCP） | gh CLI（`gh auth login` 済みならPATはセットアップスクリプトが自動設定） |

### 初回認証が必要
| サーバー | 認証方法 |
|---------|---------|
| supabase | Claude Code で初回使用時にブラウザ認証 |

### 要環境変数（初回接続時にオーナーへ値を確認する）
| サーバー | 必要な環境変数 |
|---------|--------------|
| vercel | `VERCEL_ACCESS_TOKEN` |
| ebay-public-api | `EBAY_CLIENT_ID`, `EBAY_CLIENT_SECRET` |
| ebay-mcp | `EBAY_CLIENT_ID`, `EBAY_CLIENT_SECRET`, `EBAY_DEV_ID`, `EBAY_REDIRECT_URI` |

### 環境セットアップ
`chezmoi init --apply yukiko10140422-star` を実行すると、依存ツール（gh, uv, Node.js）が自動インストールされる。
手動で必要な作業は GitHub 認証（`gh auth login`）と環境変数の設定のみ。
