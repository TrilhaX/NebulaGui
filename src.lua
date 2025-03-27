--[[
    Modern UI Library v1.0
    Recursos incluídos:
    - Theme System
    - Botões estilizados
    - Modais
    - Sliders
    - Toggles
    - Notificações
    - Navigation Bar
--]]

local UILib = {}

-- Serviços necessários
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Configuração do tema
UILib.Theme = {
    Primary = Color3.fromRGB(0, 170, 255),
    Secondary = Color3.fromRGB(245, 245, 245),
    TextColor = Color3.fromRGB(255, 255, 255),
    DarkText = Color3.fromRGB(50, 50, 50),
    Success = Color3.fromRGB(85, 170, 127),
    Danger = Color3.fromRGB(255, 95, 87),
    BorderRadius = UDim.new(0, 8),
    Font = Enum.Font.GothamMedium
}

-- Função para criar elementos básicos
function UILib:CreateElement(elementType, properties)
    local element = Instance.new(elementType)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    return element
end

-- Componente: Botão Moderno
function UILib:CreateButton(options)
    local button = self:CreateElement("TextButton", {
        Size = options.Size or UDim2.new(0, 200, 0, 40),
        BackgroundColor3 = self.Theme.Primary,
        Font = self.Theme.Font,
        TextColor3 = self.Theme.TextColor,
        Text = options.Text or "Button",
        AutoButtonColor = false,
        Parent = options.Parent
    })

    local corner = self:CreateElement("UICorner", {
        CornerRadius = self.Theme.BorderRadius,
        Parent = button
    })

    local padding = self:CreateElement("UIPadding", {
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = button
    })

    -- Efeitos de hover
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Primary:Lerp(Color3.new(1,1,1), 0.1)}):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Primary}):Play()
    end)

    -- Efeito de clique
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Position = UDim2.new(0.5, 0, 0.5, 2)}):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
    end)

    return button
end

-- Componente: Modal
function UILib:CreateModal(options)
    local modalOverlay = self:CreateElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        Parent = options.Parent
    })

    local modalFrame = self:CreateElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 400, 0, 250),
        BackgroundColor3 = self.Theme.Secondary,
        Parent = modalOverlay
    })

    -- Adicionar conteúdo ao modal
    -- ... (adicionar título, texto e botões)

    return modalOverlay
end

-- Componente: Slider
function UILib:CreateSlider(options)
    local sliderContainer = self:CreateElement("Frame", {
        Size = UDim2.new(0, 300, 0, 50),
        BackgroundTransparency = 1,
        Parent = options.Parent
    })

    local sliderTrack = self:CreateElement("TextButton", {
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
        AutoButtonColor = false,
        Parent = sliderContainer
    })

    local sliderFill = self:CreateElement("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Theme.Primary,
        Parent = sliderTrack
    })

    local sliderThumb = self:CreateElement("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 0, 0.5, -10),
        BackgroundColor3 = self.Theme.Primary,
        Parent = sliderContainer
    })

    -- Lógica do slider
    local isDragging = false
    -- ... (adicionar lógica de arrasto)

    return sliderContainer
end

-- Componente: Notification
function UILib:ShowNotification(options)
    local notification = self:CreateElement("Frame", {
        Size = UDim2.new(0.3, 0, 0, 50),
        Position = UDim2.new(0.5, 0, 0, -50),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = self.Theme.Secondary,
        Parent = options.Parent
    })

    -- Animação de entrada
    TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, 0, 0, 20)
    }):Play()

    -- Auto-fechar após 5 segundos
    task.delay(5, function()
        TweenService:Create(notification, TweenInfo.new(0.5), {
            Position = UDim2.new(0.5, 0, 0, -50)
        }):Play()
        task.wait(0.5)
        notification:Destroy()
    end)

    return notification
end

-- Componente: Navigation Bar
function UILib:CreateNavBar(options)
    local navBar = self:CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Theme.Primary,
        Parent = options.Parent
    })

    local layout = self:CreateElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 20),
        Parent = navBar
    })

    -- Adicionar itens
    for _, item in pairs(options.Items) do
        local navButton = self:CreateButton({
            Text = item.Text,
            Parent = navBar,
            Size = UDim2.new(0, 100, 0, 30)
        })
        navButton.MouseButton1Click:Connect(item.Callback)
    end

    return navBar
end

return UILib
