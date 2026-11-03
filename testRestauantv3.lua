-- Script Path: game:GetService("StarterPlayer").StarterPlayerScripts.Source.Modules.Tasks.RestaurantTycoonManager
-- Ultimate Clean Master Script (Draggable, Semi-Transparent Black UI with Top-Left Close Icon)

print("[DEBUG] --- LOCAL PLAYER RESTAURANT MANAGER LOADED ---")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

-- ---------------------------------------------------------------------------
-- Native Systems & Enums Safe Requirement
-- ---------------------------------------------------------------------------
local _, Customers = pcall(function() return require(PlayerScripts.Source.Systems.Restaurant.Customers) end)
local _, CustomerState = pcall(function() return require(ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerState) end)
local _, CustomerType = pcall(function() return require(ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerType) end)
local _, TaskEnum = pcall(function() return require(ReplicatedStorage.Source.Enums.Restaurant.Task) end)
local _, ItemType = pcall(function() return require(ReplicatedStorage.Source.Enums.Placement.ItemType) end)
local _, GrabFood = pcall(function() return require(PlayerScripts.Source.Systems.Restaurant.GrabFood) end)
local _, TasksSys = pcall(function() return require(PlayerScripts.Source.Systems.Restaurant.Tasks) end)

local isRunning = true

-- ---------------------------------------------------------------------------
-- Toggle States (All start OFF by default)
-- ---------------------------------------------------------------------------
local autoCollectDishesEnabled = false
local autoCollectBillsEnabled = false
local autoTakeOrderEnabled = false
local autoServeEnabled = false

-- ---------------------------------------------------------------------------
-- Control Panel GUI Setup (Transparent Black, Draggable, Top-Left Close Icon)
-- ---------------------------------------------------------------------------
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
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.35 -- Semi-transparent cool black background
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Draggable Functionality
local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Top-Most Left Cancel / Close Icon Button ("X")
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(0, 6, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Text = "X"
closeBtn.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- Menu Title (Shifted slightly right to accommodate the close icon)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 0, 30)
title.Position = UDim2.new(0, 32, 0, 2)
title.BackgroundTransparency = 1
title.Text = "Restaurant Tycoon 3"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local function createButton(position, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 24)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- OFF dark gray
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

local toggleDishesBtn = createButton(UDim2.new(0, 10, 0, 38), "Dishes: OFF")
local toggleBillsBtn = createButton(UDim2.new(0, 10, 0, 68), "Bills & Tips: OFF")
local toggleOrderBtn = createButton(UDim2.new(0, 10, 0, 98), "Take Orders: OFF")
local toggleServeBtn = createButton(UDim2.new(0, 10, 0, 128), "Serve Food: OFF")

-- Kill / Cancel Button at the bottom
local killButton = createButton(UDim2.new(0, 10, 0, 165), "Kill Script")
killButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)

-- ---------------------------------------------------------------------------
-- Button Event Handlers
-- ---------------------------------------------------------------------------
toggleDishesBtn.MouseButton1Click:Connect(function()
    autoCollectDishesEnabled = not autoCollectDishesEnabled
    toggleDishesBtn.Text = autoCollectDishesEnabled and "Dishes: ON" or "Dishes: OFF"
    toggleDishesBtn.BackgroundColor3 = autoCollectDishesEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(80, 80, 80)
end)

toggleBillsBtn.MouseButton1Click:Connect(function()
    autoCollectBillsEnabled = not autoCollectBillsEnabled
    toggleBillsBtn.Text = autoCollectBillsEnabled and "Bills & Tips: ON" or "Bills & Tips: OFF"
    toggleBillsBtn.BackgroundColor3 = autoCollectBillsEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(80, 80, 80)
end)

toggleOrderBtn.MouseButton1Click:Connect(function()
    autoTakeOrderEnabled = not autoTakeOrderEnabled
    toggleOrderBtn.Text = autoTakeOrderEnabled and "Take Orders: ON" or "Take Orders: OFF"
    toggleOrderBtn.BackgroundColor3 = autoTakeOrderEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(80, 80, 80)
end)

toggleServeBtn.MouseButton1Click:Connect(function()
    autoServeEnabled = not autoServeEnabled
    toggleServeBtn.Text = autoServeEnabled and "Serve Food: ON" or "Serve Food: OFF"
    toggleServeBtn.BackgroundColor3 = autoServeEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(80, 80, 80)
end)

local function TerminateScript()
    isRunning = false
    screenGui:Destroy()
    print("[DEBUG] Script killed and UI removed successfully.")
end

closeBtn.MouseButton1Click:Connect(TerminateScript)
killButton.MouseButton1Click:Connect(TerminateScript)

-- ---------------------------------------------------------------------------
-- Helper Functions
-- ---------------------------------------------------------------------------
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

    if LocalPlayer:FindFirstChild("Tycoon") and LocalPlayer.Tycoon.Value then
        return LocalPlayer.Tycoon.Value
    end

    return nil
end

local function GetValidTables(surfaceFolder)
    local tables = {}
    local seenInstances = {}
    for _, child in ipairs(surfaceFolder:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^T%d+") and not seenInstances[child] then
            seenInstances[child] = true
            table.insert(tables, child)
        end
    end
    return tables
end

local function ClearNativeTaskLock()
    pcall(function()
        if TasksSys then
            if TasksSys.ResetTask then TasksSys:ResetTask() end
            if TasksSys.FinishTask then TasksSys:FinishTask() end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Automation Action Handlers
-- ---------------------------------------------------------------------------
local processedTrash = {}
local function ProcessDishes(tycoon, tableModel)
    if not isRunning or not autoCollectDishesEnabled then return end
    local trash = tableModel:FindFirstChild("Trash")
    if not trash or not trash:GetAttribute("Collectable") or processedTrash[trash] then return end

    processedTrash[trash] = true
    ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
        Name = TaskEnum.CollectDishes,
        FurnitureModel = tableModel,
        Tycoon = tycoon
    })
    ClearNativeTaskLock()
    
    task.delay(1.5, function() processedTrash[trash] = nil end)
end

local processedBills = {}
local function ProcessBills(tycoon, tableModel)
    if not isRunning or not autoCollectBillsEnabled then return end
    local billObj = tableModel:FindFirstChild("Bill", true)
    if not billObj or processedBills[billObj] or billObj:GetAttribute("Taken") == true then return end

    processedBills[billObj] = true
    ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
        Name = TaskEnum.CollectBill,
        FurnitureModel = tableModel,
        Tycoon = tycoon
    })
    ClearNativeTaskLock()

    task.delay(1.5, function() processedBills[billObj] = nil end)
end

local processedTipJars = {}
local function ProcessTipJar(tycoon, tipJarModel)
    if not isRunning or not autoCollectBillsEnabled then return end
    local tipValue = tipJarModel:GetAttribute("Value") or 0
    if tipValue <= 0 or processedTipJars[tipJarModel] then return end

    processedTipJars[tipJarModel] = true
    ReplicatedStorage.Events.Restaurant.TipsCollected:FireServer(tycoon)

    task.delay(2, function() processedTipJars[tipJarModel] = nil end)
end

local processedOrders = {}
local function CheckDynamicOrders(tycoon)
    if not isRunning or not autoTakeOrderEnabled then return end

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
                    ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
                        Name = TaskEnum.TakeOrder,
                        GroupId = groupId,
                        CustomerId = customerId,
                        Tycoon = tycoon
                    })
                    ClearNativeTaskLock()

                    task.delay(2, function() processedOrders[customerObj] = nil end)
                end
            end
        end
    end
end

local function CheckAndServeFood(tycoon)
    if not isRunning or not autoServeEnabled or not GrabFood then return end

    local objectsFolder = tycoon:FindFirstChild("Objects")
    local foodFolder = objectsFolder and objectsFolder:FindFirstChild("Food")
    if not foodFolder then return end

    local canGrab, capacity = GrabFood:CanGrabSomethingIn(tycoon)
    if canGrab and capacity > 0 then
        for _, foodPlate in ipairs(foodFolder:GetChildren()) do
            if not foodPlate:GetAttribute("Taken") then
                GrabFood:AttemptGrab(tycoon, foodPlate)
            end
        end
    end

    local clientCustomers = tycoon:FindFirstChild("ClientCustomers")
    if not clientCustomers then return end

    for _, groupFolder in ipairs(clientCustomers:GetChildren()) do
        local groupId = groupFolder.Name

        for _, customerObj in ipairs(groupFolder:GetChildren()) do
            local customerId = customerObj.Name
            local customerData = Customers:GetCustomerData(tycoon, groupId, customerId)

            if customerData and customerData.State == CustomerState.WaitingForDish then
                local isKid = (customerData.CustomerType == CustomerType.Kid)
                local heldFood = GrabFood:IsHoldingFoodForNPC(customerData.Order, isKid)

                if heldFood then
                    ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
                        Name = TaskEnum.Serve,
                        GroupId = groupId,
                        CustomerId = customerId,
                        FoodModel = heldFood.Model,
                        Tycoon = tycoon
                    })
                    ClearNativeTaskLock()
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Main Background Processing Loop
-- ---------------------------------------------------------------------------
task.spawn(function()
    while isRunning do
        task.wait(0.4)
        pcall(function()
            if not isRunning then return end
            if autoCollectDishesEnabled or autoCollectBillsEnabled or autoTakeOrderEnabled or autoServeEnabled then
                local tycoon = GetLocalTycoon()
                if tycoon then
                    if autoTakeOrderEnabled then
                        CheckDynamicOrders(tycoon)
                    end
                    
                    if autoServeEnabled then
                        CheckAndServeFood(tycoon)
                    end
                    
                    if autoCollectDishesEnabled or autoCollectBillsEnabled then
                        local surfaceFolder = tycoon:FindFirstChild("Items") and tycoon.Items:FindFirstChild("Surface")
                        if surfaceFolder then
                            for _, tableModel in ipairs(GetValidTables(surfaceFolder)) do
                                if not isRunning then break end
                                
                                if autoCollectDishesEnabled then
                                    local trash = tableModel:FindFirstChild("Trash")
                                    if trash and trash:GetAttribute("Collectable") == true then
                                        ProcessDishes(tycoon, tableModel)
                                    end
                                end
                                
                                if autoCollectBillsEnabled then
                                    local hasBill = tableModel:FindFirstChild("Bill", true)
                                    if hasBill then
                                        ProcessBills(tycoon, tableModel)
                                    end
                                end
                            end
                        end
                        
                        local itemsFolder = tycoon:FindFirstChild("Items")
                        if autoCollectBillsEnabled and itemsFolder then
                            for _, descendant in ipairs(itemsFolder:GetDescendants()) do
                                if not isRunning then break end
                                if descendant:IsA("Model") and descendant:GetAttribute("ItemType") == ItemType.TipJar then
                                    ProcessTipJar(tycoon, descendant)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

return {
    Init = function()
        print("[DEBUG] Game called Init().")
    end
}
