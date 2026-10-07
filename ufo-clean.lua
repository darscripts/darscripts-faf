
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldUI = playerGui:FindFirstChild("DARScriptsUI")

if oldUI then
	oldUI:Destroy()
end

local function runUFOTeleport()

	local character =
		player.Character
		or player.CharacterAdded:Wait()

	local UFOAnimations =
		require(
			ReplicatedStorage.Modules.UFOAnimations
		)

	local UFOHelper =
		require(
			ReplicatedStorage.Modules.UFOHelper
		)

	local Math =
		require(
			ReplicatedStorage.Modules.Math
		)

	local Notifications =
		require(
			ReplicatedStorage.Modules.GuiModels.Notifications
		)

	local persistent =
		UFOHelper.GetUFOPersistent()

	if not persistent then
		error("Could not find UFO persistent model.")
	end

	local position =
		persistent:GetPivot().Position

	local angle =
		math.rad(
			math.random(0, 360)
		)

	local x =
		math.cos(angle) * 11

	local z =
		math.sin(angle) * 11

	local primaryPart =
		persistent.PrimaryPart

	if not primaryPart then
		error("UFO persistent model has no PrimaryPart.")
	end

	local y =
		character:GetExtentsSize().Y / 2
		+ primaryPart.Size.Y / 2

	Math.SetModelCenterCFrame(
		character,

		CFrame.new(
			position
			+ Vector3.new(
				x,
				y,
				z
			)
		)
	)

	character:SetAttribute(
		"InsideUFO",
		true
	)

	player.CameraMaxZoomDistance = 25

	UserInputService.MouseBehavior =
		Enum.MouseBehavior.Default

	UserInputService.MouseIconEnabled =
		true

	UFOAnimations.StartAnimations()

	local responseList =
		Notifications.GetPromptResponseList(
			"Plasma"
		)

	if not responseList then
		warn(
			"DAR: Plasma response list wasn't found."
		)

		return
	end

	local yesButton =
		responseList:WaitForChild(
			"Option1"
		)

	local noButton =
		responseList:WaitForChild(
			"Option2"
		)

	yesButton.MouseButton1Down:Connect(
		function()

			if yesButton.Visible then

				Notifications.PromptButtonInput(
					1
				)

			end

		end
	)

	noButton.MouseButton1Down:Connect(
		function()

			if noButton.Visible then

				Notifications.PromptButtonInput(
					2
				)

			end

		end
	)

	print("UFO test ready.")
	print("Click a seed and press YES.")
end

local autoBuyEnabled = false
local autoBuyRunning = false

local function runAutoBuy()

	if autoBuyRunning then
		return
	end

	autoBuyRunning = true

	local Larry =
		require(
			ReplicatedStorage.Modules.Larry
		)

	local UFOHelper =
		require(
			ReplicatedStorage.Modules.UFOHelper
		)

	local PlayerContext =
		require(
			player.PlayerScripts:WaitForChild(
				"PlayerContext"
			)
		)

	local SEED =
		"Gasbloom Willow"

	local ATTEMPTS =
		10000

	local purchaseCount =
		0

	local busy =
		false

	print(
		"DAR Auto-Buy & Grab Started."
	)

	while autoBuyEnabled do

		if
			not busy
			and purchaseCount < ATTEMPTS
		then

			local success, err =
				pcall(
					function()

						Larry.FireServer(
							"PurchaseAlienSeeds",
							SEED
						)

					end
				)

			if success then

				purchaseCount += 1

			else

				warn(
					"DAR purchase error:",
					err
				)

			end

		end

		if not busy then

			local pipe

			local pipeSuccess =
				pcall(
					function()

						pipe =
							UFOHelper.GetDispenserPipe()

					end
				)

			if
				pipeSuccess
				and pipe
			then

				local boxSpawn =
					pipe:FindFirstChild(
						"BoxSpawn"
					)

				if boxSpawn then

					local boxRef =
						boxSpawn:FindFirstChild(
							tostring(
								player.UserId
							)
						)

					if
						boxRef
						and
						pipe:GetAttribute(
							"AnimationEnded"
						) == true
					then

						busy = true

						print(
							"Trying to grab box"
						)

						pcall(
							function()

								Larry.FireServer(
									"GrabAlienSeedBox"
								)

							end
						)

						local timeout =
							os.clock() + 3

						repeat

							task.wait()

							if not autoBuyEnabled then
								break
							end

							local carrying =
								PlayerContext.Carrying

							local state =
								PlayerContext
									.CurrentContextState

							if
								carrying
								and carrying.Primary
								and state
								and state.CanDrop
							then

								break

							end

						until
							os.clock()
							> timeout

						local carrying =
							PlayerContext.Carrying

						local state =
							PlayerContext
								.CurrentContextState

						if
							carrying
							and carrying.Primary
						then

							print(
								"Carrying:",
								carrying.Primary.Name
							)

							if
								state
								and state.CanDrop
							then

								print(
									"Dropping"
								)

								pcall(
									function()

										PlayerContext
											.DropDraggables()

									end
								)

							end

						else

							warn(
								"Box never entered carrying state"
							)

						end

						task.wait(0.75)

						busy = false
					end
				end
			end
		end

		task.wait(0.1)
	end

	autoBuyRunning = false

	print(
		"DAR Auto-Buy & Grab Stopped."
	)
end

local CONFIG = {

	WindowTitle =
		"DAR Scripts",

	ScriptName =
		"UFO Teleport",

	AccentColor =
		Color3.fromHex("#7C3AED"),

	BackgroundColor =
		Color3.fromRGB(
			18,
			18,
			24
		),

	TextColor =
		Color3.fromRGB(
			255,
			255,
			255
		),

	SubTextColor =
		Color3.fromRGB(
			140,
			140,
			150
		),

	ButtonIdleColor =
		Color3.fromRGB(
			40,
			40,
			48
		),

	ButtonActiveColor =
		Color3.fromHex(
			"#7C3AED"
		),

	WindowSize =
		UDim2.fromOffset(
			300,
			205
		)
}

local function createUI()

	local main =
		Instance.new(
			"ScreenGui"
		)

	main.Name =
		"DARScriptsUI"

	main.ResetOnSpawn =
		false

	main.ZIndexBehavior =
		Enum.ZIndexBehavior.Sibling

	main.Parent =
		playerGui

	local frame =
		Instance.new(
			"Frame"
		)

	frame.Name =
		"MainFrame"

	frame.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	frame.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	frame.Size =
		CONFIG.WindowSize

	frame.BackgroundColor3 =
		CONFIG.BackgroundColor

	frame.BorderSizePixel =
		0

	frame.Active =
		true

	frame.Draggable =
		true

	frame.Parent =
		main

	local corner =
		Instance.new(
			"UICorner"
		)

	corner.CornerRadius =
		UDim.new(
			0,
			8
		)

	corner.Parent =
		frame

	local topBorder =
		Instance.new(
			"Frame"
		)

	topBorder.Name =
		"TopBorder"

	topBorder.Size =
		UDim2.new(
			1,
			0,
			0,
			4
		)

	topBorder.BackgroundColor3 =
		CONFIG.AccentColor

	topBorder.BorderSizePixel =
		0

	topBorder.Parent =
		frame

	local title =
		Instance.new(
			"TextLabel"
		)

	title.Name =
		"Title"

	title.Size =
		UDim2.new(
			1,
			-40,
			0,
			25
		)

	title.Position =
		UDim2.new(
			0,
			15,
			0,
			8
		)

	title.BackgroundTransparency =
		1

	title.Text =
		CONFIG.WindowTitle

	title.Font =
		Enum.Font.GothamBold

	title.TextSize =
		16

	title.TextColor3 =
		CONFIG.AccentColor

	title.TextXAlignment =
		Enum.TextXAlignment.Left

	title.Parent =
		frame

	local sep =
		Instance.new(
			"Frame"
		)

	sep.Size =
		UDim2.new(
			1,
			-30,
			0,
			1
		)

	sep.Position =
		UDim2.new(
			0,
			15,
			0,
			35
		)

	sep.BackgroundColor3 =
		CONFIG.AccentColor

	sep.BackgroundTransparency =
		0.7

	sep.BorderSizePixel =
		0

	sep.Parent =
		frame

	local scriptLabel =
		Instance.new(
			"TextLabel"
		)

	scriptLabel.Name =
		"ScriptLabel"

	scriptLabel.Size =
		UDim2.new(
			1,
			-30,
			0,
			20
		)

	scriptLabel.Position =
		UDim2.new(
			0,
			15,
			0,
			45
		)

	scriptLabel.BackgroundTransparency =
		1

	scriptLabel.Text =
		CONFIG.ScriptName

	scriptLabel.Font =
		Enum.Font.Gotham

	scriptLabel.TextSize =
		14

	scriptLabel.TextColor3 =
		CONFIG.TextColor

	scriptLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	scriptLabel.Parent =
		frame

	local statusText =
		Instance.new(
			"TextLabel"
		)

	statusText.Name =
		"StatusText"

	statusText.Size =
		UDim2.new(
			1,
			-30,
			0,
			16
		)

	statusText.Position =
		UDim2.new(
			0,
			15,
			0,
			65
		)

	statusText.BackgroundTransparency =
		1

	statusText.Text =
		"Status: Idle"

	statusText.Font =
		Enum.Font.Gotham

	statusText.TextSize =
		11

	statusText.TextColor3 =
		CONFIG.SubTextColor

	statusText.TextXAlignment =
		Enum.TextXAlignment.Left

	statusText.Parent =
		frame

	local actionButton =
		Instance.new(
			"TextButton"
		)

	actionButton.Name =
		"ActionButton"

	actionButton.Size =
		UDim2.new(
			1,
			-30,
			0,
			36
		)

	actionButton.Position =
		UDim2.new(
			0,
			15,
			0,
			85
		)

	actionButton.BackgroundColor3 =
		CONFIG.ButtonIdleColor

	actionButton.BorderSizePixel =
		0

	actionButton.Text =
		"EXECUTE"

	actionButton.Font =
		Enum.Font.GothamBold

	actionButton.TextSize =
		14

	actionButton.TextColor3 =
		CONFIG.TextColor

	actionButton.AutoButtonColor =
		true

	actionButton.Parent =
		frame

	local buttonCorner =
		Instance.new(
			"UICorner"
		)

	buttonCorner.CornerRadius =
		UDim.new(
			0,
			6
		)

	buttonCorner.Parent =
		actionButton

	local autoBuyLabel =
		Instance.new(
			"TextLabel"
		)

	autoBuyLabel.Name =
		"AutoBuyLabel"

	autoBuyLabel.Size =
		UDim2.new(
			1,
			-100,
			0,
			24
		)

	autoBuyLabel.Position =
		UDim2.new(
			0,
			15,
			0,
			137
		)

	autoBuyLabel.BackgroundTransparency =
		1

	autoBuyLabel.Text =
		"Auto Buy"

	autoBuyLabel.Font =
		Enum.Font.Gotham

	autoBuyLabel.TextSize =
		14

	autoBuyLabel.TextColor3 =
		CONFIG.TextColor

	autoBuyLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	autoBuyLabel.Parent =
		frame

	local autoBuyStatus =
		Instance.new(
			"TextLabel"
		)

	autoBuyStatus.Name =
		"AutoBuyStatus"

	autoBuyStatus.Size =
		UDim2.new(
			1,
			-100,
			0,
			16
		)

	autoBuyStatus.Position =
		UDim2.new(
			0,
			15,
			0,
			158
		)

	autoBuyStatus.BackgroundTransparency =
		1

	autoBuyStatus.Text =
		"Status: Off"

	autoBuyStatus.Font =
		Enum.Font.Gotham

	autoBuyStatus.TextSize =
		11

	autoBuyStatus.TextColor3 =
		CONFIG.SubTextColor

	autoBuyStatus.TextXAlignment =
		Enum.TextXAlignment.Left

	autoBuyStatus.Parent =
		frame

	local toggle =
		Instance.new(
			"TextButton"
		)

	toggle.Name =
		"AutoBuyToggle"

	toggle.Size =
		UDim2.fromOffset(
			50,
			26
		)

	toggle.Position =
		UDim2.new(
			1,
			-65,
			0,
			143
		)

	toggle.BackgroundColor3 =
		CONFIG.ButtonIdleColor

	toggle.BorderSizePixel =
		0

	toggle.Text =
		""

	toggle.AutoButtonColor =
		false

	toggle.Parent =
		frame

	local toggleCorner =
		Instance.new(
			"UICorner"
		)

	toggleCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	toggleCorner.Parent =
		toggle

	local toggleKnob =
		Instance.new(
			"Frame"
		)

	toggleKnob.Name =
		"Knob"

	toggleKnob.Size =
		UDim2.fromOffset(
			20,
			20
		)

	toggleKnob.Position =
		UDim2.fromOffset(
			3,
			3
		)

	toggleKnob.BackgroundColor3 =
		Color3.fromRGB(
			220,
			220,
			225
		)

	toggleKnob.BorderSizePixel =
		0

	toggleKnob.Parent =
		toggle

	local knobCorner =
		Instance.new(
			"UICorner"
		)

	knobCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	knobCorner.Parent =
		toggleKnob

	local closeButton =
		Instance.new(
			"TextButton"
		)

	closeButton.Name =
		"CloseButton"

	closeButton.Size =
		UDim2.fromOffset(
			24,
			24
		)

	closeButton.Position =
		UDim2.new(
			1,
			-30,
			0,
			8
		)

	closeButton.BackgroundColor3 =
		CONFIG.BackgroundColor

	closeButton.BorderSizePixel =
		0

	closeButton.Text =
		"X"

	closeButton.Font =
		Enum.Font.GothamBold

	closeButton.TextSize =
		14

	closeButton.TextColor3 =
		CONFIG.AccentColor

	closeButton.Parent =
		frame

	local closeCorner =
		Instance.new(
			"UICorner"
		)

	closeCorner.CornerRadius =
		UDim.new(
			0,
			4
		)

	closeCorner.Parent =
		closeButton

	return {

		Main = main,

		Frame = frame,

		StatusText =
			statusText,

		ActionButton =
			actionButton,

		CloseButton =
			closeButton,

		AutoBuyToggle =
			toggle,

		AutoBuyKnob =
			toggleKnob,

		AutoBuyStatus =
			autoBuyStatus

	}
end

local ui =
	createUI()

local isBusy =
	false

local function setUIState(state)

	if state == "idle" then

		ui.ActionButton.Text =
			"EXECUTE"

		ui.ActionButton.BackgroundColor3 =
			CONFIG.ButtonIdleColor

		ui.StatusText.Text =
			"Status: Idle"

		ui.StatusText.TextColor3 =
			CONFIG.SubTextColor

	elseif state == "running" then

		ui.ActionButton.Text =
			"EXECUTING..."

		ui.ActionButton.BackgroundColor3 =
			CONFIG.ButtonActiveColor

		ui.StatusText.Text =
			"Teleporting..."

		ui.StatusText.TextColor3 =
			CONFIG.AccentColor

	end
end

local function executeScript()

	if isBusy then
		return
	end

	isBusy =
		true

	setUIState(
		"running"
	)

	task.spawn(
		function()

			local success, err =
				pcall(
					runUFOTeleport
				)

			if not success then

				warn(
					"DAR Script Error: "
					.. tostring(err)
				)

				ui.StatusText.Text =
					"Status: ERROR"

				ui.StatusText.TextColor3 =
					Color3.fromRGB(
						255,
						70,
						70
					)

			else

				setUIState(
					"idle"
				)

			end

			isBusy =
				false

		end
	)
end

local function updateAutoBuyToggle()

	if autoBuyEnabled then

		ui.AutoBuyStatus.Text =
			"Status: On"

		ui.AutoBuyStatus.TextColor3 =
			CONFIG.AccentColor

		TweenService:Create(
			ui.AutoBuyToggle,

			TweenInfo.new(
				0.15
			),

			{
				BackgroundColor3 =
					CONFIG.AccentColor
			}
		):Play()

		TweenService:Create(
			ui.AutoBuyKnob,

			TweenInfo.new(
				0.15
			),

			{
				Position =
					UDim2.fromOffset(
						27,
						3
					)
			}
		):Play()

	else

		ui.AutoBuyStatus.Text =
			"Status: Off"

		ui.AutoBuyStatus.TextColor3 =
			CONFIG.SubTextColor

		TweenService:Create(
			ui.AutoBuyToggle,

			TweenInfo.new(
				0.15
			),

			{
				BackgroundColor3 =
					CONFIG.ButtonIdleColor
			}
		):Play()

		TweenService:Create(
			ui.AutoBuyKnob,

			TweenInfo.new(
				0.15
			),

			{
				Position =
					UDim2.fromOffset(
						3,
						3
					)
			}
		):Play()

	end
end

ui.ActionButton.MouseButton1Click:Connect(
	executeScript
)

ui.AutoBuyToggle.MouseButton1Click:Connect(
	function()

		autoBuyEnabled =
			not autoBuyEnabled

		updateAutoBuyToggle()

		if autoBuyEnabled then

			task.spawn(
				function()

					local success, err =
						pcall(
							runAutoBuy
						)

					if not success then

						warn(
							"DAR Auto-Buy Error:",
							err
						)

						autoBuyEnabled =
							false

						updateAutoBuyToggle()

					end

				end
			)

		end
	end
)

ui.CloseButton.MouseButton1Click:Connect(
	function()

		autoBuyEnabled =
			false

		ui.Main.Enabled =
			false

	end
)

print(
	"DAR Scripts UI Loaded."
)
