# Setup.Tests.ps1
# PowerShellセットアップスクリプトの単体テスト
# Pester v5 対応
# UTF-8 BOM付きで保存

<#
.SYNOPSIS
    PowerShellセットアップスクリプトのPesterテスト

.DESCRIPTION
    各モジュールの関数をモックして単体テストを実行します。

.EXAMPLE
    Invoke-Pester -Path .\tests\Setup.Tests.ps1
#>

BeforeAll {
    # テスト用のパス設定
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModulePath = Join-Path -Path $ProjectRoot -ChildPath "powershell-scripts\modules"

    # モジュールのインポート
    Import-Module (Join-Path -Path $ModulePath -ChildPath "Logger.psm1") -Force
    Import-Module (Join-Path -Path $ModulePath -ChildPath "PCInfo.psm1") -Force
    Import-Module (Join-Path -Path $ModulePath -ChildPath "API.psm1") -Force
    Import-Module (Join-Path -Path $ModulePath -ChildPath "Domain.psm1") -Force
    Import-Module (Join-Path -Path $ModulePath -ChildPath "WindowsUpdate.psm1") -Force
    Import-Module (Join-Path -Path $ModulePath -ChildPath "AppInstall.psm1") -Force
}

Describe "Logger.psm1 Tests" {
    Context "Write-SetupLog" {
        It "Should write log message without error" {
            { Write-SetupLog "Test message" -Level INFO -NoConsole } | Should -Not -Throw
        }

        It "Should create log directory if not exists" {
            $testLogPath = "TestDrive:\Logs"
            Initialize-LogDirectory -Path $testLogPath | Should -Be $true
            Test-Path -Path $testLogPath | Should -Be $true
        }
    }

    Context "Start-SetupTranscript" {
        It "Should start transcript without error" {
            # トランスクリプト機能は環境依存のためスキップ
            Set-ItResult -Skipped -Because "Transcript is environment-dependent"
        }
    }
}

Describe "PCInfo.psm1 Tests" {
    Context "Get-SerialNumber" {
        It "Should return a serial number" {
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    SerialNumber = "ABC123456"
                }
            }

            $serial = Get-SerialNumber
            $serial | Should -Not -BeNullOrEmpty
            $serial | Should -BeOfType [string]
        }

        It "Should handle missing serial number gracefully" {
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    SerialNumber = $null
                }
            }

            $serial = Get-SerialNumber
            $serial | Should -Be ""
        }
    }

    Context "Get-MACAddress" {
        It "Should return a MAC address" {
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    MACAddress      = "00-11-22-33-44-55"
                    PhysicalAdapter = $true
                    NetEnabled      = $true
                }
            }

            $mac = Get-MACAddress
            $mac | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-SystemInfo" {
        It "Should return system information object" {
            Mock Get-CimInstance {
                param($ClassName)
                switch ($ClassName) {
                    "Win32_OperatingSystem" {
                        return [PSCustomObject]@{
                            Caption          = "Windows 11 Pro"
                            Version          = "10.0.22621"
                            BuildNumber      = "22621"
                            OSArchitecture   = "64-bit"
                            LastBootUpTime   = Get-Date
                            InstallDate      = Get-Date
                        }
                    }
                    "Win32_ComputerSystem" {
                        return [PSCustomObject]@{
                            Name               = "TEST-PC"
                            Domain             = "WORKGROUP"
                            PartOfDomain       = $false
                            Manufacturer       = "Dell Inc."
                            Model              = "OptiPlex 7090"
                            TotalPhysicalMemory = 16GB
                        }
                    }
                    "Win32_Processor" {
                        return [PSCustomObject]@{
                            Name                     = "Intel Core i7-10700"
                            NumberOfCores            = 8
                            NumberOfLogicalProcessors = 16
                        }
                    }
                }
            }

            $sysInfo = Get-SystemInfo
            $sysInfo | Should -Not -BeNullOrEmpty
            $sysInfo.ComputerName | Should -Be "TEST-PC"
            $sysInfo.OSName | Should -Be "Windows 11 Pro"
        }
    }
}

Describe "API.psm1 Tests" {
    Context "Test-APIConnection" {
        It "Should return true for successful connection" {
            Mock Invoke-RestMethod {
                return @{ status = "ok" }
            }

            $result = Test-APIConnection -APIServer "http://192.168.1.100:5000"
            $result | Should -Be $true
        }

        It "Should return false for failed connection" {
            Mock Invoke-RestMethod {
                throw "Connection failed"
            }

            $result = Test-APIConnection -APIServer "http://192.168.1.100:5000"
            $result | Should -Be $false
        }
    }

    Context "Get-PCInfoFromAPI" {
        It "Should return PC info from API" {
            Mock Invoke-RestMethod {
                return [PSCustomObject]@{
                    pcname   = "20251116M"
                    odj_path = "/odj/20251116M.txt"
                }
            }

            $pcInfo = Get-PCInfoFromAPI -APIServer "http://192.168.1.100:5000" -Serial "ABC123"
            $pcInfo | Should -Not -BeNullOrEmpty
            $pcInfo.pcname | Should -Be "20251116M"
            $pcInfo.odj_path | Should -Be "/odj/20251116M.txt"
        }

        It "Should retry on failure" {
            $script:callCount = 0
            Mock Invoke-RestMethod {
                $script:callCount++
                if ($script:callCount -lt 3) {
                    throw "Temporary failure"
                }
                return [PSCustomObject]@{
                    pcname   = "20251116M"
                    odj_path = "/odj/20251116M.txt"
                }
            }

            $pcInfo = Get-PCInfoFromAPI -APIServer "http://192.168.1.100:5000" -Serial "ABC123" -RetryCount 3 -RetryDelay 1
            $script:callCount | Should -BeGreaterThan 1
        }
    }

    Context "Send-SetupLog" {
        It "Should send log data successfully" {
            Mock Invoke-RestMethod {
                return @{ result = "ok" }
            }

            $logData = @{
                serial    = "ABC123"
                pcname    = "20251116M"
                status    = "completed"
                timestamp = "2025-11-16 12:00:00"
            }

            $result = Send-SetupLog -APIServer "http://192.168.1.100:5000" -LogData $logData
            $result | Should -Be $true
        }
    }
}

Describe "Domain.psm1 Tests" {
    Context "Test-PCNameFormat" {
        It "Should validate correct PC name format" {
            $result = Test-PCNameFormat -PCName "20251116M"
            $result | Should -Be $true
        }

        It "Should reject invalid PC name format" {
            $result = Test-PCNameFormat -PCName "INVALID-PC"
            $result | Should -Be $false
        }

        It "Should reject PC name with invalid date" {
            $result = Test-PCNameFormat -PCName "20251332M"  # 13月32日
            $result | Should -Be $false
        }
    }

    Context "Set-PCName" {
        It "Should set PC name with valid format" {
            Mock Rename-Computer {}
            Mock Test-PCNameFormat { return $true }

            $result = Set-PCName -NewName "20251116M" -Force
            $result | Should -Be $true
        }

        It "Should reject PC name with invalid format" {
            $result = Set-PCName -NewName "INVALID" -Force
            $result | Should -Be $false
        }
    }

    Context "Test-DomainJoin" {
        It "Should return true if domain joined" {
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    PartOfDomain = $true
                    Domain       = "example.com"
                }
            }

            $result = Test-DomainJoin
            $result | Should -Be $true
        }

        It "Should return false if not domain joined" {
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    PartOfDomain = $false
                    Domain       = "WORKGROUP"
                }
            }

            $result = Test-DomainJoin
            $result | Should -Be $false
        }
    }
}

Describe "WindowsUpdate.psm1 Tests" {
    Context "Test-UpdatesRequired" {
        It "Should return true if updates are required" {
            Mock Get-UpdateCount { return 5 }

            $result = Test-UpdatesRequired
            $result | Should -Be $true
        }

        It "Should return false if no updates required" {
            Mock Get-UpdateCount { return 0 }

            $result = Test-UpdatesRequired
            $result | Should -Be $false
        }
    }

    Context "Test-RebootRequired" {
        It "Should detect reboot requirement from registry" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{
                    RebootPending = $true
                }
            }

            $result = Test-RebootRequired
            $result | Should -Be $true
        }
    }
}

Describe "AppInstall.psm1 Tests" {
    Context "Test-AppInstalled" {
        It "Should detect installed app by path" {
            Mock Test-Path { return $true }

            $result = Test-AppInstalled -AppName "Test App" -CheckPath "C:\Program Files\TestApp\app.exe"
            $result | Should -Be $true
        }

        It "Should detect installed app by registry" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{
                    DisplayName = "Test App"
                }
            }

            $result = Test-AppInstalled -AppName "Test App"
            $result | Should -Be $true
        }

        It "Should return false for uninstalled app" {
            Mock Test-Path { return $false }
            Mock Get-ItemProperty { return $null }

            $result = Test-AppInstalled -AppName "Test App"
            $result | Should -Be $false
        }
    }

    Context "Install-Application" {
        It "Should install application successfully" {
            Mock Test-Path { return $true }
            Mock Start-Process {
                return [PSCustomObject]@{
                    ExitCode  = 0
                    HasExited = $true
                }
            }
            Mock Wait-Process {}

            $result = Install-Application -AppName "Test App" -InstallerPath "C:\Setup\Apps\test.exe" -Silent
            $result | Should -Be $true
        }

        It "Should fail if installer not found" {
            Mock Test-Path { return $false }

            $result = Install-Application -AppName "Test App" -InstallerPath "C:\Setup\Apps\notfound.exe" -Silent
            $result | Should -Be $false
        }
    }
}

AfterAll {
    # クリーンアップ
    Remove-Module Logger -ErrorAction SilentlyContinue
    Remove-Module PCInfo -ErrorAction SilentlyContinue
    Remove-Module API -ErrorAction SilentlyContinue
    Remove-Module Domain -ErrorAction SilentlyContinue
    Remove-Module WindowsUpdate -ErrorAction SilentlyContinue
    Remove-Module AppInstall -ErrorAction SilentlyContinue
}
