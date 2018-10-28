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
darkModeBrightnessMax := 15
darkModeBrightnessDelta := 7


;-------------------------------------------------------------------------------
; Shortcuts
;-------------------------------------------------------------------------------
; Key remap
F4:: Send {F1}
F1:: Send !{F4}
F2:: turnOffDisplay()
Numpad0:: Send {LWin}
AppsKey:: Send {Volume_Up 2}
Numpad3:: Send {Volume_Up 2}
; RCtrl::   Send {Volume_Up 2}
RAlt::  Send {Volume_Down 2}
Numpad2::  Send {Volume_Down 2}
Numpad5::  Reload
; For CapsLock->Esc, use KeyTweak instead. Support for mapping using autohotkey isn't perfect
; *CapsLock:: Send {Esc Down}
; *CapsLock Up:: Send {Esc Up}
Esc:: Send {Esc} ; if absent, standalone Esc cannot be used. Don't know why

; Remove Windows built-in keys
^#Right::
^#Left:: 
    return

#!Up::
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
#!Down::
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

; Night light
#!n::
Esc & n::
NumpadEnter::
    nightLightEnabled := !nightLightEnabled
    temperature := monitorSetting().temperature
    brightness  := monitorSetting().brightness
    setMonitorDdc("b " . brightness . " p " . temperature)
    return

; Resolution
#!r::
Esc & r::
NumpadAdd::
    if (A_ScreenWidth = monitorSettings[1].width)
        setResolution(monitorSettings[2].width, monitorSettings[2].height)
    else
        setResolution(monitorSettings[1].width, monitorSettings[1].height)
    return

; Multimedia
#!Right::
Esc & Right::
    Send {Media_Next}
    return
#!Left::
Esc & Left::
    Send {Media_Prev}
    return
#!Space::
Esc & Space::
    Send {Media_Play_Pause}
    return

; Quake-like trigger for WSL Terminal
; ^'::
Esc & '::
NumpadDot::
    if (CurrentDesktop = 2)
        switchDesktopByNumber(1)
    else
        switchDesktopByNumber(2)
    updateCurrentApp()
	updateBrightness()
	return

; Window management
; ^;:: ; Chrome/VSCode toggle
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

; Common folders
#!d::
Esc & d::
    Run, d:\Downloads
    return

; Copy/paste for terminal
Esc & v:: Send +{Ins}


