function lovr.conf(t)
  -- Set 16:9 window size (1280x720)
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = false
  -- Disable VR mode since this is a desktop editor
  t.modules.headset = false
end
