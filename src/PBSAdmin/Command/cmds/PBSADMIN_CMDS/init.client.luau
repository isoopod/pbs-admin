--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Modules
local _, Iris = pcall(require, ReplicatedStorage.Utils.Iris)

local get: RemoteFunction = ReplicatedStorage:WaitForChild("PBSAdminGetAutofill")
local commands = get:InvokeServer(true)

pcall(Iris.Init)
local windowVisible = Iris.State(true)
Iris:Connect(function()
	Iris.Window({"Commands"}, {isOpened = windowVisible})
		for i,v in commands do
			Iris.Tree({i})
				Iris.SameLine()
					for _,t in v[1] do
						local s = t
						if typeof(t) == "table" then
							s = "{"
							for _,v in t do
								s = `{s}'{v}', `
							end
							s = `{s}}`
						end
						Iris.Text({`{s}`, true, nil, true})
					end
				Iris.End()
				Iris.Text({v[2], true, nil, true})
			Iris.End()
		end
	Iris.End()
end)

script:GetAttributeChangedSignal("upd"):Connect(function()
	windowVisible:set(true)
end)