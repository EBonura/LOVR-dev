local Camera = require('camera')
local geometry = require('geometry')

local World = {
    camera = nil,
    showGrid = true,
    gridSize = 20,  -- Smaller grid size for better visualization
    faces = {},
    keyStates = {}
}

function World:new()
    local world = setmetatable({}, { __index = World })
    world.camera = Camera:new()
    world.keyStates = {}
    world.faces = {}
    
    -- Create a sample vertical face for testing
    local face = geometry.Face:new(0, 0, 0, 'z', 1)
    
    -- Make it slanted by adjusting heights
    face:adjustVertexHeight(1, 2)  -- Raise first vertex by 0.5 units
    face:adjustVertexHeight(2, 1)  -- Raise second vertex by 0.25 units
    
    table.insert(world.faces, face)
    
    return world
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

function World:update(dt)
    self:handleInput()
    self.camera:update(dt)
end

function World:draw(pass)
    -- Set up 3D rendering with camera
    pass:setViewPose(1, self.camera.position, self.camera.rotation)
    
    -- Draw aligned grid
    self:drawGrid(pass)
    
    -- Draw all faces
    for _, face in ipairs(self.faces) do
        face:draw(pass)
    end
end

function World:handleInput()
    -- Toggle grid with 'g' key
    if lovr.system.isKeyDown('g') and not self.keyStates['g'] then
        self.showGrid = not self.showGrid
    end
    self.keyStates['g'] = lovr.system.isKeyDown('g')
end

return World