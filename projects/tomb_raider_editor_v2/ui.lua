local UI = {
    -- Panel dimensions and styling
    panelWidth = 300,
    backgroundColor = {0.2, 0.2, 0.2, 0.9},
    padding = 10,
    
    -- References to other modules
    camera = nil,
    world = nil,
    saveload = nil,
    
    -- Texture management
    textures = {},
    textureSize = 64,
    selectedTexture = nil,
    startY = nil,
    texPerRow = nil,
    
    -- Folder navigation
    availableFolders = {"Brick", "Floor", "Metal", "Misc", "Stains", "Stone", "Wall"},
    currentFolderIndex = 1,
    
    -- Common UI element sizes
    buttonWidth = 30,
    buttonHeight = 30,
    
    -- Mode indicator properties
    modeIndicatorWidth = 200,
    modeIndicatorHeight = 40,
    modeColors = {
        PLACE = {0.2, 0.8, 0.2, 0.8},       -- Green for place mode
        SELECT = {0.2, 0.2, 0.8, 0.8},      -- Blue for select mode
        FACE_SELECT = {0.8, 0.2, 0.8, 0.8}  -- Purple for face select mode
    },

    -- File operation buttons
    fileButtons = {
        { text = "New", shortcut = "Ctrl+N", action = "new" },
        { text = "Save", shortcut = "Ctrl+S", action = "save" },
        { text = "Save As", shortcut = "Ctrl+Shift+S", action = "saveas" },
        { text = "Load", shortcut = "Ctrl+O", action = "load" }
    },

    -- Button state tracking
    hoveredButton = nil,
    activeButton = nil,  -- Currently pressed button

    -- Button colors
    buttonColors = {
        normal = {0.3, 0.3, 0.3, 1},
        hover = {0.4, 0.4, 0.4, 1},
        active = {0.2, 0.2, 0.2, 1},
    },

    -- Button text colors
    buttonTextColors = {
        normal = {1, 1, 1, 1},
        hover = {1, 1, 1, 1},
        active = {0.8, 0.8, 0.8, 1},
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
    -- Store current texture info before loading new folder
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
    
    -- Restore previous texture selection if possible
    if previousTexture then
        if previousTexture.folder == folder then
            for _, tex in ipairs(self.textures) do
                if tex.number == previousTexture.number then
                    self.selectedTexture = tex
                    return
                end
            end
        end
    end
    
    -- Fall back to first texture if needed
    if #self.textures > 0 and not self.selectedTexture then
        self.selectedTexture = self.textures[1]
    end
end

function UI:isPointInButton(x, y, buttonX, buttonY, width, height)
    return x >= buttonX - width/2 and 
           x <= buttonX + width/2 and 
           y >= buttonY - height/2 and 
           y <= buttonY + height/2
end

function UI:updateHoveredButton(x, y)
    local width = lovr.system.getWindowWidth()
    local height = lovr.system.getWindowHeight()
    local panelX = width - self.panelWidth
    local buttonWidth = self.panelWidth / #self.fileButtons

    self.hoveredButton = nil
    
    -- Buttons are now 60 pixels from bottom
    if y >= (height - 60) and y <= (height - 60 + self.buttonHeight) then
        local buttonIndex = math.floor((x - panelX) / buttonWidth) + 1
        if buttonIndex >= 1 and buttonIndex <= #self.fileButtons then
            self.hoveredButton = self.fileButtons[buttonIndex]
        end
    end
end

function UI:mousepressed(x, y, button)
    if button == 1 then -- Left click
        self.activeButton = self.hoveredButton
    end
end

function UI:mousereleased(x, y, button)
    if button == 1 and self.activeButton and self.hoveredButton == self.activeButton then
        -- Handle the button click
        if self.activeButton.action == "new" then
            if self.saveload then
                self.saveload:newWorld(self.world)
            end
        elseif self.activeButton.action == "save" then
            if self.saveload then
                if self.saveload.currentFilename then
                    self.saveload:saveWorld(self.world, self.saveload.currentFilename)
                else
                    self.saveload:saveWorld(self.world, "world.json")
                end
            end
        elseif self.activeButton.action == "saveas" then
            if self.saveload then
                local timestamp = os.date("%Y%m%d_%H%M%S")
                self.saveload:saveWorld(self.world, "world_" .. timestamp .. ".json")
            end
        elseif self.activeButton.action == "load" then
            if self.saveload then
                self.saveload:loadWorld(self.world, "world.json")
            end
        end
    end
    self.activeButton = nil
end

function UI:drawFileButtons(pass, x, y)
    local buttonWidth = self.panelWidth / #self.fileButtons
    
    for i, button in ipairs(self.fileButtons) do
        local buttonX = x + (i-1) * buttonWidth + buttonWidth/2
        local buttonY = y - self.buttonHeight/2
        
        -- Determine button state
        local buttonState = "normal"
        if self.activeButton == button and self.hoveredButton == button then
            buttonState = "active"
        elseif self.hoveredButton == button then
            buttonState = "hover"
        end
        
        -- Draw button background with appropriate color
        pass:setColor(unpack(self.buttonColors[buttonState]))
        pass:plane(
            buttonX,
            buttonY,
            0,
            buttonWidth - 4,
            self.buttonHeight
        )
        
        -- Draw button text with appropriate color
        pass:setColor(unpack(self.buttonTextColors[buttonState]))
        pass:text(
            button.text,
            buttonX,
            buttonY,
            0,
            0.4
        )
    end
    
    -- Draw current filename if one is set
    if self.saveload and self.saveload.currentFilename then
        pass:setColor(0.8, 0.8, 0.8, 0.6)
        pass:text(
            "Current: " .. self.saveload.currentFilename,
            x + self.padding,
            y + self.buttonHeight + 5,
            0,
            0.3,
            0,
            0, 1, 0,
            0,
            'left'
        )
    end
    
    return y + self.buttonHeight
end

function UI:drawFolderNavigation(pass, x, y)
    -- Previous folder button
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
    
    -- Current folder name
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
    
    -- Next folder button
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

function UI:drawModeIndicator(pass)
    if not self.world then return end

    local currentMode = self.world.currentMode
    local bgColor = self.modeColors[currentMode] or {0.2, 0.2, 0.2, 0.8}
    
    -- Draw background
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

function UI:drawStatusMessage(pass, x, y)
    if not self.saveload then return y end

    if self.saveload.lastError then
        -- Draw error message in red
        pass:setColor(1, 0.2, 0.2, 1)
        pass:text(
            self.saveload.lastError,
            x + self.padding,
            y - 20,
            0,
            0.4,
            0,
            0, 1, 0,
            0,
            'left'
        )
        return y - 40
    elseif self.saveload.lastMessage then
        -- Draw success message in green
        pass:setColor(0.2, 1, 0.2, 1)
        pass:text(
            self.saveload.lastMessage,
            x + self.padding,
            y - 20,
            0,
            0.4,
            0,
            0, 1, 0,
            0,
            'left'
        )
        return y - 40
    end
    
    return y
end

function UI:draw(pass)
    -- Get window dimensions
    local width, height = lovr.system.getWindowDimensions()
    
    -- Draw camera info in top right of 3D view (before UI panel)
    pass:setColor(1, 1, 1, 0.7)
    local cameraText = self.camera:getDebugText()
    pass:text(
        cameraText,
        width - self.panelWidth - 20, -- 20 pixels padding from UI panel
        30,  -- 30 pixels from top
        0,
        0.3,  -- Smaller text size
        0,
        0, 1, 0,
        0,
        'right'
    )
    
    -- Set up 2D orthographic projection for UI
    local projection = mat4():orthographic(0, width, height, 0, -10, 10)
    pass:setProjection(1, projection)
    
    -- Reset view transform
    pass:setViewPose(1, mat4():identity())
    
    -- Draw mode indicator
    self:drawModeIndicator(pass)
    
    -- Calculate panel position
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
    
    -- Draw title
    pass:setColor(1, 1, 1, 1)
    local font = lovr.graphics.getDefaultFont()
    font:setPixelDensity(1)
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

    -- Draw selected texture info (moved lower)
    if self.selectedTexture then
        pass:text(
            "Selected: " .. self.selectedTexture.name,
            panelX + self.padding,
            height - 100,  -- Moved from 90 to 100
            0,
            0.4,
            0,
            0, 1, 0,
            0,
            'left'
        )
    end
    
    -- Set up texture grid
    self.startY = height - 130  -- Adjusted to account for selected text movement
    self.texPerRow = math.floor((self.panelWidth - self.padding * 2) / self.textureSize)
    local spacing = self.textureSize + self.padding
    
    -- Draw texture grid
    for i, tex in ipairs(self.textures) do
        local row = math.floor((i-1) / self.texPerRow)
        local col = (i-1) % self.texPerRow
        
        local x = panelX + self.padding + col * spacing
        local y = self.startY - row * spacing
        
        -- Draw texture
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
        
        -- Draw selection highlight
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
    
    -- Draw file buttons at the very bottom with padding
    pass:setColor(0.15, 0.15, 0.15, 1)  -- Darker background for button area
    pass:plane(
        panelX + self.panelWidth/2,
        40,  -- Height for button area
        0,
        self.panelWidth,
        80  -- Area for buttons and filename
    )
    local nextY = self:drawFileButtons(pass, panelX, 60)  -- 60 pixels from bottom
    
    -- Draw status message
    self:drawStatusMessage(pass, panelX, nextY)
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

    -- Check folder navigation buttons
    local folderNavY = height - 70
    if math.abs(height - y - folderNavY) <= self.buttonHeight/2 then
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

    -- Check texture grid clicks
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
                -- Update all selected blocks
                for _, block in ipairs(self.world.selectedBlocks) do
                    block:setTexture(selectedTex.texture, textureInfo)
                end
            elseif self.world.currentMode == self.world.MODE_FACE_SELECT then
                -- Update all selected faces
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

function UI:setSelectedTextureByImage(texture, textureInfo)
    if not texture or not textureInfo then return false end
    
    -- Switch to correct folder if needed
    if textureInfo.folder ~= self:getCurrentFolder() then
        self.currentFolderIndex = self:getFolderIndex(textureInfo.folder)
        self:loadTexturesFromCurrentFolder()
    end
    
    -- Find and select matching texture
    for _, tex in ipairs(self.textures) do
        if tex.folder == textureInfo.folder and tex.number == textureInfo.number then
            self.selectedTexture = tex
            return true
        end
    end
    
    return false
end

function UI:getTextureInfo(texture)
    -- Try to find in current folder first
    for _, tex in ipairs(self.textures) do
        if tex.texture == texture then
            return {
                folder = tex.folder,
                number = tex.number
            }
        end
    end

    -- Get original texture's filename pattern
    local origFilename = self:getTextureFilenameFromObject(texture)
    if origFilename then
        local folder, number = origFilename:match("Horror_([^_]+)_(%d+)")
        if folder and number then
            return {
                folder = folder,
                number = tonumber(number)
            }
        end
    end

    return nil
end

function UI:getTextureFilenameFromObject(texture)
    for _, tex in ipairs(self.textures) do
        if tex.texture == texture then
            return string.format("Horror_%s_%02d-128x128.png", tex.folder, tex.number)
        end
    end
    return nil
end

return UI