local Block = {
    -- Position in world space (center of block base)
    position = nil,
    
    -- Corner heights (0 = base, 1 = full height)
    -- Ordered: -x-z, +x-z, -x+z, +x+z (counter-clockwise from back left)
    vertices = {0, 0, 0, 0},
    
    -- Standard block dimensions
    width = 1,
    depth = 1,
    height = 1,
    
    -- Height levels available (0, 0.33, 0.66, 1)
    heightLevels = {0, 0.33, 0.66, 1}
}

function Block:new(x, y, z)
    local block = setmetatable({}, { __index = Block })
    block.position = lovr.math.newVec3(x, y, z)
    block.vertices = {0, 0, 0, 0}  -- Initialize vertices array
    return block
end

function Block:setVertexHeight(index, level)
    -- level should be 1-4 (representing the 4 possible heights)
    if index >= 1 and index <= 4 and level >= 1 and level <= 4 then
        self.vertices[index] = self.heightLevels[level]
    end
end

function Block:getCornerPosition(index)
    -- Determine X offset: +0.5 for vertices 2 and 4, -0.5 for vertices 1 and 3
    local xOffset = ((index == 2) or (index == 4)) and 0.5 or -0.5
    -- Determine Z offset: +0.5 for vertices 3 and 4, -0.5 for vertices 1 and 2
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