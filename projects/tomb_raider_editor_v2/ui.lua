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
    local folder = self:getCurrentFolder()
    local folderPath = "textures/" .. folder .. "/"
    self.textures = {}
    
    -- Load all textures from the current folder
    for i = 1, 14 do  -- Adjust range based on your texture count
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
    
    -- Select first texture by default if available
    if #self.textures > 0 then
        self.selectedTexture = self.textures[1]
    end
end

function UI:setSelectedTextureByImage(texture)
    -- First, try to find it in the current folder
    for _, tex in ipairs(self.textures) do
        if tex.texture == texture then
            self.selectedTexture = tex
            return true
        end
    end
    
    -- If not found, we need to identify which folder this texture belongs to
    -- Try each folder until we find a match
    local originalFolder = self.currentFolderIndex
    
    for i, folder in ipairs(self.availableFolders) do
        self.currentFolderIndex = i
        self:loadTexturesFromCurrentFolder()
        
        for _, tex in ipairs(self.textures) do
            if tex.texture == texture then
                -- Found it!
                self.selectedTexture = tex
                return true
            end
        end
    end
    
    -- If we didn't find it, restore original folder
    self.currentFolderIndex = originalFolder
    self:loadTexturesFromCurrentFolder()
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
    
    -- Convert click coordinates to match our UI coordinate system
    -- UI uses top-down coordinates where 0 is at the top
    local uiY = height - y
    
    -- Calculate folder navigation area position (matching the draw function)
    local folderNavY = height - 70  -- This matches where we draw it
    
    -- Check if click is in the folder navigation area
    -- Note: Since we're in UI coordinates now (y=0 at top), we check if uiY is near folderNavY
    if math.abs(uiY - folderNavY) <= self.buttonHeight/2 then
        -- Previous folder button (left arrow)
        if x >= panelX and x < panelX + self.buttonWidth then
            print("Previous folder clicked") -- Debug print
            self:previousFolder()
            return true
        end
        
        -- Next folder button (right arrow)
        local nextButtonX = panelX + self.panelWidth - self.buttonWidth
        if x >= nextButtonX and x < panelX + self.panelWidth then
            print("Next folder clicked") -- Debug print
            self:nextFolder()
            return true
        end
        
        return true -- Clicked in folder navigation area but not on buttons
    end
    
    -- Convert click to panel-relative coordinates
    local relativeX = x - panelX - self.padding
    
    -- Get click Y in window coordinates (from top)
    local windowY = lovr.system.getWindowHeight() - y
    
    -- Calculate how far down from the start of texture grid we clicked
    local verticalOffset = self.startY - windowY
    
    -- Calculate row and column
    local spacing = self.textureSize + self.padding
    local row = math.floor(verticalOffset / spacing)
    local col = math.floor(relativeX / spacing)
    
    -- Calculate index
    local index = row * self.texPerRow + col + 1
    
    -- Check if we clicked a valid texture
    if index >= 1 and index <= #self.textures and col < self.texPerRow and row >= 0 then
        self.selectedTexture = self.textures[index]
        
        -- Update textures based on mode
        if self.world then
            if self.world.currentMode == self.world.MODE_SELECT and self.world.selectedBlock then
                -- In block select mode, update entire block
                self.world.selectedBlock:setTexture(self.selectedTexture.texture)
            elseif self.world.currentMode == self.world.MODE_FACE_SELECT and self.world.selectedFace then
                -- In face select mode, update only selected face
                self.world.selectedFace.block:setFaceTexture(
                    self.world.selectedFace.face,
                    self.selectedTexture.texture
                )
            end
        end
        
        return true
    end
    
    return false
end

return UI