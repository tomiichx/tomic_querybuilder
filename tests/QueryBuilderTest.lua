---@class Utilities
local Utilities = require 'src.classes.Utilities'

if Utilities.isProduction() then
    print(('[%s]: \'QueryBuilder\' tests skipped in the production environment.'):format(Utilities.CURRENT_RESOURCE_NAME))
    return
end

---@class DB
local DB = require 'src.classes.DB'

local function assertEquals(expected, actual, message)
    if expected ~= actual then
        print(('❌ Test failed: %s'):format(message))
        print(('Expected: %s'):format(tostring(expected)))
        print(('Actual: %s'):format(tostring(actual)))

        return false
    end

    print(('✅ Test passed: %s'):format(message))
    return true
end

local function assertTableEquals(expected, actual, message)
    if #expected ~= #actual then
        print(('❌ Test failed: %s (different lengths)'):format(message))
        return false
    end

    for i = 1, #expected do
        if expected[i] ~= actual[i] then
            print(('❌ Test failed: %s (mismatch at index %d)'):format(message, i))
            print(('Expected: %s'):format(tostring(expected[i])))
            print(('Actual: %s'):format(tostring(actual[i])))

            return false
        end
    end

    print(('✅ Test passed: %s'):format(message))
    return true
end

local tests = {
    -- Test basic select
    function()
        local query = DB:table('users'):buildQuery()

        return assertEquals(
            'SELECT * FROM `users`',
            query,
            'Basic select query should be correctly formed'
        )
    end,

    -- Test count
    function()
        local query, params = DB:table('users'):buildQuery(true)

        return assertEquals(
            'SELECT COUNT(*) FROM `users`',
            query,
            'Count query should be correctly formed'
        ) and assertTableEquals(
            {},
            params,
            'Count query should not bind any parameters'
        )
    end,

    -- Test select with specific columns
    function()
        local query = DB:table('users')
            :select('id', 'username', 'email')
            :buildQuery()

        return assertEquals(
            'SELECT `id`, `username`, `email` FROM `users`',
            query,
            'Select with specific columns should be correctly formed'
        )
    end,

    -- Test where clause
    function()
        local query, params = DB:table('users')
            :where('id', 1)
            :buildQuery()

        return assertEquals(
            'SELECT * FROM `users` WHERE `id` = ?',
            query,
            'Where clause should be correctly formed'
        ) and assertTableEquals(
            { 1 },
            params,
            'Where parameters should be correctly bound'
        )
    end,

    -- Test multiple where clauses
    function()
        local query, params = DB:table('users')
            :where('age', '>', 18)
            :where('status', 'active')
            :buildQuery()

        return assertEquals(
            'SELECT * FROM `users` WHERE `age` > ? AND `status` = ?',
            query,
            'Multiple where clauses should be correctly formed'
        ) and assertTableEquals(
            { 18, 'active' },
            params,
            'Multiple where parameters should be correctly bound'
        )
    end,

    -- Test group by
    function()
        local query = DB:table('users')
            :groupBy('group')
            :buildQuery()

        return assertEquals(
            'SELECT * FROM `users` GROUP BY `group`',
            query,
            'Group by clause should be correctly formed'
        )
    end,

    -- Test order by
    function()
        local query = DB:table('users')
            :orderBy('username', 'DESC')
            :buildQuery()

        return assertEquals(
            'SELECT * FROM `users` ORDER BY `username` DESC',
            query,
            'Order by clause should be correctly formed'
        )
    end,

    -- Test limit and offset
    function()
        local query = DB:table('users')
            :limit(10)
            :offset(20)
            :buildQuery()

        return assertEquals(
            'SELECT * FROM `users` LIMIT 10 OFFSET 20',
            query,
            'Limit and offset should be correctly formed'
        )
    end,

    -- Test SQL injection prevention in where clause
    function()
        local maliciousInput = "1; DROP TABLE users; --"
        local query, params = DB:table('users')
            :where('id', maliciousInput)
            :buildQuery()

        return assertEquals(
            'SELECT * FROM `users` WHERE `id` = ?',
            query,
            'SQL injection in where clause should be prevented'
        ) and assertTableEquals(
            { maliciousInput },
            params,
            'Malicious input should be parameterized'
        )
    end,

    -- Test SQL injection prevention in column names
    function()
        local maliciousColumn = "id FROM users; DROP TABLE users; SELECT * FROM users WHERE id"
        local query = DB:table('users')
            :where(maliciousColumn, 1)
            :buildQuery()

        return assertEquals(
            'SELECT * FROM `users` WHERE `' .. maliciousColumn .. '` = ?',
            query,
            'Column names should not be parameterized (handled by developer)'
        )
    end,

    -- Test complex query
    function()
        local query, params = DB:table('users')
            :select('id', 'username', 'email')
            :where('age', '>', 18)
            :where('status', 'active')
            :groupBy('group')
            :orderBy('username', 'DESC')
            :limit(10)
            :offset(20)
            :buildQuery()

        return assertEquals(
            'SELECT `id`, `username`, `email` FROM `users` WHERE `age` > ? AND `status` = ? GROUP BY `group` ORDER BY `username` DESC LIMIT 10 OFFSET 20',
            query,
            'Complex query should be correctly formed'
        ) and assertTableEquals(
            { 18, 'active' },
            params,
            'Complex query parameters should be correctly bound'
        )
    end,

    -- Test insert query building
    function()
        local query, params = DB:table('users')
            :buildInsertQuery({
                group = 'admin',
                identifier = 'steam:12345'
            })

        return assertEquals(
            'INSERT INTO `users` (`group`, `identifier`) VALUES (?, ?)',
            query,
            'Insert query should be correctly formed'
        ) and assertTableEquals(
            { 'admin', 'steam:12345' },
            params,
            'Insert parameters should be correctly bound'
        )
    end,

    -- Test update query building
    function()
        local query, params = DB:table('users')
            :where('identifier', 'steam:12345')
            :buildUpdateQuery({
                group = 'moderator',
                identifier = 'steam:123456'
            })

        return assertEquals(
            'UPDATE `users` SET `group` = ?, `identifier` = ? WHERE `identifier` = ?',
            query,
            'Update query should be correctly formed'
        ) and assertTableEquals(
            { 'moderator', 'steam:123456', 'steam:12345' },
            params,
            'Update parameters should be correctly bound'
        )
    end,

    -- Test delete query building
    function()
        local query, params = DB:table('users')
            :where('identifier', 'steam:12345')
            :buildDeleteQuery()

        return assertEquals(
            'DELETE FROM `users` WHERE `identifier` = ?',
            query,
            'Delete query should be correctly formed'
        ) and assertTableEquals(
            { 'steam:12345' },
            params,
            'Delete parameters should be correctly bound'
        )
    end,

    -- Test where raw
    function()
        local query, params = DB:table('users')
            :whereRaw('age > ? AND status = ?', 18, 'active')
            :buildQuery()

        return assertEquals(
            'SELECT * FROM `users` WHERE age > ? AND status = ?',
            query,
            'Where raw clause should be correctly formed'
        ) and assertTableEquals(
            { 18, 'active' },
            params,
            'Where raw parameters should be correctly bound'
        )
    end,
}

CreateThread(function()
    print('Running QueryBuilder tests...\n')
    local totalTests = #tests
    local passedTests = 0

    for _, test in ipairs(tests) do
        if test() then
            passedTests = passedTests + 1
        end

        print('')
    end

    print(('\nTest summary: %d/%d tests passed'):format(passedTests, totalTests))

    if passedTests == totalTests then
        print('🎉 All tests passed!')
    else
        print('❌ Some tests failed!')
    end
end)
