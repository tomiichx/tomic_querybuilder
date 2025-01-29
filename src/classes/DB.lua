---@class QueryBuilder
local QueryBuilder <const> = require 'src.classes.QueryBuilder'

---@class DB
local DB = lib.class('DB')

---Create a new QueryBuilder instance
---@param name string
---@return QueryBuilder
function DB:table(name)
    return QueryBuilder:constructor(name)
end

return DB
