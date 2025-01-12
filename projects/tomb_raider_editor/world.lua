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
  local key = utils.getBlockKey(x, y, z)
  local block = self.blocks[key] or {
    x = x,
    y = y,
    z = z,
    textures = {
      front = nil,
      back = nil,
      left = nil,
      right = nil,
      top = nil,
      bottom = nil
    }
  }
  
  -- Update only the selected face's texture
  block.textures[TextureMenu.getSelectedFace()] = TextureMenu.getSelectedTexture()
  self.blocks[key] = block
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
    lovr.math.vec3(0.5, self.gridHeight, 0.5),
    lovr.math.vec3(0, 1, 0)
  )
  
  if hitPoint then
    local gx, gy, gz = utils.worldToGrid(hitPoint.x, hitPoint.y, hitPoint.z)
    self.cursorPosition = {x = gx, y = self.gridHeight + 0.5, z = gz}
    self.hitPoint = hitPoint  -- Store the actual hit point for drawing the dot
    
    -- Only show preview if there's no block at this position at the current grid height
    local key = utils.getBlockKey(gx, self.gridHeight + 0.5, gz)
    if not self.blocks[key] then
      self.previewPosition = self.cursorPosition
    else
      self.previewPosition = nil
    end
  else
    self.cursorPosition = nil
    self.previewPosition = nil
    self.hitPoint = nil
  end
end

function World:draw(pass)
  -- Draw grid lines
  pass:setColor(1, 1, 1, 0.3)
  pass:plane(0.5, self.gridHeight, 0.5, 20, 20, -math.pi / 2, 1, 0, 0, 'line', 20, 20)
  
  -- Draw blocks
  pass:setColor(1, 1, 1)
  for key, block in pairs(self.blocks) do
    -- Use stored coordinates directly to match preview position exactly
    local x, y, z = block.x, block.y, block.z
    
    -- Front face (facing positive Z)
    if block.textures.front then
      pass:setMaterial(block.textures.front)
      pass:plane(x, y, z + 0.5, 1, 1)
    end
    
    -- Back face (facing negative Z)
    if block.textures.back then
      pass:setMaterial(block.textures.back)
      pass:plane(x, y, z - 0.5, 1, 1, math.pi, 0, 1, 0)
    end
    
    -- Left face (facing negative X)
    if block.textures.left then
      pass:setMaterial(block.textures.left)
      pass:plane(x - 0.5, y, z, 1, 1, math.pi/2, 0, 1, 0)
    end
    
    -- Right face (facing positive X)
    if block.textures.right then
      pass:setMaterial(block.textures.right)
      pass:plane(x + 0.5, y, z, 1, 1, -math.pi/2, 0, 1, 0)
    end
    
    -- Top face (facing positive Y)
    if block.textures.top then
      pass:setMaterial(block.textures.top)
      pass:plane(x, y + 0.5, z, 1, 1, -math.pi/2, 1, 0, 0)
    end
    
    -- Bottom face (facing negative Y)
    if block.textures.bottom then
      pass:setMaterial(block.textures.bottom)
      pass:plane(x, y - 0.5, z, 1, 1, math.pi/2, 1, 0, 0)
    end
  end
  pass:setMaterial()
  
  -- Draw preview cube with current texture
  if self.previewPosition then
    pass:setColor(1, 1, 1, 0.5)
    local x, y, z = self.previewPosition.x, self.previewPosition.y, self.previewPosition.z
    local selectedFace = TextureMenu.getSelectedFace()
    local texture = TextureMenu.getSelectedTexture()
    
    -- Draw semi-transparent faces for all sides
    pass:setColor(0.5, 0.5, 0.5, 0.2)
    -- Front face (facing positive Z)
    pass:plane(x, y, z + 0.5, 1, 1)
    -- Back face (facing negative Z)
    pass:plane(x, y, z - 0.5, 1, 1, math.pi, 0, 1, 0)
    -- Left face (facing negative X)
    pass:plane(x - 0.5, y, z, 1, 1, math.pi/2, 0, 1, 0)
    -- Right face (facing positive X)
    pass:plane(x + 0.5, y, z, 1, 1, -math.pi/2, 0, 1, 0)
    -- Top face (facing positive Y)
    pass:plane(x, y + 0.5, z, 1, 1, -math.pi/2, 1, 0, 0)
    -- Bottom face (facing negative Y)
    pass:plane(x, y - 0.5, z, 1, 1, math.pi/2, 1, 0, 0)
    
    -- Highlight selected face with texture or solid color
    pass:setColor(1, 1, 1, 0.5)
    if texture then
      pass:setMaterial(texture)
    end
    
    -- Draw the selected face
    if selectedFace == 'front' then
      pass:plane(x, y, z + 0.5, 1, 1)
    elseif selectedFace == 'back' then
      pass:plane(x, y, z - 0.5, 1, 1, math.pi, 0, 1, 0)
    elseif selectedFace == 'left' then
      pass:plane(x - 0.5, y, z, 1, 1, math.pi/2, 0, 1, 0)
    elseif selectedFace == 'right' then
      pass:plane(x + 0.5, y, z, 1, 1, -math.pi/2, 0, 1, 0)
    elseif selectedFace == 'top' then
      pass:plane(x, y + 0.5, z, 1, 1, -math.pi/2, 1, 0, 0)
    elseif selectedFace == 'bottom' then
      pass:plane(x, y - 0.5, z, 1, 1, math.pi/2, 1, 0, 0)
    end
    
    if texture then
      pass:setMaterial()
    end
  end
  -- Draw hit point dot (red)
  if self.hitPoint then
    pass:setColor(1, 0, 0, 1)
    pass:sphere(self.hitPoint.x, self.hitPoint.y, self.hitPoint.z, 0.05)
  end
end

return World
