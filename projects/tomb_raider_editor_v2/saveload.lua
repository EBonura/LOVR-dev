-- saveload.lua
local Block = require('block')

local SaveLoad = {
    currentFilename = nil
}

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

function SaveLoad:saveWorld(world, filename)
    local data = {
        blocks = {},
        gridY = world.currentGridY -- Save current grid height
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
    local json = require('json') -- You'll need to add a JSON library
    local jsonString = json.encode(data)
    
    -- Save to file
    local success = lovr.filesystem.write(filename, jsonString)
    if success then
        self.currentFilename = filename
        return true
    end
    return false
end

function SaveLoad:loadWorld(world, filename)
    -- Read file contents
    local contents = lovr.filesystem.read(filename)
    if not contents then return false end
    
    -- Parse JSON
    local json = require('json')
    local data = json.decode(contents)
    if not data then return false end
    
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
    return true
end

function SaveLoad:newWorld(world)
    -- Clear all blocks
    world.blocks = {}
    -- Reset grid height
    world.currentGridY = 0
    -- Clear current filename
    self.currentFilename = nil
end

return SaveLoad