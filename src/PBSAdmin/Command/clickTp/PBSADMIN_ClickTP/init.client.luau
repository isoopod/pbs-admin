local player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local mouse = player:GetMouse()

local character = player.Character or player.CharacterAdded:Wait()
local humaniod: Humanoid = character:WaitForChild("Humanoid")

local prevState = humaniod:GetStateEnabled(Enum.HumanoidStateType.Seated)
humaniod.Sit = false
humaniod:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
task.wait(0.1)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean): ()
	if not processed then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if character then
				local rotation = character:GetPivot()
				local rX, rY, rZ = rotation:ToEulerAnglesXYZ()

				character:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, character:GetExtentsSize().Y / 2, 0)) * CFrame.Angles(rX, rY, rZ))
			end
		end
	end
end)

script.Destroying:Wait()
if humaniod and humaniod.Parent then humaniod:SetStateEnabled(Enum.HumanoidStateType.Seated, prevState) end
