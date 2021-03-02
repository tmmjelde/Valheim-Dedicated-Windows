# Valheim-Dedicated-Windows
#A Valheim Dedicated Server auto update script for Windows (Powershell)
#Place the config file and powershell script in C:\SteamCMD folder along with steamcmd.exe.
#You need to download SteamCMD and install the server yourself to C:\Valheim.
#If your paths differ, update the script and config file with your own paths.

#Backups are in testing, and not completely verified yet.
#Backups will not be made unless BackupsEnabled:True in your config file.
#BackupsFolder will be created if it doesn't exist.
#BackupsDaysToKeep will create a lot of data over time if set to 7 days.
#Consider that Valheim creates an automatic backup every 20 minutes, as well as manual "Save" commands from console, and every time "Stop-Valheim" is used.
#If your world is 70MB, it will be 7 days * 24 hours * 3 backups per hour * 70 MB = 35GB

#Contents example of the config file:

Note that this is a JSON Formatted configuration file.
Any directory paths need to have double \\ instead of single \.
Every line must be separated by a ,
Except the last line.
The file must start with { and end with }

{
    "servername":  "lazyservername",
    "port": "2456",
    "password": "notsosecret",
    "gameid":  "896660",
    "steamcmd":  "C:\\Steamcmd\\steamcmd.exe",
    "forceinstalldir":  "C:\\Valheim",
    "BackupsEnabled":  "False",
    "BackupsFolder":  "C:\\ValheimBackup",
    "BackupsDaysToKeep":  "7"
}

