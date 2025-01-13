local World = {
    gridSize = 20,  -- Size of the ground grid
}

function World:new()
    local world = setmetatable({}, { __index = World })
    return world
end

function World:drawGrid(pass)
    -- Draw grid slightly below Y=0 to prevent z-fighting
    pass:setColor(0.5, 0.5, 0.5, 0.5)
    pass:plane(0.5, -0.001, 0.5, self.gridSize, self.gridSize, -math.pi/2, 1, 0, 0, 'line', self.gridSize, self.gridSize)
end

function World:drawCursorIntersection(pass, t, intersection)
    if t > 0 then  -- Only draw if intersection is in front of camera
        -- Round intersection to nearest grid unit
        local gridX = math.floor(intersection.x + 0.5)
        local gridZ = math.floor(intersection.z + 0.5)
        
        -- Draw wireframe cube
        pass:setColor(1, 1, 1, 1)
        pass:box(gridX, 0.5, gridZ, 1, 1, 1, 0, 0, 0, 0, 'line')
        
        -- Draw intersection point
        pass:setColor(1, 0, 0, 1)
        pass:sphere(intersection, 0.1)
    end
end

return World