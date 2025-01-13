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
      -- Calculate delta from last position instead of GetMouseX/Y
      local dx = (mx - camera.lastx) * camera.sensitivity 
      local dy = (my - camera.lasty) * camera.sensitivity
      camera.rotation = camera.rotation:mul(lovr.math.quat(-dx, 0, 1, 0)):mul(lovr.math.quat(-dy, 1, 0, 0))
    end

    -- Store current position for next frame
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
  
  -- Create fresh movement vector
  local movement = lovr.math.vec3(dx, dy, dz):mul(dt * camera.speed)
  movement:rotate(camera.rotation)
  camera.position:add(movement)
end

function lovr.draw(pass)
  -- Set camera
  pass:setViewPose(1, camera.position, camera.rotation)
  
  -- Draw grid
  pass:setColor(0.5, 0.5, 0.5, 0.5)
  pass:plane(0, 0, 0, 20, 20, -math.pi/2, 1, 0, 0, 'line', 20, 20)
  
  -- Draw right panel background (80% to 100% of screen width)
  pass:setColor(0.2, 0.2, 0.2, 1)
  pass:push()
  pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
  pass:plane(0.8, 0, -1, 0.4, 2) -- 20% width panel
  pass:setColor(1, 1, 1, 1)
  pass:text("Tools", 0.65, 0.8, -0.9, 0.05)
  pass:pop()
end

function lovr.mousepressed(x, y, button)
  -- Only rotate camera when right-clicking in the 3D view area (left 80% of screen)
  if button == 2 and x < lovr.system.getWindowWidth() * 0.8 then
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
