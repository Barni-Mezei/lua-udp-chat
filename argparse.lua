local args = {}
local aliases = {}

--"minet.switch.default_gateway"
-- arg_name ("wlan"): The name of the argument
-- arg_aliases ("wlan", "-w"): The aliases of this argument
-- arg_type ("number"): The type of this argument (string|number|boolean|table)
-- arg_description ("The WLAN of this device"): The description of this argument
-- arg_action ("set"): Action to do with the provided argument.
--            set: modifies the settings
--            call: calls the provided function, with the input passed in as a string
-- arg_path ("minet.wlan"): The setting path or a callable
function add_argument(arg_name, arg_aliases, arg_type, arg_default, arg_description, arg_action, arg_path)
    args[#args + 1] = {
        alias = arg_aliases,
        name = arg_name,
        type = arg_type,
        default = arg_default,
        description = arg_description,

        action = arg_action,
        path = arg_path,
    }
end

local function generate_aliases()
    for arg_index,arg in pairs(args) do
        for _,alias in pairs(arg.alias) do
            aliases[alias] = arg_index
        end
    end
end


-- Prints a colored help message line
function print_help(arg_name, arg_type, default_value, description)
    io.write(arg_name.." ")
    write_color("("..arg_type..")", colors.gray)
    io.write(": ")
    write_color(default_value, colors.yellow)
    print(" - "..description)
end

function list_arguments()
    for _,arg in pairs(args) do
        print_help(arg.name, arg.type, arg.default, arg.description)
    end
end

local function convert(str, target_type)
    if target_type == "string" then return str end
    if target_type == "number" then return tonumber(str) end
    if target_type == "boolean" then return str == "1" or str == "true" end

    return str
end

function parse(raw_args)
    generate_aliases()

    local arg_index = nil

    for i = 1, #raw_args do
        -- Display help message
        if raw_args[i] == "help" or raw_args[i] == "-h" then
            list_arguments()

            os.exit()
        end

        -- Execute argument action
        if arg_index then
            local action = args[arg_index].action
            local arg_type = args[arg_index].type
            local path = args[arg_index].path
            local name = args[arg_index].name

            if action == "set" then
                settings[path] = convert(raw_args[i], arg_type)
                print_color(("Set %s: %s"):format(
                    string.upper(name),
                    tostring(raw_args[i])
                ), colors.gray)
            end

            -- Call the specified function
            if action == "call" then
                path(raw_args[i])
            end

            arg_index = nil
        end

        -- Get argument type
        if arg_index == nil and aliases[raw_args[i]] ~= nil then
            arg_index = aliases[raw_args[i]]
        end 
    end

end