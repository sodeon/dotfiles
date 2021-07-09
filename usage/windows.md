## OpenSSH
    https://winscp.net/eng/docs/guide_windows_openssh_server#on_windows_10_version_1803_and_newer

    Optional features -> OpenSSH server

    Start the service and/or configure automatic start:
        Administrative Tools and open Services. Locate OpenSSH SSH Server service.
        In the Properties dialog, Right click -> Properties -> (Manual->Automatic)
        Right click -> Start

## Free Disk Space
    Cleanup WinSxS folder (which will grow in size gradually): dism.exe /online /Cleanup-Image /StartComponentCleanup
