local Camera = require('camera')
local World = require('world')
local utils = require('utils')

-- Projection matrix for mouse picking
local projection
local world
local camera

function lovr.load()
  lovr.graphics.setBackgroundColor(0.05, 0.05, 0.05)
  -- Create projection matrix for mouse picking
  local width, height = lovr.system.getWindowDimensions()
  projection = lovr.math.newMat4():perspective(67.5, width/height, 0.01, 100)
  
  -- Initialize world and camera
  world = World.new()
  camera = Camera.new()
end

function lovr.resize(width, height)
  -- Update projection matrix when window is resized
  projection:set(lovr.math.newMat4():perspective(67.5, width/height, 0.01, 100))
end

function lovr.update(dt)
  camera:update(dt)
  
  -- Update mouse position and preview
  local mouseX, mouseY = lovr.system.getMousePosition()
  world:updatePreview(camera, mouseX, mouseY)
end

function lovr.mousepressed(x, y, button)
  local origin, direction = camera:screenToWorldRay(x, y)
  
  -- Intersect with ground plane (y = 0)
  local hitPoint = utils.rayPlaneIntersection(
    origin,
    direction,
    lovr.math.vec3(0, 0, 0),
    lovr.math.vec3(0, 1, 0)
  )
  
  if hitPoint then
    local gx, gy, gz = utils.worldToGrid(hitPoint.x, hitPoint.y, hitPoint.z)
    
    if button == 1 then -- Left click to place
      world:placeBlock(gx, 0.5, gz)
    elseif button == 2 then -- Right click to remove
      world:removeBlock(gx, 0.5, gz)
    end
  end
end

function lovr.draw(pass)
  pass:setViewPose(1, camera.position, camera:getRotation())
  
  -- Draw world
  world:draw(pass)
  
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
