require "common"

local socket = require("socket")
local udp = socket.udp()
local res, err

-- Start program
local args = { ... }

if #args == 0 then
    -- Client mode
    print("CLIENT")

    res, err = udp:setpeername("szfp.duckdns.org", 34004)
    print("Target set", result, err)


    while true do
        io.write(": ")
        local message = io.read()

        -- Send message
        res, err = udp:send(message)
    end
else
    -- Server mode
    print("SERVER")

    res, err = udp:setsockname("127.0.0.1", 8000)
    print("Listen set", result, err)

    -- Set packet read timeout
    udp:settimeout(1)

    while true do
        local data = udp:receive()
        
        if data ~= nil then 
            pprint(data)
        end
    end
end
