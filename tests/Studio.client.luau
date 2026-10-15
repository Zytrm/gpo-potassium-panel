local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local qa=RS:WaitForChild("GPOFieldKitQA")
local report=qa:WaitForChild("Report")
local function run()
    local pass=0
    local function check(name,condition) assert(condition,name);pass+=1;print("[FIELDKIT QA] PASS "..name) end
    local char=player.Character or player.CharacterAdded:Wait()
    local h=char:WaitForChild("Humanoid",10);local root=char:WaitForChild("HumanoidRootPart",10)
    assert(h and root,"No test character")
    root.CFrame=CFrame.new(0,10000,0);root.AssemblyLinearVelocity=Vector3.zero
    local state=require(qa.Main)
    check("client boots with disruptive actions off",state.running and not state.forward and not state.anchor)
    check("all five tabs created",state.ui.pages.ESP and state.ui.pages.Movement and state.ui.pages.Players and state.ui.pages["Stat Profiles"] and state.ui.pages.Settings)
    for name in pairs(state.ui.pages) do state.ui:show(name);check("tab "..name,state.ui.pages[name].Visible) end
    state.ui:collapse();check("collapse",not state.ui.body.Visible);state.ui:collapse();check("expand",state.ui.body.Visible)
    local wasAnchored,wasAuto=root.Anchored,h.AutoRotate
    state.setAnchor(true);check("anchor enables",root.Anchored and not h.AutoRotate and state.anchor)
    local anchoredPosition=root.Position;task.wait(0.2);check("anchor holds position in midair",(root.Position-anchoredPosition).Magnitude<0.01)
    state.setAnchor(false);check("anchor restores properties",root.Anchored==wasAnchored and h.AutoRotate==wasAuto and not state.anchor)
    state.setForward(true);state.setAnchor(true);check("anchor stops forward",not state.forward and state.anchor)
    state.setForward(true);check("forward releases anchor",state.forward and not state.anchor and root.Anchored==wasAnchored)
    local before=root.Position
    task.wait(0.3)
    check("forward moves character",(root.Position-before).Magnitude>1)
    state.setForward(false);root.CFrame=CFrame.new(0,10000,0)
    local wall=Instance.new("Part");wall.Name="FieldKitCollisionFixture";wall.Anchored=true;wall.Size=Vector3.new(100,2000,1);wall.CFrame=CFrame.new(0,10000,-8);wall.Parent=workspace
    state.setForward(true);task.wait(0.5);state.setForward(false)
    check("forward movement stops before wall",root.Position.Z>-7.5 and root.Position.Z<-1)
    wall:Destroy()
    state.safetyReset();check("safety reset clears actions",not state.forward and not state.anchor and root.Anchored==wasAnchored)
    local chest=Instance.new("Model");chest.Name="Legendary Fruit Chest"
    local part=Instance.new("Part");part.Anchored=true;part.Position=root.Position+Vector3.new(0,0,-20);part.Parent=chest;chest.PrimaryPart=part;chest.Parent=workspace
    task.wait(0.2);check("spawned chest registered",state.markers[chest] and state.markers[chest].category=="legendary")
    chest:Destroy();task.wait(0.1);check("destroyed chest removed",state.markers[chest]==nil)
    local fake=Instance.new("Model");fake.Name="Legendary Fruit Chest Blueprint";fake.Parent=workspace;task.wait(0.1)
    check("blueprint excluded",state.markers[fake]==nil);fake:Destroy()
    local npcRoot=workspace:FindFirstChild("NPCs") or Instance.new("Folder",workspace);npcRoot.Name="NPCs"
    local npc=Instance.new("Model");npc.Name="Yome";local np=Instance.new("Part",npc);np.Anchored=true;np.Position=root.Position; npc.PrimaryPart=np;npc.Parent=npcRoot
    task.wait(0.1);check("Yome remains only a trainer",state.markers[npc] and state.markers[npc].category=="trainers");npc:Destroy()
    local medal=Instance.new("Part");medal.Name="BlackLeg";medal.Anchored=true;medal.Position=root.Position;medal.Parent=workspace
    state.pickupEvent("spawnfs",medal)
    check("spawnfs pickup has explicit Black Leg identity",state.markers[medal] and state.markers[medal].category=="styleMedals" and state.markers[medal].blackleg)
    medal:Destroy();task.wait(0.1);check("collected Black Leg pickup marker removed",state.markers[medal]==nil)
    local other=Instance.new("Part");other.Name="UnidentifiedToken";other.Anchored=true;other.Parent=workspace
    state.pickupEvent("spawnfs",other);check("unknown style is not guessed",state.markers[other] and not state.markers[other].blackleg)
    state.pickupEvent("spawnMedal",other);check("spawnMedal has independent category",state.markers[other] and state.markers[other].category=="medals");other:Destroy()
    state.pickupEvent("spawnfs",nil);check("unavailable pickup handled",state.lastPickupEvent:find("unavailable")~=nil)
    local beam=Instance.new("Model");beam.Name="medalPiller"
    for _=1,2 do local p=Instance.new("Part");p.Anchored=true;p.Parent=beam;local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Cylinder;mesh.Parent=p end
    beam.Parent=workspace.Effects;task.wait(0.1)
    check("existing exact medal beam shape detected",state.markers[beam] and state.markers[beam].category=="styleMedals");beam:Destroy()
    local snap=state.snapshot();check("actual stat fields read",snap and snap.available==100 and snap.current.SwordMastery==0)
    state.fields.SwordMastery.Text="20";state.preview();check("stat preview requires confirmation",state.ui.modal~=nil and snap.stats.SwordMastery.Value==0)
    state.ui.modal:Destroy();state.ui.modal=nil
    local values={};for key in pairs(snap.schema) do values[key]=0 end;values.SwordMastery=20;values.Defense=10
    local plan=assert(state.Core.plan(values,snap.current,snap.available,snap.schema))
    state.applyProfile(snap,plan,nil)
    local deadline=os.clock()+15;repeat task.wait(0.1) until not state.transaction or os.clock()>deadline
    local allocated=state.snapshot()
    check("allocation confirms exact replicated totals",not state.transaction and allocated.current.SwordMastery==20 and allocated.current.Defense==10 and allocated.available==70)
    values.SwordMastery=0;values.Defense=5
    local resetPlan=assert(state.Core.plan(values,allocated.current,allocated.available,allocated.schema))
    state.applyProfile(allocated,resetPlan,1)
    deadline=os.clock()+15;repeat task.wait(0.1) until not state.transaction or os.clock()>deadline
    local reset=state.snapshot()
    check("essence reset followed by confirmed allocation",not state.transaction and reset.current.SwordMastery==0 and reset.current.Defense==5 and reset.available==95)
    check("reset consumes exactly one essence",RS["Stats"..player.Name].Inventory.Inventory.Value=="{}")
    h.EvaluateStateMachine=false
    h.WalkSpeed=20;state.config.swim=true;h:ChangeState(Enum.HumanoidStateType.Swimming)
    task.wait(0.2);check("native swim adds ten percent",math.abs(h.WalkSpeed-22)<0.001)
    task.wait(0.3);check("native swim does not compound",math.abs(h.WalkSpeed-22)<0.001)
    h.WalkSpeed=30;task.wait(0.2);check("swim respects updated baseline",math.abs(h.WalkSpeed-33)<0.001)
    h:ChangeState(Enum.HumanoidStateType.Running);task.wait(0.2);check("leaving water restores baseline",math.abs(h.WalkSpeed-30)<0.001)
    h:ChangeState(Enum.HumanoidStateType.Swimming);task.wait(0.2);state.config.swim=false;task.wait(0.2)
    check("disabling swim restores baseline",math.abs(h.WalkSpeed-30)<0.001)
    h.EvaluateStateMachine=true
    state.setAnchor(true);h.Health=0;task.wait(0.2);check("death releases anchor",not state.anchor and root.Anchored==wasAnchored)
    state.stop();check("unload destroys GUI",not state.running and state.gui.Parent==nil)
    report:FireServer(true,pass.." client checks passed")
end
local ok,err=pcall(run)
if not ok then warn("[FIELDKIT QA] FAIL "..tostring(err));report:FireServer(false,tostring(err)) end
