local Camera = require('camera')
local World = require('world')
local utils = require('utils')

local scene = {
    camera = nil,
    world = nil,
}

function lovr.load()
    scene.camera = Camera:new()
    scene.world = World:new()
end

function lovr.update(dt)
    scene.camera:update(dt)
end

function lovr.draw(pass)
    -- Set camera for 3D scene
    pass:setViewPose(1, scene.camera.position, scene.camera.rotation)
    
    -- Calculate ray intersection
    local intersection, t = calculateRayIntersection()
    
    -- Draw world elements
    scene.world:drawGrid(pass)
    scene.world:drawCursorIntersection(pass, t, intersection)
    
    -- Draw debug overlay
    drawDebugInfo(pass)
end

function calculateRayIntersection()
    local mx, my = lovr.system.getMousePosition()
    local width, height = lovr.system.getWindowDimensions()
    
    -- Convert mouse position to view space coordinates
    local nx = (mx / width) * 2 - 1
    local ny = ((height - my) / height) * 2 - 1
    
    -- Create ray direction with FOV and aspect ratio scaling
    local rayStart = scene.camera.position
    local fov = 67.5 * (math.pi / 180)
    local tanFov = math.tan(fov / 2)
    local aspect = width / height
    
    local rayDirection = lovr.math.vec3(
        nx * tanFov * aspect,
        ny * tanFov,
        -1
    )
    rayDirection:rotate(scene.camera.rotation)
    rayDirection:normalize()
    
    -- Calculate intersection with grid plane (y = 0)
    local t = -rayStart.y / rayDirection.y
    local intersection = lovr.math.vec3(
        rayStart.x + rayDirection.x * t,
        0,
        rayStart.z + rayDirection.z * t
    )
    
    return intersection, t
end

function drawDebugInfo(pass)
    -- Reset view for debug overlay
    pass:setViewPose(1, lovr.math.vec3(0, 0, 0), lovr.math.quat())
    pass:setColor(1, 1, 1, 1)
    pass:text(
        scene.camera:getDebugText(),
        -1.1, 0.6, -1,
        0.04,
        0,
        0, 1, 0,
        0,
        'left',
        'top'
    )
end

function lovr.mousepressed(x, y, button)
    scene.camera:mousepressed(x, y, button)
end

function lovr.mousereleased(x, y, button)
    scene.camera:mousereleased(x, y, button)
end