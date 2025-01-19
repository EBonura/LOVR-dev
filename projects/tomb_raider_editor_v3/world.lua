local Camera = require('camera')

local World = {
    camera = nil,
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
    
    -- Draw a test grid
    pass:setColor(0.5, 0.5, 0.5, 0.5)
    pass:plane(0, 0, 0, 10, 10, -math.pi/2, 1, 0, 0, 'line', 10, 10)
    
    -- Draw a test cube
    pass:setColor(1, 0, 0, 1)
    pass:cube(0, 0.5, 0, 1, lovr.timer.getTime())
end

function World:handleInput()
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
