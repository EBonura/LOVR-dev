-- ui.lua
local InfoBox = require('InfoBox')

local UI = {
    selection = nil,
    width = 0,
    height = 0,
    modeBox = nil
}

function UI:new(selection)
    local ui = setmetatable({}, { __index = UI })
    ui.selection = selection
    ui.width, ui.height = lovr.system.getWindowDimensions()
    
    -- Set up pixel density for the default font
    lovr.graphics.getDefaultFont():setPixelDensity(1)
    
    -- Create mode info box (non-interactive)
    ui.modeBox = InfoBox:new({
        x = ui.width/2,
        y = 40,
        width = 200,
        height = 40,
        text = selection.currentMode .. " MODE",
        backgroundColor = selection:getCurrentModeColor(),
        isHoverable = true  -- Optional: enable hover effect even if not a button
    })
    
    return ui
end

function UI:update(dt)
    -- Update window dimensions and box position in case of resize
    self.width, self.height = lovr.system.getWindowDimensions()
    self.modeBox:setPosition(self.width/2, 40)
    
    -- Update box text and color
    self.modeBox:setText(self.selection.currentMode .. " MODE")
    self.modeBox:setBackgroundColor(self.selection:getCurrentModeColor())
    
    -- Update hover state
    self.modeBox:update(dt)
end

function UI:drawHUD(pass)
    -- Set up 2D projection
    pass:setViewPose(1, mat4():identity())
    pass:setProjection(1, mat4():orthographic(0, self.width, self.height, 0, -1, 1))
    
    -- Draw the mode box
    self.modeBox:draw(pass)
end

function UI:handleInput()
    local x, y = lovr.system.getMousePosition()
    
    if lovr.system.isMouseDown(1) then  -- Left mouse button
        -- Example of handling button clicks if any InfoBoxes are buttons
        self.modeBox:handleMousePressed(x, y, 1)
    end
end

return UI