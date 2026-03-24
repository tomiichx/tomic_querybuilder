# FiveM QueryBuilder

A Laravel-inspired QueryBuilder for FiveM, built on top of ox_lib and oxmysql.

## Dependencies

- ox_lib
- oxmysql

## Credits

Built on [oxmysql](https://github.com/overextended/oxmysql) and [ox_lib](https://github.com/overextended/ox_lib).
Thanks to the **Overextended** team for their work on the FiveM ecosystem.

## Installation

Under construction - not ready for production use yet.

## Usage

### Select

```lua
local users = DB:table("users")
    :select("identifier", "firstname", "lastname")
    :where("group", "LIKE", "%admin")
    :groupBy("identifier")
    :orderBy("lastname", "ASC")
    :limit(10)
    :get()
```

### First (single row)

```lua
local user = DB:table("users")
    :where("identifier", "char1:12345")
    :first()
```

Returns a single row or `nil`. Uses `MySQL.single.await` under the hood.

### Distinct

```lua
local roles = DB:table("users")
    :distinct()
    :select("role")
    :get()
```

### Where clauses

```lua
-- Basic
DB:table("users"):where("id", 1)
DB:table("users"):where("age", ">", 18)

-- OR
DB:table("users")
    :where("role", "admin")
    :orWhere("role", "moderator")

-- IN
DB:table("users"):whereIn("id", { 1, 2, 3 })

-- NULL checks
DB:table("users"):whereNull("deleted_at")
DB:table("users"):whereNotNull("email")

-- BETWEEN
DB:table("users"):whereBetween("age", 18, 65)

-- Raw
DB:table("users"):whereRaw("age > ? AND status = ?", 18, "active")
```

All where methods can be chained together:

```lua
local users = DB:table("users")
    :where("active", true)
    :whereIn("role", { "admin", "mod" })
    :whereNotNull("email")
    :whereBetween("age", 18, 65)
    :whereNull("deleted_at")
    :get()
```

### Pagination

```lua
local page = DB:table("users")
    :select("firstname", "lastname")
    :paginate(10, 1)

print(("Returned %d out of %d"):format(#page.data, page.totalCount))
```

Returns `{ data, totalCount, perPage, currentPage, lastPage }`.

### Aggregates

```lua
local count = DB:table("users"):count()
local total = DB:table("orders"):where("status", "completed"):sum("total")
local lowest = DB:table("products"):min("price")
local highest = DB:table("products"):max("price")
local average = DB:table("users"):avg("salary")
```

### Insert

```lua
local insertID = DB:table("users"):insert({
    identifier = "char1:12345",
    firstname = "John",
    lastname = "Doe",
    accounts = { bank = 100, cash = 0 },
    group = "admin"
})
```

Table values are automatically encoded as JSON.

### Update

```lua
local affectedRows = DB:table("users")
    :where("identifier", "char1:12345")
    :update({ group = "moderator" })
```

### Delete

```lua
local affectedRows = DB:table("users")
    :where("identifier", "char1:12345")
    :delete()
```
