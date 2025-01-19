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
        FACE = {0.7, 0.2, 0.2, 0.8},    -- Red
        EDGE = {0.2, 0.6, 0.2, 0.8},    -- Green
        VERTEX = {0.2, 0.2, 0.8, 0.8}   -- Blue
    }
}

function Selection:new()
    local selection = setmetatable({}, { __index = Selection })
    return selection
end

function Selection:setMode(mode)
    if mode == self.MODE_FACE or mode == self.MODE_EDGE or mode == self.MODE_VERTEX then
        -- Clear all hover and selection states from geometry
        self:clearAllGeometryStates()
        
        -- Clear internal selection tracking
        self.selectedFace = nil
        self.selectedEdge = nil
        self.selectedVertex = nil
        self.hoveredFace = nil
        self.hoveredEdge = nil
        self.hoveredVertex = nil
        
        self.currentMode = mode
    end
end

function Selection:clearAllGeometryStates()
    -- This should be called whenever we need to reset all states
    if self.selectedFace then
        self.selectedFace.isSelected = false
        for _, edge in ipairs(self.selectedFace.edges) do
            edge.isSelected = false
        end
        for _, vertex in ipairs(self.selectedFace.vertices) do
            vertex.isSelected = false
        end
    end
    
    if self.hoveredFace then
        self.hoveredFace.isHovered = false
        for _, edge in ipairs(self.hoveredFace.edges) do
            edge.isHovered = false
        end
        for _, vertex in ipairs(self.hoveredFace.vertices) do
            vertex.isHovered = false
        end
    end
end

function Selection:updateHoverState(intersections)
    -- Clear previous hover states
    if self.hoveredFace then
        self.hoveredFace.isHovered = false
    end
    if self.hoveredEdge then
        self.hoveredEdge.isHovered = false
    end
    if self.hoveredVertex then
        self.hoveredVertex.isHovered = false
    end

    -- Update hover states based on mode
    if self.currentMode == self.MODE_FACE and intersections.face then
        self.hoveredFace = intersections.face
        self.hoveredFace.isHovered = true
    elseif self.currentMode == self.MODE_EDGE and intersections.edge then
        self.hoveredEdge = intersections.edge
        self.hoveredEdge.isHovered = true
    elseif self.currentMode == self.MODE_VERTEX and intersections.vertex then
        self.hoveredVertex = intersections.vertex
        self.hoveredVertex.isHovered = true
    end
end

function Selection:handleClick(intersections, isShiftHeld)
    if self.currentMode == self.MODE_FACE and intersections.face then
        self:selectFace(intersections.face, isShiftHeld)
    elseif self.currentMode == self.MODE_EDGE and intersections.edge then
        self:selectEdge(intersections.edge, isShiftHeld)
    elseif self.currentMode == self.MODE_VERTEX and intersections.vertex then
        self:selectVertex(intersections.vertex, isShiftHeld)
    end
end

function Selection:selectFace(face, isShiftHeld)
    if not isShiftHeld then
        -- Clear previous selection
        if self.selectedFace then
            self.selectedFace.isSelected = false
        end
    end
    
    face.isSelected = true
    self.selectedFace = face
end

function Selection:selectEdge(edge, isShiftHeld)
    if not isShiftHeld then
        -- Clear previous selection
        if self.selectedEdge then
            self.selectedEdge.isSelected = false
        end
    end
    
    edge.isSelected = true
    self.selectedEdge = edge
end

function Selection:selectVertex(vertex, isShiftHeld)
    if not isShiftHeld then
        -- Clear previous selection
        if self.selectedVertex then
            self.selectedVertex.isSelected = false
        end
    end
    
    vertex.isSelected = true
    self.selectedVertex = vertex
end

-- Helper to check if any element is selected
function Selection:hasSelection()
    return self.selectedFace ~= nil or 
           self.selectedEdge ~= nil or 
           self.selectedVertex ~= nil
end

-- Helper to get current mode color
function Selection:getCurrentModeColor()
    return self.modeColors[self.currentMode]
end

return Selection