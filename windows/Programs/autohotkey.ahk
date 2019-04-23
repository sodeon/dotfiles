;-------------------------------------------------------------------------------
; Note
;-------------------------------------------------------------------------------
; NOT free form language
; Breaking into multi-line has restrictions
; string concat using "." must have space before and after

; Key modifiers
; ^: ctrl
; #: win
; !: alt
; +: shift
; *: (wildcard) even if other modifiers are pressed, ignore them
; ~: send also original key

; Rules:
; All hotkeys has "Esc + X" pattern
; Numpad is mapped to monitor and media control
; F1~F5 are used for app switching


;-------------------------------------------------------------------------------
; Preprocessor 
;-------------------------------------------------------------------------------
#SingleInstance force
#Include autohotkey/lib.ahk


;-------------------------------------------------------------------------------
; Config variables (some used by libraries)
;-------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Default settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; nightLightEnabled control brightness and color temperature of video/reading mode
nightLightEnabled := true

; brightness has memory effect, temperature/width/height are fixed. The code design preserve the flexibility for all to have memory effect though
monitorSettings := [{brightness: 20, temperature: "6500K", width: 3840, height: 2160}  ; for full screen video
                   ,{brightness:  5, temperature: "5000K", width: 2880, height: 2160}  ; for centered reading
                   ,{brightness:  9, temperature: "5000K", width: 2880, height: 2160}] ; for centered reading using dark theme apps (e.g. terminal/vscode)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load resource file to override default settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#Include *i .autohotkeyrc


;-------------------------------------------------------------------------------
; Welcome message (if put after hotkey definitions, notification won't trigger
;-------------------------------------------------------------------------------
showNotification("Autohotkey loaded")


;-------------------------------------------------------------------------------
; Workarounds
;-------------------------------------------------------------------------------
Esc:: Send {Esc} ; if absent, standalone Esc cannot be used. Don't know why


;-------------------------------------------------------------------------------
; Shortcuts - basic
;-------------------------------------------------------------------------------
; Remove built-in keyboard shortcuts
^#Right::
^#Left:: return ; change virtual desktop

; Function keys Key remap
F1:: winActivateExe("chrome.exe")
F2:: winActivateExe("mintty.exe", "", "", 2)
; F3:: winActivateExe("d:\Downloads", "", "", 3) ; explorer.exe always exists regardless of whether there are any opened explorer window
F3::
	switchDesktopByNumber(3)
    if WinExist("ahk_class CabinetWClass") { ; explorer file manager
        ; WinActivate, ahk_class CabinetWClass ; Does not put explorer to front as you might open a video from explorer
    } else
        Run, d:\Downloads
    updateAppHistory()
    updateBrightness()
    return
F4:: winActivateExe("firefox.exe", "C:\Program Files\Mozilla Firefox")
F5:: winActivateLast()
; F5:: winActivateExe("Code.exe", "C:\Users\Andy\AppData\Local\Programs\Microsoft VS Code")

; Pause/ScrollLock
Pause:: turnOffDisplay()
; ScrollLock::

; Numpad
NumpadAdd:: Send {Esc}
Numpad2::  Send {Volume_Down}
Numpad3::  Send {Volume_Up}
NumpadSub:: turnOffDisplay()
NumpadMult:: Send {PrintScreen}
^NumpadMult:: Send ^{PrintScreen}

Esc & v:: Send +{Ins} ; Paste for terminal (does not map copy as wsl and windows clipboard is not linked)
Esc & u:: Send ^u
Esc & p:: ; delete one word
    if WinActive("ahk_exe mintty.exe") or WinActive("ahk_exe gvim.exe") ; ctrl+w to delete one word only works in vim and terminal
		Send ^w
    else
        Send ^{Backspace}
    return

!`:: Send !{F4} ; unify vscode and other app's closing shortcuts


;-------------------------------------------------------------------------------
; Shortcuts - Monitor control (brightness, night light, resolution)
;-------------------------------------------------------------------------------
; Brightness
Esc & Up::
Numpad9::
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
    return
Esc & Down::
Numpad8::
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
    return

; Brightness and night light
Esc & b::
Numpad0::
    nightLightEnabled := !nightLightEnabled
    temperature := monitorSetting().temperature
    brightness  := monitorSetting().brightness
    setMonitorDdc("b " . brightness . " p " . temperature)
    showNotification("Brightness: " . brightness, (nightLightEnabled ? "Reading mode" : "Video mode"))
    return

; Resolution
Esc & r::
NumpadDot::
    if (A_ScreenWidth = monitorSettings[1].width)
        setResolution(monitorSettings[2].width, monitorSettings[2].height)
    else
        setResolution(monitorSettings[1].width, monitorSettings[1].height)
    return


;-------------------------------------------------------------------------------
; Shortcuts - Multimedia
;-------------------------------------------------------------------------------
Numpad7:: Send f

Esc & Left::
Numpad4::
	SetTitleMatchMode, 2 ; partial match window title
    if WinActive("ahk_exe mpc-hc64.exe") or WinActive("YouTube")
		Send j 
    else
		Send {Media_Prev}
	return

Esc & Space::
Numpad5::
	SetTitleMatchMode, 2 ; partial match window title
    if WinActive("ahk_exe mpc-hc64.exe") or WinActive("YouTube")
		Send k 
    else
		Send {Media_Play_Pause}
	return

Esc & Right::
Numpad6::
	SetTitleMatchMode, 2 ; partial match window title
    if WinActive("ahk_exe mpc-hc64.exe") or WinActive("YouTube")
		Send l 
    else
		Send {Media_Next}
	return


;-------------------------------------------------------------------------------
; Shortcuts - Window management
;-------------------------------------------------------------------------------
; Quake-like trigger for WSL Terminal
Esc & '::
    if WinActive("ahk_exe mintty.exe")
		switchDesktopAndUpdateApp(1)
    else
        winActivateExe("mintty.exe", "", "", 2)
	return

; Chrome/VSCode toggle (not used anymore)
Esc & `;:: ; "`" as escape character for semicolon
    if (CurrentDesktop = 1) ; only toggle when current virtual desktop is 1
        if WinActive("ahk_exe chrome.exe") and WinExist("ahk_exe Code.exe")
			winActivateExe("Code.exe", "C:\Users\Andy\AppData\Local\Programs\Microsoft VS Code")
        else
			winActivateExe("chrome.exe")
    else
        switchDesktopAndUpdateApp(1)
    return

; Alt+Tab brightness adjustment based on app
~!Tab::
    SetTimer, UpdateAppAndBrightness, 100
    return
UpdateAppAndBrightness:
    if (GetKeyState("Alt")) ; if alt is not released, alt+tab operation is still ongoing
        return
    SetTimer, UpdateAppAndBrightness, OFF
    updateAppHistory()
    updateBrightness()
    return

Esc & 1:: switchDesktopByNumber(1)
Esc & 2:: switchDesktopByNumber(2)
Esc & 3:: switchDesktopByNumber(3)
Esc & 4:: switchDesktopByNumber(4)


;-------------------------------------------------------------------------------
; Shortcuts - forders (not actually used, only as a proxy by Logitech Option)
;-------------------------------------------------------------------------------
#!d::  Run, d:\Downloads ; does not remove due to Logitech Option binding which cannot bind Esc
