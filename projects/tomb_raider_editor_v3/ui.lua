local UI = {}

function UI:new()
    local ui = setmetatable({}, { __index = UI })
    return ui
end

function UI:update(dt)
    -- Update UI state
end

function UI:draw(pass)
    -- Render UI elements
end

return UI
