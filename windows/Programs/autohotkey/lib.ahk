#Include %A_LineFile%/../notification.ahk
#Include %A_LineFile%/../dual-key.ahk
#Include %A_LineFile%/../mouse-mode.ahk
#Include %A_LineFile%/../monitor.ahk
#Include %A_LineFile%/../virtual-desktop.ahk


;-------------------------------------------------------------------------------
; Window Switching
;-------------------------------------------------------------------------------
; Bring specified executable to focus. If the appis not launched, launch it
winActivateExe(exe, exePath = "", params = "", runOptions = "Max", dstDesktop = 1) {
    if WinExist("ahk_exe" exe)
        WinActivate, ahk_exe %exe%
    else {
        if (currentDesktop() != dstDesktop)
            switchDesktopByNumber(dstDesktop)

        fullExe := exe
        if (exePath != "")
            fullExe := exePath "\" fullExe
        ; if (params != "")
        ;     fullExe .= " " params
        fullExe := """" fullExe """" ; enclosing command with quotations
        Run, %fullExe% %params%,, %runOptions%
    }
}


;-------------------------------------------------------------------------------
; Maximize window or toggle full screen mode if already maximized
;-------------------------------------------------------------------------------
toggleFullScreen(terminal) {
    if WinActive("ahk_exe " . terminal)
        SendInput !{Enter}
    else
        SendInput {F11}
}

maxThenFullScreen(browser, terminal) {
    WinGet, maximized, MinMax, A
    if (!maximized)
        WinMaximize, A
    else if WinActive("ahk_exe " . browser) && (WinActive("YouTube") || WinActive("Twitch") || WinActive("bilibili") || WinActive("Netflix"))
        SendInput f
    else 
        toggleFullScreen(terminal)
}


;-------------------------------------------------------------------------------
; mode_switch keyboard layer
;-------------------------------------------------------------------------------
; App-aware page up/down
pageup() {
    if GetKeyState("Shift")
        SendInput +{PgUp}
    else if GetKeyState("Ctrl")
        SendInput ^{PgUp}
    else
        SendInput {PgUp}
    return
}

pagedown() {
    if GetKeyState("Shift")
        SendInput +{PgDn}
    else if GetKeyState("Ctrl")
        SendInput ^{PgDn}
    else
        SendInput {PgDn}
    return
}


;-------------------------------------------------------------------------------
; Audio
;-------------------------------------------------------------------------------
toggleSoundOutput() {
    global defaultAudioDevice, audioDevices 
    defaultAudioDevice++
    if (defaultAudioDevice > audioDevices.maxIndex())
        defaultAudioDevice := 1
    audioDevice := audioDevices[defaultAudioDevice]
    RunWait, nircmd/nircmd.exe setdefaultsounddevice "%audioDevice%"
    showNotification("Audio Output: " . audioDevice)
}


;-------------------------------------------------------------------------------
; Power management
;-------------------------------------------------------------------------------
turnOffDisplay() {
    Run, nircmd/nircmd.exe monitor off,, Hide
}

suspend() {
    Run, nircmd/nircmd.exe standby,, Hide
}


;-------------------------------------------------------------------------------
; Run
;-------------------------------------------------------------------------------
RunWaitOne(command) {
    ; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99¬
    shell := ComObjCreate("WScript.Shell")
    ; Execute a single command via cmd.exe
    exec := shell.exec(ComSpec " /C " command)
    ; exec := shell.Run(ComSpec " /C " command, 0, true) ; not able to retrieve result: https://autohotkey.com/boards/viewtopic.php?t=13257
    ; Read and return the command's output
    return exec.StdOut.ReadAll()
}

RunWaitMany(commands) {
    shell := ComObjCreate("WScript.Shell")
    ; Open cmd.exe with echoing of commands disabled
    exec := shell.Exec(ComSpec " /Q /K echo off")
    ; Send the commands to execute, separated by newline
    exec.StdIn.WriteLine(commands "`nexit")  ; Always exit at the end!
    ; Read and return the output of all commands
    return exec.StdOut.ReadAll()
}


;-------------------------------------------------------------------------------
; Hotkey management
;-------------------------------------------------------------------------------
notifyHotkeysSuspension() {
    ; Suspend, Toggle ; Suspend command must be at the first line of hotkey, not in function.
                      ; If in function, once suspended, hotkeys will not be toggled back anymore.
    if (!A_isSuspended) {
        ; showNotification("Autohotkey Enabled")
        Progress, off
    } else {
        ; showNotification("Autohotkey Disabled")
        Progress,% "b zh0 w100 h60 cwFFAAAA x" A_ScreenWidth-120 " y" A_ScreenHeight-100, Disabled, Autohotkey
    } 
    return
}
