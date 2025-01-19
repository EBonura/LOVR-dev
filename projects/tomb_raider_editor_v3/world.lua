local Camera = require('camera')
local geometry = require('geometry')
local Selection = require('selection')

local World = {
    camera = nil,
    showGrid = true,
    gridSize = 20,
    faces = {},
    keyStates = {},
    selection = nil  -- Selection manager
}

function World:new()
    local world = setmetatable({}, { __index = World })
    world.camera = Camera:new()
    world.keyStates = {}
    world.faces = {}
    world.selection = Selection:new()
    
    -- Create a sample vertical face for testing
    local face = geometry.Face:new(0, 0, 0, 'z', 1)
    face:adjustVertexHeight(1, 2)
    face:adjustVertexHeight(2, 1)
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
    -- 3D Scene
    pass:setViewPose(1, self.camera.position, self.camera.rotation)
    
    -- Draw grid
    self:drawGrid(pass)
    
    -- Draw faces using selection manager
    for _, face in ipairs(self.faces) do
        self.selection:drawFace(pass, face)
    end
    
    -- Draw HUD
    self.selection:drawHUD(pass)
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

function World:handleInput()
    -- Handle mode switches
    for key in pairs({'1', '2', '3'}) do
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

return World