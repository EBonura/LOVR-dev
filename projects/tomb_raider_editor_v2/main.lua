local Camera = require('camera')
local World = require('world')
local utils = require('utils')
local UI = require('ui')

local scene = {
    camera = nil,
    world = nil,
    ui = nil
}

function lovr.load()
    scene.camera = Camera:new()
    scene.world = World:new(scene.camera)
    scene.camera:setWorld(scene.world)  -- Give camera access to world
    scene.ui = UI:new(scene.camera)
end

function lovr.update(dt)
    scene.camera:update(dt)
end

function lovr.keypressed(key)
    scene.camera:handleKeyPressed(key)
end

function lovr.draw(pass)
    -- First draw 3D scene
    pass:setViewPose(1, scene.camera.position, scene.camera.rotation)
    
    -- Calculate ray intersection
    local intersection, t = calculateRayIntersection()
    
    -- Draw world elements
    scene.world:drawGrid(pass)
    scene.world:drawCursorIntersection(pass, t, intersection)
    
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

function lovr.mousepressed(x, y, button)
    -- Check if mouse is in UI area first
    if scene.ui:isPointInPanel(x, y) then
        -- We'll add UI interaction later
        return
    end
    
    -- If not in UI, handle camera controls
    scene.camera:mousepressed(x, y, button)
end

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
    
    -- If not in UI, handle camera controls
    scene.camera:mousepressed(x, y, button)
end