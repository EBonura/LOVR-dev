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
    activeButton = nil
}

function FileDialog:new()
    local dialog = setmetatable({}, { __index = FileDialog })
    dialog:initialize()
    return dialog
end

function FileDialog:initialize()
    -- Set default save directory to LÖVR's save directory
    self.currentPath = lovr.filesystem.getSaveDirectory()
    self:refreshFileList()
end

function FileDialog:refreshFileList()
    self.files = {}
    
    -- Add parent directory option if not at root
    if self.currentPath ~= lovr.filesystem.getSaveDirectory() then
        table.insert(self.files, {
            name = "..",
            isDirectory = true
        })
    end
    
    -- Get all files and directories
    local items = lovr.filesystem.getDirectoryItems(self.currentPath)
    for _, item in ipairs(items) do
        local fullPath = self.currentPath .. "/" .. item
        local isDirectory = lovr.filesystem.isDirectory(fullPath)
        
        table.insert(self.files, {
            name = item,
            isDirectory = isDirectory
        })
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
    
    -- Check if click is within dialog bounds
    if x < dialogX or x > dialogX + self.width or
       y < dialogY or y > dialogY + self.height then
        if self.onCancel then
            self.onCancel()
        end
        self:hide()
        return true
    end
    
    -- Check filename input field
    local inputY = dialogY + self.height - 2 * (self.buttonHeight + self.padding)
    if y >= inputY - self.buttonHeight/2 and y <= inputY + self.buttonHeight/2 then
        self.isInputActive = true
        return true
    end
    
    -- Check file list
    local listY = dialogY + self.padding
    local relativeY = y - listY
    local itemIndex = math.floor(relativeY / self.itemHeight) + 1 + self.scrollOffset
    
    if itemIndex >= 1 and itemIndex <= #self.files then
        local file = self.files[itemIndex]
        if file.isDirectory then
            if file.name == ".." then
                -- Go up one directory
                self.currentPath = self.currentPath:match("(.*)/.*$") or ""
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
    
    -- Check buttons
    local buttonY = dialogY + self.height - self.buttonHeight - self.padding
    if y >= buttonY - self.buttonHeight/2 and y <= buttonY + self.buttonHeight/2 then
        local buttonWidth = (self.width - 3 * self.padding) / 2
        local confirmX = dialogX + self.padding
        local cancelX = dialogX + self.width - buttonWidth - self.padding
        
        if x >= confirmX and x <= confirmX + buttonWidth then
            -- Confirm button
            if self.onComplete then
                self.onComplete(self.currentPath .. "/" .. self.filename)
            end
            self:hide()
            return true
        elseif x >= cancelX and x <= cancelX + buttonWidth then
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

function FileDialog:handleMouseMoved(x, y)
    if not self.isOpen then return false end
    
    local windowWidth, windowHeight = lovr.system.getWindowDimensions()
    local dialogX = (windowWidth - self.width) / 2
    local dialogY = (windowHeight - self.height) / 2
    
    -- Check buttons
    local buttonY = dialogY + self.height - self.buttonHeight - self.padding
    if y >= buttonY - self.buttonHeight/2 and y <= buttonY + self.buttonHeight/2 then
        local buttonWidth = (self.width - 3 * self.padding) / 2
        local confirmX = dialogX + self.padding
        local cancelX = dialogX + self.width - buttonWidth - self.padding
        
        if x >= confirmX and x <= confirmX + buttonWidth then
            self.hoveredButton = "confirm"
            return true
        elseif x >= cancelX and x <= cancelX + buttonWidth then
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
        dialogY + self.height/2,
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
        dialogY + self.padding,
        0,
        0.5
    )
    
    -- Draw current path
    pass:setColor(0.8, 0.8, 0.8, 1)
    pass:text(
        self.currentPath,
        dialogX + self.padding,
        dialogY + 2 * self.padding + 20,
        0,
        0.3
    )
    
    -- Draw file list
    local listY = dialogY + 3 * self.padding + 40
    for i = 1, math.min(self.maxVisibleItems, #self.files) do
        local fileIndex = i + self.scrollOffset
        local file = self.files[fileIndex]
        if file then
            -- Draw selection highlight
            if self.selectedFile == file then
                pass:setColor(0.3, 0.5, 0.7, 0.5)
                pass:plane(
                    dialogX + self.width/2,
                    listY + (i-1) * self.itemHeight + self.itemHeight/2,
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
                listY + (i-1) * self.itemHeight + self.itemHeight/2,
                0,
                0.3
            )
        end
    end
    
    -- Draw filename input field
    local inputY = dialogY + self.height - 2 * (self.buttonHeight + self.padding)
    pass:setColor(0.15, 0.15, 0.15, 1)
    pass:plane(
        dialogX + self.width/2,
        inputY,
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
        inputY,
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
        buttonY,
        0,
        buttonWidth,
        self.buttonHeight
    )
    pass:setColor(1, 1, 1, 1)
    pass:text(
        self.mode == "save" and "Save" or "Open",
        dialogX + self.padding + buttonWidth/2,
        buttonY,
        0,
        0.4
    )
    
    -- Cancel button
    local cancelColor = self.hoveredButton == "cancel" and self.buttonColors.hover or self.buttonColors.normal
    pass:setColor(unpack(cancelColor))
    pass:plane(
        dialogX + self.width - buttonWidth - self.padding + buttonWidth/2,
        buttonY,
        0,
        buttonWidth,
        self.buttonHeight
    )
    pass:setColor(1, 1, 1, 1)
    pass:text(
        "Cancel",
        dialogX + self.width - buttonWidth - self.padding + buttonWidth/2,
        buttonY,
        0,
        0.4
    )
end

return FileDialog