local World = require('world')
local UI = require('ui')
local Controls = require('controls')

local engine = {
    world = nil,
    ui = nil,
    controls = nil
}

function lovr.load()
    engine.world = World:new()
    engine.ui = UI:new()
    engine.controls = Controls:new(engine.world, engine.ui)
end

function lovr.update(dt)
    engine.controls:update(dt)
    engine.world:update(dt)
    engine.ui:update(dt)
end

function lovr.draw(pass)
    engine.world:draw(pass)
    engine.ui:draw(pass)
end

-- Route all input handling to Controls module
function lovr.keypressed(key)
    engine.controls:keypressed(key)
end

function lovr.mousemoved(x, y)
    engine.controls:mousemoved(x, y)
end

function lovr.mousepressed(x, y, button)
    engine.controls:mousepressed(x, y, button)
end

function lovr.mousereleased(x, y, button)
    engine.controls:mousereleased(x, y, button)
end