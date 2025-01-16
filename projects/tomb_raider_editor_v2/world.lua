local Block = require('block')

local World = {
    gridSize = 50,  -- Size of the ground grid
    camera = nil,   -- Reference to camera
    currentGridY = 0,  -- Current Y level of the grid
    numLineSegments = 10,  -- Number of segments for fading lines
    smallGridSize = 10,    -- Size of the local grid around the cube
    blocks = {},  -- Table to store all blocks
    ui = nil,     -- Reference to UI
    
    -- Mode handling
    MODE_PLACE = "PLACE",
    MODE_SELECT = "SELECT",
    MODE_FACE_SELECT = "FACE_SELECT",

    selectedFace = nil,  -- Will store {block = blockRef, face = "front"|"back"|"left"|"right"|"top"|"bottom"}
    hoveredFace = nil,   -- Same structure as selectedFace

    currentMode = "PLACE",  -- Default mode
    
    -- Selection handling
    selectedBlock = nil,
    selectedBlocks = {},  -- Table to store multiple selected blocks
    selectedFaces = {},   -- Table to store multiple selected faces
    highlightedBlock = nil  -- For hovering before selection
}

function World:new(camera)
    local world = setmetatable({}, { __index = World })
    world.camera = camera
    world.blocks = {}
    world.ui = nil
    world.history = require('history'):new()  -- Add this line
    return world
end

function World:setUI(ui)
    self.ui = ui
end

function World:setMode(mode)
    if mode == self.MODE_PLACE or 
       mode == self.MODE_SELECT or 
       mode == self.MODE_FACE_SELECT then
        self.currentMode = mode
        -- Clear selections when switching modes
        if mode == self.MODE_PLACE then
            self.selectedBlock = nil
            self.selectedBlocks = {}
            self.highlightedBlock = nil
            self.selectedFace = nil
            self.selectedFaces = {}
            self.hoveredFace = nil
        elseif mode == self.MODE_FACE_SELECT then
            -- Keep selected block when switching to face select
            self.selectedFace = nil
            self.selectedFaces = {}
            self.hoveredFace = nil
        end
    end
end

function World:toggleMode()
    if self.currentMode == self.MODE_PLACE then
        self:setMode(self.MODE_SELECT)
    elseif self.currentMode == self.MODE_SELECT then
        self:setMode(self.MODE_FACE_SELECT)
    else
        self:setMode(self.MODE_PLACE)
    end
end

function World:findBlockAt(x, y, z)
    for _, block in ipairs(self.blocks) do
        if block.position.x == x and 
           block.position.y == y and 
           block.position.z == z then
            return block
        end
    end
    return nil
end

function World:moveSelectedBlocks(dx, dy, dz)
    if self.currentMode ~= self.MODE_SELECT or #self.selectedBlocks == 0 then
        return false
    end

    -- First check if any block would collide after movement
    for _, block in ipairs(self.selectedBlocks) do
        local newX = block.position.x + dx
        local newY = block.position.y + dy
        local newZ = block.position.z + dz

        -- Check if new position would collide with any non-selected block
        for _, otherBlock in ipairs(self.blocks) do
            if not self:isBlockSelected(otherBlock) and
               otherBlock.position.x == newX and
               otherBlock.position.y == newY and
               otherBlock.position.z == newZ then
                return false -- Movement would cause collision
            end
        end
    end

    -- Save state before movement
    self.history:pushState(self)

    -- If no collisions, perform the movement
    for _, block in ipairs(self.selectedBlocks) do
        block.position:add(vec3(dx, dy, dz))
    end
    return true
end

function World:isBlockSelected(block)
    for _, selectedBlock in ipairs(self.selectedBlocks) do
        if selectedBlock == block then
            return true
        end
    end
    return false
end

function World:duplicateSelectedBlocks()
    if self.currentMode ~= self.MODE_SELECT or #self.selectedBlocks == 0 then
        return false
    end

    -- Save state before duplication
    self.history:pushState(self)

    local newBlocks = {}
    
    -- Create duplicates of all selected blocks
    for _, block in ipairs(self.selectedBlocks) do
        -- Create new block one unit up from the original
        local newBlock = Block:new(
            block.position.x,
            block.position.y + 1,  -- Offset upward by 1 unit
            block.position.z
        )
        
        -- Copy vertex heights
        for i = 1, 4 do
            newBlock.vertices[i] = block.vertices[i]
        end
        
        -- Copy textures for all faces
        local faces = {"front", "back", "left", "right", "top", "bottom"}
        for _, face in ipairs(faces) do
            if block.faceTextures[face] then
                newBlock:setFaceTexture(
                    face,
                    block.faceTextures[face],
                    block.faceTextureInfos[face]
                )
            end
        end
        
        table.insert(self.blocks, newBlock)
        table.insert(newBlocks, newBlock)
    end
    
    -- Select the new blocks
    self.selectedBlocks = newBlocks
    if #newBlocks > 0 then
        self.selectedBlock = newBlocks[1]
    end
    
    return true
end

-- In World class (world.lua)
function World:handleKeyPressed(key)
    -- Check for undo/redo first
    local ctrl = lovr.system.isKeyDown('lctrl') or 
                lovr.system.isKeyDown('rctrl') or
                lovr.system.isKeyDown('lgui') or 
                lovr.system.isKeyDown('rgui')
    
    local shift = lovr.system.isKeyDown('lshift') or 
                 lovr.system.isKeyDown('rshift')
    
    if ctrl then
        if key == 'z' then
            if shift then
                -- Redo (Ctrl+Shift+Z)
                if self.history:redo(self) then
                    return true
                end
            else
                -- Undo (Ctrl+Z)
                if self.history:undo(self) then
                    return true
                end
            end
        end
    end

    -- Mode-specific key handling
    if self.currentMode == self.MODE_SELECT then
        -- SELECT mode controls
        if key == 'delete' or key == 'backspace' then
            if #self.selectedBlocks > 0 then
                self.history:pushState(self)
                for _, block in ipairs(self.selectedBlocks) do
                    self:deleteBlock(block.position.x, block.position.y, block.position.z)
                end
                self.selectedBlocks = {}
            end
            return true
        elseif key == 'r' then
            if #self.selectedBlocks > 0 then
                -- Rotation control
                self.history:pushState(self)
                local direction = shift and -1 or 1
                for _, block in ipairs(self.selectedBlocks) do
                    block:rotate(direction)
                end
            end
            return true
        elseif key == 'd' and ctrl then
            -- Duplicate selected blocks (Ctrl+D)
            return self:duplicateSelectedBlocks()
        elseif key == 'up' then
            if shift then
                return self:moveSelectedBlocks(0, 1, 0)  -- Move up
            else
                return self:moveSelectedBlocks(0, 0, -1) -- Move forward
            end
        elseif key == 'down' then
            if shift then
                return self:moveSelectedBlocks(0, -1, 0)  -- Move down
            else
                return self:moveSelectedBlocks(0, 0, 1)   -- Move backward
            end
        elseif key == 'left' then
            return self:moveSelectedBlocks(-1, 0, 0)
        elseif key == 'right' then
            return self:moveSelectedBlocks(1, 0, 0)
        end
    elseif self.currentMode == self.MODE_FACE_SELECT then
        -- FACE_SELECT mode controls
        if (key == 'up' or key == 'down') and #self.selectedFaces > 0 then
            self.history:pushState(self)
            local direction = key == 'up' and 1 or -1
            for _, faceInfo in ipairs(self.selectedFaces) do
                faceInfo.block:moveFaceVertices(faceInfo.face, direction)
            end
            return true
        end
    end

    -- Common controls for all modes
    if key == 'pageup' or key == 'pagedown' then
        local direction = key == 'pageup' and 1 or -1
        self.currentGridY = self.currentGridY + direction
        return true
    end

    return false
end

function World:handleClick(x, y, z, isShiftHeld)
    if self.currentMode == self.MODE_PLACE then
        self:placeBlock(x, y, z)
    elseif self.currentMode == self.MODE_SELECT then
        local block = self:findBlockAt(x, y, z)
        if block then
            if isShiftHeld then
                -- Add to or remove from multi-selection
                local isAlreadySelected = false
                for i, selectedBlock in ipairs(self.selectedBlocks) do
                    if selectedBlock == block then
                        table.remove(self.selectedBlocks, i)
                        isAlreadySelected = true
                        break
                    end
                end
                if not isAlreadySelected then
                    table.insert(self.selectedBlocks, block)
                end
                -- Update primary selection
                self.selectedBlock = block
            else
                -- Single selection
                self.selectedBlock = block
                self.selectedBlocks = {block}
            end
            
            -- Sync UI texture selection with block's texture
            if self.ui then
                -- Get texture from front face as default
                local frontTexture = block.faceTextures["front"]
                local frontTextureInfo = block.faceTextureInfos["front"]
                if frontTexture and frontTextureInfo then
                    self.ui:setSelectedTextureByImage(frontTexture, frontTextureInfo)
                end
            end
        elseif not isShiftHeld then
            -- Clear selection only if shift is not held
            self.selectedBlock = nil
            self.selectedBlocks = {}
        end
    elseif self.currentMode == self.MODE_FACE_SELECT and self.hoveredFace then
        -- In face select mode, handle face selection
        if isShiftHeld then
            -- Add to or remove from multi-selection
            local isAlreadySelected = false
            for i, selectedFace in ipairs(self.selectedFaces) do
                if selectedFace.block == self.hoveredFace.block and 
                   selectedFace.face == self.hoveredFace.face then
                    table.remove(self.selectedFaces, i)
                    isAlreadySelected = true
                    break
                end
            end
            if not isAlreadySelected then
                table.insert(self.selectedFaces, {
                    block = self.hoveredFace.block,
                    face = self.hoveredFace.face
                })
            end
            -- Update primary selection
            self.selectedFace = {
                block = self.hoveredFace.block,
                face = self.hoveredFace.face
            }
        else
            -- Single selection
            self.selectedFace = {
                block = self.hoveredFace.block,
                face = self.hoveredFace.face
            }
            self.selectedFaces = {{
                block = self.hoveredFace.block,
                face = self.hoveredFace.face
            }}
        end
        
        -- Sync UI texture selection with face texture
        if self.ui then
            local block = self.selectedFace.block
            local face = self.selectedFace.face
            local faceTexture = block.faceTextures[face]
            local faceTextureInfo = block.faceTextureInfos[face]
            
            if faceTexture and faceTextureInfo then
                self.ui:setSelectedTextureByImage(faceTexture, faceTextureInfo)
            end
        end
    end
end

function World:placeBlock(x, y, z)
    -- Check if a block already exists at this position
    for _, block in ipairs(self.blocks) do
        if block.position.x == x and 
           block.position.y == y and 
           block.position.z == z then
            return false
        end
    end
    
    -- Save state before modification
    self.history:pushState(self)
    
    -- Get current texture and UI settings
    local texture = nil
    local textureInfo = nil
    local enabledFaces = nil
    
    if self.ui then
        if self.ui.selectedTexture then
            texture = self.ui.selectedTexture.texture
            textureInfo = {
                folder = self.ui.selectedTexture.folder,
                number = self.ui.selectedTexture.number
            }
        end
        enabledFaces = self.ui.enabledFaces
    end
    
    -- Create the block without textures initially
    local block = Block:new(x, y, z)
    
    -- Apply textures only to enabled faces
    if texture and textureInfo then
        for face, enabled in pairs(enabledFaces or {}) do
            if enabled then
                block:setFaceTexture(face, texture, textureInfo)
            else
                block:setFaceTexture(face, nil, nil)  -- Explicitly disable face
            end
        end
    end
    
    table.insert(self.blocks, block)
    return true
end

function World:deleteBlock(x, y, z)
    for i = #self.blocks, 1, -1 do
        local block = self.blocks[i]
        if block.position.x == x and 
           block.position.y == y and 
           block.position.z == z then
            -- Note: We don't push history state here because deletion is always
            -- called from a function that already pushed the state
            table.remove(self.blocks, i)
            if block == self.selectedBlock then
                self.selectedBlock = nil
            end
            return true
        end
    end
    return false
end

function World:drawBlock(pass, block)
    -- In face select mode, pass face information to block
    if self.currentMode == self.MODE_FACE_SELECT then
        local hoveredFaceName = self.hoveredFace and self.hoveredFace.block == block and self.hoveredFace.face or nil
        block:draw(pass, hoveredFaceName, self.selectedFaces)
    else
        -- In other modes, just draw normally
        block:draw(pass)
    end
    
    -- Draw selection highlights in SELECT mode
    if self.currentMode == self.MODE_SELECT then
        -- Draw multi-selection highlights
        for _, selectedBlock in ipairs(self.selectedBlocks) do
            if selectedBlock == block then
                pass:setColor(1, 1, 0, 0.05)  -- Yellow for selection
                block:drawHighlight(pass)
            end
        end
        -- Draw hover highlight
        if block == self.highlightedBlock then
            pass:setColor(0.5, 0.5, 1, 0.1)  -- Blue for hover
            block:drawHighlight(pass)
        end
    end
end

function World:drawGrid(pass)
    -- Adjust opacity based on current height
    local gridOpacity = self.currentGridY == 0 and 0.5 or 0.15  -- More visible at ground level, faint otherwise
    
    -- Draw main grid at ground level (y=0)
    pass:setColor(0.5, 0.5, 0.5, gridOpacity)
    pass:plane(0.5, 0, 0.5, self.gridSize, self.gridSize, -math.pi/2, 1, 0, 0, 'line', self.gridSize, self.gridSize)
    
    -- Draw all blocks with potential highlights
    for _, block in ipairs(self.blocks) do
        self:drawBlock(pass, block)
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