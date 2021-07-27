function scale_or_zoom(delta)
    if (mp.get_property_bool("fullscreen", false)) then
        mp.set_property_number("video-zoom"  , mp.get_property_number("video-zoom"  ) + delta)
        mp.osd_message("Zoom: " .. mp.get_property_number("video-zoom"))
    else
        mp.set_property_number("window-scale", mp.get_property_number("window-scale") + delta)
        mp.osd_message("Scale: " .. mp.get_property_number("window-scale"))
    end
end
mp.register_script_message("scale-or-zoom", scale_or_zoom)
