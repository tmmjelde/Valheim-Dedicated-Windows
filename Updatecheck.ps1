$Config = Get-Content "C:\SteamCMD\Updatecheck.config" | convertfrom-json
<#Contents example of the config file
{
    "servername":  "lazyservername",
    "world": "Dedicated"
    "port": "2456",
    "password": "notsosecret",
    "gameid":  "896660",
    "steamcmd":  "C:\\Steamcmd\\steamcmd.exe",
    "forceinstalldir":  "C:\\Valheim",
    "BackupsEnabled":  "False",
    "BackupsFolder":  "C:\\ValheimBackup",
    "BackupsDaysToKeep":  "7"
}
#>
Function Start-Valheim {
    #Starts the Valheim Server
    #Should add -saves parameter to allow config file to specify where save files are located.
    $Process = get-process valheim_server -ErrorAction SilentlyContinue
    if ($Process){
        write-host "Valheim already running"
    }else {
        $env:SteamAppId="892970"
        Start-Process "$($config.forceinstalldir)\valheim_server.exe" -ArgumentList "-nographics -batchmode -name `"$($config.servername)`" -port $($config.port) -world `"$($config.world)`" -password `"$($config.password)`""
    }
}
Function Update-Valheim {
    #Starts updating the Valheim Server
    $Process = get-process valheim_server -ErrorAction SilentlyContinue
    if ($Process){
        write-host "Stop the game server first: Stop-Valheim"
    }else {
        Write-Host "Updating $($config.servername)"
        Start-Process "$($config.steamcmd)" -ArgumentList "+login anonymous +force_install_dir `"$($config.forceinstalldir)`" +app_update $($config.gameid) validate +exit" -wait
    }
}
Function Stop-Valheim {
    #Sends Ctrl+C to the Valheim window, which saves the server first and shuts down cleanly
    $Process = get-process valheim_server -ErrorAction SilentlyContinue
    if ($Process){
        # be sure to set $ProcessID properly. Sending CTRL_C_EVENT signal can disrupt or terminate a process
        $ProcessID = $Process.Id
        $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("Add-Type -Names 'w' -Name 'k' -M '[DllImport(""kernel32.dll"")]public static extern bool FreeConsole();[DllImport(""kernel32.dll"")]public static extern bool AttachConsole(uint p);[DllImport(""kernel32.dll"")]public static extern bool SetConsoleCtrlHandler(uint h, bool a);[DllImport(""kernel32.dll"")]public static extern bool GenerateConsoleCtrlEvent(uint e, uint p);public static void SendCtrlC(uint p){FreeConsole();AttachConsole(p);GenerateConsoleCtrlEvent(0, 0);}';[w.k]::SendCtrlC($ProcessID)"))
        start-process powershell.exe -argument "-nologo -noprofile -executionpolicy bypass -EncodedCommand $encodedCommand"
        write-host "Waiting for Process $($ProcessID) to stop"
        Wait-Process -id $ProcessID
    } else {
        write-host "no process found, not terminating anything"
    }
}
Function Get-ValheimCurrentVersion {
    ((Get-Content "$($config.forceinstalldir)\steamapps\appmanifest_$($config.gameid).acf" | Where-Object {$_ -like "*buildid*"}).split('"').trim() | Where-Object {$_})[-1]
}
Function Get-ValheimLatestVersion {
    Write-Host "Checking for latest version online..."
    try {
        $Data = Invoke-WebRequest -Uri "https://api.steamcmd.net/v1/info/$($config.gameid)"
        $json = $data.content | convertfrom-json
        $BuildID = $json.data.$($config.gameid).depots.branches.public.buildid
    }
        catch {
        write-host "Unable to reach steam servers. Error: $error"
        $BuildID = "NotAvailable"
    }
    Return $BuildID
}


Function Start-ValheimBackupRegular {
    #This will back up Valheim world
    #Should implement support for -saves parameter in config file and link the backup there if specified.
    
    #Check if backup folder exists. If not, create it.
    if ($Config.BackupsFolder){
        if (!(test-path $Config.Backupsfolder)){New-Item $Config.Backupsfolder -ItemType Directory}
    
        $DBFile = Get-ChildItem "$($env:userprofile)\appdata\LocalLow\IronGate\Valheim\worlds\\$($Config.world).db"
        $FWLFile = Get-ChildItem "$($env:userprofile)\appdata\LocalLow\IronGate\Valheim\worlds\$($Config.world).fwl"
        $Date = get-date $DBFile.LastWriteTime -format "yyyy-MM-dd_HH-mm"
        $Destination = "$($Config.Backupsfolder)\$($config.world)\$date"
        $Destination
        if (!(test-path $Destination)){New-Item -Path $Destination -ItemType Directory
            Copy-Item $DBFile -Destination $Destination
            Copy-Item $FWLFile -Destination $Destination
        }
    } Else {
        Write-Host "Update config file with BackupsFolder"
    }
}
Function Start-ValheimBackupCleanup {
    #This will clean up old backups
    
    if ($Config.BackupsDaysToKeep){
        #Check if backup folder exists. If not, create it.
        if (!(test-path $Config.Backupsfolder)){New-Item $Config.Backupsfolder -ItemType Directory}
        $DeleteOlderThan = (Get-Date).AddDays(-$($Config.BackupsDaysToKeep))
        $FolderToClean = "$($Config.Backupsfolder)\$($config.world)"
        Get-ChildItem $FolderToClean | Where-Object {$_.LastWriteTime -lt $DeleteOlderThan} | Remove-Item -Recurse
    } Else {
        Write-Host "Update config file with BackupDaysToKeep"
    }
}

#Run every 300 seconds forever
$stop = "$false"
do{
    $BuildID = Get-ValheimLatestVersion
    $CurrentBuildID = Get-ValheimCurrentVersion
    
    if ( ($BuildID -ne $CurrentBuildID) -and ($BuildID -ne "NotAvailable") ) {
        #New version detected. Initiating patching
        write-host "New version found. Stopping and updating Valheim_server"
        Stop-Valheim
        Update-Valheim
    } else {
        Write-host "Newest buildid is current: $($BuildID)"
    }
    if ($Config.BackupsEnabled -eq "True") {
        Start-ValheimBackupRegular
        Start-ValheimBackupCleanup
    }
    #This will start Valheim after patching, and even if it's not patched but crashed for some reason
    Start-Valheim
    #Will run every 5 minutes (300 seconds)
    Start-Sleep -Seconds 300
} while ($stop)
