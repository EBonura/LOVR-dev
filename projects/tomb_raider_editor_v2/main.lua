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
  
  -- Calculate cursor ray in world space
  local mx, my = lovr.system.getMousePosition()
  local width, height = lovr.system.getWindowDimensions()
  
  -- Convert mouse position to view space coordinates
  local nx = (mx / width) * 2 - 1  -- Remove inversion to fix left/right movement
  local ny = ((height - my) / height) * 2 - 1
  
  -- Create ray direction with FOV and aspect ratio scaling
  local rayStart = camera.position
  local fov = 67.5 * (math.pi / 180)
  local tanFov = math.tan(fov / 2)
  local aspect = width / height
  
  local rayDirection = lovr.math.vec3(
    nx * tanFov * aspect,  -- Scale x by both FOV and aspect ratio
    ny * tanFov,          -- Scale y by FOV only
    -1
  )
  rayDirection:rotate(camera.rotation)
  rayDirection:normalize()
  
  -- Calculate intersection with grid plane (y = 0)
  local t = -rayStart.y / rayDirection.y
  local intersection = lovr.math.vec3(
    rayStart.x + rayDirection.x * t,
    0,
    rayStart.z + rayDirection.z * t
  )
  
  -- Draw grid (offset by 0.5 to align with cube centers, and slightly below Y=0 to prevent z-fighting)
  pass:setColor(0.5, 0.5, 0.5, 0.5)
  pass:plane(0.5, -0.001, 0.5, 20, 20, -math.pi/2, 1, 0, 0, 'line', 20, 20)
  
  -- Draw intersection point and cube
  if t > 0 then  -- Only draw if intersection is in front of camera
    -- Round intersection to nearest grid unit
    local gridX = math.floor(intersection.x + 0.5)
    local gridZ = math.floor(intersection.z + 0.5)
    
    -- Draw wireframe cube
    pass:setColor(1, 1, 1, 1)
    pass:box(gridX, 0.5, gridZ, 1, 1, 1, 0, 0, 0, 0, 'line')
    
    -- Draw intersection point
    pass:setColor(1, 0, 0, 1)
    pass:sphere(intersection, 0.1)
  end
  
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
  
  -- For 2D UI, use the same scaling as the ray direction before normalization
  local uiX = nx * tanFov * aspect
  local uiY = ny * tanFov
  
  -- Only draw if within panel bounds
  if uiX >= (panelX - panelWidth/2) and 
     uiX <= (panelX + panelWidth/2) and 
     uiY <= 1 and 
     uiY >= -1 then
    -- Set view pose for 2D overlay
    pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
    pass:setColor(0, 0, 1, 1)  -- Blue color
    -- Draw a circle at the scaled mouse position
    pass:circle(lovr.math.vec3(uiX, uiY, -1), 0.02)
  end
end

function lovr.mousepressed(x, y, button)
  camera:mousepressed(x, y, button)
end

function lovr.mousereleased(x, y, button)
  camera:mousereleased(x, y, button)
end
