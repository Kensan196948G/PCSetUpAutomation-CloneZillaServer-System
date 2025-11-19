# データベーススキーマ

## テーブル一覧

### 1. pc_master テーブル
PC情報を管理するマスターテーブル

#### カラム定義
| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | 主キー |
| serial | TEXT | UNIQUE, NOT NULL | PCシリアル番号（一意） |
| pcname | TEXT | NOT NULL | PC名（YYYYMMDDM形式） |
| odj_path | TEXT | NULLABLE | ODJファイルパス |
| created_at | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 作成日時 |

#### インデックス
- PRIMARY KEY: id
- UNIQUE INDEX: serial

#### 命名規則
- **YYYYMMDDM形式**:
  - YYYY: 導入年（4桁）
  - MM: 導入月（2桁）
  - DD: 導入日（2桁）
  - M: 固定サフィックス
  - 例: 2025年11月16日導入 → `20251116M`

#### サンプルデータ
```sql
INSERT INTO pc_master (serial, pcname, odj_path) 
VALUES ('ABC123456', '20251116M', '/srv/odj/20251116M.txt');
```

---

### 2. setup_logs テーブル
セットアップログを記録するテーブル

#### カラム定義
| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | 主キー |
| serial | TEXT | NOT NULL | PCシリアル番号 |
| pcname | TEXT | NOT NULL | PC名 |
| status | TEXT | NOT NULL | セットアップ状態 |
| timestamp | DATETIME | NOT NULL | タイムスタンプ |
| logs | TEXT | NULLABLE | ログ文字列（詳細情報） |
| step | TEXT | NULLABLE | セットアップステップ |

#### インデックス
- PRIMARY KEY: id
- INDEX: serial（検索高速化）
- INDEX: timestamp（時系列検索用）

#### status の値
- `started`: セットアップ開始
- `imaging`: イメージ展開中
- `boot`: 初回起動
- `pc_name_set`: PC名設定完了
- `odj_applied`: ドメイン参加完了
- `windows_update`: Windows Update実行中
- `app_installation`: アプリインストール中
- `completed`: セットアップ完了
- `failed`: セットアップ失敗

#### step の値
- `pxe_boot`: PXEブート
- `clonezilla`: Clonezillaイメージ展開
- `first_boot`: 初回起動
- `pc_rename`: PC名変更
- `odj`: Offline Domain Join
- `windows_update`: Windows Update
- `app_install`: アプリケーションインストール
- `finalize`: 最終処理

#### サンプルデータ
```sql
INSERT INTO setup_logs (serial, pcname, status, timestamp, logs, step) 
VALUES (
  'ABC123456', 
  '20251116M', 
  'completed', 
  '2025-11-16 12:33:22',
  'Setup completed successfully',
  'finalize'
);
```

---

## リレーションシップ

### pc_master と setup_logs
- **関連**: 1対多（1つのPCに対して複数のログ）
- **外部キー**: なし（疎結合設計）
- **結合**: serial カラムで結合可能

```sql
SELECT 
  pm.pcname,
  pm.serial,
  sl.status,
  sl.timestamp,
  sl.logs
FROM pc_master pm
LEFT JOIN setup_logs sl ON pm.serial = sl.serial
ORDER BY sl.timestamp DESC;
```

---

## マイグレーション管理

### Flask-Migrate使用
```bash
# 初期化
flask db init

# マイグレーション作成
flask db migrate -m "Initial migration"

# マイグレーション適用
flask db upgrade

# ロールバック
flask db downgrade
```

### マイグレーションファイル格納
- ディレクトリ: `/migrations/versions/`

---

## データベース設定

### 開発環境（SQLite）
```python
SQLALCHEMY_DATABASE_URI = 'sqlite:///pc_setup.db'
```

### 本番環境（PostgreSQL）
```python
SQLALCHEMY_DATABASE_URI = 'postgresql://user:password@localhost/pcsetup'
```

---

## バックアップ・復元

### SQLite
```bash
# バックアップ
cp pc_setup.db pc_setup_backup_$(date +%Y%m%d).db

# 復元
cp pc_setup_backup_20251116.db pc_setup.db
```

### PostgreSQL
```bash
# バックアップ
pg_dump pcsetup > pcsetup_backup_$(date +%Y%m%d).sql

# 復元
psql pcsetup < pcsetup_backup_20251116.sql
```

---

## パフォーマンス最適化

### インデックス戦略
1. **pc_master.serial**: UNIQUE INDEX（一意性保証と検索高速化）
2. **setup_logs.serial**: INDEX（ログ検索の高速化）
3. **setup_logs.timestamp**: INDEX（時系列検索の高速化）

### クエリ最適化
- N+1問題を避けるため、joinを使用
- 大量データの場合はページネーション実装
- 不要なカラムは SELECT しない（SELECT * 回避）

---

## データ整合性

### 制約
- **UNIQUE制約**: pc_master.serial（重複登録防止）
- **NOT NULL制約**: 必須カラムに適用
- **DEFAULT値**: created_at, timestamp（自動タイムスタンプ）

### トランザクション
- 複数テーブルへの挿入は トランザクション内で実行
- エラー時は自動ロールバック
