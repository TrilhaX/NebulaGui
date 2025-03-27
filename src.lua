local UILibrary = {}
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--------------------------------------------------
-- Cria a janela principal com configurações customizadas.
--------------------------------------------------
function UILibrary:CreateWindow(config)
    config = config or {}
    
    -- Criação do ScreenGui principal.
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "UILibrary_Window"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Criação do frame principal (janela).
    local window = Instance.new("Frame")
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Position = config.Position or UDim2.new(0.5, 0, 0.5, 0)
    window.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    window.BorderSizePixel = 0
    window.Visible = config.Visible == nil and true or config.Visible

    -- Auto resize para mobile: se TouchEnabled, usa tamanho relativo; caso contrário, usa tamanho fixo.
    if UserInputService.TouchEnabled then
        window.Size = UDim2.new(0.9, 0, 0.8, 0)
    else
        window.Size = config.Size or UDim2.new(0, 500, 0, 400)
    end
    window.Parent = screenGui

    -- Título da janela (será a área de arrasto).
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleLabel.Text = config.Title or "UILibrary"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSans
    titleLabel.TextSize = 20
    titleLabel.Parent = window

    -- Adicionando a funcionalidade de arrastar
    local dragSpeed = 1 -- Ajuste a sensibilidade do arrasto
    local isDragging = false
    local dragStartPos
    local windowStartPos

    -- Função para atualizar a posição durante o arrasto
    local function updateDrag(input)
        if not isDragging then return end
        
        local delta = input.Position - dragStartPos
        local newX = windowStartPos.X.Offset + (delta.X * dragSpeed)
        local newY = windowStartPos.Y.Offset + (delta.Y * dragSpeed)
        
        -- Limites da tela
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local windowSize = window.AbsoluteSize
        
        -- Calcular limites máximos
        local minX = -windowSize.X/2
        local maxX = viewportSize.X - windowSize.X/2
        local minY = -windowSize.Y/2
        local maxY = viewportSize.Y - windowSize.Y/2
        
        newX = math.clamp(newX, minX, maxX)
        newY = math.clamp(newY, minY, maxY)
        
        window.Position = UDim2.new(
            0, newX,
            0, newY
        )
    end

    -- Conectar eventos de arrasto ao título da janela
    titleLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartPos = input.Position
            windowStartPos = window.Position
            
            -- Conectar o evento de movimento
            local moveConnection = RunService.RenderStepped:Connect(function()
                if isDragging then
                    local input = UserInputService:GetLastInputForMovement()
                    if input then
                        updateDrag(input)
                    end
                end
            end)
            
            -- Quando soltar o botão
            local releaseConnection
            releaseConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    moveConnection:Disconnect()
                    releaseConnection:Disconnect()
                end
            end)
        end
    end)

    -- Exibe informações do usuário, se habilitado.
    if config.UserInfo then
        local player = game.Players.LocalPlayer

        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2.new(0, 80, 0, 80)
        avatar.Position = UDim2.new(1, -90, 0, 10)
        avatar.BackgroundTransparency = 1
        avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=100&height=100&format=png"
        avatar.Parent = window

        local userName = Instance.new("TextLabel")
        userName.Size = UDim2.new(0, 100, 0, 20)
        userName.Position = UDim2.new(1, -110, 0, 100)
        userName.BackgroundTransparency = 1
        userName.Text = player.Name
        userName.TextColor3 = Color3.fromRGB(255, 255, 255)
        userName.Font = Enum.Font.SourceSans
        userName.TextSize = 18
        userName.Parent = window
    end

    return window, screenGui
end

--------------------------------------------------
-- Cria um botão dentro do pai definido.
--------------------------------------------------
function UILibrary:CreateButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Position = UDim2.new(0, 5, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 18
    button.Text = text or "Button"
    button.Parent = parent

    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    return button
end

--------------------------------------------------
-- Cria um label dentro do pai definido.
--------------------------------------------------
function UILibrary:CreateLabel(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 30)
    label.Position = UDim2.new(0, 5, 0, 80)
    label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 18
    label.Text = text or "Label"
    label.Parent = parent

    return label
end

return UILibrary