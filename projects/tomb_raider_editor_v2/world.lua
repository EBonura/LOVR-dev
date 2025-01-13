local World = {
    gridSize = 50,  -- Size of the ground grid
    camera = nil,   -- Reference to camera
    currentGridY = 0  -- Current Y level of the grid
}

function World:new(camera)
    local world = setmetatable({}, { __index = World })
    world.camera = camera
    return world
end

function World:drawGrid(pass)
    -- Draw grid at current Y level
    pass:setColor(0.5, 0.5, 0.5, 0.5)
    pass:plane(0.5, self.currentGridY, 0.5, self.gridSize, self.gridSize, -math.pi/2, 1, 0, 0, 'line', self.gridSize, self.gridSize)
end

function World:drawCursorIntersection(pass, t, intersection)
    if t > 0 then  -- Only draw if intersection is in front of camera
        -- Round intersection to nearest grid unit
        local gridX = math.floor(intersection.x + 0.5)
        local gridZ = math.floor(intersection.z + 0.5)
        
        -- Update camera with current grid cell
        if self.camera then
            self.camera:setCurrentGridCell(gridX, self.currentGridY, gridZ)
        end
        
        -- Draw wireframe cube
        pass:setColor(1, 1, 1, 1)
        pass:box(gridX, self.currentGridY + 0.5, gridZ, 1, 1, 1, 0, 0, 0, 0, 'line')
        
        -- Draw intersection point
        pass:setColor(1, 0, 0, 1)
        pass:sphere(intersection, 0.1)
    end
end

function World:shiftGridUp()
    self.currentGridY = self.currentGridY + 1
end

function World:shiftGridDown()
    self.currentGridY = self.currentGridY - 1
end

return World