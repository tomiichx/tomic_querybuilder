# FiveM QueryBuilder

A Laravel-inspired QueryBuilder for FiveM, built on top of ox_lib and oxmysql.

## Dependencies

- ox_lib
- oxmysql

## Installation

- Under construction, please DO NOT use this yet. 🚧

## Usage Examples

Here are some basic examples of how to use the query builder:

### Complex Select Query

```lua
-- Retrieve a list of users filtered by group, grouped by identifier, ordered by lastname, and limited to 10 results
local users = DB:table("users")
    :select("identifier", "firstname", "lastname")
    :where("group", "LIKE", "%admin")
    :groupBy("identifier")
    :orderBy("lastname", "ASC")
    :limit(10)
    :get()
```

### Basic Paginated Select Query

```lua
-- Get paginated results by specifying perPage and currentPage
local entriesPerPage = 10
local currentPage = 1

local obj = DB:table("users")
    :select("firstname", "lastname")
    :paginate(entriesPerPage, currentPage)

print(("Returned %d out of %d"):format(entriesPerPage, obj.totalCount))
```

### Basic Count Query

```lua
-- Count the number of users active in the last hour
local count = DB:table("users")
    :where("last_seen", ">", os.time() - 3600)
    :count()

print(("Count: %d"):format(count))
```

### Basic Insert Query

```lua
-- Insert a new user record
local insertId = DB:table("users"):insert({
    identifier = "char1:12345",
    firstname = "John",
    lastname = "Doe",
    accounts = { bank = 100, cash = 0, black_money = 0 }, -- Automatically parsed as JSON string
    group = "admin"
})
```

### Basic Update Query

```lua
-- Update user group
local affectedRows = DB:table("users")
    :where("identifier", "char1:12345")
    :update({
        group = "moderator"
    })
```

### Basic Delete Query

```lua
-- Delete user by identifier
local affectedRows = DB:table("users")
    :where("identifier", "char1:12345")
    :delete()
```
