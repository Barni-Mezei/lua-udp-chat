require "common"
require "argparse"

local socket = require("socket")
local udp = socket.udp()
local res, err

settings = {
    address = "0.0.0.0"
    port = 8000
    username = "unknown"
}

-- Start program
local args = { ... }

add_argument(
    "port", {"port", "-p"},
    "number", "8000", "The port of the server",
    "set", "port"
)

add_argument(
    "address", {"ip", "adr", "address", "-a"},
    "string", "0.0.0.0", "The IP of the server",
    "set", "address"
)

add_argument(
    "username", {"username", "name", "-u"},
    "string", "unknown", "The username of this client",
    "set", "username"
)

parse(args)

pprint(settings)

error()


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
