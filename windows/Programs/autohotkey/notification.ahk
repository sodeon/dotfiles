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



