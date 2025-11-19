# DRBL/Clonezillaサーバー構成管理 Ansible導入計画書

## 1. 目的

現在 `drbl-server/install.sh` スクリプトによって行われているDRBL/Clonezillaサーバーのセットアッププロセスを、構成管理ツール **Ansible** を用いた宣言的な管理方法に移行します。

この計画のゴールは、サーバー構築プロセスの **自動化**、**再現性の確保**、そして将来的な **メンテナンス性の向上** です。

## 2. Ansible導入のメリット

| メリット | 説明 |
| :--- | :--- |
| **冪等性（べきとうせい）の保証** | Playbook（Ansibleの実行ファイル）を何度実行しても、サーバーは常に定義された「あるべき状態」に収束します。これにより、予期せぬ変更を防ぎ、安定した環境を維持できます。 |
| **可読性とドキュメント化** | シェルスクリプトの一連のコマンド（**How**）ではなく、YAML形式で最終的な状態（**What**）を記述するため、インフラの構成がコードとして理解しやすくなります。 |
| **再利用性と拡張性** | 「ロール」という仕組みを使い、DRBLサーバーの構築手順を再利用可能な部品として管理できます。これにより、構成の追加や変更が容易になります。 |
| **エージェントレス** | 管理対象サーバーに特別なエージェントソフトをインストールする必要がなく、SSH接続さえできればすぐに利用を開始できるため、導入が容易です。 |

## 3. ディレクトリ構成案

プロジェクトルートに `ansible` ディレクトリを新設し、以下の標準的な構成で管理します。

```plaintext
ansible/
├── inventory/
│   └── hosts.ini           # 管理対象サーバー(DRBLサーバー)のIPアドレス等を定義
│
├── roles/
│   └── drbl_server/        # DRBLサーバーを構築するための再利用可能な部品(ロール)
│       ├── tasks/          # 具体的な処理を記述するタスクファイル
│       │   ├── main.yml          # このロールの実行起点となるファイル
│       │   ├── 01_prepare.yml    # パッケージマネージャの更新やリポジトリ追加
│       │   ├── 02_install.yml    # 必要なパッケージのインストール
│       │   └── 03_configure.yml  # ディレクトリ作成や権限設定
│       └── handlers/
│           └── main.yml          # (今回は不要) サービス再起動などの処理を定義
│
└── drbl_playbook.yml         # DRBLサーバーをセットアップするためのメイン実行ファイル
```

## 4. `install.sh` からAnsibleタスクへの移行計画

`install.sh` で実行されている各コマンドは、Ansibleの標準モジュールを使って以下のようにタスク化できます。

| `install.sh` の処理 | Ansibleモジュール | `drbl_server` ロールのタスクファイル |
| :--- | :--- | :--- |
| `apt-get update` | `ansible.builtin.apt` | `01_prepare.yml` |
| DRBLリポジトリのGPGキー追加 | `ansible.builtin.apt_key` | `01_prepare.yml` |
| DRBLリポジトリの追加 | `ansible.builtin.apt_repository` | `01_prepare.yml` |
| `apt-get install drbl ...` | `ansible.builtin.apt` | `02_install.yml` |
| `mkdir -p /home/partimag` | `ansible.builtin.file` | `03_configure.yml` |
| `chmod 755 /home/partimag` | `ansible.builtin.file` (mode) | `03_configure.yml` |

## 5. Playbookサンプル (`drbl_playbook.yml`)

実際にDRBLサーバーを構築する際は、以下のPlaybookを実行します。

```yaml
---
- name: Provision DRBL/Clonezilla Server
  hosts: drbl_servers  # inventory/hosts.ini で定義したホストグループ名
  become: yes          # root権限(sudo)で実行することを宣言

  roles:
    # drbl_serverロールを適用する
    - role: drbl_server
```

## 6. 今後のステップ

この計画に合意が得られた後、別途ご依頼いただければ、以下の手順で実装を進めることが可能です。

1.  `ansible` ディレクトリと上記構成を作成する。
2.  `drbl_server` ロールに、`install.sh` の内容を移植したタスク群を実装する。
3.  `inventory` と `drbl_playbook.yml` を作成する。
4.  テスト環境でPlaybookを実行し、サーバーが正しく構築されることを検証する。
