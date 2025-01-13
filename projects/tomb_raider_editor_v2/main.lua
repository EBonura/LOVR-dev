local Camera = require('camera')
local utils = require('utils')  -- We'll keep using the utilities

local scene = {
    camera = nil,
    gridSize = 20,  -- Size of the ground grid
}

function lovr.load()
    scene.camera = Camera:new()
end

function lovr.update(dt)
    scene.camera:update(dt)
end

function lovr.draw(pass)
    -- Set camera for 3D scene
    pass:setViewPose(1, scene.camera.position, scene.camera.rotation)
    
    -- Calculate cursor ray in world space
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
    
    -- Draw main elements
    drawGrid(pass)
    drawCursorIntersection(pass, t, intersection)
    drawDebugInfo(pass)
end

function drawGrid(pass)
    -- Draw grid slightly below Y=0 to prevent z-fighting
    pass:setColor(0.5, 0.5, 0.5, 0.5)
    pass:plane(0.5, -0.001, 0.5, scene.gridSize, scene.gridSize, -math.pi/2, 1, 0, 0, 'line', scene.gridSize, scene.gridSize)
end

function drawCursorIntersection(pass, t, intersection)
    if t > 0 then  -- Only draw if intersection is in front of camera
        -- Round intersection to nearest grid unit
        local gridX = math.floor(intersection.x + 0.5)
        local gridZ = math.floor(intersection.z + 0.5)
        
        -- Draw wireframe cube
        pass:setColor(1, 1, 1, 1)
        pass:box(gridX, 0.5, gridZ, 1, 1, 1, 0, 0, 0, 0, 'line')
        
        -- Draw intersection point
        pass:setColor(1, 0, 0, 1)
        pass:sphere(intersection, 0.1)
    end
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