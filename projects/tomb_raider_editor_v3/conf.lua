function lovr.conf(t)
    t.window.width = 1920
    t.window.height = 1080
    t.window.fullscreen = false  -- Can be toggled via command line or in-game
    t.window.resizable = true   -- Allow window resizing
    t.modules.headset = false   -- We're making a desktop app
end