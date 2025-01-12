local Camera = {}
Camera.__index = Camera

function Camera.new()
  local self = setmetatable({}, Camera)
  self.position = lovr.math.newVec3(0, 1.7, 3) -- Typical standing height and closer to grid
  self.yaw = 0
  self.pitch = -0.2 -- Slight downward tilt to see grid better
  self.speed = 5 -- Movement speed in meters per second
  return self
end

function Camera:getRotation()
  return lovr.math.quat(self.yaw, 0, 1, 0) * lovr.math.quat(self.pitch, 1, 0, 0)
end

function Camera:getForward()
  return self:getRotation():direction()
end

function Camera:getRight()
  local yawRotation = lovr.math.quat(self.yaw, 0, 1, 0)
  return yawRotation:direction():cross(lovr.math.vec3(0, 1, 0)):normalize()
end

function Camera:screenToWorldRay(x, y)
  local width, height = lovr.system.getWindowDimensions()
  -- Convert to normalized device coordinates (-1 to 1)
  local nx = (2 * x / width) - 1
  local ny = 1 - (2 * y / height)
  
  -- Create ray in view space
  local tanFov = math.tan(math.rad(67.5) / 2)
  local aspect = width / height
  local rayX = nx * aspect * tanFov
  local rayY = ny * tanFov
  local rayDir = lovr.math.vec3(rayX, rayY, -1):normalize()
  
  -- Transform ray direction to world space using camera rotation
  rayDir = self:getRotation():mul(rayDir)
  
  return self.position, rayDir
end

function Camera:update(dt)
  -- Get input vectors
  local dx = 0
  local dy = 0
  local dz = 0
  
  -- Forward/Backward
  if lovr.system.isKeyDown('w') then dz = -1 end
  if lovr.system.isKeyDown('s') then dz = 1 end
  
  -- Left/Right
  if lovr.system.isKeyDown('a') then dx = -1 end
  if lovr.system.isKeyDown('d') then dx = 1 end
  
  -- Up/Down
  if lovr.system.isKeyDown('space') then dy = 1 end
  if lovr.system.isKeyDown('lshift') then dy = -1 end
  
  -- Camera rotation
  if lovr.system.isKeyDown('left') then self.yaw = self.yaw + dt end
  if lovr.system.isKeyDown('right') then self.yaw = self.yaw - dt end
  if lovr.system.isKeyDown('up') then 
    self.pitch = math.min(self.pitch + dt, math.pi/2)
  end
  if lovr.system.isKeyDown('down') then
    self.pitch = math.max(self.pitch - dt, -math.pi/2)
  end
  
  -- Update position based on input
  if dx ~= 0 or dy ~= 0 or dz ~= 0 then
    local moveSpeed = self.speed * dt
    local movement = lovr.math.vec3()
    
    -- Forward/backward movement (using flattened forward direction)
    if dz ~= 0 then
      local forward = self:getForward()
      local flatForward = lovr.math.vec3(forward.x, 0, forward.z):normalize()
      movement:add(flatForward:mul(-dz)) -- Negative because forward is -Z
    end
    
    -- Left/right movement (strafe)
    if dx ~= 0 then
      movement:add(self:getRight():mul(dx))
    end
    
    -- Up/down movement (world space)
    if dy ~= 0 then
      movement:add(lovr.math.vec3(0, dy, 0))
    end
    
    -- Normalize movement vector if we're moving in multiple directions
    if dx ~= 0 and dz ~= 0 then
      movement:normalize()
    end
    
    -- Apply movement
    movement:mul(moveSpeed)
    self.position:add(movement)
  end
end

return Camera
