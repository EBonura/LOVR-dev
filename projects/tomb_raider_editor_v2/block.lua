local Block = {
    -- Position in world space (base position)
    position = nil,
    
    -- Heights for each vertex in world units (no longer normalized 0-1)
    -- Can be any value >= 0, adjusts in increments of 0.25
    -- Ordered: (top vertices) -x-z, +x-z, -x+z, +x+z, (bottom vertices) -x-z, +x-z, -x+z, +x+z
    vertices = {1, 1, 1, 1, 0, 0, 0, 0},  -- Start with flat top at height 1, bottom at height 0
    
    -- Block x/z dimensions (always 1x1)
    width = 1,
    depth = 1,
    
    -- Height increment for adjustments
    heightIncrement = 0.25,
    
    -- Face vertex mappings (which vertices each face uses)
    faceVertices = {
        front = {3, 4, 7, 8},   -- -x+z, +x+z for both top and bottom
        back = {1, 2, 5, 6},    -- -x-z, +x-z for both top and bottom
        left = {1, 3, 5, 7},    -- -x-z, -x+z for both top and bottom
        right = {2, 4, 6, 8},   -- +x-z, +x+z for both top and bottom
        top = {1, 2, 3, 4},     -- top 4 vertices
        bottom = {5, 6, 7, 8}   -- bottom 4 vertices
    },

    -- Store textures for each face
    faceTextures = nil,
    faceTextureInfos = nil
}

function Block:new(x, y, z, texture, textureInfo)
    local block = setmetatable({}, { __index = Block })
    block.position = lovr.math.newVec3(x, y, z)
    block.vertices = {1, 1, 1, 1, 0, 0, 0, 0}  -- Initialize with flat top and bottom
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

function Block:getFaceVertices(face)
    return self.faceVertices[face]
end

function Block:moveFaceVertices(face, direction)
    local vertices = self.faceVertices[face]
    if not vertices then return end
    
    -- Calculate height adjustment
    local heightChange = direction * self.heightIncrement
    
    -- Adjust vertex heights directly for all vertices in the face
    for _, vertexIndex in ipairs(vertices) do
        -- Don't allow vertices to go below 0
        local newHeight = self.vertices[vertexIndex] + heightChange
        if newHeight >= 0 then
            self.vertices[vertexIndex] = newHeight
        end
    end
end

function Block:getCornerPosition(index)
    -- Define offsets for a 1x1 block (±0.5 in each direction)
    local xOffset = ((index == 2) or (index == 4) or (index == 6) or (index == 8)) and 0.5 or -0.5
    local zOffset = ((index == 3) or (index == 4) or (index == 7) or (index == 8)) and 0.5 or -0.5
    
    -- Return absolute world position
    return self.position.x + xOffset,
           self.position.y + self.vertices[index],
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
        heightPercentage = 1.0  -- Faces that aren't vertical don't deform UVs
    else
        -- For side faces, calculate based on the actual height
        local height = math.max(math.abs(v1.y - v3.y), math.abs(v2.y - v4.y))
        heightPercentage = height
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
    for i = 1, 8 do  -- Now get all 8 corners
        corners[i] = vec3(self:getCornerPosition(i))
    end
    
    -- Draw faces with proper vertex order
    -- Draw faces with corresponding vertices
    -- Top face (1,2,3,4)
    self:drawFace(pass, corners[1], corners[2], corners[3], corners[4],
                 vec3(0, 1, 0), "top", hoveredFace == "top", selectedFaces)
    
    -- Bottom face (5,6,7,8)
    self:drawFace(pass, corners[5], corners[6], corners[7], corners[8],
                 vec3(0, -1, 0), "bottom", hoveredFace == "bottom", selectedFaces)
    
    -- Front face (3,4,7,8)
    self:drawFace(pass, corners[3], corners[4], corners[7], corners[8],
                 vec3(0, 0, 1), "front", hoveredFace == "front", selectedFaces)
    
    -- Back face (1,2,5,6)
    self:drawFace(pass, corners[1], corners[2], corners[5], corners[6],
                 vec3(0, 0, -1), "back", hoveredFace == "back", selectedFaces)
    
    -- Left face (1,3,5,7)
    self:drawFace(pass, corners[1], corners[3], corners[5], corners[7],
                 vec3(-1, 0, 0), "left", hoveredFace == "left", selectedFaces)
    
    -- Right face (2,4,6,8)
    self:drawFace(pass, corners[2], corners[4], corners[6], corners[8],
                 vec3(1, 0, 0), "right", hoveredFace == "right", selectedFaces)
end

function Block:rotate(direction)
    -- direction should be 1 for clockwise, -1 for counterclockwise
    
    -- Rotate top vertices (1-4)
    if direction == 1 then
        -- Clockwise rotation for top vertices
        local temp = self.vertices[1]
        self.vertices[1] = self.vertices[3]
        self.vertices[3] = self.vertices[4]
        self.vertices[4] = self.vertices[2]
        self.vertices[2] = temp
        
        -- Clockwise rotation for bottom vertices (5-8)
        temp = self.vertices[5]
        self.vertices[5] = self.vertices[7]
        self.vertices[7] = self.vertices[8]
        self.vertices[8] = self.vertices[6]
        self.vertices[6] = temp
    else
        -- Counterclockwise rotation for top vertices
        local temp = self.vertices[1]
        self.vertices[1] = self.vertices[2]
        self.vertices[2] = self.vertices[4]
        self.vertices[4] = self.vertices[3]
        self.vertices[3] = temp
        
        -- Counterclockwise rotation for bottom vertices
        temp = self.vertices[5]
        self.vertices[5] = self.vertices[6]
        self.vertices[6] = self.vertices[8]
        self.vertices[8] = self.vertices[7]
        self.vertices[7] = temp
    end

    -- Rotate face textures
    local faces = {"front", "right", "back", "left"}
    local textures = {}
    local textureInfos = {}
    
    -- Store current textures and their info
    for _, face in ipairs(faces) do
        textures[face] = self.faceTextures[face]
        textureInfos[face] = self.faceTextureInfos[face]
    end
    
    if direction == 1 then
        -- Clockwise rotation
        self.faceTextures.front = textures.left
        self.faceTextures.right = textures.front
        self.faceTextures.back = textures.right
        self.faceTextures.left = textures.back
        
        self.faceTextureInfos.front = textureInfos.left
        self.faceTextureInfos.right = textureInfos.front
        self.faceTextureInfos.back = textureInfos.right
        self.faceTextureInfos.left = textureInfos.back
    else
        -- Counterclockwise rotation
        self.faceTextures.front = textures.right
        self.faceTextures.right = textures.back
        self.faceTextures.back = textures.left
        self.faceTextures.left = textures.front
        
        self.faceTextureInfos.front = textureInfos.right
        self.faceTextureInfos.right = textureInfos.back
        self.faceTextureInfos.back = textureInfos.left
        self.faceTextureInfos.left = textureInfos.front
    end
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
                local x1, _, z1 = self:getCornerPosition(1)
                local x2, _, z2 = self:getCornerPosition(2)
                local x3, _, z3 = self:getCornerPosition(3)
                local x4, _, z4 = self:getCornerPosition(4)
                centerPoint = vec3((x1 + x2 + x3 + x4)/4, self.position.y, (z1 + z2 + z3 + z4)/4)
            else
                -- For side faces, calculate center based on actual vertex positions
                local v1Index, v2Index = vertices[1], vertices[2]
                local x1, y1, z1 = self:getCornerPosition(v1Index)
                local x2, y2, z2 = self:getCornerPosition(v2Index)
                centerPoint = vec3(
                    (x1 + x2)/2,
                    (y1 + y2 + self.position.y + self.position.y)/4,
                    (z1 + z2)/2
                )
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
                        local x1, y1, _ = self:getCornerPosition(vertices[1])
                        local x2, y2, _ = self:getCornerPosition(vertices[2])
                        local minY = math.min(y1, y2, self.position.y)
                        local maxY = math.max(y1, y2)
                        local minX = math.min(x1, x2)
                        local maxX = math.max(x1, x2)
                        inBounds = hitPoint.x >= minX and hitPoint.x <= maxX and
                                  hitPoint.y >= minY and hitPoint.y <= maxY
                    elseif face.name == "left" or face.name == "right" then
                        local _, y1, z1 = self:getCornerPosition(vertices[1])
                        local _, y2, z2 = self:getCornerPosition(vertices[2])
                        local minY = math.min(y1, y2, self.position.y)
                        local maxY = math.max(y1, y2)
                        local minZ = math.min(z1, z2)
                        local maxZ = math.max(z1, z2)
                        inBounds = hitPoint.z >= minZ and hitPoint.z <= maxZ and
                                  hitPoint.y >= minY and hitPoint.y <= maxY
                    elseif face.name == "top" or face.name == "bottom" then
                        -- For top/bottom faces, check if point is within rectangular boundary
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