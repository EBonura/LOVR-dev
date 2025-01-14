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

    -- Texture for all faces (default texture)
    texture = nil,
    
    -- Per-face textures
    faceTextures = nil  -- Will be initialized when needed
}

function Block:new(x, y, z, texture)
    local block = setmetatable({}, { __index = Block })
    block.position = lovr.math.newVec3(x, y, z)
    block.vertices = {1, 1, 1, 1}  -- Initialize all vertices at full height
    block.texture = texture
    block.faceTextures = {}  -- Initialize empty face textures table
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

function Block:drawFace(pass, v1, v2, v3, v4, normal, faceName, isHighlighted)
    local faceTexture = self.faceTextures[faceName] or self.texture
    
    -- Draw highlighted face background if needed
    if isHighlighted then
        pass:setColor(1, 1, 0, 0.3)  -- Yellow semi-transparent highlight
        local center = (v1 + v2 + v3 + v4) / 4
        local width = vec3(v2 - v1):length()
        local height = vec3(v3 - v1):length()
        
        pass:push()
        pass:translate(center)
        
        if normal.x ~= 0 then
            pass:rotate(normal.x > 0 and math.pi/2 or -math.pi/2, 0, 1, 0)
        elseif normal.z ~= 0 then
            pass:rotate(normal.z > 0 and math.pi or 0, 0, 1, 0)
        elseif normal.y ~= 0 then
            pass:rotate(normal.y > 0 and -math.pi/2 or math.pi/2, 1, 0, 0)
        end
        
        pass:plane(0, 0, 0.001, width, height)  -- Slight offset to avoid z-fighting
        pass:pop()
    end

    -- Draw textured face
    if faceTexture then
        local center = (v1 + v2 + v3 + v4) / 4
        local width = vec3(v2 - v1):length()
        local height = vec3(v3 - v1):length()
        
        pass:setMaterial(faceTexture)
        pass:push()
        pass:translate(center)
        
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
    
    -- Draw wireframe outline with proper color components
    pass:setColor(isHighlighted and 1 or 1, isHighlighted and 1 or 1, isHighlighted and 0 or 1, 1)
    pass:line(v1, v2)
    pass:line(v2, v4)
    pass:line(v4, v3)
    pass:line(v3, v1)
end

function Block:draw(pass, hoveredFace, selectedFace)
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
    self:drawFace(pass, bottomCorners[1], bottomCorners[2], bottomCorners[3], bottomCorners[4],
                 vec3(0, -1, 0), "bottom", hoveredFace == "bottom" or selectedFace == "bottom")
    
    -- Top face
    self:drawFace(pass, corners[1], corners[2], corners[3], corners[4],
                 vec3(0, 1, 0), "top", hoveredFace == "top" or selectedFace == "top")
    
    -- Side faces
    self:drawFace(pass, corners[1], corners[2], bottomCorners[1], bottomCorners[2],
                 vec3(0, 0, -1), "back", hoveredFace == "back" or selectedFace == "back")
    self:drawFace(pass, corners[2], corners[4], bottomCorners[2], bottomCorners[4],
                 vec3(1, 0, 0), "right", hoveredFace == "right" or selectedFace == "right")
    self:drawFace(pass, corners[4], corners[3], bottomCorners[4], bottomCorners[3],
                 vec3(0, 0, 1), "front", hoveredFace == "front" or selectedFace == "front")
    self:drawFace(pass, corners[3], corners[1], bottomCorners[3], bottomCorners[1],
                 vec3(-1, 0, 0), "left", hoveredFace == "left" or selectedFace == "left")
end

function Block:drawHighlight(pass)
    -- Draw slightly larger box around the block for highlighting
    local scale = 1.02  -- Make highlight slightly bigger than block
    local x, y, z = self.position:unpack()
    pass:box(x, y + 0.5, z, scale, scale, scale)
end

function Block:setTexture(texture)
    self.texture = texture
    self.faceTextures = {}  -- Reset face-specific textures
end

function Block:setFaceTexture(face, texture)
    if not self.faceTextures then
        self.faceTextures = {}
    end
    self.faceTextures[face] = texture
end

function Block:intersectFace(rayStart, rayDir)
    local faces = {
        {name = "front",  normal = vec3(0, 0, 1)},
        {name = "back",   normal = vec3(0, 0, -1)},
        {name = "left",   normal = vec3(-1, 0, 0)},
        {name = "right",  normal = vec3(1, 0, 0)},
        {name = "top",    normal = vec3(0, 1, 0)},
        {name = "bottom", normal = vec3(0, -1, 0)}
    }
    
    local closestFace = nil
    local closestT = math.huge
    
    for _, face in ipairs(faces) do
        -- Calculate intersection with face plane
        local planePoint = vec3(self.position)
        if face.name == "front" then
            planePoint.z = planePoint.z + 0.5
        elseif face.name == "back" then
            planePoint.z = planePoint.z - 0.5
        elseif face.name == "left" then
            planePoint.x = planePoint.x - 0.5
        elseif face.name == "right" then
            planePoint.x = planePoint.x + 0.5
        elseif face.name == "top" then
            planePoint.y = planePoint.y + 0.5
        elseif face.name == "bottom" then
            planePoint.y = planePoint.y - 0.5
        end
        
        -- Check for intersection
        local denom = rayDir:dot(face.normal)
        if math.abs(denom) > 0.0001 then
            local t = (planePoint - rayStart):dot(face.normal) / denom
            if t > 0 and t < closestT then
                -- Check if intersection point is within face bounds
                local hitPoint = rayStart + rayDir * t
                local inBounds = true
                
                -- Check bounds based on face
                if face.name == "front" or face.name == "back" then
                    inBounds = math.abs(hitPoint.x - self.position.x) <= 0.5 and
                              math.abs(hitPoint.y - self.position.y) <= 0.5
                elseif face.name == "left" or face.name == "right" then
                    inBounds = math.abs(hitPoint.z - self.position.z) <= 0.5 and
                              math.abs(hitPoint.y - self.position.y) <= 0.5
                else  -- top or bottom
                    inBounds = math.abs(hitPoint.x - self.position.x) <= 0.5 and
                              math.abs(hitPoint.z - self.position.z) <= 0.5
                end
                
                if inBounds then
                    closestT = t
                    closestFace = face.name
                end
            end
        end
    end
    
    return closestFace, closestT
end

return Block