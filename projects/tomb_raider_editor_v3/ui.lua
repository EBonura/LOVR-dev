-- ui.lua
local UI = {
    selection = nil,  -- Reference to Selection module
    width = 0,      -- Window width
    height = 0,     -- Window height
}

function UI:new(selection)
    local ui = setmetatable({}, { __index = UI })
    ui.selection = selection
    ui.width, ui.height = lovr.system.getWindowDimensions()
    return ui
end

function UI:update(dt)
    -- Update window dimensions in case of resize
    self.width, self.height = lovr.system.getWindowDimensions()
end

function UI:drawHUD(pass)
    -- Set up 2D orthographic projection for UI elements
    local width, height = lovr.system.getWindowDimensions()
    pass:setProjection(1, mat4():orthographic(0, width, 0, height, -1, 1))
    
    -- Draw mode indicator
    local modeColor = self.selection:getCurrentModeColor()
    pass:setColor(unpack(modeColor))
    pass:text(
        self.selection.currentMode .. " MODE",
        20,
        height - 40,
        0,
        0.5  -- Text scale
    )
end

function UI:handleInput()
    -- Handle keyboard input
    if lovr.system.isKeyDown('escape') then
        return
    end

    -- Handle mouse input
    if lovr.system.isMouseDown(1) then  -- Left mouse button
        return
    end

    if lovr.system.isMouseDown(2) then  -- Right mouse button
        return
    end

    -- Get mouse position
    local x, y = lovr.system.getMousePosition()
end

return UI