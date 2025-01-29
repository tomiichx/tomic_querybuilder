---@class Input
local Input = lib.class('Input')

---Sanitize a string value
---@param value string The value to sanitize
---@return string sanitized The sanitized value
function Input:sanitize(value)
    if type(value) ~= 'string' then
        return value
    end

    value = value:gsub('[%c]', '')

    value = value:gsub('\'', '\'\'')
    value = value:gsub('\\', '\\\\')

    return value
end

---Sanitize a table of values recursively
---@param data table The table to sanitize
---@return table sanitized The sanitized table
function Input:sanitizeTable(data)
    local sanitized = {}

    for k, v in pairs(data) do
        if type(v) == 'table' then
            sanitized[k] = self:sanitizeTable(v)
        else
            sanitized[k] = self:sanitize(v)
        end
    end

    return sanitized
end

---Bind a value for SQL query parameter
---@param value any The value to bind
---@param params table The parameters table to add the binding to
---@return string The parameter placeholder
function Input:bind(value, params)
    value = self:sanitize(value)
    params[#params + 1] = value
    return '?'
end

return Input
