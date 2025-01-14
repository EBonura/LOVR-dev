local UI = {
    panelWidth = 300,  -- Width in pixels
    backgroundColor = {0.2, 0.2, 0.2, 0.9},
    camera = nil,      -- Camera reference
    textures = {},     -- Store loaded textures
    textureSize = 64,  -- Display size for texture previews
    padding = 10,      -- Padding between elements
    selectedTexture = nil, -- Currently selected texture
    startY = nil,      -- Starting Y position for texture grid
    texPerRow = nil,   -- Number of textures per row
    world = nil,       -- Reference to world
    
    -- New properties for folder navigation
    availableFolders = {"Brick", "Floor", "Metal", "Misc", "Stains", "Stone", "Wall"},
    currentFolderIndex = 1,
    buttonWidth = 30,
    buttonHeight = 30,
    
    -- Mode indicator properties
    modeIndicatorWidth = 200,
    modeIndicatorHeight = 40,
    modeColors = {
        PLACE = {0.2, 0.8, 0.2, 0.8},       -- Green for place mode
        SELECT = {0.2, 0.2, 0.8, 0.8},      -- Blue for select mode
        FACE_SELECT = {0.8, 0.2, 0.8, 0.8}  -- Purple for face select mode
    }
}

function UI:new(camera)
    local ui = setmetatable({}, { __index = UI })
    ui.camera = camera
    ui:loadTexturesFromCurrentFolder()
    return ui
end

function UI:getCurrentFolder()
    return self.availableFolders[self.currentFolderIndex]
end

function UI:nextFolder()
    self.currentFolderIndex = self.currentFolderIndex % #self.availableFolders + 1
    self:loadTexturesFromCurrentFolder()
end

function UI:previousFolder()
    self.currentFolderIndex = (self.currentFolderIndex - 2) % #self.availableFolders + 1
    self:loadTexturesFromCurrentFolder()
end

function UI:loadTexturesFromCurrentFolder()
    -- Store the current texture info before loading new folder
    local previousTexture = nil
    if self.selectedTexture then
        previousTexture = {
            folder = self.selectedTexture.folder,
            number = self.selectedTexture.number
        }
    end

    local folder = self:getCurrentFolder()
    local folderPath = "textures/" .. folder .. "/"
    self.textures = {}
    
    -- Load all textures from the current folder
    for i = 1, 14 do
        local filename = string.format("Horror_%s_%02d-128x128.png", folder, i)
        local path = folderPath .. filename
        
        -- Try to load the texture
        local success, texture = pcall(lovr.graphics.newTexture, path)
        if success then
            table.insert(self.textures, {
                texture = texture,
                name = filename,
                path = path,
                folder = folder,
                number = i
            })
        end
    end
    
    -- Only select first texture if we don't have a previous selection
    if previousTexture then
        -- Try to find the matching texture in new folder
        if previousTexture.folder == folder then
            for _, tex in ipairs(self.textures) do
                if tex.number == previousTexture.number then
                    self.selectedTexture = tex
                    return
                end
            end
        end
    end
    
    -- Fall back to first texture only if no previous selection
    if #self.textures > 0 and not self.selectedTexture then
        self.selectedTexture = self.textures[1]
    end
end

function UI:findTextureInFolder(texture, folder)
    -- First, try to find the original texture's path
    local originalPath = nil
    for _, tex in ipairs(self.textures) do
        if tex.texture == texture then
            originalPath = tex.path
            break
        end
    end
    
    -- If we couldn't find the original path, try to construct it from the pattern
    if not originalPath then
        local folderPath = "textures/" .. folder .. "/"
        for i = 1, 14 do
            local filename = string.format("Horror_%s_%02d-128x128.png", folder, i)
            local path = folderPath .. filename
            
            -- Try to load this texture
            local success, testTexture = pcall(lovr.graphics.newTexture, path)
            if success and testTexture == texture then
                originalPath = path
                break
            end
        end
    end
    
    if not originalPath then
        return false
    end
    
    -- Switch to the target folder and load its textures
    local prevIndex = self.currentFolderIndex
    self.currentFolderIndex = self:getFolderIndex(folder)
    self:loadTexturesFromCurrentFolder()
    
    -- Find and select the matching texture by comparing paths
    for _, tex in ipairs(self.textures) do
        if tex.path == originalPath then
            self.selectedTexture = tex
            return true
        end
    end
    
    -- If we didn't find a match, revert to the previous folder
    self.currentFolderIndex = prevIndex
    self:loadTexturesFromCurrentFolder()
    return false
end


function UI:getFolderIndex(folderName)
    for i, folder in ipairs(self.availableFolders) do
        if folder == folderName then
            return i
        end
    end
    return 1  -- Default to first folder if not found
end

function UI:getTextureFilenameFromObject(texture)
    -- Try to find the texture in current folder first
    for _, tex in ipairs(self.textures) do
        if tex.texture == texture then
            return string.format("Horror_%s_%02d-128x128.png", tex.folder, tex.number)
        end
    end
    return nil
end

function UI:getTextureInfo(texture)
    -- Try to find it in current folder first
    for _, tex in ipairs(self.textures) do
        if tex.texture == texture then
            return {
                folder = tex.folder,
                number = tex.number
            }
        end
    end
    
    -- Get the original texture's filename pattern
    local origFilename = self:getTextureFilenameFromObject(texture)
    if origFilename then
        -- Extract folder and number from filename
        local folder, number = origFilename:match("Horror_([^_]+)_(%d+)")
        if folder and number then
            number = tonumber(number)
            return {
                folder = folder,
                number = number
            }
        end
    end
    
    return nil
end

function UI:setSelectedTextureByImage(texture, textureInfo)
    if not texture or not textureInfo then 
        return false 
    end
    
    -- Switch to the correct folder if needed
    if textureInfo.folder ~= self:getCurrentFolder() then
        self.currentFolderIndex = self:getFolderIndex(textureInfo.folder)
        self:loadTexturesFromCurrentFolder()
    end
    
    -- Find and select the texture with matching number
    for _, tex in ipairs(self.textures) do
        if tex.folder == textureInfo.folder and tex.number == textureInfo.number then
            self.selectedTexture = tex
            return true
        end
    end
    
    return false
end

function UI:drawModeIndicator(pass)
    if not self.world then return end
    
    -- Draw background panel
    local currentMode = self.world.currentMode
    local bgColor = self.modeColors[currentMode] or {0.2, 0.2, 0.2, 0.8}
    pass:setColor(unpack(bgColor))
    pass:plane(
        self.modeIndicatorWidth/2,
        self.modeIndicatorHeight/2,
        0,
        self.modeIndicatorWidth,
        self.modeIndicatorHeight
    )
    
    -- Draw mode text
    pass:setColor(1, 1, 1, 1)
    pass:text(
        currentMode .. " MODE",
        10,
        self.modeIndicatorHeight/2,
        0,
        0.5,
        0,
        0, 1, 0,
        0,
        'left'
    )
    
    -- Draw shortcut hint
    pass:setColor(1, 1, 1, 0.7)
    pass:text(
        "[TAB] to switch",
        self.modeIndicatorWidth - 10,
        self.modeIndicatorHeight/2,
        0,
        0.3,
        0,
        0, 1, 0,
        0,
        'right'
    )
end

function UI:drawFolderNavigation(pass, x, y)
    -- Draw previous folder button
    pass:setColor(0.3, 0.3, 0.3, 1)
    pass:plane(
        x + self.buttonWidth/2,
        y,
        0,
        self.buttonWidth,
        self.buttonHeight
    )
    pass:setColor(1, 1, 1, 1)
    pass:text("<", x + self.buttonWidth/2, y, 0, 0.8)
    
    -- Draw current folder name
    local folderNameWidth = self.panelWidth - (2 * self.buttonWidth) - (2 * self.padding)
    pass:setColor(0.25, 0.25, 0.25, 1)
    pass:plane(
        x + self.buttonWidth + self.padding + folderNameWidth/2,
        y,
        0,
        folderNameWidth,
        self.buttonHeight
    )
    pass:setColor(1, 1, 1, 1)
    pass:text(
        self:getCurrentFolder(),
        x + self.buttonWidth + self.padding + folderNameWidth/2,
        y,
        0,
        0.6
    )
    
    -- Draw next folder button
    pass:setColor(0.3, 0.3, 0.3, 1)
    pass:plane(
        x + self.panelWidth - self.buttonWidth/2,
        y,
        0,
        self.buttonWidth,
        self.buttonHeight
    )
    pass:setColor(1, 1, 1, 1)
    pass:text(">", x + self.panelWidth - self.buttonWidth/2, y, 0, 0.8)
end

function UI:draw(pass)
    -- Get window dimensions
    local width, height = lovr.system.getWindowDimensions()
    
    -- Set up 2D orthographic projection
    local projection = mat4():orthographic(0, width, height, 0, -10, 10)
    pass:setProjection(1, projection)
    
    -- Reset view transform
    pass:setViewPose(1, mat4():identity())
    
    -- Draw mode indicator first
    self:drawModeIndicator(pass)
    
    -- Calculate panel position (right side of screen)
    local panelX = width - self.panelWidth
    
    -- Draw panel background
    pass:setColor(unpack(self.backgroundColor))
    pass:plane(
        panelX + self.panelWidth/2,
        height/2,
        0,
        self.panelWidth,
        height
    )
    
    -- Set up text
    pass:setColor(1, 1, 1, 1)
    local font = lovr.graphics.getDefaultFont()
    font:setPixelDensity(1)
    
    -- Draw title
    pass:text(
        "Texture Panel",
        panelX + self.padding,
        height - 30,
        0,
        0.8,
        0,
        0, 1, 0,
        0,
        'left'
    )

    -- Draw folder navigation
    self:drawFolderNavigation(pass, panelX, height - 70)

    -- Draw selected texture info right below folder navigation
    if self.selectedTexture then
        pass:text(
            "Selected: " .. self.selectedTexture.name,
            panelX + self.padding,
            height - 90,
            0,
            0.4,
            0,
            0, 1, 0,
            0,
            'left'
        )
    end
    
    -- Update class variables for click detection
    self.startY = height - 120  -- Adjusted to account for folder navigation
    self.texPerRow = math.floor((self.panelWidth - self.padding * 2) / self.textureSize)
    local spacing = self.textureSize + self.padding
    
    -- Draw textures grid
    for i, tex in ipairs(self.textures) do
        local row = math.floor((i-1) / self.texPerRow)
        local col = (i-1) % self.texPerRow
        
        local x = panelX + self.padding + col * spacing
        local y = self.startY - row * spacing
        
        -- Draw texture preview
        pass:setColor(1, 1, 1, 1)
        pass:setMaterial(tex.texture)
        pass:plane(
            x + self.textureSize/2,
            y - self.textureSize/2,
            0,
            self.textureSize,
            self.textureSize
        )
        pass:setMaterial()
        
        -- Draw selection highlight if this is the selected texture
        if self.selectedTexture == tex then
            pass:setColor(1, 0, 0, 1)
            pass:line(
                x, y, 0,
                x + self.textureSize, y, 0
            )
            pass:line(
                x + self.textureSize, y, 0,
                x + self.textureSize, y - self.textureSize, 0
            )
            pass:line(
                x + self.textureSize, y - self.textureSize, 0,
                x, y - self.textureSize, 0
            )
            pass:line(
                x, y - self.textureSize, 0,
                x, y, 0
            )
        end
    end
    
    -- Draw debug info at the bottom
    pass:setColor(1, 1, 1, 1)
    pass:text(
        self.camera:getDebugText(),
        panelX + self.padding,
        60,
        0,
        0.6,
        0,
        0, 1, 0,
        0,
        'left'
    )
end

function UI:isPointInPanel(x, y)
    local width = lovr.system.getWindowWidth()
    return x >= (width - self.panelWidth)
end

function UI:handleClick(x, y)
    if not self:isPointInPanel(x, y) then
        return false
    end
    
    -- Get window and panel coordinates
    local width = lovr.system.getWindowWidth()
    local height = lovr.system.getWindowHeight()
    local panelX = width - self.panelWidth
    
    local uiY = height - y
    local folderNavY = height - 70
    
    if math.abs(uiY - folderNavY) <= self.buttonHeight/2 then
        if x >= panelX and x < panelX + self.buttonWidth then
            self:previousFolder()
            return true
        end
        
        local nextButtonX = panelX + self.panelWidth - self.buttonWidth
        if x >= nextButtonX and x < panelX + self.panelWidth then
            self:nextFolder()
            return true
        end
        return true
    end
    
    local relativeX = x - panelX - self.padding
    local windowY = lovr.system.getWindowHeight() - y
    local verticalOffset = self.startY - windowY
    local spacing = self.textureSize + self.padding
    local row = math.floor(verticalOffset / spacing)
    local col = math.floor(relativeX / spacing)
    local index = row * self.texPerRow + col + 1
    
    if index >= 1 and index <= #self.textures and col < self.texPerRow and row >= 0 then
        local selectedTex = self.textures[index]
        self.selectedTexture = selectedTex
        
        -- Create texture info
        local textureInfo = {
            folder = selectedTex.folder,
            number = selectedTex.number
        }
        
        -- Update textures based on mode
        if self.world then
            if self.world.currentMode == self.world.MODE_SELECT then
                -- In block select mode, update all selected blocks
                for _, block in ipairs(self.world.selectedBlocks) do
                    block:setTexture(selectedTex.texture, textureInfo)
                end
            elseif self.world.currentMode == self.world.MODE_FACE_SELECT then
                -- In face select mode, update all selected faces
                for _, faceInfo in ipairs(self.world.selectedFaces) do
                    local block = faceInfo.block
                    local face = faceInfo.face
                    block:setFaceTexture(
                        face,
                        selectedTex.texture,
                        textureInfo
                    )
                end
            end
        end
        
        return true
    end
    
    return false
end

return UI
