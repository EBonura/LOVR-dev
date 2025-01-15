local Block = require('block')
local FileDialog = require('filedialog')

local SaveLoad = {
    currentFilename = nil,
    fileDialog = nil,
    lastError = nil,
    lastMessage = nil,
    messageTimeout = 3, -- Message display time in seconds
    messageTimer = 0
}

function SaveLoad:update(dt)
    -- Update message timer
    if self.lastError or self.lastMessage then
        self.messageTimer = self.messageTimer + dt
        if self.messageTimer >= self.messageTimeout then
            self.lastError = nil
            self.lastMessage = nil
            self.messageTimer = 0
        end
    end
    
    -- Update file dialog
    if self.fileDialog then
        self.fileDialog:update(dt)
    end
end

function SaveLoad:showError(message)
    self.lastError = message
    self.lastMessage = nil
    self.messageTimer = 0
end

function SaveLoad:showMessage(message)
    self.lastMessage = message
    self.lastError = nil
    self.messageTimer = 0
end

function SaveLoad:handleKeyPressed(key)
    if self.fileDialog and self.fileDialog.isOpen then
        return self.fileDialog:handleKeyPressed(key)
    end
    return false
end

function SaveLoad:handleTextInput(text)
    if self.fileDialog and self.fileDialog.isOpen then
        return self.fileDialog:handleTextInput(text)
    end
    return false
end

function SaveLoad:handleMousePressed(x, y, button)
    if self.fileDialog and self.fileDialog.isOpen then
        return self.fileDialog:handleMousePressed(x, y, button)
    end
    return false
end

function SaveLoad:handleMouseMoved(x, y)
    if self.fileDialog and self.fileDialog.isOpen then
        return self.fileDialog:handleMouseMoved(x, y)
    end
    return false
end

function SaveLoad:handleScroll(dx, dy)
    if self.fileDialog and self.fileDialog.isOpen then
        return self.fileDialog:handleScroll(dx, dy)
    end
    return false
end

function SaveLoad:serializeBlock(block)
    return {
        position = { x = block.position.x, y = block.position.y, z = block.position.z },
        vertices = block.vertices,
        textures = {}, -- Will store texture info for each face
        width = block.width,
        depth = block.depth,
        height = block.height
    }
end

function SaveLoad:deserializeBlock(data)
    local block = Block:new(data.position.x, data.position.y, data.position.z)
    block.vertices = data.vertices
    block.width = data.width or 1
    block.depth = data.depth or 1
    block.height = data.height or 1
    return block
end

function SaveLoad:initialize()
    -- Create levels directory in save directory for writing
    lovr.filesystem.createDirectory("levels")
    
    -- Mount the existing levels directory for reading
    local levelsPath = lovr.filesystem.getSource() .. "/levels"
    lovr.filesystem.mount(levelsPath, "levels")
    print("SaveLoad: Mounted levels directory:", levelsPath)
    print("Save directory:", lovr.filesystem.getSaveDirectory())
    
    self.fileDialog = FileDialog:new()
end

function SaveLoad:saveWorld(world, filename)
    -- Ensure the filename is in the levels directory
    if not filename:match("^levels/") then
        filename = "levels/" .. filename
    end
    
    local data = {
        blocks = {},
        gridY = world.currentGridY
    }
    
    -- Serialize each block
    for _, block in ipairs(world.blocks) do
        local blockData = self:serializeBlock(block)
        
        -- Store texture info for each face
        local faces = {"front", "back", "left", "right", "top", "bottom"}
        for _, face in ipairs(faces) do
            if block.faceTextures[face] then
                blockData.textures[face] = {
                    folder = block.faceTextureInfos[face].folder,
                    number = block.faceTextureInfos[face].number
                }
            end
        end
        
        table.insert(data.blocks, blockData)
    end
    
    -- Convert to JSON string
    local json = require('json')
    local jsonString = json.encode(data)
    
    -- Print debug info
    print("Saving to:", filename)
    print("Full save path:", lovr.filesystem.getSaveDirectory() .. "/" .. filename)
    
    -- Save to file
    local success = lovr.filesystem.write(filename, jsonString)
    if success then
        self.currentFilename = filename
        self:showMessage("World saved successfully to " .. filename)
        return true
    else
        self:showError("Failed to save world to " .. filename)
        return false
    end
end

function SaveLoad:loadWorld(world, filename)
    -- Ensure the filename is in the levels directory
    if not filename:match("^levels/") then
        filename = "levels/" .. filename
    end
    
    print("Loading from:", filename)
    -- Read file contents
    local contents = lovr.filesystem.read(filename)
    if not contents then 
        self:showError("Failed to read file: " .. filename)
        return false 
    end
    
    -- Parse JSON
    local json = require('json')
    local data = json.decode(contents)
    if not data then 
        self:showError("Failed to parse world data from " .. filename)
        return false 
    end
    
    -- Clear existing blocks
    world.blocks = {}
    
    -- Restore grid height
    world.currentGridY = data.gridY or 0
    
    -- Create new blocks
    for _, blockData in ipairs(data.blocks) do
        local block = self:deserializeBlock(blockData)
        
        -- Restore textures
        for face, textureInfo in pairs(blockData.textures) do
            local path = string.format(
                "textures/%s/Horror_%s_%02d-128x128.png",
                textureInfo.folder,
                textureInfo.folder,
                textureInfo.number
            )
            
            -- Load texture
            local success, texture = pcall(lovr.graphics.newTexture, path)
            if success then
                block:setFaceTexture(face, texture, textureInfo)
            end
        end
        
        table.insert(world.blocks, block)
    end
    
    self.currentFilename = filename
    self:showMessage("World loaded successfully from " .. filename)
    return true
end

function SaveLoad:promptSave(world, defaultFilename)
    if not self.fileDialog then return end
    
    self.fileDialog:show("save", defaultFilename or "world.json",
        function(filename)
            self:saveWorld(world, filename)
        end,
        function()
            self:showMessage("Save cancelled")
        end
    )
end

function SaveLoad:promptLoad(world)
    if not self.fileDialog then return end
    
    self.fileDialog:show("load", nil,
        function(filename)
            self:loadWorld(world, filename)
        end,
        function()
            self:showMessage("Load cancelled")
        end
    )
end

function SaveLoad:newWorld(world)
    -- Clear all blocks
    world.blocks = {}
    -- Reset grid height
    world.currentGridY = 0
    -- Clear current filename
    self.currentFilename = nil
    self:showMessage("Created new world")
end

function SaveLoad:draw(pass)
    -- Draw file dialog if open
    if self.fileDialog then
        self.fileDialog:draw(pass)
    end
end

return SaveLoad