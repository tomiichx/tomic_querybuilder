# FiveM QueryBuilder

A Laravel-inspired QueryBuilder for FiveM, built on top of ox_lib and oxmysql.

## Dependencies

- ox_lib
- oxmysql

## Installation

1. Add this resource to your FiveM resources folder
2. Add `ensure tomic_querybuilder` to your server.cfg (after ox_lib and oxmysql)
3. In any resource that wants to use the QueryBuilder, add `@tomic_querybuilder/src/classes/DB.lua` to the `server_script(s)`

## Usage

In your resource's `fxmanifest.lua`:

```lua
server_script '@tomic_querybuilder/src/classes/DB.lua'
```
