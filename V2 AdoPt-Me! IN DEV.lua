-- Place this LocalScript in a suitable location, within StarterPlayerScripts or StarterGui.

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local workspace = game:GetService("Workspace")

local args = {
    [1] = localPlayer, -- This is the player instance
    [2] = true -- This could represent a true/false flag for the unsubscription process
}

-- State variable to control whether the script is active
local scriptActive = false -- Start with the script turned off
local searchingForSalon = false -- Variable to track if we are looking for the salon
local searchingForSchool = false -- Variable to track if we are looking for the school

-- Function to unsubscribe from the house
local function unsubscribeFromHouse()
    if not scriptActive then return end -- Exit if the script is not active
    
    local success, response = pcall(function()
        return replicatedStorage.API.UnsubscribeFromHouse:InvokeServer(unpack(args))
    end)

    if success then
        if response then
            print("Successfully unsubscribed from house:", response)
        else
            warn("Unsubscribed, but received no response from the server.")
        end
    else
        warn("Failed to unsubscribe from house. Error:", response)
    end
end

-- Function to find a part by name within a model
local function findPartInModel(model, partName)
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("Part") and child.Name == partName then
            return child -- Return immediately when found
        end
    end
    return nil
end

-- Function to find configuration for destination ID
local function findConfigurationForDestinationId()
    if not scriptActive then return end -- Exit if the script is not active
    
    local interiors = workspace:WaitForChild("Interiors")
    
    for _, model in pairs(interiors:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("Doors") then
            local doors = model.Doors
            if doors:FindFirstChild("MainDoor") then
                local mainDoor = doors.MainDoor
                if mainDoor:FindFirstChild("WorkingParts") then
                    local workingParts = mainDoor.WorkingParts
                    if workingParts:FindFirstChild("Configuration") then
                        return workingParts.Configuration
                    end
                end
            end
        end
    end
end

-- Function to change destination ID
local function changeDestinationId(destination)
    if not scriptActive then return end -- Exit if the script is not active
    
    local configuration = findConfigurationForDestinationId()
    
    if configuration and configuration:FindFirstChild("destination_id") then
        configuration.destination_id.Value = destination -- Change the destination_id
        print("Changed destination_id to: " .. configuration.destination_id.Value)
    else
        warn("Configuration or destination_id not found.")
    end
end

-- Function to periodically change destination ID to "PizzaShop"
local function changeDestinationIdForPizzaShop()
    while scriptActive do
        changeDestinationId("PizzaShop") -- Set the destination_id to "PizzaShop"
        wait(5) -- Wait 5 seconds between updates
    end
end

-- Function to teleport to TouchToEnter part
local function teleportToTouchToEnter()
    if not scriptActive then return end -- Exit if the script is not active
    
    local success, response = pcall(function()
        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

        -- Check all models under Interiors for TouchToEnter
        local interiors = workspace:WaitForChild("Interiors")
        for _, model in pairs(interiors:GetChildren()) do
            if model:IsA("Model") then
                local touchToEnterPart = findPartInModel(model, "TouchToEnter")
                if touchToEnterPart then
                    if character.PrimaryPart then
                        character:SetPrimaryPartCFrame(touchToEnterPart.CFrame)
                        print("Successfully teleported to TouchToEnter part.")
                    else
                        warn("No PrimaryPart found in character.")
                    end
                    return -- Exit function after teleporting to the first TouchToEnter part
                end
            end
        end
        warn("The TouchToEnter part was not found in the specified models.")
    end)

    if not success then
        warn("Failed to teleport to TouchToEnter part. Error:", response)
    end
end

-- Function to find PizzaShop
local function findPizzaShop()
    if not scriptActive then return end -- Exit if the script is not active
    
    local interiors = workspace:FindFirstChild("Interiors")
    if interiors then
        return interiors:FindFirstChild("PizzaShop")
    else
        return nil
    end
end

-- Function to set PizzaShop properties and teleport the player
local function setPizzaShop()
    if not scriptActive then return end -- Exit if the script is not active
    
    local pizzaShop = findPizzaShop()
    
    if pizzaShop then
        -- Teleport to the InteriorOrigin part when it is set
        local interiorOrigin = pizzaShop:FindFirstChild("InteriorOrigin")
        if interiorOrigin and interiorOrigin:IsA("Part") then
            interiorOrigin.Transparency = 0 -- Set transparency of InteriorOrigin to 0
            interiorOrigin.Size = Vector3.new(512, 1, 512) -- Set size to match baseplate dimensions
            interiorOrigin.Anchored = true -- Anchor the InteriorOrigin part to prevent it from falling
            
            local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
            if character and character.PrimaryPart then
                character:SetPrimaryPartCFrame(interiorOrigin.CFrame + Vector3.new(0, 3, 0)) -- Teleport above the InteriorOrigin
                print("Teleported to InteriorOrigin.")
            else
                warn("No PrimaryPart found in character.")
            end
            
            print("PizzaShop properties have been set.")
            return true
        end
    else
        warn("PizzaShop not found in Interiors.")
        return false
    end
end

-- Function to check InteriorOrigin and teleport to it if found
local function checkInteriorOrigin()
    local pizzaShop = findPizzaShop()
    if pizzaShop then
        local interiorOrigin = pizzaShop:FindFirstChild("InteriorOrigin")
        if interiorOrigin and interiorOrigin:IsA("Part") then
            -- Teleport to InteriorOrigin once it is detected
            local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
            if character and character.PrimaryPart then
                character:SetPrimaryPartCFrame(interiorOrigin.CFrame + Vector3.new(0, 3, 0)) -- Teleport above the InteriorOrigin
                print("Teleported to InteriorOrigin.")
            else
                warn("No PrimaryPart found in character.")
            end
            
            -- Set the properties of the InteriorOrigin part
            interiorOrigin.Transparency = 0 -- Set transparency to 0
            interiorOrigin.Size = Vector3.new(512, 1, 512) -- Set size to match baseplate dimensions
            interiorOrigin.Anchored = true -- Anchor the InteriorOrigin part
            
            print("InteriorOrigin properties have been set.")
        end
    end
end

-- Function to check InteriorOrigin continuously
local function checkInteriorOriginContinuously()
    while scriptActive do
        checkInteriorOrigin()
        wait(2) -- Check again after 2 seconds
    end
end

-- Function to continuously find the Salon's InteriorOrigin
local function continuouslyFindSalonInteriorOrigin()
    while searchingForSalon do
        wait(2) -- Check every 2 seconds
        local salonModel = workspace:FindFirstChild("Interiors") and workspace.Interiors:FindFirstChild("Salon")
        if salonModel then
            local interiorOrigin = salonModel:FindFirstChild("InteriorOrigin")
            if interiorOrigin and interiorOrigin:IsA("Part") then
                -- Teleport to the InteriorOrigin of Salon if found
                local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                if character and character.PrimaryPart then
                    -- Set the transparency and size
                    interiorOrigin.Transparency = 0 -- Set transparency to 0
                    interiorOrigin.Size = Vector3.new(512, 1, 512) -- Set size to mimic a baseplate
                    interiorOrigin.Anchored = true -- Anchor the InteriorOrigin part
                    character:SetPrimaryPartCFrame(interiorOrigin.CFrame + Vector3.new(0, 3, 0))
                    print("Teleported to Salon's InteriorOrigin.")
                else
                    warn("No PrimaryPart found in character.")
                end
                return -- Exit once the Salon's InteriorOrigin has been found and teleported to
            end
        else
            warn("Salon model not found in Interiors.")
        end
    end
end

-- Function to continuously find the School's InteriorOrigin
local function continuouslyFindSchoolInteriorOrigin()
    while searchingForSchool do
        wait(2) -- Check every 2 seconds
        local schoolModel = workspace:FindFirstChild("Interiors") and workspace.Interiors:FindFirstChild("School")
        if schoolModel then
            local interiorOrigin = schoolModel:FindFirstChild("InteriorOrigin")
            if interiorOrigin and interiorOrigin:IsA("Part") then
                -- Teleport to the InteriorOrigin of School if found
                local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                if character and character.PrimaryPart then
                    -- Set the transparency and size
                    interiorOrigin.Transparency = 0 -- Set transparency to 0
                    interiorOrigin.Size = Vector3.new(512, 1, 512) -- Set size to mimic a baseplate
                    interiorOrigin.Anchored = true -- Anchor the InteriorOrigin part
                    character:SetPrimaryPartCFrame(interiorOrigin.CFrame + Vector3.new(0, 3, 0))
                    print("Teleported to School's InteriorOrigin.")
                else
                    warn("No PrimaryPart found in character.")
                end
                return -- Exit once the School's InteriorOrigin has been found and teleported to
            else
                warn("InteriorOrigin not found in School.")
            end
        else
            warn("School model not found in Interiors.")
        end
    end
end

-- Updated function to create a platform below the character when teleporting to Campsite Origin
local function createPlatformAboveCampsite(campsiteOrigin)
    local platform = Instance.new("Part") -- Create a new part
    platform.Size = Vector3.new(512, 1, 512) -- Set platform size to mimic a baseplate
    platform.Position = campsiteOrigin.Position + Vector3.new(0, 5, 0) -- Position it above the Campsite Origin
    platform.Anchored = true -- Make it anchored
    platform.BrickColor = BrickColor.new("Bright blue") -- Set color of the platform
    platform.Parent = workspace -- Parent the platform to the workspace
    return platform
end

-- Function to create a countdown UI element
local function createCountdownLabel(taskName, initialTime)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = taskName .. "CountdownGui"
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(0, 300, 0, 50) -- Size of the label
    countdownLabel.Position = UDim2.new(0.5, -150, 0, 10) -- Centered at the top
    countdownLabel.TextScaled = true
    countdownLabel.BackgroundColor3 = Color3.new(1, 1, 1) -- White background
    countdownLabel.BackgroundTransparency = 0.5 -- Semi-transparent
    countdownLabel.TextColor3 = Color3.new(0, 0, 0) -- Black text
    countdownLabel.Text = taskName .. ": " .. initialTime
    countdownLabel.Parent = screenGui
    
    return countdownLabel
end

-- Function for countdown with provided task name and duration
local function startCountdown(taskName, duration)
    local countdownLabel = createCountdownLabel(taskName, duration)

    for i = duration, 0, -1 do
        countdownLabel.Text = taskName .. ": " .. i
        wait(1) -- Wait for 1 second
    end

    -- Remove the countdown label after completion
    countdownLabel.Parent:Destroy()
    print(taskName .. " countdown finished.")
end

-- Function to teleport to Campsite Origin with a 7-second countdown
local function teleportToCampsiteOrigin()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

    if character and character.PrimaryPart then
        -- Teleport to TouchToEnter part of School
        local touchToEnterPart = workspace.Interiors.School.Doors.MainDoor.WorkingParts.TouchToEnter
        if touchToEnterPart then
            character:SetPrimaryPartCFrame(touchToEnterPart.CFrame) -- Teleport to TouchToEnter
            print("Teleported to School's TouchToEnter.")
            
            -- Countdown before creating the platform and teleporting to Campsite Origin
            for i = 7, 1, -1 do
                print("Teleporting to Campsite Origin in " .. i .. " second" .. (i > 1 and "s..." or "..."))
                wait(1) -- Wait for 1 second for each countdown iteration
            end
            
            -- Get Campsite Origin and create a platform
            local campsiteOrigin = workspace.StaticMap.Campsite:FindFirstChild("CampsiteOrigin")
            if campsiteOrigin then
                local platform = createPlatformAboveCampsite(campsiteOrigin) -- Create platform above Campsite Origin

                -- Teleport character to the top of the platform
                character:SetPrimaryPartCFrame(platform.CFrame + Vector3.new(0, 3, 0)) -- Position the character just above the platform
                print("Teleported to Campsite Origin above the platform.")

                -- Start the countdown for campsite task
                coroutine.wrap(startCountdown)("Doing Camp Task", 100) -- Starts a 100-second countdown
            else
                warn("Campsite Origin not found!")
            end
        else
            warn("School's TouchToEnter not found!")
        end
    else
        warn("Character or PrimaryPart not found.")
    end
end

-- GUI Creation
local screenGui = Instance.new("ScreenGui")
local toggleButton = Instance.new("TextButton")
local closeButton = Instance.new("TextButton")
local teleportToSalonButton = Instance.new("TextButton")
local teleportToSchoolButton = Instance.new("TextButton") -- New button for School
local teleportToCampsiteButton = Instance.new("TextButton") -- New button for Campsite Origin

-- Set up properties for the ScreenGui
screenGui.Name = "ToggleGui"
screenGui.DisplayOrder = 1
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Set up properties for the Toggle Button
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 250, 0, 50) -- Width = 250, Height = 50
toggleButton.Position = UDim2.new(0, 10, 0, 10) -- Position to top-left corner with a little offset
toggleButton.Text = "Teleport to PizzaShop: Off" -- Initial button text
toggleButton.TextScaled = true
toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255) -- Button color
toggleButton.Parent = screenGui

-- Set up properties for the Close Button
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 100, 0, 50) -- Width = 100, Height = 50
closeButton.Position = UDim2.new(0, 10, 0, 70) -- Below the teleport button
closeButton.Text = "Close"
closeButton.TextScaled = true
closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Important to distinguish
closeButton.Parent = screenGui

-- Set up properties for the Teleport to Salon Button
teleportToSalonButton.Name = "TeleportToSalonButton"
teleportToSalonButton.Size = UDim2.new(0, 250, 0, 50) -- Width = 250, Height = 50
teleportToSalonButton.Position = UDim2.new(0, 10, 0, 130) -- Below the Close button
teleportToSalonButton.Text = "Teleport to Salon"
teleportToSalonButton.TextScaled = true
teleportToSalonButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green color for positive action
teleportToSalonButton.Parent = screenGui

-- Set up properties for the Teleport to School Button
teleportToSchoolButton.Name = "TeleportToSchoolButton"
teleportToSchoolButton.Size = UDim2.new(0, 250, 0, 50) -- Width = 250, Height = 50
teleportToSchoolButton.Position = UDim2.new(0, 10, 0, 190) -- Below the Salon button
teleportToSchoolButton.Text = "Teleport to School"
teleportToSchoolButton.TextScaled = true
teleportToSchoolButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green color for positive action
teleportToSchoolButton.Parent = screenGui

-- Set up properties for the Teleport to Campsite Button
teleportToCampsiteButton.Name = "TeleportToCampsiteButton"
teleportToCampsiteButton.Size = UDim2.new(0, 250, 0, 50) -- Width = 250, Height = 50
teleportToCampsiteButton.Position = UDim2.new(0, 10, 0, 250) -- Below the School button
teleportToCampsiteButton.Text = "Teleport to Campsite Origin"
teleportToCampsiteButton.TextScaled = true
teleportToCampsiteButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green color for positive action
teleportToCampsiteButton.Parent = screenGui

-- Function to toggle script active status and execute script logic
local function toggleScript()
    scriptActive = not scriptActive
    if scriptActive then
        toggleButton.Text = "Teleport to PizzaShop: On"
        print("Script is now active.")
        
        -- Call the necessary functions when the script is activated
        unsubscribeFromHouse() -- Unsubscribe from the house
        wait(5) -- Wait for 5 seconds after unsubscribing
        
        -- Start the coroutine for continuous destination id update
        coroutine.wrap(changeDestinationIdForPizzaShop)()

        -- Attempt to teleport to the neighborhood
        wait(3) -- Ensure there is sufficient time for the unsubscribe to complete
        teleportToTouchToEnter() -- Attempt to teleport to the TouchToEnter part.
        
        -- Start checking for InteriorOrigin continuously
        coroutine.wrap(checkInteriorOriginContinuously)() 
        
        -- Start the countdown for Pizza Shop Task
        coroutine.wrap(startCountdown)("Doing Pizza Shop Task", 100) -- Starts a 100-second countdown
    else
        toggleButton.Text = "Teleport to PizzaShop: Off"
        print("Script is now inactive.")
    end
end

-- Function to close the GUI
local function closeGui()
    scriptActive = false -- Stop any active operations
    screenGui:Destroy()
    print("GUI closed.")
end

-- Function to handle teleport to Salon button
local function teleportToSalon()
    print("Teleport to Salon button clicked.") -- Debugging statement

    -- Change the destination_id to "Salon"
    local configuration = workspace.Interiors.PizzaShop.Doors.MainDoor.WorkingParts.Configuration
    if configuration and configuration:FindFirstChild("destination_id") then
        configuration.destination_id.Value = "Salon"
        print("Changed destination_id to Salon.")
    else
        warn("destination_id not found in the configuration.")
        return
    end

    -- Teleport to the TouchToEnter part first
    local touchToEnterPart = workspace.Interiors.PizzaShop.Doors.MainDoor.WorkingParts.TouchToEnter
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    
    if character and character.PrimaryPart then
        character:SetPrimaryPartCFrame(touchToEnterPart.CFrame) -- Teleport to TouchToEnter
        print("Teleported to TouchToEnter.")
    else
        warn("No PrimaryPart found in character.")
        return
    end

    -- Start the countdown for Salon task
    coroutine.wrap(startCountdown)("Doing Salon Task", 100) -- Starts a 100-second countdown

    -- Set searchingForSalon to true and start looking for Salon's InteriorOrigin
    searchingForSalon = true
    coroutine.wrap(continuouslyFindSalonInteriorOrigin)()

    -- Fire TouchInterest in a loop
    while scriptActive do
        wait() 
        firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, workspace.Interiors.PizzaShop.Doors.MainDoor.WorkingParts.TouchToEnter, 0)
    end
end

-- Function to handle teleport to School button
local function teleportToSchool()
    print("Teleport to School button clicked.") -- Debugging statement

    -- Change the destination_id to "School"
    local configuration = workspace.Interiors.Salon.Doors.MainDoor.WorkingParts.Configuration
    if configuration and configuration:FindFirstChild("destination_id") then
        configuration.destination_id.Value = "School"
        print("Changed destination_id to School.")
    else
        warn("destination_id not found in the configuration.")
        return
    end

    -- Teleport to the TouchToEnter part first
    local touchToEnterPart = workspace.Interiors.Salon.Doors.MainDoor.WorkingParts.TouchToEnter
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    
    if character and character.PrimaryPart then
        character:SetPrimaryPartCFrame(touchToEnterPart.CFrame) -- Teleport to TouchToEnter
        print("Teleported to TouchToEnter.")
    else
        warn("No PrimaryPart found in character.")
        return
    end

    -- Start the countdown for School task
    coroutine.wrap(startCountdown)("Doing School Task", 100) -- Starts a 100-second countdown

    -- Set searchingForSchool to true and start looking for School's InteriorOrigin
    searchingForSchool = true
    coroutine.wrap(continuouslyFindSchoolInteriorOrigin)()

    -- Fire TouchInterest in a loop
    while scriptActive do
        wait() 
        firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, workspace.Interiors.Salon.Doors.MainDoor.WorkingParts.TouchToEnter, 0)
    end
end

-- Connect the button click events to the respective functions
toggleButton.MouseButton1Click:Connect(toggleScript)
closeButton.MouseButton1Click:Connect(closeGui)
teleportToSalonButton.MouseButton1Click:Connect(teleportToSalon)
teleportToSchoolButton.MouseButton1Click:Connect(teleportToSchool)
teleportToCampsiteButton.MouseButton1Click:Connect(teleportToCampsiteOrigin)  -- Connect the button to the updated teleport function
