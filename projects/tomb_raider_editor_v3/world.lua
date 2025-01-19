local Camera = require('camera')

local World = {
    camera = nil,
    showGrid = true,     -- Grid visibility state
    gridSize = 50,       -- Larger grid size
    gridDivisions = 50   -- Number of grid divisions
}

function World:new()
    local world = setmetatable({}, { __index = World })
    world.camera = Camera:new()
    return world
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
    -- Toggle grid with 'g' key
    if lovr.system.isKeyDown('g') then
        -- Only toggle once per press
        if not self.gKeyPressed then
            self.showGrid = not self.showGrid
            self.gKeyPressed = true
        end
    else
        self.gKeyPressed = false
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