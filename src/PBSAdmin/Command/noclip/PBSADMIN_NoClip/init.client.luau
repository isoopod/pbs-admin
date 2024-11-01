local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local KeyCode = Enum.KeyCode.Space

local Character = script.Parent
local Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")

local linearVelocity = Instance.new("LinearVelocity")
linearVelocity.ForceLimitsEnabled = false
linearVelocity.Parent = script
local alignOrientation = Instance.new("AlignOrientation")
alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
alignOrientation.Parent = script

linearVelocity.Attachment0 = Humanoid.RootPart.RootAttachment
alignOrientation.Attachment0 = linearVelocity.Attachment0

local Camera = game.Workspace.Camera
local function getMoveDirection()
	-- If we aren't trying to move dont move us
	local MoveDirection = Humanoid.MoveDirection
	if UIS:IsKeyDown(Enum.KeyCode.Space) then
		MoveDirection += Vector3.yAxis
	end
	if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		MoveDirection -= Vector3.yAxis
	end
	-- Normalizing a zero vector results in not a number
	if MoveDirection == Vector3.zero then return Vector3.zero end

	MoveDirection = MoveDirection.Unit

	local dir = (Camera.CFrame * CFrame.new(
		(CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Vector3.new(Camera.CFrame.lookVector.X, 0, Camera.CFrame.lookVector.Z)):VectorToObjectSpace(MoveDirection))
	)).Position - Camera.CFrame.Position
	-- Normalizing a zero vector results in not a number
	if dir == Vector3.zero then return dir end
	return dir.Unit
end

local function updateFly()
	Humanoid.PlatformStand = true
	alignOrientation.CFrame = game.Workspace.Camera.CFrame
	-- This is infact fine since after the tween completes, there is no reference to it so it will automatically get gc'd
	TweenService:Create(linearVelocity, TweenInfo.new(0.3), { VectorVelocity = getMoveDirection() * 3 * Humanoid.WalkSpeed }):Play()
end

local originalCollisionGroup: { [BasePart]: string } = {}

local function noclip(enabled: boolean)
	if enabled then
		for _, v in Character:GetDescendants() do
			if v:IsA("BasePart") then
				originalCollisionGroup[v] = v.CollisionGroup
				v.CollisionGroup = "PlayerNoclip"
			end
		end
	else
		for i, v in originalCollisionGroup do
			i.CollisionGroup = v
		end
	end
end

runService:BindToRenderStep("PBSADMIN_NOCLIP", Enum.RenderPriority.Input.Value + 1, updateFly)
if Humanoid.RootPart and Humanoid.RootPart:FindFirstChild("Running") then Humanoid.RootPart.Running.Volume = 0 end

noclip(true)

local Flying = true

local lastInputTime = 0 -- to toggle flight you have to double press the key
local maxInputDelta = 0.25 -- max time in seconds between pressing the key again to toggle flight

UIS.InputBegan:Connect(function(key, gameProcessed)
	if gameProcessed then return end
	if key.KeyCode == KeyCode then
		if os.clock() - lastInputTime <= maxInputDelta then
			if Flying == false then
				Flying = true
				if Humanoid.RootPart then
					Humanoid.PlatformStand = true

					if Humanoid.RootPart:FindFirstChild("Running") then Humanoid.RootPart.Running.Volume = 0 end

					linearVelocity.Attachment0 = Humanoid.RootPart.RootAttachment
					alignOrientation.Attachment0 = linearVelocity.Attachment0

					runService:BindToRenderStep("PBSADMIN_NOCLIP", Enum.RenderPriority.Input.Value + 1, updateFly)
					noclip(true)
				end
			else
				Flying = false
				noclip(false)
				runService:UnbindFromRenderStep("PBSADMIN_NOCLIP")

				Humanoid.PlatformStand = false

				if Humanoid.RootPart:FindFirstChild("Running") then Humanoid.RootPart.Running.Volume = 0.65 end

				linearVelocity.Attachment0 = nil
				alignOrientation.Attachment0 = nil
			end
		end
		lastInputTime = os.clock()
	end
end)

-- does not fire when destroying through the explorer FYI as that just parents to nil
script.Destroying:Wait()
runService:UnbindFromRenderStep("PBSADMIN_NOCLIP")
if Humanoid then
	Humanoid.PlatformStand = false
	if Humanoid.RootPart and Humanoid.RootPart:FindFirstChild("Running") then Humanoid.RootPart.Running.Volume = 0.65 end
	noclip(false)
end
