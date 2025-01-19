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
        FACE = {0.7, 0.2, 0.2, 1},    -- Strong dark red
        EDGE = {0.2, 0.6, 0.2, 1},    -- Strong dark green
        VERTEX = {0.2, 0.2, 0.8, 1}   -- Strong dark blue
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