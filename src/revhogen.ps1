function Update-Accessibility {
    $current = "$($script:MyInvocation.MyCommand.Path)"
    $command = "-ExecutionPolicy Bypass -NoExit -NoLogo -File `"$current`""
    $granted = [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544"
    $heading = Get-Item -Path "$current" | Select-Object -ExpandProperty BaseName
    $removed = $null -eq (Get-Command "wt" -EA SilentlyContinue)
    $session = Test-Path -Path env:WT_SESSION
    if (-not $granted -and $removed) {
        $command = "-ExecutionPolicy Bypass -NoLogo -File `"$current`""
        Start-Process -FilePath "powershell" -ArgumentList "$command" -Verb RunAs
        Write-Host "`n" ; Exit
    }
    elseif (-not $granted -and -not $removed) {
        $command = "nt -d `"$PSScriptRoot`" --title `"$heading`" powershell $command"
        Start-Process -FilePath "wt" -ArgumentList "$command" -Verb RunAs ; Exit
    }
    elseif (-not $removed -and -not $session) {
        $command = "nt -d `"$PSScriptRoot`" --title `"$heading`" powershell $command"
        Start-Process -FilePath "wt" -ArgumentList "$command" -Verb RunAs ; Exit
    }
}

function Update-NvidiaGameReadyDriver {
    $address = "https://us.download.nvidia.com"
    $address = "$address/Windows/516.40/516.40-desktop-win10-win11-64bit-international-dch-whql.exe"
    $adjunct = "-s -noreboot"
    $program = Join-Path -Path "$env:TEMP" -ChildPath "$(Split-Path "$address" -Leaf)"
    (New-Object Net.WebClient).DownloadFile("$address", "$program")
    Start-Process -FilePath "$program" -ArgumentList "$adjunct" -Verb RunAs -Wait
}

function Update-NvidiaGeforceExperience {
    $address = "https://us.download.nvidia.com/GFE/GFEClient"
    $address = "$address/3.25.1.27/GeForce_Experience_v3.25.1.27.exe"
    $adjunct = "-s -noreboot"
    $program = Join-Path -Path "$env:TEMP" -ChildPath "$(Split-Path "$address" -Leaf)"
    (New-Object Net.WebClient).DownloadFile("$address", "$program")
    Start-Process -FilePath "$program" -ArgumentList "$adjunct" -Verb RunAs -Wait
    $lnkfile = [IO.Path]::Combine([Environment]::GetFolderPath("CommonDesktopDirectory"), "*GeForce*.lnk")
    if (Test-Path -Path "$lnkfile") { Remove-Item -Path "$lnkfile" }
    $lnkfile = [IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "*GeForce*.lnk")
    if (Test-Path -Path "$lnkfile") { Remove-Item -Path "$lnkfile" }
    # https://github.com/Moyster/BaiGfe/issues/26
    $deposit = "C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience\www\"
    $archive = "https://github.com/Moyster/BaiGfe/files/8431929/app.zip"
    Rename-Item -Path "$deposit/app.js" -NewName "$deposit/_app.js"
}

function Update-Qbittorrent {
    $deposit = "${env:USERPROFILE}\Downloads\P2P"
    $loading = "${env:USERPROFILE}\Downloads\P2P\Incompleted"
    $starter = "${env:PROGRAMFILES}\qBittorrent\qbittorrent.exe"
    $website = "https://www.qbittorrent.org/download.php"
    $pattern = "Latest:\s+v([\d.]+)"
    $content = (New-Object Net.WebClient).DownloadString("$website")
    $version = [Regex]::Matches("$content", "$pattern").Groups[1].Value
    $current = try { (Get-Command "$starter" -ErrorAction SilentlyContinue).Version.ToString() } catch { '0.0.0.0' }
    $updated = [Version] "$current" -ge [Version] "$version"
    if (-not $updated) {
        $address = "https://downloads.sourceforge.net/project/qbittorrent/qbittorrent-win32"
        $address = "$address/qbittorrent-${version}/qbittorrent_${version}_x64_setup.exe"
        $adjunct = "/S"
        $program = Join-Path -Path "$env:TEMP" -ChildPath "$(Split-Path "$address" -Leaf)"
        (New-Object Net.WebClient).DownloadFile("$address", "$program")
        Start-Process -FilePath "$program" -ArgumentList "$adjunct" -Verb RunAs -Wait
    }
    New-Item -Path "$deposit" -ItemType Directory -EA SilentlyContinue
    New-Item -Path "$loading" -ItemType Directory -EA SilentlyContinue
    $configs = "${env:APPDATA}\qBittorrent\qBittorrent.ini"
    New-Item -Path $(Split-Path "$configs") -ItemType Directory -EA SilentlyContinue
    Set-Content -Path "$configs" -Value "[LegalNotice]"
    Add-Content -Path "$configs" -Value "Accepted=true"
    Add-Content -Path "$configs" -Value "[Preferences]"
    Add-Content -Path "$configs" -Value "Bittorrent\MaxRatio=0"
    Add-Content -Path "$configs" -Value "Downloads\SavePath=$($deposit.Replace('\', '/'))"
    Add-Content -Path "$configs" -Value "Downloads\TempPath=$($loading.Replace('\', '/'))"
    Add-Content -Path "$configs" -Value "Downloads\TempPathEnabled=true"
}

function Update-System {
    Rename-Computer -NewName "MONOLITH" -EA SilentlyContinue
    Set-TimeZone -Name "Romance Standard Time"
}

if ($MyInvocation.InvocationName -ne ".") {
    $Host.UI.RawUI.WindowTitle = (Get-Item -Path "$($script:MyInvocation.MyCommand.Path)").BaseName
    Update-Accessibility ; $ProgressPreference = "SilentlyContinue" ; Clear-Host
    Write-Host "+--------------------------------------------------------------------+"
    Write-Host "|                                                                    |"
    Write-Host "|  > REVHOGEN                                                        |"
    Write-Host "|                                                                    |"
    Write-Host "|  > REVIOS POST INSTALLATION SCRIPT                                 |"
    Write-Host "|                                                                    |"
    Write-Host "+--------------------------------------------------------------------+"
    $maximum = (70 - 20) * -1
    $heading = "`n{0,$maximum}{1,-3}{2,-6}{3,-3}{4,-8}" -f "FUNCTION", "", "STATUS", "", "DURATION"
    $factors = (
        "Update-System",
        # "Update-NvidiaGameReadyDriver",
        # "Update-NvidiaGeforceExperience",
        "Update-Qbittorrent"
    )
    Write-Host "$heading"
    foreach ($element in $factors) {
        $started = Get-Date
        $content = $($element.Split(' ')[0]).ToUpper()
        $loading = "`n{0,$maximum}{1,-3}{2,-6}{3,-3}{4,-8}" -f "$content", "", "ACTIVE", "", "--:--:--"
        Write-Host "$loading" -ForegroundColor DarkYellow -NoNewline
        try {
            Invoke-Expression $element *> $null
            $waiting = "{0:hh}:{0:mm}:{0:ss}" -f ($(Get-Date) - $started)
            $success = "`r{0,$maximum}{1,-3}{2,-6}{3,-3}{4,-8}" -f "$content", "", "WORKED", "", "$waiting"
            Write-Host "$success" -ForegroundColor Green -NoNewLine
        }
        catch {
            $waiting = "{0:hh}:{0:mm}:{0:ss}" -f ($(Get-Date) - $started)
            $failure = "`r{0,$maximum}{1,-3}{2,-6}{3,-3}{4,-8}" -f "$content", "", "FAILED", "", "$waiting"
            Write-Host "$failure" -ForegroundColor Red -NoNewLine
        }
    }
    Write-Host "`n"
}