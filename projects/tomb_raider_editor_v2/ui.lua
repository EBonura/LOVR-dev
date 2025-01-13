local UI = {
    panelWidth = 0.4,  -- Use proportion of screen instead of pixels
    backgroundColor = {0.2, 0.2, 0.2, 1}
}

function UI:new()
    local ui = setmetatable({}, { __index = UI })
    return ui
end

function UI:draw(pass)
    -- Save current state
    pass:push()
    
    -- Reset view to 2D view
    pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
    
    -- Calculate panel position in normalized device coordinates
    local width, height = lovr.system.getWindowDimensions()
    local aspect = width / height
    local panelX = aspect * (1 - self.panelWidth/2)  -- Adjust for right side
    
    -- Draw panel background
    pass:setColor(unpack(self.backgroundColor))
    pass:plane(panelX, 0, -1, self.panelWidth * aspect, 2)
    
    -- Draw title (positioned relative to panel)
    pass:setColor(1, 1, 1, 1)
    pass:text(
        "Right Panel",
        panelX - 0.15,  -- Offset from panel center
        0.8,            -- Near top of screen
        -0.9,           -- Slightly in front of panel
        0.05            -- Smaller text size
    )
    
    -- Restore state
    pass:pop()
end

function UI:isPointInPanel(x, y)
    local width = lovr.system.getWindowWidth()
    local panelStartX = width * (1 - self.panelWidth)
    return x >= panelStartX
end

return UI