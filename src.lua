local UILibrary = {}

function UILibrary:CreateWindow(config)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local Frame = Instance.new("Frame")
    Frame.Size = config.Size or UDim2.new(0, 400, 0, 300)
    Frame.Position = config.Position or UDim2.new(0.5, -200, 0.5, -150)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.Visible = config.Visible or true
    Frame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Title.Text = config.Title or "UI Library"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Parent = Frame
    
    if config.UserInfo then
        local player = game.Players.LocalPlayer
        local Avatar = Instance.new("ImageLabel")
        Avatar.Size = UDim2.new(0, 80, 0, 80)
        Avatar.Position = UDim2.new(1, -90, 0, 10)
        Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=100&height=100&format=png"
        Avatar.Parent = Frame
        
        local UserName = Instance.new("TextLabel")
        UserName.Size = UDim2.new(0, 100, 0, 20)
        UserName.Position = UDim2.new(1, -110, 0, 100)
        UserName.Text = player.Name
        UserName.TextColor3 = Color3.fromRGB(255, 255, 255)
        UserName.BackgroundTransparency = 1
        UserName.Parent = Frame
    end
    
    return Frame
end

function UILibrary:CreateButton(parent, text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 30)
    Button.Position = UDim2.new(0, 5, 0, 40)
    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Text = text or "Button"
    Button.Parent = parent
    
    Button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return Button
end

function UILibrary:CreateLabel(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 30)
    Label.Position = UDim2.new(0, 5, 0, 80)
    Label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Text = text or "Label"
    Label.Parent = parent
    
    return Label
end

return UILibrary
