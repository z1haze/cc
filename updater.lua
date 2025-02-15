if not turtle then
    printError("Turtle required")
end

local files = {
    ["2YZEVMCY"] = "go.lua",
    ["6XZpaN99"] = "Miner3.lua",
    ["JyLntqAR"] = "Aware3.lua"
}

for code, name in pairs(files) do
    if fs.exists(name) then
        shell.run("rm " .. name)
    end
    shell.run("pastebin get " .. code .. " " .. name)
end