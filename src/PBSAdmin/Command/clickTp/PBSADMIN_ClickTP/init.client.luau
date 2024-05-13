local player = game:GetService("Players").LocalPlayer
local contextActionService = game:GetService("ContextActionService")
local mouse = player:GetMouse()

local character = player.Character

function handleInput(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		if character then
			local rotation = character:GetPivot()
			local rX,rY,rZ = rotation:ToEulerAnglesXYZ()
	
			character:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0,character:GetExtentsSize().Y/2,0)) * CFrame.Angles(rX, rY, rZ))
		end
	end
	return Enum.ContextActionResult.Pass
end

contextActionService:BindAction("PBSADMIN_CLICK_TP", handleInput, false, Enum.UserInputType.MouseButton1)

script.Destroying:Connect(function()
	contextActionService:UnbindAction("PBSADMIN_CLICK_TP")
end)