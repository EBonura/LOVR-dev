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
    heightLevels = {1, 0.66, 0.33, 0},

    -- Texture for all faces (we'll expand this to per-face later)
    texture = nil
}

function Block:new(x, y, z, texture)
    local block = setmetatable({}, { __index = Block })
    block.position = lovr.math.newVec3(x, y, z)
    block.vertices = {1, 1, 1, 1}  -- Initialize all vertices at full height
    block.texture = texture
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

function Block:drawFace(pass, v1, v2, v3, v4, normal)
    if self.texture then
        local center = (v1 + v2 + v3 + v4) / 4
        local width = vec3(v2 - v1):length()
        local height = vec3(v3 - v1):length()
        
        pass:setMaterial(self.texture)
        pass:push()
        pass:translate(center)
        
        -- Rotate based on the provided normal
        if normal.x ~= 0 then
            pass:rotate(normal.x > 0 and math.pi/2 or -math.pi/2, 0, 1, 0)
        elseif normal.z ~= 0 then
            pass:rotate(normal.z > 0 and math.pi or 0, 0, 1, 0)
        elseif normal.y ~= 0 then
            pass:rotate(normal.y > 0 and -math.pi/2 or math.pi/2, 1, 0, 0)
        end
        
        pass:plane(0, 0, 0, width, height)
        pass:pop()
        pass:setMaterial()
    end
    
    -- Draw wireframe outline
    pass:setColor(1, 1, 1, 1)
    pass:line(v1, v2)
    pass:line(v2, v4)
    pass:line(v4, v3)
    pass:line(v3, v1)
end

function Block:draw(pass)
    -- Get all corner positions
    local corners = {}
    for i = 1, 4 do
        corners[i] = vec3(self:getCornerPosition(i))
    end
    
    -- Get bottom corners
    local bottomCorners = {
        vec3(corners[1].x, self.position.y, corners[1].z),
        vec3(corners[2].x, self.position.y, corners[2].z),
        vec3(corners[3].x, self.position.y, corners[3].z),
        vec3(corners[4].x, self.position.y, corners[4].z)
    }
    
    -- Draw faces with proper normals
    -- Bottom face
    self:drawFace(pass, bottomCorners[1], bottomCorners[2], bottomCorners[3], bottomCorners[4], vec3(0, -1, 0))
    
    -- Top face
    self:drawFace(pass, corners[1], corners[2], corners[3], corners[4], vec3(0, 1, 0))
    
    -- Side faces
    self:drawFace(pass, corners[1], corners[2], bottomCorners[1], bottomCorners[2], vec3(0, 0, -1))  -- back
    self:drawFace(pass, corners[2], corners[4], bottomCorners[2], bottomCorners[4], vec3(1, 0, 0))   -- right
    self:drawFace(pass, corners[4], corners[3], bottomCorners[4], bottomCorners[3], vec3(0, 0, 1))   -- front
    self:drawFace(pass, corners[3], corners[1], bottomCorners[3], bottomCorners[1], vec3(-1, 0, 0))  -- left
end

function Block:drawHighlight(pass)
    -- Draw slightly larger box around the block for highlighting
    local scale = 1.02  -- Make highlight slightly bigger than block
    local x, y, z = self.position:unpack()
    pass:box(x, y + 0.5, z, scale, scale, scale)
end

return Block