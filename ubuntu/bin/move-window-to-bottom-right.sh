#!/bin/bash

displayGeometry=`xdotool getdisplaygeometry`
# windowPosition=`xdotool getactivewindow getwindowgeometry | grep Position | sed -r 's/^\s*Position:\s*//' | sed -r 's/ \(.*$//'`
windowGeometry=`xdotool getactivewindow getwindowgeometry | grep Geometry | sed -r 's/^\s*Geometry:\s*//' | sed -r 's/x/ /'`

# Get screen width/height
read displayWidth displayHeight <<< $(echo $displayGeometry)

# Get window width/height
read width height <<< $(echo $windowGeometry)

# Calculate bottom right position
let "newX = $displayWidth - $width"
let "newY = $displayHeight - $height"

# echo screen: $displayWidth $displayHeight
# echo window: $width $height
# echo final: $newX $newY
xdotool getactivewindow windowmove $newX $newY
