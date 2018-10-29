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


;-------------------------------------------------------------------------------
; Preprocessor 
;-------------------------------------------------------------------------------
#SingleInstance force
#Include autohotkey\lib.ahk


;-------------------------------------------------------------------------------
; Config variables
;-------------------------------------------------------------------------------
DesktopCount := 2 ; # of virtual desktop

; when night light is disabled, brightness will be set to video   mode
; when night light is enabled , brightness will be set to reading mode
; nightLightEnabled control brightness and color temperature of video/reading mode
nightLightEnabled := true

; brightness has memory effect, temperature/width/height are fixed. The code design preserve the flexibility for all to have memory effect though
monitorSettings := [{brightness: 20, temperature: "6500K", width: 3840, height: 2160}  ; for full screen video
                   ,{brightness:  5, temperature: "5000K", width: 2880, height: 2160}  ; for centered reading
                   ,{brightness:  9, temperature: "5000K", width: 2880, height: 2160}] ; for centered reading using dark theme apps (e.g. terminal/vscode)

currentApp := "chrome" ; vscode/wsl-terminal: dark mode


;-------------------------------------------------------------------------------
; Shortcuts - basic
;-------------------------------------------------------------------------------
; Remove built-in keyboard shortcuts
^#Right::
^#Left:: return ; change virtual desktop

; Basic Key remap
F4:: Send {F1}
F1:: Send !{F4}
F3:: turnOffDisplay() ; F2 is used for rename
Numpad0::
NumpadDot:: Send {LWin}
Numpad1::  Send {Volume_Mute}
Numpad2::  Send {Volume_Down}
Numpad3::  Send {Volume_Up}
Esc:: Send {Esc} ; if absent, standalone Esc cannot be used. Don't know why

; Copy/paste for terminal
Esc & v:: Send +{Ins}


;-------------------------------------------------------------------------------
; Shortcuts - Monitor control (brightness, night light, resolution)
;-------------------------------------------------------------------------------
; Brightness
Esc & Up::
NumpadSub::
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
    setMonitorDdc("b " . (brightness + delta))
    setting.brightness += delta
    return
Esc & Down::
NumpadMult::
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
    setMonitorDdc("b " . (brightness - delta))
    setting.brightness -= delta
    return

; Night light / reading mode
Esc & n::
NumpadEnter::
    nightLightEnabled := !nightLightEnabled
    temperature := monitorSetting().temperature
    brightness  := monitorSetting().brightness
    setMonitorDdc("b " . brightness . " p " . temperature)
    return

; Resolution
Esc & r::
NumpadAdd::
    if (A_ScreenWidth = monitorSettings[1].width)
        setResolution(monitorSettings[2].width, monitorSettings[2].height)
    else
        setResolution(monitorSettings[1].width, monitorSettings[1].height)
    return


;-------------------------------------------------------------------------------
; Shortcuts - Multimedia
;-------------------------------------------------------------------------------
Esc & Right:: Send {Media_Next}
Esc & Left::  Send {Media_Prev}
Esc & Space:: Send {Media_Play_Pause}
Numpad4::
	SetTitleMatchMode, 2 ; partial match window title
	IfWinActive, YouTube
		Send j 
    else
		Send {Media_Prev}
	return
Numpad5::
	SetTitleMatchMode, 2 ; partial match window title
	IfWinActive, YouTube
		Send k 
    else
		Send {Media_Play_Pause}
	return
Numpad6::
	SetTitleMatchMode, 2 ; partial match window title
	IfWinActive, YouTube
		Send l 
    else
		Send {Media_Next}
	return


;-------------------------------------------------------------------------------
; Shortcuts - Window management
;-------------------------------------------------------------------------------
; Quake-like trigger for WSL Terminal
Esc & '::
    if (CurrentDesktop = 2)
        switchDesktopByNumber(1)
    else
        switchDesktopByNumber(2)
    updateCurrentApp()
	updateBrightness()
	return

; Chrome/VSCode toggle
Esc & `;:: ; "`" as escape character for semicolon
    if (CurrentDesktop = 1) ; only toggle when current virtual desktop is 1
        if WinActive("ahk_exe chrome.exe") and WinExist("ahk_exe Code.exe")
            WinActivate, ahk_exe Code.exe
        else
            WinActivate, ahk_exe chrome.exe
    else
        switchDesktopByNumber(1)
    updateCurrentApp()
    updateBrightness()
    return

; Alt+Tab brightness adjustment based on app
~!Tab::
    SetTimer, UpdateAppAndBrightness, 100
    return
UpdateAppAndBrightness:
    if (GetKeyState("Alt")) ; if alt is not released, alt+tab operation is still ongoing
        return
    SetTimer, UpdateAppAndBrightness, OFF
    updateCurrentApp()
    updateBrightness()
    return


;-------------------------------------------------------------------------------
; Shortcuts - forders (not actually used, only as a proxy by Logitech Option)
;-------------------------------------------------------------------------------
#!d::  Run, d:\Downloads ; does not remove due to Logitech Option binding which cannot bind Esc
; Esc & d:: Run, d:\Downloads
