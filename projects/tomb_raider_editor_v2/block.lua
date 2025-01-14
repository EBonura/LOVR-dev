local Block = {
    -- Position in world space (center of block base)
    position = nil,
    
    -- Corner heights (1 = full height, lower values pull down)
    -- Ordered: -x-z, +x-z, -x+z, +x+z (counter-clockwise from back left)
    vertices = {1, 1, 1, 1},  -- Start at full height
    
    -- Standard block dimensions
    width = 1,
    depth = 1,
    height = 1,
    
    -- Height levels available (1 = full height, going down)
    heightLevels = {1, 0.66, 0.33, 0}
}

function Block:new(x, y, z)
    local block = setmetatable({}, { __index = Block })
    block.position = lovr.math.newVec3(x, y, z)
    block.vertices = {1, 1, 1, 1}  -- Initialize all vertices at full height
    return block
end

function Block:setVertexHeight(index, level)
    -- level should be 1-4 (1 = full height, 4 = lowest)
    if index >= 1 and index <= 4 and level >= 1 and level <= 4 then
        self.vertices[index] = self.heightLevels[level]
    end
end

function Block:getCornerPosition(index)
    -- Define offsets for a 1x1 block (±0.5 in each direction)
    local xOffset = ((index == 2) or (index == 4)) and 0.5 or -0.5
    local zOffset = ((index == 3) or (index == 4)) and 0.5 or -0.5
    
    return self.position.x + xOffset,
           self.position.y + (self.vertices[index] * self.height),
           self.position.z + zOffset
end

function Block:draw(pass)
    -- Draw wireframe for now to visualize the structure
    pass:setColor(1, 1, 1, 1)
    
    -- Draw vertical lines at corners
    for i = 1, 4 do
        local x, y, z = self:getCornerPosition(i)
        pass:line(
            x, self.position.y, z,  -- Base
            x, y, z                 -- Top
        )
    end
    
    -- Draw base rectangle
    local x1, _, z1 = self:getCornerPosition(1)
    local x2, _, z2 = self:getCornerPosition(2)
    local x3, _, z3 = self:getCornerPosition(3)
    local x4, _, z4 = self:getCornerPosition(4)
    
    pass:line(x1, self.position.y, z1, x2, self.position.y, z2)
    pass:line(x2, self.position.y, z2, x4, self.position.y, z4)
    pass:line(x4, self.position.y, z4, x3, self.position.y, z3)
    pass:line(x3, self.position.y, z3, x1, self.position.y, z1)
    
    -- Draw top edges
    local _, y1, _ = self:getCornerPosition(1)
    local _, y2, _ = self:getCornerPosition(2)
    local _, y3, _ = self:getCornerPosition(3)
    local _, y4, _ = self:getCornerPosition(4)
    
    pass:line(x1, y1, z1, x2, y2, z2)
    pass:line(x2, y2, z2, x4, y4, z4)
    pass:line(x4, y4, z4, x3, y3, z3)
    pass:line(x3, y3, z3, x1, y1, z1)
end

return Block