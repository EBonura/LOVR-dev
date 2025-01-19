local Camera = require('camera')
local geometry = require('geometry')
local Selection = require('selection')
local UI = require('ui')

local World = {
    camera = nil,
    showGrid = true,
    gridSize = 20,
    faces = {},
    keyStates = {},
    selection = nil
}

function World:new(selection)
    local world = setmetatable({}, { __index = World })
    world.camera = Camera:new()
    world.keyStates = {}
    world.faces = {}
    world.selection = selection
    
    -- Create a sample vertical face for testing
    local face = geometry.Face:new(0, 0, 0, 'z', 1)
    face:adjustVertexHeight(1, 2)
    face:adjustVertexHeight(2, 1)
    table.insert(world.faces, face)
    
    return world
end

function World:update(dt)
    self:handleInput()
    self.camera:update(dt)
    
    -- Calculate ray and intersections
    local ray = self:calculateRayFromMouse()
    if ray then
        local intersections = self:calculateIntersections(ray)
        self.selection:updateHoverState(intersections)
    end
end

function World:draw(pass)
    -- Set up view
    pass:setViewPose(1, self.camera.position, self.camera.rotation)
    
    -- Draw grid
    if self.showGrid then
        self:drawGrid(pass)
    end
    
    -- Draw faces - each face handles its own drawing based on its state
    for _, face in ipairs(self.faces) do
        face:draw(pass, self.selection.currentMode)
    end
end

function World:drawGrid(pass)
    if not self.showGrid then return end
    
    pass:setColor(0.3, 0.3, 0.3, 1)
    
    -- Draw grid lines aligned to integer coordinates
    local halfSize = self.gridSize / 2
    
    -- Draw lines along X axis
    for x = -halfSize, halfSize do
        pass:line(x, 0, -halfSize, x, 0, halfSize)
    end
    
    -- Draw lines along Z axis
    for z = -halfSize, halfSize do
        pass:line(-halfSize, 0, z, halfSize, 0, z)
    end
    
    -- Draw center axes with different colors
    pass:setColor(1, 0, 0, 1)  -- Red for X axis
    pass:line(-halfSize, 0, 0, halfSize, 0, 0)
    
    pass:setColor(0, 0, 1, 1)  -- Blue for Z axis
    pass:line(0, 0, -halfSize, 0, 0, halfSize)
end

function World:handleKeyPress(key)
    -- Mode switching
    if key == '1' then
        self.selection:setMode(self.selection.MODE_FACE)
        return true
    elseif key == '2' then
        self.selection:setMode(self.selection.MODE_EDGE)
        return true
    elseif key == '3' then
        self.selection:setMode(self.selection.MODE_VERTEX)
        return true
    end
    return false
end

function World:handleMousePressed(button, x, y)
    if button == 1 then  -- Left click
        local ray = self:calculateRayFromMouse()
        if ray then
            local intersections = self:calculateIntersections(ray)
            local isShiftHeld = lovr.system.isKeyDown('lshift') or lovr.system.isKeyDown('rshift')
            self.selection:handleClick(intersections, isShiftHeld)
        end
    end
end

function World:handleInput()
    -- Handle mode switches
    local keys = {'1', '2', '3'} -- Define keys outside the loop
    for _, key in ipairs(keys) do
        if lovr.system.isKeyDown(key) and not self.keyStates[key] then
            self:handleKeyPress(key)
        end
        self.keyStates[key] = lovr.system.isKeyDown(key)
    end
    
    -- Toggle grid with 'g' key
    if lovr.system.isKeyDown('g') and not self.keyStates['g'] then
        self.showGrid = not self.showGrid
    end
    self.keyStates['g'] = lovr.system.isKeyDown('g')
end

function World:calculateRayFromMouse()
    local mx, my = lovr.system.getMousePosition()
    local width, height = lovr.system.getWindowDimensions()
    
    -- Convert mouse to normalized device coordinates (-1 to 1)
    local nx = (mx / width) * 2 - 1
    local ny = -((my / height) * 2 - 1)  -- Flip Y coordinate
    
    local fov = 67.5  -- Matches LÖVR's default FOV
    local tanFov = math.tan(math.rad(fov) / 2)
    local aspect = width / height
    
    -- Create view-space ray direction
    local rayDir = lovr.math.vec3(
        nx * aspect * tanFov,
        ny * tanFov,
        -1
    ):normalize()
    
    -- Transform ray by camera rotation to get world-space direction
    rayDir:rotate(self.camera.rotation)
    
    return {
        origin = lovr.math.vec3(self.camera.position), -- Clone position
        direction = rayDir
    }
end

function World:calculateIntersections(ray)
    local results = {
        face = nil,
        edge = nil,
        vertex = nil,
        faceDistance = math.huge,
        edgeDistance = math.huge,
        vertexDistance = math.huge
    }
    
    for _, face in ipairs(self.faces) do
        -- Face intersection
        local normal = face:getNormal()
        local d = ray.direction:dot(normal)
        if math.abs(d) > 1e-6 then
            local p0 = face.vertices[1].position
            local t = (p0 - ray.origin):dot(normal) / d
            
            if t > 0 and t < results.faceDistance then
                local hitPoint = ray.origin + ray.direction * t
                
                -- Check if point is within face bounds
                local minX, maxX = math.huge, -math.huge
                local minY, maxY = math.huge, -math.huge
                local minZ, maxZ = math.huge, -math.huge
                
                for _, vertex in ipairs(face.vertices) do
                    minX = math.min(minX, vertex.position.x)
                    maxX = math.max(maxX, vertex.position.x)
                    minY = math.min(minY, vertex.position.y)
                    maxY = math.max(maxY, vertex.position.y)
                    minZ = math.min(minZ, vertex.position.z)
                    maxZ = math.max(maxZ, vertex.position.z)
                end
                
                if hitPoint.x >= minX and hitPoint.x <= maxX and
                   hitPoint.y >= minY and hitPoint.y <= maxY and
                   hitPoint.z >= minZ and hitPoint.z <= maxZ then
                    results.face = face
                    results.faceDistance = t
                end
                
                -- Edge intersection (check distance to each edge)
                for _, edge in ipairs(face.edges) do
                    local v1 = edge.v1.position
                    local v2 = edge.v2.position
                    local edgeDir = (v2 - v1):normalize()
                    local toV1 = hitPoint - v1
                    local projection = toV1:dot(edgeDir)
                    
                    if projection >= 0 and projection <= (v2 - v1):length() then
                        local distanceToEdge = (toV1 - edgeDir * projection):length()
                        if distanceToEdge < 0.1 and t < results.edgeDistance then
                            results.edge = edge
                            results.edgeDistance = t
                        end
                    end
                end
                
                -- Vertex intersection (check distance to each vertex)
                for _, vertex in ipairs(face.vertices) do
                    local distanceToVertex = (hitPoint - vertex.position):length()
                    if distanceToVertex < 0.1 and t < results.vertexDistance then
                        results.vertex = vertex
                        results.vertexDistance = t
                    end
                end
            end
        end
    end
    
    return results
end

return World