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
; Preprocessor and configs (some used by libraries)
;-------------------------------------------------------------------------------
#SingleInstance force

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Default settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; nightLightEnabled control brightness and color temperature of video/reading mode
nightLightEnabled := true

; brightness has memory effect, temperature/width/height are fixed. The code design preserve the flexibility for all to have memory effect though
monitorSettings := [{brightness: 20, temperature: "6500K", width: 3840, height: 2160}  ; for full screen video
                   ,{brightness:  5, temperature: "5000K", width: 2880, height: 2160}  ; for centered reading
                   ,{brightness:  5, temperature: "5000K", width: 2880, height: 2160}] ; for centered reading using dark theme apps (e.g. terminal/vscode)

; Apps
browser  := "chrome.exe"
terminal := "ubuntu.exe"
editor   := "gvim.exe"
ide      := "Code.exe"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load resource file to override default settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#Include *i .autohotkeyrc


;-------------------------------------------------------------------------------
; Library
;-------------------------------------------------------------------------------
#Include autohotkey/lib.ahk


;-------------------------------------------------------------------------------
; Welcome message (if put after hotkey definitions, notification won't trigger
;-------------------------------------------------------------------------------
showNotification("Autohotkey loaded")


;-------------------------------------------------------------------------------
; Basic
;-------------------------------------------------------------------------------
Esc:: Send {Esc} ; if absent, standalone Esc cannot be used. Don't know why

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

; Close app
!`:: 
    if WinActive("ahk_exe " . terminal) {
        showNotification(terminal . " does not support closing by keyboard shortcut")
        ; While WinActive("ahk_exe " . terminal) {
        ;     Send ^d
        ;     Sleep, 30
        ; }
    } else
        Send !{F4}
    return


;-------------------------------------------------------------------------------
; App/workspace switching
;-------------------------------------------------------------------------------
; Function keys Key remap
$F1:: winActivateExe(browser)
; $F2:: winActivateExe(terminal, "", "", 2)
$F2:: winActivateExe(terminal, "", "run source wsl-init")
$F3:: ; file explorer
    if WinExist("ahk_class CabinetWClass") {
        ; Cycle through file explorers
        GroupAdd, explorers, ahk_class CabinetWClass ;You have to make a new group for each application, don't use the same one for all of them!
        if WinActive("ahk_exe explorer.exe")
            GroupActivate, explorers, r
        else
            WinActivate ahk_class CabinetWClass ;you have to use WinActivatebottom if you didn't create a window group.
    } else {
        ; switchDesktopByNumber(3)
        Run, d:\Downloads
    }
    updateAppHistory()
    updateBrightness()
    return
$F4:: switchDesktopByNumber(4)
$F5:: winActivateLast()

+F1:: Send {F1}
+F2:: Send {F2}
+F3:: Send {F3}
+F4:: Send {F4}
+F5:: Send {F5}

; Quake-like trigger for WSL Terminal
; Esc & '::
;     if WinActive("ahk_exe " . terminal)
; 		switchDesktopAndUpdateApp(1)
;     else
;         winActivateExe(terminal, "", "", 2)
; 	return

; Browser/VSCode toggle (not used anymore)
; Esc & `;:: ; "`" as escape character for semicolon
;     if (CurrentDesktop = 1) ; only toggle when current virtual desktop is 1
;         if WinActive("ahk_exe " . browser) and WinExist("ahk_exe Code.exe")
; 			winActivateExe("Code.exe", "C:\Users\Andy\AppData\Local\Programs\Microsoft VS Code")
;         else
; 			winActivateExe(browser)
;     else
;         switchDesktopAndUpdateApp(1)
;     return

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

; Remove built-in keyboard shortcuts for switching virtual desktop
^#Right::
^#Left:: return

!1:: switchDesktopByNumber(1)
!2:: switchDesktopByNumber(2)
!3:: switchDesktopByNumber(3)
!4:: switchDesktopByNumber(4)

; $^w::
;     if WinActive("ahk_exe " . browser) or WinActive("ahk_exe " . ide) ; ctrl+w to delete one word only works in vim and terminal
; 		Send ^w
;     else
;         Send !{F4}
;     return

;-------------------------------------------------------------------------------
; Typing assist
;-------------------------------------------------------------------------------
Esc & k:: Send {Up}
Esc & j:: Send {Down}
Esc & h:: Send ^{Left}
Esc & l:: Send ^{Right}

Esc & m:: Send {Left}
Esc & ,:: Send {Right}
Esc & n:: Send {Home}
Esc & .:: Send {End}

Esc & p:: ; delete one word
    if WinActive("ahk_exe " . terminal) or WinActive("ahk_exe " . editor) ; ctrl+w to delete one word only works in vim and terminal
		Send ^w
    else
        Send ^{Backspace}
    return
Esc & u:: Send ^u
Esc & o:: Send {Backspace}


;-------------------------------------------------------------------------------
; Monitor control (brightness, night light, resolution)
;-------------------------------------------------------------------------------
; Brightness
Esc & Volume_Up::
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
Esc & Volume_Down::
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
; Multimedia
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
; Forders (not actually used, only as a proxy by Logitech Option)
;-------------------------------------------------------------------------------
#!d::  Run, d:\Downloads ; does not remove due to Logitech Option binding which cannot bind Esc
