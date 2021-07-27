;-------------------------------------------------------------------------------
; Alt and shift mouse mode
;-------------------------------------------------------------------------------
; Alt
_mouseAltMode = 0

isMouseAlt() {
    global _mouseAltMode
    return _mouseAltMode 
}

toMouseAlt() {
    global _mouseAltMode
    _mouseAltMode := 1
    Progress,% "b zh0 w100 h60 cwFFAAAA x" A_ScreenWidth-120 " y" A_ScreenHeight-100, Mouse, Alt
}

toMouseNormal() {
    global _mouseAltMode
    _mouseAltMode := 0
    Progress, off
}

toggleMouseAlt() {
    global _mouseAltMode
    if (isMouseAlt())
        toMouseNormal()
    else
        toMouseAlt()
}

; Shift
_mouseShifts    := []
_mouseShiftKeys := []

initMouseShift(layer, key) {
    global _mouseShifts, _mouseShiftKeys
    _mouseShifts   [layer] := 0
    _mouseShiftKeys[layer] := key
}

resetMouseShift(layer) {
    global _mouseShifts, _mouseShiftKeys
    _mouseShifts[layer] := 0
}

isMouseShift(layer) { ; Whether mouse is currently in shifted state or any shift state keys has been used
    global _mouseShifts, _mouseShiftKeys
    if (!_mouseShifts[layer]) ; Once shifted, remember the state until explicitly reset. Small performance optimizations
        _mouseShifts[layer] := GetKeyState(_mouseShiftKeys[layer])
    return _mouseShifts[layer]
}

hasMouseShifted(layer) { ; Whether any shift state keys has been used
    global _mouseShifts, _mouseShiftKeys
    return _mouseShifts[layer]
}


