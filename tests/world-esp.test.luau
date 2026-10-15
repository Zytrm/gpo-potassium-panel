local Core=require("../src/Core")
local WorldESP=require("../src/WorldESP")
local signals={}
local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local c={Connected=true};self.listeners[c]=fn
        function c:Disconnect() self.Connected=false;s.listeners[self]=nil end
        return c
    end
    function s:Fire(...)
        local copy={};for c,fn in pairs(self.listeners) do copy[c]=fn end
        for c,fn in pairs(copy) do if c.Connected then fn(...) end end
    end
    table.insert(signals,s);return s
end
local Fake={}
local meta={}
function meta.__index(o,k) return Fake[k] or rawget(o,k) or o.props[k] end
function meta.__newindex(o,k,v)
    if k=="Parent" then
        local old=o.props.Parent;if old==v then return end
        local subtree={o};for _,child in ipairs(o:GetDescendants()) do table.insert(subtree,child) end
        if old then
            for _,part in ipairs(subtree) do local a=old;while a do a.DescendantRemoving:Fire(part);a=a.Parent end end
            table.remove(old.children,table.find(old.children,o))
        end
        o.props.Parent=v
        if old then old.ChildRemoved:Fire(o) end
        if v then
            table.insert(v.children,o);v.ChildAdded:Fire(o)
            for _,part in ipairs(subtree) do local a=v;while a do a.DescendantAdded:Fire(part);a=a.Parent end end
        end
        for _,part in ipairs(subtree) do part.AncestryChanged:Fire(part,part.Parent) end
    else
        local old=o.props[k];o.props[k]=v
        if old~=v and o.changed[k] then o.changed[k]:Fire() end
    end
end
local function instance(class,name,parent)
    local o=setmetatable({props={ClassName=class,Name=name,MeshId=""},children={},changed={},ChildAdded=signal(),ChildRemoved=signal(),DescendantAdded=signal(),DescendantRemoving=signal(),AncestryChanged=signal()},meta)
    o.Parent=parent;return o
end
function Fake:IsA(class) return self.ClassName==class or class=="Instance" or class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="MeshPart") end
function Fake:GetChildren() local r={};for _,c in ipairs(self.children) do table.insert(r,c) end;return r end
function Fake:GetDescendants() local r={};for _,c in ipairs(self.children) do table.insert(r,c);for _,d in ipairs(c:GetDescendants()) do table.insert(r,d) end end;return r end
function Fake:IsDescendantOf(root) local p=self.Parent;while p do if p==root then return true end;p=p.Parent end;return false end
function Fake:FindFirstChild(name) for _,c in ipairs(self.children) do if c.Name==name then return c end end end
function Fake:GetPropertyChangedSignal(name) if not self.changed[name] then self.changed[name]=signal() end;return self.changed[name] end
local queue={}
local function defer(fn) table.insert(queue,fn) end
local function flush() local pending=queue;queue={};for _,fn in ipairs(pending) do fn() end end
local world=instance("Workspace","Workspace")
local effects=instance("Folder","Effects",world)
local npcs=instance("Folder","NPCs",world)
local markers={};local additions=0
local detector=WorldESP.new(world,Core,function(o,c,n,s) additions+=1;markers[o]={category=c,name=n,style=s} end,function(o) markers[o]=nil end,defer)
local passed=0
local function test(name,fn) fn();passed+=1;print("PASS "..name) end
local chest,mesh,medal
test("existing trainer is discovered",function() local npc=instance("Model","Yome",npcs);flush();assert(markers[npc].category=="trainers") end)
test("empty chest waits for streamed mesh",function() chest=instance("Model","LuckyChestV1",effects);flush();assert(not markers[chest]) end)
test("late mesh triggers discovery",function() mesh=instance("MeshPart","Chest",chest);mesh.MeshId="rbxassetid://10798559852";flush();assert(markers[chest].category=="legendary") end)
test("unrelated descendants do not duplicate marker",function() local before=additions;instance("Part","Decoration",chest);flush();assert(additions==before) end)
test("mesh ID changes reclassify",function() mesh.MeshId="rbxassetid://10811929054";flush();assert(markers[chest].category=="mythic") end)
test("nested chest meshes are supported",function() local folder=instance("Folder","Parts",chest);mesh.Parent=folder;flush();assert(markers[chest].category=="mythic") end)
test("streaming out last valid mesh removes marker",function() mesh.Parent=nil;flush();assert(not markers[chest]) end)
test("streaming mesh back restores one marker",function() mesh.Parent=chest;flush();assert(markers[chest].category=="mythic") end)
test("collected chest is removed",function() chest.Parent=world;flush();assert(not markers[chest]) end)
test("returning chest is rediscovered",function() chest.Parent=effects;flush();assert(markers[chest].category=="mythic") end)
test("existing Black Leg medal is found without spawn event",function() medal=instance("Model","BlackLeg Medal");instance("Part","Part",medal);medal.Parent=effects;flush();assert(markers[medal].style=="blackleg") end)
test("renamed medal reclassifies",function() medal.Name="Rokushiki Medal";flush();assert(markers[medal].style=="rokushiki") end)
test("generic Medal names are supported",function() medal.Name="Gold Medal";flush();assert(markers[medal].category=="medals") end)
test("renamed nonmedal is removed",function() medal.Name="VisualEffect";flush();assert(not markers[medal]) end)
test("identical meshes outside Effects are ignored",function() local model=instance("Model","Other",world);local p=instance("MeshPart","Chest",model);p.MeshId="rbxassetid://10798559852";detector:Inspect(p);flush();assert(not markers[model]) end)
test("replaced Effects folder resets old markers",function() effects.Parent=nil;flush();assert(not markers[chest]);effects=instance("Folder","Effects",world);chest.Parent=effects;flush();assert(markers[chest].category=="mythic") end)
test("pending events cannot resurrect after unload",function() mesh.MeshId="rbxassetid://10798559852";detector:Destroy();flush();assert(next(markers)==nil) end)
test("unload disconnects all detector signals",function() for _,s in ipairs(signals) do assert(next(s.listeners)==nil) end end)
test("detector starts before Effects exists",function()
    local w=instance("Workspace","World");local results={}
    local d=WorldESP.new(w,Core,function(o,c) results[o]=c end,function(o) results[o]=nil end,defer)
    local e=instance("Folder","Effects",w);local m=instance("Model","BlackLeg Medal",e);instance("Part","Part",m);flush();assert(results[m]=="styleMedals");d:Destroy()
end)
print(passed.." detector lifecycle tests passed")
