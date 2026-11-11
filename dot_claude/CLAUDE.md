# Global Rules

このファイルは薄い index。具体ルールはモジュール側を編集する。

## モジュール

@global/core.md
@global/integrations.md
@global/harness.md

## 自動で読み込まれるもの (ここに @ を書かなくてよい)

`~/.claude/rules/` の中の `.md` は **frontmatter に `paths:` が無いものが毎回すべて自動で読み込まれる**。
- `rules/common/*.md` — 共通ワークフロー (ECC 由来、上書きしない)
- `rules/ebay/ebay-core.md` — eBay 事業の大原則 + 正典の節の索引
- `rules/<lang>/*.md` と `rules/web/*.md` — `paths:` 付き。該当ファイルを触った時だけ読まれる

## 字数の上限 (2026-11-11)

毎回読み込む指示ファイルは **合計 15 万字まで** (超えた分は読まれない)。
測定: `node ~/.claude/scripts/instruction-load-size.mjs --list`
- 長い参照資料は `rules/` に置かない → `~/.claude/docs/` に置いて、要約から節を指す
- `rules/` に足すなら `paths:` で絞れないか先に考える

## 編集ガイド

- 言語・Git・安全 → `global/core.md`
- Obsidian / MCP / Ollama / 1Password → `global/integrations.md`
- ECC ハーネス・verification・cost tracking → `global/harness.md`
- 共通ワークフロー (テスト・レビュー等) → `rules/common/*.md` (ECC 由来、上書きしない)
- **eBay 出品フロー・在庫管理・ストーカー (正典) → `docs/ebay/listing-flow-2026-08.md` (§0〜§2) + `docs/ebay/listing-flow-2026-08-part2.md` (§3〜§7)**
  (agent/skill の個別記述と食い違ったら**こちらが正**。仕組みを変えたら本文を先に直し、節を足したら `rules/ebay/ebay-core.md` の索引にも足す)
- 言語別ルール → `rules/<lang>/*.md` (`paths:` 付き)
- ルール一式の導入手順 (ECC の README) → `docs/rules-meta/README.md`
