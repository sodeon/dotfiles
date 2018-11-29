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
; F1 and F4 are remapped since low number function keys are mostly useless


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
DesktopCount := 3 ; # of virtual desktop


; a set of monitor presets, indexed by names
; current monitor preset name
; application -> monitor preset mapping
; unmapped application uses current monitor preset
; userMonitorPreset := "reading"
; curMonitorPresetName := "reading"
; monitorPresets := {video  : {brightness: 20, temperature: "6500K"}
;                   ,reading: {brightness:  5, temperature: "5000K"}
;                   ,dark   : {brightness:  9, temperature: "5000K"}}
; monitorPreset() {
;     return monitorPresets[monitorPresetName]
; }
; appMonitorPreset := {wsl-terminal: "dark"
;                     ,vscode      : "dark"}

; when night light is disabled, brightness will be set to video   mode
; when night light is enabled , brightness will be set to reading mode
; nightLightEnabled control brightness and color temperature of video/reading mode
nightLightEnabled := true

; brightness has memory effect, temperature/width/height are fixed. The code design preserve the flexibility for all to have memory effect though
monitorSettings := [{brightness: 20, temperature: "6500K", width: 3840, height: 2160}  ; for full screen video
                   ,{brightness:  5, temperature: "5000K", width: 2880, height: 2160}  ; for centered reading
                   ,{brightness:  9, temperature: "5000K", width: 2880, height: 2160}] ; for centered reading using dark theme apps (e.g. terminal/vscode)

currentApp := "chrome" ; vscode/wsl-terminal: dark mode, any name other than previous two does not matter

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load resource file to override default settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#Include *i .autohotkeyrc


;-------------------------------------------------------------------------------
; Welcome message (if put after hotkey definitions, notification won't trigger
;-------------------------------------------------------------------------------
showNotification("Autohotkey loaded")


;-------------------------------------------------------------------------------
; Shortcuts - basic
;-------------------------------------------------------------------------------
; Remove built-in keyboard shortcuts
^#Right::
^#Left:: return ; change virtual desktop

; Basic Key remap
F4:: Send {F1}
F1:: Send !{F4}

; NumpadAdd:: Send {LWin} ; dot can be mapped to something else useful and meaningful
NumpadAdd:: Send {Esc}

; Numpad1::  Send {Volume_Mute}
Numpad2::  Send {Volume_Down}
Numpad3::  Send {Volume_Up}

NumpadSub:: turnOffDisplay() ; F2 is used for rename
NumpadMult:: Send {PrintScreen}
^NumpadMult:: Send ^{PrintScreen}

Esc:: Send {Esc} ; if absent, standalone Esc cannot be used. Don't know why

; Paste for terminal (does not map copy as wsl and windows clipboard is not linked)
Esc & v:: Send +{Ins}
Esc & Backspace:: Send ^{Backspace}
Esc & u:: Send ^u
Esc & w:: ; delete one word
Esc & p:: ; delete one word
    if WinActive("ahk_exe mintty.exe") ; ctrl+w to delete one word only works in vim and terminal
		Send ^w
    else
        Send ^{Backspace}
    return


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

; Night light / reading mode
Esc & n::
; NumpadEnter::
Numpad0::
    nightLightEnabled := !nightLightEnabled
    temperature := monitorSetting().temperature
    brightness  := monitorSetting().brightness
    setMonitorDdc("b " . brightness . " p " . temperature)
    showNotification("Brightness: " . brightness, (nightLightEnabled ? "Reading mode" : "Video mode"))
    return

; Resolution
Esc & r::
; NumpadAdd::
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
    if (CurrentDesktop = 2)
        switchDesktopByNumber(1)
    else {
        switchDesktopByNumber(2)
		WinActivate, ahk_exe mintty.exe
    }
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

Esc & 1:: switchDesktopByNumber(1)
Esc & 2:: switchDesktopByNumber(2)
Esc & 3:: switchDesktopByNumber(3)
Esc & 4:: switchDesktopByNumber(4)


;-------------------------------------------------------------------------------
; Shortcuts - forders (not actually used, only as a proxy by Logitech Option)
;-------------------------------------------------------------------------------
#!d::  Run, d:\Downloads ; does not remove due to Logitech Option binding which cannot bind Esc
; Esc & d:: Run, d:\Downloads
