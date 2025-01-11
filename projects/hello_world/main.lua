function lovr.conf(t)
  -- Enable key input
  t.window.overlay = true
end

local reloadTime = 0
local cubeColor = { 0, 0, 0 }

function lovr.keypressed(key)
  if key == 'r' then
    -- Attempt to reload the code
    package.loaded['main'] = nil
    require('main')
    reloadTime = lovr.timer.getTime()
    cubeColor = { 0, 1, 0 }  -- Flash green on reload
  end
end

function lovr.draw(pass)
  -- Fade back to white after reload
  if lovr.timer.getTime() - reloadTime < 0.5 then
    pass:setColor(cubeColor)
  else
    pass:setColor(1, 1, 1)
  end
  
  -- Draw a rotating cube at the origin
  pass:cube(0, 1.7, -3, .5, lovr.timer.getTime())
  
  -- Draw reload instructions
  pass:text("Press 'R' to reload", 0, 2.2, -3, 0.1)
end
