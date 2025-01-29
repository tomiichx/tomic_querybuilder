local Input <const> = require 'src.classes.Input'
local Utilities <const> = require 'src.classes.Utilities'

---@class QueryBuilder
---@field selects table
---@field from string
---@field wheres table
---@field groupBys table
---@field orderBys table
---@field _limit number
---@field _offset number
---@field input Input
local QueryBuilder = lib.class('QueryBuilder')

---Creates a new QueryBuilder instance
---@param tableName string
---@return QueryBuilder
function QueryBuilder:constructor(tableName)
    self.selects = {}
    self.from = tableName
    self.wheres = {}
    self.groupBys = {}
    self.orderBys = {}
    self._limit = nil
    self._offset = nil

    return self
end

---Add a raw select clause
---@param expression string
---@return QueryBuilder
function QueryBuilder:selectRaw(expression)
    self.selects[#self.selects + 1] = expression
    return self
end

---Select specific columns
---@param ... string
---@return QueryBuilder
function QueryBuilder:select(...)
    self.selects = { ... }
    return self
end

---Add a raw where clause
---@param expression string
---@return QueryBuilder
function QueryBuilder:whereRaw(expression)
    self.wheres[#self.wheres + 1] = expression
    return self
end

---Add a where clause
---@param column string
---@param operator string|any
---@param value any|nil
---@return QueryBuilder
function QueryBuilder:where(column, operator, value)
    if value == nil then
        value = operator
        operator = '='
    end

    value = type(value) == 'table' and
        Input:sanitizeTable(value) or
        Input:sanitize(value)

    self.wheres[#self.wheres + 1] = {
        column = column,
        operator = operator,
        value = value
    }

    return self
end

---Add an ORDER BY clause
---@param column string
---@param direction string
---@return QueryBuilder
function QueryBuilder:orderBy(column, direction)
    if not direction then
        direction = 'ASC'
    end

    local preparedDirection = direction:upper()

    if preparedDirection ~= 'ASC' and preparedDirection ~= 'DESC' then
        error('Invalid direction. Must be either ASC or DESC.')
    end

    self.orderBys[#self.orderBys + 1] = { column = column, direction = direction }

    return self
end

---Set LIMIT clause
---@param limit number
---@return QueryBuilder
function QueryBuilder:limit(limit)
    self._limit = limit
    return self
end

---Set OFFSET clause
---@param offset number
---@return QueryBuilder
function QueryBuilder:offset(offset)
    self._offset = offset
    return self
end

---Build the SQL query
---@param isCount ?boolean
---@return string query, table params
function QueryBuilder:buildQuery(isCount)
    local query, params = self:buildSelectQuery(isCount or false)
    return query, params
end

---Execute the query and get all results
---@return table
function QueryBuilder:get()
    local query, params = self:buildQuery()
    return MySQL.query.await(query, params)
end

---Execute the query and get the first result
---@return number
function QueryBuilder:count()
    local query, params = self:buildQuery(true)
    return MySQL.scalar.await(query, params)
end

---Insert data into the table
---@param data table
---@return number insertId
function QueryBuilder:insert(data)
    local query, params = self:buildInsertQuery(data)
    return MySQL.insert.await(query, params)
end

---Update data in the table
---@param data table
---@return number affectedRows
function QueryBuilder:update(data)
    local query, params = self:buildUpdateQuery(data)
    return MySQL.update.await(query, params)
end

---Delete records from the table
---@return number affectedRows
function QueryBuilder:delete()
    local query, params = self:buildDeleteQuery()
    return MySQL.update.await(query, params)
end

---Build select query
---@param isCount ?boolean
---@return string query, table params
function QueryBuilder:buildSelectQuery(isCount)
    isCount = isCount or false

    local query = {
        ('SELECT %s FROM %s'):format(
            isCount and 'COUNT(*)' or (#self.selects == 0 and '*' or table.concat(
                Utilities.map(self.selects, Utilities.ensureBackticks),
                ', '
            )),
            Utilities.ensureBackticks(self.from)
        )
    }

    local params = {}

    if #self.wheres > 0 then
        local whereClause, whereParams = self:buildWhereClause(params)
        query[#query + 1] = 'WHERE ' .. whereClause
        params = whereParams
    end

    if #self.orderBys > 0 then
        local clauses = {}

        for _, orderBy in ipairs(self.orderBys) do
            clauses[#clauses + 1] = ('%s %s'):format(
                Utilities.ensureBackticks(orderBy.column),
                orderBy.direction
            )
        end

        query[#query + 1] = 'ORDER BY ' .. table.concat(clauses, ', ')
    end

    if self._limit then
        query[#query + 1] = 'LIMIT ' .. self._limit
    end

    if self._offset then
        query[#query + 1] = 'OFFSET ' .. self._offset
    end

    return table.concat(query, ' '), params
end

---Build where clause
---@param params table
---@return string clause
---@return table params
function QueryBuilder:buildWhereClause(params)
    if #self.wheres == 0 then
        return '', params
    end

    local clauses = {}

    for _, where in ipairs(self.wheres) do
        if type(where) == 'string' then
            clauses[#clauses + 1] = where
        else
            clauses[#clauses + 1] = ('%s %s ?'):format(
                Utilities.ensureBackticks(where.column),
                where.operator
            )

            params[#params + 1] = where.value
        end
    end

    return table.concat(clauses, ' AND '), params
end

---Build insert query
---@param data table
---@return string query, table params
function QueryBuilder:buildInsertQuery(data)
    local columns = {}
    local values = {}
    local params = {}

    for _, column in ipairs(Utilities.getSorted(data)) do
        columns[#columns + 1] = Utilities.ensureBackticks(column)
        values[#values + 1] = '?'
        params[#params + 1] = data[column]
    end

    return
        ('INSERT INTO %s (%s) VALUES (%s)'):format(
            Utilities.ensureBackticks(self.from),
            table.concat(columns, ', '),
            table.concat(values, ', ')
        ),
        params
end

---Build update query
---@param data table
---@return string query, table params
function QueryBuilder:buildUpdateQuery(data)
    local columns = {}
    local params = {}

    for _, column in ipairs(Utilities.getSorted(data)) do
        columns[#columns + 1] = Utilities.ensureBackticks(column) .. ' = ?'
        params[#params + 1] = data[column]
    end

    return
        ('UPDATE %s SET %s WHERE %s'):format(
            Utilities.ensureBackticks(self.from),
            table.concat(columns, ', '),
            self:buildWhereClause(params)
        ),
        params
end

---Build delete query
---@return string query, table params
function QueryBuilder:buildDeleteQuery()
    local params = {}
    local query = ('DELETE FROM %s'):format(Utilities.ensureBackticks(self.from))

    if #self.wheres > 0 then
        local whereClause, whereParams = self:buildWhereClause(params)
        query = query .. ' WHERE ' .. whereClause
        params = whereParams
    end

    return query, params
end

return QueryBuilder
