local UI = {
    panelWidth = 300,  -- Width in pixels
    backgroundColor = {0.2, 0.2, 0.2, 0.9}
}

function UI:new()
    local ui = setmetatable({}, { __index = UI })
    return ui
end

function UI:draw(pass)
    -- Get window dimensions
    local width, height = lovr.system.getWindowDimensions()
    
    -- Set up 2D orthographic projection
    local projection = mat4():orthographic(0, width, height, 0, -10, 10)
    pass:setProjection(1, projection)
    
    -- Reset view transform
    pass:setViewPose(1, mat4():identity())
    
    -- Calculate panel position (right side of screen)
    local panelX = width - self.panelWidth
    
    -- Draw panel background
    pass:setColor(unpack(self.backgroundColor))
    pass:plane(
        panelX + self.panelWidth/2,  -- Center X of panel
        height/2,                     -- Center Y of panel
        0,                           -- Z position
        self.panelWidth,            -- Width
        height                      -- Height
    )
    
    -- Set up text
    pass:setColor(1, 1, 1, 1)
    local font = lovr.graphics.getDefaultFont()
    font:setPixelDensity(1)
    
    -- Draw title text
    pass:text(
        "Control Panel",
        panelX + 20,    -- Left-aligned with padding
        30,             -- Top padding
        0,              -- Z position
        1,              -- Scale
        0,              -- Rotation
        0, 1, 0,        -- Rotation axis
        0,              -- Wrap width
        'left'          -- Alignment
    )
end

function UI:isPointInPanel(x, y)
    local width = lovr.system.getWindowWidth()
    return x >= (width - self.panelWidth)
end

return UI