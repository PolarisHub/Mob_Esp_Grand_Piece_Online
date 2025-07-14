local Players     = cloneref(game:GetService("Players"))
local RunService  = cloneref(game:GetService("RunService"))
local TextService = game:GetService("TextService")
local Teams       = game:GetService("Teams")

local ESPLibrary = {}

-- Configuration settings
ESPLibrary.Settings = {
    Enabled = true,
    Box = {
        Enabled = true,
        ShowCorners = true,
        ShowSides = true,
        UseTeamColor = false,
        DefaultColor = Color3.fromRGB(0, 200, 200)
    },
    Text = {
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true,
        UseTeamColor = false,
        DefaultColor = Color3.new(1, 1, 1)
    },
    Highlight = {
        Enabled = true,
        UseTeamColor = false,
        DefaultFillColor = Color3.fromRGB(100, 100, 100),
        DefaultOutlineColor = Color3.fromRGB(0, 200, 200)
    }
}

ESPLibrary.ExistantPlayers = {}
ESPLibrary.RunningThreads = {}
ESPLibrary.CustomInstances = {}
ESPLibrary.CustomThreads = {}
ESPLibrary.XenithESP = nil

---------------------------------------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------------------------------------
function ESPLibrary.CreateInstance(className, props)
    if typeof(className) ~= "string" then return end
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

function ESPLibrary.GetTeamColor(player)
    if player and player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return ESPLibrary.Settings.Box.DefaultColor
end

function ESPLibrary.LerpColorSequence(a, b, alpha)
    local keys = {}
    for i = 1, #a.Keypoints do
        local ak, bk = a.Keypoints[i], b.Keypoints[i]
        keys[i] = ColorSequenceKeypoint.new(ak.Time, ak.Value:Lerp(bk.Value, alpha))
    end
    return ColorSequence.new(keys)
end

---------------------------------------------------------------------------------------------------
-- Individual Instance ESP Creation
---------------------------------------------------------------------------------------------------
function ESPLibrary:AddInstance(folder, part, settings, name)
    if not part or not part.Parent then
        warn("ESPLibrary: Invalid part provided to AddInstance")
        return nil
    end
    
    -- Default settings if not provided
    local defaultSettings = {
        name = true,
        distance = true,
        health = false,
        box = true,
        corners = true,
        sides = true,
        highlight = true,
        teamColor = false,
        customName = name or part.Name,
        boxColor = Color3.fromRGB(0, 200, 200),
        textColor = Color3.new(1, 1, 1),
        highlightFillColor = Color3.fromRGB(100, 100, 100),
        highlightOutlineColor = Color3.fromRGB(0, 200, 200)
    }
    
    -- Merge provided settings with defaults
    if settings then
        for key, value in pairs(settings) do
            defaultSettings[key] = value
        end
    end
    
    local instanceId = part:GetDebugId() .. "_" .. tostring(tick())
    
    -- Create ESP data structure
    local data = {
        Part = part,
        Settings = defaultSettings,
        Folder = folder,
        InstanceId = instanceId
    }
    
    -- Create the ESP components
    ESPLibrary.CreateCustomESPComponents(data)
    ESPLibrary.RenderCustomESP(data)
    
    -- Store the instance
    ESPLibrary.CustomInstances[instanceId] = data
    
    -- Return the ESP object for manipulation
    return {
        Id = instanceId,
        Part = part,
        Data = data,
        
        -- Methods to control this specific ESP instance
        SetName = function(self, newName)
            data.Settings.customName = newName
        end,
        
        SetBoxColor = function(self, color)
            data.Settings.boxColor = color
            ESPLibrary.UpdateCustomInstanceColors(data)
        end,
        
        SetTextColor = function(self, color)
            data.Settings.textColor = color
            ESPLibrary.UpdateCustomInstanceColors(data)
        end,
        
        ToggleBox = function(self, state)
            data.Settings.box = state
            if data.MainFrame then
                data.MainFrame.Visible = state
            end
        end,
        
        ToggleHighlight = function(self, state)
            data.Settings.highlight = state
            if data.Highlight then
                data.Highlight.Enabled = state
            end
        end,
        
        ToggleName = function(self, state)
            data.Settings.name = state
            ESPLibrary.UpdateCustomInstanceText(data)
        end,
        
        ToggleDistance = function(self, state)
            data.Settings.distance = state
            ESPLibrary.UpdateCustomInstanceText(data)
        end,
        
        Destroy = function(self)
            ESPLibrary:RemoveInstance(instanceId)
        end
    }
end

function ESPLibrary:RemoveInstance(instanceId)
    local data = ESPLibrary.CustomInstances[instanceId]
    if not data then return end
    
    -- Clean up UI components
    if data.MainFrame then data.MainFrame:Destroy() end
    if data.Highlight then data.Highlight:Destroy() end
    
    -- Clean up threads
    if ESPLibrary.CustomThreads[instanceId] then
        ESPLibrary.CustomThreads[instanceId]:Disconnect()
        ESPLibrary.CustomThreads[instanceId] = nil
    end
    
    -- Remove from storage
    ESPLibrary.CustomInstances[instanceId] = nil
end

function ESPLibrary.CreateCustomESPComponents(data)
    local part = data.Part
    local settings = data.Settings
    
    -- Main container
    local frame = ESPLibrary.CreateInstance("Frame", {
        Parent               = data.Folder or ESPLibrary.XenithESP,
        Name                 = settings.customName.."_ESP",
        BackgroundColor3     = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.8,
        AnchorPoint          = Vector2.new(0.5,0.5),
        Size                 = UDim2.new(0,180,0,250),
        Visible              = false,
    })
    data.MainFrame = frame
    ESPLibrary.CreateInstance("UICorner", {Parent = frame, CornerRadius = UDim.new(0,1)})

    -- Frame stroke
    local frameStroke = ESPLibrary.CreateInstance("UIStroke", {
        Parent    = frame,
        Color     = settings.boxColor,
        Thickness = 1,
    })
    data.FrameStroke = frameStroke

    -- Box gradient
    local boxGrad = ESPLibrary.CreateInstance("UIGradient", {
        Parent = frame,
        Color  = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200,0,0)),
        }
    })
    data.UIGradientMainFrame = boxGrad

    -- Corner boxes (only if enabled)
    if settings.corners then
        local corners = {
            { "CornerTL", UDim2.new(0.015,0,0.010,0), UDim2.new(0,0,0,0), Vector2.new(0,0) },
            { "CornerBL", UDim2.new(0.015,0,0.010,0), UDim2.new(0,0,1,0), Vector2.new(0,1) },
            { "CornerTR", UDim2.new(0.015,0,0.010,0), UDim2.new(1,0,0,0), Vector2.new(1,0) },
            { "CornerBR", UDim2.new(0.015,0,0.010,0), UDim2.new(1,0,1,0), Vector2.new(1,1) },
        }
        for _, info in ipairs(corners) do
            local name, size, pos, anchor = unpack(info)
            local box = ESPLibrary.CreateInstance("Frame", {
                Parent            = frame,
                Name              = name,
                Size              = size,
                Position          = pos,
                AnchorPoint       = anchor,
                ZIndex            = 3,
                BackgroundColor3  = settings.boxColor,
                Visible           = settings.corners,
            })
            ESPLibrary.CreateInstance("UIStroke", {Parent = box, Color = Color3.new(0,0,0), Thickness = 0.6})
            data[name] = box
        end
    end

    -- Side bars (only if enabled)
    if settings.sides then
        local sides = {
            { "SideTL_H", UDim2.new(0.1,0,0.01,0), UDim2.new(0,0,0,0), Vector2.new(0,0) },
            { "SideTL_V", UDim2.new(0.01,0,0.1,0), UDim2.new(0,0,0,0), Vector2.new(0,0) },
            { "SideTR_H", UDim2.new(0.1,0,0.01,0), UDim2.new(1,0,0,0), Vector2.new(1,0) },
            { "SideTR_V", UDim2.new(0.01,0,0.1,0), UDim2.new(1,0,0,0), Vector2.new(1,0) },
            { "SideBL_H", UDim2.new(0.1,0,0.01,0), UDim2.new(0,0,1,0), Vector2.new(0,1) },
            { "SideBL_V", UDim2.new(0.01,0,0.1,0), UDim2.new(0,0,1,0), Vector2.new(0,1) },
            { "SideBR_H", UDim2.new(0.1,0,0.01,0), UDim2.new(1,0,1,0), Vector2.new(1,1) },
            { "SideBR_V", UDim2.new(0.01,0,0.1,0), UDim2.new(1,0,1,0), Vector2.new(1,1) },
        }
        for _, info in ipairs(sides) do
            local name, size, pos, anchor = unpack(info)
            local bar = ESPLibrary.CreateInstance("Frame", {
                Parent            = frame,
                Name              = name,
                Size              = size,
                Position          = pos,
                AnchorPoint       = anchor,
                ZIndex            = 2,
                BackgroundColor3  = settings.boxColor,
                Visible           = settings.sides,
            })
            ESPLibrary.CreateInstance("UIStroke", {Parent = bar, Color = Color3.new(0,0,0), Thickness = 0.6})
            data[name] = bar
        end
    end

    -- Text label + gradient
    local nameLabel = ESPLibrary.CreateInstance("TextLabel", {
        Parent                 = frame,
        Name                   = "NameLabel",
        BackgroundTransparency = 1,
        Text                   = "",
        TextColor3             = settings.textColor,
        TextStrokeTransparency = 0.6,
        Font                   = Enum.Font.Code,
        TextWrapped            = false,
        TextScaled             = false,
        AutomaticSize          = Enum.AutomaticSize.None,
        AnchorPoint            = Vector2.new(0.5,1),
        Position               = UDim2.new(0.5,0,0,-4),
        ZIndex                 = 10,
    })
    data.NameLabel = nameLabel

    local textGrad = ESPLibrary.CreateInstance("UIGradient", {
        Parent = nameLabel,
        Color  = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
        }
    })
    data.TextGradient = textGrad

    -- Highlight (only if enabled)
    if settings.highlight then
        local highlight = ESPLibrary.CreateInstance("Highlight", {
            Parent            = workspace,
            Adornee           = part,
            FillColor         = settings.highlightFillColor,
            OutlineColor      = settings.highlightOutlineColor,
            FillTransparency  = 0.7,
            OutlineTransparency = 0.5,
            Enabled           = settings.highlight,
        })
        data.Highlight = highlight
    end

    -- Animation loop
    task.spawn(function()
        local baseColor      = settings.boxColor
        local midColor       = baseColor:Lerp(Color3.new(1,1,1), 0.3)
        local highlightColor = baseColor:Lerp(Color3.new(1,1,1), 0.6)

        local pulseSpeed     = 0.4
        local minAlpha       = 0.35
        local maxAlpha       = 0.75

        while frame.Parent do
            local t     = tick()
            local pulse = (math.sin(t * pulseSpeed * math.pi * 2) + 1) / 2

            if not settings.teamColor then
                boxGrad.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, baseColor),
                    ColorSequenceKeypoint.new(0.5, midColor),
                    ColorSequenceKeypoint.new(1, highlightColor),
                }

                frame.BackgroundColor3      = baseColor:Lerp(midColor, pulse * 0.5)
                frame.BackgroundTransparency = 1 - (minAlpha + (maxAlpha - minAlpha)*pulse)

                frameStroke.Color        = midColor
                frameStroke.Transparency = 0.4 + 0.3*(1-pulse)

                for _, child in pairs(data) do
                    if typeof(child)=="Instance" and child:IsA("Frame") and child~=frame then
                        child.BackgroundColor3 = highlightColor:Lerp(baseColor, pulse*0.5)
                        local stroke = child:FindFirstChildOfClass("UIStroke")
                        if stroke then
                            stroke.Color        = baseColor
                            stroke.Transparency = 0.5 + 0.3*pulse
                        end
                    end
                end
            end

            if data.TextGradient then
                data.TextGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, midColor),
                    ColorSequenceKeypoint.new(1, highlightColor),
                }
                data.NameLabel.TextColor3 = highlightColor:Lerp(midColor, pulse)
            end

            if data.Highlight and not settings.teamColor then
                data.Highlight.FillColor           = midColor
                data.Highlight.OutlineColor        = highlightColor
                data.Highlight.FillTransparency    = minAlpha + (maxAlpha - minAlpha) * (1-pulse) * 0.5
                data.Highlight.OutlineTransparency = 0.2 + 0.5 * (1-pulse)
            end
            
            task.wait(0.01)
        end
    end)
    
    -- Update initial text
    ESPLibrary.UpdateCustomInstanceText(data)
end

function ESPLibrary.UpdateCustomInstanceColors(data)
    local settings = data.Settings
    
    -- Update frame stroke
    if data.FrameStroke then
        data.FrameStroke.Color = settings.boxColor
    end
    
    -- Update corners and sides
    for _, cornerName in ipairs({"CornerTL", "CornerBL", "CornerTR", "CornerBR"}) do
        if data[cornerName] then
            data[cornerName].BackgroundColor3 = settings.boxColor
        end
    end
    
    for _, sideName in ipairs({"SideTL_H", "SideTL_V", "SideTR_H", "SideTR_V", "SideBL_H", "SideBL_V", "SideBR_H", "SideBR_V"}) do
        if data[sideName] then
            data[sideName].BackgroundColor3 = settings.boxColor
        end
    end
    
    -- Update text color
    if data.NameLabel then
        data.NameLabel.TextColor3 = settings.textColor
    end
    
    -- Update highlight colors
    if data.Highlight then
        data.Highlight.OutlineColor = settings.highlightOutlineColor
        data.Highlight.FillColor = settings.highlightFillColor
    end
end

function ESPLibrary.UpdateCustomInstanceText(data)
    if not data.NameLabel then return end
    
    local settings = data.Settings
    local part = data.Part
    local textParts = {}
    
    if settings.name then
        table.insert(textParts, settings.customName)
    end
    
    if settings.distance then
        local cam = workspace.CurrentCamera
        if cam and part then
            local partPos = part.Position
            if part:IsA("Model") then
                local primaryPart = part.PrimaryPart or part:FindFirstChild("HumanoidRootPart") or part:FindFirstChildOfClass("BasePart")
                if primaryPart then
                    partPos = primaryPart.Position
                end
            end
            local dist = (cam.CFrame.Position - partPos).Magnitude
            table.insert(textParts, string.format("[%d]", math.round(dist)))
        end
    end
    
    if settings.health then
        -- Try to find humanoid for health (useful for NPCs/Models)
        if part:IsA("Model") then
            local humanoid = part:FindFirstChild("Humanoid")
            if humanoid then
                local hpPct = humanoid.Health / humanoid.MaxHealth
                table.insert(textParts, string.format("[%d%%]", math.floor(hpPct * 100)))
            end
        end
    end
    
    data.NameLabel.Text = table.concat(textParts, " / ")
end

function ESPLibrary.RenderCustomESP(data)
    local part = data.Part
    local settings = data.Settings
    
    ESPLibrary.CustomThreads[data.InstanceId] = RunService.RenderStepped:Connect(function()
        if not settings.box then
            data.MainFrame.Visible = false
            return
        end
        
        if not part or not part.Parent then
            data.MainFrame.Visible = false
            return
        end
        
        local cam = workspace.CurrentCamera
        local frame = data.MainFrame
        
        -- Get part position
        local partPos = part.Position
        if part:IsA("Model") then
            local primaryPart = part.PrimaryPart or part:FindFirstChild("HumanoidRootPart") or part:FindFirstChildOfClass("BasePart")
            if primaryPart then
                partPos = primaryPart.Position
            end
        end
        
        local screenPt, onScreen = cam:WorldToScreenPoint(partPos)
        if not onScreen then 
            frame.Visible = false 
            return 
        end
        
        frame.Visible = true
        frame.Position = UDim2.new(0, screenPt.X, 0, screenPt.Y)

        -- Box sizing
        local dist = (cam.CFrame.Position - partPos).Magnitude
        local scaleFact = math.clamp(1 - (dist/60), 0, .2)
        local sizeBase = 4.5 + 4.5 * scaleFact
        local w = sizeBase * cam.ViewportSize.Y / (screenPt.Z * 1.7)
        local h = w * 1.5
        frame.Size = UDim2.new(0, w, 0, h)

        -- Update text
        ESPLibrary.UpdateCustomInstanceText(data)
        
        -- Text sizing
        local lbl = data.NameLabel
        local sf = math.clamp(30 / math.max(dist,0.1), .5, 1.5)
        local bounds = TextService:GetTextSize(lbl.Text, 24, lbl.Font, Vector2.new(1e5,1e5))
        lbl.Size = UDim2.new(0, math.clamp(bounds.X*sf,120,240),
                             0, math.clamp(bounds.Y*sf,24,48))
        lbl.TextSize = 24 * sf
    end)
end

---------------------------------------------------------------------------------------------------
-- Original Player ESP Functions (keeping existing functionality)
---------------------------------------------------------------------------------------------------

-- Toggle Functions
function ESPLibrary:ToggleESP(state)
    self.Settings.Enabled = state
    if self.XenithESP then
        self.XenithESP.Enabled = state
    end
end

function ESPLibrary:ToggleBox(state)
    self.Settings.Box.Enabled = state
    for _, data in pairs(self.ExistantPlayers) do
        if data.MainFrame then
            data.MainFrame.Visible = state and data.MainFrame.Visible
        end
    end
end

function ESPLibrary:ToggleCorners(state)
    self.Settings.Box.ShowCorners = state
    for _, data in pairs(self.ExistantPlayers) do
        for _, cornerName in ipairs({"CornerTL", "CornerBL", "CornerTR", "CornerBR"}) do
            if data[cornerName] then
                data[cornerName].Visible = state and self.Settings.Box.Enabled
            end
        end
    end
end

function ESPLibrary:ToggleSides(state)
    self.Settings.Box.ShowSides = state
    for _, data in pairs(self.ExistantPlayers) do
        for _, sideName in ipairs({"SideTL_H", "SideTL_V", "SideTR_H", "SideTR_V", "SideBL_H", "SideBL_V", "SideBR_H", "SideBR_V"}) do
            if data[sideName] then
                data[sideName].Visible = state and self.Settings.Box.Enabled
            end
        end
    end
end

function ESPLibrary:ToggleBoxTeamColor(state)
    self.Settings.Box.UseTeamColor = state
    self:UpdateAllColors()
end

function ESPLibrary:ToggleTextTeamColor(state)
    self.Settings.Text.UseTeamColor = state
    self:UpdateAllColors()
end

function ESPLibrary:ToggleHighlight(state)
    self.Settings.Highlight.Enabled = state
    for _, data in pairs(self.ExistantPlayers) do
        if data.Highlight then
            data.Highlight.Enabled = state
        end
    end
end

function ESPLibrary:ToggleHighlightTeamColor(state)
    self.Settings.Highlight.UseTeamColor = state
    self:UpdateAllColors()
end

function ESPLibrary:ToggleName(state)
    self.Settings.Text.ShowName = state
    self:UpdateAllText()
end

function ESPLibrary:ToggleHealth(state)
    self.Settings.Text.ShowHealth = state
    self:UpdateAllText()
end

function ESPLibrary:ToggleDistance(state)
    self.Settings.Text.ShowDistance = state
    self:UpdateAllText()
end

function ESPLibrary:UpdateAllColors()
    for player, data in pairs(self.ExistantPlayers) do
        self:UpdatePlayerColors(player, data)
    end
end

function ESPLibrary:UpdateAllText()
    for player, data in pairs(self.ExistantPlayers) do
        self:UpdatePlayerText(player, data)
    end
end

function ESPLibrary:UpdatePlayerColors(player, data)
    local teamColor = self:GetTeamColor(player)
    
    -- Update box colors
    if self.Settings.Box.UseTeamColor then
        if data.FrameStroke then
            data.FrameStroke.Color = teamColor
        end
        
        -- Update corners and sides
        for _, cornerName in ipairs({"CornerTL", "CornerBL", "CornerTR", "CornerBR"}) do
            if data[cornerName] then
                data[cornerName].BackgroundColor3 = teamColor
            end
        end
        
        for _, sideName in ipairs({"SideTL_H", "SideTL_V", "SideTR_H", "SideTR_V", "SideBL_H", "SideBL_V", "SideBR_H", "SideBR_V"}) do
            if data[sideName] then
                data[sideName].BackgroundColor3 = teamColor
            end
        end
    end
    
    -- Update text colors
    if self.Settings.Text.UseTeamColor and data.NameLabel then
        data.NameLabel.TextColor3 = teamColor
    end
    
    -- Update highlight colors
    if self.Settings.Highlight.UseTeamColor and data.Highlight then
        data.Highlight.OutlineColor = teamColor
        data.Highlight.FillColor = teamColor
    end
end

function ESPLibrary:UpdatePlayerText(player, data)
    if not data.NameLabel then return end
    
    local textParts = {}
    
    if self.Settings.Text.ShowHealth then
        local chr = player.Character
        if chr then
            local hum = chr:FindFirstChild("Humanoid")
            if hum then
                local hpPct = hum.Health / hum.MaxHealth
                table.insert(textParts, string.format("[%d%%]", math.floor(hpPct * 100)))
            end
        end
    end
    
    if self.Settings.Text.ShowName then
        table.insert(textParts, player.Name)
    end
    
    if self.Settings.Text.ShowDistance then
        local chr = player.Character
        if chr then
            local hrp = chr:FindFirstChild("HumanoidRootPart")
            if hrp then
                local cam = workspace.CurrentCamera
                local dist = (cam.CFrame.Position - hrp.Position).Magnitude
                table.insert(textParts, string.format("[%d]", math.round(dist)))
            end
        end
    end
    
    data.NameLabel.Text = table.concat(textParts, " / ")
end

function ESPLibrary.CreateESPComponents(plr)
    if ESPLibrary.ExistantPlayers[plr] then return end
    ESPLibrary.ExistantPlayers[plr] = {}
    local data = ESPLibrary.ExistantPlayers[plr]

    -- Main container
    local frame = ESPLibrary.CreateInstance("Frame", {
        Parent               = ESPLibrary.XenithESP,
        Name                 = plr.Name.."_ESP",
        BackgroundColor3     = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.8,
        AnchorPoint          = Vector2.new(0.5,0.5),
        Size                 = UDim2.new(0,180,0,250),
        Visible              = false,
    })
    data.MainFrame = frame
    ESPLibrary.CreateInstance("UICorner", {Parent = frame, CornerRadius = UDim.new(0,1)})

    -- Frame stroke
    local frameStroke = ESPLibrary.CreateInstance("UIStroke", {
        Parent    = frame,
        Color     = ESPLibrary.Settings.Box.UseTeamColor and ESPLibrary.GetTeamColor(plr) or ESPLibrary.Settings.Box.DefaultColor,
        Thickness = 1,
    })
    data.FrameStroke = frameStroke

    -- Box gradient
    local boxGrad = ESPLibrary.CreateInstance("UIGradient", {
        Parent = frame,
        Color  = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200,0,0)),
        }
    })
    data.UIGradientMainFrame = boxGrad

    -- Corner boxes
    local corners = {
        { "CornerTL", UDim2.new(0.015,0,0.010,0), UDim2.new(0,0,0,0), Vector2.new(0,0) },
        { "CornerBL", UDim2.new(0.015,0,0.010,0), UDim2.new(0,0,1,0), Vector2.new(0,1) },
        { "CornerTR", UDim2.new(0.015,0,0.010,0), UDim2.new(1,0,0,0), Vector2.new(1,0) },
        { "CornerBR", UDim2.new(0.015,0,0.010,0), UDim2.new(1,0,1,0), Vector2.new(1,1) },
    }
    for _, info in ipairs(corners) do
        local name, size, pos, anchor = unpack(info)
        local box = ESPLibrary.CreateInstance("Frame", {
            Parent            = frame,
            Name              = name,
            Size              = size,
            Position          = pos,
            AnchorPoint       = anchor,
            ZIndex            = 3,
            BackgroundColor3  = ESPLibrary.Settings.Box.UseTeamColor and ESPLibrary.GetTeamColor(plr) or ESPLibrary.Settings.Box.DefaultColor,
            Visible           = ESPLibrary.Settings.Box.ShowCorners,
        })
        ESPLibrary.CreateInstance("UIStroke", {Parent = box, Color = Color3.new(0,0,0), Thickness = 0.6})
        data[name] = box
    end

    -- Side bars
    local sides = {
        { "SideTL_H", UDim2.new(0.1,0,0.01,0), UDim2.new(0,0,0,0), Vector2.new(0,0) },
        { "SideTL_V", UDim2.new(0.01,0,0.1,0), UDim2.new(0,0,0,0), Vector2.new(0,0) },
        { "SideTR_H", UDim2.new(0.1,0,0.01,0), UDim2.new(1,0,0,0), Vector2.new(1,0) },
        {
