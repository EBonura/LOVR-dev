-- main.lua
local World = require('world')
local UI = require('ui')
local Selection = require('selection')

local engine = {
    world = nil,
    ui = nil,
    selection = nil
}

function lovr.load()
    engine.selection = Selection:new()
    engine.world = World:new(engine.selection)
    engine.ui = UI:new(engine.selection)
end

function lovr.draw(pass)
    engine.world:draw(pass)
    engine.ui:drawHUD(pass)
end

function lovr.update(dt)
    engine.world:update(dt)
    engine.ui:update(dt)
end

function lovr.keypressed(key)
    if key == 'escape' then
        lovr.event.quit()
    end
end

return engine