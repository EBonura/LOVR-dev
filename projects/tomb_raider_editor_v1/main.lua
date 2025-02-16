local Camera = require('camera')
local World = require('world')
local utils = require('utils')
local TextureMenu = require('texture_menu')

-- Projection matrix for mouse picking
local projection
local world
local camera
local menuHandledClick = false
local lastClickTime = 0
local lastClickX = 0
local lastClickY = 0
local DOUBLE_CLICK_TIME = 0.3 -- seconds between clicks to count as double-click

function lovr.load()
  lovr.graphics.setBackgroundColor(0.05, 0.05, 0.05)
  -- Create projection matrix for mouse picking
  local width, height = lovr.system.getWindowDimensions()
  projection = lovr.math.newMat4():perspective(67.5, width/height, 0.01, 100)
  
  -- Initialize world and camera
  world = World.new()
  camera = Camera.new()
  TextureMenu.load()
end

function lovr.resize(width, height)
  -- Update projection matrix when window is resized
  projection:set(lovr.math.newMat4():perspective(67.5, width/height, 0.01, 100))
end

function lovr.update(dt)
  camera:update(dt)
  
  -- Grid height controls
  if lovr.system.isKeyDown('r') then
    world:adjustGridHeight(1)
  elseif lovr.system.isKeyDown('f') then
    world:adjustGridHeight(-1)
  end
  
  -- Update mouse position, preview, and texture menu hover
  local mouseX, mouseY = lovr.system.getMousePosition()
  
  -- Only update world cursor when not over texture panel
  if not TextureMenu.isOverPanel(mouseX, mouseY) then
    world:updateCursor(camera, mouseX, mouseY)
  end
  
  TextureMenu.updateHover(mouseX, mouseY)
end

function lovr.mousepressed(x, y, button)
  local currentTime = lovr.timer.getTime()
  if button == 1 then
    -- First check if we're over the texture panel
    if TextureMenu.isOverPanel(x, y) then
      TextureMenu.mousepressed(x, y)
      -- Update last click info
      lastClickTime = currentTime
      lastClickX = x
      lastClickY = y
      return
    end
    
    -- If menu didn't handle the click, proceed with block placement/removal
    local origin, direction = camera:screenToWorldRay(x, y)
    
    -- Intersect with ground plane at current grid height
    local hitPoint = utils.rayPlaneIntersection(
      origin,
      direction,
      lovr.math.vec3(0, world.gridHeight, 0),
      lovr.math.vec3(0, 1, 0)
    )
    
    if hitPoint then
      -- Use the exact same grid coordinates for placement as preview
      local gx, gy, gz = utils.worldToGrid(hitPoint.x, hitPoint.y, hitPoint.z)
      
      -- Check for double click
      if currentTime - lastClickTime < DOUBLE_CLICK_TIME 
         and math.abs(x - lastClickX) < 2 
         and math.abs(y - lastClickY) < 2 then
        -- Double click detected - remove block
        world:removeBlock(gx, world.gridHeight + 0.5, gz)
      else
        -- Single click - place block
        world:placeBlock(gx, world.gridHeight + 0.5, gz)
      end
    end
  end
  
  -- Update last click info
  lastClickTime = currentTime
  lastClickX = x
  lastClickY = y
end

function lovr.draw(pass)
  pass:setViewPose(1, camera.position, camera:getRotation())
  
  -- Draw world
  world:draw(pass)
  
  -- Draw texture menu
  TextureMenu.draw(pass)
  
  -- Draw controls help text
  pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
  pass:setColor(1, 1, 1)
  pass:text(
    "Controls:\n" ..
    "WASD - Move\n" ..
    "E/Q - Up/Down\n" ..
    "Arrow Keys - Look around\n" ..
    "R/F - Adjust grid height\n" ..
    "Left Click - Place block\n" ..
    "Double Click - Remove block\n" ..
    "Esc - Exit",
    -0.95, 0.7, -1, -- x, y, z position
    0.04, -- scale
    0, -- angle
    0, 1, 0, -- rotation axis
    0, -- wrap
    'left', -- horizontal alignment
    'top' -- vertical alignment
  )
  
  -- Draw hit point at the very end, after everything else
  pass:setViewPose(1, camera.position, camera:getRotation())
  world:drawHitPoint(pass)
end

function lovr.keypressed(key)
  if key == 'escape' then
    lovr.event.quit()
  end
end
