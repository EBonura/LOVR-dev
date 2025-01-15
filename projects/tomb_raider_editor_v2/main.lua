local Camera = require('camera')
local World = require('world')
local UI = require('ui')
local utils = require('utils')
local SaveLoad = require('saveload')

local scene = {
    camera = nil,
    world = nil,
    ui = nil,
    saveload = nil
}

local lastClickTime = 0
local DOUBLE_CLICK_TIME = 0.3  -- Time window for double click in seconds

function lovr.load()
    -- Initialize core systems
    scene.camera = Camera:new()
    scene.world = World:new(scene.camera)
    scene.camera:setWorld(scene.world)
    
    -- Initialize UI
    scene.ui = UI:new(scene.camera)
    scene.world:setUI(scene.ui)
    scene.ui.world = scene.world
    
    -- Initialize save/load system
    scene.saveload = SaveLoad
    scene.ui.saveload = scene.saveload
end

function lovr.update(dt)
    scene.camera:update(dt)
end

function lovr.keypressed(key)
    -- Check for modifier keys
    local ctrl = lovr.system.isKeyDown('lctrl') or 
                lovr.system.isKeyDown('rctrl') or
                lovr.system.isKeyDown('lgui') or 
                lovr.system.isKeyDown('rgui')
    
    local shift = lovr.system.isKeyDown('lshift') or 
                 lovr.system.isKeyDown('rshift')
    
    -- Handle file operations first
    if ctrl then
        if key == 'n' then
            -- New (Ctrl+N)
            scene.saveload:newWorld(scene.world)
            return
        elseif key == 's' then
            if shift then
                -- Save As (Ctrl+Shift+S)
                local timestamp = os.date("%Y%m%d_%H%M%S")
                scene.saveload:saveWorld(scene.world, "world_" .. timestamp .. ".json")
            else
                -- Save (Ctrl+S)
                if scene.saveload.currentFilename then
                    scene.saveload:saveWorld(scene.world, scene.saveload.currentFilename)
                else
                    scene.saveload:saveWorld(scene.world, "world.json")
                end
            end
            return
        elseif key == 'o' then
            -- Load (Ctrl+O)
            scene.saveload:loadWorld(scene.world, "world.json")
            return
        end
    end
    
    -- Mode switching
    if key == 'tab' then
        scene.world:toggleMode()
        return
    end
    
    -- Let world handle keys first (for block/face manipulation)
    if scene.world:handleKeyPressed(key) then
        return
    end
    
    -- Let camera handle remaining keys
    scene.camera:handleKeyPressed(key)
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
    local near = 0.01
    
    -- Calculate ray direction using perspective projection
    local tanFov = math.tan(fov / 2)
    local rayDirection = lovr.math.vec3(
        nx * tanFov * aspect,
        ny * tanFov,
        -1
    )
    rayDirection:normalize()
    rayDirection:rotate(scene.camera.rotation)
    
    -- Calculate intersection with grid plane
    local rayStart = scene.camera.position
    local planeY = scene.world.currentGridY
    local t = (planeY - rayStart.y) / rayDirection.y
    
    local intersection = lovr.math.vec3(
        rayStart.x + rayDirection.x * t,
        planeY,
        rayStart.z + rayDirection.z * t
    )
    
    return intersection, t, rayStart, rayDirection
end

function lovr.mousepressed(x, y, button)
    -- Check UI interaction first
    if scene.ui:isPointInPanel(x, y) then
        if button == 1 then  -- Left click
            if scene.ui:handleClick(x, y) then
                return
            end
        end
        return
    end
    
    -- Handle block interactions with left click
    if button == 1 then
        local intersection, t, rayStart, rayDir = calculateRayIntersection()
        if t > 0 then
            local gridX = math.floor(intersection.x + 0.5)
            local gridZ = math.floor(intersection.z + 0.5)
            
            -- Check if shift is held for multi-selection
            local isShiftHeld = lovr.system.isKeyDown('lshift') or 
                              lovr.system.isKeyDown('rshift')
            
            if scene.world.currentMode == scene.world.MODE_FACE_SELECT then
                -- Handle face selection if we have a hovered face
                if scene.world.hoveredFace then
                    scene.world:handleClick(gridX, scene.world.currentGridY, gridZ, isShiftHeld)
                end
            else
                -- Handle PLACE and SELECT modes
                local currentTime = lovr.timer.getTime()
                if scene.world.currentMode == scene.world.MODE_PLACE and 
                   currentTime - lastClickTime < DOUBLE_CLICK_TIME then
                    -- Double click in PLACE mode deletes block
                    scene.world:deleteBlock(gridX, scene.world.currentGridY, gridZ)
                else
                    -- Single click handles normal placement/selection
                    scene.world:handleClick(gridX, scene.world.currentGridY, gridZ, isShiftHeld)
                end
                lastClickTime = currentTime
            end
        end
    end
    
    -- Handle camera controls with right click
    if button == 2 then
        scene.camera:mousepressed(x, y, button)
    end
end

function lovr.mousereleased(x, y, button)
    -- Check UI interaction first
    if scene.ui:isPointInPanel(x, y) then
        return
    end
    
    -- Handle camera controls
    scene.camera:mousereleased(x, y, button)
end

function lovr.draw(pass)
    -- Draw 3D scene first
    pass:setViewPose(1, scene.camera.position, scene.camera.rotation)
    
    -- Only process mouse interaction if not in UI
    local mx, my = lovr.system.getMousePosition()
    if not scene.ui:isPointInPanel(mx, my) then
        -- Calculate ray intersection
        local intersection, t, rayStart, rayDir = calculateRayIntersection()
        
        -- Handle different modes
        if scene.world.currentMode == scene.world.MODE_FACE_SELECT then
            -- Face selection mode
            if t > 0 then
                local closestBlock = nil
                local closestFace = nil
                local closestT = math.huge
                
                for _, block in ipairs(scene.world.blocks) do
                    local face, faceT = block:intersectFace(rayStart, rayDir)
                    if face and faceT < closestT then
                        closestBlock = block
                        closestFace = face
                        closestT = faceT
                    end
                end
                
                scene.world.hoveredFace = closestBlock and {
                    block = closestBlock,
                    face = closestFace
                } or nil
            end
        elseif scene.world.currentMode == scene.world.MODE_SELECT and t > 0 then
            -- Block selection mode
            local gridX = math.floor(intersection.x + 0.5)
            local gridZ = math.floor(intersection.z + 0.5)
            scene.world.highlightedBlock = scene.world:findBlockAt(
                gridX,
                scene.world.currentGridY,
                gridZ
            )
        end
        
        -- Draw world elements
        scene.world:drawGrid(pass)
        
        -- Draw cursor intersection only in PLACE mode
        if scene.world.currentMode == scene.world.MODE_PLACE then
            scene.world:drawCursorIntersection(pass, t, intersection)
        end
    else
        -- Still draw grid when mouse is in UI
        scene.world:drawGrid(pass)
        -- Clear highlights
        scene.world.highlightedBlock = nil
        scene.world.hoveredFace = nil
    end
    
    -- Draw UI last
    pass:push()
    scene.ui:draw(pass)
    pass:pop()
end

return scene