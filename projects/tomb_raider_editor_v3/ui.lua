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
    
    -- Add this line
    lovr.graphics.getDefaultFont():setPixelDensity(1)
    
    return ui
end

function UI:update(dt)
    -- Update window dimensions in case of resize
    self.width, self.height = lovr.system.getWindowDimensions()
end

function UI:drawHUD(pass)
    local width, height = lovr.system.getWindowDimensions()
    
    -- Reset view and set up 2D projection
    pass:setViewPose(1, mat4():identity())
    pass:setProjection(1, mat4():orthographic(0, width, height, 0, -1, 1))
    
    -- Draw mode indicator with explicit positioning
    local modeColor = self.selection:getCurrentModeColor()
    pass:setColor(unpack(modeColor))
    pass:plane(
        width/2,  -- Center X
        40,       -- Y from top
        0,        -- Z
        200,      -- Width
        40        -- Height
    )
    
    -- Draw text with explicit font and positioning
    local font = lovr.graphics.getDefaultFont()
    pass:setFont(font)
    pass:setColor(1, 1, 1, 1)
    pass:text(
        self.selection.currentMode .. " MODE",
        width/2,  -- Center X
        40,       -- Y from top
        0,        -- Z
        0.5,      -- Scale
        0,        -- Rotation
        0, 1, 0,  -- Axis
        0,        -- Wrap width
        'center'  -- Alignment
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