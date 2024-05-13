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

## Command Structure
A command is a module script that is a child to PBSAdmin/Command. The modules name is the commands primary alias. On top of having a primary alias, there is a table of strings within the config of a command where you can add additional aliases to the command. You do not need to put the command's primary alias into the alias table. Make sure that no primary or secondary aliases are the same in any command, as this will cause an overlap and only one will be registered.

Commands have a minRank key in their configuration. This determines the minimum rank needed for a command. This is a number, correlating to one of the ranks within the permissions module. You can find the translations for these numbers in permissions module, however the most useful ones will be `1` for member and `2` for admin. If you have the PBSAdmin_Local gui inside member instead of none then unranked players will not be able to use any commands even if the minRank is set to `0` (unless of course they use exploits to fire the remote themselves) so for this reason the console is given to everyone by default.

Commands have a syntax table which is used for the text prediction system. In this table, members can be a string, or a table of strings. Strings that are not `"any"` will be displayed in the console when writing that argument and will stay as long as the user does not input a character not in that. This does not use rich text formatting so you can use `<` and `>` as expected. A table of strings will match the nearest one while typing the argument. In future more special cases like `<player>` may be reserved to generate a list of each player but for now it will just display as normal.

A command's configuration also has a help string. This is a block string which needs to be rich text compatible. see [here](https://create.roblox.com/docs/ui/rich-text#escape-forms) for all escape forms in rich text. You do not need to use `\n` to mark a new line in a block string, just move to a new line in the string to start a new line. It is recommended to test your help string before uploading your command, as it can go offscreen.

The config table should also include a __call metamethod. This is a function that gets fired when the command is triggered, and will fire with the arguments:

`self` `player` `verified` `...`

`Self` is the command itself and should use the Command type from the Command Class. `Player` is the Player Instance who fired the command. `Verified` is a boolean determing if the command has been verified using the command caching and confirmation system. `...` is any additional arguments passed, which are all strings and come from the console. Anything input from the console is split by whitespace and this is everything except the command itself. For example, `role false me owner` when executed, would result as `...` being "false", "me", "owner". 

__call needs to return two values. A response code which can be got from the Responses Enum from the Command Class. Success indicates a successful execution of the command and colors the output white. Error indicates something went wrong with the command and colors the output red. Verify indicates the command should be checked to confirm the action, will color the output blue, and stores that command in the cached command table. With a cached command, if the very next command is just `Y` then the command will be fired again with the exact same inputs as the first time, but verified will be set to `true`. The second return is a string representing the result of the command. This should tell the user what happened with the command, use string interpolation to pass variables and such into the result. It's recommended to include `Y/N` at the end of a verify result. 

When creating a command it is easiest to copy an existing command as a template.

## Handling Command Execution.
The Command Class provides a series of utilities to make verifying a command easy while also allowing a lot of room with what happens when a command is called. 

`self:UserHasPermissionsForCommand(player: Player): boolean`

Returns true if the `player`'s rank is high enough to use the command. Based of the minRank value of the command.

`self:GetPlayer(player: Player, name: string, useUserId: string?): Player? | offlinePlayer?`

Gets a player based on a player input string. `player` should be the player who called the command, this is needed for using `me` as an input to return yourself. `name` can be an approximate name of a player in the server when `useUserId` is `"false"`, and an exact ROBLOX UserId when `useUserId` is `"true"`. `useUserId` is case insensitive. When `useUserId` is true, if a result is found, it will be an `offlinePlayer`, which is used internally for managing permissions, but can be used for other things. The only relevant information in an offlinePlayer is `name` as a string and `userId` as a number. If you are dealing with a situation where you may have a offlinePlayer or a Player, you can differentiate them by using ClassName. You can also use FindFirstChild or index a character, if either are false when they shouldn't be then you are dealing with an offlinePlayer. The most efficient method is to use ClassName however. 

`self:CanUserModifyOther(player: Player, other: Player): boolean`

Returns true if `player` can modify `other`. This is determined by if `player` is a higher rank than `other`, or if the user has the rank `owner` then this will always return true.

`self:IsUserVerified(player: Player, other: Player): boolean`

Returns true in the following cases: the `isVerified_Only` attribute is set to false, `player` is an `owner`, `other` has verified their roblox account with a Phone Number or Government ID.

You should not be making a command that uses `self:GiveToolsForRole`  