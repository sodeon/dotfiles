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

    if WinExist("ahk_exe" exe)
        WinActivate, ahk_exe %exe%
    else {
        if (CurrentDesktop != dstDesktop)
            switchDesktopByNumber(dstDesktop)

        fullExe := exe
        if (exePath != "")
            fullExe := exePath "\" fullExe
        ; if (params != "")
        ;     fullExe .= " " params
        fullExe := """" fullExe """" ; enclosing command with quotations
        Run, %fullExe% %params%
    }

    updateAppHistory()
    updateBrightness()
    return
}

; Activate the last window, including virtual desktop
winActivateLast() {
    global PreviousApp

    ; WinActivate will take care virtual desktop number
    WinActivate, ahk_id %PreviousApp%

    updateAppHistory()
    updateBrightness()
    return
}

switchDesktopAndUpdateApp(targetDesktop) {
    switchDesktopByNumber(targetDesktop)
    updateAppHistory()
	updateBrightness()
}

closeApp() {
    global terminal
    if WinActive("ahk_exe " . terminal)
        showNotification(terminal . " does not support closing by keyboard shortcut")
    else
        SendInput !{F4}
}


;-------------------------------------------------------------------------------
; Window snapping
; https://gist.github.com/AWMooreCO/1ef708055a11862ca9dc
;-------------------------------------------------------------------------------
/**
 * SnapActiveWindow resizes and moves (snaps) the active window to a given position.
 * @param {string} winPlaceVertical   The vertical placement of the active window.
 *                                    Expecting "bottom" or "middle", otherwise assumes
 *                                    "top" placement.
 * @param {string} winPlaceHorizontal The horizontal placement of the active window.
 *                                    Expecting "left" or "right", otherwise assumes
 *                                    window should span the "full" width of the monitor.
 * @param {string} winSizeHeight      The height of the active window in relation to
 *                                    the active monitor's height. Expecting "half" size,
 *                                    otherwise will resize window to a "third".
 */
; SnapActiveWindow(winPlaceVertical, winPlaceHorizontal, winSizeHeight, activeMon := 0) {
;     WinGet activeWin, ID, A
; 	SysGet, MonitorCount, MonitorCount
; 	
;     if (!activeMon) {
; 		activeMon := GetMonitorIndexFromWindow(activeWin)
; 	} else if (activeMon > MonitorCount) {
; 		activeMon := 1
; 	}
; 	
;     SysGet, MonitorWorkArea, MonitorWorkArea, %activeMon%
; 	
;     if (winSizeHeight == "full") {
;         height := (MonitorWorkAreaBottom - MonitorWorkAreaTop)
;     } else if (winSizeHeight == "half") {
;         height := (MonitorWorkAreaBottom - MonitorWorkAreaTop)/2
;     } else if (winSizeHeight == "third") {
;         height := (MonitorWorkAreaBottom - MonitorWorkAreaTop)/3
;     } else {
; 		height := (MonitorWorkAreaBottom - MonitorWorkAreaTop)
; 	}
;     if (winPlaceHorizontal == "left") {
;         posX  := MonitorWorkAreaLeft
;         width := (MonitorWorkAreaRight - MonitorWorkAreaLeft)/2
;     } else if (winPlaceHorizontal == "right") {
;         posX  := MonitorWorkAreaLeft + (MonitorWorkAreaRight - MonitorWorkAreaLeft)/2
;         width := (MonitorWorkAreaRight - MonitorWorkAreaLeft)/2
;     } else {
;         posX  := MonitorWorkAreaLeft
;         width := MonitorWorkAreaRight - MonitorWorkAreaLeft
;     }
;     if (winPlaceVertical == "bottom") {
;         posY := MonitorWorkAreaBottom - height
;     } else if (winPlaceVertical == "middle") {
;         posY := MonitorWorkAreaTop + height
;     } else {
;         posY := MonitorWorkAreaTop
;     }
; 	
; 	; Rounding
; 	posX := floor(posX)
; 	posY := floor(posY)
; 	width := floor(width)
; 	height := floor(height)
; 	
; 	; Borders (Windows 10)
; 	SysGet, BorderX, 32
; 	SysGet, BorderY, 33
; 	if (BorderX) {
; 		posX := posX - BorderX
; 		width := width + (BorderX * 2)
; 	}
; 	if (BorderY) {
; 		height := height + BorderY
; 	}
; 	
; 	; If window is already there move to same spot on next monitor
; 	WinGetPos, curPosX, curPosY, curWidth, curHeight, A
; 	if ((posX = curPosX) && (posY = curPosY) && (width = curWidth) && (height = curHeight)) {
; 		activeMon := activeMon + 1
; 		SnapActiveWindow(winPlaceVertical, winPlaceHorizontal, winSizeHeight, activeMon)
; 	} else {
; 		WinMove,A,,%posX%,%posY%,%width%,%height%
; 	}
; }

/**
 * GetMonitorIndexFromWindow retrieves the HWND (unique ID) of a given window.
 * @param {Uint} windowHandle
 * @author shinywong
 * @link http://www.autohotkey.com/board/topic/69464-how-to-determine-a-window-is-in-which-monitor/?p=440355
 */
; GetMonitorIndexFromWindow(windowHandle) {
;     ; Starts with 1.
;     monitorIndex := 1
;     VarSetCapacity(monitorInfo, 40)
;     NumPut(40, monitorInfo)
;     if (monitorHandle := DllCall("MonitorFromWindow", "uint", windowHandle, "uint", 0x2))
;         && DllCall("GetMonitorInfo", "uint", monitorHandle, "uint", &monitorInfo) {
;         monitorLeft   := NumGet(monitorInfo,  4, "Int")
;         monitorTop    := NumGet(monitorInfo,  8, "Int")
;         monitorRight  := NumGet(monitorInfo, 12, "Int")
;         monitorBottom := NumGet(monitorInfo, 16, "Int")
;         workLeft      := NumGet(monitorInfo, 20, "Int")
;         workTop       := NumGet(monitorInfo, 24, "Int")
;         workRight     := NumGet(monitorInfo, 28, "Int")
;         workBottom    := NumGet(monitorInfo, 32, "Int")
;         isPrimary     := NumGet(monitorInfo, 36, "Int") & 1
;         SysGet, monitorCount, MonitorCount
;         Loop, %monitorCount% {
;             SysGet, tempMon, Monitor, %A_Index%
;             ; Compare location to determine the monitor index.
;             if ((monitorLeft = tempMonLeft) and (monitorTop = tempMonTop)
;                 and (monitorRight = tempMonRight) and (monitorBottom = tempMonBottom)) {
;                 monitorIndex := A_Index
;                 break
;             }
;         }
;     }
;     return %monitorIndex%
; }


;-------------------------------------------------------------------------------
; mode_switch keyboard layer
;-------------------------------------------------------------------------------
pageup() {
    If GetKeyState("Shift")
        SendInput +{PgUp}
    Else If GetKeyState("Ctrl")
        SendInput ^{PgUp}
    Else
        SendInput {PgUp}
    return
}

pagedown() {
    If GetKeyState("Shift")
        SendInput +{PgDn}
    Else If GetKeyState("Ctrl")
        SendInput ^{PgDn}
    Else
        SendInput {PgDn}
    return
}


;-------------------------------------------------------------------------------
; Brightness, night light, resolution
;-------------------------------------------------------------------------------
updateAppHistory() {
    global CurrentApp, PreviousApp
    temp := CurrentApp ; if the same window is triggered twice, don't register it as PreviousApp
    WinGet, CurrentApp, ID, A ; get current active window ID
    if (temp != CurrentApp)
        PreviousApp := temp
}

; app aware monitor brightness/nightlight settings
monitorSetting() {
    global terminal, editor, ide, monitorSettings, nightLightEnabled
    WinGet, app, ProcessName, A
    if (app = terminal or app = editor or app = ide)
        return monitorSettings[3]
    else if (nightLightEnabled)
        return monitorSettings[2]
    else
        return monitorSettings[1]
}

updateBrightness() {
    global terminal, editor, ide, monitorSettings, nightLightEnabled
    WinGet, app, ProcessName, A
    if (app = terminal or app = editor or app = ide)
        brightness := monitorSettings[3].brightness
    else if (nightLightEnabled) ; normal reading mode
        brightness := monitorSettings[2].brightness
    else ; video mode
        brightness := monitorSettings[1].brightness
    setMonitorDdc("b " . brightness)
}

setMonitorDdc(ddc) {
    Run, ClickMonitorDDC/ClickMonitorDDC.exe %ddc%,, Hide
}


setResolution(width, height) {
    ; RunWait, ChangeScreenResolution.exe /w=%width% /h=%height% /f=60 /d=0,, Hide
    RunWait, nircmd/nircmd.exe setdisplay %width% %height% 32,, Hide
}

increaseBrightness() {
    global monitorSetting, nightLightEnabled
    setting := monitorSetting()
    brightness := setting.brightness
    if (brightness >= 100)
        return
    else if (brightness < 2)
        delta := 2 - brightness
    else if (brightness < 5)
        delta := 5 - brightness
    else
        delta := 5
    brightness += delta
    setMonitorDdc("b " . brightness)
    setting.brightness := brightness
    showNotification("Brightness: " . brightness)
}

decreaseBrightness() {
    global monitorSetting, nightLightEnabled
    setting := monitorSetting()
    brightness := setting.brightness
    if (brightness <= 0)
        return
    else if (brightness <= 2)
        delta := brightness
    else if (brightness <= 5)
        delta := brightness - 2
    else
        delta := 5
    brightness -= delta
    setMonitorDdc("b " . brightness)
    setting.brightness := brightness
    showNotification("Brightness: " . brightness)
}

toggleBrightnessMode() {
    global monitorSetting, nightLightEnabled
    nightLightEnabled := !nightLightEnabled
    temperature := monitorSetting().temperature
    brightness  := monitorSetting().brightness
    setMonitorDdc("b " . brightness . " p " . temperature)
    showNotification("Brightness: " . brightness, (nightLightEnabled ? "Reading mode" : "Video mode"))
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
; Virtual Desktop
;-------------------------------------------------------------------------------
; Globals
DesktopCount    := 4 ; Windows starts with 2 desktops at boot
CurrentDesktop  := 1 ; Desktop count is 1-indexed (Microsoft numbers them this way)
CurrentApp      := "" ; always update to date active window process ID
PreviousApp     := "" ; last active window process ID different from current one

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
       SendInput ^#{Right}
       CurrentDesktop++
       OutputDebug, [right] target: %targetDesktop% current: %CurrentDesktop%
   }
   ; Go left until we reach the desktop we want
   while(CurrentDesktop > targetDesktop) {
       SendInput ^#{Left}
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

updateAppHistory()
updateBrightness()


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


