require "common"

local socket = require("socket")
local udp = socket.udp()
local res, err

settings = {
    address = "0.0.0.0",
    port = 8000,
    username = "unknown",
    server = false,
}

require "argparse"

-- Start program
local raw_args = { ... }

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

add_argument(
    "server", {"server", "-s"},
    "boolean", "false", "Starts the program in server mode",
    "set", "server"
)

parse(raw_args)


function server_mode()
    -- Server mode
    print_color("SERVER", colors.yellow)

    res, err = udp:setsockname("0.0.0.0", settings.port)
    print(("Listening on %d"):format(settings.port))

    -- Set packet read timeout
    udp:settimeout(1)

    while true do
        local data = udp:receive()
        
        if data ~= nil then 
            pprint(data)
        end
    end
end

function client_mode()
    -- Client mode
    print_color("CLIENT", colors.yellow)

    res, err = udp:setpeername(settings.address, settings.port)
    print(("Target address %s:%d"):format(settings.address, settings.port))

    while true do
        local message = ("<%s>: "):format(settings.username)
        io.write(message)
        message = message .. io.read()

        -- Send message
        res, err = udp:send(message)
        print(err)
    end
end

----------
-- MAIN --
----------

if settings.server then
    server_mode()
else
    client_mode()
end