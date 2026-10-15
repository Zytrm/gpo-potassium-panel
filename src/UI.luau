local UI={}
UI.__index=UI
local colors={bg=Color3.fromRGB(15,23,31),surface=Color3.fromRGB(25,36,47),line=Color3.fromRGB(53,68,79),text=Color3.fromRGB(239,244,248),muted=Color3.fromRGB(174,190,201),gold=Color3.fromRGB(242,188,104),green=Color3.fromRGB(120,224,178)}
UI.Colors=colors
function UI.make(class,props,parent)
    local o=Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    o.Parent=parent
    return o
end
local function text(parent,value,size,height)
    return UI.make("TextLabel",{BackgroundTransparency=1,Text=value,TextColor3=colors.text,TextSize=size or 14,Font=Enum.Font.SourceSans,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,height or 32)},parent)
end
local function button(parent,value,callback,primary)
    local b=UI.make("TextButton",{Text=value,TextSize=14,Font=Enum.Font.SourceSansSemibold,TextColor3=primary and colors.bg or colors.text,BackgroundColor3=primary and colors.gold or colors.surface,BorderSizePixel=0,Size=UDim2.new(1,0,0,44),AutoButtonColor=true},parent)
    UI.make("UICorner",{CornerRadius=UDim.new(0,4)},b)
    if callback then b.Activated:Connect(callback) end
    return b
end
UI.text=text
UI.button=button
function UI.new(parent)
    local self=setmetatable({pages={},tabs={},connections={},collapsed=false},UI)
    local gui=UI.make("ScreenGui",{Name="GPOFieldKit",ResetOnSpawn=false,DisplayOrder=75,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=false},parent)
    gui:SetAttribute("unhideable",true) -- respected by the inspected MatchHandler UI hiding logic
    self.gui=gui
    local panel=UI.make("Frame",{Name="Panel",Size=UDim2.fromOffset(700,560),Position=UDim2.fromOffset(40,48),BackgroundColor3=colors.bg,BorderSizePixel=0,ClipsDescendants=true},gui)
    self.panel=panel
    UI.make("UICorner",{CornerRadius=UDim.new(0,4)},panel)
    UI.make("UIStroke",{Color=colors.line,Thickness=1},panel)
    UI.make("Frame",{Name="GoldRule",BackgroundColor3=colors.gold,BorderSizePixel=0,Size=UDim2.new(1,0,0,3)},panel)
    local header=UI.make("Frame",{Name="Header",BackgroundTransparency=1,Size=UDim2.new(1,0,0,76),Active=true},panel)
    self.header=header
    local badge=text(header,"G",28,44);badge.Position=UDim2.fromOffset(20,14);badge.Size=UDim2.fromOffset(44,44);badge.TextXAlignment=Enum.TextXAlignment.Center;badge.Font=Enum.Font.SourceSansBold;badge.TextColor3=colors.gold;badge.BackgroundTransparency=0;badge.BackgroundColor3=colors.surface
    local title=text(header,"GRAND PIECE  /  FIELD KIT",22,28);title.Position=UDim2.fromOffset(80,14);title.Size=UDim2.new(1,-200,0,28);title.Font=Enum.Font.SourceSansBold
    local sub=text(header,"Map intelligence & character utilities",14,24);sub.TextColor3=colors.muted;sub.Position=UDim2.fromOffset(80,42);sub.Size=UDim2.new(1,-200,0,24)
    self.minimize=button(header,"–");self.minimize.Position=UDim2.new(1,-108,0,16);self.minimize.Size=UDim2.fromOffset(44,44)
    self.close=button(header,"×");self.close.Position=UDim2.new(1,-56,0,16);self.close.Size=UDim2.fromOffset(44,44)
    local body=UI.make("Frame",{Name="Body",BackgroundTransparency=1,Position=UDim2.fromOffset(0,76),Size=UDim2.new(1,0,1,-120)},panel)
    self.body=body
    local nav=UI.make("Frame",{Name="Navigation",BackgroundColor3=colors.surface,BorderSizePixel=0,Size=UDim2.new(0,156,1,0)},body)
    UI.make("UIPadding",{PaddingTop=UDim.new(0,16),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)},nav)
    UI.make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},nav)
    local cap=text(nav,"TOOLS",14,24);cap.TextColor3=colors.gold;cap.LayoutOrder=0
    for i,name in ipairs({"ESP","Movement","Players","Stat Profiles","Settings"}) do
        local page=UI.make("ScrollingFrame",{Name=name:gsub(" ",""),BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(176,8),Size=UDim2.new(1,-196,1,-16),ScrollBarThickness=3,ScrollBarImageColor3=colors.gold,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Visible=false},body)
        UI.make("UIPadding",{PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,12)},page)
        UI.make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},page)
        self.pages[name]=page
        local tab=button(nav,string.format("%02d   %s",i,name),function() self:show(name) end);tab.LayoutOrder=i;tab.TextXAlignment=Enum.TextXAlignment.Left
        UI.make("UIPadding",{PaddingLeft=UDim.new(0,8)},tab)
        self.tabs[name]=tab
    end
    local status=UI.make("TextLabel",{Name="Status",BackgroundColor3=colors.surface,BorderSizePixel=0,Position=UDim2.new(0,0,1,-44),Size=UDim2.new(1,0,0,44),Text="Ready",TextSize=14,TextWrapped=true,Font=Enum.Font.SourceSans,TextColor3=colors.muted,TextXAlignment=Enum.TextXAlignment.Left},panel)
    UI.make("UIPadding",{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16)},status)
    self.status=status
    self.tooltip=UI.make("TextLabel",{Name="Tooltip",Visible=false,BackgroundColor3=colors.surface,TextColor3=colors.text,TextSize=14,Font=Enum.Font.SourceSans,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.fromOffset(300,60),ZIndex=20,BorderSizePixel=0},gui)
    UI.make("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},self.tooltip)
    self:show("ESP")
    self.minimize.Activated:Connect(function() self:collapse() end)
    return self
end
function UI:show(name)
    for k,p in pairs(self.pages) do p.Visible=k==name;self.tabs[k].TextColor3=k==name and colors.gold or colors.muted end
    self.selected=name
end
function UI:collapse()
    self.collapsed=not self.collapsed
    self.body.Visible=not self.collapsed;self.status.Visible=not self.collapsed
    self.panel.Size=UDim2.fromOffset(700,self.collapsed and 76 or 560)
    self.minimize.Text=self.collapsed and "+" or "–"
end
function UI:hint(object,value)
    object.MouseEnter:Connect(function()
        self.tooltip.Text=value;self.tooltip.Position=UDim2.fromOffset(self.panel.AbsolutePosition.X+184,self.panel.AbsolutePosition.Y+82);self.tooltip.Visible=true
    end)
    object.MouseLeave:Connect(function() self.tooltip.Visible=false end)
end
function UI:heading(page,title,desc)
    local h=text(page,title,24,36);h.Font=Enum.Font.SourceSansBold
    if desc then local d=text(page,desc,14,48);d.TextColor3=colors.muted end
end
function UI:note(page,value,height)
    local n=text(page,value,14,height or 48);n.TextColor3=colors.muted
    return n
end
function UI:toggle(page,label,get,set,hint)
    local b=button(page,"")
    b.TextXAlignment=Enum.TextXAlignment.Left
    UI.make("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)},b)
    local function refresh() local on=get();b.Text=(on and "●  ON     " or "○  OFF    ")..label;b.TextColor3=on and colors.green or colors.text end
    b.Activated:Connect(function() set(not get());refresh() end)
    refresh();if hint then self:hint(b,hint) end
    return refresh,b
end
function UI:field(page,label,value,changed)
    local row=UI.make("Frame",{Name=label:gsub(" ",""),BackgroundTransparency=1,Size=UDim2.new(1,0,0,36)},page)
    local l=text(row,label,14,36);l.Size=UDim2.new(0.64,-8,1,0)
    local box=UI.make("TextBox",{Name="Input",Text=tostring(value),ClearTextOnFocus=false,TextSize=14,Font=Enum.Font.SourceSans,BackgroundColor3=colors.surface,TextColor3=colors.text,BorderSizePixel=0,Position=UDim2.new(0.64,0,0,0),Size=UDim2.new(0.36,0,1,0)},row)
    UI.make("UICorner",{CornerRadius=UDim.new(0,4)},box)
    if changed then box.FocusLost:Connect(function() changed(box.Text,box) end) end
    return box,row
end
function UI:slider(page,label,get,set,min,max,uis,track)
    local field=self:field(page,label,get(),function(value,box) local n=tonumber(value);if n and n==n and math.abs(n)<math.huge then set(math.clamp(math.floor(n),min,max)) end;box.Text=tostring(get()) end)
    local rail=button(page,"");rail.Name="SpeedSlider";rail.Size=UDim2.new(1,0,0,44)
    local fill=UI.make("Frame",{BackgroundColor3=colors.gold,BorderSizePixel=0,Position=UDim2.fromOffset(0,20),Size=UDim2.new((get()-min)/(max-min),0,0,4)},rail)
    local dragging=false
    local function update(x) local t=math.clamp((x-rail.AbsolutePosition.X)/math.max(1,rail.AbsoluteSize.X),0,1);set(math.floor(min+t*(max-min)+0.5));field.Text=tostring(get());fill.Size=UDim2.new((get()-min)/(max-min),0,0,4) end
    rail.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;update(input.Position.X) end end)
    track(uis.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then update(input.Position.X) end end))
    track(uis.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
    field.FocusLost:Connect(function() fill.Size=UDim2.new((get()-min)/(max-min),0,0,4) end)
    return field
end
function UI:confirm(title,body,onConfirm)
    if self.modal then self.modal:Destroy() end
    local shade=UI.make("Frame",{Name="Confirmation",BackgroundColor3=colors.bg,BackgroundTransparency=0.05,Size=UDim2.fromScale(1,1),ZIndex=30},self.panel)
    self.modal=shade
    local content=UI.make("Frame",{BackgroundColor3=colors.surface,BorderSizePixel=0,Position=UDim2.fromOffset(48,48),Size=UDim2.new(1,-96,1,-96),ZIndex=31},shade)
    UI.make("UIPadding",{PaddingLeft=UDim.new(0,24),PaddingRight=UDim.new(0,24),PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,16)},content)
    UI.make("UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},content)
    local h=text(content,title,24,36);h.LayoutOrder=0;h.ZIndex=32;h.Font=Enum.Font.SourceSansBold
    local sc=UI.make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,1,-156),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=3,LayoutOrder=1,ZIndex=32},content)
    local t=text(sc,body,14,0);t.AutomaticSize=Enum.AutomaticSize.Y;t.ZIndex=33
    local yes=button(content,"Confirm",function() shade:Destroy();self.modal=nil;onConfirm() end,true);yes.LayoutOrder=2;yes.ZIndex=32
    local no=button(content,"Cancel",function() shade:Destroy();self.modal=nil end);no.LayoutOrder=3;no.ZIndex=32
end
return UI
