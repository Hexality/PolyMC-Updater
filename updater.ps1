$PSDefaultParameterValues['*:Encoding'] = 'ascii'
Import-Module PSWriteColor
$global:ProgressPreference="SilentlyContinue"

if (($IsWindows -eq $False)) { Write-Color -Text "Incompatible platform! | This updater is meant to be used specifcally with windows, please update using system's package manager instead." -Color Red }
else {
if((($PSVersionTable).PSVersion.Major) -lt 7) {
    if(((Test-Path $env:ProgramFiles\PowerShell\*\pwsh.exe) -eq $True) -and ((($PSVersionTable).PSVersion.Major) -lt 7)) {
        Start-Process pwsh -ArgumentList "-c `"D:\PolyMC\updater.ps1`"" -PassThru
        exit
    }
    else{
    "This version of powershell is not supported."
    "want me to update it for you? ([Y] Yes | [N] No)"
    do {
        $key = [Console]::ReadKey($true)
        $value = $key.KeyChar
        switch ($value) {
            y {
                clear-host
                if(((winget --info)[0]) -like "Windows Package*") { 
                    Write-Color -Text "Windows Package Manager is going to install ","Microsoft.Powershell" -ForegroundColor Yellow,Green
                    Write-Color -Text "Administrator ","permission is ","required." -ForegroundColor Yellow,White,Red
                    Write-Color -Text "Please ","accept ","when prompted." -ForegroundColor Yellow,White,Red
                    winget install Microsoft.Powershell
                }
                else {
                    if((Test-Path $env:TEMP\Powershell.msixbundle) -eq $False) {
                        $psContent = ((Invoke-WebRequest https://api.github.com/repos/PowerShell/PowerShell/releases/latest -ContentType "application/json").Content | ConvertFrom-Json)
                        $psVer = $psContent.tag_name
                        Write-Color -Text "Downloading Powershell"," $psVer from GitHub" -Color
                        $repoVer = $psVer.Trim(' ')
                        $fileVer = $repoVer.Trim('v')
                        $poshUrl = "https://github.com/PowerShell/PowerShell/releases/download/$repoVer/PowerShell-$fileVer-win.msixbundle"
                        Invoke-WebRequest -Uri $poshUrl -OutFile $env:TEMP\Powershell.msixbundle
                    }
                    Write-Color -Text "Installing Powershell" -ForegroundColor Yellow
                    Write-Color -Text "Administrator ","permission is ","required." -ForegroundColor Yellow,White,Red
                    Write-Color -Text "Please ","accept ","when prompted." -ForegroundColor Yellow,White,Red
                    Start-Process PowerShell -NoNewWindow -ArgumentList '-noexit -c "Add-AppxPackage $env:TEMP\Powershell.msixbundle"' -Verb RunAs
                }
            }
            n {
                break
            }
        }
    } while($value -notmatch 'y|n')
    }
    }
else{
#====================# Functions #====================#

    function Show-Changelog {
        clear-host
        $clBody | Show-Markdown
        Write-Color -Text "Press ","Q ","to go back to menu." -Color Black,Red,Black -BackGroundColor White,White,White
        do {
            $key = [Console]::ReadKey($true)
            $value = $key.KeyChar
            switch ($value) {
                q {
                    clear-host
                    Show-Menu
                }
            }
        } while($value -notmatch 'q')
    }
    function Get-File {
        #Function originally made by KUTime, edited for my needs here.
        param (
            [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
            [ValidateNotNullOrEmpty()]
            [System.Uri]
            $uri,
            [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
            [ValidateNotNullOrEmpty()]
            [System.IO.FileInfo]
            $targetFile,
            [Parameter(ValueFromPipelineByPropertyName)]
            [ValidateNotNullOrEmpty()]
            [Int32]
            $bufferSize = 1,
            [Parameter(ValueFromPipelineByPropertyName)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet('KB, MB')]
            [String]
            $bufferUnit = 'MB',
            [Parameter(ValueFromPipelineByPropertyName)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet('KB, MB')]
            [Int32]
            $Timeout = 10000
        )

        $useBitTransfer = $null -ne (Get-Module -Name BitsTransfer -ListAvailable) -and ($PSVersionTable.PSVersion.Major -le 5)

        if ($useBitTransfer) {
            Write-Information -MessageData 'Using a fallback BitTransfer method since you are running Windows PowerShell'
            Start-BitsTransfer -Source $uri -Destination "$($targetFile.FullName)"
        }
        else {
            $request = [System.Net.HttpWebRequest]::Create($uri)
            $request.set_Timeout($Timeout) #15 second timeout
            $response = $request.GetResponse()
            $totalLength = [System.Math]::Floor($response.get_ContentLength())
            $responseStream = $response.GetResponseStream()
            $targetStream = New-Object -TypeName ([System.IO.FileStream]) -ArgumentList "$($targetFile.FullName)", Create
            switch ($bufferUnit) {
                'KB' { $bufferSize = $bufferSize * 1024 }
                'MB' { $bufferSize = $bufferSize * 1024 * 1024 }
                Default { $bufferSize = 1024 * 1024 }
            }
            Write-Verbose -Message "Buffer size: $bufferSize B ($($bufferSize/("1$bufferUnit")) $bufferUnit)"
            $buffer = New-Object byte[] $bufferSize
            $count = $responseStream.Read($buffer, 0, $buffer.length)
            $downloadedBytes = $count
            Start-Sleep -s 2
            Write-Color -NoNewLine -Text "`rDownloading update", "                                                                        `n" -Color Green,White
            while ($count -gt 0) {
                $targetStream.Write($buffer, 0, $count)
                $count = $responseStream.Read($buffer, 0, $buffer.length)
                $downloadedBytes = $downloadedBytes + $count
                $i = [int]([Math]::Round((([Math]::Floor($downloadedBytes/1024))/([Math]::Floor($totalLength/1024)))*100))
                $progressBar = ("`r╼┄┄┄┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼╾┄┄┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼╾┄┄┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═╾┄┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═╾┄┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═╾┄┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══╾┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══╾┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══╾┄┄┄┄┄┄┄┄┄┄┄00$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══╾┄┄┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══╾┄┄┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══╾┄┄┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════╾┄┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════╾┄┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════╾┄┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════╾┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════╾┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════╾┄┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════╾┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════╾┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════╾┄┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══════╾┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══════╾┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══════╾┄┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════════╾┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════════╾┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════════╾┄┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════════╾┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════════╾┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════════╾┄┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════╾┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════╾┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════╾┄┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══════════╾┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══════════╾┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═══════════╾┄┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════════════╾┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════════════╾┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼════════════╾┄0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════════════╾0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════════════╾0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼═════════════╾0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%╾┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%╾┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%╾┄┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═╾┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═╾┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═╾┄┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%══╾┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%══╾┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%══╾┄┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═══╾┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═══╾┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═══╾┄┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%════╾┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%════╾┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%════╾┄┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═════╾┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═════╾┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═════╾┄┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%══════╾┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%══════╾┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%══════╾┄┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═══════╾┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═══════╾┄┄┄┄┄┄┄","`r╼══════════════0$($i)%═══════╾┄┄┄┄┄┄┄","`r╼══════════════0$($i)%════════╾┄┄┄┄┄┄","`r╼══════════════0$($i)%════════╾┄┄┄┄┄┄","`r╼══════════════0$($i)%════════╾┄┄┄┄┄┄","`r╼══════════════0$($i)%═════════╾┄┄┄┄┄","`r╼══════════════0$($i)%═════════╾┄┄┄┄┄","`r╼══════════════0$($i)%═════════╾┄┄┄┄┄","`r╼══════════════0$($i)%══════════╾┄┄┄┄","`r╼══════════════0$($i)%══════════╾┄┄┄┄","`r╼══════════════0$($i)%══════════╾┄┄┄┄","`r╼══════════════0$($i)%═══════════╾┄┄┄","`r╼══════════════0$($i)%═══════════╾┄┄┄","`r╼══════════════0$($i)%═══════════╾┄┄┄","`r╼══════════════0$($i)%════════════╾┄┄","`r╼══════════════0$($i)%════════════╾┄┄","`r╼══════════════0$($i)%════════════╾┄┄","`r╼══════════════0$($i)%════════════╾┄┄","`r╼══════════════0$($i)%═════════════╾┄","`r╼══════════════0$($i)%═════════════╾┄","`r╼══════════════0$($i)%═════════════╾┄","`r╼══════════════0$($i)%═════════════╾┄","`r╼══════════════0$($i)%══════════════╾","`r╼══════════════$($i)%══════════════╾")
                Write-Color -NoNewLine -Text "`r$($ProgressBar[$i])","                        " -Color Yellow,White
            }
            Clear-Host
            Write-Color -NoNewLine -Text "`nFinished downloading update.", "                                              " -Color Green, White
            $targetStream.Flush()
            $targetStream.Close()
            $targetStream.Dispose()
            $responseStream.Dispose()
        }
    }
    function Extract {
        # By gangstanthony
        param (
            [string]$file,
            [string]$destination
        )
    
        if (!$destination) {
            $destination = [string](Resolve-Path $file)
            $destination = $destination.Substring(0, $destination.LastIndexOf('.'))
            mkdir $destination | Out-Null
        }
        $shell = New-Object -ComObject Shell.Application
        #$shell.NameSpace($destination).CopyHere($shell.NameSpace($file).Items(), 16);
        $zip = $shell.NameSpace($file)
        foreach ($item in $zip.items()) {
            $shell.Namespace($destination).CopyHere($item)
        }
    }
    function Show-Menu{
        $MenuOptions = ("            Update it           ","         Remind me later        ","         Show changelog         ")
    
        $MaxValue = $MenuOptions.count-1
        $Selection = 0
        $EnterPressed = $False
        
        Clear-Host

        While($EnterPressed -eq $False){
            
            Write-Color -Text "        New update found     "       -Color Green
            Write-Color -Text "╭────────────────────────────────╮"          -Color Green
            Write-Color -Text "│        Want to update?         │"   -Color Green
            Write-Color -Text "├────────────────────────────────┤"          -Color Green
            For ($i=0; $i -le $MaxValue; $i++){
                
                If ($i -eq $Selection){
                    Write-Color -Text "│","$($MenuOptions[$i])","│" -ForegroundColor Green,Black,Green -BackGroundColor Black,Yellow,Black
                    If($i -ne $MaxValue){
                        Write-Color -Text "├────────────────────────────────┤" -ForegroundColor Green -BackGroundColor Black
                    }
                } Else {
                    Write-Color -Text "│","$($MenuOptions[$i])","│" -ForegroundColor Green,White,Green -BackGroundColor Black,Black,Black
                    If($i -ne $MaxValue){
                        Write-Color -Text "├────────────────────────────────┤" -ForegroundColor Green -BackGroundColor Black
                    }
                }
                If($i -eq $MaxValue){
                    Write-Color -Text "╰────────────────────────────────╯" -ForegroundColor Green -BackGroundColor Black
                    Write-Color -Text " Up/Down to nav, Enter to select." -ForegroundColor Green -BackGroundColor Black
                }
    
            }
    
            $KeyInput = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown").virtualkeycode
    
            Switch($KeyInput){
                13{
                    $EnterPressed = $True
                    if ($Selection -eq 0) {
                        Clear-Host
                        Write-Color -Text "Y pressed, updating...`n" -Color Green
                        UpdateLauncher
                    }
                    elseif($selection -eq 1) {
                        Write-Color -Text "`nUpdate postponed, closing...`n"
                        Start-Sleep -s 2s
                        pwsh -windowstyle hidden -c "Start-Process D:\PolyMC\PolyMC.exe ; exit"
                        exit
                    }
                    elseif ($selection -eq 2) {
                        Show-Changelog
                    }
                }
    
                38{
                    If ($Selection -eq 0){
                        $Selection = $MaxValue
                    } Else {
                        $Selection -= 1
                    }
                    Clear-Host
                    break
                }
    
                40{
                    If ($Selection -eq $MaxValue){
                        $Selection = 0
                    } Else {
                        $Selection +=1
                    }
                    Clear-Host
                    break
                }
                Default{
                    Clear-Host
                }
            }
        }
    }
    function UpdateLauncher {
        $Urls = ((($jsonResponse.assets.browser_download_url -Match "Windows") -Match "zip") -NotMatch "Portable")
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            $dlUrl = $Urls -Match "x86_64"
        } 
        elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
            $dlUrl = $Urls -Match "i686"
        } 
        else {
            "Unsupported System!"
            break
        }
        mkdir "$($PSScriptRoot)\_Temp" -ErrorAction SilentlyContinue
        $cachePath = "$($PSScriptRoot)\_Temp"
        
        Get-File -Uri "$($dlUrl)" -TargetFile "$cachePath\Update.zip" -ErrorAction SilentlyContinue
        Start-Sleep -s 2
        Clear-Host
        Write-Color -NoNewLine -Text "`nExtracting archive...", "                                              " -Color Green,White
        Expand-Archive -Path "$cachePath\Update.zip" -DestinationPath "$cachePath\" -Force
        Start-Sleep -s 2
        Remove-Item "$cachePath\Update.zip"
        Start-Sleep -s 2
        Move-Item "$cachePath\*" "$cachePath\..\" -Force
        Write-Color -Text "Update complete"
        Start-Sleep -s 2
        pwsh -windowstyle hidden -c "Start-Process D:\PolyMC\PolyMC.exe ; exit"
        exit
    }

#=====================================================#

    $latest = '{"Major": 0, "Minor": 0, "Build": 0}' | ConvertFrom-Json
    $current = (Get-Item "$($PSScriptRoot)\PolyMC.exe").VersionInfo.FileVersionRaw
    $jsonResponse = ((Invoke-WebRequest https://api.github.com/repos/polymc/polymc/releases/latest -contenttype 'application/json').Content | ConvertFrom-Json)
    $tag = $jsonResponse.tag_name
    $clBody = $jsonResponse.Body
    $latest.Major, $latest.Minor, $latest.Build = $tag.Split('.')
    if (($current.Major -lt $latest.Major) -or ($current.Minor -lt $latest.Minor) -or ($current.Build -lt $latest.Build)) {
        Clear-Host
        Show-Menu
    }
    else {
        pwsh -windowstyle hidden -c "Start-Process $PSScriptRoot\PolyMC.exe ; exit"
        exit
    }
}}