-- Script Path: game:GetService("StarterPlayer").StarterPlayerScripts.Source.Modules.Tasks.RestaurantTycoonManager
-- Optimized & Self-Refreshing Silent Master Script

print("[DEBUG] --- LOCAL PLAYER RESTAURANT MANAGER LOADED ---")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

-- Require native systems safely
local successCustomers, Customers = pcall(function() return require(PlayerScripts.Source.Systems.Restaurant.Customers) end)
local successCustomerState, CustomerState = pcall(function() return require(ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerState) end)
local successCustomerType, CustomerType = pcall(function() return require(ReplicatedStorage.Source.Enums.Restaurant.Customer.CustomerType) end)
local successTaskEnum, TaskEnum = pcall(function() return require(ReplicatedStorage.Source.Enums.Restaurant.Task) end)
local successItemType, ItemType = pcall(function() return require(ReplicatedStorage.Source.Enums.Placement.ItemType) end)
local successGrabFood, GrabFood = pcall(function() return require(PlayerScripts.Source.Systems.Restaurant.GrabFood) end)

local isRunning = true

-- All toggles start OFF by default
local autoCollectDishesEnabled = false
local autoCollectBillsEnabled = false
local autoTakeOrderEnabled = false
local autoServeEnabled = false
local autoAssignTableEnabled = false

-- Create Unified Control Panel GUI (5 Toggles + Kill Button)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("RestaurantTycoonManagerUI") then
    playerGui.RestaurantTycoonManagerUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RestaurantTycoonManagerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 235)
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

local function createButton(position, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 24)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(120, 120, 120) -- OFF gray
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
local toggleServeBtn = createButton(UDim2.new(0, 10, 0, 125), "Serve Food: OFF")
local toggleTableBtn = createButton(UDim2.new(0, 10, 0, 155), "Assign Tables: OFF")
local killBtn = createButton(UDim2.new(0, 10, 0, 190), "Kill Script")
killBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)

toggleDishesBtn.MouseButton1Click:Connect(function()
    autoCollectDishesEnabled = not autoCollectDishesEnabled
    toggleDishesBtn.Text = autoCollectDishesEnabled and "Dishes: ON" or "Dishes: OFF"
    toggleDishesBtn.BackgroundColor3 = autoCollectDishesEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
end)

toggleBillsBtn.MouseButton1Click:Connect(function()
    autoCollectBillsEnabled = not autoCollectBillsEnabled
    toggleBillsBtn.Text = autoCollectBillsEnabled and "Bills & Tips: ON" or "Bills & Tips: OFF"
    toggleBillsBtn.BackgroundColor3 = autoCollectBillsEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
end)

toggleOrderBtn.MouseButton1Click:Connect(function()
    autoTakeOrderEnabled = not autoTakeOrderEnabled
    toggleOrderBtn.Text = autoTakeOrderEnabled and "Take Orders: ON" or "Take Orders: OFF"
    toggleOrderBtn.BackgroundColor3 = autoTakeOrderEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
end)

toggleServeBtn.MouseButton1Click:Connect(function()
    autoServeEnabled = not autoServeEnabled
    toggleServeBtn.Text = autoServeEnabled and "Serve Food: ON" or "Serve Food: OFF"
    toggleServeBtn.BackgroundColor3 = autoServeEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
end)

toggleTableBtn.MouseButton1Click:Connect(function()
    autoAssignTableEnabled = not autoAssignTableEnabled
    toggleTableBtn.Text = autoAssignTableEnabled and "Assign Tables: ON" or "Assign Tables: OFF"
    toggleTableBtn.BackgroundColor3 = autoAssignTableEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(120, 120, 120)
end)

killBtn.MouseButton1Click:Connect(function()
    isRunning = false
    screenGui:Destroy()
    print("[DEBUG] Script killed and UI removed.")
end)

-- STRICT Local Player Tycoon Finder
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
    for _, child in ipairs(surfaceFolder:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^T%d+") then
            table.insert(tables, child)
        end
    end
    return tables
end

local function HasNearbyChair(tycoon, tableModel)
    local furnitureFolder = tycoon:FindFirstChild("Items") and tycoon.Items:FindFirstChild("Furniture")
    if not furnitureFolder then return true end

    local tablePos = tableModel:GetPivot().Position

    for _, chairModel in ipairs(furnitureFolder:GetChildren()) do
        if chairModel:IsA("Model") and chairModel.Name:match("^C%d+") then
            local chairPos = chairModel:GetPivot().Position
            if (Vector3.new(tablePos.X, 0, tablePos.Z) - Vector3.new(chairPos.X, 0, chairPos.Z)).Magnitude < 5 then
                return true
            end
        end
    end

    return false
end

local processedTrash = {}
local processedBills = {}
local processedTipJars = {}
local processedOrders = {}
local processedAssignments = {}
local tableFailCounts = {}

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
    
    task.delay(2, function() processedTrash[trash] = nil end)
end

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

    task.delay(2, function() processedBills[billObj] = nil end)
end

local function ProcessTipJar(tycoon, tipJarModel)
    if not isRunning or not autoCollectBillsEnabled then return end
    local tipValue = tipJarModel:GetAttribute("Value") or 0
    if tipValue <= 0 or processedTipJars[tipJarModel] then return end

    processedTipJars[tipJarModel] = true
    ReplicatedStorage.Events.Restaurant.TipsCollected:FireServer(tycoon)

    task.delay(3, function() processedTipJars[tipJarModel] = nil end)
end

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

                    task.delay(3, function() processedOrders[customerObj] = nil end)
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
                end
            end
        end
    end
end

local function CheckAndAssignTables(tycoon)
    if not isRunning or not autoAssignTableEnabled then return end

    local clientCustomers = tycoon:FindFirstChild("ClientCustomers")
    local surfaceFolder = tycoon:FindFirstChild("Items") and tycoon.Items:FindFirstChild("Surface")
    if not clientCustomers or not surfaceFolder then return end

    for _, groupFolder in ipairs(clientCustomers:GetChildren()) do
        if not autoAssignTableEnabled then break end
        local groupId = groupFolder.Name

        if Customers:GetGroupState(tycoon, groupId) == CustomerState.Entered and not processedAssignments[groupId] then
            local availableTable = nil
            
            for _, tableModel in ipairs(GetValidTables(surfaceFolder)) do
                if not tableFailCounts[tableModel] then
                    local hasCustomers = tableModel:FindFirstChild("Customers") and #tableModel.Customers:GetChildren() > 0
                    local trashObj = tableModel:FindFirstChild("Trash")
                    local hasTrash = trashObj and trashObj:GetAttribute("Collectable") == true
                    local billObj = tableModel:FindFirstChild("Bill", true)
                    local hasUncollectedBill = billObj and billObj:GetAttribute("Taken") ~= true
                    local isOccupiedByAttr = tableModel:GetAttribute("Occupied") == true or tableModel:GetAttribute("GroupId") ~= nil
                    local hasChairNearby = HasNearbyChair(tycoon, tableModel)

                    if not hasCustomers and not hasTrash and not hasUncollectedBill and not isOccupiedByAttr and hasChairNearby then
                        availableTable = tableModel
                        break
                    end
                end
            end

            if availableTable then
                processedAssignments[groupId] = true
                ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
                    Name = TaskEnum.SendToTable,
                    GroupId = groupId,
                    FurnitureModel = availableTable,
                    Tycoon = tycoon
                })

                task.delay(1.5, function()
                    if Customers:GetGroupState(tycoon, groupId) == CustomerState.Entered then
                        tableFailCounts[availableTable] = (tableFailCounts[availableTable] or 0) + 1
                        if tableFailCounts[availableTable] >= 2 then
                            task.delay(10, function() tableFailCounts[availableTable] = nil end)
                        end
                    else
                        tableFailCounts[availableTable] = nil
                    end
                end)

                task.delay(4, function() processedAssignments[groupId] = nil end)
                break
            else
                processedAssignments[groupId] = true
                task.delay(2, function() processedAssignments[groupId] = nil end)
            end
        end
    end
end

-- Self-Refreshing & Error-Protected Background Loop
task.spawn(function()
    print("[DEBUG] Local Player manager loop started!")
    while isRunning do
        task.wait(0.3)
        
        -- Wrap execution in pcall to guarantee self-refreshing stability on error
        pcall(function()
            if autoCollectDishesEnabled or autoCollectBillsEnabled or autoTakeOrderEnabled or autoServeEnabled or autoAssignTableEnabled then
                local tycoon = GetLocalTycoon()
                if tycoon then
                    if autoAssignTableEnabled then
                        CheckAndAssignTables(tycoon)
                    end

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
    print("[DEBUG] Local Player manager loop terminated.")
end)

return {
    Init = function()
        print("[DEBUG] Game called Init().")
    end
}
