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


return World
