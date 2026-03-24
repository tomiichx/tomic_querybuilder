---@class QueryBuilder
local QueryBuilder = require "src.classes.QueryBuilder"

---@class DB
DB = lib.class("DB")

---@param name string
---@return QueryBuilder
function DB:table(name)
    return QueryBuilder:constructor(name)
end

return DB
