local Input <const> = require 'src.classes.Input'

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

local tests = {
    function()
        local input = "normal string"
        local sanitized = Input:sanitize(input)

        return assertEquals(
            input,
            sanitized,
            'Normal string should remain unchanged'
        )
    end,

    function()
        local input = "Tomić'); DROP TABLE users; --"
        local sanitized = Input:sanitize(input)

        return assertEquals(
            "Tomić''); DROP TABLE users; --",
            sanitized,
            'SQL injection attempt should be escaped'
        )
    end,

    function()
        local input = {
            name = "Tomić'); DROP TABLE users; --",
            age = 25,
            email = "tomić@example.com"
        }
        local sanitized = Input:sanitizeTable(input)

        return assertEquals(
            "Tomić''); DROP TABLE users; --",
            sanitized.name,
            'SQL injection in table should be escaped'
        )
    end,

    function()
        local input = {
            user = {
                name = "Tomić'); DROP TABLE users; --",
                settings = {
                    theme = "dark'); --"
                }
            }
        }

        local sanitized = Input:sanitizeTable(input)

        return assertEquals(
            "dark''); --",
            sanitized.user.settings.theme,
            'Nested SQL injection should be escaped'
        )
    end
}

CreateThread(function()
    print('Running Input sanitization tests...\n')
    local totalTests = #tests
    local passedTests = 0

    for _, test in ipairs(tests) do
        if test() then
            passedTests += 1
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
