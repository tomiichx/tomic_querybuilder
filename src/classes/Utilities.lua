---@class Utilities
local Utilities = {}

local CURRENT_RESOURCE_NAME <const> = cache.resource
local CURRENT_ENVIRONMENT <const> = GetResourceMetadata(CURRENT_RESOURCE_NAME, "environment", 0)
local PRODUCTION <const> = "production"

---@type string
Utilities.CURRENT_RESOURCE_NAME = CURRENT_RESOURCE_NAME

---@return boolean
function Utilities.isProduction()
    return CURRENT_ENVIRONMENT == PRODUCTION
end

---@param tbl table
---@param fn function
---@return table
function Utilities.map(tbl, fn)
    local mapped = {}
    for i, v in ipairs(tbl) do
        mapped[i] = fn(v)
    end
    return mapped
end

---@param identifier string
---@return string
function Utilities.ensureBackticks(identifier)
    if identifier:match("^`.*`$") then
        return identifier
    end

    if identifier == "*" then
        return identifier
    end

    return "`" .. identifier .. "`"
end

---@param tbl table<string, any>
---@return string[]
function Utilities.getSorted(tbl)
    local sortedKeys = {}

    for k in pairs(tbl) do
        sortedKeys[#sortedKeys + 1] = k
    end

    table.sort(sortedKeys)

    return sortedKeys
end

---@param value string?
---@return boolean
function Utilities.isEmpty(value)
    local trimmedValue = (value or ""):match("^%s*(.-)%s*$")
    return trimmedValue == nil or trimmedValue == ""
end

return Utilities
