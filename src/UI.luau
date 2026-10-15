local UI={}
UI.__index=UI
local colors={bg=Color3.fromRGB(9,8,17),surface=Color3.fromRGB(23,20,37),line=Color3.fromRGB(64,49,86),text=Color3.fromRGB(245,243,255),muted=Color3.fromRGB(182,172,203),gold=Color3.fromRGB(239,91,255),green=Color3.fromRGB(79,255,190)}
UI.Colors=colors
local WIDTH,HEIGHT,HEADER=560,420,58
local rainbow=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,76,177)),ColorSequenceKeypoint.new(0.2,Color3.fromRGB(255,193,91)),ColorSequenceKeypoint.new(0.4,Color3.fromRGB(124,255,158)),ColorSequenceKeypoint.new(0.6,Color3.fromRGB(68,231,255)),ColorSequenceKeypoint.new(0.8,Color3.fromRGB(180,111,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,76,177))})
function UI.make(class,props,parent)
    local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local function corner(o) UI.make("UICorner",{CornerRadius=UDim.new(0,3)},o) end
local function spectrum(o) return UI.make("UIGradient",{Color=rainbow,Rotation=0},o) end
local function text(parent,value,size,height)
    return UI.make("TextLabel",{BackgroundTransparency=1,Text=value,TextColor3=colors.text,TextSize=size or 14,Font=Enum.Font.SciFi,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,height or 24)},parent)
end
local function button(parent,value,callback,primary)
    local b=UI.make("TextButton",{Text=value,TextSize=14,Font=Enum.Font.SciFi,TextColor3=colors.text,BackgroundColor3=primary and Color3.fromRGB(65,29,88) or colors.surface,BorderSizePixel=0,Size=UDim2.new(1,0,0,32),AutoButtonColor=true},parent);corner(b)
    if primary then local stroke=UI.make("UIStroke",{Color=Color3.new(1,1,1),Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b);spectrum(stroke) end
    if callback then b.Activated:Connect(callback) end;return b
end
UI.text=text;UI.button=button
function UI.new(parent)
    local self=setmetatable({pages={},tabs={},connections={},gradients={},collapsed=false},UI)
    local gui=UI.make("ScreenGui",{Name="GPOFieldKit",ResetOnSpawn=false,DisplayOrder=75,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=false},parent)
    gui:SetAttribute("unhideable",true);self.gui=gui
    local panel=UI.make("Frame",{Name="Panel",Size=UDim2.fromOffset(WIDTH,HEIGHT),Position=UDim2.fromOffset(32,40),BackgroundColor3=colors.bg,BorderSizePixel=0,ClipsDescendants=true},gui);self.panel=panel;corner(panel)
    local border=UI.make("UIStroke",{Color=Color3.new(1,1,1),Thickness=2},panel);table.insert(self.gradients,spectrum(border))
    local rule=UI.make("Frame",{Name="RGBRail",BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Size=UDim2.new(1,0,0,3)},panel);table.insert(self.gradients,spectrum(rule))
    local header=UI.make("Frame",{Name="Header",BackgroundTransparency=1,Size=UDim2.new(1,0,0,HEADER),Active=true},panel);self.header=header
    local title=text(header,"GPO // OVERDRIVE",30,38);title.Name="Title";title.Position=UDim2.fromOffset(16,10);title.Size=UDim2.new(1,-120,0,38);title.Font=Enum.Font.Bangers;title.Rotation=-2;title.TextColor3=Color3.new(1,1,1);table.insert(self.gradients,spectrum(title))
    self.minimize=button(header,"−");self.minimize.Position=UDim2.new(1,-84,0,14);self.minimize.Size=UDim2.fromOffset(32,32)
    self.close=button(header,"×");self.close.Position=UDim2.new(1,-44,0,14);self.close.Size=UDim2.fromOffset(32,32)
    local nav=UI.make("Frame",{Name="Navigation",BackgroundTransparency=1,Position=UDim2.fromOffset(12,HEADER),Size=UDim2.new(1,-24,0,32)},panel);self.nav=nav
    UI.make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},nav)
    local body=UI.make("Frame",{Name="Body",BackgroundTransparency=1,Position=UDim2.fromOffset(12,HEADER+42),Size=UDim2.new(1,-24,1,-HEADER-76)},panel);self.body=body
    local labels={ESP="ESP",Movement="MOVE",Players="PLAYERS",["Stat Profiles"]="STATS",Settings="SETUP"}
    for i,name in ipairs({"ESP","Movement","Players","Stat Profiles","Settings"}) do
        local page=UI.make("ScrollingFrame",{Name=name:gsub(" ",""),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ScrollBarThickness=2,ScrollBarImageColor3=colors.gold,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Visible=false},body)
        UI.make("UIPadding",{PaddingRight=UDim.new(0,7),PaddingBottom=UDim.new(0,8)},page)
        UI.make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},page);self.pages[name]=page
        local tab=button(nav,labels[name],function() self:show(name) end);tab.Name=name;tab.LayoutOrder=i;tab.Size=UDim2.new(0.2,-4,1,0);tab.Font=Enum.Font.Arcade;tab.TextSize=12;self.tabs[name]=tab
        local indicator=UI.make("Frame",{Name="ActiveLine",Visible=false,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2)},tab);table.insert(self.gradients,spectrum(indicator))
    end
    local status=UI.make("TextLabel",{Name="Status",BackgroundColor3=colors.surface,BorderSizePixel=0,Position=UDim2.new(0,0,1,-28),Size=UDim2.new(1,0,0,28),Text="READY",TextSize=12,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd,Font=Enum.Font.SciFi,TextColor3=colors.muted,TextXAlignment=Enum.TextXAlignment.Left},panel)
    UI.make("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)},status);self.status=status
    self.tooltip=UI.make("TextLabel",{Name="Tooltip",Visible=false,BackgroundColor3=colors.surface,TextColor3=colors.text,TextSize=13,Font=Enum.Font.SourceSans,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.fromOffset(310,72),ZIndex=20,BorderSizePixel=0},gui)
    UI.make("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},self.tooltip)
    self:hint(status,function() return status.Text end)
    self:show("ESP");self.minimize.Activated:Connect(function() self:collapse() end)
    local elapsed=0;local clock=0
    self.rgbConnection=game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed+=dt;clock+=dt;if elapsed<1/30 or not panel.Visible then return end;elapsed=0
        for _,gradient in ipairs(self.gradients) do gradient.Rotation=(clock*28)%360 end
    end)
    gui.Destroying:Connect(function() self.rgbConnection:Disconnect() end);return self
end
function UI:show(name)
    self.tooltip.Visible=false
    for k,p in pairs(self.pages) do
        p.Visible=k==name;local tab=self.tabs[k];tab.TextColor3=k==name and colors.text or colors.muted;tab.BackgroundColor3=k==name and Color3.fromRGB(54,28,72) or colors.surface;tab.ActiveLine.Visible=k==name
    end
    self.selected=name
end
function UI:collapse()
    self.collapsed=not self.collapsed;self.body.Visible=not self.collapsed;self.nav.Visible=not self.collapsed;self.status.Visible=not self.collapsed;self.tooltip.Visible=false
    self.panel.Size=UDim2.fromOffset(WIDTH,self.collapsed and HEADER or HEIGHT);self.minimize.Text=self.collapsed and "+" or "−"
end
function UI:hint(object,value)
    object.MouseEnter:Connect(function()
        self.tooltip.Text=type(value)=="function" and value() or value
        self.tooltip.Position=UDim2.fromOffset(self.panel.AbsolutePosition.X+110,self.panel.AbsolutePosition.Y+104);self.tooltip.Visible=true
    end)
    object.MouseLeave:Connect(function() self.tooltip.Visible=false end)
end
function UI:heading(page,title,desc)
    local h=text(page,string.upper(title),20,26);h.Font=Enum.Font.Bangers;if desc then self:hint(h,desc) end;return h
end
function UI:note(page,value,height)
    local n=text(page,value,12,height or 24);n.TextColor3=colors.muted;return n
end
function UI:grid(page,columns,height)
    columns=columns or 2;height=height or 32
    local group=UI.make("Frame",{Name="ControlGrid",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},page)
    UI.make("UIGridLayout",{CellSize=UDim2.new(1/columns,-(columns-1)*6/columns,0,height),CellPadding=UDim2.fromOffset(6,6),SortOrder=Enum.SortOrder.LayoutOrder},group);return group
end
function UI:toggle(page,label,get,set,hint)
    local b=button(page,"");b.TextXAlignment=Enum.TextXAlignment.Left
    local labelText=text(b,label,13,32);labelText.Position=UDim2.fromOffset(10,0);labelText.Size=UDim2.new(1,-67,1,0);labelText.TextWrapped=false;labelText.TextTruncate=Enum.TextTruncate.AtEnd
    local pill=UI.make("Frame",{Name="State",Size=UDim2.fromOffset(42,20),Position=UDim2.new(1,-50,0.5,-10),BackgroundColor3=colors.line,BorderSizePixel=0},b);corner(pill)
    local stateText=text(pill,"OFF",12,20);stateText.TextXAlignment=Enum.TextXAlignment.Center;stateText.Font=Enum.Font.Arcade
    local function refresh() local on=get();stateText.Text=on and "ON" or "OFF";stateText.TextColor3=on and colors.bg or colors.text;pill.BackgroundColor3=on and colors.green or colors.line;b.BackgroundColor3=on and Color3.fromRGB(26,47,43) or colors.surface end
    b.Activated:Connect(function() set(not get());refresh() end);refresh();self:hint(b,hint or label);return refresh,b
end
local shortStats={SwordMastery="Sword",GunMastery="Gun",DevilFruitMastery="Fruit",FightingStyleMastery="Style",RokushikiMastery="Rokushiki",BlackLegMastery="Black Leg",ElectroMastery="Electro",FishmanKarateMastery="Fishman",DragonClawMastery="Dragon Claw",CyborgMastery="Cyborg"}
function UI:field(page,label,value,changed)
    local row=UI.make("Frame",{Name=label:gsub(" ",""),BackgroundTransparency=1,Size=UDim2.new(1,0,0,28)},page)
    local l=text(row,shortStats[label] or label,13,28);l.Size=UDim2.new(0.62,-6,1,0);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd
    local box=UI.make("TextBox",{Name="Input",Text=tostring(value),ClearTextOnFocus=false,TextSize=14,Font=Enum.Font.Code,BackgroundColor3=colors.surface,TextColor3=colors.text,BorderSizePixel=0,Position=UDim2.new(0.62,0,0,0),Size=UDim2.new(0.38,0,1,0)},row);corner(box)
    if changed then box.FocusLost:Connect(function() changed(box.Text,box) end) end;return box,row
end
function UI:slider(page,label,get,set,min,max,uis,track)
    local field=self:field(page,label,get(),function(value,box) local n=tonumber(value);if n and n==n and math.abs(n)<math.huge then set(math.clamp(math.floor(n),min,max)) end;box.Text=tostring(get()) end)
    local rail=button(page,"");rail.Name="SpeedSlider";rail.Size=UDim2.new(1,0,0,24)
    local fill=UI.make("Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Position=UDim2.fromOffset(0,10),Size=UDim2.new((get()-min)/(max-min),0,0,4)},rail);spectrum(fill)
    local dragging=false
    local function update(x) local t=math.clamp((x-rail.AbsolutePosition.X)/math.max(1,rail.AbsoluteSize.X),0,1);set(math.floor(min+t*(max-min)+0.5));field.Text=tostring(get());fill.Size=UDim2.new((get()-min)/(max-min),0,0,4) end
    rail.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;update(input.Position.X) end end)
    track(uis.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then update(input.Position.X) end end))
    track(uis.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
    field.FocusLost:Connect(function() fill.Size=UDim2.new((get()-min)/(max-min),0,0,4) end);return field
end
function UI:confirm(title,body,onConfirm)
    if self.modal then self.modal:Destroy() end;self.tooltip.Visible=false
    local shade=UI.make("Frame",{Name="Confirmation",BackgroundColor3=colors.bg,BackgroundTransparency=0.03,Size=UDim2.fromScale(1,1),ZIndex=30},self.panel);self.modal=shade
    local content=UI.make("Frame",{BackgroundColor3=colors.surface,BorderSizePixel=0,Position=UDim2.fromOffset(20,20),Size=UDim2.new(1,-40,1,-40),ZIndex=31},shade)
    UI.make("UIPadding",{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16),PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12)},content)
    UI.make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},content)
    local h=text(content,title,24,32);h.LayoutOrder=0;h.ZIndex=32;h.Font=Enum.Font.Bangers
    local sc=UI.make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,1,-120),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=2,LayoutOrder=1,ZIndex=32},content)
    local t=text(sc,body,14,0);t.Font=Enum.Font.SourceSans;t.AutomaticSize=Enum.AutomaticSize.Y;t.ZIndex=33
    local yes=button(content,"CONFIRM",function() shade:Destroy();self.modal=nil;onConfirm() end,true);yes.LayoutOrder=2;yes.ZIndex=32
    local no=button(content,"CANCEL",function() shade:Destroy();self.modal=nil end);no.LayoutOrder=3;no.ZIndex=32
end
return UI
