-- geometry.lua

local COLORS = {
    EDGE_NORMAL = {0.7, 0.7, 0.7, 1},      -- Light gray for normal edges
    VERTEX_NORMAL = {0.6, 0.6, 0.6, 1},    -- Slightly darker gray for normal vertices
    SELECTED = {1, 1, 0, 1},               -- Yellow for selected elements
    HOVERED = {1, 1, 0, 0.5},              -- Semi-transparent yellow for hover
    FACE_FILL = {0.3, 0.3, 0.3, 0.4},      -- Semi-transparent dark gray for face fill
}

-- Vertex class
local Vertex = {
    position = nil,  -- vec3
    HEIGHT_STEP = 0.25,
    isSelected = false,
    isHovered = false
}

function Vertex:new(x, y, z)
    local vertex = setmetatable({}, { __index = Vertex })
    vertex.position = lovr.math.newVec3(
        math.floor(x),
        math.floor(y / vertex.HEIGHT_STEP) * vertex.HEIGHT_STEP,
        math.floor(z)
    )
    return vertex
end

function Vertex:adjustHeight(direction)
    self.position.y = self.position.y + (direction * self.HEIGHT_STEP)
end

function Vertex:draw(pass)
    -- Choose color based on selection/hover state
    if self.isSelected then
        pass:setColor(unpack(COLORS.SELECTED))
        pass:sphere(self.position, 0.04)  -- Slightly larger when selected
    elseif self.isHovered then
        pass:setColor(unpack(COLORS.HOVERED))
        pass:sphere(self.position, 0.04)
    else
        pass:setColor(unpack(COLORS.VERTEX_NORMAL))
        pass:sphere(self.position, 0.03)
    end
end

-- Edge class
local Edge = {
    v1 = nil,  -- First vertex
    v2 = nil,  -- Second vertex
    isSelected = false,
    isHovered = false
}

function Edge:new(v1, v2)
    local edge = setmetatable({}, { __index = Edge })
    edge.v1 = v1
    edge.v2 = v2
    return edge
end

function Edge:draw(pass)
    -- Choose color based on selection/hover state
    if self.isSelected then
        pass:setColor(unpack(COLORS.SELECTED))
    elseif self.isHovered then
        pass:setColor(unpack(COLORS.HOVERED))
    else
        pass:setColor(unpack(COLORS.EDGE_NORMAL))
    end
    pass:line(self.v1.position, self.v2.position)
end

-- Face class
local Face = {
    vertices = {},  -- Array of 4 vertices in clockwise order
    edges = {},     -- Array of 4 edges
    texture = nil,
    axis = nil,    -- 'x', 'z', or 'y'
    facing = 1,    -- 1 or -1
    isSelected = false,
    isHovered = false
}

function Face:new(x, y, z, axis, facing)
    local face = setmetatable({}, { __index = Face })
    
    face.vertices = {}
    face.edges = {}
    face.axis = axis
    face.facing = facing
    
    -- Create vertices based on axis
    if axis == 'x' then
        face.vertices[1] = Vertex:new(x, y, z)        -- top-left
        face.vertices[2] = Vertex:new(x, y, z + 1)    -- top-right
        face.vertices[3] = Vertex:new(x, y, z + 1)    -- bottom-right
        face.vertices[4] = Vertex:new(x, y, z)        -- bottom-left
    elseif axis == 'z' then
        face.vertices[1] = Vertex:new(x, y, z)        -- top-left
        face.vertices[2] = Vertex:new(x + 1, y, z)    -- top-right
        face.vertices[3] = Vertex:new(x + 1, y, z)    -- bottom-right
        face.vertices[4] = Vertex:new(x, y, z)        -- bottom-left
    else
        face.vertices[1] = Vertex:new(x, y, z)        -- top-left
        face.vertices[2] = Vertex:new(x + 1, y, z)    -- top-right
        face.vertices[3] = Vertex:new(x + 1, y, z + 1)-- bottom-right
        face.vertices[4] = Vertex:new(x, y, z + 1)    -- bottom-left
    end
    
    -- Create edges connecting vertices
    for i = 1, 4 do
        local next = (i % 4) + 1
        face.edges[i] = Edge:new(face.vertices[i], face.vertices[next])
    end
    
    return face
end

function Face:getNormal()
    local normal = lovr.math.vec3(0, 0, 0)
    normal[self.axis] = self.facing
    return normal
end

function Face:drawFill(pass)
    -- Create vertices for two triangles
    local format = {
        { 'VertexPosition', 'vec3' }
    }
    
    local vertices = {
        -- First triangle
        { self.vertices[1].position.x, self.vertices[1].position.y, self.vertices[1].position.z },
        { self.vertices[2].position.x, self.vertices[2].position.y, self.vertices[2].position.z },
        { self.vertices[3].position.x, self.vertices[3].position.y, self.vertices[3].position.z },
        -- Second triangle
        { self.vertices[1].position.x, self.vertices[1].position.y, self.vertices[1].position.z },
        { self.vertices[3].position.x, self.vertices[3].position.y, self.vertices[3].position.z },
        { self.vertices[4].position.x, self.vertices[4].position.y, self.vertices[4].position.z }
    }
    
    local mesh = lovr.graphics.newMesh(format, vertices)
    pass:draw(mesh)
end

function Face:draw(pass, mode)
    -- Draw face fill with appropriate color
    if self.isSelected then
        pass:setColor(COLORS.SELECTED[1], COLORS.SELECTED[2], COLORS.SELECTED[3], 0.3)
    elseif self.isHovered then
        pass:setColor(COLORS.HOVERED[1], COLORS.HOVERED[2], COLORS.HOVERED[3], 0.2)
    else
        pass:setColor(COLORS.FACE_FILL)
    end
    self:drawFill(pass)

    -- Draw edges and vertices based on mode
    if mode == 'EDGE' then
        -- Draw edges with their individual states
        for _, edge in ipairs(self.edges) do
            edge:draw(pass)
        end
        -- Draw normal vertices
        pass:setColor(COLORS.VERTEX_NORMAL)
        for _, vertex in ipairs(self.vertices) do
            pass:sphere(vertex.position, 0.03)
        end
    elseif mode == 'VERTEX' then
        -- Draw normal edges
        pass:setColor(COLORS.EDGE_NORMAL)
        for _, edge in ipairs(self.edges) do
            edge:draw(pass)
        end
        -- Draw vertices with their individual states
        for _, vertex in ipairs(self.vertices) do
            vertex:draw(pass)
        end
    else  -- FACE mode or default
        -- Draw normal edges and vertices
        pass:setColor(COLORS.EDGE_NORMAL)
        for _, edge in ipairs(self.edges) do
            edge:draw(pass)
        end
        pass:setColor(COLORS.VERTEX_NORMAL)
        for _, vertex in ipairs(self.vertices) do
            vertex:draw(pass)
        end
    end
    
    -- Draw textured face if texture is available
    if self.texture then
        self:drawTextured(pass)
    end
end

function Face:drawTextured(pass)
    local format = {
        { 'VertexPosition', 'vec3' },
        { 'VertexNormal', 'vec3' },
        { 'VertexUV', 'vec2' }
    }
    
    local normal = self:getNormal()
    local vertices = {
        -- First triangle
        { self.vertices[1].position.x, self.vertices[1].position.y, self.vertices[1].position.z, normal.x, normal.y, normal.z, 0, 0 },
        { self.vertices[2].position.x, self.vertices[2].position.y, self.vertices[2].position.z, normal.x, normal.y, normal.z, 1, 0 },
        { self.vertices[3].position.x, self.vertices[3].position.y, self.vertices[3].position.z, normal.x, normal.y, normal.z, 1, 1 },
        -- Second triangle
        { self.vertices[1].position.x, self.vertices[1].position.y, self.vertices[1].position.z, normal.x, normal.y, normal.z, 0, 0 },
        { self.vertices[3].position.x, self.vertices[3].position.y, self.vertices[3].position.z, normal.x, normal.y, normal.z, 1, 1 },
        { self.vertices[4].position.x, self.vertices[4].position.y, self.vertices[4].position.z, normal.x, normal.y, normal.z, 0, 1 }
    }
    
    local mesh = lovr.graphics.newMesh(format, vertices)
    pass:setColor(1, 1, 1, 1)
    pass:setMaterial(self.texture)
    pass:draw(mesh)
    pass:setMaterial()
end

function Face:adjustVertexHeight(index, direction)
    self.vertices[index]:adjustHeight(direction)
end

return {
    Vertex = Vertex,
    Edge = Edge,
    Face = Face,
    COLORS = COLORS
}