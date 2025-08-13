local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Debug,LocalPlayer = false,PlayerService.LocalPlayer
local MainAssetFolder = Debug and ReplicatedStorage.BracketV32
    or InsertService:LoadLocalAsset("rbxassetid://96885474104231")

    local function GetAsset(AssetPath)
        AssetPath = AssetPath:split("/")
        local Asset = MainAssetFolder
        for Index,Name in pairs(AssetPath) do
            Asset = Asset[Name]
        end return Asset:Clone()
    end
local function GetLongest(A,B)
    return A > B and A or B
end
local function GetType(Object,Default,Type)
    if typeof(Object) == Type then
        return Object
    end
    return Default
end

local function MakeDraggable(Dragger,Object,Callback)
    local StartPosition,StartDrag = nil,nil
    local touchStartPos, touchStartTime
    
    local function handleInput(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            StartPosition = UserInputService:GetMouseLocation()
            StartDrag = Object.AbsolutePosition
            touchStartPos = Input.Position
            touchStartTime = os.clock()
        end
    end
    
    Dragger.InputBegan:Connect(handleInput)
    
    UserInputService.InputChanged:Connect(function(Input)
        if StartDrag and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            local Mouse = UserInputService:GetMouseLocation()
            local Delta = Mouse - StartPosition
            StartPosition = Mouse
            Object.Position = Object.Position + UDim2.new(0,Delta.X,0,Delta.Y)
        end
    end)
    
    local function handleInputEnd(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            -- Check if it was a tap (short duration and small movement)
            local touchEndPos = Input.Position
            local touchDuration = os.clock() - touchStartTime
            local touchDistance = (touchEndPos - touchStartPos).magnitude
            
            if touchDuration > 0.3 or touchDistance > 10 then
                -- It was a drag, not a tap
                StartPosition,StartDrag = nil,nil
                if Callback then
                    Callback(Object.Position)
                end
            end
        end
    end
    
    Dragger.InputEnded:Connect(handleInputEnd)
    UserInputService.TouchEnded:Connect(handleInputEnd)
end

local function MakeResizeable(Dragger,Object,MinSize,Callback)
    local StartPosition,StartSize = nil,nil
    local touchStartPos, touchStartTime
    
    local function handleInput(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            StartPosition = UserInputService:GetMouseLocation()
            StartSize = Object.AbsoluteSize
            touchStartPos = Input.Position
            touchStartTime = os.clock()
        end
    end
    
    Dragger.InputBegan:Connect(handleInput)
    
    UserInputService.InputChanged:Connect(function(Input)
        if StartPosition and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            local Mouse = UserInputService:GetMouseLocation()
            local Delta = Mouse - StartPosition

            local Size = StartSize + Delta
            local SizeX = math.max(MinSize.X,Size.X)
            local SizeY = math.max(MinSize.Y,Size.Y)
            Object.Size = UDim2.fromOffset(SizeX,SizeY)
        end
    end)
    
    local function handleInputEnd(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            -- Check if it was a tap (short duration and small movement)
            local touchEndPos = Input.Position
            local touchDuration = os.clock() - touchStartTime
            local touchDistance = (touchEndPos - touchStartPos).magnitude
            
            if touchDuration > 0.3 or touchDistance > 10 then
                -- It was a drag, not a tap
                StartPosition,StartSize = nil,nil
                if Callback then
                    Callback(Object.Size)
                end
            end
        end
    end
    
    Dragger.InputEnded:Connect(handleInputEnd)
    UserInputService.TouchEnded:Connect(handleInputEnd)
end

local function ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
    for Index,Instance in pairs(ScreenAsset:GetChildren()) do
        if Instance.Name == "Palette" or Instance.Name == "OptionContainer" then
            Instance.Visible = false
        end
    end
    for Index,Instance in pairs(ScreenAsset.Window.TabContainer:GetChildren()) do
        if Instance:IsA("ScrollingFrame") and Instance ~= TabAsset then
            Instance.Visible = false
        else
            Instance.Visible = true
        end
    end
    for Index,Instance in pairs(ScreenAsset.Window.TabButtonContainer:GetChildren()) do
        if Instance:IsA("TextButton") then
            Instance.Highlight.Visible = Instance == TabButtonAsset
        end
    end
end
local function ChooseTabSide(TabAsset,Mode)
    if Mode == "Longest" then
        if TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y > TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y then
            return TabAsset.LeftSide
        else
            return TabAsset.RightSide
        end
    elseif Mode == "Left" then
        return TabAsset.LeftSide
    elseif Mode == "Right" then
        return TabAsset.RightSide
    else
        if TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y > TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y then
            return TabAsset.RightSide
        else
            return TabAsset.LeftSide
        end
    end
end

local function GetConfigs(PFName)
    if not isfolder(PFName) then makefolder(PFName) end
    if not isfolder(PFName.."\\Configs") then makefolder(PFName.."\\Configs") end
    if not isfile(PFName.."\\DefaultConfig.txt") then writefile(PFName.."\\DefaultConfig.txt","") end

    local Configs = {}
    for Index,Config in pairs(listfiles(PFName.."\\Configs") or {}) do
        Config = Config:gsub(PFName.."\\Configs\\","")
        Config = Config:gsub(".json","")
        Configs[Index] = Config
    end
    return Configs
end
local function ConfigsToList(PFName)
    if not isfolder(PFName) then makefolder(PFName) end
    if not isfolder(PFName.."\\Configs") then makefolder(PFName.."\\Configs") end
    if not isfile(PFName.."\\DefaultConfig.txt") then writefile(PFName.."\\DefaultConfig.txt","") end

    local Configs = {}
    for Index,Config in pairs(listfiles(PFName.."\\Configs") or {}) do
        Config = Config:gsub(PFName.."\\Configs\\","")
        Config = Config:gsub(".json","")
        local DefaultConfig = readfile(PFName.."\\DefaultConfig.txt")
        Configs[Index] = {Name = Config,Mode = "Button",
            Value = Config == DefaultConfig}
    end
    return Configs
end

local function InitToolTip(Parent,ScreenAsset,Text)
    Parent.MouseEnter:Connect(function()
        ScreenAsset.ToolTip.Text = Text
        ScreenAsset.ToolTip.Size = UDim2.new(0,ScreenAsset.ToolTip.TextBounds.X + 2,0,ScreenAsset.ToolTip.TextBounds.Y + 2)
        ScreenAsset.ToolTip.Visible = true
    end)
    Parent.MouseLeave:Connect(function()
        ScreenAsset.ToolTip.Visible = false
    end)
    
    -- Mobile touch support
    local touchStartTime
    Parent.TouchTap:Connect(function()
        ScreenAsset.ToolTip.Text = Text
        ScreenAsset.ToolTip.Size = UDim2.new(0,ScreenAsset.ToolTip.TextBounds.X + 2,0,ScreenAsset.ToolTip.TextBounds.Y + 2)
        ScreenAsset.ToolTip.Visible = true
        
        -- Hide after 2 seconds for touch devices
        task.delay(2, function()
            ScreenAsset.ToolTip.Visible = false
        end)
    end)
end
local function InitScreen()
    local ScreenAsset = GetAsset("Screen/Bracket")
    if not Debug then sethiddenproperty(ScreenAsset,"OnTopOfCoreBlur",true) end
    ScreenAsset.Name = "Bracket " .. game:GetService("HttpService"):GenerateGUID(false)
    ScreenAsset.Parent = Debug and LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui
    
    -- Add touch input support
    local touchInput = Instance.new("TouchInputService")
    touchInput.Parent = ScreenAsset
    
    return {ScreenAsset = ScreenAsset}
end
local function InitWindow(ScreenAsset,Window)
    local WindowAsset = GetAsset("Window/Window")

    WindowAsset.Parent = ScreenAsset
    WindowAsset.Visible = Window.Enabled
    WindowAsset.Title.Text = Window.Name
    WindowAsset.Position = Window.Position
    WindowAsset.Size = Window.Size

    MakeDraggable(WindowAsset.Drag,WindowAsset,function(Position)
        Window.Position = Position
    end)
    MakeResizeable(WindowAsset.Resize,WindowAsset,Vector2.new(296,296),function(Size)
        Window.Size = Size
    end)

    WindowAsset.TabButtonContainer.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        WindowAsset.TabButtonContainer.CanvasSize = UDim2.new(0,WindowAsset.TabButtonContainer.ListLayout.AbsoluteContentSize.X,0,0)
    end)
    
    -- Mobile-friendly positioning
    RunService.RenderStepped:Connect(function()
        if WindowAsset.Visible then
            local mousePos = UserInputService:GetMouseLocation()
            ScreenAsset.ToolTip.Position = UDim2.new(0,mousePos.X + 5,0,mousePos.Y - 5)
            
            -- Adjust window position if it goes off-screen on mobile
            if UserInputService.TouchEnabled then
                local windowPos = WindowAsset.AbsolutePosition
                local windowSize = WindowAsset.AbsoluteSize
                local screenSize = workspace.CurrentCamera.ViewportSize
                
                if windowPos.X + windowSize.X > screenSize.X then
                    WindowAsset.Position = UDim2.new(0, screenSize.X - windowSize.X, WindowAsset.Position.Y.Scale, WindowAsset.Position.Y.Offset)
                end
                if windowPos.Y + windowSize.Y > screenSize.Y then
                    WindowAsset.Position = UDim2.new(WindowAsset.Position.X.Scale, WindowAsset.Position.X.Offset, 0, screenSize.Y - windowSize.Y)
                end
                if windowPos.X < 0 then
                    WindowAsset.Position = UDim2.new(0, 0, WindowAsset.Position.Y.Scale, WindowAsset.Position.Y.Offset)
                end
                if windowPos.Y < 0 then
                    WindowAsset.Position = UDim2.new(WindowAsset.Position.X.Scale, WindowAsset.Position.X.Offset, 0, 0)
                end
            end
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        Window.RainbowHue = os.clock()%10/10
    end)
    
    function Window:SetName(Name)
        Window.Name = Name
        WindowAsset.Title.Text = Name
    end
    function Window:SetSize(Size)
        Window.Size = Size
        WindowAsset.Size = Size
    end
    function Window:SetPosition(Position)
        Window.Position = Position
        WindowAsset.Pisition = Position
    end
    function Window:SetColor(Color)
        if Color.R < 5/255
        and Color.G < 5/255
        and Color.B < 5/255 then
            Color = Color3.fromRGB(5,5,5)
        end

        for Index,Instance in pairs(Window.Colorable) do
            if Instance.BackgroundColor3 == Window.Color then
                Instance.BackgroundColor3 = Color
            end
            if Instance.BorderColor3 == Window.Color then
                Instance.BorderColor3 = Color
            end
        end
        Window.Color = Color
    end
    function Window:Toggle(Boolean)
        Window.Enabled = Boolean
        WindowAsset.Visible = Window.Enabled

        if not Debug then
        RunService:SetRobloxGuiFocused(Window.Enabled and Window.Flags["UI/Blur"]) end
        if not Window.Enabled then for Index,Instance in pairs(ScreenAsset:GetChildren()) do
            if Instance.Name == "Palette" or Instance.Name == "OptionContainer" then
                Instance.Visible = false
            end
        end end
    end

    function Window:SetValue(Flag,Value)
        for Index,Element in pairs(Window.Elements) do
            if Element.Flag == Flag then
                Element:SetValue(Value)
            end
        end
    end

    function Window:GetValue(Flag)
        for Index,Element in pairs(Window.Elements) do
            if Element.Flag == Flag then
                return Window.Flags[Element.Flag]
            end
        end
    end

    function Window:Watermark(Watermark)
        Watermark = GetType(Watermark,{},"table")
        Watermark.Title = GetType(Watermark.Title,"","string")
        Watermark.Enabled = GetType(Watermark.Enabled,false,"boolean")
        Watermark.Flag = GetType(Watermark.Flag,"UI/Watermark/Position","string")

        ScreenAsset.Watermark.Visible = Watermark.Enabled
        ScreenAsset.Watermark.Title.Text = Watermark.Title
        ScreenAsset.Watermark.Position = UDim2.new(0.95,0,0,10)
        ScreenAsset.Watermark.Size = UDim2.new(
        0,ScreenAsset.Watermark.Title.TextBounds.X + 6,
        0,ScreenAsset.Watermark.Title.TextBounds.Y + 6)
        MakeDraggable(ScreenAsset.Watermark,ScreenAsset.Watermark,function(Position)
            Window.Flags[Watermark.Flag] = 
            {Position.X.Scale,Position.X.Offset,
            Position.Y.Scale,Position.Y.Offset}
        end)

        function Watermark:Toggle(Boolean)
            Watermark.Enabled = Boolean
            ScreenAsset.Watermark.Visible = Watermark.Enabled
        end
        function Watermark:Transparency(Number)
            ScreenAsset.Watermark.BackgroundTransparency = Number
            ScreenAsset.Watermark.Stroke.Transparency = Number
            ScreenAsset.Watermark.Title.TextTransparency = Number
        end
        function Watermark:SetTitle(Text)
            Watermark.Title = Text
            ScreenAsset.Watermark.Title.Text = Watermark.Title
            ScreenAsset.Watermark.Size = UDim2.new(0,ScreenAsset.Watermark.Title.TextBounds.X + 6,0,ScreenAsset.Watermark.Title.TextBounds.Y + 6)
        end
        function Watermark:SetValue(Table)
            if not Table then return end
            ScreenAsset.Watermark.Position = UDim2.new(
                Table[1],Table[2],
                Table[3],Table[4]
            )
        end

        Window.Elements[#Window.Elements + 1] = Watermark
        Window.Watermark = Watermark
    end

    function Window:SaveConfig(PFName,Name)
        local Config = {}
        if table.find(GetConfigs(PFName),Name) then
            Config = HttpService:JSONDecode(readfile(PFName.."\\Configs\\"..Name..".json"))
        end
        for Index,Element in pairs(Window.Elements) do
            if not Element.IgnoreFlag then
                Config[Element.Flag] = Window.Flags[Element.Flag]
            end
        end
        writefile(PFName.."\\Configs\\"..Name..".json",HttpService:JSONEncode(Config))
    end
    function Window:LoadConfig(PFName,Name)
        if table.find(GetConfigs(PFName),Name) then
            local DecodedJSON = HttpService:JSONDecode(readfile(PFName.."\\Configs\\"..Name..".json"))
            for Index,Element in pairs(Window.Elements) do
                if DecodedJSON[Element.Flag] ~= nil then
                    Element:SetValue(DecodedJSON[Element.Flag])
                end
            end
        end
    end
    function Window:DeleteConfig(PFName,Name)
        if table.find(GetConfigs(PFName),Name) then
            delfile(PFName.."\\Configs\\"..Name..".json")
        end
    end
    function Window:GetDefaultConfig(PFName)
        if not isfolder(PFName) then makefolder(PFName) end
        if not isfolder(PFName.."\\Configs") then makefolder(PFName.."\\Configs") end
        if not isfile(PFName.."\\DefaultConfig.txt") then writefile(PFName.."\\DefaultConfig.txt","") end

        local DefaultConfig = readfile(PFName.."\\DefaultConfig.txt")
        if table.find(GetConfigs(PFName),DefaultConfig) then
            return DefaultConfig
        end
    end
    function Window:LoadDefaultConfig(PFName)
        if not isfolder(PFName) then makefolder(PFName) end
        if not isfolder(PFName.."\\Configs") then makefolder(PFName.."\\Configs") end
        if not isfile(PFName.."\\DefaultConfig.txt") then writefile(PFName.."\\DefaultConfig.txt","") end

        local DefaultConfig = readfile(PFName.."\\DefaultConfig.txt")
        if table.find(GetConfigs(PFName),DefaultConfig) then
            Window:LoadConfig(PFName,DefaultConfig)
        end
    end

    Window.Background = WindowAsset.Background
    return WindowAsset
end
local function InitTab(ScreenAsset,WindowAsset,Window,Tab)
    local TabButtonAsset = GetAsset("Tab/TabButton")
    local TabAsset = GetAsset("Tab/Tab")

    TabButtonAsset.Parent = WindowAsset.TabButtonContainer
    TabButtonAsset.Text = Tab.Name
    TabButtonAsset.Highlight.BackgroundColor3 = Window.Color
    TabButtonAsset.Size = UDim2.new(0,TabButtonAsset.TextBounds.X + 6,1,-1)
    TabAsset.Parent = WindowAsset.TabContainer
    TabAsset.Visible = false

    table.insert(Window.Colorable,TabButtonAsset.Highlight)
    TabAsset.LeftSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if ChooseTabSide(TabAsset,"Longest") == TabAsset.LeftSide then
            TabAsset.CanvasSize = UDim2.new(0,0,0,TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y + 21)
        else
            TabAsset.CanvasSize = UDim2.new(0,0,0,TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y + 21)
        end
    end)
    TabAsset.RightSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if ChooseTabSide(TabAsset,"Longest") == TabAsset.LeftSide then
            TabAsset.CanvasSize = UDim2.new(0,0,0,TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y + 21)
        else
            TabAsset.CanvasSize = UDim2.new(0,0,0,TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y + 21)
        end
    end)
    
    -- Mobile-friendly tab switching
    local touchStartTime
    TabButtonAsset.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            touchStartTime = os.clock()
        end
    end)
    
    TabButtonAsset.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local touchDuration = os.clock() - touchStartTime
            if touchDuration < 0.3 then -- Only register as tap if short duration
                ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
            end
        end
    end)

    if #WindowAsset.TabContainer:GetChildren() == 1 then
        ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
    end

    function Tab:SetName(Name)
        Tab.Name = Name
        TabButtonAsset.Text = Name
        TabButtonAsset.Size = UDim2.new(0,TabButtonAsset.TextBounds.X + 6,1,-1)
    end

    return function(Side)
        return ChooseTabSide(TabAsset,Side)
    end
end
local function InitSection(Parent,Section)
    local SectionAsset = GetAsset("Section/Section")

    SectionAsset.Parent = Parent
    SectionAsset.Title.Text = Section.Name
    SectionAsset.Title.Size = UDim2.new(0,SectionAsset.Title.TextBounds.X + 6,0,2)

    SectionAsset.Container.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SectionAsset.Size = UDim2.new(1,0,0,SectionAsset.Container.ListLayout.AbsoluteContentSize.Y + 15)
    end)

    function Section:SetName(Name)
        Section.Name = Name
        SectionAsset.Title.Text = Name
        SectionAsset.Title.Size = UDim2.new(0,Section.Title.TextBounds.X + 6,0,2)
    end

    return SectionAsset.Container
end
local function InitDivider(Parent,Divider)
    local DividerAsset = GetAsset("Divider/Divider")

    DividerAsset.Parent = Parent
    DividerAsset.Title.Text = Divider.Text

    DividerAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
        if DividerAsset.Title.TextBounds.X > 0 then
            DividerAsset.Size = UDim2.new(1,0,0,DividerAsset.Title.TextBounds.Y)
            DividerAsset.Left.Size = UDim2.new(0.5,-(DividerAsset.Title.TextBounds.X / 2) - 5,0,2)
            DividerAsset.Right.Position = UDim2.new(0.5,(DividerAsset.Title.TextBounds.X / 2) + 5,0.5,0)
            DividerAsset.Right.Size = UDim2.new(0.5,-(DividerAsset.Title.TextBounds.X / 2) - 5,0,2)
        else
            DividerAsset.Size = UDim2.new(1,0,0,2)
            DividerAsset.Left.Size = UDim2.new(1,0,0,2)
            DividerAsset.Right.Position = UDim2.new(0,0,0.5,0)
            DividerAsset.Right.Size = UDim2.new(1,0,0,2)
        end
    end)

    function Divider:SetText(Text)
        Divider.Text = Text
        DividerAsset.Title.Text = Text
    end
end
local function InitLabel(Parent,Label)
    local LabelAsset = GetAsset("Label/Label")

    LabelAsset.Parent = Parent
    LabelAsset.Text = Label.Text

    LabelAsset:GetPropertyChangedSignal("TextBounds"):Connect(function()
        LabelAsset.Size = UDim2.new(1,0,0,LabelAsset.TextBounds.Y)
    end)

    function Label:SetText(Text)
        Label.Text = Text
        LabelAsset.Text = Text
    end
end
local function InitButton(Parent,ScreenAsset,Window,Button)
    local ButtonAsset = GetAsset("Button/Button")

    ButtonAsset.Parent = Parent
    ButtonAsset.Title.Text = Button.Name

    table.insert(Window.Colorable,ButtonAsset)
    Button.Connection = ButtonAsset.MouseButton1Click:Connect(Button.Callback)

    ButtonAsset.MouseButton1Down:Connect(function()
        ButtonAsset.BorderColor3 = Window.Color
    end)
    ButtonAsset.MouseButton1Up:Connect(function()
        ButtonAsset.BorderColor3 = Color3.new(0,0,0)
    end)
    ButtonAsset.MouseLeave:Connect(function()
        ButtonAsset.BorderColor3 = Color3.new(0,0,0)
    end)
    ButtonAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
        ButtonAsset.Size = UDim2.new(1,0,0,ButtonAsset.Title.TextBounds.Y + 2)
    end)
    
    -- Mobile touch support
    ButtonAsset.TouchTap:Connect(function()
        Button.Callback()
    end)

    function Button:SetName(Name)
        Button.Name = Name
        ButtonAsset.Title.Text = Name
    end
    function Button:SetCallback(Callback)
        Button.Callback = Callback
        Button.Connection:Disconnect()
        Button.Connection = ButtonAsset.MouseButton1Click:Connect(Callback)
    end
    function Button:ToolTip(Text)
        InitToolTip(ButtonAsset,ScreenAsset,Text)
    end
end
local function InitToggle(Parent,ScreenAsset,Window,Toggle)
    local ToggleAsset = GetAsset("Toggle/Toggle")

    ToggleAsset.Parent = Parent
    ToggleAsset.Title.Text = Toggle.Name
    ToggleAsset.Tick.BackgroundColor3 = Toggle.Value and Window.Color or Color3.fromRGB(60,60,60)

    table.insert(Window.Colorable,ToggleAsset.Tick)
    
    local function handleInput(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Toggle.Value = not Toggle.Value
            Window.Flags[Toggle.Flag] = Toggle.Value
            Toggle.Callback(Toggle.Value)
            ToggleAsset.Tick.BackgroundColor3 = Toggle.Value and Window.Color or Color3.fromRGB(60,60,60)
        end
    end
    
    ToggleAsset.InputBegan:Connect(handleInput)
    ToggleAsset.TouchTap:Connect(handleInput) -- Mobile touch support
    
    ToggleAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
        ToggleAsset.Size = UDim2.new(1,0,0,ToggleAsset.Title.TextBounds.Y)
    end)

    function Toggle:SetName(Name)
        Toggle.Name = Name
        ToggleAsset.Title.Text = Name
    end
    function Toggle:SetValue(Boolean)
        Toggle.Value = Boolean
        Window.Flags[Toggle.Flag] = Toggle.Value
        Toggle.Callback(Toggle.Value)
        ToggleAsset.Tick.BackgroundColor3 = Toggle.Value and Window.Color or Color3.fromRGB(60,60,60)
    end
    function Toggle:SetCallback(Callback)
        Toggle.Callback = Callback
    end
    function Toggle:ToolTip(Text)
        InitToolTip(ToggleAsset,ScreenAsset,Text)
    end
    function Toggle:Keybind(Keybind)
        Keybind = GetType(Keybind,{},"table")
        Keybind.Flag = GetType(Keybind.Flag,Toggle.Flag.."/Keybind","string")

        Keybind.Value = GetType(Keybind.Value,"NONE","string")
        Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
        Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")

        Window.Elements[#Window.Elements + 1] = Keybind
        Window.Flags[Keybind.Flag] = Keybind.Value

        ToggleAsset.Keybind.Visible = true
        ToggleAsset.Keybind.Text = "[ " .. Keybind.Value .. " ]"
        Keybind.WaitingForBind = false

        ToggleAsset.Keybind.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                ToggleAsset.Keybind.Text = "[ ... ]"
                Keybind.WaitingForBind = true
            end
        end)
        ToggleAsset.Keybind:GetPropertyChangedSignal("TextBounds"):Connect(function()
            ToggleAsset.Keybind.Size = UDim2.new(0,ToggleAsset.Keybind.TextBounds.X,1,0)
            ToggleAsset.Title.Size = UDim2.new(1,-ToggleAsset.Keybind.Size.X.Offset - 20,1,0)
        end)

        UserInputService.InputBegan:Connect(function(Input)
            local Key = tostring(Input.KeyCode):gsub("Enum.KeyCode.","")
            if Keybind.WaitingForBind and Input.UserInputType == Enum.UserInputType.Keyboard then
                if not table.find(Keybind.Blacklist,Key) then
                    ToggleAsset.Keybind.Text = "[ " .. Key .. " ]"
                    Keybind.Value = Key
                else
                    if Keybind.DoNotClear then
                        ToggleAsset.Keybind.Text = "[ " .. Keybind.Value .. " ]"
                    else
                        ToggleAsset.Keybind.Text = "[ NONE ]"
                        Keybind.Value = "NONE"
                    end
                end

                Keybind.WaitingForBind = false
                Window.Flags[Keybind.Flag] = Keybind.Value
                Keybind.Callback(Keybind.Value,false)
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                if Key == Keybind.Value then
                    Toggle.Value = not Toggle.Value 
                    Window.Flags[Toggle.Flag] = Toggle.Value

                    Toggle.Callback(Toggle.Value)
                    Keybind.Callback(Keybind.Value,true)
                    ToggleAsset.Tick.BackgroundColor3 = Toggle.Value and Window.Color or Color3.fromRGB(60,60,60)
                end
            end
            if Keybind.Mouse then
                local Key = tostring(Input.UserInputType):gsub("Enum.UserInputType.","")
                if Keybind.WaitingForBind and Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Keybind.WaitingForBind and Input.UserInputType == Enum.UserInputType.MouseButton2
                    or Keybind.WaitingForBind and Input.UserInputType == Enum.UserInputType.MouseButton3 then
                    ToggleAsset.Keybind.Text = "[ " .. Key .. " ]"

                    Keybind.Value = Key
                    Keybind.WaitingForBind = false
                    Window.Flags[Keybind.Flag] = Keybind.Value
                    Keybind.Callback(Keybind.Value,false)
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.MouseButton2
                    or Input.UserInputType == Enum.UserInputType.MouseButton3 then

                    if Key == Keybind.Value then
                        Toggle.Value = not Toggle.Value
                        Window.Flags[Toggle.Flag] = Toggle.Value

                        Toggle.Callback(Toggle.Value)
                        Keybind.Callback(Keybind.Value,true)
                        ToggleAsset.Tick.BackgroundColor3 = Toggle.Value and Window.Color or Color3.fromRGB(60,60,60)
                    end
                end
            end
        end)
        UserInputService.InputEnded:Connect(function(Input)
            local Key = tostring(Input.KeyCode):gsub("Enum.KeyCode.","")
            if Input.UserInputType == Enum.UserInputType.Keyboard then
                if Key == Keybind.Value then
                    Keybind.Callback(Keybind.Value,false)
                end
            end
            if Keybind.Mouse then
                local Key = tostring(Input.UserInputType):gsub("Enum.UserInputType.","")
                if Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.MouseButton2
                    or Input.UserInputType == Enum.UserInputType.MouseButton3 then

                    if Key == Keybind.Value then
                        Keybind.Callback(Keybind.Value,false)
                    end
                end
            end
        end)
        function Keybind:SetValue(Key)
            ToggleAsset.Keybind.Text = "[ " .. tostring(Key) .. " ]"
            Keybind.Value = Key
            Keybind.WaitingForBind = false
            Window.Flags[Keybind.Flag] = Keybind.Value
            Keybind.Callback(Keybind.Value,false)
        end
        function Keybind:SetCallback(Callback)
            Keybind.Callback = Callback
        end

        return Keybind
    end
end
local function InitSlider(Parent,ScreenAsset,Window,Slider)
    local SliderAsset = GetAsset("Slider/Slider")

    SliderAsset.Parent = Parent
    SliderAsset.Title.Text = Slider.Name
    Slider.Value = tonumber(string.format("%." .. Slider.Precise .. "f",Slider.Value))
    SliderAsset.Background.Bar.Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min),0,1,0)
    SliderAsset.Background.Bar.BackgroundColor3 = Window.Color
    table.insert(Window.Colorable,SliderAsset.Background.Bar)

    if #Slider.Unit == 0 then
        SliderAsset.Value.PlaceholderText = Slider.Value
    else
        SliderAsset.Value.PlaceholderText = Slider.Value .. " " .. Slider.Unit
    end

    local function UpdateVisual(Value)
        Slider.Value = tonumber(string.format("%." .. Slider.Precise .. "f",Value))
        SliderAsset.Background.Bar.Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min),0,1,0)
        if #Slider.Unit == 0 then
            SliderAsset.Value.PlaceholderText = Slider.Value
        else
            SliderAsset.Value.PlaceholderText = Slider.Value .. " " .. Slider.Unit
        end

        Window.Flags[Slider.Flag] = Slider.Value
        Slider.Callback(Slider.Value)
    end
    local function AttachToMouse(Input)
        local XScale = math.clamp((Input.Position.X - SliderAsset.Background.AbsolutePosition.X) / SliderAsset.Background.AbsoluteSize.X,0,1)
        local SliderPrecise = math.clamp(XScale * (Slider.Max - Slider.Min) + Slider.Min,Slider.Min,Slider.Max)
        UpdateVisual(SliderPrecise)
    end

    function Slider:SetName(Name)
        Slider.Name = Name
        SliderAsset.Title.Text = Name
    end
    function Slider:SetValue(Value)
        UpdateVisual(Value)
    end
    function Slider:SetCallback(Callback)
        Slider.Callback = Callback
    end
    function Slider:ToolTip(Text)
        InitToolTip(SliderAsset,ScreenAsset,Text)
    end

    SliderAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
        SliderAsset.Value.Size = UDim2.new(0,SliderAsset.Value.TextBounds.X,0,16)
        SliderAsset.Title.Size = UDim2.new(1,-SliderAsset.Value.Size.X.Offset,0,16)
        SliderAsset.Size = UDim2.new(1,0,0,SliderAsset.Title.TextBounds.Y + 8)
    end)
    SliderAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
        SliderAsset.Value.Size = UDim2.new(0,SliderAsset.Value.TextBounds.X,0,16)
        SliderAsset.Title.Size = UDim2.new(1,-SliderAsset.Value.Size.X.Offset,0,16)
    end)
    SliderAsset.Value.FocusLost:Connect(function()
        if not tonumber(SliderAsset.Value.Text) then
            SliderAsset.Value.Text = Slider.Value
        elseif tonumber(SliderAsset.Value.Text) <= Slider.Min then
            SliderAsset.Value.Text = Slider.Min
        elseif tonumber(SliderAsset.Value.Text) >= Slider.Max then
            SliderAsset.Value.Text = Slider.Max
        end
        UpdateVisual(SliderAsset.Value.Text)
        SliderAsset.Value.Text = ""
    end)
    
    -- Mobile-friendly slider implementation
    local touchStartTime
    SliderAsset.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            touchStartTime = os.clock()
            AttachToMouse(Input)
            Slider.Active = true
        end
    end)
    
    SliderAsset.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local touchDuration = os.clock() - touchStartTime
            if touchDuration > 0.3 then -- Only register as drag if long enough
                Slider.Active = false
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(Input)
        if Slider.Active and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            AttachToMouse(Input)
        end
    end)
end
local function InitTextbox(Parent,ScreenAsset,Window,Textbox)
    local TextboxAsset = GetAsset("Textbox/Textbox")

    TextboxAsset.Parent = Parent
    TextboxAsset.Title.Text = Textbox.Name
    TextboxAsset.Background.Input.Text = Textbox.Value
    TextboxAsset.Background.Input.PlaceholderText = Textbox.Placeholder

    TextboxAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
        TextboxAsset.Size = UDim2.new(1,0,0,(TextboxAsset.Title.TextBounds.Y + 2) + (TextboxAsset.Background.Input.TextBounds.Y + 2))
    end)
    TextboxAsset.Background.Input:GetPropertyChangedSignal("TextBounds"):Connect(function()
        TextboxAsset.Background.Size = UDim2.new(1,0,0,TextboxAsset.Background.Input.TextBounds.Y + 2)
    end)
    TextboxAsset.Background.Input.FocusLost:Connect(function(EnterPressed)
        if not EnterPressed then return end
        Textbox.Value = TextboxAsset.Background.Input.Text
        Window.Flags[Textbox.Flag] = Textbox.Value
        Textbox.Callback(Textbox.Value)
        if Textbox.AutoClear then
            TextboxAsset.Background.Input.Text = ""
        end
    end)
    
    -- Mobile touch support
    TextboxAsset.TouchTap:Connect(function()
        TextboxAsset.Background.Input:CaptureFocus()
    end)

    function Textbox:SetName(Name)
        Textbox.Name = Name
        TextboxAsset.Title.Text = Name
    end
    function Textbox:SetValue(Text)
        Textbox.Value = Text
        Window.Flags[Textbox.Flag] = Textbox.Value
        TextboxAsset.Background.Input.Text = Textbox.Value
        Textbox.Callback(Textbox.Value)
    end
    function Textbox:SetPlaceholder(Text)
        Textbox.Placeholder = Text
        TextboxAsset.Background.Input.PlaceholderText = Textbox.Placeholder
    end
    function Textbox:SetCallback(Callback)
        Textbox.Callback = Callback
    end
    function Textbox:ToolTip(Text)
        InitToolTip(TextboxAsset,ScreenAsset,Text)
    end
end
local function InitKeybind(Parent,ScreenAsset,Window,Keybind)
    local KeybindAsset = GetAsset("Keybind/Keybind")

    KeybindAsset.Parent = Parent
    KeybindAsset.Title.Text = Keybind.Name
    KeybindAsset.Value.Text = "[ " .. Keybind.Value .. " ]"
    Keybind.WaitingForBind = false

    KeybindAsset.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            KeybindAsset.Value.Text = "[ ... ]"
            Keybind.WaitingForBind = true
        end
    end)
    KeybindAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
        KeybindAsset.Size = UDim2.new(1,0,0,KeybindAsset.Title.TextBounds.Y)
    end)
    KeybindAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
        KeybindAsset.Value.Size = UDim2.new(0,KeybindAsset.Value.TextBounds.X,1,0)
        KeybindAsset.Title.Size = UDim2.new(1,-KeybindAsset.Value.Size.X.Offset,1,0)
    end)
    UserInputService.InputBegan:Connect(function(Input)
        local Key = tostring(Input.KeyCode):gsub("Enum.KeyCode.","")
        if Keybind.WaitingForBind and Input.UserInputType == Enum.UserInputType.Keyboard then
            if not table.find(Keybind.Blacklist,Key) then
                KeybindAsset.Value.Text = "[ " .. Key .. " ]"
                Keybind.Value = Key
            else
                if Keybind.DoNotClear then
                    KeybindAsset.Value.Text = "[ " .. Keybind.Value .. " ]"
                else
                    KeybindAsset.Value.Text = "[ NONE ]"
                    Keybind.Value = "NONE"
                end
            end

            Keybind.WaitingForBind = false
            Window.Flags[Keybind.Flag] = Keybind.Value
            Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
        elseif Input.UserInputType == Enum.UserInputType.Keyboard then
            if Key == Keybind.Value then
                Keybind.Toggle = not Keybind.Toggle
                Keybind.Callback(Keybind.Value,true,Keybind.Toggle)
            end
        end
        if Keybind.Mouse then
            local Key = tostring(Input.UserInputType):gsub("Enum.UserInputType.","")
            if Keybind.WaitingForBind and Input.UserInputType == Enum.UserInputType.MouseButton1
                or Keybind.WaitingForBind and Input.UserInputType == Enum.UserInputType.MouseButton2
                or Keybind.WaitingForBind and Input.UserInputType == Enum.UserInputType.MouseButton3 then
                KeybindAsset.Value.Text = "[ " .. Key .. " ]"

                Keybind.Value = Key
                Keybind.WaitingForBind = false
                Window.Flags[Keybind.Flag] = Keybind.Value
                Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
            elseif Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.MouseButton2
                or Input.UserInputType == Enum.UserInputType.MouseButton3 then

                if Key == Keybind.Value then
                    Keybind.Toggle = not Keybind.Toggle
                    Keybind.Callback(Keybind.Value,true,Keybind.Toggle)
                end
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(Input)
        local Key = tostring(Input.KeyCode):gsub("Enum.KeyCode.","")
        if Input.UserInputType == Enum.UserInputType.Keyboard then
            if Key == Keybind.Value then
                Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
            end
        end
        if Keybind.Mouse then
            local Key = tostring(Input.UserInputType):gsub("Enum.UserInputType.","")
            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.MouseButton2
                or Input.UserInputType == Enum.UserInputType.MouseButton3 then

                if Key == Keybind.Value then
                    Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
                end
            end
        end
    end)


    function Keybind:SetName(Name)
        Keybind.Name = Name
        KeybindAsset.Title.Text = Name
    end
    function Keybind:SetValue(Key)
        KeybindAsset.Value.Text = "[ " .. tostring(Key) .. " ]"
        Keybind.Value = Key
        Keybind.WaitingForBind = false
        Window.Flags[Keybind.Flag] = Keybind.Value
        Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
    end
    function Keybind:SetCallback(Callback)
        Keybind.Callback = Callback
    end
    function Keybind:ToolTip(Text)
        InitToolTip(KeybindAsset,ScreenAsset,Text)
    end
end
local function InitDropdown(Parent,ScreenAsset,Window,Dropdown)
    local DropdownAsset = GetAsset("Dropdown/Dropdown")
    local OptionContainerAsset = GetAsset("Dropdown/OptionContainer")
    DropdownAsset.Parent = Parent
    DropdownAsset.Title.Text = Dropdown.Name
    
    -- Create a scrolling frame for the options
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Name = "OptionScroller"
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.Size = UDim2.new(1, 0, 0, 0) -- Start with height 0
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.ScrollBarThickness = 6 -- Thicker scrollbar for mobile
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    ScrollFrame.ScrollingEnabled = true
    ScrollFrame.Visible = false
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 2)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ScrollFrame
    
    OptionContainerAsset.Parent = ScrollFrame
    ScrollFrame.Parent = ScreenAsset
    
    -- Mobile-friendly touch handling
    local touchStartPos, touchStartTime
    local touchDebounce = false
    
    local function UpdateDropdownPosition()
        local maxHeight = math.min(300, ScrollFrame.AbsoluteWindowSize.Y - DropdownAsset.AbsolutePosition.Y - 50)
        ScrollFrame.Size = UDim2.new(1, 0, 0, maxHeight)
        ScrollFrame.Position = UDim2.new(0, DropdownAsset.AbsolutePosition.X, 0, DropdownAsset.AbsolutePosition.Y + DropdownAsset.AbsoluteSize.Y + 2)
    end

    local function HandleTouchInput(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if input.UserInputState == Enum.UserInputState.Begin then
                touchStartPos = input.Position
                touchStartTime = os.clock()
            elseif input.UserInputState == Enum.UserInputState.End then
                local touchEndPos = input.Position
                local touchDuration = os.clock() - touchStartTime
                local touchDistance = (touchEndPos - touchStartPos).magnitude
                
                -- If it's a tap (short duration and small distance)
                if touchDuration < 0.3 and touchDistance < 10 then
                    if not touchDebounce then
                        touchDebounce = true
                        
                        if not ScrollFrame.Visible and OptionContainerAsset.ListLayout.AbsoluteContentSize.Y ~= 0 then
                            UpdateDropdownPosition()
                            ScrollFrame.Visible = true
                        elseif ScrollFrame.Visible then
                            ScrollFrame.Visible = false
                        end
                        
                        task.delay(0.3, function() touchDebounce = false end)
                    end
                end
            end
        end
    end

    DropdownAsset.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not ScrollFrame.Visible and OptionContainerAsset.ListLayout.AbsoluteContentSize.Y ~= 0 then
                UpdateDropdownPosition()
                ScrollFrame.Visible = true
            elseif ScrollFrame.Visible then
                ScrollFrame.Visible = false
            end
        end
    end)
    
    -- Connect touch input handler
    UserInputService.TouchStarted:Connect(HandleTouchInput)
    UserInputService.TouchEnded:Connect(HandleTouchInput)

    DropdownAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
        DropdownAsset.Title.Size = UDim2.new(1, 0, 0, DropdownAsset.Title.TextBounds.Y + 2)
        DropdownAsset.Background.Position = UDim2.new(0.5, 0, 0, DropdownAsset.Title.Size.Y.Offset)
        DropdownAsset.Size = UDim2.new(1, 0, 0, DropdownAsset.Title.Size.Y.Offset + DropdownAsset.Background.Size.Y.Offset)
    end)

    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end)

    local function SetOptionState(Option, Toggle)
        local Selected = {}

        -- Value Setting
        if Option.Mode == "Button" then
            for Index, Option in pairs(Dropdown.List) do
                if Option.Mode == "Button" then
                    if Option.Instance then
                        Option.Instance.BorderColor3 = Color3.fromRGB(60, 60, 60)
                    end
                    Option.Value = false
                end
            end
            Option.Value = true
            ScrollFrame.Visible = false
        elseif Option.Mode == "Toggle" then
            Option.Value = Toggle
        end

        Option.Instance.BorderColor3 = Option.Value and Window.Color or Color3.fromRGB(60, 60, 60)

        -- Selected Setting
        for Index, Option in pairs(Dropdown.List) do
            if Option.Value then
                Selected[#Selected + 1] = Option.Name
            end
        end

        -- Dropdown Title Setting
        if #Selected == 0 then
            DropdownAsset.Background.Value.Text = "..."
        else
            DropdownAsset.Background.Value.Text = table.concat(Selected, ", ")
        end

        Dropdown.Value = Selected
        if Option.Callback then
            Option.Callback(Dropdown.Value, Option)
        end
        Window.Flags[Dropdown.Flag] = Dropdown.Value
    end

    for Index, Option in pairs(Dropdown.List) do
        local OptionAsset = GetAsset("Dropdown/Option")
        OptionAsset.Parent = OptionContainerAsset
        OptionAsset.Title.Text = Option.Name
        Option.Instance = OptionAsset

        table.insert(Window.Colorable, OptionAsset)
        
        OptionAsset.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                SetOptionState(Option, not Option.Value)
            end
        end)
        
        OptionAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
            OptionAsset.Size = UDim2.new(1, 0, 0, OptionAsset.Title.TextBounds.Y + 2)
        end)
    end

    for Index, Option in pairs(Dropdown.List) do
        if Option.Value then
            SetOptionState(Option, Option.Value)
        end
    end

    function Dropdown:BulkAdd(Table)
        for Index, Option in pairs(Table) do
            local OptionAsset = GetAsset("Dropdown/Option")
            OptionAsset.Parent = OptionContainerAsset
            OptionAsset.Title.Text = Option.Name
            Option.Instance = OptionAsset

            table.insert(Window.Colorable, OptionAsset)
            table.insert(Dropdown.List, Option)
            OptionAsset.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    SetOptionState(Option, not Option.Value)
                end
            end)
            OptionAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
                OptionAsset.Size = UDim2.new(1, 0, 0, OptionAsset.Title.TextBounds.Y + 2)
            end)
        end
        for Index, Option in pairs(Dropdown.List) do
            if Option.Value then
                SetOptionState(Option, Option.Value)
            end
        end
    end

    function Dropdown:RemoveOption(Name)
        for Index, Option in pairs(Dropdown.List) do
            if Option.Name == Name then
                Option.Instance:Destroy()
                Dropdown.List[Index] = nil
            end
        end
    end

    function Dropdown:Clear()
        for Index, Option in pairs(Dropdown.List) do
            Option.Instance:Destroy()
            Dropdown.List[Index] = nil
        end
    end

    function Dropdown:SetValue(Options)
        if #Options == 0 then
            DropdownAsset.Background.Value.Text = "..."
            return
        end
        for Index, Option in pairs(Dropdown.List) do
            if table.find(Options, Option.Name) then
                SetOptionState(Option, true)
            else
                if Option.Mode ~= "Button" then
                    SetOptionState(Option, false)
                end
            end
        end
    end

    function Dropdown:SetName(Name)
        Dropdowndown.Name.Name = Name = Name
        Drop
        DropdownAssetdownAsset.Title.Text = Name
    end

    function.Title.Text = Name
    end

    function Dropdown:Tool Dropdown:ToolTip(Text)
        InitToolTipTip(Text)
        InitToolTip(DropdownAsset, ScreenAsset, Text)
    end(DropdownAsset, ScreenAsset, Text)
    end
    
    -- Close dropdown when
    
    -- Close dropdown when clicking outside
    UserInput clicking outside
    UserInputService.InputService.InputBeganBegan:Connect:Connect(function(input)
        if (input.User(function(input)
        if (input.UserInputTypeInputType == Enum.UserInput == Enum.UserInputType.MouseButton1 orType.MouseButton1 or input.User input.UserInputType == EnumInputType == Enum.UserInputType.T.UserInputouch) and ScrollFrame.Visible thenType.Touch) and ScrollFrame.Visible then

                       local mousePos = input local mousePos = input.Position.Position
            if not DropdownAsset:Is
            if not DropdownAsset:DescendantOf(game) then return endIsDescendantOf(game
            
            local isInDropdown) then return end
            
            local isInDropdown = PointInRectangle(
                mousePos = PointInRectangle(
                mousePos,
                DropdownAsset.A,
                DropdownAssetbsolutePosition.AbsolutePosition,
                DropdownAsset.Absolute,
                DropdownAssetPosition + DropdownAsset.Abs.AbsolutePosition + DropdownAssetoluteSize
            )
.AbsoluteSize
            
            local isIn            )
            
            local isInOptions = PointInOptions = PointInRectangleRectangle(
                mouse(
                mousePos,
                ScrollFrame.AbsolutePos,
                ScrollPosition,
                ScrollFrame.AFrame.AbsolutePosition,
                ScrollFrame.AbsolutePosition + ScrollFramebsolutePosition + ScrollFrame.Abs.AbsoluteSizeoluteSize
           
            )
            
 )
            
            if            if not isInDropdown not isInDropdown and and not isIn not isInOptions then
                ScrollFrame.Options then
               Visible = false
            ScrollFrame.Visible = false end
       
            end end
    end
        end
    end)
    
   )
    
    -- Helper -- Helper function to check if function to check if a point a point is within a rectangle
    is within a rectangle
    local function PointInRectangle(point, corner local function PointInRectangle(point, corner1, corner2)
       1, corner2)
        local minX local minX = = math.min(corner1.X, corner2.X math.min(corner1.X, corner2.X)
       )
        local maxX = math.max(corner1.X, corner local maxX = math.max(corner1.X, corner2.X2.X)
        local minY)
        local minY = math.min(cor = math.min(corner1.Y, corner2ner1.Y, corner2.Y.Y)
        local maxY)
        local maxY = math.max(corner1.Y = math.max(corner1.Y, corner, corner2.Y2.Y)
        
        return point.X)
        
        return point.X >= minX and >= minX and point.X <= maxX and point.Y >= min point.X <= maxX and point.Y >= minY andY and point.Y <= maxY point.Y <= maxY
    end
end
    end
end
local function
local function InitColorpicker(Parent, InitColorpicker(Parent,ScreenAsset,Window,Colorpicker)
   ScreenAsset,Window,Colorpicker)
    local ColorpickerAsset = GetAsset("Colorpicker local ColorpickerAsset = GetAsset("Colorpicker/Color/Colorpicker")
    local PaletteAssetpicker")
    local PaletteAsset = Get = GetAsset("Colorpicker/PalAsset("Colorpicker/Palette")
    ColorpickerAssetette")
    ColorpickerAsset.Parent = Parent.Parent = Parent
   
    ColorpickerAsset.Title.Text = ColorpickerAsset.Title.Text = Colorpicker.Name
    PaletteAsset.P Colorpicker.Name
    PaletteAsset.Parent = ScreenAsset

arent = ScreenAsset

    local PaletteRender = nil
    local    local PaletteRender = nil
    local S SVRender = nil
    localVRender = nil
    local HueRender HueRender = nil
    local AlphaRender = = nil
    local AlphaRender = nil nil

    local function TableToColor

    local function TableToColor((Table)
        if type(TableTable)
        if type(Table) ~= ") ~= "table" then returntable" then Table end
        return Color3.fromHSV(Table[ return Table end
        return Color3.fromHSV(Table[1],Table[2],1],Table[2],Table[3Table[3])
    end])
    end
    local function
    local function FormatToString(Color)
        return math.round(Color.R * 255) FormatToString(Color)
        return math.round(Color.R *  .. "," .. math.round(Color255) .. "," .. math.round(Color.G * 255) ...G * 255) .. "," .. "," .. math.round(Color.B math.round(Color.B * 255 * 255)
    end

    local function Update)
    end

    local()
        Colorpicker.Value[6 function Update()
        Colorpicker.Value[6] = TableToColor(Color] = TableToColor(Colorpicker.Valuepicker.Value)
       )
        Colorpicker ColorpickerAsset.Color.BackAsset.Color.BackgroundColor3 = ColorpickergroundColor3 = Colorpicker.Value[6]
       .Value[6]
        PaletteAsset.SVP PaletteAsset.SVPicker.BackgroundColoricker.BackgroundColor3 = Color3.fromHSV3 = Color3.fromHSV(Color(Colorpicker.Valuepicker[1],1,.Value[1],1,11)
        Palette)
        PaletteAsset.SAsset.SVPicker.PinVPicker.Pin.Position = U.Position = UDim2Dim2.new(Colorpicker.Value[2.new(Colorpicker.Value],0,[2],01 - Colorpicker,1 - Color.Value[3picker.Value[3],0)
       ],0)
        PaletteAsset.Hue PaletteAsset.Hue.Pin.Pin.Position = U.Position = UDim2Dim2.new(1 - Color.new(1 - Colorpicker.Value[1],0picker.Value[1],0,0.5,,0.5,00)

        Palette)

        PaletteAsset.Alpha.PAsset.Alpha.Pin.Position =in.Position = U UDimDim2.new(Colorpicker2.new(Colorpicker.Value.Value[4],[4],0,0,0.0.5,05,0)
        PaletteAsset)
        PaletteAsset..Alpha.ValueAlpha.Value.Text =.Text = Colorpicker.Value Colorpicker.Value[4]
        PaletteAsset.[4]
        PaletteAsset.Alpha.BackgroundAlpha.BackgroundColor3 = Colorpicker.Value[6Color3 = Colorpicker.Value[6]

        PaletteAsset.R]

        PaletteAsset.RGB.RGBBox.PlaceholderText = FormatToString(ColorGB.RGBBox.PlaceholderText = FormatToString(Colorpicker.Valuepicker.Value[6])
        PaletteAsset[6])
        PaletteAsset..HEX.HEX.HEXBox.PlaceholderTextHEXBox.Place = Colorpicker.Value[6]:holderText = Colorpicker.Value[ToHex()
        Window.Flags6]:ToHex()
        Window.Flags[Colorpicker.Flag][Colorpicker.Flag] = Colorpicker.Value
        Colorpicker.Callback(Colorpicker.Value, = Colorpicker.Value
        Colorpicker.Callback(Colorpicker.Value,Colorpicker.Value[6])
    end
Colorpicker.Value[6])
    end
    Update    Update()

    ColorpickerAsset.Title()

    ColorpickerAsset.Title:GetPropertyChangedSignal(":GetPropertyChangedSignal("TextBounds"):Connect(functionTextBounds"):Connect(function()
        Color()
        ColorpickerAsset.Size = UDimpickerAsset.Size = UDim2.new(12.new(1,0,0,,0,0,ColorpickerAsset.Title.TextColorpickerAsset.Title.TextBounds.Y)
    end)
    
   Bounds.Y)
    end)
    
    -- Mobile-friendly color -- Mobile-friendly color picker picker
    local touchStartTime
    local touchStartTime
    ColorpickerAsset.InputBegan:Connect(function(
    ColorpickerAsset.InputBeganInput)
        if (Input.UserInputType:Connect(function(Input)
        if (Input.UserInput == Enum.UserInputType.MouseButton1Type == Enum.UserInputType.Mouse or Input.UserInputType == Enum.UserInputTypeButton1 or Input.Touch) and not Palette.UserInputType == Enum.UserInputType.Touch) and not PaletteAsset.Visible thenAsset.Visible then
            touchStart
            touchStartTime = os.clock()
            PaletteTime = os.clock()
            PaletteAsset.Visible = trueAsset.Visible = true
            PaletteRender =
            PaletteRender = RunService.R RunService.RenderSteppedenderStepped:Connect(function()
                if not PaletteAsset.Visible then Palette:Connect(function()
                if not PaletteAssetRender:Disconnect() end
                Palette.Visible then PaletteRender:Disconnect() end
                PaletteAsset.Position = UDim2.newAsset.Position = UDim2.new(0,(Color(0,(ColorpickerAsset.Color.AbsolutePosition.X -pickerAsset.Color.AbsolutePosition.X - PaletteAsset.Abs PaletteAsset.AbsoluteSize.X) +oluteSize.X) +  20,0,ColorpickerAsset20,0,ColorpickerAsset.Color.AbsolutePosition.Color.AbsolutePosition.Y +.Y + 52)
            end)
        elseif 52)
            end)
        elseif (Input.UserInputType == Enum.User (Input.UserInputType == Enum.UserInputInputType.MouseButton1 or Input.UserInputType == Enum.UserType.MouseButton1 or Input.UserInputType == Enum.UserInputTypeInputType.Touch.Touch) then
            local touchDuration = os.clock()) then
            local touchDuration = os.clock() - touchStartTime - touch
            if touchDuration > 0StartTime
            if touchDuration > 0.3 then --.3 then -- Only Only close if it was a close if it was a long press
                long press
                PaletteRender PaletteRender:Disconnect()
                Palette:Disconnect()
                PaletteAsset.Visible = falseAsset.Visible = false
            end
       
            end
        end
    end end
    end)
    
    PaletteAsset)
    
    Palette.SVPickerAsset.SVPicker.InputBegan:Connect(function(Input)
       .InputBegan:Connect(function(Input)
        if Input.UserInputType == if Input.UserInputType == Enum.User Enum.UserInputTypeInputType.MouseButton.MouseButton1 or1 or Input.UserInputType == Enum Input.UserInputType == Enum.User.UserInputType.Touch then
            if SVRender then
                SVRInputType.Touch then
            if SVRender then
                Sender:Disconnect()
VRender:Disconnect()
            end            end
            SVRender = Run
            SVRender = RunService.RService.RenderSteenderStepped:pped:Connect(function()
               Connect(function()
                if not PaletteAsset if not PaletteAsset.Visible then.Visible then SVRender:Disconnect() SVRender:Disconnect() end
                local Mouse = UserInput end
                local Mouse = UserInputService:GetMouseLocationService:GetMouseLocation()
                local()
                local ColorX = math.clamp(Mouse ColorX = math.cl.X - PaletteAsset.SVPicker.AbsolutePosition.Xamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X,0,0,Pal,PaletteAssetetteAsset.SVPicker.AbsoluteSize.X.SVPicker.AbsoluteSize.X) / PaletteAsset.SVP) / PaletteAsseticker.AbsoluteSize.X

                local Color.SVPicker.AbsoluteSize.XY = math.cl

                local ColorY = math.clamp(Mamp(Mouse.Y - (Paletteouse.Y - (Asset.SVPicker.AbsPaletteAsset.SVPicker.AbsolutePosition.Y + 36),0,PaletteAsset.SVPolutePosition.Y + 36),0icker.AbsoluteSize.Y,PaletteAsset.SVPicker.Absolute) / PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPSize.Y
                Colorpickericker.AbsoluteSize.Y
               .Value[2] = ColorX
                Color Colorpicker.Value[2] = Colorpicker.Value[3] =X
                Colorpicker.Value[3] = 1 - Color 1 - ColorY
                Update()
            end)
        end
   Y
                Update()
            end)
        end
    end end)
    PaletteAsset.SVPicker.Input)
    PaletteAsset.SVPicker.InputEndedEnded:Connect(function(Input)
        if Input.UserInputType == Enum.User:Connect(function(Input)
        if InputInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.UserInputType == Enum.User.MouseButton1 or Input.UserInputType == EnumInputType.Touch then
            if SVR.UserInputType.Touch then
            ifender then
                SVR SVRender then
                SVRender:Disconnect()
            endender:Disconnect()
            end
        end
    end)
    PaletteAsset
        end
    end.Hue.Input)
    PaletteAsset.Hue.InputBeganBegan:Connect(function(Input:Connect(function(Input)
        if)
        if Input.UserInputType == Enum.User Input.UserInputType == Enum.UserInputInputType.MouseButton1 or Input.UserInputType == EnumType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then.UserInputType.Touch then
            if HueRender then
            if HueRender then
                Hue
                HueRender:DisconnectRender:Disconnect()
            end
           ()
            end
            HueRender HueRender = Run = RunService.RenderStepped:Connect(functionService.RenderStepped:Connect(function()
                if not PaletteAsset()
                if not.Visible then PaletteAsset.Visible then HueRender:Disconnect HueRender:Disconnect() end
               () end
                local Mouse = User local Mouse = UserInputService:GetInputService:GetMouseLocation()
               MouseLocation()
                local ColorX = local ColorX = math math.clamp(Mouse.X - PaletteAsset.clamp(Mouse.X - PaletteAsset.H.Hue.AbsolutePosition.X,0ue.AbsolutePosition.X,0,PaletteAsset,PaletteAsset.Hue.AbsoluteSize.X).Hue.AbsoluteSize.X) / PaletteAsset.Hue.Absolute / PaletteAsset.Hue.AbsoluteSizeSize.X
                Colorpicker.X
                Colorpicker.Value[.Value[1] = 1 - ColorX1] = 1
                Update()
            end)
        - ColorX
                Update()
            end)
        end
    end)
    end
    end PaletteAsset.Hue.Input)
    PaletteAssetEnded:Connect.Hue.InputEnded(function(Input)
       :Connect(function(Input if Input.UserInput)
        if Input.UserInputType ==Type == Enum.User Enum.UserInputTypeInputType.MouseButton1.MouseButton1 or Input.UserInput or Input.UserInputType == Enum.UserInputTypeType == Enum.UserInputType.Touch then.Touch then
            if HueRender
            if HueRender then
                HueRender:Disconnect then
                HueRender:Disconnect()
            end
        end
    end)
()
            end
        end
    end)
    PaletteAsset.    PaletteAsset.Alpha.InputAlpha.InputBegan:Connect(function(InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInput)
        if Input.UserInputType == Enum.UserInputType.MType.MouseButton1 or Input.UserInputTypeouseButton1 or Input.UserInputType == Enum == Enum.UserInputType.T.UserInputType.Touch then
            if AlphaRender then
               ouch then
            if AlphaRender then
                AlphaRender AlphaRender::DisconnectDisconnect()
            end()
            end
            AlphaRender = RunService.RenderStepped:Connect(function
            AlphaRender = RunService.RenderStepped:Connect(function()
                if not PaletteAsset.()
                if not PaletteAsset.Visible then AlphaRender:DisconnectVisible then AlphaRender:Disconnect()() end
                local Mouse = UserInputService: end
                local Mouse = UserInputGetMouseLocation()
               Service:GetMouseLocation()
                local ColorX = math.clamp(M local ColorX = math.clamp(Mouse.X - PaletteAsset.Alpha.Aouse.X - PaletteAsset.Alpha.AbsolutePosition.XbsolutePosition.X,0,0,PaletteAsset.Alpha,PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset..AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.XAlpha.AbsoluteSize.X
                Colorpicker.Value
                Colorpicker.Value[4] =[4] = math.floor(ColorX * 10 math.floor(ColorX * 10^2) / (10^2) / (10^2) --^2) -- idk %.2f little bit broken with idk %.2f little bit broken with this
                Update()
            end)
        this
                Update()
            end)
        end
    end end
    end)
    Palette)
    PaletteAsset.Alpha.InputAsset.Alpha.InputEnded:Connect(function(Input)
        if Input.UserInputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseType == Enum.UserInputType.MouseButtonButton1 or Input.UserInputType == Enum.UserInputType1 or Input.UserInputType == Enum.UserInputType.Touch then.Touch then
            if AlphaRender then
            if AlphaRender then
                Alpha
                AlphaRender:Disconnect()
            endRender:Disconnect()
            end
        end
        end
    end)

    function Color
    end)

    function Colorpicker:SetName(Namepicker:SetName(Name)
        Colorpicker.Name =)
        Colorpicker.Name = Name Name
        ColorpickerAsset.Title.Text = Name
        ColorpickerAsset.Title.Text = Name
   
    end
    end
    function Colorpicker:Set function Colorpicker:SetCallback(Callback)
        Colorpicker.Callback =Callback(Callback)
        Colorpicker.Callback = Callback
    Callback
    end
    function Colorpicker end
    function Colorpicker:Set:SetValue(HSVAR)
        ColorpickerValue(HSVAR)
        Colorpicker.Value = HSVAR.Value = HSVAR
        Update()
    end
   
        Update()
    end
    function Color function Colorpicker:ToolTip(Textpicker:ToolTip(Text)
       )
        InitToolTip(Colorpicker InitToolTip(ColorpickerAsset,ScreenAsset,Text)
    end

    table.insert(WindowAsset,ScreenAsset,Text)
    end

    table.insert(Window.Colorable,PaletteAsset.Colorable,PaletteAsset.Rainbow.T.Rainbow.Tick)
    PaletteAsset.Rick)
    PaletteAsset.Rainbow.Tick.BackgroundColor3ainbow.Tick.BackgroundColor3 = Colorpicker.Value[5] and = Colorpicker.Value[5] and Window.Color or Color Window.Color or Color3.fromRGB(60,3.fromRGB(60,60,6060,60)
    PaletteAsset.R)
    PaletteAsset.Rainbowainbow.InputBegan:Connect(function(Input.InputBegan:Connect(function(Input)
        if Input.UserInput)
        if Input.UserInputType == Enum.UserInputTypeType == Enum.User.MouseButton1 or Input.UserInputType ==InputType.MouseButton1 or Input.UserInputType == Enum.User Enum.UserInputType.Touch then
            ColorInputType.Touch then
            Colorpicker.Value[5]picker.Value[5] = = not Colorpicker.Value[5]
            not Colorpicker.Value[5]
            PaletteAsset.Rainbow.Tick.Back PaletteAsset.Rainbow.Tick.BackgroundColor3 = ColorpickergroundColor3 = Colorpicker.Value[5].Value[5] and Window.Color or Color3.fromRGB and Window.Color or Color3.fromRGB(60,60,60)
        end
   (60,60,60)
        end
    end)
    RunService.Heartbeat end)
    RunService.Heartbeat:Connect(function()
        if Colorpicker:Connect(function()
        if Colorpicker.Value[5] then
            if.Value[5] then
            if PaletteAsset.Visible then PaletteAsset.Visible then
                Colorpicker
                Colorpicker.Value[1] = Window.Rain.Value[1] = Window.RainbowHbowHue
                Update()
            elseue
                Update()
            else 
                Colorpicker.Value 
                Colorpicker.Value[1][1] = Window.Rainbow = Window.RainbowHue
                ColorpickerHue
                Colorpicker.Value[6] = TableToColor.Value[6] = TableToColor(Colorpicker.Value)
               (Colorpicker.Value)
                ColorpickerAsset ColorpickerAsset.Color.BackgroundColor3 =.Color.BackgroundColor3 = Colorpicker.Value Colorpicker.Value[6]
                Window.Flags[Color[6]
                Windowpicker.Flag] = Colorpicker.Value
               .Flags[Colorpicker.Flag] = Colorpicker.Value
                Colorpicker.Callback(Color Colorpicker.Callback(Colorpicker.Valuepicker.Value,Colorpicker.Value[6,Colorpicker.Value[6])
            end
        end
    end])
            end
        end
    end)

    PaletteAsset.R)

    PaletteAsset.RGB.RGBBox.FocusLost:GB.RGBBox.FocusLost:Connect(function(Enter)
Connect(function(Enter)
        if not        if not Enter then return end
        local ColorString = Enter then return end
        local ColorString = string string.split(string.gsub(PaletteAsset.RGB.R.split(string.gsub(PaletteAsset.RGB.RGBBox.Text," ",""),",")
        local HueGBBox.Text," ",""),",")
        local Hue,Saturation,Value = Color,Saturation,Value = Color3.fromRGB3.fromRGB(ColorString[1],ColorString[2],ColorString[3(ColorString[1],ColorString[2],ColorString[3]):ToHSV()
       ]):ToHSV()
        Palette PaletteAsset.RGB.RGBBox.Text = ""
        Colorpicker.ValueAsset.RGB.RGBBox.Text = ""
        Colorpicker.Value[1] = Hue[1] = Hue
       
        Colorpicker.Value[2] = Saturation
        Colorpicker Colorpicker.Value[2] = Saturation
        Colorpicker.Value[3] = Value
        Update.Value[3] = Value
        Update()
    end)
    PaletteAsset()
    end)
    PaletteAsset.HEX.HEXBox.FocusLost.HEX.HEXBox.FocusLost:Connect(function(:Connect(function(EnterEnter)
        if not Enter then return end)
        if not Enter then return end
        local Hue,Saturation,
        local Hue,SValue = Color3.fromHex("#"aturation,Value = Color3.fromHex("#" .. Palette .. PaletteAsset.Asset.HEX.HEXBoxHEX.HEXBox.Text):ToHSV.Text):ToHSV()
        PaletteAsset()
        PaletteAsset.RGB.RGBBox.Text.RGB.RGBBox.Text = = ""
        Colorpicker.Value[1] = Hue ""
        Colorpicker.Value[1] = Hue
        Colorpicker.Value[2] =
        Colorpicker.Value[2] = Saturation
        Colorpicker Saturation
        Colorpicker.Value[3] = Value
        Update.Value[3] = Value
        Update()
    end)
end

local Bracket = InitScreen()
function B()
    end)
end

local Bracket = InitScreen()
function Bracket:racket:Window(Window)
    Window = GetType(Window,{},"Window(Window)
    Window = GetType(Window,{},"tabletable")
    Window.Name = GetType(Window.Name,"Window","string")
    Window.Name = GetType(Window.Name,"Window","string")
")
    Window.Color = GetType(Window.Color,Color3.new(    Window.Color = GetType(Window.Color,Color3.new(1,0.5,0.25),"Color31,0.5,0.25),"Color3")
    Window.Size = GetType(Window.Size,UD")
    Window.Size = GetType(Window.Size,UDim2im2.new(0,496,0,496),"UDim.new(0,496,0,496),"UDim2")
    Window.Position = GetType(Window.P2")
    Window.Position = GetType(Window.Position,UDim2.new(0.5,-248,0osition,UDim2.new(0.5,-248,0.5,-248),"UDim2")
    Window..5,-248),"UDim2")
    Window.Enabled = GetTypeEnabled = GetType(Window.Enabled(Window.Enabled,true,"boolean")

    Window.Rainbow,true,"boolean")

    Window.RainbowHueHue = 0
    Window.Colorable = = 0
    Window.Colorable = {}
    Window.Elements = {}
    Window.Flags = {}

    local WindowAsset = {}
    Window.Elements = {}
    Window.Flags = {}

    local WindowAsset = InitWindow InitWindow(Bracket.ScreenAsset,Window)
    function Window:(Bracket.ScreenAsset,Window)
    function Window:Tab(TTab(Tab)
        Tab = GetType(Tab,{},"ab)
        Tab = GetType(Tab,{},"table")
        Tab.Name = GetType(Tabtable")
        Tab.Name = GetType(Tab.Name,"Tab","string")
        local ChooseTab.Name,"Tab","string")
        local ChooseTab = Init = InitTab(Bracket.ScreenAsset,WindowAsset,Window,Tab)

        function Tab:AddConfigSection(PTab(Bracket.ScreenAsset,WindowAsset,Window,Tab)

        function Tab:AddConfigSection(PFNameFName,Side)
            local ConfigSection = Tab:Section({Name = "Configs",Side = Side}) do
                local ConfigList, ConfigDropdown =,Side)
            local ConfigSection = Tab:Section({Name = "Configs",Side = Side}) do
                local ConfigList, ConfigDropdown = ConfigsToList(PFName), nil
                local function ConfigsToList(PFName), nil
                local function UpdateList(Name)
                    Config UpdateList(Name)
                    ConfigDropdown:Clear()
                    ConfigListDropdown:Clear()
                    ConfigList = ConfigsToList(PFName = ConfigsToList(PFName)
                    ConfigDropdown:BulkAdd)
                    ConfigDropdown:BulkAdd(ConfigList)
                    ConfigDropdown:SetValue({Name or (ConfigList[1](ConfigList)
                    ConfigDropdown:SetValue({Name or (ConfigList[1] and ConfigList[1].Name) or nil})
                end and ConfigList[1].Name) or nil})
                end

                ConfigSection:Textbox({Name = "Create",

                ConfigSection:Textbox({Name = "Create",IgnoreIgnoreFlag = true,
                    AutoClear = true,Placeholder = "Name",Callback = function(Text)
                       Flag = true,
                    AutoClear = true,Placeholder = "Name",Callback = function(Text)
                        Window:SaveConfig(PF Window:SaveConfig(PFName,Text)
                        UpdateList(Text)
                    end})
                ConfigDropdown = ConfigName,Text)
                        UpdateList(Text)
                    end})
                ConfigDropdown = ConfigSection:Section:Dropdown({Name = "List",IgnoreFlag = true,
                    List = ConfigDropdown({Name = "List",IgnoreFlag = true,
                    List = ConfigList})
                ConfigSection:Button({Name = "Save",Callback = functionList})
                ConfigSection:Button({Name = "Save",Callback = function()
                    if ConfigDropdown.Value and ConfigDropdown.Value[1()
                    if ConfigDropdown.Value and ConfigDropdown.Value[1] then
                        Window:SaveConfig(P] then
                        Window:SaveConfig(PFName,ConfigDropdown.ValueFName,ConfigDropdown.Value[1])
                   [1])
                    end
                end})
                ConfigSection:Button({Name = "Load",Callback = function end
                end})
                ConfigSection:Button({Name = "Load",Callback = function()
                    if ConfigDropdown.Value and ConfigDropdown.Value[1] then
                        Window:LoadConfig(PFName,ConfigDropdown()
                    if ConfigDropdown.Value and ConfigDropdown.Value[1] then
                        Window:LoadConfig.Value[1])
                    end
                end})
                ConfigSection:Button({(PFName,ConfigDropdown.Value[1])
                    end
                end})
                ConfigSection:Button({Name = "Delete",Callback = function()
                    if ConfigDropdown.Value and ConfigDropdown.ValueName = "Delete",Callback = function()
                    if ConfigDropdown.Value and ConfigDropdown.Value[1] then
                        Window:[1] then
                        Window:DeleteConfig(PFName,ConfigDropdown.Value[1])
                        UpdateListDeleteConfig(PFName,ConfigDropdown.Value[1])
                        UpdateList()
                    end
                end})

                local DefaultConfig()
                    end
                end})

                local DefaultConfig = = Window:GetDefaultConfig(PFName)
                local ConfigDivider = ConfigSection:Divider({Text = DefaultConfig Window:GetDefaultConfig(PFName)
                local ConfigDivider = ConfigSection:Divider({Text = DefaultConfig
                    and "Default Config\n<font color=\"rgb(189,189
                    and "Default Config\n<font color=\"rgb(189,189,189)\">[ "..DefaultConfig.." ]</font,189)\">[ "..DefaultConfig.." ]</font>"
                    or "Default Config"})
                ConfigSection:Button({Name = "Set",Callback = function()
                    if ConfigDropdown>"
                    or "Default Config"})
                ConfigSection:Button({Name = "Set",Callback = function()
                    if ConfigDropdown.Value and ConfigDropdown.Value[1] then
                        DefaultConfig =.Value and ConfigDropdown.Value[1] then
                        DefaultConfig = ConfigDropdown.Value[1]
                        write ConfigDropdown.Value[1]
                        writefile(PFName.."\\Defaultfile(PFName.."\\DefaultConfig.txt",DefaultConfig)
                        ConfigDivider:SetText(
                            "Default ConfigConfig.txt",DefaultConfig)
                        ConfigDivider:SetText(
                            "Default Config\n<font color=\"rgb(189,189,189\n<font color=\"rgb(189,189,189)\">[ "..DefaultConfig.." ]</)\">[ "..DefaultConfig.." ]</font>font>")
                    end
                end})
                ConfigSection:Button({Name = "Clear",Callback = function")
                    end
                end})
                ConfigSection:Button({Name = "Clear",Callback = function()
                    writefile(PFName.."\\DefaultConfig.txt","()
                    writefile(PFName.."\\DefaultConfig.txt","")
                    ConfigDivider:SetText("Default Config")
                    ConfigDivider:SetText("Default Config")
                end})
            end
        end

        function Tab:Div")
                end})
            end
        end

        function Tab:Divider(Divider)
            Dividerider(Divider)
            Divider = GetType(D = GetType(Divider,{},"table")
            Divider.Text = GetType(Divider.Textivider,{},"table")
            Divider.Text = GetType(Divider.Text,"","string")
            InitDivider(ChooseTab(Divider,"","string")
            InitDivider(ChooseTab(Divider.Side),Divider)
            return Divider
        end.Side),Divider)
            return Divider
        end
        function Tab:Label(Label)
            Label = GetType(Label,{},"table")
            Label
        function Tab:Label(Label)
            Label = GetType(Label,{},"table")
            Label.Text = GetType(Label.Text,"Label","string")
            InitLabel(ChooseTab.Text = GetType(Label.Text,"Label","string")
            InitLabel(ChooseTab(Label.Side),Label)
            return Label
       (Label.Side),Label)
            return Label
        end
        function end
        function Tab:Button(Button)
            Button = GetType(Button,{},"table")
            Button.Name = Tab:Button(Button)
            Button = GetType(Button,{},"table")
            Button.Name = GetType GetType(Button.Name,"Button","string")
            Button.Callback = GetType(Button.Callback,function()(Button.Name,"Button","string")
            Button.Callback = GetType(Button.Callback,function() end,"function end,"function")
            InitButton(ChooseTab(Button.Side),Bracket.ScreenAsset,Window,Button)
            return Button")
            InitButton(ChooseTab(Button.Side),Bracket.ScreenAsset,Window,Button)
            return Button
        end
        function Tab:Toggle(Toggle)

        end
        function Tab:Toggle(Toggle)
            Toggle = GetType(Toggle,{},"table            Toggle = GetType(Toggle,{},"table")
            Toggle")
            Toggle.Name = GetType(Toggle.Name,"Toggle","string")
            Toggle.Flag = GetType.Name = GetType(Toggle.Name,"Toggle","string")
            Toggle.Flag = GetType(Toggle.Flag,Toggle.Name,"string")

            Toggle.Value = GetType(Toggle.Value(Toggle.Flag,Toggle.Name,"string")

            Toggle.Value = GetType(Toggle.Value,false,false,"boolean")
           ,"boolean")
            Toggle.Callback = GetType(Toggle.Callback,function() end,"function")
            Window.Elements[#Window.Elements + 1 Toggle.Callback = GetType(Toggle.Callback,function() end,"function")
            Window.Elements[#Window.Elements + 1] = Toggle
            Window.Flags[Toggle.Flag] = Toggle
            Window.Flags[Toggle.Flag] = Toggle.Value

            InitToggle(ChooseTab] = Toggle.Value

            InitToggle(ChooseTab(Toggle.Side),B(Toggle.Side),Bracket.ScreenAsset,Window,Toggle)
            return Toggle
        end
        function Tab:Slider(Slracket.ScreenAsset,Window,Toggle)
            return Toggle
        end
        function Tab:Slider(Slider)
            Slider = GetType(Slider,{},"table")
            Slider.Name = GetType(Sliderider)
            Slider = GetType(Slider,{},"table")
            Slider.Name = GetType(Slider.Name,"Slider","string")
            Slider.Flag = GetType(Slider.Flag,.Name,"Slider","string")
            Slider.Flag = GetType(Slider.Flag,Slider.Name,"string")

            Slider.Min = GetType(Slider.MinSlider.Name,"string")

            Slider.Min = GetType(Slider.Min,,0,"number")
            Slider.Max = GetType(Slider.Max,100,"number")
            Slider0,"number")
            Slider.Max = GetType(Slider.Max,100,"number")
            Slider.Precise = GetType(Slider.Precise,0,"number")
            Slider.Precise = GetType(Slider.Precise,0,"number")
            Slider.Unit = GetType(Slider.Unit,"",".Unit = GetType(Slider.Unit,"","stringstring")
            Slider.Value = GetType(Slider.Value,Slider.Max / 2,"number")
            Slider.Value = GetType(Slider.Value,Slider.Max / 2,"number")
            Slider.Callback = GetType(Slider.Callback,")
            Slider.Callback = GetType(Slider.Callback,function() end,"function")
            Window.Elementsfunction() end,"function")
            Window.Elements[#[#Window.Elements + 1] = Slider
            Window.Flags[Slider.FlagWindow.Elements + 1] = Slider
            Window.Flags[Slider.Flag] = Slider.Value

            InitSlider(ChooseTab(Slider.S] = Slider.Value

            InitSlider(ChooseTab(Slider.Side),Bracket.ScreenAsset,Window,Slideride),Bracket.ScreenAsset,Window,Slider)
            return Slider
        end
        function Tab:Textbox(Textbox)
            Text)
            return Slider
        end
        function Tab:Textbox(Textbox)
            Textbox = GetType(Textbox,{},"table")
            Textbox.Name = GetType(Textbox.Name,"box = GetType(Textbox,{},"table")
            Textbox.Name = GetType(Textbox.Name,"Textbox","string")
            Textbox.Flag = GetType(Textbox","string")
            Textbox.Flag = GetType(Textbox.Flag,Textbox.Name,"string")

           Textbox.Flag,Textbox.Name,"string")

            Textbox Textbox.Value = GetType(Textbox.Value,"","string")
            Textbox.NumbersOnly = GetType(.Value = GetType(Textbox.Value,"","string")
            Textbox.NumbersOnly = GetType(Textbox.NumbersOnly,false,"boolean")
            Textbox.Placeholder = GetType(TextboxTextbox.NumbersOnly,false,"boolean")
            Textbox.Placeholder = GetType(Textbox.Placeholder,"Input here","string")
            Textbox.Callback = Get.Placeholder,"Input here","string")
            Textbox.Callback = GetType(Textbox.Callback,function() endType(Textbox.Callback,function() end,"function")
           ,"function")
            Window.Elements[#Window.Elements + 1] = Textbox
            Window.Flags Window.Elements[#Window.Elements + 1] = Textbox
            Window.Flags[Textbox.Flag] = Textbox.Value

            InitTextbox(Choose[Textbox.Flag] = Textbox.Value

            InitTextbox(ChooseTab(Textbox.Side),BracketTab(Textbox.Side),Bracket.ScreenAsset,Window.ScreenAsset,Window,Textbox)
            return Textbox
        end
        function Tab:,Textbox)
            return Textbox
        end
        function Tab:Keybind(Keybind)
            Keybind = GetType(Keybind(Keybind)
            Keybind = GetType(Keybind,{},"table")
            Keybind.Name = GetType(KeybindKeybind,{},"table")
            Keybind.Name = GetType(Keybind.Name,".Name,"Keybind","string")
            Keybind.Flag = GetType(Keybind.Flag,Keybind.Name,"stringKeybind","string")
            Keybind.Flag = GetType(Keybind.Flag,Keybind.Name,"string")

            Keybind.Value = GetType(Keybind.Value,"NONE","")

            Keybind.Value = GetType(Keybind.Value,"NONE","string")
            Keybind.Mouse = GetTypestring")
            Keybind.Mouse = GetType(Keybind.M(Keybind.Mouse,false,"boolean")
            Keybind.Callback = GetType(Keybind.Callback,functionouse,false,"boolean")
            Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
            Keybind.Blacklist = GetType(Keybind.Black() end,"function")
            Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","list,{"W","A","S","D","Slash","Tab","Backspace","ETab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
            Window.Elements[#Window.Elements + scape","Space","Delete","Unknown","Backquote"},"table")
            Window.Elements[#Window.Elements + 1] =1] = Keybind
            Window.Flags[Keybind.Flag] = Keybind.Value

            InitKeybind( Keybind
            Window.Flags[Keybind.Flag] = Keybind.Value

            InitKeybind(ChooseTab(Keybind.Side),Bracket.ScreenAsset,Window,ChooseTab(Keybind.Side),Bracket.ScreenAsset,Window,Keybind)
            return Keybind
Keybind)
            return Keybind
        end
               end
        function Tab:Dropdown(Dropdown)
            Dropdown = GetType(Dropdown,{},"table")
            Dropdown.Name = GetType(D function Tab:Dropdown(Dropdown)
            Dropdown = GetType(Dropdown,{},"table")
            Dropdown.Name = GetType(Dropdown.Name,"Dropdown","string")
            Dropdown.Flag = GetTyperopdown.Name,"Dropdown","string")
            Dropdown.Flag = GetType(Dropdown.Flag,Dropdown.Name,"(Dropdown.Flag,Dropdown.Name,"string")
string")
            Dropdown.List = GetType(Dropdown.List,{},"table")
            Window            Dropdown.List = GetType(Dropdown.List,{},"table")
            Window.Elements[#Window.Elements + 1] =.Elements[#Window.Elements + 1] = Dropdown
            Window.Flags Dropdown
            Window.Flags[Dropdown[Dropdown.Flag] = Dropdown.Value

            InitDropdown(ChooseTab(Drop.Flag] = Dropdown.Value

            InitDropdown(ChooseTab(Dropdown.Side),Bracket.ScreenAsset,Window,Dropdown)
           down.Side),Bracket.ScreenAsset,Window,Dropdown)
            return Drop return Dropdown
        end
        function Tab:Colorpicker(Colorpicker)
            Colorpicker = GetTypedown
        end
        function Tab:Colorpicker(Colorpicker)
            Colorpicker = GetType(Colorpicker(Colorpicker,{},"table")
            Colorpicker.Name = GetType(Colorpicker.Name,"Colorpicker","string,{},"table")
            Colorpicker.Name = GetType(Colorpicker.Name,"Colorpicker","string")
           ")
            Colorpicker.Flag = GetType(Colorpicker Colorpicker.Flag = GetType(Colorpicker.F.Flag,Colorpicker.Name,"string")

            Colorpicker.Value = GetType(Colorpicker.Value,{lag,Colorpicker.Name,"string")

            Colorpicker.Value = GetType(Colorpicker.Value,{1,11,1,1,0,false},"table")
            Colorpicker.C,1,0,false},"table")
            Colorpicker.Callback = Getallback = GetType(Colorpicker.Callback,function() end,"function")
            Window.ElementsType(Colorpicker.Callback,function() end,"function")
            Window.Elements[#Window.Elements + 1] = Colorpicker
            Window.Flags[Colorpicker[#Window.Elements + 1] = Colorpicker
            Window.Flags[Colorpicker.Flag] = Colorpicker.Value

            InitColorpicker(ChooseTab.Flag] = Colorpicker.Value

            InitColorpicker(ChooseTab(Colorpicker.Side(Colorpicker.Side),Bracket.ScreenAsset,Window,Colorpicker)
            return),Bracket.ScreenAsset,Window,Colorpicker)
            return Colorpicker
 Colorpicker
        end
        function Tab:Section(Section)
            Section = Get        end
        function Tab:Section(Section)
            Section = GetType(SType(Section,{},"table")
            Section.Name = GetType(Section.Name,"ection,{},"table")
            Section.Name = GetType(Section.Name,"Section","Section","string")
            local SectionContainer = InitSection(ChooseTab(Section.Side),Section)

           string")
            local SectionContainer = InitSection(ChooseTab(Section.Side),Section)

            function Section function Section:Divider(Divider)
                Divider = GetType(Divider:Divider(Divider)
                Divider = GetType(Divider,{},"table")
,{},"table")
                Divider.Text = GetType                Divider.Text = GetType(Divider.Text,"","string")
                InitDivider(SectionContainer,(Divider.Text,"","string")
                InitDivider(SectionContainer,Divider)
               Divider)
                return Divider
            end
            return Divider
            end
            function Section:Label(Label)
                Label = function Section:Label(Label)
                Label = GetType(Label GetType(Label,{},"table")
                Label.Text = GetType(Label.Text,"Label","string,{},"table")
                Label.Text = GetType(Label.Text,"Label","string")
                Init")
                InitLabel(SectionContainer,Label)
               Label(SectionContainer,Label)
                return Label
            end return Label
            end
            function Section:Button(Button
            function Section:Button(Button)
                Button = GetType(Button,{},"table")
                Button.Name =)
                Button = GetType(Button,{},"table")
                GetType(Button.Name,"Button","string Button.Name = GetType(Button.Name,"Button","string")
                Button.Callback = GetType(Button.Callback,function() end,"function")
                Button.Callback = GetType(Button.Callback,function() end,"function")
                InitButton(SectionContainer,B")
                InitButton(SectionContainer,Bracket.ScreenAsset,Window,Button)
               racket.ScreenAsset,Window,Button)
                return Button
            end return Button
            end
            function Section:Toggle(Toggle)
                Toggle = GetType
            function Section:Toggle(Toggle)
                Toggle = GetType(Toggle,{},"table")
               (Toggle,{},"table")
                Toggle.Name = GetType(Toggle.Name,"Toggle"," Toggle.Name = GetType(Toggle.Name,"Toggle","string")
                Toggle.Fstring")
                Toggle.Flag = GetType(Toggle.Flag,Toggle.Name,"stringlag = GetType(Toggle.Flag,Toggle.Name,"string")

                Toggle.Value")

                Toggle.Value = GetType(Toggle.Value,false = GetType(Toggle.Value,false,"boolean")
                Toggle.Callback = GetType(T,"boolean")
                Toggle.Callback = GetType(Toggle.Callback,function() end,"functionoggle.Callback,function() end,"function")
                Window.Elements[#Window.E")
                Window.Elements[#Window.Elements + 1] = Toggle
               lements + 1] = Toggle
                Window.Flags[Toggle.Flag] = T Window.Flags[Toggle.Flag] = Toggle.Value

                InitToggle(SectionContainer,Bracketoggle.Value

                InitToggle(SectionContainer,Bracket.ScreenAsset,Window,T.ScreenAsset,Window,Toggle)
                return Toggle
            end
            functionoggle)
                return Toggle
            end
            function Section:Slider(Slider Section:Slider(Slider)
                Slider = GetType(Slider,)
                Slider = GetType(Slider{},"table")
                Slider.Name = GetType(Slider.Name,"Slider,{},"table")
                Slider.Name = GetType(Slider.Name,"Slider","string")
                Slider","string")
                Slider.Flag = GetType(Slider.Flag.Flag = GetType(Slider.Flag,Slider.Name,"string")

                Sl,Slider.Name,"string")

                Slider.Min = GetType(Slider.Min,0,"numberider.Min = GetType(Slider.Min,0,"number")
                Slider.Max")
                Slider.Max = GetType(Slider.Max,100,"number = GetType(Slider.Max,100,"number")
                Slider.Precise")
                Slider.Precise = GetType(Slider.Precise,0 = GetType(Slider.Precise,0,"number")
                Sl,"number")
                Slider.Unit = GetType(Slider.Unit,"","ider.Unit = GetType(Slider.Unit,"","stringstring")
                Slider.Value = GetType(Slider.Value,Slider.Max /")
                Slider.Value = GetType(Slider.Value,Slider.Max / 2,"number")
                Slider.Callback = Get 2,"number")
                Slider.Callback = GetType(Slider.Callback,function() end,"functionType(Slider.Callback,function() end,"function")
                Window.Elements")
                Window.Elements[#Window.Elements + 1] = Sl[#Window.Elements + 1] = Slider
                Window.Flagsider
                Window.Flags[Slider.Flag] = Slider.Value

               [Slider.Flag] = Slider.Value

                InitSlider InitSlider(SectionContainer,Bracket.ScreenAsset,Window,Slider)
                return Sl(SectionContainer,Bracket.ScreenAsset,Window,Slider)
                return Slider
            end
           ider
            end
            function Section:Textbox(Textbox)
 function Section:Textbox(Textbox)
                Textbox = GetType(Text                Textbox = GetType(Textbox,{},"table")
                Textbox.Name = GetType(Textbox,{},"table")
                Textbox.Name = GetType(Textbox.Name,"Textbox.Name,"Textbox","stringbox","string")
                Textbox.Flag = GetType(Textbox.Flag,Textbox")
                Textbox.Flag = GetType(Textbox.Flag,Textbox.Name,".Name,"string")

                Textbox.Value = GetType(Textbox.Value,"","string")
               string")

                Textbox.Value = GetType(Textbox.Value,"","string")
                Textbox.NumbersOnly = GetType(Textbox.NumbersOnly,false,"boolean Textbox.NumbersOnly = GetType(Textbox.NumbersOnly,false,"boolean")
                Textbox.Placeholder = GetType(Textbox.Placeholder,"Input here","string")
                Textbox.Placeholder = GetType(Textbox.Placeholder,"Input here","string")
                Text")
                Textbox.Callback = GetType(Textbox.Callback,function() endbox.Callback = GetType(Textbox.Callback,function() end,"function,"function")
                Window.Elements[#Window.Elements + 1] =")
                Window.Elements[#Window.Elements + 1] = Textbox
                Textbox
                Window.Flags[Textbox.Flag Window.Flags[Textbox.Flag] = Textbox.Value

               ] = Textbox.Value

                InitTextbox(SectionContainer,Bracket.ScreenAsset,Window,Textbox InitTextbox(SectionContainer,Bracket.ScreenAsset,Window,Textbox)
                return Textbox
            end
           )
                return Textbox
            end
            function Section:Keybind(Keybind)
                function Section:Keybind(Keybind)
                Keybind = GetType(Keybind,{},"table")
                Keybind Keybind = GetType(Keybind,{},"table")
                Keybind.Name = GetType(Keybind.Name.Name = GetType(Keybind.Name,"Keybind","string")
                Keybind.F,"Keybind","string")
                Keybind.Flag = GetType(Keybindlag = GetType(Keybind.Flag,Keybind.Name,"string")

                Keybind.Flag,Keybind.Name,"string")

                Keybind.Value = GetType(Keybind.Value = GetType(Keybind.Value,"NONE","string")
                Keybind.M.Value,"NONE","string")
                Keybind.Mouse = GetType(Keybind.Mouse,falseouse = GetType(Keybind.Mouse,false,"boolean")
                Keybind.Callback = GetType(Keybind,"boolean")
                Keybind.Callback = GetType(Keybind.Callback,function() end,".Callback,function() end,"function")
                Keybind.Blacklist = GetTypefunction")
                Keybind.Blacklist = GetType(Keybind(Keybind.Blacklist,{"W","A","S","D","Slash.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","","Tab","Backspace","Escape","Space","Delete","Unknown","BackEscape","Space","Delete","Unknown","Backquote"},"table")
               quote"},"table")
                Window.Elements[#Window.Elements + 1] = Window.Elements[#Window.Elements + 1] = Keybind
                Window.Flags Keybind
                Window.Flags[Keybind.Flag] = Keybind.Value

               [Keybind.Flag] = Keybind.Value

                InitKeybind(SectionContainer,Bracket.ScreenAsset InitKeybind(SectionContainer,Bracket.ScreenAsset,Window,,Window,Keybind)
                return Keybind
            end
            function Section:Dropdown(Dropdown)
                Dropdown =Keybind)
                return Keybind
            end
            function Section:Dropdown(Dropdown)
                Dropdown GetType(Dropdown,{},"table")
                Dropdown.Name = GetType(Dropdown.Name = GetType(Dropdown,{},"table")
                Dropdown.Name = GetType(Dropdown.Name,"Dropdown","string")
                Dropdown,"Dropdown","string")
                Dropdown.Flag = GetType(Dropdown.Flag.Flag = GetType(Dropdown.Flag,Dropdown.Name,"string")
               ,Dropdown.Name,"string")
                Dropdown.List = GetType(Dropdown.List,{},"table Dropdown.List = GetType(Dropdown.List,{},"table")
                Window.Elements[#Window")
                Window.Elements[#Window.Elements + 1] = Dropdown
                Window.Elements + 1] = Dropdown
                Window.Flags[Dropdown.Flags[Dropdown.Flag] = Dropdown.Value

                InitDropdown(Section.Flag] = Dropdown.Value

                InitDropdown(SectionContainer,Bracket.ScreenAsset,Window,Dropdown)
               Container,Bracket.ScreenAsset,Window,Dropdown)
                return Dropdown
            end
            function Section:Colorpicker(Colorpicker)
                return Dropdown
            end
            function Section:Colorpicker(Colorpicker)
                Colorpicker = GetType Colorpicker = GetType(Colorpicker(Colorpicker,{},"table")
                Color,{},"table")
                Colorpicker.Name = Getpicker.Name = GetType(Colorpicker.Name,"Colorpicker","string")
                Colorpicker.Flag = GetType(Colorpicker.Flag,Colorpicker.Name,"string")

                ColorType(Colorpicker.Name,"Colorpicker","string")
                Colorpicker.Flag = GetType(Colorpicker.Flag,Colorpicker.Name,"string")

                Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"tablepicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
                Colorpicker.Callback = GetType(Colorpicker.Callback,function() end")
                Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function,"function")
                Window.Elements[#Window.Elements + 1] = Colorpicker
                Window")
                Window.Elements[#Window.Elements + 1] = Colorpicker
                Window.F.Flags[Colorpicker.Flag] = Colorpicker.Value

                InitColorpicker(Slags[Colorpicker.Flag] = Colorpicker.Value

                InitColorpicker(SectionContainerectionContainer,Bracket.ScreenAsset,Window,Colorpicker)
                return Colorpicker
            end,Bracket.ScreenAsset,Window,Colorpicker)
                return Colorpicker
            end
            return Section
            return Section
        end
        return Tab
    end
    return Window
end

function Bracket
        end
        return Tab
    end
    return Window
end

function Bracket:Table:TableToColor(Table)
    if type(Table) ~= "ToColor(Table)
    if type(Table) ~= "table" then returntable" then return Table end
    return Color3.fromHSV(Table[1],Table Table end
    return Color3.fromHSV(Table[1],Table[2],Table[2],Table[3])
end

function Bracket:Notification(Notification)
    Notification[3])
end

function Bracket:Notification(Notification)
    Notification = GetType( = GetType(Notification,{},"table")
    Notification.Title = GetType(NotificationNotification,{},"table")
    Notification.Title = GetType(Notification.Title,"Title",".Title,"Title","string")
    Notification.Description = Getstring")
    Notification.Description = GetType(Notification.Description,"Description","stringType(Notification.Description,"Description","string")

    local NotificationAsset = GetAsset("Notification/ND")
    NotificationAsset.Parent = Bracket.ScreenAsset")

    local NotificationAsset = GetAsset("Notification/ND")
    NotificationAsset.Parent = Bracket.ScreenAsset.NDHandle.NDHandle
    NotificationAsset.Title.Text = Notification.Title
    NotificationAsset.Description.Text = Notification
    NotificationAsset.Title.Text = Notification.Title
    NotificationAsset.Description.Text = Notification.D.Description
    NotificationAsset.Title.Size = UDim2.new(1,0,escription
    NotificationAsset.Title.Size = UDim2.new(1,0,0,0,NotificationAsset.Title.TextBounds.Y)
    NotificationAsset.Description.Size = UDim2.new(1NotificationAsset.Title.TextBounds.Y)
    NotificationAsset.Description.Size = UDim2.new(1,0,,0,0,NotificationAsset.Description.TextBounds.Y)
    NotificationAsset.Size = U0,NotificationAsset.Description.TextBounds.Y)
    NotificationAsset.Size = UDim2.newDim2.new(
        0,GetLongest(
            NotificationAsset.Title.TextBounds(
        0,GetLongest(
            NotificationAsset.Title.TextBounds.X,
            Notification.X,
            NotificationAsset.Description.TextBounds.X
        ) + 24,
        0,NotificationAssetAsset.Description.TextBounds.X
        ) + 24,
        0,NotificationAsset.ListLayout.AbsoluteContentSize.Y + 8
    )

    if Notification.D.ListLayout.AbsoluteContentSize.Y + 8
    )

    if Notification.Duration then
        task.spawn(function()
            for Time = Notification.Duration,1,-1uration then
        task.spawn(function()
            for Time = Notification.Duration,1,-1 do
                Notification do
                NotificationAsset.Title.Close.Text = Time
                task.wait(1)
            end
            NotificationAssetAsset.Title.Close.Text = Time
                task.wait(1)
            end
            NotificationAsset.Title.Title.Close.Text = 0

            if Notification.Callback then
                Notification.Callback()
            end.Close.Text = 0

            if Notification.Callback then
                Notification.Callback()
            end
           
            NotificationAsset:Destroy()
        end)
    else
        NotificationAsset NotificationAsset:Destroy()
        end)
    else
        NotificationAsset.Title.Close.Mouse.Title.Close.MouseButton1Click:Connect(function()
            NotificationAsset:Button1Click:Connect(function()
            NotificationAsset:Destroy()
        end)
    end
end

function Bracket:Notification2(Notification)
    Notification = GetType(Notification,{},"table")
    Notification.TitleDestroy()
        end)
    end
end

function Bracket:Notification2(Notification)
    Notification = GetType(Notification,{},"table")
    Notification.Title = = GetType(Notification.Title,"Title","string")
    Notification.Duration = Get GetType(Notification.Title,"Title","string")
    Notification.Duration = GetType(Notification.DType(Notification.Duration,5,"number")
    Notification.Color = GetType(Notification.Color,Color3.newuration,5,"number")
    Notification.Color = GetType(Notification.Color,Color3.new(1,(1,0.5,0.25),"Color3")

    local Notification0.5,0.25),"Color3")

    local NotificationAsset = GetAssetAsset = GetAsset("Notification/NL")
    NotificationAsset.Parent = Bracket.ScreenAsset.NL("Notification/NL")
    NotificationAsset.Parent = Bracket.ScreenAsset.NLHandleHandle
    NotificationAsset.Main.Title.Text = Notification.Title
    NotificationAsset.Main.GLine.BackgroundColor3 = Notification
    NotificationAsset.Main.Title.Text = Notification.Title
    NotificationAsset.Main.GLine.BackgroundColor3 = Notification.Color
    NotificationAsset.Main.Size = UDim2.new(
        0,NotificationAsset.Main.Title.Color
    NotificationAsset.Main.Size = UDim2.new(
        0,NotificationAsset.Main.Title.TextBounds.TextBounds.X + 10,
        0,NotificationAsset.Main.Title.TextBounds.Y + .X + 10,
        0,NotificationAsset.Main.Title.TextBounds.Y + 66
    )
    NotificationAsset.Size = UDim2.new(
        0,0,0
    )
    NotificationAsset.Size = UDim2.new(
        0,0,0,Notification,NotificationAsset.Main.Size.Y.Offset + 4
    )

    local function TweenSizeAsset.Main.Size.Y.Offset + 4
    )

    local function TweenSize(X,Y,(X,Y,Callback)
        NotificationAsset:TweenSize(
            UDim2.newCallback)
        NotificationAsset:TweenSize(
            UDim2.new(0,X(0,X,0,Y),
            Enum.EasingDirection.In,0,Y),
            Enum.EasingDirection.InOut,
            Enum.EasingStyle.Linear,
            0.25,false,Out,
            Enum.EasingStyle.Linear,
            0.25,false,Callback
        )
    end

    TweenSize(NotificationAsset.Main.Size.XCallback
        )
    end

    TweenSize(NotificationAsset.Main.Size.X.Offset + 4,
    Notification.Offset + 4,
    NotificationAsset.Main.Size.Y.Offset +Asset.Main.Size.Y.Offset + 4,function()
        task.wait(Notification.Duration 4,function()
        task.wait(Notification.Duration) TweenSize(0) TweenSize(0,
        NotificationAsset.Main.Size.Y.Offset +,
        NotificationAsset.Main.Size.Y.Offset + 4,function()
            if Notification.C 4,function()
            if Notification.Callback then
                Notification.Callback()
allback then
                Notification.Callback()
            end NotificationAsset:Destroy()
        end            end NotificationAsset:Destroy()
        end)
    end)
end

return Bracket
