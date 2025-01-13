local UI = {
    panelWidth = 300,  -- Width in pixels
    backgroundColor = {0.2, 0.2, 0.2, 0.9},
    camera = nil       -- Add camera field
}

function UI:new(camera)
    local ui = setmetatable({}, { __index = UI })
    ui.camera = camera  -- Store the camera reference
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
    
    -- Draw title text at the top
    pass:text(
        "Control Panel",
        panelX + 10,    -- Left-aligned with smaller padding
        height - 50,             -- Near top
        0,              -- Z position
        0.8,            -- Modest scale
        0,              -- Rotation
        0, 1, 0,        -- Rotation axis
        0,              -- Wrap width
        'left'          -- Alignment
    )

    -- Draw debug info below title
    pass:text(
        self.camera:getDebugText(),  -- Camera debug text
        panelX + 10,                 -- Left-aligned with smaller padding
        60,                          -- Below title with spacing
        0,                           -- Z position
        0.6,                         -- Smaller scale
        0,                           -- Rotation
        0, 1, 0,                     -- Rotation axis
        0,                           -- Wrap width
        'left'                       -- Alignment
    )
end

function UI:isPointInPanel(x, y)
    local width = lovr.system.getWindowWidth()
    return x >= (width - self.panelWidth)
end

return UI