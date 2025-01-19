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

function UI:isPointInUI(x, y)
    -- Check if point is in UI area
    return false  -- For now
end

function UI:receiveKey(key)
    -- React to keyboard input
end

function UI:receiveMouse(x, y)
    -- React to mouse movement
end

function UI:receiveMousePress(x, y, button)
    -- React to mouse press
end

function UI:receiveMouseRelease(x, y, button)
    -- React to mouse release
end

return UI
