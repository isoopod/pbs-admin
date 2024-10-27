--[=[
    @class ClientCommand
    A client command is a ModuleScript under the ClientCommands Module in the PBSAdmin_Local gui.   
    The Module should require this module and intialize by calling cmd.register()
    ```lua
    local cmd = require(script.Parent)

    cmd.register({"test"}, {}, function()
        print("Hello World!") 
    end)

    -- Module should just return nil
    return nil
    ```
    The module should return nil 
    These are for commands that dont require access to the server for validation, so they do not have a way of limiting to a specific rank.   
]=]

local api = {}

api.Responses = {
	Error = 1,
	Success = 2,
	Verify = 3, --Y/N to verify the command
	Minimize = 4, --Greyed out response
	Warning = 5,
}

api.cmdData = {}

--- @function register
--- @within ClientCommand
--- @param names {string} -- Functions like aliases for regular commands, except is just an array of strings (no alias data), and the Module's name is not automatically registered.
--- @param syntax {string | {string}} -- Identical to syntax in regular command handlers
--- @param __call (...string) -> () -- The function called when the command is executed, with all extra parameters
--- Registers a Client Command
function api.register(names: { string }, syntax: { string | { string } }, __call: (...string) -> (number, string)): ()
	for _, v in names do
		api.cmdData[v] = setmetatable({ syntax = syntax }, { __call = __call })
	end
end

return api :: {
	Responses: { Error: number, Success: number, Verify: number, Minimize: number, Warning: number },
	cmdData: { [string]: { syntax: { string | { string } } } & (...string) -> (number, string) },

	register: (names: { string }, syntax: { string | { string } }, __call: (...string) -> (number, string)) -> (),
}
