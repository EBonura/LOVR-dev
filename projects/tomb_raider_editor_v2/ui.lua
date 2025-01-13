local UI = {
    panelWidth = 0.4,
    backgroundColor = {0.2, 0.2, 0.2, 1}
}

function UI:new()
    local ui = setmetatable({}, { __index = UI })
    return ui
end

function UI:draw(pass)
    -- Save current state
    pass:push()
    
    -- Set up for 2D UI rendering
    pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
    
    -- Calculate panel position
    local width, height = lovr.system.getWindowDimensions()
    local aspect = width / height
    local panelX = width * (1 - self.panelWidth)
    
    -- Draw panel background
    pass:setColor(unpack(self.backgroundColor))
    pass:plane(panelX, 0, -0.5, self.panelWidth * aspect, 2)
    
    -- Set up text rendering
    pass:setColor(1, 1, 1, 1)
    local font = lovr.graphics.getDefaultFont()
    font:setPixelDensity(1)
    
    -- Draw title text (slightly in front of panel)
    pass:text(
        "Right Panel",
        panelX ,  -- Offset from panel center
        0.8,            -- Near top of screen
        -0.49,          -- Slightly in front of panel
        0.0008            -- Text size
    )
    
    pass:pop()
end

function UI:isPointInPanel(x, y)
    local width = lovr.system.getWindowWidth()
    local panelStartX = width * (1 - self.panelWidth)
    return x >= panelStartX
end

return UI