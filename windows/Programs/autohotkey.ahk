;-------------------------------------------------------------------------------
; Use "KeyTweak" to bind:
; 1. caps lock to esc.
; 2. Right alt/control/menu to volume control
;
; Note:
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
; $: do not re-route back

; Rules:
; All hotkeys has "Esc + X" pattern
; Numpad is mapped to monitor and media control
;-------------------------------------------------------------------------------
; Preprocessor, configs and library (config can be used by library)
;-------------------------------------------------------------------------------
#SingleInstance force

; Improve performance: https://www.autohotkey.com/boards/viewtopic.php?t=6413
SendMode Input
#NoEnv ; https://www.autohotkey.com/docs/commands/_NoEnv.htm 
; #KeyHistory 0 ; https://www.autohotkey.com/docs/commands/KeyHistory.htm  Dual key will use key histroy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Default settings
; nightLightEnabled control brightness and color temperature of video/reading mode
nightLightEnabled := true

; brightness has memory effect, temperature/width/height are fixed. The code design preserve the flexibility for all to have memory effect though
monitorSettings := [{brightness: 20, temperature: "6500K", width: 3840, height: 2160}  ; for multimedia (video, photos)
                   ,{brightness:  5, temperature: "5000K", width: 2880, height: 2160}] ; for reading, browsing

; Apps
browser  := "chrome.exe"
terminal := "ubuntu.exe"
editor   := "gvim.exe"
ide      := "Code.exe"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load resource file to override default settings
#Include *i .autohotkeyrc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Library
#Include autohotkey/lib.ahk
; #Include autohotkey/dual.ahk
; #Include autohotkey/dual-defaults.ahk


;-------------------------------------------------------------------------------
; Welcome message (if put after hotkey definitions, notification won't trigger
;-------------------------------------------------------------------------------
showNotification("Autohotkey loaded")


;-------------------------------------------------------------------------------
; Basic
;-------------------------------------------------------------------------------
$Esc:: SendInput {Esc} ; if absent, standalone Esc cannot be used. Don't know why

!`:: closeApp()

; Reload autohotkey
!+r:: Run, cmd.exe /C autohotkey.ahk,, Hide


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; For TKL layout
Pause:: turnOffDisplay()
+Pause:: suspend()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; For Microsoft Designer Keyboard 
; 4 upper right keys
#F21:: turnOffDisplay()
^#F21:: suspend()
!#F21:: SendInput {PrintScreen}
^!#F21:: SendInput ^{PrintScreen}
; +#F21:: SendInput d

; Numpad
NumpadAdd:: SendInput {Esc}
NumpadSub:: SendInput {Volume_Up}
NumpadMult:: SendInput {Volume_Down}
; NumpadDiv:: 


;-------------------------------------------------------------------------------
; App/workspace switching
;-------------------------------------------------------------------------------
!1:: 
    if WinActive("ahk_exe " . browser)
        SendInput !{Tab}
    else
        winActivateExe(browser)
    return
!2:: 
    if WinActive("ahk_exe " . terminal)
        SendInput !{Tab}
    else
        winActivateExe(terminal, "", "run source wsl-init")
    return
!3:: ; file explorer 
    if WinExist("ahk_class CabinetWClass") {
        ; Cycle through file explorers
        GroupAdd, explorers, ahk_class CabinetWClass ;You have to make a new group for each application, don't use the same one for all of them!
        if WinActive("ahk_exe explorer.exe")
            GroupActivate, explorers, r
        else
            WinActivate ahk_class CabinetWClass ;you have to use WinActivatebottom if you didn't create a window group.
    } else {
        ; Run, d:\Downloads
        Run, explorer.exe
    }
    updateAppHistory()
    updateBrightness()
    return
; !4:: switchDesktopByNumber(4)

; Alt+Tab brightness adjustment based on app
; ~!Tab::
;     SetTimer, UpdateAppAndBrightness, 100
;     return
; UpdateAppAndBrightness:
;     if (GetKeyState("Alt")) ; if alt is not released, alt+tab operation is still ongoing
;         return
;     SetTimer,, off
;     updateAppHistory()
;     updateBrightness()
;     return

; Switch between workspace using hjkl
$^#h:: SendInput ^#{Left}
$^#l:: SendInput ^#{Right}


;-------------------------------------------------------------------------------
; mode_switch layer
;-------------------------------------------------------------------------------
; Typing assist
F5 & k::
    if !GetKeyState("Alt") 
        SendInput {Up}
    else
        SendInput {Media_Play_Pause}
    return
F5 & j::
    if !GetKeyState("Alt") 
        SendInput {Down}
    else
        SendInput {Media_Prev}
    return
F5 & h:: SendInput {Left}
F5 & l::
    if !GetKeyState("Alt") 
        SendInput {Right}
    else
        SendInput {Media_Next}
    return

F5 & e:: SendInput ^{Left}
F5 & r:: SendInput ^{Right}

F5 & m:: pagedown()
F5 & ,:: pageup()
F5 & f:: pagedown()
F5 & b:: pageup()

F5 & [:: SendInput {Home}
F5 & ]:: SendInput {End}

F5 & o:: SendInput {Backspace}
F5 & p:: ; delete one word
    if WinActive("ahk_exe " . terminal) or WinActive("ahk_exe " . editor) ; ctrl+w to delete one word only works in vim and terminal
		SendInput ^w
    else
        SendInput ^{Backspace}
    return
F5 & u:: ; delete whole line
    if WinActive("ahk_exe " . terminal) or WinActive("ahk_exe " . editor) ; ctrl+w to delete one word only works in vim and terminal
        SendInput ^u
    else {
        ; Does not work on all applications
        SendInput {End}^+{Backspace}
    }
    return
F5 & d:: SendInput {Del}

; Function keys
; F5 & 1:: SendInput {F1} ; Conflict with volume/brightness adjustments
; F5 & 2:: SendInput {F2} ; Conflict with volume/brightness adjustments
F5 & 3:: SendInput {F3}
F5 & 4:: SendInput {F4}
F5 & 5:: SendInput {F5}
F5 & 6:: SendInput {F6}
F5 & 7:: SendInput {F7}
F5 & 8:: SendInput {F8}
F5 & 9:: SendInput {F9}
F5 & 0:: SendInput {F10}
F5 & -:: SendInput {F11}
F5 & =:: SendInput {F12}


;-------------------------------------------------------------------------------
; Monitor control (brightness, night light, resolution)
;-------------------------------------------------------------------------------
; Brightness
; Numpad8::
F5 & 1::
    if !GetKeyState("Alt")
        SendInput {Volume_Down}
    else
        decreaseBrightness()
    return

; Numpad9::
F5 & 2::
    if !GetKeyState("Alt")
        SendInput {Volume_Up}
    else
        increaseBrightness()
    return

; Brightness and night light
; Numpad0::
F5 & `:: ; "d"isplay mode
    if !GetKeyState("Alt")
        SendInput {Volume_Mute}
    else
        toggleBrightnessMode()
    return

; Resolution
; NumpadDot::
!r::
    if (A_ScreenWidth = monitorSettings[1].width)
        setResolution(monitorSettings[2].width, monitorSettings[2].height)
    else
        setResolution(monitorSettings[1].width, monitorSettings[1].height)
    return


;-------------------------------------------------------------------------------
; Mouse proxies (not directly be used, but used by mouse key bindings)
;-------------------------------------------------------------------------------
; Razer Basilisk
Xbutton1:: ; Close tab/window
    if WinActive("ahk_exe " . browser)
        SendInput ^w
    else
        closeApp()
    return

Xbutton2:: ; New tab/window
    if WinActive("ahk_exe explorer.exe")
        Run, explorer.exe
    else
        SendInput ^t
    return

F22::
    if WinActive("ahk_exe " . browser) or WinActive("ahk_exe " . terminal)
        SendInput ^b
    else
        SendInput {PgUp}
    return
F23::
    if WinActive("ahk_exe " . browser) or WinActive("ahk_exe " . terminal)
        SendInput ^f
    else
        SendInput {PgDn}
    return

$F17 Up:: SendInput !{Left}

; Holding back button
F17 & WheelDown:: SendInput {Volume_Down}
F17 & WheelUp::   SendInput {Volume_Up}

F17 & LButton:: decreaseBrightness()
F17 & RButton:: increaseBrightness()
F17 & MButton:: toggleBrightnessMode()

; Holding back button + hypershift
F17 & F22:: SendInput {Home}
F17 & F23:: SendInput {End}

F17 & PgDn:: SendInput W ; Move tab right
F17 & PgUp:: SendInput Q ; Move tab left

F17 & XButton2:: SendInput ^r ; Reload
F17 & Esc::  SendInput E ; Detach webpage


;-------------------------------------------------------------------------------
; Dual mode keys (like Linux's xcape)
; https://autohotkey.com/board/topic/103174-dual-function-control-key/
;-------------------------------------------------------------------------------
; CapsLock: Esc
$LControl:: SendInput {LCtrl down}
$LControl Up::
    if (A_PriorKey = "LControl")
        SendInput {LControl Up}{Esc}
    else
        SendInput {LControl Up}
    return

; LAlt: Alt+Tab
$LAlt:: SendInput {LAlt down}
$LAlt Up::
    if (A_PriorKey = "LAlt")
        SendInput {Tab}{LAlt Up}
    else
        SendInput {LAlt Up}
    return

; RAlt: Toggle input method
$RAlt:: SendInput {RAlt down}
$RAlt Up::
    if (A_PriorKey = "RAlt") {
        SendInput {RAlt Up}#{Space}
        SetTimer, LShift, 150 ; There is a delay for Windows to trigger input method. Use set timer to wait for that trigger to complete.
    } else
        SendInput {RAlt Up}
    return
    LShift:
        SendInput {LShift}
        SetTimer,, off
        return


;-------------------------------------------------------------------------------
; Legacy
;-------------------------------------------------------------------------------
; Quake-like trigger for WSL Terminal
; Esc & '::
;     if WinActive("ahk_exe " . terminal)
; 		switchDesktopAndUpdateApp(1)
;     else
;         winActivateExe(terminal, "", "", 2)
; 	return

; Numpad7:: Send f

; Numpad4::
; 	SetTitleMatchMode, 2 ; partial match window title
;     if WinActive("ahk_exe mpc-hc64.exe") or WinActive("YouTube")
; 		Send j 
;     else
; 		Send {Media_Prev}
; 	return

; Numpad5::
; 	SetTitleMatchMode, 2 ; partial match window title
;     if WinActive("ahk_exe mpc-hc64.exe") or WinActive("YouTube")
; 		Send k 
;     else
; 		Send {Media_Play_Pause}
; 	return

; Numpad6::
; 	SetTitleMatchMode, 2 ; partial match window title
;     if WinActive("ahk_exe mpc-hc64.exe") or WinActive("YouTube")
; 		Send l 
;     else
; 		Send {Media_Next}
; 	return
