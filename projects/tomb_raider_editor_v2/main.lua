local camera = {
  position = lovr.math.newVec3(0, 2, -4),
  rotation = lovr.math.newQuat(),
  speed = 3,
  mouseDown = false,
  sensitivity = 0.002, -- Reduced from 0.002
  lastx = 0,
  lasty = 0
}

function lovr.load()
  -- We don't need any mouse initialization - it's handled by lovr.system
end

function lovr.update(dt)
  -- Camera rotation with mouse input
  if lovr.system.isMouseDown(2) then -- Right mouse button
    local mx, my = lovr.system.getMousePosition()
    
    if camera.mouseDown then
      local dx = (mx - camera.lastx) * camera.sensitivity 
      local dy = (my - camera.lasty) * camera.sensitivity
      
      -- Apply rotations directly without storing intermediates
      camera.rotation:mul(lovr.math.quat(-dx, 0, 1, 0))
      camera.rotation:mul(lovr.math.quat(-dy, 1, 0, 0))
    end
    
    camera.lastx = mx
    camera.lasty = my
  end

  -- WASD movement
  local dx, dy, dz = 0, 0, 0
  if lovr.system.isKeyDown('w') then dz = -1 end
  if lovr.system.isKeyDown('s') then dz = 1 end
  if lovr.system.isKeyDown('a') then dx = -1 end
  if lovr.system.isKeyDown('d') then dx = 1 end
  if lovr.system.isKeyDown('q') then dy = -1 end
  if lovr.system.isKeyDown('e') then dy = 1 end
  
  -- Apply movement
  local movement = lovr.math.vec3(dx, dy, dz)
  movement:mul(dt * camera.speed)
  movement:rotate(camera.rotation)
  camera.position:add(movement)
end

function lovr.draw(pass)
  -- Set camera
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
  -- Calculate panel boundary in screen coordinates
  local width = lovr.system.getWindowWidth()
  local panelStart = width * 0.8
  
  -- Only rotate camera when right-clicking in the 3D view area
  if button == 2 and x < panelStart then
    camera.mouseDown = true
    -- Initialize last position when starting to drag
    camera.lastx, camera.lasty = lovr.system.getMousePosition()
  end
end

function lovr.mousereleased(x, y, button)
  if button == 2 then
    camera.mouseDown = false
  end
end
