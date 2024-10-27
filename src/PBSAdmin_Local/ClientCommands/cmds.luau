local AdminGui = require(script.Parent.Parent.AdminGui)
local autofill = require(script.Parent.Parent.Autofill)
local cmd = require(script.Parent)

cmd.register({ "cmds", "commands" }, {}, function()
	if not script.Parent.Parent:FindFirstChild("PBSAdmin_LIST_Commands") then
		local scr, cmf, ent = AdminGui.ScrollGui("Commands")
		local num = 1

		local commands = autofill.getVerboseAutofill()

		local cmds = {}
		for k in commands do
			table.insert(cmds, k)
		end
		table.sort(cmds)

		for _, k in cmds do
			local cl = ent:Clone()

			-- formats the syntax table as a readable string
			local syntax = table.concat(
				(function()
					local formatted = {}
					for _, s in commands[k].syntax do
						table.insert(formatted, typeof(s) == "table" and `\{{table.concat(s, ", ")}\}` or `\{{s}\}`)
					end
					return formatted
				end)(),
				" "
			)

			cl.Index.Text = tostring(num)
			cl.Content.Entry.Text = `{k} {syntax}`
			cl.Name = k
			cl.LayoutOrder = num
			cl.Parent = cmf

			-- TODO: expandable help section

			num += 1
		end

		scr.Parent = script.Parent.Parent
	end
	return cmd.Responses.Success, "Opened commands menu"
end)

return nil
