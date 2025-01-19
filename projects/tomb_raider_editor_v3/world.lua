local Camera = require('camera')

local World = {
    camera = nil,
    showGrid = true,     -- Grid visibility state
    gridSize = 50,       -- Larger grid size
    gridDivisions = 50,  -- Number of grid divisions
    keyStates = {}       -- Track state of all keys
}

function World:new()
    local world = setmetatable({}, { __index = World })
    world.camera = Camera:new()
    world.keyStates = {}
    return world
end

function World:isKeyTriggered(key)
    if lovr.system.isKeyDown(key) then
        if not self.keyStates[key] then
            self.keyStates[key] = true
            return true
        end
    else
        self.keyStates[key] = false
    end
    return false
end

function World:update(dt)
    self:handleInput()
    self.camera:update(dt)
    -- Rest of world update logic
end

function World:draw(pass)
    -- Set the camera view for rendering
    pass:setViewPose(1, self.camera.position, self.camera.rotation)
    
    -- Draw the grid if enabled
    if self.showGrid then
        pass:setColor(0.5, 0.5, 0.5, 0.5)
        pass:plane(0, 0, 0, self.gridSize, self.gridSize, -math.pi/2, 1, 0, 0, 'line', self.gridDivisions, self.gridDivisions)
    end
end

function World:handleInput()
    -- Toggle grid with 'g' key using generalized system
    if self:isKeyTriggered('g') then
        self.showGrid = not self.showGrid
    end
    
    -- Pass mouse events to camera
    local x, y = lovr.system.getMousePosition()
    
    -- Handle mouse press/release for camera
    if lovr.system.isMouseDown(2) then -- Right mouse button
        if not self.camera.mouseDown then
            self.camera:mousepressed(x, y, 2)
        end
    else
        if self.camera.mouseDown then
            self.camera:mousereleased(x, y, 2)
        end
    end
end

return World