-- Client commands can just be used as a module loader for clientside portions of commands.
-- There is nothing that enforces a module under here to register a command.

local AdminGui = require(script.Parent.Parent.AdminGui)
local Utils = require(script.Parent.Parent.Utils)

-- bytenet integration
local Bytenet = Utils.Bytenet

Bytenet.HINT.listen(function(data)
	-- This data comes from the server and should already be filtered
	AdminGui.hint(data.message, data.duration)
end)
