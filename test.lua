-- ⚡ W89K'S JOINER - VERSION CLEAN
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Interface
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "W89kJoiner"
screenGui.ResetOnSpawn = false
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 140)
mainFrame.Position = UDim2.new(0.5, -180, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡w89k's Joiner"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 35)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⚡ Ready to find servers!"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- Server Info
local serverInfoLabel = Instance.new("TextLabel")
serverInfoLabel.Size = UDim2.new(1, -20, 0, 40)
serverInfoLabel.Position = UDim2.new(0, 10, 0, 55)
serverInfoLabel.BackgroundTransparency = 1
serverInfoLabel.Text = "🌶️ Scanning for available servers..."
serverInfoLabel.TextColor3 = Color3.fromRGB(150, 255, 200)
serverInfoLabel.TextSize = 10
serverInfoLabel.Font = Enum.Font.RobotoMono
serverInfoLabel.TextWrapped = true
serverInfoLabel.Parent = mainFrame

-- Main Control Button
local autoHopButton = Instance.new("TextButton")
autoHopButton.Size = UDim2.new(1, -20, 0, 35)
autoHopButton.Position = UDim2.new(0, 10, 0, 95)
autoHopButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
autoHopButton.BorderSizePixel = 0
autoHopButton.Text = "⚡ START AUTO-JOIN"
autoHopButton.TextColor3 = Color3.fromRGB(0, 0, 0)
autoHopButton.TextSize = 14
autoHopButton.Font = Enum.Font.GothamBold
autoHopButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = autoHopButton

-- Variables
local autoMode = false
local checkDelay = 3
local currentJobId = ""
local lastJobId = game.JobId
local triedJobIds = {}

-- Fonctions
local function updateStatus(text, color)
    statusLabel.Text = text
    if color then statusLabel.TextColor3 = color end
    print("⚡ " .. text)
end

local function updateServerInfo(name, players, money, jobId)
    currentJobId = jobId or ""
    local displayJobId = jobId and jobId:sub(1, 8) .. "..." or "No Job ID"
    serverInfoLabel.Text = "🏷️ " .. (name or "Unknown") .. " | 💰 " .. (money or "?") .. " | 👥 " .. (players or "?") .. "\n🆔 " .. displayJobId
end

-- FONCTION API CHILLI
local function fetchChilliServer()
    updateStatus("🌶️ Scanning Chilli servers...", Color3.fromRGB(255, 215, 0))
    
    local attempts = 0
    while attempts < 3 do
        attempts = attempts + 1
        
        local success, result = pcall(function()
            return game:HttpGet("http://51.68.234.157:20046/last-message")
        end)
        
        if success then
            local success2, data = pcall(function()
                return HttpService:JSONDecode(result)
            end)
            
            if success2 and data.success and data.message and data.message.embeds then
                local embed = data.message.embeds[1]
                if embed and embed.fields then
                    local serverData = {
                        name = "Unknown",
                        players = "?/?",
                        money = "Unknown",
                        jobId = nil
                    }
                    
                    -- Parse fields
                    for _, field in pairs(embed.fields) do
                        if field.name and field.value then
                            if field.name:find("Name") then
                                serverData.name = field.value:gsub("%*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                            elseif field.name:find("Money") then
                                serverData.money = field.value:gsub("%*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                            elseif field.name:find("Players") then
                                serverData.players = field.value:gsub("%*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                            elseif field.name:find("Job ID") and not field.name:find("Mobile") and not field.name:find("Script") then
                                local jobId = field.value:gsub("```", ""):gsub("^%s+", ""):gsub("%s+$", "")
                                if jobId and jobId:len() > 10 and not jobId:find("game:GetService") then
                                    serverData.jobId = jobId
                                end
                            end
                        end
                    end
                    
                    if serverData.jobId and serverData.jobId ~= lastJobId and not triedJobIds[serverData.jobId] then
                        return serverData
                    end
                end
            end
        end
        
        if attempts < 3 then
            wait(1)
        end
    end
    
    return nil
end

-- FONCTION JOIN AVEC RETRY
local function smartJoinWithRetry()
    local maxAttempts = 5
    local attemptCount = 0
    
    while attemptCount < maxAttempts and autoMode do
        attemptCount = attemptCount + 1
        updateStatus("🔄 Attempt " .. attemptCount .. "/" .. maxAttempts .. "...", Color3.fromRGB(100, 200, 255))
        
        local serverData = fetchChilliServer()
        
        if serverData and serverData.jobId then
            updateServerInfo(serverData.name, serverData.players, serverData.money, serverData.jobId)
            updateStatus("⚡ Joining " .. serverData.name .. "...", Color3.fromRGB(255, 215, 0))
            
            triedJobIds[serverData.jobId] = true
            
            local teleportSuccess, teleportError = pcall(function()
                TeleportService:TeleportToPlaceInstance(109983668079237, serverData.jobId, Players.LocalPlayer)
            end)
            
            if teleportSuccess then
                updateStatus("✅ TELEPORT INITIATED!", Color3.fromRGB(100, 255, 100))
                
                -- Attendre pour vérifier le succès
                for i = 1, 5 do
                    wait(1)
                    if game.JobId ~= lastJobId then
                        updateStatus("🎉 SUCCESSFULLY JOINED!", Color3.fromRGB(100, 255, 100))
                        return true
                    end
                end
                
                updateStatus("⚠️ Server may be full, trying next...", Color3.fromRGB(255, 200, 100))
            else
                updateStatus("❌ Teleport failed, trying next...", Color3.fromRGB(255, 100, 100))
            end
        else
            updateStatus("❌ No valid server found, retrying...", Color3.fromRGB(255, 150, 100))
        end
        
        if attemptCount < maxAttempts then
            wait(2)
        end
    end
    
    updateStatus("❌ All attempts failed. Retrying in next cycle...", Color3.fromRGB(255, 100, 100))
    return false
end

local function autoLoop()
    spawn(function()
        while autoMode do
            updateStatus("🌶️ Starting server hunt...", Color3.fromRGB(255, 215, 0))
            
            -- Nettoyer les vieux Job IDs
            local triedCount = 0
            for _ in pairs(triedJobIds) do triedCount = triedCount + 1 end
            if triedCount > 20 then
                triedJobIds = {}
                updateStatus("🧹 Cleared old servers", Color3.fromRGB(200, 200, 200))
            end
            
            -- Essayer de join
            if smartJoinWithRetry() then
                break
            end
            
            -- Countdown
            for i = checkDelay, 1, -1 do
                if not autoMode then break end
                updateStatus("⏱️ Next scan in " .. i .. "s...", Color3.fromRGB(200, 200, 255))
                wait(1)
            end
        end
    end)
end

-- Events
autoHopButton.MouseButton1Click:Connect(function()
    autoMode = not autoMode
    
    if autoMode then
        autoHopButton.Text = "⏸️ STOP AUTO-JOIN"
        autoHopButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        autoHopButton.TextColor3 = Color3.new(1, 1, 1)
        
        updateStatus("⚡ AUTO-JOIN STARTED!", Color3.fromRGB(255, 215, 0))
        autoLoop()
        
    else
        autoHopButton.Text = "⚡ START AUTO-JOIN"
        autoHopButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        autoHopButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        updateStatus("⏸️ Auto-join stopped", Color3.fromRGB(255, 150, 150))
    end
end)

-- Initialize
spawn(function()
    wait(1)
    updateStatus("⚡ w89k's Joiner ready!", Color3.fromRGB(255, 215, 0))
    
    -- Test initial
    spawn(function()
        wait(2)
        updateStatus("🧪 Testing connection...", Color3.fromRGB(255, 200, 100))
        local serverData = fetchChilliServer()
        if serverData then
            updateServerInfo(serverData.name, serverData.players, serverData.money, serverData.jobId)
            updateStatus("✅ Connected! Found: " .. serverData.name, Color3.fromRGB(100, 255, 100))
        else
            updateStatus("⚡ Ready to scan for servers!", Color3.fromRGB(255, 215, 0))
        end
    end)
end)

print("⚡ w89k's Joiner loaded successfully!")
