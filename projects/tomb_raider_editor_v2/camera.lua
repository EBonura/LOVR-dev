local Camera = {
  position = lovr.math.newVec3(0, 2, -4),
  rotation = lovr.math.newQuat(),
  speed = 3,
  mouseDown = false,
  sensitivity = 0.002,
  lastx = 0,
  lasty = 0,
  yaw = 0,
  pitch = 0,
  currentGridCell = {x = 0, y = 0, z = 0},
  world = nil,
  gridKeyHoldTime = 0,        -- Time for key hold
  gridKeyHoldDelay = 0.3,     -- Delay before continuous movement starts
  gridMoveRepeatRate = 0.1    -- How fast it moves when held
}

function Camera:new()
  local camera = setmetatable({}, { __index = Camera })
  return camera
end

function Camera:setWorld(world)
  self.world = world
end

function Camera:handleKeyPressed(key)
  -- Immediate response to key press
  if self.world then
    if key == 'r' then
      self.world:shiftGridUp()
    elseif key == 'f' then
      self.world:shiftGridDown()
    end
  end
end

function Camera:update(dt)
  -- Camera rotation with mouse input
  if lovr.system.isMouseDown(2) then -- Right mouse button
    local mx, my = lovr.system.getMousePosition()
    
    if self.mouseDown then
      local dx = (mx - self.lastx) * self.sensitivity 
      local dy = (my - self.lasty) * self.sensitivity
      
      -- Update yaw and pitch angles
      self.yaw = self.yaw - dx
      self.pitch = math.max(-math.pi/2, math.min(math.pi/2, self.pitch - dy))
      
      -- Set rotation directly from angles using a single new quaternion
      self.rotation = lovr.math.newQuat()
      self.rotation:mul(lovr.math.quat(self.yaw, 0, 1, 0))
      self.rotation:mul(lovr.math.quat(self.pitch, 1, 0, 0))
    end
    
    self.lastx = mx
    self.lasty = my
  end

  -- Handle held keys for grid movement
  if self.world then
    if lovr.system.isKeyDown('r') or lovr.system.isKeyDown('f') then
      self.gridKeyHoldTime = self.gridKeyHoldTime + dt
      if self.gridKeyHoldTime > self.gridKeyHoldDelay then
        -- Calculate how many moves should occur based on time held
        local moveInterval = (self.gridKeyHoldTime - self.gridKeyHoldDelay) % self.gridMoveRepeatRate
        if moveInterval < dt then  -- Only move on interval
          if lovr.system.isKeyDown('r') then
            self.world:shiftGridUp()
          else
            self.world:shiftGridDown()
          end
        end
      end
    else
      self.gridKeyHoldTime = 0
    end
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
  movement:mul(dt * self.speed)
  movement:rotate(self.rotation)
  self.position:add(movement)
end

function Camera:setCurrentGridCell(x, y, z)
  self.currentGridCell.x = x
  self.currentGridCell.y = y
  self.currentGridCell.z = z
end

function Camera:mousepressed(x, y, button)
  if button == 2 then
    self.mouseDown = true
    -- Initialize last position when starting to drag
    self.lastx, self.lasty = lovr.system.getMousePosition()
  end
end

function Camera:mousereleased(x, y, button)
  if button == 2 then
    self.mouseDown = false
  end
end

function Camera:getDebugText()
  return string.format(
    "Camera Info:\n" ..
    "Position: %.2f, %.2f, %.2f\n" ..
    "Yaw: %.2f\n" ..
    "Pitch: %.2f\n" ..
    "Grid Cell: %d, %d, %d",
    self.position.x, self.position.y, self.position.z,
    self.yaw,
    self.pitch,
    self.currentGridCell.x, self.currentGridCell.y, self.currentGridCell.z
  )
end

return Camera