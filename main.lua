require "common"

local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")
local socket = require("socket")

local receiver_udp = socket.udp()
local sender_udp = socket.udp()

local res, err

settings = {
    address = "0.0.0.0",
    public_ip = "0.0.0.0",
    port = 8000,
    username = "unknown",
    server = false,

    client_id = 0,
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

-- Find public IP of this peer
print("Retrieving public IP...")

local response_body = {}
local res, code = http.request{
    url = "http://api.ipify.org",
    sink = ltn12.sink.table(response_body)
}
if code == 200 then
    settings.public_ip = table.concat(response_body)
    print(("IP: %s"):format(settings.public_ip))
else
    print_color("Failed to retrieve IP address: HTTP " .. tostring(code), colors.red)
end

local clients = {}
local client_id = 1

local function makePacket(messageType, data)
    local ip = targetIp or settings.address
    local port = targetPort or settings.port

    local packetTypes = {
        join = 0,
        ack = 1,
        message = 5,
        disconnect = 6,
    }

    if packetTypes[messageType] ~= nil then
        data.type = packetTypes[messageType]
        return json.encode(data)
    end

    return '{"type": -1}'
end

local function server_mode()
    -- Server mode
    print_color("SERVER", colors.yellow)

    res, err = receiver_udp:setsockname("0.0.0.0", settings.port)
    print(("Listening on %d"):format(settings.port))

    -- Set packet read timeout
    receiver_udp:settimeout(1)

    while true do
        local str = receiver_udp:receive()
        
        if str ~= nil then 
            local data = json.decode(str, 1)

            pprint(data)

            if data.type == 0 then
                -- Someone joined
                print(data.msg)
                
                client_id = client_id + 1
                local str = makePacket("ack", {
                    id = client_id
                })

                print("Waiting...")
                sleep(1)

                sender_udp:sendto(str, data.ip, settings.port)
                print("Sending ack", data.ip, settings.port, client_id)

            end

        end
    end
end

function client_mode()
    -- Client mode
    print_color("CLIENT", colors.yellow)

    res, err = sender_udp:setpeername(settings.address, settings.port)
    print(("Target address %s:%d"):format(settings.address, settings.port))

    res, err = receiver_udp:setsockname("0.0.0.0", settings.port)
    print(("Listening on %d"):format(settings.port))

    -- Set packet read timeout
    receiver_udp:settimeout(1)



    local str = makePacket("join", {
        msg = ("<%s> joined the chat"):format(settings.username),
        username = settings.username,
        ip = settings.public_ip,
    })

    res, err = sender_udp:send(str)

    while true do
        local str = receiver_udp:receive()
        
        if str ~= nil then 
            local data = json.decode(str, 1)

            pprint(data)

            if data.type == 1 then
                -- Someone joined
                print(data.id)
            end

        end
    end

    --[[while true do
        local message = ("<%s>: "):format(settings.username)
        io.write(message)
        message = message .. io.read()

        local str = makePacket("message", {
            msg = message,
            username = settings.username,
            id = settings.client_id,
        })

        res, err = sender_udp:send(str)
    end]]
end

----------
-- MAIN --
----------

if settings.server then
    server_mode()
else
    client_mode()
end