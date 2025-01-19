-- vertex.lua
local Vertex = {
    position = nil,  -- vec3
    HEIGHT_STEP = 0.25
}

function Vertex:new(x, y, z)
    local vertex = setmetatable({}, { __index = Vertex })
    
    -- Ensure position is grid-aligned on X/Z, quantized on Y
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

-- edge.lua
local Edge = {
    v1 = nil,  -- First vertex
    v2 = nil   -- Second vertex
}

function Edge:new(v1, v2)
    local edge = setmetatable({}, { __index = Edge })
    edge.v1 = v1
    edge.v2 = v2
    return edge
end

function Edge:draw(pass)
    pass:line(self.v1.position, self.v2.position)
end

-- face.lua
local Face = {
    vertices = {},  -- Array of 4 vertices in clockwise order
    edges = {},     -- Array of 4 edges
    texture = nil,
    axis = nil,    -- 'x', 'z', or 'y'
    facing = 1     -- 1 or -1
}

function Face:new(x, y, z, axis, facing)
    local face = setmetatable({}, { __index = Face })
    
    -- Create vertices based on axis
    face.vertices = {}
    face.edges = {}
    face.axis = axis
    face.facing = facing
    
    if axis == 'x' then
        -- Face lies in YZ plane
        face.vertices[1] = Vertex:new(x, y, z)        -- top-left
        face.vertices[2] = Vertex:new(x, y, z + 1)    -- top-right
        face.vertices[3] = Vertex:new(x, y, z + 1)    -- bottom-right
        face.vertices[4] = Vertex:new(x, y, z)        -- bottom-left
    elseif axis == 'z' then
        -- Face lies in XY plane
        face.vertices[1] = Vertex:new(x, y, z)        -- top-left
        face.vertices[2] = Vertex:new(x + 1, y, z)    -- top-right
        face.vertices[3] = Vertex:new(x + 1, y, z)    -- bottom-right
        face.vertices[4] = Vertex:new(x, y, z)        -- bottom-left
    else
        -- Face lies in XZ plane (horizontal)
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

function Face:draw(pass)
    -- Draw edges
    pass:setColor(1, 1, 1, 1)
    for _, edge in ipairs(self.edges) do
        edge:draw(pass)
    end
    
    -- Draw vertices
    pass:setColor(1, 0, 0, 1)
    for _, vertex in ipairs(self.vertices) do
        pass:sphere(vertex.position, 0.05)
    end
    
    -- Draw face fill with texture if available
    if self.texture then
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
end

function Face:adjustVertexHeight(index, direction)
    self.vertices[index]:adjustHeight(direction)
end

return {
    Vertex = Vertex,
    Edge = Edge,
    Face = Face
}