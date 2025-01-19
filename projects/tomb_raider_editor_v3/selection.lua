-- selection.lua
local Selection = {
    -- Current mode
    MODE_FACE = 'FACE',
    MODE_EDGE = 'EDGE',
    MODE_VERTEX = 'VERTEX',
    currentMode = 'FACE',

    -- Currently selected elements
    selectedFace = nil,
    selectedEdge = nil,
    selectedVertex = nil,

    -- Hover state (before selection)
    hoveredFace = nil,
    hoveredEdge = nil,
    hoveredVertex = nil,

    -- Mode-specific colors
    modeColors = {
        FACE = {1, 0.5, 0.5, 1},    -- Red
        EDGE = {0.5, 1, 0.5, 1},    -- Green
        VERTEX = {0.5, 0.5, 1, 1}   -- Blue
    }
}

function Selection:new()
    local selection = setmetatable({}, { __index = Selection })
    return selection
end

function Selection:setMode(mode)
    if mode == self.MODE_FACE or mode == self.MODE_EDGE or mode == self.MODE_VERTEX then
        -- Clear selections when changing modes
        self.selectedFace = nil
        self.selectedEdge = nil
        self.selectedVertex = nil
        self.hoveredFace = nil
        self.hoveredEdge = nil
        self.hoveredVertex = nil
        self.currentMode = mode
    end
end

function Selection:getCurrentModeColor()
    return self.modeColors[self.currentMode]
end

function Selection:drawHUD(pass)
    -- Set up 2D drawing
    local width, height = lovr.system.getWindowDimensions()
    local projection = mat4():orthographic(0, width, 0, height, -1, 1)
    pass:setProjection(1, projection)
    
    -- Draw mode indicator
    local color = self:getCurrentModeColor()
    pass:setColor(unpack(color))
    pass:text(
        self.currentMode .. " MODE",
        20,
        height - 40,
        0,
        0.5  -- Text scale
    )
end

function Selection:clearHovered()
    self.hoveredFace = nil
    self.hoveredEdge = nil
    self.hoveredVertex = nil
end

function Selection:clearSelected()
    self.selectedFace = nil
    self.selectedEdge = nil
    self.selectedVertex = nil
end

-- Drawing helpers for faces in different selection states
function Selection:drawFace(pass, face)
    -- Draw the face differently based on mode and selection/hover state
    if self.currentMode == self.MODE_FACE then
        local isSelected = (face == self.selectedFace)
        local isHovered = (face == self.hoveredFace)
        face:draw(pass, isSelected, isHovered)
    elseif self.currentMode == self.MODE_EDGE then
        face:drawWithEdgeHighlight(pass, self.selectedEdge, self.hoveredEdge)
    elseif self.currentMode == self.MODE_VERTEX then
        face:drawWithVertexHighlight(pass, self.selectedVertex, self.hoveredVertex)
    end
end

return Selection