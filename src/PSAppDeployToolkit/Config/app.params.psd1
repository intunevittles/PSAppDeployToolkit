@{
    AppName           = "VLC Media Player"
    AppVersion        = "3.0.20"
    Publisher         = "VideoLAN"
    DisplayName       = "VLC Media Player"
    Description       = "VLC is a free, open-source media player that plays most multimedia files."
    InstallCommand    = "Deploy-Application.exe"
    UninstallCommand  = "Deploy-Application.exe Uninstall"
    IconPath          = "C:\Path\To\VLC\vlc_icon.ico"
    DetectionScript   = "C:\Path\To\VLC\Detect-VLC.ps1"
    MinimumOS         = "20H2"
    Architecture      = "All"
}