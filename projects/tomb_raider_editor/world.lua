local utils = require('utils')
local TextureMenu = require('texture_menu')

local World = {}
World.__index = World

function World.new()
  local self = setmetatable({}, World)
  self.blocks = {} -- Store placed blocks: key = "x,y,z", value = true
  self.gridSize = 10
  self.gridHeight = 0 -- Current height of the placement grid
  self.cursorPosition = nil
  self.previewPosition = nil
  self.lastHeightChange = 0 -- Timer for height adjustment
  self.heightChangeDelay = 0.2 -- Delay between height changes (in seconds)
  return self
end

function World:placeBlock(x, y, z)
  -- Store the exact same coordinates we use for preview along with the current texture
  self.blocks[utils.getBlockKey(x, y, z)] = {
    x = x,
    y = y,
    z = z,
    texture = TextureMenu.getSelectedTexture()
  }
end

function World:removeBlock(x, y, z)
  local key = utils.getBlockKey(x, y, z)
  self.blocks[key] = nil
end

function World:adjustGridHeight(delta)
  local currentTime = lovr.timer.getTime()
  if currentTime - self.lastHeightChange >= self.heightChangeDelay then
    self.gridHeight = self.gridHeight + delta
    self.lastHeightChange = currentTime
  end
end

function World:updateCursor(camera, mouseX, mouseY)
  local origin, direction = camera:screenToWorldRay(mouseX, mouseY)
  local hitPoint = utils.rayPlaneIntersection(
    origin,
    direction,
    lovr.math.vec3(0, self.gridHeight, 0),
    lovr.math.vec3(0, 1, 0)
  )
  
  if hitPoint then
    local gx, gy, gz = utils.worldToGrid(hitPoint.x, hitPoint.y, hitPoint.z)
    self.cursorPosition = {x = gx, y = self.gridHeight + 0.5, z = gz}
    
    -- Only show preview if there's no block at this position
    local key = utils.getBlockKey(gx, gy, gz)
    if not self.blocks[key] then
      self.previewPosition = self.cursorPosition
    else
      self.previewPosition = nil
    end
  else
    self.cursorPosition = nil
    self.previewPosition = nil
  end
end

function World:draw(pass)
  -- Draw grid lines
  pass:setColor(1, 1, 1, 0.3)
  pass:plane(0, self.gridHeight, 0, 20, 20, -math.pi / 2, 1, 0, 0, 'line', 20, 20)
  
  -- Draw blocks
  pass:setColor(1, 1, 1)
  for key, block in pairs(self.blocks) do
    -- Use stored coordinates directly to match preview position exactly
    pass:setMaterial(block.texture)
    pass:box(block.x, block.y, block.z, 1, 1, 1)
  end
  pass:setMaterial()
  
  -- Draw preview cube with current texture
  if self.previewPosition then
    pass:setColor(1, 1, 1, 0.5)
    pass:setMaterial(TextureMenu.getSelectedTexture())
    pass:box(self.previewPosition.x, self.previewPosition.y, self.previewPosition.z, 1, 1, 1)
    pass:setMaterial()
  end
  
  -- Draw cursor wireframe (red)
  if self.cursorPosition then
    pass:setColor(1, 0, 0, 1)
    pass:setWireframe(true)
    pass:box(self.cursorPosition.x, self.cursorPosition.y, self.cursorPosition.z, 1.01, 1.01, 1.01)
    pass:setWireframe(false)
  end
end

return World
