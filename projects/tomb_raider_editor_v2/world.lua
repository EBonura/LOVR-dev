local Block = require('block')

local World = {
    gridSize = 50,  -- Size of the ground grid
    camera = nil,   -- Reference to camera
    currentGridY = 0,  -- Current Y level of the grid
    numLineSegments = 10,  -- Number of segments for fading lines
    smallGridSize = 10,    -- Size of the local grid around the cube
    blocks = {}  -- Table to store all blocks
}

function World:new(camera)
    local world = setmetatable({}, { __index = World })
    world.camera = camera
    world.blocks = {}  -- Initialize empty blocks table
    return world
end

function World:placeBlock(x, y, z)
    -- Check if a block already exists at this position
    for _, block in ipairs(self.blocks) do
        if block.position.x == x and 
           block.position.y == y and 
           block.position.z == z then
            return false  -- Block already exists here
        end
    end
    
    -- Create and add new block
    local block = Block:new(x, y, z)
    -- For now, set default heights (we'll add height editing later)
    for i = 1, 4 do
        block:setVertexHeight(i, 1)  -- Set all vertices to base height
    end
    table.insert(self.blocks, block)
    return true
end

function World:drawGrid(pass)
    -- Adjust opacity based on current height
    local gridOpacity = self.currentGridY == 0 and 0.5 or 0.15  -- More visible at ground level, faint otherwise
    
    -- Draw main grid at ground level (y=0)
    pass:setColor(0.5, 0.5, 0.5, gridOpacity)
    pass:plane(0.5, 0, 0.5, self.gridSize, self.gridSize, -math.pi/2, 1, 0, 0, 'line', self.gridSize, self.gridSize)
    
    -- Draw all blocks
    for _, block in ipairs(self.blocks) do
        block:draw(pass)
    end
end

function World:drawFadingLine(pass, startX, startY, startZ, endX, endY, endZ)
    local segments = self.numLineSegments
    
    for i = 1, segments do
        local t1 = (i - 1) / segments
        local t2 = i / segments
        
        -- Calculate segment points
        local x1 = startX + (endX - startX) * t1
        local y1 = startY + (endY - startY) * t1
        local z1 = startZ + (endZ - startZ) * t1
        
        local x2 = startX + (endX - startX) * t2
        local y2 = startY + (endY - startY) * t2
        local z2 = startZ + (endZ - startZ) * t2
        
        -- Alpha fades from 0.8 at top to 0 at bottom
        local alpha = 0.8 * (1 - t1)
        pass:setColor(1, 0, 0, alpha)
        pass:line(x1, y1, z1, x2, y2, z2)
    end
end

function World:drawSmallGrid(pass, centerX, centerY, centerZ)
    -- Only draw if we're above ground level
    if self.currentGridY == 0 then
        return
    end

    -- Draw a smaller grid at current height
    pass:setColor(1, 0, 0, 0.2)  -- Red, semi-transparent to match guide lines
    
    -- Calculate grid boundaries, aligned with main grid by subtracting 0.5
    local halfSize = self.smallGridSize / 2
    local startX = centerX - halfSize - 0.5
    local startZ = centerZ - halfSize - 0.5
    
    -- Draw horizontal lines
    for i = 0, self.smallGridSize do
        local x = startX + i
        pass:line(x, centerY, startZ, x, centerY, startZ + self.smallGridSize)
    end
    
    -- Draw vertical lines
    for i = 0, self.smallGridSize do
        local z = startZ + i
        pass:line(startX, centerY, z, startX + self.smallGridSize, centerY, z)
    end
end

function World:drawCursorIntersection(pass, t, intersection)
    if t > 0 then  -- Only draw if intersection is in front of camera
        -- Round intersection to nearest grid unit
        local gridX = math.floor(intersection.x + 0.5)
        local gridZ = math.floor(intersection.z + 0.5)
        
        -- Draw the small grid at current height around the cursor
        self:drawSmallGrid(pass, gridX, self.currentGridY, gridZ)
        
        -- Update camera with current grid cell
        if self.camera then
            self.camera:setCurrentGridCell(gridX, self.currentGridY, gridZ)
        end
        
        -- Draw wireframe cube
        pass:setColor(1, 1, 1, 1)
        pass:box(gridX, self.currentGridY + 0.5, gridZ, 1, 1, 1, 0, 0, 0, 0, 'line')
        
        -- Draw fading guide lines from cube corners to ground
        local y = self.currentGridY
        -- Starting from the bottom of the cube (y) instead of the center (y + 0.5)
        self:drawFadingLine(pass, gridX - 0.5, y, gridZ - 0.5, gridX - 0.5, 0, gridZ - 0.5)
        self:drawFadingLine(pass, gridX + 0.5, y, gridZ - 0.5, gridX + 0.5, 0, gridZ - 0.5)
        self:drawFadingLine(pass, gridX - 0.5, y, gridZ + 0.5, gridX - 0.5, 0, gridZ + 0.5)
        self:drawFadingLine(pass, gridX + 0.5, y, gridZ + 0.5, gridX + 0.5, 0, gridZ + 0.5)
        
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