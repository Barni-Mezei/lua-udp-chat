colors = {
    red = "\27[31m",
    green = "\27[32m",
    blue = "\27[34m",
    aqua = "\27[36m",
    yellow = "\27[93m",

    black = "\27[30m",
    gray = "\27[90m",
    light_gray = "\27[37m",
    white = "\27[m",
}

-- Prints a text in color
function print_color(text, color)
    local c = color or ""
    print(("%s%s%s"):format(c, text, colors.white))
end

-- Writes a text in color
function write_color(text, color)
    local c = color or ""
    io.write(("%s%s%s"):format(c, text, colors.white))
end