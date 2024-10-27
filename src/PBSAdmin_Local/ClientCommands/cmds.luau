local AdminGui = require(script.Parent.Parent.AdminGui)
local autofill = require(script.Parent.Parent.Autofill)
local cmd = require(script.Parent)

cmd.register({ "cmds", "commands" }, {}, function()
	if not script.Parent.Parent:FindFirstChild("PBSAdmin_CMDS") then
		local scr, cmf, ent, num = AdminGui.ScrollGui()
		scr.Name = "PBSAdmin_CMDS"

		local cmds = {}
		for i in autofill.autofill do
			if i ~= "Y" and i ~= "N" then
				table.insert(cmds, i)
			end
		end
		table.sort(cmds)

		for _, v in cmds do
			num += 1
			local cl = ent:Clone()

			-- formats the syntax table as a readable string
			local syntax = table.concat(
				(function()
					local formatted = {}
					for _, s in autofill.autofill[v] do
						table.insert(formatted, typeof(s) == "table" and `\{{table.concat(s, ", ")}\}` or `\{{s}\}`)
					end
					return formatted
				end)(),
				" "
			)
			cl.Text = `{num} {v} {syntax}`
			cl.Position = UDim2.fromOffset(0, num * 20)
			cl.Parent = cmf
		end

		scr.Parent = script.Parent.Parent
	end
	return cmd.Responses.Success, "Opened commands menu"
end)

return nil
