local UI = {
    panelWidth = 300,  -- Width in pixels
    backgroundColor = {0.2, 0.2, 0.2, 0.9},
    camera = nil,      -- Camera reference
    textures = {},     -- Store loaded textures
    textureSize = 64,  -- Display size for texture previews
    padding = 10,      -- Padding between elements
    selectedTexture = nil -- Currently selected texture
}

function UI:new(camera)
    local ui = setmetatable({}, { __index = UI })
    ui.camera = camera
    ui:loadTextures()
    return ui
end

function UI:loadTextures()
    -- Load all brick textures
    local brickPath = "textures/Brick/"
    self.textures = {}
    
    -- List of brick textures (hardcoded for now)
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
    
    -- Draw textures grid
    local startY = height - 60  -- Start below title
    local texPerRow = math.floor((self.panelWidth - self.padding * 2) / self.textureSize)
    local spacing = self.textureSize + self.padding
    
    for i, tex in ipairs(self.textures) do
        local row = math.floor((i-1) / texPerRow)
        local col = (i-1) % texPerRow
        
        local x = panelX + self.padding + col * spacing
        local y = startY - row * spacing
        
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
            pass:setColor(1, 1, 0, 0.5)
            pass:line(
                x, y,
                x + self.textureSize, y,
                x + self.textureSize, y - self.textureSize,
                x, y - self.textureSize,
                x, y
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
    local relativeY = lovr.system.getWindowHeight() - y
    
    -- Calculate grid position
    local texPerRow = math.floor((self.panelWidth - self.padding * 2) / self.textureSize)
    local spacing = self.textureSize + self.padding
    
    local col = math.floor(relativeX / spacing)
    local row = math.floor((lovr.system.getWindowHeight() - 60 - relativeY) / spacing)
    
    local index = row * texPerRow + col + 1
    
    -- Check if we clicked a valid texture
    if index >= 1 and index <= #self.textures then
        self.selectedTexture = self.textures[index]
        return true
    end
    
    return false
end

return UI