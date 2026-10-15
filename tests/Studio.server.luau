local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local qa=RS:WaitForChild("GPOFieldKitQA")
local report=Instance.new("RemoteEvent");report.Name="Report";report.Parent=qa
local finished,success,message=false,false,"Client never reported"
report.OnServerEvent:Connect(function(_,ok,result) finished=true;success=ok;message=result end)
local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local statsRoot=Instance.new("Folder");statsRoot.Name="Stats"..player.Name;statsRoot.Parent=RS
local stats=Instance.new("Folder");stats.Name="Stats";stats.Parent=statsRoot
local points=Instance.new("IntValue");points.Name="SkillPoints";points.Value=100;points.Parent=stats
for _,name in ipairs({"SwordMastery","Defense","Strength","Stamina","GunMastery","DevilFruitMastery","FightingStyleMastery"}) do local v=Instance.new("IntValue");v.Name=name;v.Parent=stats end
local inventory=Instance.new("Folder");inventory.Name="Inventory";inventory.Parent=statsRoot
local items=Instance.new("StringValue");items.Name="Inventory";items.Value='{"SP Reset Essence":1}';items.Parent=inventory
-- Test double only: validates the observed protocol and updates replicated fixture data.
-- This does not claim to reconstruct the missing game's server rules.
local remote=RS.Events.stats
remote.OnServerEvent:Connect(function(sender,name,unused,amount)
    if sender~=player then return end
    if name=="BattleRoyaleSPReset" then
        local data=game:GetService("HttpService"):JSONDecode(items.Value)
        if (data["SP Reset Essence"] or 0)<1 then return end
        for _,v in ipairs(stats:GetChildren()) do if v~=points then points.Value+=v.Value;v.Value=0 end end
        items.Value='{}'
    elseif type(name)=="string" and unused==nil and type(amount)=="number" and amount%1==0 and amount>0 and amount<=points.Value then
        local stat=stats:FindFirstChild(name)
        if stat and stat~=points then stat.Value+=amount;points.Value-=amount end
    end
end)
-- The copied lobby has CharacterAutoLoads=false and no original spawn service.
player:LoadCharacterAsync()
local client=qa.Client:Clone();client.Parent=player:WaitForChild("PlayerGui")
local deadline=os.clock()+35
repeat task.wait(0.1) until finished or os.clock()>deadline
print("[FIELDKIT QA] "..message)
assert(success,message)
