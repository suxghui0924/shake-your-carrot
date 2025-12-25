local TimeFormatter = {}

function TimeFormatter.formatTime(sec: number): string
    sec = math.max(0, math.floor(sec or 0))
    local minutes = math.floor(sec / 60)
    local seconds = sec % 60
    return string.format("%02d:%02d", minutes, seconds)
end

return TimeFormatter
