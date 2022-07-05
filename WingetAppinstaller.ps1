$ErrorActionPreference = 'SilentlyContinue'
function Download-AppxPackage {
[CmdletBinding()]
param (
  [string]$Uri,
  [string]$Path = "."
)
   
  process {
    echo ""
    $StopWatch = [system.diagnostics.stopwatch]::startnew()
    $Path = (Resolve-Path $Path).Path
    #Get Urls to download
    Write-Host -ForegroundColor Yellow "Processing $Uri"
    $WebResponse = Invoke-WebRequest -UseBasicParsing -Method 'POST' -Uri 'https://store.rg-adguard.net/api/GetFiles' -Body "type=url&url=$Uri&ring=Retail" -ContentType 'application/x-www-form-urlencoded'
    $LinksMatch = ($WebResponse.Links | where {$_ -like '*.appx*'} | where {$_ -like '*_neutral_*' -or $_ -like "*_"+$env:PROCESSOR_ARCHITECTURE.Replace("AMD","X").Replace("IA","X")+"_*"} | Select-String -Pattern '(?<=a href=").+(?=" r)').matches.value
    $Files = ($WebResponse.Links | where {$_ -like '*.appx*'} | where {$_ -like '*_neutral_*' -or $_ -like "*_"+$env:PROCESSOR_ARCHITECTURE.Replace("AMD","X").Replace("IA","X")+"_*"} | where {$_ } | Select-String -Pattern '(?<=noreferrer">).+(?=</a>)').matches.value
    #Create array of links and filenames
    $DownloadLinks = @()
    for($i = 0;$i -lt $LinksMatch.Count; $i++){
        $Array += ,@($LinksMatch[$i],$Files[$i])
    }
    #Sort by filename descending
    $Array = $Array | sort-object @{Expression={$_[1]}; Descending=$True}
    $LastFile = "temp123"
    for($i = 0;$i -lt $LinksMatch.Count; $i++){
        $CurrentFile = $Array[$i][1]
        $CurrentUrl = $Array[$i][0]
        #Find first number index of current and last processed filename
        if ($CurrentFile -match "(?<number>\d)"){}
        $FileIndex = $CurrentFile.indexof($Matches.number)
        if ($LastFile -match "(?<number>\d)"){}
        $LastFileIndex = $LastFile.indexof($Matches.number)

        #If current filename product not equal to last filename product
        if (($CurrentFile.SubString(0,$FileIndex-1)) -ne ($LastFile.SubString(0,$LastFileIndex-1))) {
            #If file not already downloaded, add to the download queue
            if (-Not (Test-Path "$Path\$CurrentFile")) {
                "Downloading $Path\$CurrentFile"
                $FilePath = "$Path\$CurrentFile"
                $FileRequest = Invoke-WebRequest -Uri $CurrentUrl -UseBasicParsing #-Method Head
                [System.IO.File]::WriteAllBytes($FilePath, $FileRequest.content)
            }
        #Delete file outdated and already exist
        }elseif ((Test-Path "$Path\$CurrentFile")) {
            Remove-Item "$Path\$CurrentFile"
            "Removing $Path\$CurrentFile"
        }
        $LastFile = $CurrentFile
    }
    "Time to process: "+$StopWatch.ElapsedMilliseconds
  }
}


if (-Not (Test-Path "C:\Support\Store")) {
    Write-Host -ForegroundColor Green "Creating directory C:\Support\Store"
    New-Item -ItemType Directory -Force -Path "C:\Support\Store"
}

Download-AppxPackage "https://apps.microsoft.com/store/detail/appinstallation/9NBLGGH4NNS1?hl=da-dk&gl=DK" "$PSScriptroot\"

Add-AppPackage -path $PSScriptRoot\Microsoft.UI.Xaml.2.7_7.2203.17001.0_x64__8wekyb3d8bbwe.appx
Add-AppPackage -path $PSScriptRoot\Microsoft.VCLibs.140.00.UWPDesktop_14.0.30704.0_x64__8wekyb3d8bbwe.appx
Add-AppxPackage -path $PSScriptRoot\Microsoft.DesktopAppInstaller_2021.1207.203.0_neutral_~_8wekyb3d8bbwe.appxbundle

#Install Folder
Invoke-WebRequest -Uri https://github.com/thatian75642/Winget-Task-Sequence/raw/main/Microsoft.DesktopAppInstaller_1.17.11601.0_x64__8wekyb3d8bbwe.zip -OutFile $PSScriptRoot\Microsoft.DesktopAppInstaller_1.17.11601.0_x64__8wekyb3d8bbwe.zip
Expand-Archive -Path "$PSScriptRoot\Microsoft.DesktopAppInstaller_1.17.11601.0_x64__8wekyb3d8bbwe.zip" -DestinationPath "$PSScriptRoot\Microsoft.DesktopAppInstaller_1.17.11601.0_x64__8wekyb3d8bbwe"
Remove-Item -path "$PSScriptRoot\Microsoft.DesktopAppInstaller_1.17.11601.0_x64__8wekyb3d8bbwe.zip"

Invoke-WebRequest -Uri https://raw.githubusercontent.com/thatian75642/Winget-Task-Sequence/main/Winget%20Install%20App.ps1 -OutFile $PSScriptRoot\Winget-install.ps1
.\Winget-install.ps1 -AppIDs notepad++.notepad++
.\winget-install.ps1 -AppIDs 7zip.7zip,notepad++.notepad++
