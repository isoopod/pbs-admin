local players = game:GetService("Players")
local contextActionService = game:GetService("ContextActionService")
local me = players.LocalPlayer

local camera = workspace.CurrentCamera

local character = me.Character

function handleInput(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		script:Destroy()
	end
	return Enum.ContextActionResult.Pass
end

contextActionService:BindAction("PBSADMIN_SPECTATE", handleInput, false, Enum.KeyCode.Backspace)

local other
for _,v in players:GetPlayers() do
	if v.Name == script:GetAttribute("Target") then
		other = v
		break
	end
end

if other and other.Character and other.Character.Humanoid then
	camera.CameraSubject = other.Character.Humanoid
end

script.Destroying:Connect(function()
	contextActionService:UnbindAction("PBSADMIN_SPECTATE")
	camera.CameraSubject = character.Humanoid
end)