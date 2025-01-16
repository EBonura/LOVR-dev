local History = {
    undoStack = {},
    redoStack = {},
    maxHistory = 100  -- Maximum number of states to keep in history
}

function History:new()
    local history = setmetatable({}, { __index = History })
    history.undoStack = {}
    history.redoStack = {}
    return history
end

-- Deep copy function for tables
local function deepcopy(orig)
    if type(orig) ~= 'table' then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == 'table' then
            v = deepcopy(v)
        end
        copy[k] = v
    end
    return copy
end

-- Creates a snapshot of the current world state
function History:createSnapshot(world)
    return {
        blocks = deepcopy(world.blocks),
        currentGridY = world.currentGridY
    }
end

-- Pushes a new state onto the undo stack
function History:pushState(world)
    local snapshot = self:createSnapshot(world)
    table.insert(self.undoStack, snapshot)
    
    -- Clear redo stack when a new action is performed
    self.redoStack = {}
    
    -- Limit the size of the undo stack
    while #self.undoStack > self.maxHistory do
        table.remove(self.undoStack, 1)
    end
end

-- Restores a snapshot to the world
-- Restores a snapshot to the world
function History:restoreSnapshot(world, snapshot)
    local Block = require('block')  -- We need Block to recreate block objects
    
    world.blocks = {}  -- Clear existing blocks
    world.currentGridY = snapshot.currentGridY
    
    -- Recreate blocks
    for _, blockData in ipairs(snapshot.blocks) do
        -- Create new block
        local block = Block:new(
            blockData.position.x,
            blockData.position.y,
            blockData.position.z
        )
        
        -- Restore vertex heights
        block.vertices = blockData.vertices
        
        -- Restore all face textures
        if world.ui then
            for face, textureInfo in pairs(blockData.faceTextureInfos) do
                -- Switch to correct folder if needed
                if textureInfo.folder ~= world.ui:getCurrentFolder() then
                    world.ui.currentFolderIndex = world.ui:getFolderIndex(textureInfo.folder)
                    world.ui:loadTexturesFromCurrentFolder()
                end
                
                -- Find matching texture
                for _, tex in ipairs(world.ui.textures) do
                    if tex.folder == textureInfo.folder and tex.number == textureInfo.number then
                        block:setFaceTexture(face, tex.texture, textureInfo)
                        break
                    end
                end
            end
        end
        
        table.insert(world.blocks, block)
    end
    
    -- Clear selections
    world.selectedBlock = nil
    world.selectedBlocks = {}
    world.highlightedBlock = nil
    world.selectedFace = nil
    world.selectedFaces = {}
    world.hoveredFace = nil
end

-- Performs an undo operation
function History:undo(world)
    if #self.undoStack > 0 then
        -- Save current state to redo stack
        local currentState = self:createSnapshot(world)
        table.insert(self.redoStack, currentState)
        
        -- Pop and restore previous state
        local previousState = table.remove(self.undoStack)
        self:restoreSnapshot(world, previousState)
        return true
    end
    return false
end

-- Performs a redo operation
function History:redo(world)
    if #self.redoStack > 0 then
        -- Save current state to undo stack
        local currentState = self:createSnapshot(world)
        table.insert(self.undoStack, currentState)
        
        -- Pop and restore next state
        local nextState = table.remove(self.redoStack)
        self:restoreSnapshot(world, nextState)
        return true
    end
    return false
end

return History