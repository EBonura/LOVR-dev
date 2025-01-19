local World = require('world')
local UI = require('ui')

local engine = {
    world = nil,
    ui = nil,
}

function lovr.load()
    engine.world = World:new()
    engine.ui = UI:new()
end


function lovr.draw(pass)
    engine.world:draw(pass)
    engine.ui:draw(pass)
end

-- Handle input in update
function lovr.update(dt)
    engine.world:update(dt)
    engine.ui:update(dt)
end

-- Handle quit
function lovr.keypressed(key)
    if key == 'escape' then
        lovr.event.quit()
    end
end

return engine