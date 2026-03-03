require "src/setup"

local args = { ... }

add_argument(
    "config", {"cfg", "conf", "config"},
    "string", "settings.conf", "Path to a config file",
    "run", function (path)
        load_config(path)
    end
)

add_argument(
    "wlan", {"wlan", "-w"},
    "number", "1", "The WLAN of this device",
    "set", "minet.wlan"
)

add_argument(
    "ip", {"ip", "-a"},
    "string", "0.0.0.0", "Static IP for this device",
    "set", "minet.client.ip"
)

add_argument(
    "default_gateway", {"default_gateway", "-g"},
    "string", "top", "Fallback side of the block",
    "set", "minet.switch.default_gateway"
)

parse(args)

local has_static_ip = true

-- List loaded protocols
--pprint(known_protocols)

-- Disable single modem functionality
minet_close()
modem = nil



-- Enable multi-modem functionality
local used_sides = peripheral.getNames()
modems = {}

for _, side in pairs(used_sides) do
    if peripheral.getType(side) == "modem" then
        modems[#modems + 1] = peripheral.wrap(side)
        modems[#modems].side = side -- Store side in the modem table itself
    end
end

-- Modify packet sending functions
minet_open = function ()
    for _,modem in pairs(modems) do
        modem.open(settings.get("minet.wlan"))
    end    
end

minet_close = function ()
    for _,modem in pairs(modems) do
        modem.closeAll()
    end    
end

-- Broadcast packages
send_packet = function (packet_type, dest_ip, dest_port, data, excluded_sides)
    local packet = make_packet(packet_type, dest_ip, dest_port, data)

    for _,modem in pairs(modems) do
        modem.transmit(settings.get("minet.wlan"), settings.get("minet.wlan"), packet)
    end    
end

function send_raw_packet(packet_data, excluded_sides)
    if not check_packet(packet_data) then return end

    local es = excluded_sides or {}

    for _,modem in pairs(modems) do
        -- Send packets only on enabled sides
        if not table.contains(es, modem.side) then
            modem.transmit(settings.get("minet.wlan"), settings.get("minet.wlan"), packet_data)
        end
    end    
end


-- Open all modems
minet_open()

if settings.get("minet.client.ip") == "0.0.0.0" then
    -- Request IP if none was provided in the config
    print("Sending DHCP request...")
    send_packet(
        "dhcp",
        "192.168.5.5", 1,
        {mode = "request"}
    )

    has_static_ip = false
else
    data.client.ip = settings.get("minet.client.ip")
    print(("IP: %s"):format(data.client.ip))
end

print_color(("Running as a SWITCH\nDefualt gateway: %s"):format(
    settings.get("minet.switch.default_gateway")
), colors.yellow)

data.peer_mode = "switch"

set_name() -- Update computer name



--
-- MINET Standard protocols
--

-- TODO: Implement routing table
--       - Redirect by routing table
--       - Default to default_gateway
local function route_packet(message, side)
    --pprint(message)

    print(("Forwarding from %s to %s, incoming side: %s"):format(
        message.source.ip,
        message.destination.ip,
        side
    ))

    send_raw_packet(message, {side})
end

--
-- Main event loop
--
local function minet_event_loop()
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        -- Check if the message is a valid packet or not
        if not check_packet(message) then goto continue end

        --pprint(message)

        -- Ignore messages with blocked origins
        if message.type ~= "dhcp" and not ip_is_allowed(message.source.ip) then
            goto continue
        end 

        if message.type ~= "dhcp" and not port_is_allowed(message.source.port) then
            goto continue
        end

        --[[print_color(("MINET Packet received %d:%d d%f %s"):format(
            replyChannel, channel, distance, message.type
        ), colors.cyan)]]

        -- Update packet hop history
        message.hop_history[#message.hop_history + 1] = data.client.ip
        message.hop_distance = math.floor(message.hop_distance + distance)

        --pprint(message.hop_history)

        -- Drop packet if max loopcount is exceeded
        if table.count(message.hop_history, data.client.ip) > settings.get("minet.switch.max_loop_count") then
            print_color("Loop count exceeded!", colors.yellow)
            add_log("warning", "Max loop count exceeded!")
            add_log("warning", ("└ Packet from %s:%s to %s:%s"):format(
                message.source.ip, message.source.port,
                message.destination.ip, message.destination.port
            ))
            goto continue
        end

        -- Drop packet if max hopcount is exceeded
        if #message.hop_history > settings.get("minet.switch.max_hop_count") then
            print_color("Hop count exceeded!", colors.yellow)
            add_log("warning", "Max hop count exceeded!")
            add_log("warning", ("└ Packet from %s:%s to %s:%s"):format(
                message.source.ip, message.source.port,
                message.destination.ip, message.destination.port
            ))
            goto continue
        end


        handler = known_protocols[message["type"]]
        
        -- handle dhcp if:
        -- - Packet type is dhcp, but
        --   - it is for me
        if handler then
            if message.type == "dhcp" and message.data.mode == "response" and data.client.ip == "0.0.0.0" then 
                handler(message)
            else
                route_packet(message, side)
            end
        else
            route_packet(message, side)
        end

        ::continue::
    end
end

local function ui_event_loop()
    while true do
        local event, key, is_held = os.pullEvent("key")

        -- Clear screen if "c" is pressed
        if key == 67 then
            term.clear()
            term.setCursorPos(1, 1)
        end

        -- Break loops if "q" is pressed
        if key == 81 then
            return
        end
    end
end

local function tick_loop()
    while true do
        -- Increment tick counter
        data.client.timer = data.client.timer + 1
        sleep(0.05)
    end
end

parallel.waitForAny(minet_event_loop, ui_event_loop, tick_loop)

minet_exit()
