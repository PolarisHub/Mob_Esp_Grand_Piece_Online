local Players     = cloneref(game:GetService("Players"))
local RunService  = cloneref(game:GetService("RunService"))
local TextService = game:GetService("TextService")
local Teams       = game:GetService("Teams")

local ESPLibrary = {}

-- Configuration settings
ESPLibrary.Settings = {
    Enabled = false,
    FontSize = 24,
    Box = {
        Enabled = false,
        ShowCorners = false,
        ShowSides = false,
        UseTeamColor = false,
        DefaultColor = Color3.fromRGB(0, 200, 200)
    },
    Text = {
        ShowName = false,
        ShowHealth = false,
        ShowDistance = false,
        UseTeamColor = false,
        DefaultColor = Color3.new(1, 1, 1)
    },
    Highlight = {
        Enabled = false,
        UseTeamColor = false,
        DefaultFillColor = Color3.fromRGB(100, 100, 100),
        DefaultOutlineColor = Color3.fromRGB(0, 200, 200)
    }
}

ESPLibrary.ExistantPlayers = {}
ESPLibrary.RunningThreads = {}
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
    if player.Team and player.Team.TeamColor then
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
-- Toggle Functions
---------------------------------------------------------------------------------------------------
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
            -- Use transparency instead of visibility to keep text visible
            if state then 
                data.MainFrame.BackgroundTransparency = 0.8
                if data.FrameStroke then
                    data.FrameStroke.Transparency = 0
                end
            else
                data.MainFrame.BackgroundTransparency = 1
                if data.FrameStroke then
                    data.FrameStroke.Transparency = 1
                end
            end
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
    
    -- Show text if any text options are enabled
    local showText = self.Settings.Text.ShowName or self.Settings.Text.ShowHealth or self.Settings.Text.ShowDistance
    if showText and #textParts > 0 then
        data.NameLabel.Text = table.concat(textParts, " / ")
        data.NameLabel.Visible = true
    else
        data.NameLabel.Visible = false
    end
end

---------------------------------------------------------------------------------------------------
-- Build all UI bits + chams for one player
---------------------------------------------------------------------------------------------------
function ESPLibrary.CreateESPComponents(plr)
    if ESPLibrary.ExistantPlayers[plr] then return end
    ESPLibrary.ExistantPlayers[plr] = {}
    local data = ESPLibrary.ExistantPlayers[plr]

    -- Main container
    local frame = ESPLibrary.CreateInstance("Frame", {
        Parent               = ESPLibrary.XenithESP,
        Name                 = plr.Name.."_ESP",
        BackgroundColor3     = Color3.fromRGB(0,0,0),
        BackgroundTransparency = ESPLibrary.Settings.Box.Enabled and 0.8 or 1,
        AnchorPoint          = Vector2.new(0.5,0.5),
        Size                 = UDim2.new(0,180,0,250),
        Visible              = true, -- Always visible so text can show
    })
    data.MainFrame = frame
    ESPLibrary.CreateInstance("UICorner", {Parent = frame, CornerRadius = UDim.new(0,1)})

    -- Frame stroke
    local frameStroke = ESPLibrary.CreateInstance("UIStroke", {
        Parent    = frame,
        Color     = ESPLibrary.Settings.Box.UseTeamColor and ESPLibrary.GetTeamColor(plr) or ESPLibrary.Settings.Box.DefaultColor,
        Thickness = 1,
        Transparency = ESPLibrary.Settings.Box.Enabled and 0 or 1,
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
            Visible           = ESPLibrary.Settings.Box.ShowCorners and ESPLibrary.Settings.Box.Enabled,
        })
        ESPLibrary.CreateInstance("UIStroke", {Parent = box, Color = Color3.new(0,0,0), Thickness = 0.6})
        data[name] = box
    end

    -- Side bars
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
            BackgroundColor3  = ESPLibrary.Settings.Box.UseTeamColor and ESPLibrary.GetTeamColor(plr) or ESPLibrary.Settings.Box.DefaultColor,
            Visible           = ESPLibrary.Settings.Box.ShowSides and ESPLibrary.Settings.Box.Enabled,
        })
        ESPLibrary.CreateInstance("UIStroke", {Parent = bar, Color = Color3.new(0,0,0), Thickness = 0.6})
        data[name] = bar
    end

    -- Text label + gradient - Now independent of box visibility
    local nameLabel = ESPLibrary.CreateInstance("TextLabel", {
        Parent                 = ESPLibrary.XenithESP, -- Directly parented to ScreenGui instead of frame
        Name                   = plr.Name.."_TextLabel",
        BackgroundTransparency = 1,
        Text                   = "",
        TextColor3             = Color3.fromRGB(255,255,255),
        TextStrokeTransparency = 0.6,
        Font                   = Enum.Font.Code,
        TextWrapped            = false,
        TextScaled             = false,
        AutomaticSize          = Enum.AutomaticSize.None,
        AnchorPoint            = Vector2.new(0.5,1),
        Position               = UDim2.new(0.5,0,0.5,0), -- Will be updated in render loop
        ZIndex                 = 10,
        Visible                = false, -- Initially hidden, will be shown when text is enabled
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

    local highlight = ESPLibrary.CreateInstance("Highlight", {
        Parent            = workspace,
        Adornee           = plr.Character or nil,
        FillColor         = ESPLibrary.Settings.Highlight.UseTeamColor and ESPLibrary.GetTeamColor(plr) or ESPLibrary.Settings.Highlight.DefaultFillColor,
        OutlineColor      = ESPLibrary.Settings.Highlight.UseTeamColor and ESPLibrary.GetTeamColor(plr) or ESPLibrary.Settings.Highlight.DefaultOutlineColor,
        FillTransparency  = 0.4,
        OutlineTransparency = 0.2,
        Enabled           = ESPLibrary.Settings.Highlight.Enabled,
    })
    data.Highlight = highlight
    
    plr.CharacterAdded:Connect(function(char)
        highlight.Adornee = char
    end)

    -- Animation loop
    task.spawn(function()
        local baseColor      = ESPLibrary.Settings.Box.UseTeamColor and ESPLibrary.GetTeamColor(plr) or Color3.fromRGB(0, 180, 200)
        local midColor       = baseColor:Lerp(Color3.new(1,1,1), 0.3)
        local highlightColor = baseColor:Lerp(Color3.new(1,1,1), 0.6)

        local pulseSpeed     = 0.4
        local minAlpha       = 0.35
        local maxAlpha       = 0.75

        while frame.Parent do
            local t     = tick()
            local pulse = (math.sin(t * pulseSpeed * math.pi * 2) + 1) / 2
            local inv   = 1 - pulse

            if not ESPLibrary.Settings.Box.UseTeamColor then
                boxGrad.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, baseColor),
                    ColorSequenceKeypoint.new(0.5, midColor),
                    ColorSequenceKeypoint.new(1, highlightColor),
                }

                frame.BackgroundColor3 = baseColor:Lerp(midColor, pulse * 0.5)
                -- Only change transparency if box is enabled
                if ESPLibrary.Settings.Box.Enabled then
                    frame.BackgroundTransparency = 1 - (minAlpha + (maxAlpha - minAlpha)*pulse)
                end

                frameStroke.Color = midColor
                -- Only change stroke transparency if box is enabled
                if ESPLibrary.Settings.Box.Enabled then
                    frameStroke.Transparency = 0.4 + 0.3*(1-pulse)
                end

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

            if not ESPLibrary.Settings.Text.UseTeamColor then
                textGrad.Color           = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, midColor),
                    ColorSequenceKeypoint.new(1, highlightColor),
                }
                data.NameLabel.TextColor3 = highlightColor:Lerp(midColor, pulse)
            end

            if not ESPLibrary.Settings.Highlight.UseTeamColor then
                highlight.FillColor           = midColor
                highlight.OutlineColor        = highlightColor
                highlight.FillTransparency    = minAlpha + (maxAlpha - minAlpha) * inv * 0.5
                highlight.OutlineTransparency = 0.2 + 0.5 * inv
            end
            
            task.wait(0.01)
        end
    end)
    
    -- Update initial colors and text
    ESPLibrary:UpdatePlayerColors(plr, data)
    ESPLibrary:UpdatePlayerText(plr, data)
end

function ESPLibrary.DeleteESPComponents(plr)
    local data = ESPLibrary.ExistantPlayers[plr]
    if not data then return end
    if data.MainFrame then data.MainFrame:Destroy() end
    if data.NameLabel then data.NameLabel:Destroy() end
    if data.Highlight then data.Highlight:Destroy() end
    if ESPLibrary.RunningThreads[plr] then
        ESPLibrary.RunningThreads[plr]:Disconnect()
        ESPLibrary.RunningThreads[plr] = nil
    end
    ESPLibrary.ExistantPlayers[plr] = nil
end

function ESPLibrary.RenderESP(plr)
    local data = ESPLibrary.ExistantPlayers[plr]
    if not data then return end
    local chr = plr.Character
    if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    data.RootPart = hrp

    ESPLibrary.RunningThreads[plr] = RunService.RenderStepped:Connect(function()
        if not ESPLibrary.Settings.Enabled then
            data.MainFrame.Visible = false
            data.NameLabel.Visible = false
            return
        end
        
        local cam, frame = workspace.CurrentCamera, data.MainFrame
        local screenPt, onScreen = cam:WorldToScreenPoint(hrp.Position)
        if not onScreen then 
            frame.Visible = false
            data.NameLabel.Visible = false
            return 
        end
        
        frame.Visible = true
        frame.Position = UDim2.new(0, screenPt.X, 0, screenPt.Y)

        -- box sizing
        local dist      = (cam.CFrame.Position - hrp.Position).Magnitude
        local scaleFact = math.clamp(1 - (dist/60), 0, .2)
        local sizeBase  = 4.5 + 4.5 * scaleFact
        local w         = sizeBase * cam.ViewportSize.Y / (screenPt.Z * 1.7)
        local h         = w * 1.5
        frame.Size      = UDim2.new(0, w, 0, h)

        -- Update text
        ESPLibrary:UpdatePlayerText(plr, data)
        
        -- Position text label independently above the player
        local textOffsetY = -h/2 - 10 -- Position above the box
        data.NameLabel.Position = UDim2.new(0, screenPt.X, 0, screenPt.Y + textOffsetY)
        
        -- text sizing
        local lbl = data.NameLabel
        local sf = math.clamp(30 / math.max(dist,0.1), .5, 1.5)
        local bounds = TextService:GetTextSize(lbl.Text, ESPLibrary.Settings.FontSize, lbl.Font, Vector2.new(1e5,1e5))
        lbl.Size     = UDim2.new(0, math.clamp(bounds.X*sf,120,240),
                                 0, math.clamp(bounds.Y*sf,24,48))
        lbl.TextSize = 24 * sf
    end)
end

---------------------------------------------------------------------------------------------------
-- Initialize everything
---------------------------------------------------------------------------------------------------
function ESPLibrary.InitializeESP()
    local old = gethui():FindFirstChild("XenithESP")
    if old then old:Destroy() end
    ESPLibrary.XenithESP       = ESPLibrary.CreateInstance("ScreenGui", {
        Parent = gethui(), Name = "XenithESP", Enabled = ESPLibrary.Settings.Enabled
    })
    ESPLibrary.ExistantPlayers = {}
    ESPLibrary.RunningThreads  = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then
            ESPLibrary.CreateESPComponents(p)
            ESPLibrary.RenderESP(p)
        end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= Players.LocalPlayer then
            ESPLibrary.CreateESPComponents(p)
            ESPLibrary.RenderESP(p)
        end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if p ~= Players.LocalPlayer then
            ESPLibrary.DeleteESPComponents(p)
        end
    end)
end

---------------------------------------------------------------------------------------------------
-- API Functions for easy use
---------------------------------------------------------------------------------------------------

-- Main toggles
function ESPLibrary:Enable()
    self:ToggleESP(true)
end

function ESPLibrary:Disable()
    self:ToggleESP(false)
end

-- Box controls
function ESPLibrary:ShowBox()
    self:ToggleBox(true)
end

function ESPLibrary:HideBox()
    self:ToggleBox(false)
end

function ESPLibrary:ShowCorners()
    self:ToggleCorners(true)
end

function ESPLibrary:HideCorners()
    self:ToggleCorners(false)
end

function ESPLibrary:ShowSides()
    self:ToggleSides(true)
end

function ESPLibrary:HideSides()
    self:ToggleSides(false)
end

-- Text controls
function ESPLibrary:ShowName()
    self:ToggleName(true)
end

function ESPLibrary:HideName()
    self:ToggleName(false)
end

function ESPLibrary:ShowHealth()
    self:ToggleHealth(true)
end

function ESPLibrary:HideHealth()
    self:ToggleHealth(false)
end

function ESPLibrary:ShowDistance()
    self:ToggleDistance(true)
end

function ESPLibrary:HideDistance()
    self:ToggleDistance(false)
end

function ESPLibrary:SetFontSize(VALUE)
    ESPLibrary.Settings.FontSize = VALUE
end

-- Team color controls
function ESPLibrary:UseTeamColors()
    self:ToggleBoxTeamColor(true)
    self:ToggleTextTeamColor(true)
    self:ToggleHighlightTeamColor(true)
end

function ESPLibrary:UseDefaultColors()
    self:ToggleBoxTeamColor(false)
    self:ToggleTextTeamColor(false)
    self:ToggleHighlightTeamColor(false)
end

-- Highlight controls
function ESPLibrary:ShowHighlight()
    self:ToggleHighlight(true)
end

function ESPLibrary:HideHighlight()
    self:ToggleHighlight(false)
end

-- Initialize
ESPLibrary.InitializeESP()

return ESPLibrary
