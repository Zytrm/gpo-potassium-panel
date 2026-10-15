local Core = {}
Core.Version = "1.1.0"
-- Verified in ReplicatedStorage.Modules.Leveling.statValues in the inspected copy.
Core.StatNames = {"Strength", "Defense", "Stamina", "GunMastery", "SwordMastery", "RokushikiMastery", "BlackLegMastery", "ElectroMastery", "DevilFruitMastery", "FishmanKarateMastery", "DragonClawMastery", "CyborgMastery", "FightingStyleMastery"}
Core.Chests = {
    ["Legendary Chest"] = "legendary", ["Legendary Fruit Chest"] = "legendary",
    ["Mythical Chest"] = "mythic", ["Mythical Fruit Chest"] = "mythic",
    ["Mythical Fruit Chest2"] = "mythic", ["Myth Chest"] = "mythic", ["Myth Chest (Discount)"] = "mythic",
}
-- Exact NPC fields in dialogue modules that call learnStyle/learnSkill.
Core.Trainers = {Yi=true,Coro=true,Oliva=true,Sharon=true,Lifa=true,Jaggy=true,Yome=true,Jin=true,Teza=true,Puff=true,Musashi=true,AE10=true,Mei=true,Miguel=true,Tatter=true,Brv1n=true,Zorana=true,["Titan of Justice"]=true,["V Kirishima, The Shadow of Halloween"]=true,["Lord Cartier the 5th"]=true}
function Core.finite(n)
    return type(n) == "number" and n == n and n > -math.huge and n < math.huge
end
function Core.copy(t)
    local out = {}
    for k,v in pairs(t) do out[k] = type(v)=="table" and Core.copy(v) or v end
    return out
end
function Core.defaults()
    return {legendary=false,mythic=false,blackleg=false,styleMedals=false,medals=false,trainers=false,health=false,fruit=false,swim=false,
        speed=30,distance=0,playerDistance=1500,markerLimit=40,forwardMode="Character",
        keys={forward="F6",anchor="F7",panel="RightShift"},profiles={}}
end
function Core.validName(s)
    return type(s)=="string" and #s>0 and #s<=40 and not s:find("[%c]") and s:find("%S")~=nil
end
function Core.validateProfile(profile, schema)
    if type(profile)~="table" then return nil,"Profile must contain stat values." end
    local out={}
    for k,v in pairs(profile) do
        if not schema[k] then return nil,"Unsupported stat: "..tostring(k) end
        if not Core.finite(v) or v<0 or v%1~=0 then return nil,k.." must be a non-negative whole number." end
        -- Bounds reflect total available points, not invented per-stat game caps.
        if v>1000000 then return nil,"Stat value exceeds the panel's input limit." end
        out[k]=v
    end
    for k in pairs(schema) do if out[k]==nil then out[k]=0 end end
    return out
end
function Core.plan(profile, current, available, schema)
    if not Core.finite(available) or available<0 then return nil,"SkillPoints data is unavailable." end
    local target,err=Core.validateProfile(profile,schema)
    if not target then return nil,err end
    local plan={target=target,allocated=0,required=0,total=0,reset=false,changes={}}
    for key in pairs(schema) do
        local before=current[key]
        if not Core.finite(before) or before<0 or before%1~=0 then return nil,"Missing current stat: "..key end
        plan.allocated+=before
        plan.total+=target[key]
        if target[key]<before then plan.reset=true end
        table.insert(plan.changes,{name=key,before=before,after=target[key]})
    end
    table.sort(plan.changes,function(a,b) return a.name<b.name end)
    plan.available=available
    if plan.reset then plan.required=plan.total else plan.required=plan.total-plan.allocated end
    local budget=plan.reset and available+plan.allocated or available
    if plan.required>budget then return nil,"Requires "..plan.required.." points; only "..budget.." are available." end
    return plan
end
function Core.sanitize(raw, validKeys, schema)
    local c=Core.defaults()
    if type(raw)~="table" then return c end
    for _,k in ipairs({"legendary","mythic","blackleg","styleMedals","medals","trainers","health","fruit","swim"}) do
        if type(raw[k])=="boolean" then c[k]=raw[k] end
    end
    for k,bounds in pairs({speed={1,150},distance={0,100000},playerDistance={50,10000},markerLimit={5,80}}) do
        if Core.finite(raw[k]) then c[k]=math.clamp(math.floor(raw[k]),bounds[1],bounds[2]) end
    end
    if raw.forwardMode=="Camera" then c.forwardMode="Camera" end
    if type(raw.keys)=="table" then
        local candidate=Core.copy(c.keys)
        for k in pairs(candidate) do if type(raw.keys[k])=="string" and validKeys[raw.keys[k]] then candidate[k]=raw.keys[k] end end
        if candidate.forward~=candidate.anchor and candidate.forward~=candidate.panel and candidate.anchor~=candidate.panel then c.keys=candidate end
    end
    if type(raw.profiles)=="table" then
        local count=0
        for name,profile in pairs(raw.profiles) do
            if count>=24 then break end
            if Core.validName(name) then local p=Core.validateProfile(profile,schema);if p then c.profiles[name]=p;count+=1 end end
        end
    end
    return c
end
function Core.bind(keys, action, key)
    for name,value in pairs(keys) do if name~=action and value==key then return false,"Already assigned to "..name.."." end end
    keys[action]=key
    return true
end
function Core.stepDistance(speed,dt)
    return speed*math.clamp(dt,0,0.1)
end
return Core
