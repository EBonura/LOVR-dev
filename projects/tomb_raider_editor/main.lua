function lovr.conf(t)
  t.window.width = 1024
  t.window.height = 768
  t.window.fullscreen = false
end

-- Projection matrix for mouse picking
local projection

function lovr.load()
  lovr.graphics.setBackgroundColor(0.05, 0.05, 0.05)
  -- Create projection matrix for mouse picking
  local width, height = lovr.system.getWindowDimensions()
  projection = lovr.math.newMat4():perspective(67.5, width/height, 0.01, 100)
end

function lovr.resize(width, height)
  -- Update projection matrix when window is resized
  projection:set(lovr.math.newMat4():perspective(67.5, width/height, 0.01, 100))
end

-- World state
local blocks = {} -- Store placed blocks: key = "x,y,z", value = true
local currentFile = "level1.txt" -- Default save file
local gridSize = 10
local mouseX, mouseY = 0, 0 -- Track mouse position
local previewPosition = nil -- Position for preview cube

-- Camera class
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

-- Helper functions
local function worldToGrid(x, y, z)
  return math.floor(x + 0.5), math.floor(y + 0.5), math.floor(z + 0.5)
end

local function getBlockKey(x, y, z)
  return string.format("%d,%d,%d", x, y, z)
end

-- Ray-plane intersection
local function rayPlaneIntersection(rayOrigin, rayDir, planePoint, planeNormal)
  local denom = rayDir:dot(planeNormal)
  if math.abs(denom) > 1e-6 then
    local diff = lovr.math.vec3(
      planePoint.x - rayOrigin.x,
      planePoint.y - rayOrigin.y,
      planePoint.z - rayOrigin.z
    )
    local t = diff:dot(planeNormal) / denom
    if t >= 0 then
      return lovr.math.vec3(
        rayOrigin.x + rayDir.x * t,
        rayOrigin.y + rayDir.y * t,
        rayOrigin.z + rayDir.z * t
      )
    end
  end
  return nil
end

-- Create camera instance
local camera = Camera.new()

function lovr.update(dt)
  camera:update(dt)
  
  -- Update mouse position
  mouseX, mouseY = lovr.system.getMousePosition()
  
  -- Calculate preview position
  local origin, direction = camera:screenToWorldRay(mouseX, mouseY)
  local hitPoint = rayPlaneIntersection(
    origin,
    direction,
    lovr.math.vec3(0, 0, 0),
    lovr.math.vec3(0, 1, 0)
  )
  
  if hitPoint then
    local gx, gy, gz = worldToGrid(hitPoint.x, hitPoint.y, hitPoint.z)
    previewPosition = {x = gx, y = 0, z = gz} -- Store preview position
  else
    previewPosition = nil
  end
end

function lovr.mousepressed(x, y, button)
  local origin, direction = camera:screenToWorldRay(x, y)
  
  -- Intersect with ground plane (y = 0)
  local hitPoint = rayPlaneIntersection(
    origin,
    direction,
    lovr.math.vec3(0, 0, 0),
    lovr.math.vec3(0, 1, 0)
  )
  
  if hitPoint then
    local gx, gy, gz = worldToGrid(hitPoint.x, hitPoint.y, hitPoint.z)
    local key = getBlockKey(gx, 0, gz) -- Place blocks at ground level for now
    
    if button == 1 then -- Left click to place
      blocks[key] = true
    elseif button == 2 then -- Right click to remove
      blocks[key] = nil
    end
  end
end

function lovr.draw(pass)
  pass:setViewPose(1, camera.position, camera:getRotation())
  
  -- Draw grid
  -- Draw a solid dark plane first
  pass:setColor(0.1, 0.1, 0.12)
  pass:plane(0, 0, 0, 20, 20, -math.pi / 2, 1, 0, 0)
  -- Draw grid lines on top
  pass:setColor(0.2, 0.2, 0.25)
  pass:plane(0, 0.001, 0, 20, 20, -math.pi / 2, 1, 0, 0, 'line', 20, 20)
  
  -- Draw blocks
  pass:setColor(1, 0.7, 0.3)
  for key in pairs(blocks) do
    local x, y, z = string.match(key, "(-?%d+),(-?%d+),(-?%d+)")
    pass:box(tonumber(x), tonumber(y) + 0.5, tonumber(z), 1, 1, 1)
  end
  
  -- Draw preview cube
  if previewPosition then
    pass:setColor(1, 1, 1, 0.5) -- Semi-transparent white
    pass:setWireframe(true)
    pass:box(previewPosition.x, previewPosition.y + 0.5, previewPosition.z, 1, 1, 1)
    pass:setWireframe(false)
  end
  
  -- Draw controls help text
  pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
  pass:setColor(1, 1, 1)
  pass:text(
    "Controls:\n" ..
    "WASD - Move\n" ..
    "Space/Shift - Up/Down\n" ..
    "Arrow Keys - Look around\n" ..
    "Left Click - Place block\n" ..
    "Right Click - Remove block\n" ..
    "Esc - Exit",
    -0.3, 0.3, -1,
    0.08
  )
end

function lovr.keypressed(key)
  if key == 'escape' then
    lovr.event.quit()
  end
end
