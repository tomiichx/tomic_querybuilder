---@class Input
local Input = {}

---@param value any
---@return any
function Input.sanitize(value)
    if type(value) ~= "string" then
        return value
    end

    value = value:gsub("[%c]", "")

    value = value:gsub("\'", "\'\'")
    value = value:gsub("\\", "\\\\")

    return value
end

---@param data table
---@return table
function Input.sanitizeTable(data)
    local sanitized = {}

    for k, v in pairs(data) do
        if type(v) == "table" then
            sanitized[k] = Input.sanitizeTable(v)
        else
            sanitized[k] = Input.sanitize(v)
        end
    end

    return sanitized
end

return Input
