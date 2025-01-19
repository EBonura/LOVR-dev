-- InfoBox.lua
local InfoBox = {}

function InfoBox:new(config)
    local box = setmetatable({}, { __index = InfoBox })
    
    -- Default values
    box.x = config.x or 0
    box.y = config.y or 0
    box.width = config.width or 200
    box.height = config.height or 40
    box.text = config.text or ""
    box.textScale = config.textScale or 0.5
    box.backgroundColor = config.backgroundColor or {0.2, 0.2, 0.2, 1}
    box.textColor = config.textColor or {1, 1, 1, 1}
    box.font = config.font or lovr.graphics.getDefaultFont()
    box.alignment = config.alignment or 'center'
    
    -- Interactive state
    box.isButton = config.isButton or false
    box.onClick = config.onClick  -- Callback function for click events
    box.isHoverable = config.isHoverable or false
    box.hoverBackgroundColor = config.hoverBackgroundColor or {0.3, 0.3, 0.3, 1}
    box.isHovered = false
    
    return box
end

function InfoBox:update(dt)
    if self.isHoverable or self.isButton then
        local x, y = lovr.system.getMousePosition()
        self.isHovered = self:containsPoint(x, y)
    end
end

function InfoBox:draw(pass)
    -- Draw background with hover effect if applicable
    local currentColor = self.isHovered and self.hoverBackgroundColor or self.backgroundColor
    pass:setColor(unpack(currentColor))
    pass:plane(
        self.x,
        self.y,
        0,
        self.width,
        self.height
    )
    
    -- Draw text
    pass:setFont(self.font)
    pass:setColor(unpack(self.textColor))
    pass:text(
        self.text,
        self.x,
        self.y,
        0,
        self.textScale,
        0,
        0, 1, 0,
        0,
        self.alignment
    )
end

function InfoBox:containsPoint(x, y)
    return x >= self.x - self.width/2 and 
           x <= self.x + self.width/2 and
           y >= self.y - self.height/2 and
           y <= self.y + self.height/2
end

function InfoBox:handleMousePressed(x, y, button)
    if self.isButton and self:containsPoint(x, y) and self.onClick then
        self.onClick(self, button)
        return true
    end
    return false
end

-- Setters for dynamic updates
function InfoBox:setText(text)
    self.text = text
end

function InfoBox:setBackgroundColor(color)
    self.backgroundColor = color
end

function InfoBox:setPosition(x, y)
    self.x = x
    self.y = y
end

return InfoBox