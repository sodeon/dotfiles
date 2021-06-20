## OpenSSH
    https://winscp.net/eng/docs/guide_windows_openssh_server#on_windows_10_version_1803_and_newer

    Optional features -> OpenSSH server

    Start the service and/or configure automatic start:
        Administrative Tools and open Services. Locate OpenSSH SSH Server service.
        In the Properties dialog, Right click -> Properties -> (Manual->Automatic)
        Right click -> Start

    Config SSH Server
        http://woshub.com/using-ssh-key-based-authentication-on-windows/
        Copy sshd_config to C:/ProgramData/ssh

    Bash as SSH default shell
        https://www.hanselman.com/blog/the-easy-way-how-to-ssh-into-bash-and-wsl2-on-windows-10-from-an-external-machine
        $New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\WINDOWS\System32\bash.exe" -PropertyType String -Force

## Free Disk Space
    Cleanup WinSxS folder (which will grow in size gradually): dism.exe /online /Cleanup-Image /StartComponentCleanup
