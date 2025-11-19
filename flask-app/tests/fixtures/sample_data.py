"""Sample data generators for testing."""
from datetime import datetime, timedelta


def generate_pc_data(count=1, start_serial='SN00000000', base_date=None):
    """Generate sample PC data.

    Args:
        count: Number of PC records to generate
        start_serial: Starting serial number
        base_date: Base date for PC names (defaults to today)

    Returns:
        List of PC data dictionaries
    """
    if base_date is None:
        base_date = datetime.now()

    pcs = []
    for i in range(count):
        # Generate serial number
        serial_num = int(start_serial[2:]) + i
        serial = f'SN{serial_num:08d}'

        # Generate PC name (increment date for variety)
        pc_date = base_date + timedelta(days=i % 30)
        pcname = pc_date.strftime('%Y%m%d') + 'M'

        # ODJ path
        odj_path = f'/srv/odj/{pcname}.txt'

        pcs.append({
            'serial': serial,
            'pcname': pcname,
            'odj_path': odj_path
        })

    return pcs


def generate_log_data(serial='TEST123', pcname='20251116M', count=1):
    """Generate sample setup log data.

    Args:
        serial: PC serial number
        pcname: PC name
        count: Number of log entries

    Returns:
        List of log data dictionaries
    """
    logs = []
    statuses = ['started', 'imaging', 'configuring', 'updating', 'completed']

    for i in range(count):
        timestamp = datetime.now() + timedelta(minutes=i*10)

        logs.append({
            'serial': serial,
            'pcname': pcname,
            'status': statuses[min(i, len(statuses)-1)],
            'timestamp': timestamp.strftime('%Y-%m-%d %H:%M:%S'),
            'logs': f'Test log entry {i+1}'
        })

    return logs


def generate_csv_content(count=10, include_header=True):
    """Generate CSV content for testing.

    Args:
        count: Number of data rows
        include_header: Include CSV header row

    Returns:
        CSV content as string
    """
    lines = []

    if include_header:
        lines.append('serial,pcname,odj_path')

    pcs = generate_pc_data(count)
    for pc in pcs:
        lines.append(f'{pc["serial"]},{pc["pcname"]},{pc["odj_path"]}')

    return '\n'.join(lines)


def generate_odj_content(pcname='20251116M', domain='example.com'):
    """Generate ODJ file content for testing.

    Args:
        pcname: PC name
        domain: Domain name

    Returns:
        ODJ XML content as string
    """
    return f"""<?xml version="1.0" encoding="utf-8"?>
<OfflineDomainJoin>
    <DomainJoin>
        <ComputerName>{pcname}</ComputerName>
        <Domain>{domain}</Domain>
        <MachinePassword>ENCRYPTED_PASSWORD_BLOB_HERE</MachinePassword>
        <Options>
            <JoinDomain>true</JoinDomain>
            <CreateAccount>false</CreateAccount>
        </Options>
    </DomainJoin>
</OfflineDomainJoin>"""


def generate_deployment_data(pc_ids, name='Test Deployment', image='win11-master-2025'):
    """Generate deployment data for testing.

    Args:
        pc_ids: List of PC IDs to include in deployment
        name: Deployment name
        image: Master image name

    Returns:
        Deployment data dictionary
    """
    return {
        'name': name,
        'pc_ids': pc_ids,
        'image_name': image,
        'auto_start': False,
        'description': f'Test deployment with {len(pc_ids)} PCs'
    }


# Predefined test datasets
SAMPLE_SERIALS = [
    'ABC123456',
    'DEF789012',
    'GHI345678',
    'JKL901234',
    'MNO567890'
]

SAMPLE_PCNAMES = [
    '20251116M',
    '20251117M',
    '20251118M',
    '20251119M',
    '20251120M'
]

SAMPLE_ERROR_MESSAGES = [
    'Network timeout during imaging',
    'Disk write error at 45%',
    'ODJ file not found',
    'Domain join failed - authentication error',
    'Windows Update service unavailable'
]
