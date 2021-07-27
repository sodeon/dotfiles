;-------------------------------------------------------------------------------
; Dual keys
; Inspired from: https://autohotkey.com/board/topic/103174-dual-function-control-key/
;-------------------------------------------------------------------------------
dualKeyCounter = 0 ; Register only one keydown event per dual key. e.g. When holding down "LCtrl", after some initial delay, OS will see repeatedly firing key down events.
dualKeyTime    = 0 ; How long does the dual key pressed.

startDualKey() {
    global dualKeyTime, dualKeyCounter
    if (dualKeyCounter == 0)
        dualKeyTime := 0
    else if (dualKeyCounter >= 1) {
        dualKeyTime := dualKeyTime + A_TimeSincePriorHotkey
    }

    dualKeyCounter := dualKeyCounter + 1
}

isDualKey(key, time = 200) {
    global dualKeyTime, dualKeyCounter
    dualKeyTime := dualKeyTime + A_TimeSincePriorHotkey
    dualKeyCounter := 0

    if (A_PriorKey = key && (dualKeyTime <= time && dualKeyTime >= 0)) ; dualKeyTime >= 0, "=" happens when dual key is sent by non-human input (e.g. QMK)
        return true
    else
        return false
}


