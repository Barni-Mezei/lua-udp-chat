require "colors"

local function pprint_iter(data, depth)
    local d = depth or 0

    if d > 64 then
        return "MAX_DEPTH"
    end

    local out = ""
    
    if type(data) == "table" then
        if next(data) == nil then
            out = ("%s%s{}%s"):format(out, colors.gray, colors.white)
        else
            out = out .. "{\n"
            for k, v in pairs(data) do
                out = out .. string.rep("    ", d + 1) .. tostring(k) .. " = " .. pprint_iter(v, d + 1) .. "\n"
            end
            out = out .. string.rep("    ", d) .. "}"
        end
    elseif type(data) == "string" then
        
        out = ("%s%s\"%s\"%s"):format(
            out,
            colors.yellow,
            data,
            colors.white
        )

    elseif type(data) == "number" then
        out = ("%s%s%s%s"):format(out, colors.red, data, colors.white)
    elseif type(data) == "boolean" then
        if data == true then
            out = ("%s%s%s%s"):format(out, colors.green, data, colors.white)
        else
            out = ("%s%s%s%s"):format(out, colors.red, data, colors.white)
        end
    else
        out = out .. tostring(data)
    end

    return out
end

-- Prints a value to the terminal
function pprint(data)
    print(pprint_iter(data))
end

-- Halts execution for the given amount of milliseconds
function sleep(ms) 
    local sec = tonumber(os.clock() + ms/1000); 
    while (os.clock() < sec) do
    end 
end