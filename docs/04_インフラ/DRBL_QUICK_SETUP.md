# 🚀 DRBL クイックセットアップ（Docker回避版）

**作成日**: 2025年11月17日
**所要時間**: 15分

---

## 📊 現在の状況

- ❌ drblpush: 未完了（docker0問題で中断）
- ✅ DHCP設定: 完了
- ✅ ネットワーク: enp2s0 (192.168.3.135)

---

## ✅ 解決策：Dockerを一時停止してdrblpush実行

### ステップ1: Docker一時停止とdrblpush準備（1分）

```bash
sudo ./SETUP_DRBL_CORRECT.sh
```

**パスワード**: ELzion1969

**実行内容**:
1. Dockerサービス停止
2. docker0インターフェース削除
3. ネットワークインターフェース確認
4. drblpush実行案内表示

---

### ステップ2: drblpush実行（10分）

```bash
sudo /usr/sbin/drblpush -i
```

**パスワード**: ELzion1969

**対話式設定ガイド**:

| 質問 | 回答 | 説明 |
|------|------|------|
| Dockerを利用していますか？ | `n` | Dockerは停止済み |
| WANポートは？ | **Enterのみ** | 空白でスキップ |
| → enp2s0がDRBL用に選択される | `y` | 正しい設定を承認 |
| MACアドレス収集 | `N` | スキップ |
| DRBLモード | Enter | Full DRBL mode |
| クライアント数 | `20` | 最大20台 |
| その他すべて | **Enter** | デフォルト値 |

---

### ステップ3: Docker再起動（1分）

drblpush完了後：

```bash
sudo systemctl start docker
```

---

### ステップ4: 動作確認（1分）

```bash
./CHECK_PXE_READINESS.sh
```

**期待される結果**:
```
✅ DHCP サーバ起動中
✅ TFTP サーバ起動中
✅ pxelinux.0 存在
✅ ファイアウォール設定OK
```

---

## 🎯 実行コマンド（順番通り）

```bash
# 1. Docker停止とdrblpush準備
sudo ./SETUP_DRBL_CORRECT.sh

# 2. drblpush実行（対話式）
sudo /usr/sbin/drblpush -i
# → すべてEnterキー連打でOK

# 3. Docker再起動
sudo systemctl start docker

# 4. 動作確認
./CHECK_PXE_READINESS.sh
```

---

**まず `sudo ./SETUP_DRBL_CORRECT.sh` を実行してください！**
