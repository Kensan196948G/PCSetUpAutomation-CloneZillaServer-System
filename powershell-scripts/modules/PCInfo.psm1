# PCInfo.psm1
# システム情報取得モジュール
# UTF-8 BOM付きで保存

<#
.SYNOPSIS
    PCのハードウェア情報を取得するモジュールです。

.DESCRIPTION
    Serial番号、MACアドレス、システム情報（OS, RAM, CPU等）を取得します。
#>

# Logger モジュールのインポート
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path -Path $ModulePath -ChildPath "Logger.psm1") -Force

<#
.SYNOPSIS
    BIOS Serial番号を取得します。

.DESCRIPTION
    WMI（Win32_BIOS）からシリアル番号を取得します。
    取得できない場合は空文字列を返します。

.EXAMPLE
    $serial = Get-SerialNumber
    if ($serial) {
        Write-Host "Serial: $serial"
    }

.OUTPUTS
    String - シリアル番号
#>
function Get-SerialNumber {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "Serial番号を取得しています..." -Level INFO

        # CIM経由でBIOS情報を取得（PowerShell 3.0以降推奨）
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop

        if ($bios -and $bios.SerialNumber) {
            $serial = $bios.SerialNumber.Trim()

            # 有効なSerial番号かチェック
            if ($serial -and $serial -ne "" -and $serial -ne "To Be Filled By O.E.M.") {
                Write-SetupLog "Serial番号を取得しました: $serial" -Level INFO
                return $serial
            }
        }

        # CIMで取得できない場合はWMIで再試行
        Write-SetupLog "CIMで取得できませんでした。WMIで再試行します..." -Level WARNING
        $bios = Get-WmiObject -Class Win32_BIOS -ErrorAction Stop

        if ($bios -and $bios.SerialNumber) {
            $serial = $bios.SerialNumber.Trim()

            if ($serial -and $serial -ne "" -and $serial -ne "To Be Filled By O.E.M.") {
                Write-SetupLog "Serial番号を取得しました（WMI経由）: $serial" -Level INFO
                return $serial
            }
        }

        Write-SetupLog "有効なSerial番号が取得できませんでした" -Level ERROR
        return ""
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-SerialNumber"
        return ""
    }
}

<#
.SYNOPSIS
    MACアドレスを取得します。

.DESCRIPTION
    物理ネットワークアダプタのMACアドレスを取得します。
    複数のアダプタがある場合は最初の有効なアダプタのMACアドレスを返します。

.EXAMPLE
    $mac = Get-MACAddress

.OUTPUTS
    String - MACアドレス（ハイフン区切り、例: 00-11-22-33-44-55）
#>
function Get-MACAddress {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "MACアドレスを取得しています..." -Level INFO

        # 物理ネットワークアダプタのみ取得
        $adapters = Get-CimInstance -ClassName Win32_NetworkAdapter -ErrorAction Stop |
            Where-Object {
                $_.PhysicalAdapter -eq $true -and
                $_.MACAddress -ne $null -and
                $_.NetEnabled -eq $true
            }

        if ($adapters) {
            # 最初の有効なアダプタのMACアドレス
            if ($adapters -is [Array]) {
                $macAddress = $adapters[0].MACAddress
            }
            else {
                $macAddress = $adapters.MACAddress
            }

            Write-SetupLog "MACアドレスを取得しました: $macAddress" -Level INFO
            return $macAddress
        }

        Write-SetupLog "有効なMACアドレスが取得できませんでした" -Level WARNING
        return ""
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-MACAddress"
        return ""
    }
}

<#
.SYNOPSIS
    システム情報を取得します。

.DESCRIPTION
    OS、メモリ、CPU、コンピュータ名、ドメイン参加状態などの情報を取得します。

.EXAMPLE
    $sysInfo = Get-SystemInfo
    Write-Host "OS: $($sysInfo.OSName)"
    Write-Host "Memory: $($sysInfo.TotalMemoryGB) GB"

.OUTPUTS
    PSCustomObject - システム情報オブジェクト
#>
function Get-SystemInfo {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "システム情報を取得しています..." -Level INFO

        # OS情報
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop

        # コンピュータシステム情報
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop

        # プロセッサ情報
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1

        # システム情報オブジェクトの作成
        $systemInfo = [PSCustomObject]@{
            ComputerName     = $cs.Name
            Domain           = $cs.Domain
            DomainJoined     = ($cs.PartOfDomain -eq $true)
            Manufacturer     = $cs.Manufacturer
            Model            = $cs.Model
            OSName           = $os.Caption
            OSVersion        = $os.Version
            OSBuild          = $os.BuildNumber
            OSArchitecture   = $os.OSArchitecture
            TotalMemoryGB    = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            CPUName          = $cpu.Name
            CPUCores         = $cpu.NumberOfCores
            CPULogicalProcs  = $cpu.NumberOfLogicalProcessors
            LastBootTime     = $os.LastBootUpTime
            InstallDate      = $os.InstallDate
        }

        Write-SetupLog "システム情報を取得しました: $($systemInfo.ComputerName)" -Level INFO
        return $systemInfo
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-SystemInfo"
        return $null
    }
}

<#
.SYNOPSIS
    システム情報をログに出力します。

.DESCRIPTION
    Get-SystemInfoで取得した情報を読みやすい形式でログに出力します。

.EXAMPLE
    Write-SystemInfoLog
#>
function Write-SystemInfoLog {
    [CmdletBinding()]
    param()

    try {
        $sysInfo = Get-SystemInfo

        if ($sysInfo) {
            Write-SetupLog "==================== システム情報 ====================" -Level INFO
            Write-SetupLog "コンピュータ名: $($sysInfo.ComputerName)" -Level INFO
            Write-SetupLog "ドメイン: $($sysInfo.Domain)" -Level INFO
            Write-SetupLog "ドメイン参加: $($sysInfo.DomainJoined)" -Level INFO
            Write-SetupLog "製造元: $($sysInfo.Manufacturer)" -Level INFO
            Write-SetupLog "モデル: $($sysInfo.Model)" -Level INFO
            Write-SetupLog "OS: $($sysInfo.OSName)" -Level INFO
            Write-SetupLog "OSバージョン: $($sysInfo.OSVersion) (Build $($sysInfo.OSBuild))" -Level INFO
            Write-SetupLog "OSアーキテクチャ: $($sysInfo.OSArchitecture)" -Level INFO
            Write-SetupLog "メモリ: $($sysInfo.TotalMemoryGB) GB" -Level INFO
            Write-SetupLog "CPU: $($sysInfo.CPUName)" -Level INFO
            Write-SetupLog "CPUコア数: $($sysInfo.CPUCores) (論理プロセッサ: $($sysInfo.CPULogicalProcs))" -Level INFO
            Write-SetupLog "最終起動時刻: $($sysInfo.LastBootTime)" -Level INFO
            Write-SetupLog "=====================================================" -Level INFO
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Write-SystemInfoLog"
    }
}

<#
.SYNOPSIS
    PC情報をまとめて取得します。

.DESCRIPTION
    Serial番号、MACアドレス、システム情報をまとめて取得します。

.EXAMPLE
    $pcInfo = Get-PCInfo
    if ($pcInfo.Serial) {
        Write-Host "Serial: $($pcInfo.Serial)"
    }

.OUTPUTS
    PSCustomObject - PC情報オブジェクト
#>
function Get-PCInfo {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "PC情報を取得しています..." -Level INFO

        $serial = Get-SerialNumber
        $mac = Get-MACAddress
        $sysInfo = Get-SystemInfo

        $pcInfo = [PSCustomObject]@{
            Serial      = $serial
            MACAddress  = $mac
            SystemInfo  = $sysInfo
            RetrievedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        Write-SetupLog "PC情報の取得が完了しました" -Level INFO
        return $pcInfo
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-PCInfo"
        return $null
    }
}

<#
.SYNOPSIS
    ディスク情報を取得します。

.DESCRIPTION
    すべての物理ディスクとボリュームの情報を取得します。

.EXAMPLE
    $disks = Get-DiskInfo

.OUTPUTS
    Array - ディスク情報の配列
#>
function Get-DiskInfo {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "ディスク情報を取得しています..." -Level INFO

        $volumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop

        $diskInfo = @()
        foreach ($volume in $volumes) {
            $info = [PSCustomObject]@{
                DriveLetter  = $volume.DeviceID
                VolumeName   = $volume.VolumeName
                FileSystem   = $volume.FileSystem
                TotalSizeGB  = [Math]::Round($volume.Size / 1GB, 2)
                FreeSpaceGB  = [Math]::Round($volume.FreeSpace / 1GB, 2)
                UsedSpaceGB  = [Math]::Round(($volume.Size - $volume.FreeSpace) / 1GB, 2)
                UsedPercent  = [Math]::Round((($volume.Size - $volume.FreeSpace) / $volume.Size) * 100, 2)
            }
            $diskInfo += $info
        }

        Write-SetupLog "ディスク情報を取得しました（$($diskInfo.Count) ボリューム）" -Level INFO
        return $diskInfo
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-DiskInfo"
        return @()
    }
}

# エクスポート
Export-ModuleMember -Function @(
    'Get-SerialNumber',
    'Get-MACAddress',
    'Get-SystemInfo',
    'Write-SystemInfoLog',
    'Get-PCInfo',
    'Get-DiskInfo'
)
