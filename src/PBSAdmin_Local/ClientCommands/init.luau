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
--- @param help string -- Extra instructions for how to use the command
--- @param __call (...string) -> () -- The function called when the command is executed, with all extra parameters
--- Registers a Client Command
function api.register(names: { string }, syntax: { string | { string } }, help: string, __call: (...string) -> (number, string)): ()
	assert(type(names) == "table", "Names must be a table of strings")
	assert(type(syntax) == "table", "Syntax must be a table of strings or tables of strings")
	assert(type(help) == "string", "Help must be a string")
	assert(type(__call) == "function", "__call must be a function")
	for _, v in names do
		api.cmdData[v] = setmetatable({ syntax = syntax, help = help }, { __call = __call })
	end
end

return api :: {
	Responses: { Error: number, Success: number, Verify: number, Minimize: number, Warning: number },
	cmdData: { [string]: { syntax: { string | { string } }, help: string } & (...string) -> (number, string) },

	register: (names: { string }, syntax: { string | { string } }, help: string, __call: (...string) -> (number, string)) -> (),
}
