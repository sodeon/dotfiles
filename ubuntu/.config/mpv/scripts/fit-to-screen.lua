function fit_to_screen(height)
    video_scale = mp.get_property_number("display-width") / mp.get_property_number("width")
    scale = mp.get_property_number("display-height") / (video_scale * mp.get_property_number("height"))
    zoom = math.log10(scale) / math.log10(2)
    mp.set_property_number("video-zoom", zoom) -- video-zoom is log2 based
    -- mp.set_property_number("video-scale-x", scale)
    -- mp.set_property_number("video-scale-y", scale)
    mp.osd_message("Fit to screen: " .. scale)
end
mp.register_script_message("fit-to-screen", fit_to_screen)
