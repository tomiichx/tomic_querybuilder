---@class Input
local Input = require "src.classes.Input"

---@class Utilities
local Utilities = require "src.classes.Utilities"

---@class QueryBuilder
---@field selects table
---@field from string
---@field wheres table
---@field groupBys table
---@field orderBys table
---@field _limit number?
---@field _offset number?
---@field _distinct boolean
local QueryBuilder = lib.class("QueryBuilder")

---@param tableName string
---@return QueryBuilder
function QueryBuilder:constructor(tableName)
    if Utilities.isEmpty(tableName) then
        error(("[%s]: Table name must be provided."):format(Utilities.CURRENT_RESOURCE_NAME))
    end

    self.selects = {}
    self.from = tableName
    self.wheres = {}
    self.groupBys = {}
    self.orderBys = {}
    self._limit = nil
    self._offset = nil
    self._distinct = false

    return self
end

---@param expression string
---@return QueryBuilder
function QueryBuilder:selectRaw(expression)
    self.selects[#self.selects + 1] = expression
    return self
end

---@param ... string
---@return QueryBuilder
function QueryBuilder:select(...)
    self.selects = { ... }
    return self
end

---@return QueryBuilder
function QueryBuilder:distinct()
    self._distinct = true
    return self
end

---@param expression string
---@param ... any
---@return QueryBuilder
function QueryBuilder:whereRaw(expression, ...)
    self.wheres[#self.wheres + 1] = { _raw = expression, params = Input.sanitizeTable({ ... }), _conjunction = "AND" }
    return self
end

---@param column string
---@param operator string|any
---@param value any?
---@return QueryBuilder
function QueryBuilder:where(column, operator, value)
    if value == nil then
        value = operator
        operator = "="
    end

    self.wheres[#self.wheres + 1] = {
        column = column,
        operator = operator,
        value = type(value) == "table" and
            Input.sanitizeTable(value) or
            Input.sanitize(value),
        _conjunction = "AND",
    }

    return self
end

---@param column string
---@param operator string|any
---@param value any?
---@return QueryBuilder
function QueryBuilder:orWhere(column, operator, value)
    if value == nil then
        value = operator
        operator = "="
    end

    self.wheres[#self.wheres + 1] = {
        column = column,
        operator = operator,
        value = type(value) == "table" and
            Input.sanitizeTable(value) or
            Input.sanitize(value),
        _conjunction = "OR",
    }

    return self
end

---@param column string
---@param values table
---@return QueryBuilder
function QueryBuilder:whereIn(column, values)
    self.wheres[#self.wheres + 1] = {
        _in = true,
        column = column,
        values = Input.sanitizeTable(values),
        _conjunction = "AND",
    }

    return self
end

---@param column string
---@return QueryBuilder
function QueryBuilder:whereNull(column)
    self.wheres[#self.wheres + 1] = {
        _null = true,
        column = column,
        _conjunction = "AND",
    }

    return self
end

---@param column string
---@return QueryBuilder
function QueryBuilder:whereNotNull(column)
    self.wheres[#self.wheres + 1] = {
        _notNull = true,
        column = column,
        _conjunction = "AND",
    }

    return self
end

---@param column string
---@param min any
---@param max any
---@return QueryBuilder
function QueryBuilder:whereBetween(column, min, max)
    self.wheres[#self.wheres + 1] = {
        _between = true,
        column = column,
        min = Input.sanitize(min),
        max = Input.sanitize(max),
        _conjunction = "AND",
    }

    return self
end

---@param column string
---@return QueryBuilder
function QueryBuilder:groupBy(column)
    self.groupBys[#self.groupBys + 1] = column
    return self
end

---@param column string
---@param direction? string
---@return QueryBuilder
function QueryBuilder:orderBy(column, direction)
    if not direction then
        direction = "ASC"
    end

    local preparedDirection = direction:upper()

    if preparedDirection ~= "ASC" and preparedDirection ~= "DESC" then
        error(("[%s]: Invalid direction provided."):format(Utilities.CURRENT_RESOURCE_NAME))
    end

    self.orderBys[#self.orderBys + 1] = { column = column, direction = direction }

    return self
end

---@param limit number
---@return QueryBuilder
function QueryBuilder:limit(limit)
    self._limit = limit
    return self
end

---@param offset number
---@return QueryBuilder
function QueryBuilder:offset(offset)
    self._offset = offset
    return self
end

---@param isCount? boolean
---@return string query, table params
function QueryBuilder:buildQuery(isCount)
    local query, params = self:buildSelectQuery(isCount or false)
    return query, params
end

---@return table
function QueryBuilder:get()
    local query, params = self:buildQuery()
    return MySQL.query.await(query, params)
end

---@return table?
function QueryBuilder:first()
    local query, params = self:buildSelectQuery(false)

    if not self._limit then
        query = query .. " LIMIT 1"
    end

    return MySQL.single.await(query, params)
end

---@return number
function QueryBuilder:count()
    local query, params = self:buildQuery(true)
    return MySQL.scalar.await(query, params)
end

---@param column string
---@return number
function QueryBuilder:sum(column)
    local query, params = self:buildAggregateQuery("SUM", column)
    return MySQL.scalar.await(query, params)
end

---@param column string
---@return any
function QueryBuilder:min(column)
    local query, params = self:buildAggregateQuery("MIN", column)
    return MySQL.scalar.await(query, params)
end

---@param column string
---@return any
function QueryBuilder:max(column)
    local query, params = self:buildAggregateQuery("MAX", column)
    return MySQL.scalar.await(query, params)
end

---@param column string
---@return number
function QueryBuilder:avg(column)
    local query, params = self:buildAggregateQuery("AVG", column)
    return MySQL.scalar.await(query, params)
end

---@param perPage number
---@param page number
---@return table
function QueryBuilder:paginate(perPage, page)
    local total = self:count()
    local results = self:limit(perPage):offset((page - 1) * perPage):get()

    return {
        data = results,
        totalCount = total,
        perPage = perPage,
        currentPage = page,
        lastPage = math.ceil(total / perPage)
    }
end

---@param data table
---@return number insertId
function QueryBuilder:insert(data)
    local query, params = self:buildInsertQuery(data)
    return MySQL.insert.await(query, params)
end

---@param data table
---@return number affectedRows
function QueryBuilder:update(data)
    local query, params = self:buildUpdateQuery(data)
    return MySQL.update.await(query, params)
end

---@return number affectedRows
function QueryBuilder:delete()
    local query, params = self:buildDeleteQuery()
    return MySQL.update.await(query, params)
end

---@param fn string
---@param column string
---@return string query, table params
function QueryBuilder:buildAggregateQuery(fn, column)
    local query = {
        ("SELECT %s(%s) FROM %s"):format(
            fn,
            Utilities.ensureBackticks(column),
            Utilities.ensureBackticks(self.from)
        )
    }

    local params = {}

    if #self.wheres > 0 then
        local whereClause = self:buildWhereClause(params)
        query[#query + 1] = "WHERE " .. whereClause
    end

    if #self.groupBys > 0 then
        query[#query + 1] = "GROUP BY " .. table.concat(
            Utilities.map(self.groupBys, Utilities.ensureBackticks),
            ", "
        )
    end

    return table.concat(query, " "), params
end

---@param isCount? boolean
---@return string query, table params
function QueryBuilder:buildSelectQuery(isCount)
    isCount = isCount or false

    local selectClause = "SELECT"

    if self._distinct and not isCount then
        selectClause = "SELECT DISTINCT"
    end

    local columns
    if isCount then
        columns = "COUNT(*)"
    elseif #self.selects == 0 then
        columns = "*"
    else
        columns = table.concat(
            Utilities.map(self.selects, Utilities.ensureBackticks),
            ", "
        )
    end

    local query = {
        ("%s %s FROM %s"):format(
            selectClause,
            columns,
            Utilities.ensureBackticks(self.from)
        )
    }

    local params = {}

    if #self.wheres > 0 then
        local whereClause = self:buildWhereClause(params)
        query[#query + 1] = "WHERE " .. whereClause
    end

    if #self.groupBys > 0 then
        query[#query + 1] = "GROUP BY " .. table.concat(
            Utilities.map(self.groupBys, Utilities.ensureBackticks),
            ", "
        )
    end

    if #self.orderBys > 0 then
        local clauses = {}

        for _, orderBy in ipairs(self.orderBys) do
            clauses[#clauses + 1] = ("%s %s"):format(
                Utilities.ensureBackticks(orderBy.column),
                orderBy.direction
            )
        end

        query[#query + 1] = "ORDER BY " .. table.concat(clauses, ", ")
    end

    if self._limit then
        query[#query + 1] = "LIMIT " .. self._limit
    end

    if self._offset then
        query[#query + 1] = "OFFSET " .. self._offset
    end

    return table.concat(query, " "), params
end

---@param params table
---@return string clause
function QueryBuilder:buildWhereClause(params)
    if #self.wheres == 0 then
        return ""
    end

    local result = {}

    for i, where in ipairs(self.wheres) do
        local clause

        if where._raw then
            clause = where._raw

            for j = 1, #where.params do
                params[#params + 1] = where.params[j]
            end
        elseif where._in then
            if #where.values == 0 then
                clause = "1 = 0"
            else
                local placeholders = {}
                for j = 1, #where.values do
                    placeholders[j] = "?"
                    params[#params + 1] = where.values[j]
                end

                clause = ("%s IN (%s)"):format(
                    Utilities.ensureBackticks(where.column),
                    table.concat(placeholders, ", ")
                )
            end
        elseif where._null then
            clause = ("%s IS NULL"):format(Utilities.ensureBackticks(where.column))
        elseif where._notNull then
            clause = ("%s IS NOT NULL"):format(Utilities.ensureBackticks(where.column))
        elseif where._between then
            clause = ("%s BETWEEN ? AND ?"):format(Utilities.ensureBackticks(where.column))
            params[#params + 1] = where.min
            params[#params + 1] = where.max
        elseif type(where) == "string" then
            clause = where
        else
            clause = ("%s %s ?"):format(
                Utilities.ensureBackticks(where.column),
                where.operator
            )
            params[#params + 1] = where.value
        end

        if i == 1 then
            result[1] = clause
        else
            result[#result + 1] = (" %s %s"):format(where._conjunction or "AND", clause)
        end
    end

    return table.concat(result)
end

---@param data table
---@return string query, table params
function QueryBuilder:buildInsertQuery(data)
    local columns = {}
    local values = {}
    local params = {}

    for _, column in ipairs(Utilities.getSorted(data)) do
        columns[#columns + 1] = Utilities.ensureBackticks(column)
        values[#values + 1] = "?"
        params[#params + 1] = type(data[column]) == "table" and
            json.encode(data[column]) or
            data[column]
    end

    return
        ("INSERT INTO %s (%s) VALUES (%s)"):format(
            Utilities.ensureBackticks(self.from),
            table.concat(columns, ", "),
            table.concat(values, ", ")
        ),
        params
end

---@param data table
---@return string query, table params
function QueryBuilder:buildUpdateQuery(data)
    local columns = {}
    local params = {}

    for _, column in ipairs(Utilities.getSorted(data)) do
        columns[#columns + 1] = Utilities.ensureBackticks(column) .. " = ?"
        params[#params + 1] = data[column]
    end

    local whereClause = self:buildWhereClause(params)

    return
        ("UPDATE %s SET %s WHERE %s"):format(
            Utilities.ensureBackticks(self.from),
            table.concat(columns, ", "),
            whereClause
        ),
        params
end

---@return string query, table params
function QueryBuilder:buildDeleteQuery()
    local params = {}
    local query = ("DELETE FROM %s"):format(Utilities.ensureBackticks(self.from))

    if #self.wheres > 0 then
        local whereClause = self:buildWhereClause(params)
        query = query .. " WHERE " .. whereClause
    end

    return query, params
end

return QueryBuilder
