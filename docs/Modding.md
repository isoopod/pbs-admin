# Integration
A big part of PBS Admin is its ability to integrate its permissions system into other components of a PBS

if you would like get a users permissions outside of the PBS Admin script, it is fairly simple.

To get the permissions module:
```lua
local ServerScriptService = game:GetService("ServerScriptService")
local Permissions = require(ServerScriptService.PBSAdmin.Permissions)
```
(This can only be used on the server obviously)

To get a users permissions:
```lua
local rank = Permissions.GetUserPermission(player.UserId)
```
rank will be a string which be one of the following:
- `banned` (this one will probably not show up as they will be immediatley kicked)
- `''` (an empty string)
- `member`
- `admin` 
- `owner`

It will likely be easier to work with these as numeric values and this can be done through the following:
```lua
local rankValue = permissions.roleValues[rank]
```

The numbers range from `-1` for `banned` to `3` for `owner` (order of increase is the same as the previous list of strings)

This is useful you want to implement checks that the user has a high enough rank to be able to do something. A good example would be making sure the user has permissions to place a block before actually placing the block, which will prevent them from exploiting to place blocks without first being set to member.

# Custom Commands
## Custom Commands License
You are free to create and distribute your own custom commands in the discord PBS Marketplace as long as your commands are not found to be harmful. You should not have to directly require the permissions module within your command, only the stock commands to edit permissions should be directly interfacing with the permissions module. The permissions system may be used through the utility methods within a command instance.