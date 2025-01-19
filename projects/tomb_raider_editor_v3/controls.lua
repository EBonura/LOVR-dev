local Controls = {
    world = nil,
    ui = nil,
    
    -- State tracking
    mouseX = 0,
    mouseY = 0,
    mouseDown = false
}

function Controls:new(world, ui)
    local controls = setmetatable({}, { __index = Controls })
    controls.world = world
    controls.ui = ui
    return controls
end

function Controls:update(dt)
    -- Handle continuous input (like held keys)
    -- Will be used for continuous movement, etc.
end

function Controls:keypressed(key)
    -- Route keyboard input to appropriate system
    if self.ui:isActive() then
        -- Send to UI when it's active
        self.ui:receiveKey(key)
    else
        -- Otherwise send to world
        self.world:receiveKey(key)
    end
end

function Controls:mousemoved(x, y)
    self.mouseX = x
    self.mouseY = y
    
    if self.ui:isPointInUI(x, y) then
        self.ui:receiveMouse(x, y)
    else
        self.world:receiveMouse(x, y)
    end
end

function Controls:mousepressed(x, y, button)
    self.mouseDown = true
    if self.ui:isPointInUI(x, y) then
        self.ui:receiveMousePress(x, y, button)
    else
        self.world:receiveMousePress(x, y, button)
    end
end

function Controls:mousereleased(x, y, button)
    self.mouseDown = false
    if self.ui:isPointInUI(x, y) then
        self.ui:receiveMouseRelease(x, y, button)
    else
        self.world:receiveMouseRelease(x, y, button)
    end
end

return Controls