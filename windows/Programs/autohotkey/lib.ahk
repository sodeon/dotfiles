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
; Brightness, night light, resolution
;-------------------------------------------------------------------------------
setResolution(width, height) {
    RunWait, ChangeScreenResolution.exe /w=%width% /h=%height% /f=60 /d=0,, Hide
}

; setBrightness(brightness) {
;     setMonitorDdc("b " . brightness)
; }

setDarkModeBrightness() {
    global darkModeBrightnessMax, darkModeBrightnessDelta
    brightness := Min(darkModeBrightnessMax, monitorSetting(true).brightness + darkModeBrightnessDelta)
    setMonitorDdc("b " . brightness)
}

setMonitorDdc(ddc) {
    Run, ClickMonitorDDC/ClickMonitorDDC_5_1.exe %ddc%,, Hide
}

; setNightLight(enable) {
;     ; Night light
;     ; https://superuser.com/questions/1200222/configure-windows-creators-update-night-light-via-registry
;     if enable
;         Run, powershell -Command ". .\Set-BlueLightReductionSettings.ps1; Set-BlueLightReductionSettings -StartHour 0 -StartMinutes 0 -EndHour 23 -EndMinutes 45 -Enabled $true  -NightColorTemperature 5700",, Hide
;     else
;         Run, powershell -Command ". .\Set-BlueLightReductionSettings.ps1; Set-BlueLightReductionSettings -StartHour 0 -StartMinutes 0 -EndHour 23 -EndMinutes 45 -Enabled $false -NightColorTemperature 5700",, Hide
; }

monitorSetting(isReadingMode) {
    global monitorSettings
    if (isReadingMode)
        return monitorSettings[2]
    else
        return monitorSettings[1]
}

curMonitorSetting() {
    global monitorSettings, nightLightEnabled
    return monitorSetting(nightLightEnabled)
}

turnOffDisplay() {
    Run, nircmd/nircmd.exe monitor off,, Hide
}


;-------------------------------------------------------------------------------
; Virtual Desktop
;-------------------------------------------------------------------------------
; Globals
DesktopCount = 2 ; Windows starts with 2 desktops at boot
CurrentDesktop = 1 ; Desktop count is 1-indexed (Microsoft numbers them this way)
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
; SetKeyDelay, 75
mapDesktopsFromRegistry()
