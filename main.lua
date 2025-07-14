local Players     = cloneref(game:GetService("Players"))
local RunService  = cloneref(game:GetService("RunService"))
local TextService = game:GetService("TextService")

local ESPLibrary = {}

---------------------------------------------------------------------------------------------------
-- helper: safe Instance.new + bulk properties
---------------------------------------------------------------------------------------------------
function ESPLibrary.CreateInstance(className, props)
    if typeof(className) ~= "string" then return end
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

---------------------------------------------------------------------------------------------------
-- helper: lerp between two ColorSequences (same key‐point count & times)
---------------------------------------------------------------------------------------------------
function ESPLibrary.LerpColorSequence(a: ColorSequence, b: ColorSequence, alpha: number)
    local keys = {}
    for i = 1, #a.Keypoints do
        local ak, bk = a.Keypoints[i], b.Keypoints[i]
        keys[i] = ColorSequenceKeypoint.new(ak.Time, ak.Value:Lerp(bk.Value, alpha))
    end
    return ColorSequence.new(keys)
end

---------------------------------------------------------------------------------------------------
-- Build all UI bits + chams for one player
---------------------------------------------------------------------------------------------------
function ESPLibrary.CreateESPComponents(plr)
    if ESPLibrary.ExistantPlayers[plr] then return end
    ESPLibrary.ExistantPlayers[plr] = {}
    local data = ESPLibrary.ExistantPlayers[plr]

    -- cache this player's team color (fallback white)
    local teamColor = (plr.TeamColor and plr.TeamColor.Color) or Color3.new(1,1,1)

    -- Main container
    local frame = ESPLibrary.CreateInstance("Frame", {
        Parent                  = ESPLibrary.XenithESP,
        Name                    = plr.Name.."_ESP",
        BackgroundColor3        = Color3.fromRGB(0,0,0),
        BackgroundTransparency  = 0.8,
        AnchorPoint             = Vector2.new(0.5,0.5),
        Size                    = UDim2.new(0,180,0,180),
        Visible                 = false,
    })
    data.MainFrame = frame
    ESPLibrary.CreateInstance("UICorner", { Parent = frame, CornerRadius = UDim.new(0,1) })

    -- Frame stroke
    local frameStroke = ESPLibrary.CreateInstance("UIStroke", {
        Parent    = frame,
        Color     = teamColor,
        Thickness = 1,
    })
    data.FrameStroke = frameStroke

    -- Box gradient
    local boxGrad = ESPLibrary.CreateInstance("UIGradient", {
        Parent = frame,
        Color  = ColorSequence.new{
            ColorSequenceKeypoint.new(0, teamColor),
            ColorSequenceKeypoint.new(1, teamColor),
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
            Parent           = frame,
            Name             = name,
            Size             = size,
            Position         = pos,
            AnchorPoint      = anchor,
            ZIndex           = 3,
            BackgroundColor3 = teamColor,
        })
        ESPLibrary.CreateInstance("UIStroke", {
            Parent    = box,
            Color     = teamColor:Lerp(Color3.new(1,1,1), 0.3),
            Thickness = 0.6,
        })
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
            Parent           = frame,
            Name             = name,
            Size             = size,
            Position         = pos,
            AnchorPoint      = anchor,
            ZIndex           = 2,
            BackgroundColor3 = teamColor,
        })
        ESPLibrary.CreateInstance("UIStroke", {
            Parent    = bar,
            Color     = teamColor:Lerp(Color3.new(1,1,1), 0.3),
            Thickness = 0.6,
        })
        data[name] = bar
    end

    -- Text label + gradient
    local nameLabel = ESPLibrary.CreateInstance("TextLabel", {
        Parent                 = frame,
        Name                   = "NameLabel",
        BackgroundTransparency = 1,
        Text                   = "",
        TextColor3             = teamColor,
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
            ColorSequenceKeypoint.new(0, teamColor),
            ColorSequenceKeypoint.new(1, teamColor),
        }
    })
    data.TextGradient = textGrad

    -- Chams highlight
    local highlight = ESPLibrary.CreateInstance("Highlight", {
        Parent               = workspace,
        Adornee              = plr.Character or nil,
        FillColor            = teamColor,
        OutlineColor         = teamColor,
        FillTransparency     = 0.7,
        OutlineTransparency  = 0.3,
    })
    data.Highlight = highlight
    plr.CharacterAdded:Connect(function(char)
        highlight.Adornee = char
    end)

    -- Render loop: positioning, sizing, text
    ESPLibrary.RunningThreads[plr] = RunService.RenderStepped:Connect(function()
        local cam, frame = workspace.CurrentCamera, data.MainFrame
        local chr = plr.Character
        if not chr then return end
        local hrp = chr:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local screenPt, onScreen = cam:WorldToScreenPoint(hrp.Position)
        if not onScreen then
            frame.Visible = false
            return
        end

        frame.Visible  = true
        frame.Position = UDim2.new(0, screenPt.X, 0, screenPt.Y)

        -- box sizing
        local dist      = (cam.CFrame.Position - hrp.Position).Magnitude
        local scaleFact = math.clamp(1 - (dist/60), 0, .2)
        local sizeBase  = 4.5 + 4.5 * scaleFact
        local w         = sizeBase * cam.ViewportSize.Y / (screenPt.Z * 1.7)
        local h         = w * 1.5
        frame.Size      = UDim2.new(0, w, 0, h)

        -- text sizing
        local hum   = chr:FindFirstChild("Humanoid")
        local hpPct = hum and hum.Health/hum.MaxHealth or 0
        local txt   = string.format("[%d%%] /%s/ [%d]",
                          math.floor(hpPct*100),
                          plr.Name,
                          math.round(dist))
        local lbl = data.NameLabel
        lbl.Text   = txt

        local sf = math.clamp(30 / math.max(dist,0.1), .5, 1.5)
        local bounds = TextService:GetTextSize(txt, 24, lbl.Font, Vector2.new(1e5,1e5))
        lbl.Size     = UDim2.new(0, math.clamp(bounds.X*sf,120,240),
                                 0, math.clamp(bounds.Y*sf,24,48))
        lbl.TextSize = 24 * sf
    end)

    -- Pulsing glow & UI tint loop
    task.spawn(function()
        local pulseSpeed = 1    -- pulses per second
        local minT, maxT = 0.5, 0.9

        while frame.Parent do
            local t = tick()
            local pulse = (math.sin(t * pulseSpeed * math.pi * 2) + 1) / 2
            local fillT = minT + (maxT - minT) * pulse

            -- UI tint (teamColor)
            boxGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, teamColor),
                ColorSequenceKeypoint.new(1, teamColor),
            }
            frameStroke.Color = teamColor

            for _, child in pairs(data) do
                if typeof(child)=="Instance" and child:IsA("Frame") and child~=frame then
                    child.BackgroundColor3 = teamColor
                    local stroke = child:FindFirstChildOfClass("UIStroke")
                    if stroke then stroke.Color = teamColor:Lerp(Color3.new(1,1,1), 0.3) end
                end
            end

            -- Highlight glow
            highlight.FillColor            = teamColor
            highlight.OutlineColor         = teamColor
            highlight.FillTransparency     = fillT
            highlight.OutlineTransparency  = 1 - fillT

            RunService.RenderStepped:Wait()
        end
    end)
end

---------------------------------------------------------------------------------------------------
-- Remove UI, chams & disconnect
---------------------------------------------------------------------------------------------------
function ESPLibrary.DeleteESPComponents(plr)
    local data = ESPLibrary.ExistantPlayers[plr]
    if not data then return end
    if data.MainFrame then data.MainFrame:Destroy() end
    if data.Highlight then data.Highlight:Destroy() end
    if ESPLibrary.RunningThreads[plr] then
        ESPLibrary.RunningThreads[plr]:Disconnect()
        ESPLibrary.RunningThreads[plr] = nil
    end
    ESPLibrary.ExistantPlayers[plr] = nil
end

---------------------------------------------------------------------------------------------------
-- Initialize everything
---------------------------------------------------------------------------------------------------
function ESPLibrary.InitializeESP()
    local old = gethui():FindFirstChild("XenithESP")
    if old then old:Destroy() end
    ESPLibrary.XenithESP       = ESPLibrary.CreateInstance("ScreenGui", {
        Parent = gethui(), Name = "XenithESP"
    })
    ESPLibrary.ExistantPlayers = {}
    ESPLibrary.RunningThreads  = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then
            ESPLibrary.CreateESPComponents(p)
        end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= Players.LocalPlayer then
            ESPLibrary.CreateESPComponents(p)
        end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if p ~= Players.LocalPlayer then
            ESPLibrary.DeleteESPComponents(p)
        end
    end)
end

-- kick it off
ESPLibrary.InitializeESP()

return ESPLibrary
