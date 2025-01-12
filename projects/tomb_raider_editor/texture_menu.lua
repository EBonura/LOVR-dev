local TextureMenu = {}

-- Store loaded textures and their names
local textures = {}
local selectedTexture = 1
local TEXTURE_SIZE = 0.15  -- Size of texture preview squares
local MARGIN = 0.02       -- Space between textures
local START_X = 0.7       -- Right edge of menu
local START_Y = 0.5       -- Top edge of menu

function TextureMenu.load()
  -- Load all textures from the Textures directory
  local textureFiles = {
    "Brick01-128.png",
    "Concrete01-128.png",
    "Concrete02-128.png",
    "Grass01-128.png",
    "Gravel02-128.png",
    "Rock01-128.png",
    "Wood03-128.png"
  }
  
  for i, filename in ipairs(textureFiles) do
    local texture = lovr.graphics.newTexture('Textures_PNG/' .. filename)
    table.insert(textures, {
      texture = texture,
      name = filename:gsub("%-128%.png$", "")  -- Remove suffix for display
    })
  end
end

function TextureMenu.draw(pass)
  -- Save current view pose
  pass:push()
  
  -- Reset view for 2D drawing
  pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
  
  -- Draw each texture
  for i, tex in ipairs(textures) do
    local y = START_Y - (i-1) * (TEXTURE_SIZE + MARGIN)
    
    -- Draw selection highlight
    if i == selectedTexture then
      pass:setColor(1, 1, 1, 1)
      pass:plane(START_X + TEXTURE_SIZE/2, y, -1, TEXTURE_SIZE + 0.01, TEXTURE_SIZE + 0.01)
    end
    
    -- Draw texture preview
    pass:setColor(1, 1, 1, 1)
    pass:setMaterial(tex.texture)
    pass:plane(START_X + TEXTURE_SIZE/2, y, -1, TEXTURE_SIZE, TEXTURE_SIZE)
    pass:setMaterial()
    
    -- Draw texture name
    pass:setColor(1, 1, 1, 1)
    pass:text(tex.name, 
      START_X + TEXTURE_SIZE + MARGIN, y, -1,  -- Position
      0.03,  -- Scale
      0,     -- Angle
      0, 1, 0,  -- Rotation axis
      0,     -- Wrap
      'left', -- Horizontal alignment
      'middle' -- Vertical alignment
    )
  end
  
  -- Restore view pose
  pass:pop()
end

function TextureMenu.mousepressed(x, y)
  -- Convert screen coordinates to world coordinates
  local width, height = lovr.system.getWindowDimensions()
  local worldX = (x / width * 2 - 1) * 0.95  -- Scale to match our coordinate system
  local worldY = -(y / height * 2 - 1) * 0.95 -- Flip Y and scale
  
  -- Check if click is in texture menu area
  if worldX >= START_X and worldX <= START_X + TEXTURE_SIZE then
    for i, _ in ipairs(textures) do
      local texY = START_Y - (i-1) * (TEXTURE_SIZE + MARGIN)
      if worldY >= texY - TEXTURE_SIZE/2 and worldY <= texY + TEXTURE_SIZE/2 then
        selectedTexture = i
        return true
      end
    end
  end
  return false
end

function TextureMenu.getSelectedTexture()
  return textures[selectedTexture].texture
end

function TextureMenu.getSelectedTextureName()
  return textures[selectedTexture].name
end

return TextureMenu
