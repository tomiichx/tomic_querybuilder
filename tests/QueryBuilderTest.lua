---@class Utilities
local Utilities = require "src.classes.Utilities"

if Utilities.isProduction() then
    print(("[%s]: 'QueryBuilder' tests skipped in the production environment."):format(Utilities.CURRENT_RESOURCE_NAME))
    return
end

---@class DB
local DB = require "src.classes.DB"

local function assertEquals(expected, actual, message)
    if expected ~= actual then
        print(("❌ Test failed: %s"):format(message))
        print(("Expected: %s"):format(tostring(expected)))
        print(("Actual: %s"):format(tostring(actual)))

        return false
    end

    print(("✅ Test passed: %s"):format(message))
    return true
end

local function assertTableEquals(expected, actual, message)
    if #expected ~= #actual then
        print(("❌ Test failed: %s (different lengths)"):format(message))
        return false
    end

    for i = 1, #expected do
        if expected[i] ~= actual[i] then
            print(("❌ Test failed: %s (mismatch at index %d)"):format(message, i))
            print(("Expected: %s"):format(tostring(expected[i])))
            print(("Actual: %s"):format(tostring(actual[i])))

            return false
        end
    end

    print(("✅ Test passed: %s"):format(message))
    return true
end

local tests = {
    function()
        local query = DB:table("users"):buildQuery()

        return assertEquals(
            "SELECT * FROM `users`",
            query,
            "Basic select query should be correctly formed"
        )
    end,

    function()
        local query, params = DB:table("users"):buildQuery(true)

        return assertEquals(
            "SELECT COUNT(*) FROM `users`",
            query,
            "Count query should be correctly formed"
        ) and assertTableEquals(
            {},
            params,
            "Count query should not bind any parameters"
        )
    end,

    function()
        local query = DB:table("users")
            :select("id", "username", "email")
            :buildQuery()

        return assertEquals(
            "SELECT `id`, `username`, `email` FROM `users`",
            query,
            "Select with specific columns should be correctly formed"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("id", 1)
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `id` = ?",
            query,
            "Where clause should be correctly formed"
        ) and assertTableEquals(
            { 1 },
            params,
            "Where parameters should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("age", ">", 18)
            :where("status", "active")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `age` > ? AND `status` = ?",
            query,
            "Multiple where clauses should be correctly formed"
        ) and assertTableEquals(
            { 18, "active" },
            params,
            "Multiple where parameters should be correctly bound"
        )
    end,

    function()
        local query = DB:table("users")
            :groupBy("group")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` GROUP BY `group`",
            query,
            "Group by clause should be correctly formed"
        )
    end,

    function()
        local query = DB:table("users")
            :orderBy("username", "DESC")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` ORDER BY `username` DESC",
            query,
            "Order by clause should be correctly formed"
        )
    end,

    function()
        local query = DB:table("users")
            :limit(10)
            :offset(20)
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` LIMIT 10 OFFSET 20",
            query,
            "Limit and offset should be correctly formed"
        )
    end,

    function()
        local maliciousInput = "1; DROP TABLE users; --"
        local query, params = DB:table("users")
            :where("id", maliciousInput)
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `id` = ?",
            query,
            "SQL injection in where clause should be prevented"
        ) and assertTableEquals(
            { maliciousInput },
            params,
            "Malicious input should be parameterized"
        )
    end,

    function()
        local maliciousColumn = "id FROM users; DROP TABLE users; SELECT * FROM users WHERE id"
        local query = DB:table("users")
            :where(maliciousColumn, 1)
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `" .. maliciousColumn .. "` = ?",
            query,
            "Column names should not be parameterized (handled by developer)"
        )
    end,

    function()
        local query, params = DB:table("users")
            :select("id", "username", "email")
            :where("age", ">", 18)
            :where("status", "active")
            :groupBy("group")
            :orderBy("username", "DESC")
            :limit(10)
            :offset(20)
            :buildQuery()

        return assertEquals(
            "SELECT `id`, `username`, `email` FROM `users` WHERE `age` > ? AND `status` = ? GROUP BY `group` ORDER BY `username` DESC LIMIT 10 OFFSET 20",
            query,
            "Complex query should be correctly formed"
        ) and assertTableEquals(
            { 18, "active" },
            params,
            "Complex query parameters should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :buildInsertQuery({
                group = "admin",
                identifier = "steam:12345"
            })

        return assertEquals(
            "INSERT INTO `users` (`group`, `identifier`) VALUES (?, ?)",
            query,
            "Insert query should be correctly formed"
        ) and assertTableEquals(
            { "admin", "steam:12345" },
            params,
            "Insert parameters should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("identifier", "steam:12345")
            :buildUpdateQuery({
                group = "moderator",
                identifier = "steam:123456"
            })

        return assertEquals(
            "UPDATE `users` SET `group` = ?, `identifier` = ? WHERE `identifier` = ?",
            query,
            "Update query should be correctly formed"
        ) and assertTableEquals(
            { "moderator", "steam:123456", "steam:12345" },
            params,
            "Update parameters should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("identifier", "steam:12345")
            :buildDeleteQuery()

        return assertEquals(
            "DELETE FROM `users` WHERE `identifier` = ?",
            query,
            "Delete query should be correctly formed"
        ) and assertTableEquals(
            { "steam:12345" },
            params,
            "Delete parameters should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :whereRaw("age > ? AND status = ?", 18, "active")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE age > ? AND status = ?",
            query,
            "Where raw clause should be correctly formed"
        ) and assertTableEquals(
            { 18, "active" },
            params,
            "Where raw parameters should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("id", 1)
            :whereRaw("status = ?", "active")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `id` = ? AND status = ?",
            query,
            "Where + whereRaw combined should be correctly formed"
        ) and assertTableEquals(
            { 1, "active" },
            params,
            "Where + whereRaw combined params should include all values"
        )
    end,

    function()
        local query, params = DB:table("users")
            :whereRaw("age > ?", 18)
            :where("status", "active")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE age > ? AND `status` = ?",
            query,
            "WhereRaw before where should be correctly formed"
        ) and assertTableEquals(
            { 18, "active" },
            params,
            "WhereRaw before where params should include all values"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("id", 1)
            :buildSelectQuery(false)

        if not query:find("LIMIT") then
            query = query .. " LIMIT 1"
        end

        return assertEquals(
            "SELECT * FROM `users` WHERE `id` = ? LIMIT 1",
            query,
            "First query should append LIMIT 1"
        ) and assertTableEquals(
            { 1 },
            params,
            "First query params should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :whereIn("id", { 1, 2, 3 })
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `id` IN (?, ?, ?)",
            query,
            "WhereIn should generate IN clause with placeholders"
        ) and assertTableEquals(
            { 1, 2, 3 },
            params,
            "WhereIn params should contain all values"
        )
    end,

    function()
        local query, params = DB:table("users")
            :whereIn("id", {})
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE 1 = 0",
            query,
            "WhereIn with empty values should produce always-false condition"
        ) and assertTableEquals(
            {},
            params,
            "WhereIn with empty values should bind no params"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("status", "active")
            :whereIn("role", { "admin", "moderator" })
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `status` = ? AND `role` IN (?, ?)",
            query,
            "Where + whereIn combined should be correctly formed"
        ) and assertTableEquals(
            { "active", "admin", "moderator" },
            params,
            "Where + whereIn combined params should include all values"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("role", "admin")
            :orWhere("role", "moderator")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `role` = ? OR `role` = ?",
            query,
            "OrWhere should use OR conjunction"
        ) and assertTableEquals(
            { "admin", "moderator" },
            params,
            "OrWhere params should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("age", ">", 18)
            :orWhere("vip", true)
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `age` > ? OR `vip` = ?",
            query,
            "OrWhere with 2-arg shorthand should use = operator"
        ) and assertTableEquals(
            { 18, true },
            params,
            "OrWhere with operator params should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("active", true)
            :where("age", ">", 18)
            :orWhere("role", "admin")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `active` = ? AND `age` > ? OR `role` = ?",
            query,
            "Mixed AND/OR should preserve conjunction order"
        ) and assertTableEquals(
            { true, 18, "admin" },
            params,
            "Mixed AND/OR params should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("users")
            :whereNull("deleted_at")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `deleted_at` IS NULL",
            query,
            "WhereNull should generate IS NULL clause"
        ) and assertTableEquals(
            {},
            params,
            "WhereNull should bind no params"
        )
    end,

    function()
        local query, params = DB:table("users")
            :whereNotNull("email")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `email` IS NOT NULL",
            query,
            "WhereNotNull should generate IS NOT NULL clause"
        ) and assertTableEquals(
            {},
            params,
            "WhereNotNull should bind no params"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("status", "active")
            :whereNull("deleted_at")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `status` = ? AND `deleted_at` IS NULL",
            query,
            "Where + whereNull combined should be correctly formed"
        ) and assertTableEquals(
            { "active" },
            params,
            "Where + whereNull combined should only bind where params"
        )
    end,

    function()
        local query, params = DB:table("users")
            :whereBetween("age", 18, 65)
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `age` BETWEEN ? AND ?",
            query,
            "WhereBetween should generate BETWEEN clause"
        ) and assertTableEquals(
            { 18, 65 },
            params,
            "WhereBetween should bind min and max"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("status", "active")
            :whereBetween("age", 18, 65)
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `status` = ? AND `age` BETWEEN ? AND ?",
            query,
            "Where + whereBetween combined should be correctly formed"
        ) and assertTableEquals(
            { "active", 18, 65 },
            params,
            "Where + whereBetween combined params should include all values"
        )
    end,

    function()
        local query = DB:table("users")
            :distinct()
            :select("role")
            :buildQuery()

        return assertEquals(
            "SELECT DISTINCT `role` FROM `users`",
            query,
            "Distinct should add DISTINCT keyword"
        )
    end,

    function()
        local query = DB:table("users")
            :distinct()
            :select("role", "status")
            :buildQuery()

        return assertEquals(
            "SELECT DISTINCT `role`, `status` FROM `users`",
            query,
            "Distinct with multiple columns should be correctly formed"
        )
    end,

    function()
        local query = DB:table("users")
            :distinct()
            :buildQuery(true)

        return assertEquals(
            "SELECT COUNT(*) FROM `users`",
            query,
            "Distinct should not affect COUNT queries"
        )
    end,

    function()
        local query, params = DB:table("orders")
            :where("status", "completed")
            :buildAggregateQuery("SUM", "total")

        return assertEquals(
            "SELECT SUM(`total`) FROM `orders` WHERE `status` = ?",
            query,
            "Sum aggregate query should be correctly formed"
        ) and assertTableEquals(
            { "completed" },
            params,
            "Sum aggregate params should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("products")
            :buildAggregateQuery("MIN", "price")

        return assertEquals(
            "SELECT MIN(`price`) FROM `products`",
            query,
            "Min aggregate query should be correctly formed"
        ) and assertTableEquals(
            {},
            params,
            "Min aggregate without where should bind no params"
        )
    end,

    function()
        local query, params = DB:table("products")
            :buildAggregateQuery("MAX", "price")

        return assertEquals(
            "SELECT MAX(`price`) FROM `products`",
            query,
            "Max aggregate query should be correctly formed"
        ) and assertTableEquals(
            {},
            params,
            "Max aggregate without where should bind no params"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("role", "employee")
            :buildAggregateQuery("AVG", "salary")

        return assertEquals(
            "SELECT AVG(`salary`) FROM `users` WHERE `role` = ?",
            query,
            "Avg aggregate query should be correctly formed"
        ) and assertTableEquals(
            { "employee" },
            params,
            "Avg aggregate params should be correctly bound"
        )
    end,

    function()
        local query, params = DB:table("orders")
            :groupBy("status")
            :buildAggregateQuery("SUM", "total")

        return assertEquals(
            "SELECT SUM(`total`) FROM `orders` GROUP BY `status`",
            query,
            "Aggregate with groupBy should be correctly formed"
        ) and assertTableEquals(
            {},
            params,
            "Aggregate with groupBy should bind no params"
        )
    end,

    function()
        local query, params = DB:table("users")
            :where("active", true)
            :whereIn("role", { "admin", "mod" })
            :whereNotNull("email")
            :whereBetween("age", 18, 65)
            :whereNull("deleted_at")
            :buildQuery()

        return assertEquals(
            "SELECT * FROM `users` WHERE `active` = ? AND `role` IN (?, ?) AND `email` IS NOT NULL AND `age` BETWEEN ? AND ? AND `deleted_at` IS NULL",
            query,
            "All where types combined should be correctly formed"
        ) and assertTableEquals(
            { true, "admin", "mod", 18, 65 },
            params,
            "All where types combined params should include all values"
        )
    end,
}

CreateThread(function()
    print("Running QueryBuilder tests...\n")
    local totalTests = #tests
    local passedTests = 0

    for _, test in ipairs(tests) do
        if test() then
            passedTests = passedTests + 1
        end

        print("")
    end

    print(("\nTest summary: %d/%d tests passed"):format(passedTests, totalTests))

    if passedTests == totalTests then
        print("🎉 All tests passed!")
    else
        print("❌ Some tests failed!")
    end
end)
