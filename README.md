# Valheim-Dedicated-Windows
#A Valheim Dedicated Server auto update script for Windows (Powershell)
#Place the config file and powershell script in C:\SteamCMD folder along with steamcmd.exe.
#You need to download SteamCMD and install the server yourself to C:\Valheim.
#If your paths differ, update the script and config file with your own paths.

#Contents example of the config file:

{
    "servername":  "lazyservername",
    "port": "2456",
    "password": "notsosecret",
    "gameid":  "896660",
    "steamcmd":  "C:\\Steamcmd\\steamcmd.exe",
    "forceinstalldir":  "C:\\Valheim"
}
