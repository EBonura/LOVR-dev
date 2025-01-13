local utils = {}

function utils.worldToGrid(x, y, z)
  return math.floor(x + 0.5), math.floor(y + 0.5), math.floor(z + 0.5)
end

function utils.rayPlaneIntersection(origin, direction, planePoint, planeNormal)
  local d = direction:dot(planeNormal)
  if math.abs(d) < 1e-6 then return nil end
  
  local t = (planePoint - origin):dot(planeNormal) / d
  if t < 0 then return nil end
  
  return origin + direction * t
end

return utils
