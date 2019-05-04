#!/bin/zsh

source ~/.config/hardware/display.zsh

if [[ $1 = "b" ]]; then
	ddcutil getvcp $brightness_feature_id --bus $i2c_bus | sed 's/^.*current value =\s*//' | sed  's/,.*$//' 
elif [[ $1 = "bu" ]]; then
	ddcutil setvcp $brightness_feature_id + $brightness_step --bus $i2c_bus
elif [[ $1 = "bd" ]]; then
	ddcutil setvcp $brightness_feature_id - $brightness_step --bus $i2c_bus
elif [[ $1 = "bv" ]]; then
	ddcutil setvcp $brightness_feature_id $default_video_brightness --bus $i2c_bus
elif [[ $1 = "br" ]]; then
	ddcutil setvcp $brightness_feature_id $default_reading_brightness --bus $i2c_bus
elif [[ $1 = "cr" ]]; then
	ddcutil setvcp $color_temperature_feature_id $color_temperature_reading --bus $i2c_bus
elif [[ $1 = "cv" ]]; then
	ddcutil setvcp $color_temperature_feature_id $color_temperature_video   --bus $i2c_bus
fi
