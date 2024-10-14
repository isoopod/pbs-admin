local player = game:GetService("Players").LocalPlayer
local contextActionService = game:GetService("ContextActionService")
local mouse = player:GetMouse()

local character = player.Character or player.CharacterAdded:Wait()
local humaniod: Humanoid = character:WaitForChild("Humanoid")

local prevState = humaniod:GetStateEnabled(Enum.HumanoidStateType.Seated)
humaniod.Sit = false
humaniod:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

function handleInput(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		if character then
			local rotation = character:GetPivot()
			local rX, rY, rZ = rotation:ToEulerAnglesXYZ()

			character:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, character:GetExtentsSize().Y / 2, 0)) * CFrame.Angles(rX, rY, rZ))
		end
	end
	return Enum.ContextActionResult.Pass
end

contextActionService:BindAction("PBSADMIN_CLICK_TP", handleInput, false, Enum.UserInputType.MouseButton1)

script.Destroying:Connect(function()
	if humaniod and humaniod.Parent then humaniod:SetStateEnabled(Enum.HumanoidStateType.Seated, prevState) end
	contextActionService:UnbindAction("PBSADMIN_CLICK_TP")
end)
