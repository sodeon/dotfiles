;-------------------------------------------------------------------------------
; Brightness, night light, resolution
;-------------------------------------------------------------------------------
; app aware monitor brightness/nightlight settings
monitorSetting() {
    global monitorSettings, displayMode
    return monitorSettings[displayMode]
}

setMonitorDdc(ddc) {
    Run, ClickMonitorDDC/ClickMonitorDDC.exe %ddc%,, Hide
}


setResolution(width, height, refreshRate) {
    ; RunWait, ChangeScreenResolution.exe /w=%width% /h=%height% /f=60 /d=0,, Hide
    RunWait, nircmd/nircmd.exe setdisplay %width% %height% 32 %refreshRate%,, Hide
}

increaseBrightness() {
    setting := monitorSetting()
    brightness := setting.brightness

    if (brightness >= 100)
        return

    if (brightness <= 0) {
        contrast := setting.contrast
        if (contrast < 50) {
            contrast += 5
            if (contrast > 50) ; Overshoot protection
                contrast = 50
            setMonitorDdc("c" . contrast)
            setting.contrast := contrast
            showNotification("Brightness: " . brightness . ", Contrast: " . contrast)
            return
        }
    } 

    ; if (brightness < 2)
    ;     delta := 2 - brightness
    ; else if (brightness < 5)
    if (brightness < 5)
        delta := 5 - brightness
    else
        delta := 5
    brightness += delta
    setMonitorDdc("b " . brightness)
    setting.brightness := brightness
    showNotification("Brightness: " . brightness)
}

decreaseBrightness() {
    setting := monitorSetting()
    brightness := setting.brightness

    if (brightness <= 0) {
        contrast := setting.contrast
        if (contrast = 0)
            return
        contrast -= 5
        setMonitorDdc("c" . contrast)
        setting.contrast := contrast
        showNotification("Brightness: " . brightness . ", Contrast: " . contrast)
        return
    } 

    ; if (brightness <= 2)
    ;     delta := brightness
    ; else if (brightness <= 5)
    ;    delta := brightness - 2
    if (brightness <= 5)
        delta := brightness
    else
        delta := 5
    brightness -= delta
    setMonitorDdc("b " . brightness)
    setting.brightness := brightness
    showNotification("Brightness: " . brightness)
}

setBrightnessMode(displayMode) {
    setMonitorDdc("p " . monitorSetting().temperature . " b " . monitorSetting().brightness . " c " . monitorSetting().contrast) ; Set temperature first, then brightness. For AOC 24G2E, setting brightness first will result in brightness settings ignored for "User1" color temperature
    setResolution(monitorSetting().width, monitorSetting().height, monitorSetting().refreshRate)
    text := "Reading"
    if (displayMode = 2)
        text := "Video"
    else if (displayMode = 3)
        text := "Gaming"
    showNotification("Brightness: " . monitorSetting().brightness . ", Contrast: " . monitorSetting().contrast, (text . " mode"))
}

toggleBrightnessMode() { ; Toggle between reading and video mode
    global displayMode
    if (displayMode >= 2)
        displayMode := 1
    else
        displayMode := 2
    setBrightnessMode(displayMode)
}

toggleGameMode() { ; Toggle between game mode and reading mode. Game mode should utilize monitor's highest refresh rate
    global displayMode
    if (displayMode != 3)
        displayMode := 3
    else
        displayMode := 1
    setBrightnessMode(displayMode)
}


