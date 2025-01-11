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

-- Camera state
local camera = {
  position = lovr.math.newVec3(0, 1.7, 3), -- Typical standing height and closer to grid
  yaw = 0,
  pitch = -0.2, -- Slight downward tilt to see grid better
  speed = 5 -- Movement speed in meters per second
}

-- Convert screen coordinates to world ray
local function screenToWorldRay(x, y)
  local width, height = lovr.system.getWindowDimensions()
  -- Convert to normalized device coordinates (-1 to 1)
  local nx = (2 * x / width) - 1
  local ny = 1 - (2 * y / height)
  
  -- Create view matrix using the same rotation order as the camera
  local rotation = lovr.math.quat(camera.yaw, 0, 1, 0) * lovr.math.quat(camera.pitch, 1, 0, 0)
  
  -- Get camera basis vectors
  local forward = rotation:direction()
  local worldUp = lovr.math.vec3(0, 1, 0)
  local right = worldUp:cross(forward):normalize()
  local up = forward:cross(right):normalize()
  
  -- Create view matrix from camera orientation
  local view = lovr.math.mat4():target(camera.position, camera.position + forward, up)
  
  -- Create ray in view space
  local tanFov = math.tan(math.rad(67.5) / 2)
  local width, height = lovr.system.getWindowDimensions()
  local aspect = width / height
  
  -- Calculate ray direction in view space
  local rayX = nx * aspect * tanFov
  local rayY = ny * tanFov
  local rayDir = lovr.math.vec3(rayX, rayY, -1):normalize()
  
  -- Transform ray direction to world space using camera rotation
  rayDir = rotation:mul(rayDir)
  
  -- Return ray starting from camera position
  return camera.position, rayDir
end

function lovr.update(dt)
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
  if lovr.system.isKeyDown('left') then camera.yaw = camera.yaw + dt end
  if lovr.system.isKeyDown('right') then camera.yaw = camera.yaw - dt end
  if lovr.system.isKeyDown('up') then 
    camera.pitch = math.min(camera.pitch + dt, math.pi/2)
  end
  if lovr.system.isKeyDown('down') then
    camera.pitch = math.max(camera.pitch - dt, -math.pi/2)
  end
  
  -- Update position based on input
  if dx ~= 0 or dy ~= 0 or dz ~= 0 then
    local moveSpeed = camera.speed * dt
    
    -- Calculate camera direction vectors using quaternion rotation
    local rotation = lovr.math.quat(camera.yaw, 0, 1, 0) * lovr.math.quat(camera.pitch, 1, 0, 0)
    local forward = rotation:direction()
    
    -- Calculate right vector (always horizontal, based on yaw only)
    local yawRotation = lovr.math.quat(camera.yaw, 0, 1, 0)
    local right = yawRotation:direction():cross(lovr.math.vec3(0, 1, 0)):normalize()
    
    -- Calculate movement vector
    local movement = lovr.math.vec3()
    
    -- Forward/backward movement (using flattened forward direction)
    if dz ~= 0 then
      local flatForward = lovr.math.vec3(forward.x, 0, forward.z):normalize()
      movement:add(flatForward:mul(-dz)) -- Negative because forward is -Z
    end
    
    -- Left/right movement (strafe)
    if dx ~= 0 then
      movement:add(right:mul(dx))
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
    camera.position:add(movement)
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

function lovr.mousepressed(x, y, button)
  local origin, direction = screenToWorldRay(x, y)
  
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
  -- Set camera view
  -- Apply yaw first, then pitch to prevent roll
  local rotation = lovr.math.quat(camera.yaw, 0, 1, 0) * lovr.math.quat(camera.pitch, 1, 0, 0)
  pass:setViewPose(1, camera.position, rotation)
  
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
    pass:box(tonumber(x), tonumber(y), tonumber(z), 1)
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
