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
    
    -- Calculate face height percentage for UV adjustment
    local heightPercentage
    if normal.y ~= 0 then
        -- For top/bottom faces, use average height of all corners
        heightPercentage = 1.0  -- Top/bottom faces don't deform vertically
    else
        -- For side faces, calculate based on the actual height of the face
        local height = math.abs(v1.y - v3.y)
        heightPercentage = height  -- Original height is 1.0
    end
    
    -- Adjust UV coordinates based on height
    local v1UV = { 0, 0 }
    local v2UV = { 1, 0 }
    local v3UV = { 0, heightPercentage }
    local v4UV = { 1, heightPercentage }
    
    local format = {
        { 'VertexPosition', 'vec3' },
        { 'VertexNormal', 'vec3' },
        { 'VertexUV', 'vec2' }
    }
    
    -- Enable backface culling
    pass:setCullMode('back')
    
    -- Create vertices with proper winding order based on face normal
    local vertices
    if normal.y > 0 then  -- Top face
        -- Counter-clockwise when viewed from above
        vertices = {
            -- First triangle (v1, v3, v2)
            { v1.x, v1.y, v1.z, normal.x, normal.y, normal.z, v1UV[1], v1UV[2] },
            { v3.x, v3.y, v3.z, normal.x, normal.y, normal.z, v3UV[1], v3UV[2] },
            { v2.x, v2.y, v2.z, normal.x, normal.y, normal.z, v2UV[1], v2UV[2] },
            -- Second triangle (v2, v3, v4)
            { v2.x, v2.y, v2.z, normal.x, normal.y, normal.z, v2UV[1], v2UV[2] },
            { v3.x, v3.y, v3.z, normal.x, normal.y, normal.z, v3UV[1], v3UV[2] },
            { v4.x, v4.y, v4.z, normal.x, normal.y, normal.z, v4UV[1], v4UV[2] }
        }
    else  -- All other faces
        vertices = {
            -- First triangle (v1, v2, v3)
            { v1.x, v1.y, v1.z, normal.x, normal.y, normal.z, v1UV[1], v1UV[2] },
            { v2.x, v2.y, v2.z, normal.x, normal.y, normal.z, v2UV[1], v2UV[2] },
            { v3.x, v3.y, v3.z, normal.x, normal.y, normal.z, v3UV[1], v3UV[2] },
            -- Second triangle (v2, v4, v3)
            { v2.x, v2.y, v2.z, normal.x, normal.y, normal.z, v2UV[1], v2UV[2] },
            { v4.x, v4.y, v4.z, normal.x, normal.y, normal.z, v4UV[1], v4UV[2] },
            { v3.x, v3.y, v3.z, normal.x, normal.y, normal.z, v3UV[1], v3UV[2] }
        }
    end
    
    local mesh = lovr.graphics.newMesh(format, vertices)

    -- Draw the textured face
    if faceTexture then
        pass:setColor(1, 1, 1, 1)
        pass:setSampler('nearest')
        pass:setMaterial(faceTexture)
        pass:draw(mesh)
        pass:setMaterial()
    end
    
    -- Draw highlight overlay if needed
    if isHighlighted then
        -- Create a slightly offset version of the vertices for highlighting
        local offset = 0.001
        local highlightVertices = {}
        
        -- Copy vertices and apply offset
        for i = 1, #vertices do
            local v = vertices[i]
            table.insert(highlightVertices, {
                v[1] + normal.x * offset,
                v[2] + normal.y * offset,
                v[3] + normal.z * offset,
                v[4], v[5], v[6],  -- normal
                v[7], v[8]         -- UV
            })
        end
        
        local highlightMesh = lovr.graphics.newMesh(format, highlightVertices)
        pass:setColor(1, 1, 0, 0.1)  -- Yellow semi-transparent highlight
        pass:draw(highlightMesh)
    end
    
    -- Draw wireframe outline
    pass:setColor(isHighlighted and 1 or 1, isHighlighted and 1 or 1, isHighlighted and 0 or 1, 1)
    pass:line(v1, v2)
    pass:line(v2, v4)
    pass:line(v4, v3)
    pass:line(v3, v1)
    
    -- Reset cull mode
    pass:setCullMode('none')
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
        -- Get vertices for this face
        local vertices = self.faceVertices[face.name]
        if vertices then
            -- Calculate average position of face vertices to get center point
            local centerPoint = vec3(0, 0, 0)
            local vertexCount = #vertices
            
            if face.name == "top" then
                -- For top face, use actual vertex heights
                for _, vIndex in ipairs(vertices) do
                    local x, y, z = self:getCornerPosition(vIndex)
                    centerPoint:add(vec3(x, y, z))
                end
                centerPoint:mul(1/vertexCount)
            elseif face.name == "bottom" then
                -- For bottom face, use base height
                local baseY = self.position.y
                local x1, _, z1 = self:getCornerPosition(1)
                local x2, _, z2 = self:getCornerPosition(2)
                local x3, _, z3 = self:getCornerPosition(3)
                local x4, _, z4 = self:getCornerPosition(4)
                centerPoint = vec3((x1 + x2 + x3 + x4)/4, baseY, (z1 + z2 + z3 + z4)/4)
            else
                -- For side faces, calculate center based on actual vertex positions
                local v1Index, v2Index = vertices[1], vertices[2]
                local x1, y1, z1 = self:getCornerPosition(v1Index)
                local x2, y2, z2 = self:getCornerPosition(v2Index)
                -- Use actual heights for the face center
                centerPoint = vec3((x1 + x2)/2, (y1 + y2)/2, (z1 + z2)/2)
            end
            
            -- Check for intersection with plane defined by face
            local denom = rayDir:dot(face.normal)
            if math.abs(denom) > 0.0001 then
                local t = (centerPoint - rayStart):dot(face.normal) / denom
                if t > 0 and t < closestT then
                    -- Calculate intersection point
                    local hitPoint = rayStart + rayDir * t
                    local inBounds = true
                    
                    -- Check bounds based on face orientation
                    if face.name == "front" or face.name == "back" then
                        local y1 = self:getCornerPosition(vertices[1])
                        local _, y2 = self:getCornerPosition(vertices[2])
                        local minY = math.min(y1, y2)
                        local maxY = math.max(y1, y2)
                        inBounds = math.abs(hitPoint.x - self.position.x) <= 0.5 and
                                  hitPoint.y >= minY and
                                  hitPoint.y <= maxY
                    elseif face.name == "left" or face.name == "right" then
                        local _, y1 = self:getCornerPosition(vertices[1])
                        local _, y2 = self:getCornerPosition(vertices[2])
                        local minY = math.min(y1, y2)
                        local maxY = math.max(y1, y2)
                        inBounds = math.abs(hitPoint.z - self.position.z) <= 0.5 and
                                  hitPoint.y >= minY and
                                  hitPoint.y <= maxY
                    elseif face.name == "top" then
                        -- For top face, check if point is within the deformed face boundary
                        local corners = {}
                        for _, vIndex in ipairs(vertices) do
                            local x, _, z = self:getCornerPosition(vIndex)
                            table.insert(corners, {x = x, z = z})
                        end
                        -- Simple point-in-polygon check for rectangular face
                        local minX = math.huge
                        local maxX = -math.huge
                        local minZ = math.huge
                        local maxZ = -math.huge
                        for _, corner in ipairs(corners) do
                            minX = math.min(minX, corner.x)
                            maxX = math.max(maxX, corner.x)
                            minZ = math.min(minZ, corner.z)
                            maxZ = math.max(maxZ, corner.z)
                        end
                        inBounds = hitPoint.x >= minX and hitPoint.x <= maxX and
                                 hitPoint.z >= minZ and hitPoint.z <= maxZ
                    else -- bottom face
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
    end
    
    return closestFace, closestT
end

return Block
