local World = {
    -- Will contain 3D scene properties
}

function World:new()
    local world = setmetatable({}, { __index = World })
    return world
end

function World:update(dt)
    -- Update world state
end

function World:draw(pass)
    -- Render 3D scene
end

function World:receiveKey(key)
    -- React to keyboard input
end

function World:receiveMouse(x, y)
    -- React to mouse movement
end

function World:receiveMousePress(x, y, button)
    -- React to mouse press
end

function World:receiveMouseRelease(x, y, button)
    -- React to mouse release
end

return World
