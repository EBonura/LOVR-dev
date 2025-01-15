-- FileDialog.lua
local FileDialog = {
    -- Dialog state
    isOpen = false,
    mode = nil, -- "save" or "load"
    
    -- Dimensions and styling
    width = 600,
    height = 400,
    padding = 10,
    buttonHeight = 30,
    backgroundColor = {0.2, 0.2, 0.2, 0.95},
    
    -- Layout dimensions
    titleOffset = 30,      -- Height for title
    pathOffset = 30,       -- Height for path
    headerPadding = 20,    -- Padding after header elements
    
    -- Input field
    filename = "",
    isInputActive = false,
    cursorBlink = 0,
    cursorBlinkRate = 0.5,
    
    -- File listing
    currentPath = "",
    files = {},
    selectedFile = nil,
    scrollOffset = 0,
    itemHeight = 25,
    maxVisibleItems = 10,
    
    -- Callbacks
    onComplete = nil,
    onCancel = nil,
    
    -- Button colors (matching UI style)
    buttonColors = {
        normal = {0.3, 0.3, 0.3, 1},
        hover = {0.4, 0.4, 0.4, 1},
        active = {0.2, 0.2, 0.2, 1}
    },
    
    -- Hover state
    hoveredButton = nil,
    activeButton = nil,
    hoveredItem = nil
}

function FileDialog:new()
    local dialog = setmetatable({}, { __index = FileDialog })
    dialog:initialize()
    return dialog
end

function FileDialog:initialize()
    -- Mount the existing levels directory
    local levelsPath = lovr.filesystem.getSource() .. "/levels"
    lovr.filesystem.mount(levelsPath, "levels")
    print("Mounted levels directory:", levelsPath)
    
    -- Start in the levels directory
    self.currentPath = "levels"
    self:refreshFileList()
    self.hoveredItem = nil
end

function FileDialog:refreshFileList()
    self.files = {}
    
    -- Add parent directory option if not at levels root
    if self.currentPath ~= "levels" then
        table.insert(self.files, {
            name = "..",
            isDirectory = true
        })
    end
    
    -- Get all files and directories from current path
    local items = lovr.filesystem.getDirectoryItems(self.currentPath)
    
    -- Debug output
    print("Current path:", self.currentPath)
    print("Number of items found:", #items)
    
    for _, item in ipairs(items) do
        local itemPath = self.currentPath .. "/" .. item
        local isDirectory = lovr.filesystem.isDirectory(itemPath)
        
        -- Only show .json files and directories
        if isDirectory or item:match("%.json$") then
            print("Found item:", item, "Is directory:", isDirectory)
            table.insert(self.files, {
                name = item,
                isDirectory = isDirectory
            })
        end
    end
    
    -- Sort: directories first, then files
    table.sort(self.files, function(a, b)
        if a.isDirectory and not b.isDirectory then return true end
        if not a.isDirectory and b.isDirectory then return false end
        return a.name:lower() < b.name:lower()
    end)
end

function FileDialog:show(mode, defaultFilename, onComplete, onCancel)
    self.isOpen = true
    self.mode = mode
    self.filename = defaultFilename or ""
    self.onComplete = onComplete
    self.onCancel = onCancel
    self:refreshFileList()
end

function FileDialog:hide()
    self.isOpen = false
    self.filename = ""
    self.selectedFile = nil
    self.onComplete = nil
    self.onCancel = nil
end

function FileDialog:isPointInButton(x, y, buttonX, buttonY, width, height)
    return x >= buttonX - width/2 and 
           x <= buttonX + width/2 and 
           y >= buttonY - height/2 and 
           y <= buttonY + height/2
end

function FileDialog:handleKeyPressed(key)
    if not self.isOpen then return false end
    
    if self.isInputActive then
        if key == "backspace" then
            self.filename = self.filename:sub(1, -2)
            return true
        elseif key == "return" then
            self.isInputActive = false
            if self.onComplete then
                self.onComplete(self.currentPath .. "/" .. self.filename)
            end
            self:hide()
            return true
        elseif key == "escape" then
            self.isInputActive = false
            return true
        end
    elseif key == "escape" then
        if self.onCancel then
            self.onCancel()
        end
        self:hide()
        return true
    end
    
    return false
end

function FileDialog:handleTextInput(text)
    if not self.isOpen or not self.isInputActive then return false end
    
    -- Filter out non-printable characters
    if text:match("^[%w%p%s]$") then
        self.filename = self.filename .. text
        return true
    end
    
    return false
end

function FileDialog:handleMousePressed(x, y, button)
    if not self.isOpen then return false end
    
    local windowWidth, windowHeight = lovr.system.getWindowDimensions()
    local dialogX = (windowWidth - self.width) / 2
    local dialogY = (windowHeight - self.height) / 2
    local yPos = self:getListYPositions()
    local windowY = y
    
    -- Check if click is within dialog bounds
    if x < dialogX or x > dialogX + self.width or
       windowY < dialogY or windowY > dialogY + self.height then
        if self.onCancel then
            self.onCancel()
        end
        self:hide()
        return true
    end
    
    -- Check filename input field
    local inputY = dialogY + self.height - 2 * (self.buttonHeight + self.padding)
    if windowY >= inputY and windowY <= inputY + self.buttonHeight then
        self.isInputActive = true
        return true
    end
    
    -- Check file list - using positions from getListYPositions
    if x >= dialogX + self.padding and x <= dialogX + self.width - self.padding and
       windowY >= yPos.listStart and windowY <= yPos.listStart + yPos.contentArea then
        
        local relativeY = windowY - yPos.listStart
        local itemIndex = math.floor(relativeY / self.itemHeight) + 1 + self.scrollOffset
        
        if itemIndex >= 1 and itemIndex <= #self.files then
            local file = self.files[itemIndex]
            if file.isDirectory then
                if file.name == ".." then
                    -- Go up one directory
                    self.currentPath = self.currentPath:match("(.*)/.*$") or "levels"
                else
                    -- Enter directory
                    self.currentPath = self.currentPath .. "/" .. file.name
                end
                self:refreshFileList()
            else
                -- Select file
                self.selectedFile = file
                self.filename = file.name
            end
            return true
        end
    end
    
    -- Check buttons
    local buttonY = dialogY + self.height - self.buttonHeight - self.padding
    if windowY >= buttonY and windowY <= buttonY + self.buttonHeight then
        local buttonWidth = (self.width - 3 * self.padding) / 2
        local confirmX = dialogX + self.padding + buttonWidth/2
        local cancelX = dialogX + self.width - buttonWidth/2 - self.padding
        
        if x >= confirmX - buttonWidth/2 and x <= confirmX + buttonWidth/2 then
            -- Confirm button
            if self.onComplete then
                self.onComplete(self.currentPath .. "/" .. self.filename)
            end
            self:hide()
            return true
        elseif x >= cancelX - buttonWidth/2 and x <= cancelX + buttonWidth/2 then
            -- Cancel button
            if self.onCancel then
                self.onCancel()
            end
            self:hide()
            return true
        end
    end
    
    return false
end

function FileDialog:getListYPositions()
    local windowHeight = lovr.system.getWindowHeight()
    local dialogY = (windowHeight - self.height) / 2
    
    -- Calculate consistent positions used across all functions
    return {
        listStart = dialogY + self.titleOffset + self.pathOffset + self.headerPadding,
        contentArea = self.height - (2 * self.buttonHeight + 3 * self.padding)
    }
end

function FileDialog:handleMouseMoved(x, y)
    if not self.isOpen then return false end
    
    local windowWidth, windowHeight = lovr.system.getWindowDimensions()
    local dialogX = (windowWidth - self.width) / 2
    local dialogY = (windowHeight - self.height) / 2
    local yPos = self:getListYPositions()
    
    -- Check if mouse is in file list area
    if x >= dialogX + self.padding and x <= dialogX + self.width - self.padding and
       y >= yPos.listStart and y <= yPos.listStart + yPos.contentArea then
        
        local relativeY = y - yPos.listStart
        local itemIndex = math.floor(relativeY / self.itemHeight) + 1 + self.scrollOffset
        
        if itemIndex >= 1 and itemIndex <= #self.files then
            self.hoveredItem = self.files[itemIndex]
            return true
        end
    end
    
    self.hoveredItem = nil
    
    -- Check buttons
    local buttonY = windowHeight - (dialogY + self.height - self.buttonHeight - self.padding)
    if y >= buttonY - self.buttonHeight/2 and y <= buttonY + self.buttonHeight/2 then
        local buttonWidth = (self.width - 3 * self.padding) / 2
        local confirmX = dialogX + self.padding + buttonWidth/2
        local cancelX = dialogX + self.width - buttonWidth/2 - self.padding
        
        if x >= confirmX - buttonWidth/2 and x <= confirmX + buttonWidth/2 then
            self.hoveredButton = "confirm"
            return true
        elseif x >= cancelX - buttonWidth/2 and x <= cancelX + buttonWidth/2 then
            self.hoveredButton = "cancel"
            return true
        end
    end
    
    self.hoveredButton = nil
    return false
end

function FileDialog:handleScroll(dx, dy)
    if not self.isOpen then return false end
    
    local maxScroll = math.max(0, #self.files - self.maxVisibleItems)
    self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollOffset - dy))
    return true
end

function FileDialog:update(dt)
    if self.isOpen and self.isInputActive then
        self.cursorBlink = (self.cursorBlink + dt) % (2 * self.cursorBlinkRate)
    end
end

function FileDialog:draw(pass)
    if not self.isOpen then return end
    
    local windowWidth, windowHeight = lovr.system.getWindowDimensions()
    local dialogX = (windowWidth - self.width) / 2
    local dialogY = (windowHeight - self.height) / 2
    
    -- Draw dialog background
    pass:setColor(unpack(self.backgroundColor))
    pass:plane(
        dialogX + self.width/2,
        windowHeight - (dialogY + self.height/2),
        0,
        self.width,
        self.height
    )
    
    -- Draw title
    pass:setColor(1, 1, 1, 1)
    local titleText = self.mode == "save" and "Save File" or "Load File"
    pass:text(
        titleText,
        dialogX + self.padding,
        windowHeight - (dialogY + self.padding),
        0,
        0.6,
        0,
        0, 1, 0,
        0,
        'left'
    )
    
    -- Draw current path
    pass:setColor(0.8, 0.8, 0.8, 1)
    pass:text(
        self.currentPath,
        dialogX + self.padding,
        windowHeight - (dialogY + 2 * self.padding + 20),
        0,
        0.4,
        0,
        0, 1, 0,
        0,
        'left'
    )
    
    -- Draw file list
    local listY = dialogY + 3 * self.padding + 40
    for i = 1, math.min(self.maxVisibleItems, #self.files) do
        local fileIndex = i + self.scrollOffset
        local file = self.files[fileIndex]
        if file then
            local itemY = windowHeight - (listY + (i-1) * self.itemHeight + self.itemHeight/2)
            
            -- Draw hover highlight
            if self.hoveredItem == file then
                pass:setColor(0.4, 0.4, 0.4, 0.5)
                pass:plane(
                    dialogX + self.width/2,
                    itemY,
                    0,
                    self.width - 2 * self.padding,
                    self.itemHeight
                )
            end
            
            -- Draw selection highlight
            if self.selectedFile == file then
                pass:setColor(0.3, 0.5, 0.7, 0.5)
                pass:plane(
                    dialogX + self.width/2,
                    itemY,
                    0,
                    self.width - 2 * self.padding,
                    self.itemHeight
                )
            end
            
            -- Draw file/directory name
            pass:setColor(1, 1, 1, 1)
            local prefix = file.isDirectory and "📁 " or "📄 "
            pass:text(
                prefix .. file.name,
                dialogX + 2 * self.padding,
                itemY,
                0,
                0.4,
                0,
                0, 1, 0,
                0,
                'left'
            )
        end
    end
    
    -- Draw filename input field
    local inputY = dialogY + self.height - 2 * (self.buttonHeight + self.padding)
    pass:setColor(0.15, 0.15, 0.15, 1)
    pass:plane(
        dialogX + self.width/2,
        windowHeight - inputY,
        0,
        self.width - 2 * self.padding,
        self.buttonHeight
    )
    
    pass:setColor(1, 1, 1, 1)
    local displayText = self.filename
    if self.isInputActive and self.cursorBlink < self.cursorBlinkRate then
        displayText = displayText .. "|"
    end
    pass:text(
        displayText,
        dialogX + 2 * self.padding,
        windowHeight - inputY,
        0,
        0.4,
        0,
        0, 1, 0,
        0,
        'left'
    )
    
    -- Draw buttons
    local buttonY = dialogY + self.height - self.buttonHeight - self.padding
    local buttonWidth = (self.width - 3 * self.padding) / 2
    
    -- Confirm button
    local confirmColor = self.hoveredButton == "confirm" and self.buttonColors.hover or self.buttonColors.normal
    pass:setColor(unpack(confirmColor))
    pass:plane(
        dialogX + self.padding + buttonWidth/2,
        windowHeight - buttonY,
        0,
        buttonWidth,
        self.buttonHeight
    )
    pass:setColor(1, 1, 1, 1)
    pass:text(
        self.mode == "save" and "Save" or "Open",
        dialogX + self.padding + buttonWidth/2,
        windowHeight - buttonY,
        0,
        0.4
    )
    
    -- Cancel button
    local cancelColor = self.hoveredButton == "cancel" and self.buttonColors.hover or self.buttonColors.normal
    pass:setColor(unpack(cancelColor))
    pass:plane(
        dialogX + self.width - buttonWidth/2 - self.padding,
        windowHeight - buttonY,
        0,
        buttonWidth,
        self.buttonHeight
    )
    pass:setColor(1, 1, 1, 1)
    pass:text(
        "Cancel",
        dialogX + self.width - buttonWidth/2 - self.padding,
        windowHeight - buttonY,
        0,
        0.4
    )
end

return FileDialog