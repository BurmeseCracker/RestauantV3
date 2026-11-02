-- Script Path: game:GetService("StarterPlayer").StarterPlayerScripts.Source.Modules.Tasks.RestaurantTycoonManager
-- Combined Auto-Collect, Auto-Bills, Auto Take Order, & Safe Dynamic Table Assignment (With Detailed Console Logs)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local Customers = require(LocalPlayer.PlayerScripts.Source.Systems.Restaurant.Customers)
local CustomerState = require(ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerState)
local TaskEnum = require(ReplicatedStorage.Source.Enums.Restaurant.Task)
local Particle2D = require(LocalPlayer.PlayerScripts.Source.Modules.Interfaces.Particle2D)

print("[DEBUG] Restaurant Tycoon 3 V1 Manager loaded successfully!")

local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local isRunning = true

-- All toggles start OFF by default
local autoCollectDishesEnabled = false
local autoCollectBillsEnabled = false
local autoTakeOrderEnabled = false
local autoAssignTableEnabled = false

-- Create Unified Control Panel GUI
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("RestaurantTycoonManagerUI") then
    playerGui.RestaurantTycoonManagerUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RestaurantTycoonManagerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 205)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Restaurant Tycoon 3 V1"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

-- Helper function to style toggle buttons
local function createButton(position, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 24)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(120, 120, 120) -- OFF gray color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = text
    btn.Parent = frame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn
    return btn
end

local toggleDishesBtn = createButton(UDim2.new(0, 10, 0, 35), "Dishes: OFF")
local toggleBillsBtn = createButton(UDim2.new(0, 10, 0, 65), "Bills & Tips: OFF")
local toggleOrderBtn = createButton(UDim2.new(0, 10, 0, 95), "Take Orders: OFF")
local toggleTableBtn = createButton(UDim2.new(0, 10, 0, 125), "Assign Tables: OFF")
local killBtn = createButton(UDim2.new(0, 10, 0, 160), "Kill Script")
killBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)

-- Button Interactions
toggleDishesBtn.MouseButton1Click:Connect(function()
    autoCollectDishesEnabled = not autoCollectDishesEnabled
    toggleDishesBtn.Text = autoCollectDishesEnabled and "Dishes: ON" or "Dishes: OFF"
    toggleDishesBtn.BackgroundColor3 = autoCollectDishesEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
    print("[DEBUG] Auto-collect dishes toggled:", autoCollectDishesEnabled)
end)

toggleBillsBtn.MouseButton1Click:Connect(function()
    autoCollectBillsEnabled = not autoCollectBillsEnabled
    toggleBillsBtn.Text = autoCollectBillsEnabled and "Bills & Tips: ON" or "Bills & Tips: OFF"
    toggleBillsBtn.BackgroundColor3 = autoCollectBillsEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
    print("[DEBUG] Auto-collect bills toggled:", autoCollectBillsEnabled)
end)

toggleOrderBtn.MouseButton1Click:Connect(function()
    autoTakeOrderEnabled = not autoTakeOrderEnabled
    toggleOrderBtn.Text = autoTakeOrderEnabled and "Take Orders: ON" or "Take Orders: OFF"
    toggleOrderBtn.BackgroundColor3 = autoTakeOrderEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
    print("[DEBUG] Auto take orders toggled:", autoTakeOrderEnabled)
end)

toggleTableBtn.MouseButton1Click:Connect(function()
    autoAssignTableEnabled = not autoAssignTableEnabled
    toggleTableBtn.Text = autoAssignTableEnabled and "Assign Tables: ON" or "Assign Tables: OFF"
    toggleTableBtn.BackgroundColor3 = autoAssignTableEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
    print("[DEBUG] Auto assign tables toggled:", autoAssignTableEnabled)
end)

killBtn.MouseButton1Click:Connect(function()
    isRunning = false
    screenGui:Destroy()
    print("[DEBUG] Restaurant Tycoon 3 V1 script killed and UI removed.")
end)

-- Efficient Local Tycoon Finder
local function GetLocalTycoon()
    local tycoonsFolder = workspace:FindFirstChild("Tycoons")
    if not tycoonsFolder then return nil end

    for _, child in ipairs(tycoonsFolder:GetChildren()) do
        if child.Name == LocalPlayer.Name 
            or child:GetAttribute("Owner") == LocalPlayer 
            or child:GetAttribute("OwnerUserId") == LocalPlayer.UserId 
            or child:GetAttribute("Player") == LocalPlayer then
            return child
        end
        
        local ownerVal = child:FindFirstChild("Owner")
        if ownerVal and (ownerVal.Value == LocalPlayer or ownerVal.Value == LocalPlayer.Name) then
            return child
        end
    end

    local children = tycoonsFolder:GetChildren()
    return (#children >= 5) and children[5] or nil
end

-- Animation helpers
local function PlayCollectAnimation(model)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hrpPos = hrp.Position
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency ~= 1 then
            descendant.CanCollide = false
            TweenService:Create(descendant, tweenInfo, {
                Transparency = 1,
                Position = Vector3.new(hrpPos.X, descendant.Position.Y, hrpPos.Z),
                Size = descendant.Size * 0.5
            }):Play()
        end
    end
end

-- Process Functions with detailed logging
local processedTrash = {}
local processedBills = {}

local function ProcessDishes(tycoon, tableModel)
    if not isRunning or not autoCollectDishesEnabled then return end
    local trash = tableModel:FindFirstChild("Trash")
    if not trash or not trash:GetAttribute("Collectable") or processedTrash[trash] then return end

    processedTrash[trash] = true
    print("[DEBUG] Found dish / trash on table:", tableModel.Name, "- Collecting...")
    PlayCollectAnimation(trash)

    ReplicatedStorage.Events.SoundRequested:Fire("AlienAccept5")
    ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
        Name = TaskEnum.CollectDishes,
        FurnitureModel = tableModel,
        Tycoon = tycoon
    })
    
    task.delay(2, function()
        processedTrash[trash] = nil
    end)
end

local function ProcessBills(tycoon, tableModel)
    if not isRunning or not autoCollectBillsEnabled then return end
    local bill = tableModel:FindFirstChild("Bill")
    if not bill or bill:GetAttribute("Taken") or processedBills[bill] then return end

    processedBills[bill] = true
    local billValue = bill:GetAttribute("Value") or 0
    print(string.format("[DEBUG] Found bill / tip on table: %s (Value: %d) - Collecting...", tableModel.Name, billValue))
    
    PlayCollectAnimation(bill)

    ReplicatedStorage.Events.SoundRequested:Fire("Cash")
    Particle2D:CreateCurrencyParticles(billValue)
    ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
        Name = TaskEnum.CollectBill,
        FurnitureModel = tableModel,
        Tycoon = tycoon
    })

    task.delay(2, function()
        processedBills[bill] = nil
    end)
end

local processedOrders = {}

local function CheckDynamicOrders(tycoon)
    if not isRunning or not autoTakeOrderEnabled then return end

    pcall(function()
        local clientCustomers = tycoon:FindFirstChild("ClientCustomers")
        if not clientCustomers then return end

        for _, groupFolder in ipairs(clientCustomers:GetChildren()) do
            if not autoTakeOrderEnabled then break end
            local groupId = groupFolder.Name

            for _, customerObj in ipairs(groupFolder:GetChildren()) do
                if not autoTakeOrderEnabled then break end
                local customerId = customerObj.Name

                if not processedOrders[customerObj] then
                    if Customers:GetCustomerState(tycoon, groupId, customerId) == CustomerState.Ordering then
                        processedOrders[customerObj] = true
                        print(string.format("[DEBUG] Found customer ready to order! Group: %s, Customer: %s", groupId, customerId))

                        ReplicatedStorage.Events.SoundRequested:Fire("AlienAccept5")
                        ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
                            Name = TaskEnum.TakeOrder,
                            GroupId = groupId,
                            CustomerId = customerId,
                            Tycoon = tycoon
                        })

                        task.delay(3, function()
                            processedOrders[customerObj] = nil
                        end)
                    end
                end
            end
        end
    end)
end

local processedAssignments = {}

local function CheckAndAssignTables(tycoon)
    if not isRunning or not autoAssignTableEnabled then return end

    pcall(function()
        local clientCustomers = tycoon:FindFirstChild("ClientCustomers")
        local itemsFolder = tycoon:FindFirstChild("Items")
        local surfaceFolder = itemsFolder and itemsFolder:FindFirstChild("Surface")
        if not clientCustomers or not surfaceFolder then return end

        for _, groupFolder in ipairs(clientCustomers:GetChildren()) do
            if not autoAssignTableEnabled then break end
            local groupId = groupFolder.Name

            if Customers:GetGroupState(tycoon, groupId) == CustomerState.Entered and not processedAssignments[groupId] then
                local availableTable = nil
                for _, tableModel in ipairs(surfaceFolder:GetChildren()) do
                    if tableModel:IsA("Model") and tableModel.Name:match("^T%d+") then
                        local hasCustomers = tableModel:FindFirstChild("Customers") and #tableModel.Customers:GetChildren() > 0
                        local hasTrash = tableModel:FindFirstChild("Trash") and tableModel.Trash:GetAttribute("Collectable")
                        local hasBill = tableModel:FindFirstChild("Bill") and not tableModel.Bill:GetAttribute("Taken")
                        local isOccupiedByAttribute = tableModel:GetAttribute("Occupied") == true or tableModel:GetAttribute("GroupId") ~= nil

                        if not hasCustomers and not hasTrash and not hasBill and not isOccupiedByAttribute then
                            availableTable = tableModel
                            break
                        end
                    end
                end

                if availableTable and autoAssignTableEnabled then
                    processedAssignments[groupId] = true
                    print(string.format("[DEBUG] Found waiting customer Group %s. Assigning to available table: %s", groupId, availableTable.Name))

                    ReplicatedStorage.Events.SoundRequested:Fire("AlienAccept4")
                    ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
                        Name = TaskEnum.SendToTable,
                        GroupId = groupId,
                        FurnitureModel = availableTable,
                        Tycoon = tycoon
                    })

                    task.delay(3, function()
                        processedAssignments[groupId] = nil
                    end)
                end
            end
        end
    end)
end

-- Unified Background Loop
task.spawn(function()
    print("[DEBUG] Master auto-manager loop started!")
    while isRunning do
        task.wait(0.3)
        
        -- Only run logic if at least one feature is toggled ON
        if autoCollectDishesEnabled or autoCollectBillsEnabled or autoTakeOrderEnabled or autoAssignTableEnabled then
            local tycoon = GetLocalTycoon()
            if tycoon then
                if autoAssignTableEnabled then
                    CheckAndAssignTables(tycoon)
                end

                if autoTakeOrderEnabled then
                    CheckDynamicOrders(tycoon)
                end

                if autoCollectDishesEnabled or autoCollectBillsEnabled then
                    for _, descendant in ipairs(tycoon:GetDescendants()) do
                        if not isRunning then break end
                        
                        if descendant.Name == "Trash" and autoCollectDishesEnabled then
                            if descendant:GetAttribute("Collectable") == true then
                                local tableModel = descendant.Parent
                                if tableModel then ProcessDishes(tycoon, tableModel) end
                            end
                        elseif descendant.Name == "Bill" and autoCollectBillsEnabled then
                            if not descendant:GetAttribute("Taken") then
                                local tableModel = descendant.Parent
                                if tableModel then ProcessBills(tycoon, tableModel) end
                            end
                        end
                    end
                end
            end
        end
    end
    print("[DEBUG] Master background loop terminated.")
end)

return {
    Init = function()
        print("[DEBUG] Game called Init().")
    end
}