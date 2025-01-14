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
    
    -- Face vertex mappings (which vertices belong to each face)
    faceVertices = {
        front = {3, 4},   -- -x+z, +x+z
        back = {1, 2},    -- -x-z, +x-z
        left = {1, 3},    -- -x-z, -x+z
        right = {2, 4},   -- +x-z, +x+z
        top = {1, 2, 3, 4}, -- all vertices
        bottom = {}       -- bottom face has no adjustable vertices
    },

    -- Store textures for each face
    faceTextures = nil,  -- Will store textures for all 6 faces
    faceTextureInfos = nil  -- Will store texture info for all 6 faces
}

function Block:new(x, y, z, texture, textureInfo)
    local block = setmetatable({}, { __index = Block })
    block.position = lovr.math.newVec3(x, y, z)
    block.vertices = {1, 1, 1, 1}  -- Initialize all vertices at full height
    block.faceTextures = {}
    block.faceTextureInfos = {}
    
    -- Initialize all faces with the provided texture if any
    if texture and textureInfo then
        local faces = {"front", "back", "left", "right", "top", "bottom"}
        for _, face in ipairs(faces) do
            block.faceTextures[face] = texture
            block.faceTextureInfos[face] = textureInfo
        end
    end
    return block
end

function Block:getVertexLevel(index)
    -- Convert height back to level (1-4)
    local height = self.vertices[index]
    for level, levelHeight in ipairs(self.heightLevels) do
        if height == levelHeight then
            return level
        end
    end
    return 1  -- Default to full height if not found
end

function Block:setVertexHeight(index, level)
    -- level should be 1-4 (1 = full height, 4 = lowest)
    if index >= 1 and index <= 4 and level >= 1 and level <= 4 then
        self.vertices[index] = self.heightLevels[level]
    end
end

function Block:getFaceVertices(face)
    return self.faceVertices[face]
end

function Block:moveFaceVertices(face, direction)
    -- direction: 1 for up, -1 for down
    if face == "bottom" then return end -- Can't move bottom face
    
    local vertices = self.faceVertices[face]
    if not vertices then return end
    
    -- Get current minimum level among face vertices
    local minLevel = 1
    local maxLevel = 4
    for _, vertexIndex in ipairs(vertices) do
        local level = self:getVertexLevel(vertexIndex)
        minLevel = math.max(minLevel, level)
        maxLevel = math.min(maxLevel, level)
    end
    
    -- Calculate new level ensuring we stay within bounds
    local newLevel
    if direction > 0 then -- Moving up
        newLevel = math.max(1, minLevel - 1)
    else -- Moving down
        newLevel = math.min(4, maxLevel + 1)
    end
    
    -- Apply new height to all vertices of the face
    for _, vertexIndex in ipairs(vertices) do
        self:setVertexHeight(vertexIndex, newLevel)
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

function Block:drawFace(pass, v1, v2, v3, v4, normal, faceName, isHovered, selectedFaces)
    -- Check if this face is selected
    local isSelected = false
    if selectedFaces then
        for _, faceInfo in ipairs(selectedFaces) do
            if faceInfo.block == self and faceInfo.face == faceName then
                isSelected = true
                break
            end
        end
    end
    
    local isHighlighted = isHovered or isSelected
    local faceTexture = self.faceTextures[faceName]
    local center = (v1 + v2 + v3 + v4) / 4
    local width = vec3(v2 - v1):length()
    local height = vec3(v3 - v1):length()

    -- First, draw the textured face
    if faceTexture then
        pass:setColor(1, 1, 1, 1)  -- Full opacity for texture
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
    
    -- Then, draw highlight overlay if needed
    if isHighlighted then
        pass:setColor(1, 1, 0, 0.1)  -- Yellow semi-transparent highlight
        pass:push()
        -- Offset center slightly in the direction of the normal
        local highlightCenter = center + normal * 0.001
        pass:translate(highlightCenter)
        
        if normal.x ~= 0 then
            pass:rotate(normal.x > 0 and math.pi/2 or -math.pi/2, 0, 1, 0)
        elseif normal.z ~= 0 then
            pass:rotate(normal.z > 0 and math.pi or 0, 0, 1, 0)
        elseif normal.y ~= 0 then
            pass:rotate(normal.y > 0 and -math.pi/2 or math.pi/2, 1, 0, 0)
        end
        
        pass:plane(0, 0, 0, width, height)  -- No need for additional z-offset since we moved the center
        pass:pop()
    end
    
    -- Finally, draw wireframe outline
    pass:setColor(isHighlighted and 1 or 1, isHighlighted and 1 or 1, isHighlighted and 0 or 1, 1)
    pass:line(v1, v2)
    pass:line(v2, v4)
    pass:line(v4, v3)
    pass:line(v3, v1)
end

function Block:draw(pass, hoveredFace, selectedFaces)
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
                 vec3(0, -1, 0), "bottom", hoveredFace == "bottom", selectedFaces)
    
    -- Top face
    self:drawFace(pass, corners[1], corners[2], corners[3], corners[4],
                 vec3(0, 1, 0), "top", hoveredFace == "top", selectedFaces)
    
    -- Side faces
    self:drawFace(pass, corners[1], corners[2], bottomCorners[1], bottomCorners[2],
                 vec3(0, 0, -1), "back", hoveredFace == "back", selectedFaces)
    self:drawFace(pass, corners[2], corners[4], bottomCorners[2], bottomCorners[4],
                 vec3(1, 0, 0), "right", hoveredFace == "right", selectedFaces)
    self:drawFace(pass, corners[4], corners[3], bottomCorners[4], bottomCorners[3],
                 vec3(0, 0, 1), "front", hoveredFace == "front", selectedFaces)
    self:drawFace(pass, corners[3], corners[1], bottomCorners[3], bottomCorners[1],
                 vec3(-1, 0, 0), "left", hoveredFace == "left", selectedFaces)
end

function Block:drawHighlight(pass)
    -- Draw slightly larger box around the block for highlighting
    local scale = 1.02  -- Make highlight slightly bigger than block
    local x, y, z = self.position:unpack()
    pass:box(x, y + 0.5, z, scale, scale, scale)
end

function Block:setTexture(texture, textureInfo)
    -- Set the same texture for all faces
    local faces = {"front", "back", "left", "right", "top", "bottom"}
    for _, face in ipairs(faces) do
        self:setFaceTexture(face, texture, textureInfo)
    end
end

function Block:setFaceTexture(face, texture, textureInfo)
    if not self.faceTextures then
        self.faceTextures = {}
    end
    if not self.faceTextureInfos then
        self.faceTextureInfos = {}
    end
    self.faceTextures[face] = texture
    self.faceTextureInfos[face] = textureInfo
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
