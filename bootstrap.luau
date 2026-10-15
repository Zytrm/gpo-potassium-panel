-- Standalone Potassium loader. The checked-in revision is updated on release.
local sha = "main"
if type(request) == "function" then
    local ok,response=pcall(request,{
        Url="https://api.github.com/repos/Zytrm/gpo-potassium-panel/commits/main",
        Method="GET",Headers={["User-Agent"]="GPOFieldKit"},
    })
    if ok and response and response.StatusCode==200 then
        local parsed,commit=pcall(game:GetService("HttpService").JSONDecode,game:GetService("HttpService"),response.Body)
        if parsed and type(commit)=="table" and type(commit.sha)=="string" and #commit.sha==40 and commit.sha:match("^[0-9a-f]+$") then sha=commit.sha end
    end
end
local source=game:HttpGet("https://raw.githubusercontent.com/Zytrm/gpo-potassium-panel/"..sha.."/main.luau")
local run,err=loadstring(source)
assert(run,"GPO Field Kit failed to compile: "..tostring(err))
return run()
