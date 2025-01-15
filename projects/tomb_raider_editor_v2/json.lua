-- json.lua
local json = {}

local function encodeString(s)
    return string.format("%q", s)
end

local function encodeNumber(n)
    if n ~= n then return "NaN" end -- Handle NaN
    if n == math.huge then return "Infinity" end
    if n == -math.huge then return "-Infinity" end
    return tostring(n)
end

local function encodePair(key, value, pretty, depth)
    local spacing = pretty and string.rep("  ", depth) or ""
    local separator = pretty and ": " or ":"
    local encoded = encodeString(key) .. separator .. json.encode(value, pretty, depth)
    return spacing .. encoded
end

function json.encode(data, pretty, depth)
    depth = depth or 0
    local dataType = type(data)
    
    -- Handle nil
    if data == nil then
        return "null"
    end
    
    -- Handle strings
    if dataType == "string" then
        return encodeString(data)
    end
    
    -- Handle numbers
    if dataType == "number" then
        return encodeNumber(data)
    end
    
    -- Handle booleans
    if dataType == "boolean" then
        return tostring(data)
    end
    
    -- Handle vec3 (specific to LÖVR)
    if dataType == "userdata" and data.type and data:type() == "vec3" then
        local x, y, z = data:unpack()
        local format = pretty and '{\n  "x": %s,\n  "y": %s,\n  "z": %s\n}' 
                            or '{"x":%s,"y":%s,"z":%s}'
        return string.format(format, 
            encodeNumber(x), 
            encodeNumber(y), 
            encodeNumber(z)
        )
    end
    
    -- Handle tables
    if dataType == "table" then
        local isArray = true
        local n = 0
        for k, v in pairs(data) do
            n = n + 1
            if type(k) ~= "number" or k ~= n then
                isArray = false
                break
            end
        end
        
        local parts = {}
        local nextDepth = depth + 1
        
        if isArray then
            -- Array
            for _, v in ipairs(data) do
                local encoded = json.encode(v, pretty, nextDepth)
                if pretty then encoded = "  " .. string.rep("  ", depth) .. encoded end
                table.insert(parts, encoded)
            end
            local separator = pretty and ",\n" or ","
            local spacing = pretty and "\n" .. string.rep("  ", depth) or ""
            return "[" .. spacing .. table.concat(parts, separator) .. spacing .. "]"
        else
            -- Object
            local keys = {}
            for k in pairs(data) do table.insert(keys, k) end
            table.sort(keys) -- Ensure consistent ordering
            
            for _, k in ipairs(keys) do
                table.insert(parts, encodePair(k, data[k], pretty, nextDepth))
            end
            local separator = pretty and ",\n" or ","
            local spacing = pretty and "\n" .. string.rep("  ", depth) or ""
            return "{" .. spacing .. table.concat(parts, separator) .. spacing .. "}"
        end
    end
    
    return "null"
end

local function decodeString(str, pos)
    local quote = str:sub(pos, pos)
    if quote ~= '"' and quote ~= "'" then
        error("String must start with quote at position " .. pos)
    end
    
    local result = ""
    pos = pos + 1
    local escaped = false
    
    while pos <= #str do
        local c = str:sub(pos, pos)
        if escaped then
            if c == 'n' then result = result .. '\n'
            elseif c == 'r' then result = result .. '\r'
            elseif c == 't' then result = result .. '\t'
            else result = result .. c
            end
            escaped = false
        elseif c == '\\' then
            escaped = true
        elseif c == quote then
            return result, pos + 1
        else
            result = result .. c
        end
        pos = pos + 1
    end
    error("Unterminated string starting at position " .. pos)
end

local function skipWhitespace(str, pos)
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c ~= ' ' and c ~= '\t' and c ~= '\n' and c ~= '\r' then
            break
        end
        pos = pos + 1
    end
    return pos
end

local function decodeNumber(str, pos)
    local endPos = pos
    while endPos <= #str do
        local c = str:sub(endPos, endPos)
        if not c:match("[%d%.%-+eE]") then break end
        endPos = endPos + 1
    end
    
    local numStr = str:sub(pos, endPos - 1)
    local num = tonumber(numStr)
    if not num then
        if numStr == "Infinity" then return math.huge, endPos end
        if numStr == "-Infinity" then return -math.huge, endPos end
        if numStr == "NaN" then return 0/0, endPos end
        error("Invalid number at position " .. pos)
    end
    return num, endPos
end

local function decode(str, pos)
    pos = skipWhitespace(str, pos)
    local c = str:sub(pos, pos)
    
    if c == '{' then
        -- Object
        local result = {}
        pos = pos + 1
        
        pos = skipWhitespace(str, pos)
        if str:sub(pos, pos) == '}' then
            return result, pos + 1
        end
        
        while true do
            pos = skipWhitespace(str, pos)
            local key
            key, pos = decodeString(str, pos)
            
            pos = skipWhitespace(str, pos)
            if str:sub(pos, pos) ~= ':' then
                error("Expected ':' at position " .. pos)
            end
            pos = pos + 1
            
            local value
            value, pos = decode(str, pos)
            result[key] = value
            
            pos = skipWhitespace(str, pos)
            c = str:sub(pos, pos)
            
            if c == '}' then
                return result, pos + 1
            elseif c == ',' then
                pos = pos + 1
            else
                error("Expected ',' or '}' at position " .. pos)
            end
        end
        
    elseif c == '[' then
        -- Array
        local result = {}
        pos = pos + 1
        
        pos = skipWhitespace(str, pos)
        if str:sub(pos, pos) == ']' then
            return result, pos + 1
        end
        
        while true do
            local value
            value, pos = decode(str, pos)
            table.insert(result, value)
            
            pos = skipWhitespace(str, pos)
            c = str:sub(pos, pos)
            
            if c == ']' then
                return result, pos + 1
            elseif c == ',' then
                pos = pos + 1
            else
                error("Expected ',' or ']' at position " .. pos)
            end
        end
        
    elseif c == '"' or c == "'" then
        -- String
        return decodeString(str, pos)
        
    elseif c:match("[%d%.%-]") then
        -- Number
        return decodeNumber(str, pos)
        
    elseif c == 'n' then
        -- null
        if str:sub(pos, pos + 3) == "null" then
            return nil, pos + 4
        end
        error("Expected 'null' at position " .. pos)
        
    elseif c == 't' then
        -- true
        if str:sub(pos, pos + 3) == "true" then
            return true, pos + 4
        end
        error("Expected 'true' at position " .. pos)
        
    elseif c == 'f' then
        -- false
        if str:sub(pos, pos + 4) == "false" then
            return false, pos + 5
        end
        error("Expected 'false' at position " .. pos)
    end
    
    error("Unexpected character at position " .. pos)
end

function json.decode(str)
    if type(str) ~= "string" then
        error("Expected string, got " .. type(str))
    end
    
    local result, pos = decode(str, 1)
    pos = skipWhitespace(str, pos)
    
    if pos <= #str then
        error("Trailing characters at position " .. pos)
    end
    
    return result
end

return json