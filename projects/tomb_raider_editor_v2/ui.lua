local UI = {
    panelWidth = 300,  -- Width in pixels
    backgroundColor = {0.2, 0.2, 0.2, 0.9},
    camera = nil,      -- Camera reference
    textures = {},     -- Store loaded textures
    textureSize = 64,  -- Display size for texture previews
    padding = 10,      -- Padding between elements
    selectedTexture = nil, -- Currently selected texture
    startY = nil,      -- Starting Y position for texture grid
    texPerRow = nil    -- Number of textures per row
}

function UI:new(camera)
    local ui = setmetatable({}, { __index = UI })
    ui.camera = camera
    ui:loadTextures()
    -- Select first texture by default
    if #ui.textures > 0 then
        ui.selectedTexture = ui.textures[1]
    end
    return ui
end

function UI:setSelectedTextureByImage(texture)
    -- Find and select the texture entry that matches the given texture
    for _, tex in ipairs(self.textures) do
        if tex.texture == texture then
            self.selectedTexture = tex
            return true
        end
    end
    return false
end

function UI:loadTextures()
    -- Load all brick textures
    local brickPath = "textures/Brick/"
    self.textures = {}
    
    -- List of brick textures
    local brickTextures = {
        "Horror_Brick_01-128x128.png",
        "Horror_Brick_02-128x128.png",
        "Horror_Brick_03-128x128.png",
        "Horror_Brick_04-128x128.png",
        "Horror_Brick_05-128x128.png",
        "Horror_Brick_06-128x128.png",
        "Horror_Brick_07-128x128.png",
        "Horror_Brick_08-128x128.png",
        "Horror_Brick_09-128x128.png",
        "Horror_Brick_10-128x128.png",
        "Horror_Brick_11-128x128.png",
        "Horror_Brick_12-128x128.png",
        "Horror_Brick_13-128x128.png",
        "Horror_Brick_14-128x128.png"
    }
    
    -- Load each texture
    for _, filename in ipairs(brickTextures) do
        local path = brickPath .. filename
        local texture = lovr.graphics.newTexture(path)
        table.insert(self.textures, {
            texture = texture,
            name = filename,
            path = path
        })
    end
end

function UI:draw(pass)
    -- Get window dimensions
    local width, height = lovr.system.getWindowDimensions()
    
    -- Set up 2D orthographic projection
    local projection = mat4():orthographic(0, width, height, 0, -10, 10)
    pass:setProjection(1, projection)
    
    -- Reset view transform
    pass:setViewPose(1, mat4():identity())
    
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

    -- Draw selected texture info right below title
    if self.selectedTexture then
        pass:text(
            "Selected: " .. self.selectedTexture.name,
            panelX + self.padding,
            height - 50,
            0,
            0.4,
            0,
            0, 1, 0,
            0,
            'left'
        )
    end
    
    -- Update class variables for click detection - moved down for more space
    self.startY = height - 80  -- Start below title and selected texture info
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
    
    -- Convert click to panel-relative coordinates
    local panelX = lovr.system.getWindowWidth() - self.panelWidth
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
        
        -- If we have a world reference and there's a selected block in SELECT mode,
        -- update its texture
        if self.world and 
           self.world.currentMode == self.world.MODE_SELECT and 
           self.world.selectedBlock then
            self.world.selectedBlock:setTexture(self.selectedTexture.texture)
        end
        
        return true
    end
    
    return false
end

return UI