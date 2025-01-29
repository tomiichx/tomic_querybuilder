---@class Utilities
local Utilities = lib.class('Utilities')

---Map function for tables
---@param tbl table The table to map over
---@param fn function The function to apply to each element
---@return table
function Utilities.map(tbl, fn)
    local mapped = {}
    for i, v in ipairs(tbl) do
        mapped[i] = fn(v)
    end
    return mapped
end

---Helper function to ensure proper backtick escaping for identifiers
---@param identifier string
---@return string
function Utilities.ensureBackticks(identifier)
    if identifier:match('^`.*`$') then
        return identifier
    end

    if identifier == '*' then
        return identifier
    end

    return '`' .. identifier .. '`'
end

function Utilities.getSorted(tbl)
    local sortedKeys = {}

    for k in pairs(tbl) do
        table.insert(sortedKeys, k)
    end

    table.sort(sortedKeys)

    return sortedKeys
end

return Utilities
