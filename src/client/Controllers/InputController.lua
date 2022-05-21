local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.shared.Knit)
local Keybindings = require(ReplicatedStorage.shared.Modules.Keybindings)
local MovementController
local WeaponController

local InputController = Knit.CreateController { Name = "InputController" }

function InputController.BindInputs()
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyPressed = input.KeyCode

            if keyPressed == Keybindings.Keyboard.Crouch then
                MovementController.Crouch()
            elseif keyPressed == Keybindings.Keyboard.Sprint then
                    MovementController.StartSprint()
            elseif keyPressed == Keybindings.Keyboard.Switch then
                WeaponController.SwapCurrentWeapon()
            elseif keyPressed == Keybindings.Keyboard.Reload then
                WeaponController.Reload()
            elseif keyPressed == Keybindings.Keyboard.ToogleAim then
                WeaponController.ToogleAim()
            end

            if keyPressed == Keybindings.Keyboard.Primary then
                WeaponController.SwapWeaponTo("Primary")
            elseif keyPressed == Keybindings.Keyboard.Sidearm then
                WeaponController.SwapWeaponTo("Sidearm")
            elseif keyPressed == Keybindings.Keyboard.Equipment then
                WeaponController.SwapWeaponTo("Equipment")
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            WeaponController.Fire()
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyPressed = input.KeyCode

            if keyPressed == Keybindings.Keyboard.Crouch then
                MovementController.GetUp()
            elseif keyPressed == Keybindings.Keyboard.Sprint then
                MovementController.EndSprint()
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            WeaponController.StopFire()
        end
    end)
end

function InputController:KnitStart()
    WeaponController = Knit.GetController("WeaponController")
    MovementController = Knit.GetController("MovementController")

    InputController.BindInputs()
end

function InputController:KnitInit()
    
end

return InputController