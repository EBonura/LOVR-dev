local TextureMenu = {}

-- Store loaded textures and their names
local textures = {}
local selectedTexture = 1
local hoveredTexture = nil
local TEXTURE_SIZE = 0.15  -- Size of texture preview squares
local MARGIN = 0.02       -- Space between textures
local START_X = 0.7       -- Position textures within the 20% panel
local START_Y = 0.5       -- Top edge of menu
local PANEL_WIDTH = 0.4   -- Width of the right panel (20% of screen = 0.4 in normalized coords)

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

function TextureMenu.updateHover(x, y)
  -- Convert screen coordinates to world coordinates
  local width, height = lovr.system.getWindowDimensions()
  local worldX = (x / width * 2 - 1) * 0.95  -- Scale to match our coordinate system
  local worldY = -(y / height * 2 - 1) * 0.95 -- Flip Y and scale
  
  -- Check if mouse is over texture squares area
  local centerX = START_X + TEXTURE_SIZE/2
  if math.abs(worldX - centerX) <= TEXTURE_SIZE/2 then
    for i, _ in ipairs(textures) do
      local texY = START_Y - (i-1) * (TEXTURE_SIZE + MARGIN)
      if worldY >= texY - TEXTURE_SIZE/2 and worldY <= texY + TEXTURE_SIZE/2 then
        hoveredTexture = i
        return
      end
    end
  end
  hoveredTexture = nil
end

function TextureMenu.isOverPanel(x, y)
  local width = lovr.system.getWindowDimensions()
  return x / width >= 0.8  -- Check if mouse is in right 20% of screen (80% mark)
end

function TextureMenu.draw(pass)
  -- Save current view pose
  pass:push()
  
  -- Reset view for 2D drawing
  pass:setViewPose(1, lovr.math.vec3(), lovr.math.quat())
  
  -- Draw background panel
  pass:setColor(0.2, 0.2, 0.2, 1)
  pass:plane(0.8, 0, -1, 0.4, 2) -- 20% width panel (0.4 in normalized coords)
  
  -- Draw each texture
  for i, tex in ipairs(textures) do
    local y = START_Y - (i-1) * (TEXTURE_SIZE + MARGIN)
    
    -- Draw hover highlight in red
    if i == hoveredTexture then
      pass:setColor(1, 0, 0, 0.3)
      pass:plane(START_X + TEXTURE_SIZE/2, y, -1, TEXTURE_SIZE + 0.01, TEXTURE_SIZE + 0.01)
    end
    
    -- Draw selection highlight in white
    if i == selectedTexture then
      pass:setColor(1, 1, 1, 0.5)
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
  -- First check if we're over the panel
  if not TextureMenu.isOverPanel(x, y) then
    return false
  end
  
  -- Convert screen coordinates to world coordinates
  local width, height = lovr.system.getWindowDimensions()
  local worldX = (x / width * 2 - 1) * 0.95  -- Scale to match our coordinate system
  local worldY = -(y / height * 2 - 1) * 0.95 -- Flip Y and scale
  
  -- Check if click is in texture squares area only (not including text)
  local centerX = START_X + TEXTURE_SIZE/2
  if math.abs(worldX - centerX) <= TEXTURE_SIZE/2 then
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
