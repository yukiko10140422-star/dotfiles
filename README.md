# dotfiles

[chezmoi](https://www.chezmoi.io/) を使って、複数の PC 間で設定ファイル（dotfiles）を同期・管理するリポジトリです。

---

## 目次

- [dotfiles とは？](#dotfiles-とは)
- [chezmoi とは？](#chezmoi-とは)
- [管理しているファイル](#管理しているファイル)
- [セットアップ手順](#セットアップ手順)
- [日常の使い方](#日常の使い方)
- [自動同期の仕組み](#自動同期の仕組み)
- [3 つのリポジトリの役割](#3-つのリポジトリの役割)
- [mcp-config リポジトリとの連携](#mcp-config-リポジトリとの連携)
- [claude-skills リポジトリとの連携](#claude-skills-リポジトリとの連携)
- [リポジトリの構成](#リポジトリの構成)
- [よく使うコマンド一覧](#よく使うコマンド一覧)
- [ファイル名の読み替えルール](#ファイル名の読み替えルール)
- [OS ごとに設定を分けたいとき](#os-ごとに設定を分けたいときテンプレート機能)
- [トラブルシューティング](#トラブルシューティング)
- [参考リンク](#参考リンク)

---

## dotfiles とは？

アプリの設定ファイルのうち、名前が `.`（ドット）で始まるものを **dotfiles** と呼びます。
例えば `.gitconfig`（Git の設定）や `.claude/settings.json`（Claude Code の設定）などです。

これらを GitHub で管理しておくと、**PC を買い替えたり、複数台で作業するときに設定を一発で復元**できます。

### なぜ dotfiles を管理するの？

| 課題 | dotfiles 管理で解決 |
|------|-------------------|
| PC を買い替えたら設定が全部消えた | GitHub から復元できる |
| 会社 PC と自宅 PC で設定がバラバラ | 同じ設定を共有できる |
| 「あの設定どうやったっけ？」と忘れる | Git で履歴が残る |
| 手作業で設定ファイルをコピーするのが面倒 | コマンド一発で適用できる |

---

## chezmoi とは？

dotfiles を管理する専用ツールです。読み方は「**シェモア**」（フランス語で「私の家」）。

### 普通の Git 管理との違い

普通に dotfiles を Git 管理しようとすると、ホームディレクトリ全体がリポジトリになってしまいます。
chezmoi は **専用の作業ディレクトリ** にコピーを保持し、`chezmoi apply` で実際の場所に展開する仕組みです。

```
~/.local/share/chezmoi/          ← chezmoi が管理するコピー（Git リポジトリ）
    dot_claude/
        settings.json            ← 「dot_」プレフィックスは実際には「.」に変換される
        dot_mcp.json             ← 同上
        CLAUDE.md
    dot_gitconfig
        ↓ chezmoi apply（展開）
~/.claude/
    settings.json                ← 実際にアプリが使うファイル
    .mcp.json
    CLAUDE.md
~/.gitconfig
```

### chezmoi の主な特徴

- **安全**: 展開前に差分を確認できる（`chezmoi diff`）
- **テンプレート**: OS ごとに設定を切り替えられる（`.tmpl` ファイル）
- **自動化**: ファイル追加時に自動で commit & push できる
- **簡単復元**: 新しい PC で `chezmoi init --apply` するだけ

---

## 管理しているファイル

### 設定ファイル

| chezmoi 上のパス | 実際のパス | 説明 |
|-----------------|-----------|------|
| `dot_claude/settings.json` | `~/.claude/settings.json` | Claude Code の設定（プラグイン、マーケットプレイスなど） |
| `dot_claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Claude Code のグローバルルール（言語・Git ワークフローなど） |
| `dot_claude/dot_mcp.json` | `~/.claude/.mcp.json` | MCP サーバー設定（`${VAR}` 形式のプレーン JSON） |
| `dot_gitconfig` | `~/.gitconfig` | Git のユーザー名・メール設定 |

> **ポイント**: `dot_mcp.json` は以前テンプレート（`.tmpl`）でしたが、Claude Code が `${VAR}` 形式の環境変数を直接解釈するため、プレーンファイルに変更しました。これにより `chezmoi add` で上書きしてもファイルが壊れなくなりました。

> **注意**: 自作スキル（`~/.claude/plugins/marketplaces/local/`）は chezmoi では管理していません。ファイル数が多く chezmoi に適さないため、専用の [claude-skills](https://github.com/yukiko10140422-star/claude-skills) リポジトリで管理しています（[詳細](#claude-skills-リポジトリとの連携)）。

### 設定テンプレート

| chezmoi 上のパス | 実際のパス | 説明 |
|-----------------|-----------|------|
| `.chezmoi.toml.tmpl` | `~/.config/chezmoi/chezmoi.toml` | chezmoi 自体の設定（自動 commit & push を有効化） |

`.chezmoi.toml.tmpl` の中身:
```toml
[git]
    autoCommit = true   # chezmoi add 時に自動で git commit する
    autoPush = true     # commit 後に自動で git push する
```

### 自動実行スクリプト

| スクリプト | 実行タイミング | 内容 |
|-----------|--------------|------|
| `run_onchange_windows-setup.bat.tmpl` | 管理ファイルの内容が変わった時 | 下記参照 |

`windows-setup.bat` が行うこと:

1. **依存ツールのインストール確認**
   - GitHub CLI（`gh`）
   - uv（`uvx` / serena 用）
   - Node.js（`npx` / context7, playwright 用）
2. **環境変数の自動設定**
   - `GITHUB_PERSONAL_ACCESS_TOKEN`（`gh auth token` から取得）
3. **スタートアップの自動設定**
   - `chezmoi-update.bat` → ログオン時に `chezmoi update` を実行（設定の自動取り込み）
   - `claude-config-watcher.vbs` → Claude 設定ファイル変更監視を常駐起動（[詳細](#自動同期の仕組み)）

---

## セットアップ手順

### 前提条件

- Git がインストールされていること
- GitHub アカウントがあること
- （Windows の場合）PowerShell の実行ポリシーが `RemoteSigned` 以上であること

```powershell
# 実行ポリシーの確認（Windows のみ）
Get-ExecutionPolicy -Scope CurrentUser

# RemoteSigned でなければ変更
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Step 1: chezmoi をインストール

お使いの OS に合わせてインストールしてください。

**Windows（PowerShell）**
```powershell
winget install twpayne.chezmoi
```

**macOS（ターミナル）**
```bash
brew install chezmoi
```

**Linux（ターミナル）**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### Step 2: このリポジトリから設定を取得・適用

```bash
chezmoi init --apply https://github.com/yukiko10140422-star/dotfiles.git
```

**これだけで完了です。** 以下がすべて自動で行われます:

1. 管理中のファイルが正しい場所に配置される
2. `chezmoi.toml`（自動 commit & push 設定）が配置される
3. 依存ツール（gh, uv, Node.js）がインストールされる
4. `GITHUB_PERSONAL_ACCESS_TOKEN` が自動設定される（`gh auth login` 済みの場合）
5. ログオン時の自動更新（`chezmoi update`）が設定される
6. Claude Config Watcher がスタートアップに登録される

### Step 3: GitHub 認証（まだの場合）

```bash
gh auth login
```

画面の指示に従ってブラウザで認証します。認証後、次回の `chezmoi apply` で `GITHUB_PERSONAL_ACCESS_TOKEN` が自動設定されます。

---

## 日常の使い方

### 設定ファイルを変更したとき

**方法 1: 自動（推奨）**

Claude Config Watcher が常駐しているので、`~/.claude/` 配下のファイルを編集すると **5 秒後に自動で同期** されます。何もする必要はありません。

```
ファイルを保存 → 5秒待つ → 自動で chezmoi add + mcp-config 同期
```

**方法 2: 手動**

```bash
# Claude 設定ファイルの場合
chezmoi add ~/.claude/settings.json

# その他の dotfiles の場合
chezmoi add ~/.gitconfig
```

> `autoCommit` と `autoPush` が有効なので、`chezmoi add` だけで自動的に GitHub に push されます。手動の `git commit` / `git push` は不要です。

### 別の PC で最新の設定を取り込むとき

```bash
chezmoi update
```

これだけで GitHub から最新の変更を pull して、ファイルを更新してくれます。

> Windows ではログオン時に自動で `chezmoi update` が実行されるので、通常は手動実行不要です。

### 適用前に差分を確認したいとき

```bash
# GitHub にある最新版と、今のローカルファイルの差分を表示
chezmoi diff
```

### 新しいファイルを管理対象に追加するとき

```bash
# 例: VS Code の設定を追加
chezmoi add ~/.vscode/settings.json
# → 自動で commit & push される
```

---

## 自動同期の仕組み

このリポジトリでは **3 つの自動同期メカニズム** が連携して動いています。

### 全体図

```
┌──────────────────────────────────────────────────────────────────┐
│  PC 上の ~/.claude/ ディレクトリ                                   │
│                                                                    │
│  ┌─────────────────────────────┐  ┌──────────────────────────┐  │
│  │ .mcp.json / CLAUDE.md /     │  │ plugins/marketplaces/    │  │
│  │ settings.json               │  │ local/ (自作スキル)       │  │
│  └─────────────┬───────────────┘  └─────────────┬────────────┘  │
│                │ ファイル変更                       │ ファイル変更   │
│                ▼                                   ▼               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Claude Config & Skills Watcher (FileSystemWatcher ×2)   │   │
│  │  #1: 設定ファイル → sync-mcp.sh --global                 │   │
│  │  #2: スキルディレクトリ(再帰) → sync-skills.sh            │   │
│  │  共通: 5秒デバウンス / .git/ 無視 / 実行中ロック            │   │
│  └──────────┬──────────────────────────────┬────────────────┘   │
│             │                              │                      │
│   ┌─────────┴─────────┐                   ▼                      │
│   ▼                   ▼        ┌────────────────────────┐        │
│ ┌──────────┐ ┌──────────────┐ │ marketplace.json 更新   │        │
│ │chezmoi   │ │mcp-config/   │ │ → README 再生成         │        │
│ │add       │ │global/       │ │ → git commit & push     │        │
│ │→ commit  │ │にコピー       │ └───────────┬────────────┘        │
│ │→ push    │ │→ commit/push │             ▼                      │
│ └────┬─────┘ └──────┬───────┘ ┌────────────────────────┐        │
│      ▼              ▼         │ GitHub                  │        │
│ ┌──────────┐ ┌──────────────┐ │ claude-skills リポ      │        │
│ │GitHub    │ │GitHub        │ └────────────────────────┘        │
│ │dotfiles  │ │mcp-config    │                                    │
│ └──────────┘ └──────────────┘                                    │
└──────────────────────────────────────────────────────────────────┘
```

### 1. chezmoi の自動 commit & push

`chezmoi add` を実行すると、`chezmoi.toml` の設定により自動で commit & push されます。

```toml
# ~/.config/chezmoi/chezmoi.toml
[git]
    autoCommit = true
    autoPush = true
```

### 2. Claude Config Watcher（FileSystemWatcher）

`~/.claude/` 配下の 3 ファイル（`.mcp.json`、`CLAUDE.md`、`settings.json`）を常時監視する PowerShell スクリプトです。

| 項目 | 内容 |
|------|------|
| **検知方式** | .NET の `FileSystemWatcher`（イベント駆動で CPU 負荷ほぼゼロ） |
| **デバウンス** | 変更検知後 5 秒間は追加の変更を待つ（連続編集でも 1 回だけ同期） |
| **実行内容** | `sync-mcp.sh --global` を Git Bash 経由で呼び出し |
| **起動方法** | Windows スタートアップに VBS ラッパーで登録済み（ウィンドウ非表示で常駐） |

ファイルの場所: `~/.claude/mcp-config/scripts/watch-claude-config.ps1`

#### デバウンスとは？

エディタでファイルを保存すると、OS レベルでは複数回の「変更イベント」が発生することがあります。
そのたびに同期処理を走らせると無駄なので、「最初の変更を検知してから 5 秒間は新しい変更を無視する」仕組みをデバウンスと呼びます。

```
  保存 → 変更イベント1 → 同期開始！
  0.1秒後 → 変更イベント2 → デバウンス中（無視）
  0.3秒後 → 変更イベント3 → デバウンス中（無視）
  5秒後 → デバウンス解除（次の変更を受け付ける）
```

### 3. ログオン時の chezmoi update

Windows のスタートアップフォルダに `chezmoi-update.bat` が配置されています。PC にログオンするたびに `chezmoi update` が実行され、別の PC で行った変更が自動的に取り込まれます。

### 同期の流れまとめ

| シナリオ | 何が起きるか |
|---------|------------|
| この PC で `~/.claude/` のファイルを変更した | Watcher #1 が検知 → sync-mcp.sh → 両リポジトリに push |
| スキルを追加・編集した | Watcher #2 が検知 → sync-skills.sh → marketplace.json 更新 + README 再生成 + push |
| この PC で他の dotfiles を変更した | 手動で `chezmoi add` → dotfiles リポジトリに push |
| 別の PC で設定を変更した | ログオン時に chezmoi update → 最新設定が適用される |
| `chezmoi add` を手動実行した | 自動 commit & push → dotfiles リポジトリに反映 |
| `sync-mcp.sh --global` を手動実行した | mcp-config + chezmoi の両方に同期 |
| `sync-skills.sh` を手動実行した | marketplace.json 更新 + README 再生成 + claude-skills に push |

---

## 3 つのリポジトリの役割

Claude Code の設定・スキルは、**3 つのリポジトリ**で分担管理しています。

| リポジトリ | 役割 | 同期方式 |
|-----------|------|---------|
| **[dotfiles](https://github.com/yukiko10140422-star/dotfiles)**（このリポジトリ） | 設定ファイル（settings.json, .mcp.json, CLAUDE.md, .gitconfig） | chezmoi add → autoCommit/autoPush |
| **[mcp-config](https://github.com/yukiko10140422-star/mcp-config)** | MCP 履歴・プロジェクト別設定・グローバル設定コピー | sync-mcp.sh → commit & push |
| **[claude-skills](https://github.com/yukiko10140422-star/claude-skills)** | 自作スキルの実体・marketplace.json | sync-skills.sh → commit & push |

## mcp-config リポジトリとの連携

Claude Code の設定は、このリポジトリ（dotfiles）と [mcp-config](https://github.com/yukiko10140422-star/mcp-config) リポジトリの **2 つで管理** されています。

### なぜ 2 つのリポジトリが必要なの？

それぞれ役割が異なります。

| リポジトリ | 役割 | 管理対象 |
|-----------|------|---------|
| **dotfiles**（このリポジトリ） | 新マシンセットアップの主役。chezmoi で一発復元 | `.mcp.json`、`CLAUDE.md`、`settings.json`、`.gitconfig` |
| **mcp-config** | MCP 履歴・プロジェクト別設定・README 自動生成 | グローバル設定のコピー、プロジェクト別スナップショット、MCP 履歴 |

具体的には:

- **dotfiles**: 「どの設定ファイルを、どこに配置するか」を管理。新 PC セットアップ時は `chezmoi init --apply` でこちらを使う
- **mcp-config**: 「いつ、どのプロジェクトで、どの MCP サーバーを使ったか」の履歴管理。README も自動生成される

### 以前の課題と解決

**以前**: ファイル変更のたびに `chezmoi add` と `sync-mcp.sh --global` を**手動で 2 回**実行する必要があった。忘れるとリポジトリ間でずれる。

**現在**: **Claude Config Watcher** が自動化。ファイルを保存するだけで両方のリポジトリが同期される。

```
ファイルを編集・保存するだけ
    ↓ FileSystemWatcher が検知（5秒デバウンス）
    ↓ sync-mcp.sh --global を自動実行
    ├→ mcp-config/global/ にコピー + MCP 履歴更新 + README 再生成 + push
    └→ chezmoi add → autoCommit + autoPush → dotfiles リポジトリに push
```

**ユーザーが意識すべきことは何もありません。** ファイルを保存するだけで両方のリポジトリが同期されます。

---

## claude-skills リポジトリとの連携

自作スキル（Claude Code プラグイン）は [claude-skills](https://github.com/yukiko10140422-star/claude-skills) リポジトリで管理しています。

### なぜ chezmoi で管理しないの？

- スキルはファイル数が多く、頻繁に追加・変更される
- chezmoi は少数の設定ファイル管理に最適化されており、プラグインディレクトリ全体の管理には不向き
- 専用リポジトリなら、marketplace.json や README の自動生成もスキルリポ内で完結する

### 自動同期の流れ

```
スキルファイルを編集・保存
    ↓ FileSystemWatcher #2 が検知（5秒デバウンス、.git/ は無視）
    ↓ sync-skills.sh を自動実行
    ├→ marketplace.json 自動更新（新規プラグイン追加 / 削除済み除去）
    ├→ README.md 再生成
    └→ git commit & push → claude-skills リポジトリに push
```

### 新マシンでの復元

`chezmoi init --apply` 実行時に `windows-setup.bat` が自動で `git clone` します。

```bash
# 手動で clone する場合
git clone https://github.com/yukiko10140422-star/claude-skills.git ~/.claude/plugins/marketplaces/local
```

---

## リポジトリの構成

```
dotfiles/
├── .chezmoi.toml.tmpl                        ← chezmoi 自体の設定（自動 commit & push）
├── README.md                                 ← このファイル
├── run_onchange_windows-setup.bat.tmpl       ← 依存ツール自動インストール・スタートアップ設定
├── dot_claude/                               ← ~/.claude/ に展開されるファイル群
│   ├── CLAUDE.md                             ← Claude Code グローバルルール
│   ├── dot_mcp.json                          ← MCP サーバー設定（プレーン JSON）
│   └── settings.json                         ← Claude Code の設定
└── dot_gitconfig                             ← Git の設定（~/.gitconfig に展開）
```

### 各ファイルの詳細

| ファイル | 形式 | 説明 |
|---------|------|------|
| `.chezmoi.toml.tmpl` | TOML テンプレート | `autoCommit`・`autoPush` を有効にして、`chezmoi add` だけで GitHub に反映されるようにする |
| `run_onchange_windows-setup.bat.tmpl` | BAT テンプレート | 管理ファイルの SHA256 ハッシュが変わると自動実行される。依存ツールのインストール、環境変数設定、スタートアップ登録を行う |
| `dot_claude/dot_mcp.json` | JSON | MCP サーバーの接続情報。環境変数は `${VAR}` 形式で記述し、Claude Code が実行時に展開する |
| `dot_claude/CLAUDE.md` | Markdown | Claude Code がすべてのプロジェクトで読み込むグローバルルール |
| `dot_claude/settings.json` | JSON | Claude Code のプラグイン設定、マーケットプレイス設定など |
| `dot_gitconfig` | INI | Git のユーザー名・メールアドレス等 |

---

## よく使うコマンド一覧

### 基本コマンド

| コマンド | 何をする？ | いつ使う？ |
|---------|-----------|-----------|
| `chezmoi init --apply <URL>` | リポジトリから初期セットアップ | 新しい PC で最初の 1 回だけ |
| `chezmoi add <ファイル>` | ファイルを管理対象に追加・更新 | 設定を変更したとき |
| `chezmoi apply` | 管理中のファイルを実際の場所に展開 | 通常は不要（init 時に自動実行） |
| `chezmoi update` | GitHub から最新を取得して適用 | 別 PC の変更を取り込むとき |

### 確認・デバッグ用コマンド

| コマンド | 何をする？ | いつ使う？ |
|---------|-----------|-----------|
| `chezmoi diff` | 適用前に差分を確認 | 変更内容を事前確認したいとき |
| `chezmoi managed` | 管理中のファイル一覧を表示 | 何が管理されているか確認したいとき |
| `chezmoi cd` | chezmoi の作業ディレクトリに移動 | 直接 Git 操作したいとき |
| `chezmoi data` | テンプレートで使える変数を確認 | テンプレートのデバッグ時 |
| `chezmoi doctor` | chezmoi の設定診断 | 動作がおかしいとき |

### 同期スクリプト（sync-mcp.sh）

| コマンド | 何をする？ |
|---------|-----------|
| `sync-mcp.sh --global` | `~/.claude/` → mcp-config + chezmoi に同期 |
| `sync-mcp.sh --deploy` | mcp-config → `~/.claude/` にデプロイ（新マシン用） |
| `sync-mcp.sh <path>` | プロジェクトの `.mcp.json` を mcp-config に記録 |

> 通常は Claude Config Watcher が `sync-mcp.sh --global` を自動実行するので、手動実行は不要です。

---

## ファイル名の読み替えルール

chezmoi は作業ディレクトリ内のファイル名を、実際の場所にコピーする際に自動変換します。

| chezmoi での名前 | 実際の名前 | 意味 |
|-----------------|-----------|------|
| `dot_` | `.` | ドットファイルであることを示す |
| `private_` | *(パーミッション 0600)* | 他のユーザーから読めなくする |
| `run_` | *(実行される)* | `chezmoi apply` 時にスクリプトとして実行される |
| `run_onchange_` | *(内容変更時に実行)* | ファイル内容のハッシュが変わった場合のみ実行される |
| `*.tmpl` | *(拡張子なし)* | Go テンプレートとして処理してから配置される |

### 具体例

```
dot_gitconfig           → ~/.gitconfig
dot_claude/             → ~/.claude/
  dot_mcp.json          → ~/.claude/.mcp.json
  settings.json         → ~/.claude/settings.json       ← dot_ が付かないファイルはそのまま
  CLAUDE.md             → ~/.claude/CLAUDE.md

run_onchange_windows-setup.bat.tmpl
  → 実行される（テンプレート展開後にバッチファイルとして実行）
  → 内容が前回から変わっていなければスキップされる
```

---

## OS ごとに設定を分けたいとき（テンプレート機能）

ファイル名に `.tmpl` を付けると、Go テンプレート構文が使えます。

### 例: `.gitconfig` を OS ごとに切り替え

ファイル名: `dot_gitconfig.tmpl`

```
[user]
    name = yukiko10140422-star
{{- if eq .chezmoi.os "windows" }}
    credential.helper = manager
{{- else if eq .chezmoi.os "darwin" }}
    credential.helper = osxkeychain
{{- end }}
```

### テンプレートで使える変数の確認

```bash
chezmoi data
```

主な変数:
- `.chezmoi.os` → `"windows"`, `"darwin"`, `"linux"`
- `.chezmoi.hostname` → PC のホスト名
- `.chezmoi.username` → ログインユーザー名

> **注意**: `.mcp.json` は以前テンプレート（`dot_mcp.json.tmpl`）でしたが、chezmoi の `{{ env "VAR" }}` 形式と Claude Code の `${VAR}` 形式が競合するため、プレーンファイルに変更しました。Claude Code が `${VAR}` を実行時に解釈するので、chezmoi 側でのテンプレート展開は不要です。

---

## トラブルシューティング

### Q: `chezmoi add` してもリモートに反映されない

**原因**: `chezmoi.toml` が正しく配置されていない可能性があります。

```bash
# chezmoi.toml の内容を確認
cat ~/.config/chezmoi/chezmoi.toml

# 以下が表示されれば OK
# [git]
#     autoCommit = true
#     autoPush = true
```

表示されない場合:
```bash
chezmoi apply  # テンプレートから chezmoi.toml を再生成
```

### Q: Claude Config Watcher が動いていない

**確認方法**（PowerShell）:
```powershell
# PowerShell プロセスの一覧を確認
Get-Process powershell | Select-Object Id, StartTime
```

**手動起動**:
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\mcp-config\scripts\watch-claude-config.ps1"
```

**スタートアップに再登録**:
```bash
# chezmoi apply を実行すれば windows-setup.bat が走り、スタートアップに再登録される
chezmoi apply
```

### Q: 別の PC で設定が古いまま

```bash
# 手動で最新を取り込む
chezmoi update
```

Windows ではログオン時に自動実行されますが、スリープ復帰では実行されません。
長時間スリープしていた場合は手動で `chezmoi update` してください。

### Q: `chezmoi apply` で競合が起きた

```bash
# まず差分を確認
chezmoi diff

# ローカルの変更を優先して chezmoi に反映する場合
chezmoi add ~/.claude/settings.json

# リポジトリの内容を優先してローカルに展開する場合
chezmoi apply --force
```

### Q: スキルを追加したのに marketplace.json に反映されない

**確認方法**:
```bash
# 手動で sync-skills.sh を実行
~/.claude/plugins/marketplaces/local/scripts/sync-skills.sh
```

スキルディレクトリの構造を確認してください。プラグインディレクトリ直下にサブディレクトリがあり、`.claude-plugin/plugin.json` が存在する必要があります。

### Q: スキルウォッチャーが動いていない

Claude Config Watcher がスキルディレクトリも監視しています。Watcher 自体の動作確認は「Claude Config Watcher が動いていない」を参照してください。

スキルディレクトリ（`~/.claude/plugins/marketplaces/local/`）が存在しない場合、スキルウォッチャーは起動しません。先に `git clone` してから Watcher を再起動してください。

### Q: sync-mcp.sh でエラーが出る

```bash
# Git Bash が必要（Windows の場合）
# Git for Windows をインストールしてください
winget install Git.Git

# 手動実行でエラーメッセージを確認
~/.claude/mcp-config/scripts/sync-mcp.sh --global
```

---

## 参考リンク

- [chezmoi 公式サイト](https://www.chezmoi.io/)
- [chezmoi クイックスタート](https://www.chezmoi.io/quick-start/)
- [chezmoi で dotfiles を管理する（参考記事）](https://zenn.dev/waki285/articles/chezmoi-dotfiles)
- [mcp-config リポジトリ](https://github.com/yukiko10140422-star/mcp-config) — MCP サーバー設定の履歴管理
- [claude-skills リポジトリ](https://github.com/yukiko10140422-star/claude-skills) — 自作スキル・プラグイン管理
