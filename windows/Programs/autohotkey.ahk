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

; Debug: Tooltip, showNotification(), Progress

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

SetTitleMatchMode, 2
#MaxHotkeysPerInterval 150 ; Dualkey detection requires this value to be high

SetWorkingDir %A_ScriptDir% ; Ensure consistent #Include behavior


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NOTICE: DO NOT MODIFY
; Default settings

; Display
displayMode = 1 ; 1: Reading, 2: Video, 3: Gaming
monitorSettings := [{brightness:  5, temperature: "5000K", contrast: 50, width: 2880, height: 2160, refreshRate: 60}  ; Reading, web browsing
                   ,{brightness: 20, temperature: "6500K", contrast: 50, width: 3840, height: 2160, refreshRate: 60}  ; Multimedia
                   ,{brightness: 50, temperature: "6500K", contrast: 50, width: 2880, height: 2160, refreshRate: 60}] ; Gaming

; Apps
browser  := "chrome.exe"
terminal := "ubuntu.exe"
editor   := "gvim.exe"
ide      := "Code.exe"

browserParams  := ""
terminalParams :=  "run source wsl-init"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load resource file to override default settings
#Include *i .autohotkeyrc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Library
#Include autohotkey/lib.ahk


;-------------------------------------------------------------------------------
; Init
;-------------------------------------------------------------------------------
setBrightnessMode(1)

initMouseShift(0, "F16")
initMouseShift(1, "F17")


;-------------------------------------------------------------------------------
; Welcome message (if put after hotkey definitions, notification won't trigger
;-------------------------------------------------------------------------------
showNotification("Autohotkey loaded")


;-------------------------------------------------------------------------------
; Basic
;-------------------------------------------------------------------------------
$Esc:: SendInput {Esc} ; if absent, standalone Esc cannot be used. Don't know why

!`::        WinClose, A
Alt & Esc:: WinClose, A

; Reload autohotkey (uses i3 reload shortcut)
!+r:: Run, cmd.exe /C autohotkey.ahk,, Hide


;-------------------------------------------------------------------------------
; App/workspace switching
;-------------------------------------------------------------------------------
!1:: 
    if WinActive("ahk_exe " . browser)
        SendInput !{Tab}
    else
        winActivateExe(browser, "", browserParams)
    return
!2:: 
    if WinActive("ahk_exe " . terminal)
        SendInput !{Tab}
    else
        winActivateExe(terminal, "", terminalParams)
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
    return
; !4:: switchDesktopByNumber(4)

; Snap window
$#h:: SendInput {Blind}{Left}
$#l:: SendInput {Blind}{Right}
$#j:: SendInput {Blind}{Down}
$#k:: SendInput {Blind}{Up}

; Switch workspace
$^#h:: SendInput {Blind}{Left}
$^#l:: SendInput {Blind}{Right}


;-------------------------------------------------------------------------------
; mode_switch layer
;-------------------------------------------------------------------------------
; Typing assist
Esc & k:: SendInput {Up}
Esc & j:: SendInput {Down}
Esc & h:: SendInput {Left}
Esc & l:: SendInput {Right}

Esc & w:: SendInput {Up}
Esc & a:: SendInput {Left}
Esc & s:: SendInput {Down}
Esc & d:: SendInput {Right}

Esc & e:: SendInput ^{Left}
Esc & r:: SendInput ^{Right}

Esc & m:: pagedown()
Esc & ,:: pageup()

Esc & `;:: SendInput {Home}
Esc & '::  SendInput {End}

Esc & o:: SendInput {Backspace}
Esc & p:: ; delete one word
    if WinActive("ahk_exe " . terminal) or WinActive("ahk_exe " . editor) ; ctrl+w to delete one word only works in vim and terminal
		SendInput ^w
    else
        SendInput ^{Backspace}
    return
Esc & u:: ; delete whole line
    if WinActive("ahk_exe " . terminal) or WinActive("ahk_exe " . editor) ; ctrl+w to delete one word only works in vim and terminal
        SendInput ^u
    else {
        ; Does not work on all applications
        SendInput {End}^+{Backspace}
    }
    return
Esc & i:: SendInput {Del}

; Function keys
Esc & 1:: SendInput {F1}
Esc & 2:: SendInput {F2}
Esc & 3:: SendInput {F3}
Esc & 4:: SendInput {F4}
Esc & 5:: SendInput {F5}
Esc & 6:: SendInput {F6}
Esc & 7:: SendInput {F7}
Esc & 8:: SendInput {F8}
Esc & 9:: SendInput {F9}
Esc & 0:: SendInput {F10}
Esc & -:: SendInput {F11}
Esc & =:: SendInput {F12}

Esc & Backspace:: SendInput {Del}

; Esc & \ Up:: SendInput {Pause}
Esc & ]:: SendInput {ScrollLock}
Esc & [:: SendInput {PrintScreen}

; CapsLock
Esc & Tab:: SetCapsLockState % !GetKeyState("CapsLock", "T")


;-------------------------------------------------------------------------------
; Monitor control (brightness, night light, resolution) 
; Media control
;-------------------------------------------------------------------------------
; Brightness
Esc & v::
    if !GetKeyState("Shift")
        SendInput {Volume_Down}
    else
        decreaseBrightness()
    return

Esc & f::
    if !GetKeyState("Shift")
        SendInput {Volume_Up}
    else
        increaseBrightness()
    return
+Volume_Down:: decreaseBrightness()
+Volume_Up:: increaseBrightness()

; Brightness and night light
Esc & g::
    if GetKeyState("Shift")
        toggleBrightnessMode()
    else if GetKeyState("Ctrl")
        toggleGameMode()
    else
        toggleSoundOutput()
    return

Esc & b:: SendInput {Volume_Mute}

; Resolution
!r::
    if (A_ScreenWidth = monitorSettings[1].width)
        setResolution(monitorSettings[2].width, monitorSettings[2].height, monitorSettings[2].refreshRate)
    else
        setResolution(monitorSettings[1].width, monitorSettings[1].height, monitorSettings[1].refreshRate)
    return

; Media control
Esc & Space:: SendInput {Media_Play_Pause}
Esc & Right:: SendInput {Media_Next}
Esc & Left::  SendInput {Media_Prev}
Esc & Down::  SendInput {Volume_Down}
Esc & Up::    SendInput {Volume_Up}


;-------------------------------------------------------------------------------
; Power
;-------------------------------------------------------------------------------
Pause:: turnOffDisplay()
+Pause:: suspend()


;-------------------------------------------------------------------------------
; Mouse proxies (not directly be used, but used by mouse key bindings)
;-------------------------------------------------------------------------------
; Logitech G602
; Thumb buttons
$F15:: SendInput #{Tab} ; G4 button
$F18:: SendInput !{Tab} ; G7 button

Xbutton1:: ; G5 button
    if (isMouseAlt()) {
        if (isMouseShift(0))
            SendInput ^+t ; Re-open closed tab
        else
            SendInput gU ; Go to top of the site
        toMouseNormal()
    } else if (isMouseShift(0) && isMouseShift(1))
        SendInput ^r ; Reload
    else if (isMouseShift(0))
        SendInput ^t ; New tab
    else if (isMouseShift(1))
        toggleBrightnessMode()
    else {
        if WinActive("ahk_exe " . browser)
            SendInput ^w
        else
            WinClose, A
    }
    return
$Xbutton2:: ; G6 button
    if (isMouseShift(0))
        SendInput {Left Down}
    else
        SendInput {Right Down}
    return
$Xbutton2 Up::
    if (isMouseShift(0))
        SendInput {Left Up}
    else
        SendInput {Right Up}
    return

; G9 button
~$F16:: 
    startDualKey()
    return
~$F16 Up::
    if (isDualKey("F16") && !hasMouseShifted(0) && !isMouseShift(1))
        toggleMouseAlt()
    resetMouseShift(0)
    return
; G8 button
~$F17:: 
    startDualKey()
    return
~$F17 Up::
    isDualKey := isDualKey("F17")
    if (isDualKey && isMouseAlt()) {
        SendInput !{Right}
        toMouseNormal()
    } else if (isDualKey && !hasMouseShifted(1) && !isMouseShift(0))
        SendInput !{Left}
    resetMouseShift(1)
    return

; Left/right/middle buttons
$LButton::
    if (isMouseAlt())
        SendInput ^-
    else if (isMouseShift(0) && isMouseShift(1))
        SendInput Q ; Move tab left
    else if (isMouseShift(0))
        SendInput ^{PgUp}
    else if (isMouseShift(1))
        decreaseBrightness()
    else
        SendInput {LButton Down}
    return
$LButton Up:: SendInput {LButton Up}
$RButton::
    if (isMouseAlt())
        SendInput ^{=}
    else if (isMouseShift(0) && isMouseShift(1))
        SendInput W ; Move tab left
    else if (isMouseShift(0))
        SendInput ^{PgDn}
    else if (isMouseShift(1))
        increaseBrightness()
    else
        SendInput {RButton}
    return
$MButton::
    if (isMouseShift(0))
        SendInput {Esc}
    else if (isMouseShift(1))
        toggleSoundOutput()
    else
        SendInput {MButton}
    return

; Scroll wheel
WheelDown::
    if (isMouseShift(0) && isMouseShift(1))
        SendInput {End}
    else if (isMouseShift(0)) {
        if WinActive("ahk_exe " . browser) or WinActive("ahk_exe " . terminal)
            SendInput ^f
        else
            SendInput {PgDn}
    } else if (isMouseShift(1))
        SendInput {Volume_Down}
    else if (isMouseAlt())
        SendInput {PgDn}
    else
        SendInput {WheelDown}
    return
WheelUp::
    if (isMouseShift(0) && isMouseShift(1))
        SendInput {Home}
    else if (isMouseShift(0)) {
        if WinActive("ahk_exe " . browser) or WinActive("ahk_exe " . terminal)
            SendInput ^b
        else
            SendInput {PgUp}
    } else if (isMouseShift(1))
        SendInput {Volume_Up}
    else if (isMouseAlt())
        SendInput {PgUp}
    else
        SendInput {WheelUp}
    return

; Upper left buttons
F13::
    if (isMouseAlt()) {
        ; Snap window to right
        ; 1. Window into maximized state. Step 2 will have consistent behavior only when window is maximized.
        ; 2. Double snap right using Windows's built-in function.
        WinMaximize, A
        SendInput #{Right 2}
        toMouseNormal()
    } else {
        ; Maximize window or toggle full screen mode if already maximized
        WinGet, maximized, MinMax, A
        if (!maximized)
            WinMaximize, A
        else if WinActive("ahk_exe " . browser) && (WinActive("YouTube") || WinActive("Twitch") || WinActive("bilibili") || WinActive("Netflix"))
            SendInput f
        else if WinActive("ahk_exe " . terminal)
            SendInput !{Enter}
        else
            SendInput {F11}
    }
    return
F14::
    if (isMouseAlt()) {
        if (isMouseShift(0))
            SendInput ^+t ; Re-open closed tab
        else
            SendInput gU ; Go to top of the site
        toMouseNormal()
    } else if (isMouseShift(0) && isMouseShift(1))
        SendInput ^r ; Reload
    else if (isMouseShift(0)) {
        if WinActive("ahk_exe " . browser)
            SendInput ^t ; New tab
        else
            SendInput ^n ; New window
    } else if (isMouseShift(1))
        toggleBrightnessMode()
    else {
        if WinActive("ahk_exe " . browser)
            SendInput e ; Detach/re-attach tab
        else
            SendInput #d
    }
    return


;-------------------------------------------------------------------------------
; Dual keys (same as Linux's xcape)
;-------------------------------------------------------------------------------
; LAlt: Alt+Tab
$LAlt:: 
    startDualKey()
    SendInput {LAlt down}
    return
$LAlt Up::
    if isDualKey("LAlt")
        SendInput {Tab}{LAlt Up}
    else
        SendInput {LAlt Up}
    return

; RAlt: Toggle input method
$RAlt:: 
    startDualKey()
    SendInput {RAlt down}
    return
$RAlt Up::
    if isDualKey("RAlt")
        SendInput {LAlt Down}{LShift}{LAlt Up}{RAlt Up} ; {RAlt Up} put to last. For unknown reason, putting it first can cause some control to lost input focus (e.g. jd.com).
    else
        SendInput {RAlt Up}
    return

; LCtrl: Send command to background (terminal); Undo (other programs)
$LCtrl:: 
    startDualKey()
    SendInput {LCtrl down}
    return

$LCtrl Up::
    if isDualKey("LControl") ; Cannot use LCtrl. LCtrl is a shorthand for sending inputs, A_PriorKey will only use LControl
        SendInput z{LCtrl Up}
    else
        SendInput {LCtrl Up}
    return

