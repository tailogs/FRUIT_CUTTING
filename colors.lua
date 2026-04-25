local colors = {}

colors.palette = {
    {1, 0.2, 0.2},
    {0.2, 1, 0.2},
    {0.2, 0.2, 1},
    {1, 1, 0.2},
    {1, 0.5, 0.2},
    {0.8, 0.2, 1},
    {1, 0.8, 0}
}

function colors.get(index)
    return colors.palette[index] or {1, 1, 1}
end

function colors.random()
    local idx = math.random(1, #colors.palette)
    return colors.palette[idx]
end

function colors.toString(color)
    return string.format("RGB(%.1f, %.1f, %.1f)", color[1], color[2], color[3])
end

return colors