local utils = require('utils')

local World = {}
World.__index = World

function World.new()
  local self = setmetatable({}, World)
  self.blocks = {} -- Store placed blocks: key = "x,y,z", value = true
  self.gridSize = 10
  self.previewPosition = nil
  return self
end

function World:placeBlock(x, y, z)
  local key = utils.getBlockKey(x, y, z)
  self.blocks[key] = true
end

function World:removeBlock(x, y, z)
  local key = utils.getBlockKey(x, y, z)
  self.blocks[key] = nil
end

function World:updatePreview(camera, mouseX, mouseY)
  local origin, direction = camera:screenToWorldRay(mouseX, mouseY)
  local hitPoint = utils.rayPlaneIntersection(
    origin,
    direction,
    lovr.math.vec3(0, 0, 0),
    lovr.math.vec3(0, 1, 0)
  )
  
  if hitPoint then
    local gx, gy, gz = utils.worldToGrid(hitPoint.x, hitPoint.y, hitPoint.z)
    self.previewPosition = {x = gx, y = 0.5, z = gz}
  else
    self.previewPosition = nil
  end
end

function World:draw(pass)
  -- Draw grid
  -- Draw a solid dark plane first
  pass:setColor(0.1, 0.1, 0.12)
  pass:plane(0, 0, 0, 20, 20, -math.pi / 2, 1, 0, 0)
  -- Draw grid lines on top
  pass:setColor(0.2, 0.2, 0.25)
  pass:plane(0, 0.001, 0, 20, 20, -math.pi / 2, 1, 0, 0, 'line', 20, 20)
  
  -- Draw blocks
  pass:setColor(1, 0.7, 0.3)
  for key in pairs(self.blocks) do
    local x, y, z = string.match(key, "(-?%d+),(-?%d+),(-?%d+)")
    pass:box(tonumber(x), tonumber(y), tonumber(z), 1, 1, 1)
  end
  
  -- Draw preview cube
  if self.previewPosition then
    pass:setColor(1, 1, 1, 0.5) -- Semi-transparent white
    pass:setWireframe(true)
    pass:box(self.previewPosition.x, self.previewPosition.y, self.previewPosition.z, 1, 1, 1)
    pass:setWireframe(false)
  end
end

return World
