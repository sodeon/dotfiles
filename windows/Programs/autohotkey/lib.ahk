;-------------------------------------------------------------------------------
; Windows 10 notifications
;-------------------------------------------------------------------------------
; time: notification time in ms
; options: see TrayTip for definitions. Default: no sound
showNotification(text, title := "", time := 1000, options := 16) {
    _hideTrayTip()
    TrayTip, %title%, %text%,, options ; argument 3 does not matter in Windows 10
    ; Sleep, 100
}

_hideTrayTip() {
    if SubStr(A_OSVersion,1,3) = "10." {
        Menu Tray, NoIcon
        Sleep, 100  ; It may be necessary to adjust this sleep.
        Menu Tray, Icon
    } else {
        TrayTip  ; Attempt to hide it the normal way.
    }
}


;-------------------------------------------------------------------------------
; Window Switching
;-------------------------------------------------------------------------------
; Bring specified executable to focus. If the appis not launched, launch it
winActivateExe(exe, exePath = "", params = "", dstDesktop = 1) {
    global CurrentDesktop

    if (CurrentDesktop != dstDesktop)
        switchDesktopByNumber(dstDesktop)

    if WinExist("ahk_exe" exe)
        WinActivate, ahk_exe %exe%
    else {
        fullExe := exe
        if (exePath != "")
            fullExe := exePath "\" fullExe
        if (params != "")
            fullExe .= " " params
        fullExe := """" fullExe """" ; enclosing command with quotations
        Run, %fullExe%
    }

    updateCurrentApp()
    updateBrightness()
    return
}

; Activate the last window, including virtual desktop
winActivateLast() {
    global CurrentDesktop, PreviousAppDesktop, PreviousApp, CurrentApp

    if (CurrentDesktop != PreviousAppDesktop) {
        switchDesktopByNumber(PreviousAppDesktop)
        PreviousAppDesktop := CurrentDesktop
    }

    WinActivate, ahk_id %PreviousApp%

    updateCurrentApp()
    updateBrightness()
    return
}


;-------------------------------------------------------------------------------
; Brightness, night light, resolution
;-------------------------------------------------------------------------------
; NOTE: only recognize wsl-terminal and vscode for special brightness handling
updateCurrentApp() {
    global CurrentApp, PreviousApp
    temp := CurrentApp ; if the same window is triggered twice, don't register it as PreviousApp
    WinGet, CurrentApp, ID, A ; get current active window ID
    if (temp != CurrentApp)
        PreviousApp := temp
}

; app aware monitor brightness/nightlight settings
monitorSetting() {
    global monitorSettings, nightLightEnabled
    WinGet, app, ProcessName, A
    if (app = "mintty.exe" or app = "Code.exe")
        return monitorSettings[3]
    else if (nightLightEnabled)
        return monitorSettings[2]
    else
        return monitorSettings[1]
}

updateBrightness() {
    global monitorSettings, nightLightEnabled
    WinGet, app, ProcessName, A
    if (app = "mintty.exe" or app = "Code.exe")
        brightness := monitorSettings[3].brightness
    else if (nightLightEnabled) ; normal reading mode
        brightness := monitorSettings[2].brightness
    else ; video mode
        brightness := monitorSettings[1].brightness
    setMonitorDdc("b " . brightness)
}

setMonitorDdc(ddc) {
    Run, ClickMonitorDDC/ClickMonitorDDC_5_1.exe %ddc%,, Hide
}


setResolution(width, height) {
    RunWait, ChangeScreenResolution.exe /w=%width% /h=%height% /f=60 /d=0,, Hide
}

turnOffDisplay() {
    Run, nircmd/nircmd.exe monitor off,, Hide
}


;-------------------------------------------------------------------------------
; Virtual Desktop
;-------------------------------------------------------------------------------
; Globals
DesktopCount    := 3 ; Windows starts with 2 desktops at boot
CurrentDesktop  := 1 ; Desktop count is 1-indexed (Microsoft numbers them this way)
PreviousAppDesktop := CurrentDesktop
CurrentApp      := ""
PreviousApp     := ""

;
; This function examines the registry to build an accurate list of the current virtual desktops and which one we're currently on.
; Current desktop UUID appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\1\VirtualDesktops
; List of desktops appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops
;
mapDesktopsFromRegistry() {
   global CurrentDesktop, DesktopCount
   ; Get the current desktop UUID. Length should be 32 always, but there's no guarantee this couldn't change in a later Windows release so we check.
   IdLength := 32
   SessionId := getSessionId()
   if (SessionId) {
       RegRead, CurrentDesktopId, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%SessionId%\VirtualDesktops, CurrentVirtualDesktop
       if (CurrentDesktopId) {
           IdLength := StrLen(CurrentDesktopId)
       }
   }
   ; Get a list of the UUIDs for all virtual desktops on the system
   RegRead, DesktopList, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
   if (DesktopList) {
       DesktopListLength := StrLen(DesktopList)
       ; Figure out how many virtual desktops there are
       DesktopCount := DesktopListLength / IdLength
   }
   else {
       DesktopCount := 1
   }
   ; Parse the REG_DATA string that stores the array of UUID's for virtual desktops in the registry.
   i := 0
   while (CurrentDesktopId and i < DesktopCount) {
       StartPos := (i * IdLength) + 1
       DesktopIter := SubStr(DesktopList, StartPos, IdLength)
       OutputDebug, The iterator is pointing at %DesktopIter% and count is %i%.
       ; Break out if we find a match in the list. If we didn't find anything, keep the
       ; old guess and pray we're still correct :-D.
       if (DesktopIter = CurrentDesktopId) {
           CurrentDesktop := i + 1
           OutputDebug, Current desktop number is %CurrentDesktop% with an ID of %DesktopIter%.
           break
       }
       i++
   }
}
;
; This functions finds out ID of current session.
;
getSessionId() {
   ProcessId := DllCall("GetCurrentProcessId", "UInt")
   if ErrorLevel {
   OutputDebug, Error getting current process id: %ErrorLevel%
   return
   }
   OutputDebug, Current Process Id: %ProcessId%
   DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
   if ErrorLevel {
   OutputDebug, Error getting session id: %ErrorLevel%
   return
   }
   OutputDebug, Current Session Id: %SessionId%
   return SessionId
}
;
; This function switches to the desktop number provided.
;
switchDesktopByNumber(targetDesktop) {
   global CurrentDesktop, DesktopCount
   ; Re-generate the list of desktops and where we fit in that. We do this because
   ; the user may have switched desktops via some other means than the script.
   mapDesktopsFromRegistry()
   ; Don't attempt to switch to an invalid desktop
   if (targetDesktop > DesktopCount || targetDesktop < 1) {
       OutputDebug, [invalid] target: %targetDesktop% current: %CurrentDesktop%
       return
   }
   ; Go right until we reach the desktop we want
   while(CurrentDesktop < targetDesktop) {
       Send ^#{Right}
       CurrentDesktop++
       OutputDebug, [right] target: %targetDesktop% current: %CurrentDesktop%
   }
   ; Go left until we reach the desktop we want
   while(CurrentDesktop > targetDesktop) {
       Send ^#{Left}
       CurrentDesktop--
       OutputDebug, [left] target: %targetDesktop% current: %CurrentDesktop%
   }
}
;
; This function creates a new virtual desktop and switches to it
;
createVirtualDesktop() {
   global CurrentDesktop, DesktopCount
   Send, #^d
   DesktopCount++
   CurrentDesktop = %DesktopCount%
   OutputDebug, [create] desktops: %DesktopCount% current: %CurrentDesktop%
}
;
; This function deletes the current virtual desktop
;
deleteVirtualDesktop()
{
    global CurrentDesktop, DesktopCount
    Send, #^{F4}
    DesktopCount--
    CurrentDesktop--
    OutputDebug, [delete] desktops: %DesktopCount% current: %CurrentDesktop%
}
; Main
SetKeyDelay, 75
mapDesktopsFromRegistry()

updateCurrentApp()


;-------------------------------------------------------------------------------
; Legacy, not used
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


