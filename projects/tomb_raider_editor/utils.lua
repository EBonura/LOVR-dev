local utils = {}

-- Convert world coordinates to grid coordinates (centers)
function utils.worldToGrid(x, y, z)
  return math.floor(x + 0.5), math.floor(y), math.floor(z + 0.5)
end

-- Get unique key for block position
function utils.getBlockKey(x, y, z)
  return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

-- Ray-plane intersection calculation
function utils.rayPlaneIntersection(rayOrigin, rayDir, planePoint, planeNormal)
  local denom = rayDir:dot(planeNormal)
  if math.abs(denom) <= 1e-6 then return nil end
  
  local diff = lovr.math.vec3(planePoint.x - rayOrigin.x, planePoint.y - rayOrigin.y, planePoint.z - rayOrigin.z)
  local t = diff:dot(planeNormal) / denom
  if t < 0 then return nil end
  
  return lovr.math.vec3(rayOrigin.x + rayDir.x * t, rayOrigin.y + rayDir.y * t, rayOrigin.z + rayDir.z * t)
end

return utils
