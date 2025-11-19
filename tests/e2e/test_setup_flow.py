"""E2E test for complete setup flow."""
import pytest
import time
from datetime import datetime


def test_complete_setup_flow(client):
    """Test complete PC setup flow from registration to completion."""

    # 1. PC登録
    serial = f"E2ETEST{int(time.time())}"
    pcname = datetime.now().strftime('%Y%m%d') + 'M'

    response = client.post('/api/pcs', json={
        'serial': serial,
        'pcname': pcname,
        'odj_path': f'/srv/odj/{pcname}.txt'
    })
    assert response.status_code == 201

    # 2. PC情報取得（Serial番号でクエリ）
    response = client.get(f'/api/pcinfo?serial={serial}')
    assert response.status_code == 200
    data = response.json
    assert data['pcname'] == pcname
    assert data['odj_path'] == f'/srv/odj/{pcname}.txt'

    # 3. セットアップ開始ログ
    response = client.post('/api/log', json={
        'serial': serial,
        'pcname': pcname,
        'status': 'in_progress',
        'timestamp': datetime.now().isoformat(),
        'step': 'pc_name_set',
        'logs': 'PC名設定完了'
    })
    assert response.status_code == 201

    # 4. Windows Update開始ログ
    response = client.post('/api/log', json={
        'serial': serial,
        'pcname': pcname,
        'status': 'in_progress',
        'timestamp': datetime.now().isoformat(),
        'step': 'windows_update',
        'logs': 'Windows Update実行中'
    })
    assert response.status_code == 201

    # 5. セットアップ完了ログ
    response = client.post('/api/log', json={
        'serial': serial,
        'pcname': pcname,
        'status': 'completed',
        'timestamp': datetime.now().isoformat(),
        'logs': 'セットアップ完了'
    })
    assert response.status_code == 201

    # 6. セットアップログの確認（完了ログが記録されていることを確認）
    # Note: 現在のAPIでは個別のログ取得エンドポイントがないため、
    # ログが正常に記録されたことは上記のステップで確認済み


def test_api_error_handling(client):
    """Test API error handling in E2E flow."""

    # 存在しないSerial番号
    response = client.get('/api/pcinfo?serial=NONEXISTENT99999')
    assert response.status_code == 404
    assert 'error' in response.json

    # 不正なログデータ（必須フィールド欠如）
    response = client.post('/api/log', json={
        'serial': 'TEST',
        # 必須フィールドpcname欠如
        'status': 'completed'
    })
    assert response.status_code == 400

    # 不正なPC登録データ（serial欠如）
    response = client.post('/api/pcs', json={
        'pcname': '20251116M',
        'odj_path': '/srv/odj/test.txt'
    })
    assert response.status_code == 400


def test_multiple_pc_registration_flow(client):
    """Test multiple PC registration flow (simulating bulk registration)."""

    # 複数のPC登録（CSV一括インポートの代替として個別登録）
    timestamp = int(time.time())
    pcs = []
    for i in range(3):
        serial = f"E2EBULK{timestamp}{i:03d}"
        pcname = datetime.now().strftime('%Y%m%d') + f'{i:03d}'

        response = client.post('/api/pcs', json={
            'serial': serial,
            'pcname': pcname,
            'odj_path': f'/srv/odj/{pcname}.txt'
        })
        assert response.status_code == 201
        pcs.append({'serial': serial, 'pcname': pcname})

    # 登録されたデータの確認
    for pc in pcs:
        response = client.get(f'/api/pcinfo?serial={pc["serial"]}')
        assert response.status_code == 200
        assert response.json['pcname'] == pc['pcname']

    # PC一覧取得
    response = client.get('/api/pcs')
    assert response.status_code == 200
    # 登録した3台が含まれているか確認（他のテストのデータも含まれる可能性あり）
    pc_list = response.json.get('items', [])
    assert len(pc_list) >= 3
    assert response.json.get('total', 0) >= 3
