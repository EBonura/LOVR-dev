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

function lovr.update(dt)
    engine.handleInput()
    engine.world:update(dt)
    engine.ui:update(dt)
end

function lovr.draw(pass)
    engine.world:draw(pass)
    engine.ui:draw(pass)
end

function engine:handleInput()
    if lovr.system.isKeyDown('escape') then
        lovr.event.quit()
    end
end