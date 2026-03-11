# dotfiles

[chezmoi](https://www.chezmoi.io/) を使って、複数の PC 間で設定ファイル（dotfiles）を同期・管理するリポジトリです。

---

## dotfiles とは？

アプリの設定ファイルのうち、名前が `.`（ドット）で始まるものを **dotfiles** と呼びます。
例えば `.gitconfig`（Git の設定）や `.claude/settings.json`（Claude Code の設定）などです。

これらをGitHub で管理しておくと、**PC を買い替えたり、複数台で作業するときに設定を一発で復元**できます。

---

## chezmoi とは？

dotfiles を管理する専用ツールです。読み方は「**シェモア**」（フランス語で「私の家」）。

普通に dotfiles を Git 管理すると、ホームディレクトリ全体がリポジトリになってしまいますが、
chezmoi は **専用の作業ディレクトリ** にコピーを保持し、`chezmoi apply` で実際の場所に展開する仕組みです。

```
~/.local/share/chezmoi/     ← chezmoi が管理するコピー（Git リポジトリ）
    dot_claude/
        settings.json       ← 「dot_」は実際には「.」に変換される
        ↓ chezmoi apply
~/.claude/
    settings.json           ← 実際に使われるファイル
```

---

## 管理しているファイル

| chezmoi 上のパス | 実際のパス | 説明 |
|-----------------|-----------|------|
| `dot_claude/settings.json` | `~/.claude/settings.json` | Claude Code の設定 |

---

## セットアップ手順

### 前提条件

- Git がインストールされていること
- GitHub アカウントがあること

### Step 1: chezmoi をインストール

**Windows**
```powershell
winget install twpayne.chezmoi
```

**macOS**
```bash
brew install chezmoi
```

**Linux**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### Step 2: このリポジトリから設定を取得・適用

```bash
chezmoi init --apply https://github.com/yukiko10140422-star/dotfiles.git
```

これだけで完了です。上の表にあるファイルがすべて正しい場所に配置されます。

---

## 日常の使い方

### 設定ファイルを変更したとき

```bash
# 1. 変更を chezmoi に取り込む（例: Claude Code の設定を変えた場合）
chezmoi add ~/.claude/settings.json

# 2. chezmoi の作業ディレクトリに移動
chezmoi cd

# 3. Git で commit & push
git add -A
git commit -m "Update claude settings"
git push
```

### 別の PC で最新の設定を取り込むとき

```bash
chezmoi update
```

これだけで GitHub から最新の変更を pull して、ファイルを更新してくれます。

### 新しいファイルを管理対象に追加するとき

```bash
# 例: .gitconfig を追加
chezmoi add ~/.gitconfig

# chezmoi の作業ディレクトリに移動して push
chezmoi cd
git add -A
git commit -m "Add gitconfig"
git push
```

---

## よく使うコマンド一覧

| コマンド | 何をする？ |
|---------|-----------|
| `chezmoi init --apply <URL>` | リポジトリから初期セットアップ（初回のみ） |
| `chezmoi add <ファイル>` | ファイルを管理対象に追加 |
| `chezmoi apply` | 管理中のファイルを実際の場所に展開 |
| `chezmoi update` | GitHub から最新を取得して適用 |
| `chezmoi cd` | 作業ディレクトリに移動 |
| `chezmoi diff` | 適用前に差分を確認 |
| `chezmoi data` | テンプレートで使える変数を確認 |
| `chezmoi managed` | 管理中のファイル一覧を表示 |

---

## ファイル名の読み替えルール

chezmoi は作業ディレクトリ内のファイル名を自動変換します。

| chezmoi での名前 | 実際の名前 | 意味 |
|-----------------|-----------|------|
| `dot_` | `.` | ドットファイルを示す |
| `private_` | *(パーミッション 0600)* | 他のユーザーから読めなくする |
| `*.tmpl` | *(拡張子なし)* | Go テンプレートとして処理される |

例: `dot_gitconfig` → `.gitconfig`

---

## OS ごとに設定を分けたいとき（テンプレート機能）

ファイル名に `.tmpl` を付けると、Go テンプレート構文が使えます。

例: `dot_gitconfig.tmpl`

```
[user]
    name = yukiko10140422-star
{{- if eq .chezmoi.os "windows" }}
    # Windows 固有の設定
    credential.helper = manager
{{- else if eq .chezmoi.os "darwin" }}
    # macOS 固有の設定
    credential.helper = osxkeychain
{{- end }}
```

`chezmoi data` を実行すると、テンプレートで使える変数（OS名など）を確認できます。

---

## リポジトリの構成

```
dotfiles/
├── README.md                    ← このファイル
└── dot_claude/
    └── settings.json            ← Claude Code の設定
```

---

## 参考リンク

- [chezmoi 公式サイト](https://www.chezmoi.io/)
- [chezmoi クイックスタート](https://www.chezmoi.io/quick-start/)
- [chezmoi で dotfiles を管理する（参考記事）](https://zenn.dev/waki285/articles/chezmoi-dotfiles)
