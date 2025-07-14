-- Add this to the Settings table
ESPLibrary.Settings = {
    -- ... existing settings ...
    TopBar = {
        Enabled = false,
        DefaultColor = Color3.new(1, 1, 1),
        UseTeamColor = false
    },
    BottomBar = {
        Enabled = false,
        DefaultColor = Color3.new(1, 1, 1),
        UseTeamColor = false
    }
}

-- Add these to the CreateESPComponents function
function ESPLibrary.CreateESPComponents(plr)
    -- ... existing code ...
    
    -- Top bar
    local topBar = ESPLibrary.CreateInstance("TextLabel", {
        Parent = frame,
        Name = "TopBar",
        BackgroundTransparency = 0.7,
        BackgroundColor3 = Color3.new(0,0,0),
        Text = "",
        TextColor3 = ESPLibrary.Settings.TopBar.UseTeamColor and ESPLibrary.GetTeamColor(plr) or ESPLibrary.Settings.TopBar.DefaultColor,
        TextStrokeTransparency = 0.6,
        Font = Enum.Font.Code,
        TextWrapped = true,
        TextScaled = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, -20),
        Visible = ESPLibrary.Settings.TopBar.Enabled,
        ZIndex = 15
    })
    data.TopBar = topBar
    
    -- Bottom bar
    local bottomBar = ESPLibrary.CreateInstance("TextLabel", {
        Parent = frame,
        Name = "BottomBar",
        BackgroundTransparency = 0.7,
        BackgroundColor3 = Color3.new(0,0,0),
        Text = "",
        TextColor3 = ESPLibrary.Settings.BottomBar.UseTeamColor and ESPLibrary.GetTeamColor(plr) or ESPLibrary.Settings.BottomBar.DefaultColor,
        TextStrokeTransparency = 0.6,
        Font = Enum.Font.Code,
        TextWrapped = true,
        TextScaled = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        Visible = ESPLibrary.Settings.BottomBar.Enabled,
        ZIndex = 15
    })
    data.BottomBar = bottomBar
    
    -- ... existing code ...
end

-- Add these to the UpdatePlayerColors function
function ESPLibrary:UpdatePlayerColors(player, data)
    -- ... existing code ...
    
    -- Update top bar color
    if data.TopBar then
        if self.Settings.TopBar.UseTeamColor then
            data.TopBar.TextColor3 = teamColor
        end
    end
    
    -- Update bottom bar color
    if data.BottomBar then
        if self.Settings.BottomBar.UseTeamColor then
            data.BottomBar.TextColor3 = teamColor
        end
    end
end

-- Add these to the RenderESP function
function ESPLibrary.RenderESP(plr)
    -- ... existing code ...
    
    -- Update bars in the render loop
    if data.TopBar then
        data.TopBar.Visible = ESPLibrary.Settings.TopBar.Enabled
        if data.TopBar.Visible then
            -- Position above the box with padding
            data.TopBar.Position = UDim2.new(0, 0, 0, -data.TopBar.TextBounds.Y - 4)
        end
    end
    
    if data.BottomBar then
        data.BottomBar.Visible = ESPLibrary.Settings.BottomBar.Enabled
        if data.BottomBar.Visible then
            -- Position below the box with padding
            data.BottomBar.Position = UDim2.new(0, 0, 1, 4)
        end
    end
end

-- Add these new API functions
function ESPLibrary:AddTopBar(player, text)
    local data = self.ExistantPlayers[player]
    if data and data.TopBar then
        data.TopBar.Text = text
    end
end

function ESPLibrary:AddBottomBar(player, text)
    local data = self.ExistantPlayers[player]
    if data and data.BottomBar then
        data.BottomBar.Text = text
    end
end

function ESPLibrary:SetTopBarText(player, text)
    self:AddTopBar(player, text)
end

function ESPLibrary:SetBottomBarText(player, text)
    self:AddBottomBar(player, text)
end

function ESPLibrary:ShowTopBar()
    self.Settings.TopBar.Enabled = true
    for _, data in pairs(self.ExistantPlayers) do
        if data.TopBar then
            data.TopBar.Visible = true
        end
    end
end

function ESPLibrary:HideTopBar()
    self.Settings.TopBar.Enabled = false
    for _, data in pairs(self.ExistantPlayers) do
        if data.TopBar then
            data.TopBar.Visible = false
        end
    end
end

function ESPLibrary:ShowBottomBar()
    self.Settings.BottomBar.Enabled = true
    for _, data in pairs(self.ExistantPlayers) do
        if data.BottomBar then
            data.BottomBar.Visible = true
        end
    end
end

function ESPLibrary:HideBottomBar()
    self.Settings.BottomBar.Enabled = false
    for _, data in pairs(self.ExistantPlayers) do
        if data.BottomBar then
            data.BottomBar.Visible = false
        end
    end
end

function ESPLibrary:ToggleTopBarTeamColor(state)
    self.Settings.TopBar.UseTeamColor = state
    self:UpdateAllColors()
end

function ESPLibrary:ToggleBottomBarTeamColor(state)
    self.Settings.BottomBar.UseTeamColor = state
    self:UpdateAllColors()
end
