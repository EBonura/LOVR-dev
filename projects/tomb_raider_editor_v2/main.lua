local Camera = require('camera')
local camera = Camera:new()

function lovr.load()
  -- We don't need any mouse initialization - it's handled by lovr.system
end

function lovr.update(dt)
  camera:update(dt)
end

function lovr.draw(pass)
  -- Set camera
  pass:setViewPose(1, camera.position, camera.rotation)
  
  -- Draw debug info (using 2D overlay)
  pass:setViewPose(1, lovr.math.vec3(0, 0, 0), lovr.math.quat())
  pass:setColor(1, 1, 1, 1)
  pass:text(
    camera:getDebugText(),
    -1.1, 0.6, -1, -- x, y, z position (matching original positioning)
    0.04, -- scale
    0, -- angle
    0, 1, 0, -- rotation axis
    0, -- wrap
    'left', -- horizontal alignment
    'top' -- vertical alignment
  )
  
  -- Reset view pose for 3D scene
  pass:setViewPose(1, camera.position, camera.rotation)
  
  -- Draw grid
  pass:setColor(0.5, 0.5, 0.5, 0.5)
  pass:plane(0, 0, 0, 20, 20, -math.pi/2, 1, 0, 0, 'line', 20, 20)
  
  -- Calculate right panel dimensions based on window size
  local width, height = lovr.system.getWindowDimensions()
  local aspect = width / height
  
  -- In normalized device coordinates (-1 to 1), calculate panel position
  -- 20% from the right means the panel starts at 0.6 in NDC
  local panelWidth = 0.8 -- 40% of NDC width
  local panelX = aspect * 0.6 -- Adjust for aspect ratio
  
  -- Draw right panel background
  pass:setColor(0.2, 0.2, 0.2, 1)
  pass:push()
  pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
  pass:plane(panelX, 0, -1, panelWidth, 2)
  pass:setColor(1, 1, 1, 1)
  pass:text("Tools", panelX - 0.3, 0.8, -0.9, 0.05)
  pass:pop()
end

function lovr.mousepressed(x, y, button)
  camera:mousepressed(x, y, button)
end

function lovr.mousereleased(x, y, button)
  camera:mousereleased(x, y, button)
end
