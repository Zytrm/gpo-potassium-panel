-- Uses the selected repo's Effects/mesh/name detectors; owns no gameplay objects.
local WorldESP={}
WorldESP.__index=WorldESP
function WorldESP.new(world,core,onAdd,onRemove,defer)
    local self=setmetatable({running=true,connections={},roots={},meshes={},pending={},classified={},effects=nil,npcs=nil},WorldESP)
    local function disconnect(list) for _,c in ipairs(list) do c:Disconnect() end end
    local function remove(o) if self.classified[o] then self.classified[o]=nil;onRemove(o) end end
    local function evaluate(o)
        if not self.running then return end
        local category,display,style
        if o.Parent==self.effects and self.effects then
            if o:IsA("Model") or o:IsA("BasePart") or o:IsA("Folder") or o:IsA("Tool") then
                local ids={};local hasPart=o:IsA("BasePart")
                -- Direct MeshParts match the reference; nested streamed parts are supported too.
                for _,part in ipairs(o:GetDescendants()) do
                    if part:IsA("BasePart") then hasPart=true end
                    if part:IsA("MeshPart") then table.insert(ids,part.MeshId) end
                end
                if hasPart then category,display,style=core.classifyEffect(o.Name,o.ClassName,ids) end
            end
        elseif o.Parent==self.npcs and self.npcs and o:IsA("Model") and core.Trainers[o.Name] then category="trainers";display=o.Name end
        local previous=self.classified[o]
        if not category then remove(o);return end
        if previous and previous.category==category and previous.display==display and previous.style==style then return end
        self.classified[o]={category=category,display=display,style=style};onAdd(o,category,display,style)
    end
    local function schedule(o)
        if not o or not self.running or self.pending[o] then return end
        self.pending[o]=true
        defer(function() self.pending[o]=nil;if self.running then evaluate(o) end end)
    end
    local function unwatchRoot(o)
        if self.roots[o] then disconnect(self.roots[o]);self.roots[o]=nil end
        remove(o)
    end
    local function watchRoot(o)
        if self.roots[o] then schedule(o);return end
        self.roots[o]={o:GetPropertyChangedSignal("Name"):Connect(function() schedule(o) end),o.AncestryChanged:Connect(function()
            if o.Parent~=self.effects and o.Parent~=self.npcs then unwatchRoot(o) else schedule(o) end
        end)}
        schedule(o)
    end
    local function effectOwner(o)
        local parent=o
        while parent and parent.Parent~=self.effects do parent=parent.Parent end
        return parent
    end
    local function watchMesh(o)
        if o:IsA("MeshPart") and not self.meshes[o] then self.meshes[o]=o:GetPropertyChangedSignal("MeshId"):Connect(function() schedule(effectOwner(o)) end) end
    end
    local function bindEffects(root)
        if root==self.effects then return end
        if self.effectConnections then disconnect(self.effectConnections) end
        for mesh,c in pairs(self.meshes) do c:Disconnect();self.meshes[mesh]=nil end
        local old=self.effects
        for o in pairs(self.roots) do if old and (o.Parent==old or o:IsDescendantOf(old)) then unwatchRoot(o) end end
        self.effects=root
        if not root then return end
        self.effectConnections={root.ChildAdded:Connect(watchRoot),root.ChildRemoved:Connect(unwatchRoot),root.DescendantAdded:Connect(function(o)
            watchMesh(o);local owner=effectOwner(o);if owner then watchRoot(owner) end
        end),root.DescendantRemoving:Connect(function(o)
            local owner=effectOwner(o)
            if self.meshes[o] then self.meshes[o]:Disconnect();self.meshes[o]=nil end
            schedule(owner)
        end)}
        for _,o in ipairs(root:GetDescendants()) do watchMesh(o) end
        for _,o in ipairs(root:GetChildren()) do watchRoot(o) end
    end
    local function bindNPCs(root)
        if root==self.npcs then return end
        if self.npcConnections then disconnect(self.npcConnections) end
        local old=self.npcs
        for o in pairs(self.roots) do if old and o.Parent==old then unwatchRoot(o) end end
        self.npcs=root
        if root then
            self.npcConnections={root.ChildAdded:Connect(watchRoot),root.ChildRemoved:Connect(unwatchRoot)}
            for _,o in ipairs(root:GetChildren()) do watchRoot(o) end
        end
    end
    local function rootAdded(o) if o.Name=="Effects" then bindEffects(o) elseif o.Name=="NPCs" then bindNPCs(o) end end
    self.connections={world.ChildAdded:Connect(rootAdded),world.ChildRemoved:Connect(function(o) if o==self.effects then bindEffects(nil) end;if o==self.npcs then bindNPCs(nil) end end)}
    bindEffects(world:FindFirstChild("Effects"));bindNPCs(world:FindFirstChild("NPCs"))
    function self:Inspect(o)
        if not self.running then return end
        if self.effects and o:IsDescendantOf(self.effects) then local owner=effectOwner(o);if owner then watchRoot(owner) end
        elseif self.npcs and o.Parent==self.npcs then watchRoot(o) end
    end
    function self:Destroy()
        if not self.running then return end;self.running=false
        disconnect(self.connections);disconnect(self.effectConnections or {});disconnect(self.npcConnections or {})
        for _,list in pairs(self.roots) do disconnect(list) end
        for _,c in pairs(self.meshes) do c:Disconnect() end
        for o in pairs(self.classified) do remove(o) end
        self.roots={};self.meshes={};self.pending={}
    end
    return self
end
return WorldESP
