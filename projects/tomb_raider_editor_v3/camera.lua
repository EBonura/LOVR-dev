-- Camera.lua
local Camera = {
    position = lovr.math.newVec3(0, 2, -4),  -- Camera starting position
    rotation = lovr.math.newQuat(),          -- Camera rotation as quaternion
    speed = 3,                               -- Movement speed
    mouseDown = false,                       -- Track right mouse button state
    sensitivity = 0.002,                     -- Mouse sensitivity
    lastx = 0,                              -- Last mouse x position
    lasty = 0,                              -- Last mouse y position
    yaw = math.pi/2,                        -- Initial yaw angle (90 degrees to face grid)
    pitch = -math.pi/6                      -- Initial pitch angle (-30 degrees downward)
}

function Camera:new()
    local camera = setmetatable({}, { __index = Camera })
    
    -- Copy default values
    for k, v in pairs(Camera) do
        if type(v) == 'table' then
            -- Deep copy for vector/quaternion objects
            camera[k] = v:clone()
        else
            camera[k] = v
        end
    end
    
    -- Apply initial rotation
    camera.rotation:mul(lovr.math.quat(camera.yaw, 0, 1, 0))
    camera.rotation:mul(lovr.math.quat(camera.pitch, 1, 0, 0))
    
    return camera
end

function Camera:handleMouseInput()
    if lovr.system.isMouseDown(2) then -- Right mouse button
        local mx, my = lovr.system.getMousePosition()
        
        if not self.mouseDown then
            self.mouseDown = true
            self.lastx = mx
            self.lasty = my
        else
            local dx = (mx - self.lastx) * self.sensitivity 
            local dy = (my - self.lasty) * self.sensitivity
            
            -- Update yaw and pitch angles
            self.yaw = self.yaw - dx
            self.pitch = math.max(-math.pi/2, math.min(math.pi/2, self.pitch - dy))
            
            -- Set rotation directly from angles using a single new quaternion
            self.rotation = lovr.math.newQuat()
            self.rotation:mul(lovr.math.quat(self.yaw, 0, 1, 0))
            self.rotation:mul(lovr.math.quat(self.pitch, 1, 0, 0))
            
            self.lastx = mx
            self.lasty = my
        end
    else
        self.mouseDown = false
    end
end

function Camera:handleKeyboardInput(dt)
    local dx, dy, dz = 0, 0, 0
    if lovr.system.isKeyDown('w') then dz = -1 end
    if lovr.system.isKeyDown('s') then dz = 1 end
    if lovr.system.isKeyDown('a') then dx = -1 end
    if lovr.system.isKeyDown('d') then dx = 1 end
    if lovr.system.isKeyDown('q') then dy = -1 end
    if lovr.system.isKeyDown('e') then dy = 1 end
    
    -- Apply movement
    local movement = lovr.math.vec3(dx, dy, dz)
    movement:mul(dt * self.speed)
    movement:rotate(self.rotation)
    self.position:add(movement)
end

function Camera:update(dt)
    self:handleMouseInput()
    self:handleKeyboardInput(dt)
end

return Camera