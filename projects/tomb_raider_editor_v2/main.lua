local Camera = require('camera')
local World = require('world')
local utils = require('utils')
local UI = require('ui')

local scene = {
    camera = nil,
    world = nil,
    ui = nil
}

local lastClickTime = 0
local DOUBLE_CLICK_TIME = 0.3  -- Time window for double click in seconds

function lovr.load()
    scene.camera = Camera:new()
    scene.world = World:new(scene.camera)
    scene.camera:setWorld(scene.world)  -- Give camera access to world
    scene.ui = UI:new(scene.camera)
    scene.world:setUI(scene.ui)      -- Give world access to UI for texturing
    scene.ui.world = scene.world     -- Give UI access to world for block updates
end

function lovr.update(dt)
    scene.camera:update(dt)
end

function lovr.keypressed(key)
    if key == 'tab' then
        scene.world:toggleMode()
        return
    elseif key == 'delete' and scene.world.currentMode == scene.world.MODE_SELECT then
        -- TODO: Implement block deletion
        return
    end
    scene.camera:handleKeyPressed(key)
end

function lovr.draw(pass)
    -- First draw 3D scene
    pass:setViewPose(1, scene.camera.position, scene.camera.rotation)
    
    -- Only calculate and draw intersection if mouse is not in UI
    local mx, my = lovr.system.getMousePosition()
    if not scene.ui:isPointInPanel(mx, my) then
        -- Calculate ray intersection
        local intersection, t = calculateRayIntersection()
        
        -- Update highlighted block in SELECT mode
        if scene.world.currentMode == scene.world.MODE_SELECT and t > 0 then
            local gridX = math.floor(intersection.x + 0.5)
            local gridZ = math.floor(intersection.z + 0.5)
            scene.world.highlightedBlock = scene.world:findBlockAt(gridX, scene.world.currentGridY, gridZ)
        end
        
        -- Draw world elements
        scene.world:drawGrid(pass)
        
        -- Only draw cursor intersection in PLACE mode
        if scene.world.currentMode == scene.world.MODE_PLACE then
            scene.world:drawCursorIntersection(pass, t, intersection)
        end
    else
        -- Still draw the grid even when mouse is in UI
        scene.world:drawGrid(pass)
        -- Clear highlight when mouse is in UI
        scene.world.highlightedBlock = nil
    end
    
    -- Draw UI last (includes debug info now)
    pass:push()
    scene.ui:draw(pass)
    pass:pop()
end

function calculateRayIntersection()
    local mx, my = lovr.system.getMousePosition()
    local width, height = lovr.system.getWindowDimensions()
    
    -- Convert mouse position to clip space (-1 to 1)
    local nx = (mx / width) * 2 - 1
    local ny = ((height - my) / height) * 2 - 1
    
    -- Get projection details
    local fov = 67.5 * (math.pi / 180)
    local aspect = width / height
    local near = 0.01  -- LÖVR's default near plane
    
    -- Calculate ray direction using proper perspective projection
    local tanFov = math.tan(fov / 2)
    local rayDirection = lovr.math.vec3(
        nx * tanFov * aspect,
        ny * tanFov,
        -1
    )
    rayDirection:normalize()  -- Normalize before rotation
    rayDirection:rotate(scene.camera.rotation)
    
    -- Calculate intersection with grid plane (y = 0)
    local rayStart = scene.camera.position
    local planeY = scene.world.currentGridY  -- Use the current grid Y level
    local t = (planeY - rayStart.y) / rayDirection.y
    
    local intersection = lovr.math.vec3(
        rayStart.x + rayDirection.x * t,
        planeY,
        rayStart.z + rayDirection.z * t
    )
    
    return intersection, t
end

-- Modify the mousepressed function
function lovr.mousepressed(x, y, button)
    -- Check if mouse is in UI area first
    if scene.ui:isPointInPanel(x, y) then
        if button == 1 then  -- Left click
            -- Handle UI interaction
            if scene.ui:handleClick(x, y) then
                return  -- Click was handled by UI
            end
        end
        return
    end
    
    -- Handle block interactions with left click
    if button == 1 then
        local intersection, t = calculateRayIntersection()
        if t > 0 then
            local gridX = math.floor(intersection.x + 0.5)
            local gridZ = math.floor(intersection.z + 0.5)
            
            -- Check for double click
            local currentTime = lovr.timer.getTime()
            if currentTime - lastClickTime < DOUBLE_CLICK_TIME then
                -- Double click detected
                scene.world:deleteBlock(gridX, scene.world.currentGridY, gridZ)
            else
                -- Single click - normal block placement/selection
                scene.world:handleClick(gridX, scene.world.currentGridY, gridZ)
            end
            lastClickTime = currentTime
        end
    end
    
    -- Handle camera controls with right click
    if button == 2 then
        scene.camera:mousepressed(x, y, button)
    end
end

function lovr.mousereleased(x, y, button)
    -- Check if mouse is in UI area first
    if scene.ui:isPointInPanel(x, y) then
        return
    end
    
    -- If not in UI, handle camera controls
    scene.camera:mousereleased(x, y, button)
end

return scene