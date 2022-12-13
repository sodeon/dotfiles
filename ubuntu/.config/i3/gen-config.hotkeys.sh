#!/bin/bash -ue
#---------------------------------------------------------------------------------------------------
# Aliases:
# Key symbol  : bindsym  -> s (bind"s"ym)
# Key code    : bindcode -> c (bind"c"ode)
# Mouse button: bindsym  -> b (bindsym --whole-window ... button[0-9])
#
# exec --no-startup-id: ->
# exec                : =>
#---------------------------------------------------------------------------------------------------
is_left_hand_mouse=${1-""}


#---------------------------------------------------------------------------------------------------
# Variables
#---------------------------------------------------------------------------------------------------
config="config.hotkeys"
monitor="monitor.pc"


#---------------------------------------------------------------------------------------------------
# Helpers
#---------------------------------------------------------------------------------------------------
trim()   { 
    sed -e '/^#/d'      `# Remove comment line`     \
        -e '/^\s*$/d'   `# Remove empty line`       \
        -e 's/#.*$//'   `# Remove trailing comment` \
        -e 's/^\s*//'   `# Remove starting spaces`  \
        -e 's/\s\+/ /g' `# Replace multiple spaces with single space`
}
indent() { sed -e 's/^/    /'; }
translate() {
    # TODO: "--release" is not properly handled.
    sed -e 's/^\([0-9][0-9][0-9]\+\) /bindcode \1 /' \
        -e 's/^\(button[0-9]\) /bindsym --whole-window \1 /' \
        -e 's/^\([^b][^i][^ ]\+button[0-9]\) /bindsym --whole-window \1 /' \
        -e 's/^\([^b][^i][^ ]\+[0-9][0-9][0-9]\+\) /bindcode \1 /' \
        -e 's/^\([^b][^i][^ ]\+\) /bindsym \1 /' \
        -e 's/ -> / exec --no-startup-id /' \
        -e 's/ => / exec /'
    # sed -e 's/^s /bindsym /'  `# Key` \
    #     -e 's/^c /bindcode /' `# Key` \
    #     -e 's/^b /bindsym --whole-window /' `# Mouse button`\
    #     -e 's/ -> / exec --no-startup-id /' \
    #     -e 's/ => / exec /'
}
# input-remapper-workaround() { # Used after trim and before translate
#     # input-remapper has problem dealing with high resolution scrolling
#     if xinput | grep -q forwarded; then
#         sed -e "s/\(201.*->\)/\1 xte 'mouseup 4' \&\& /" `# ` \
#             -e "s/\(202.*->\)/\1 xte 'mouseup 5' \&\& /" `# ` \
#             -e "s/\(201.*=>\)/\1 xte 'mouseup 4' \&\& /" `# ` \
#             -e "s/\(202.*=>\)/\1 xte 'mouseup 5' \&\& /" `# `
#     else
#         sed -e 's/a/a/' # Bypass
#     fi
# }
left-hand-mouse() { # Used after trim and before translate
    if [[ $is_left_hand_mouse != "" ]]; then # Swap button1 and button3 mappings. Retain button3 mapping if no paired button1 mapping.
        sed -e "s/button3/buttong/" `# ` \
            -e "s/button1/button3/" `# ` \
            -e "s/buttong/button1/" `# ` \
            -e "s/mod+button1/mod+button3/" `# ` \
            -e "s/Control+button1/Control+button3/" `# `
    else
        sed -e "s/a/a/" # Bypass
    fi
}

mouse-mode() {
    echo "mode $1 {" >> $config
        cat keyboard/{normal,$monitor} | trim | translate | indent >> $config
}
end-mode() { 
    echo "}" >> $config
}

add-bindings()        { cat $@ | trim | left-hand-mouse | translate          >> $config; }
add-indent-bindings() { cat $@ | trim | left-hand-mouse | translate | indent >> $config; }
# add-bindings()        { cat $@ | trim | input-remapper-workaround | left-hand-mouse | translate          >> $config; }
# add-indent-bindings() { cat $@ | trim | input-remapper-workaround | left-hand-mouse | translate | indent >> $config; }


#---------------------------------------------------------------------------------------------------
# Main
#---------------------------------------------------------------------------------------------------
rm $config

add-bindings keyboard/normal
add-bindings keyboard/$monitor

# Normalscroll
add-bindings mouse/common
# add-bindings mouse/{normalscroll,common}

# mouse-mode Hyperscroll
#     add-indent-bindings mouse/{hyperscroll,common}
# end-mode

# mouse-mode Alt
#     add-indent-bindings mouse/{alt,common}
# end-mode

# mouse-mode Game
#     add-indent-bindings mouse/game
# end-mode
