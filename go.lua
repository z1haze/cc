if not turtle then
    error("Turtle required!")
end

write("Miner initializing")
textutils.slowPrint("...", 5)

local DEBUG = false

local Miner = require("Miner")
local miner = Miner.create({
    junk = {
        ["minecraft:dirt"] = true,
        ["minecraft:stone"] = true,
        ["minecraft:cobblestone"] = true,
        ["minecraft:deepslate"] = true,
        ["minecraft:cobbled_deepslate"] = true,
        ["minecraft:tuff"] = true,
        ["minecraft:gravel"] = true,
        ["minecraft:andesite"] = true,
        ["minecraft:granite"] = true,
        ["minecraft:diorite"] = true,
        -- byg
        ["byg:soapstone"] = true,
        -- blockus
        ["blockus:limestone"] = true,
        ["blockus:marble"] = true,
        ["blockus:bluestone"] = true,
        ["blockus:veridite"] = true,
        -- create
        ["create:asurine"] = true,
        -- promenade
        ["promenade:carbonite"] = true,
        ["promenade:blunite"] = true
    }
})

-- Program level variables
local branchCount, branchLength, branchGap, startY, minY, maxY, targetY, floorGap

--- ===============================================================
--- GUI STUFF
--- ===============================================================

local function clearLine()
    local x, y = term.getCursorPos()

    term.setCursorPos(1, y)
    write("|                                     |")
    term.setCursorPos(x, y)
end

local resourceMessages = {
    action = {
        ["descend"] = "Descending",
        ["branch"] = "Branch Mining",
        ["home"] = "Heading Home",
        ["pitstop"] = "Pitstop",
        ["checkpoint"] = "Checkpoint",
        ["floor"] = "Next Floor",
        ["done"] = "Finished"
    }
}

local GUIAction
local GUICurrentBranch = 1
local GUICollected = 0
local GUIMoved = 0
local GUIBranchBlock = 1

local function guiStats()
    local action = GUIAction
    local actionResourceMsg = action and resourceMessages.action[action] or "Awaiting Work"
    local actionMessage

    -- write the current action line
    term.setCursorPos(3, 2)
    clearLine()
    write("Current Action: " .. actionResourceMsg .. "...")

    if action == "descend" then
        actionMessage = "Descending to Y-Level " .. targetY
    elseif action == "branch" then
        actionMessage = "On Branch " .. GUICurrentBranch .. "/" .. branchCount

        if GUIBranchBlock then
            actionMessage = actionMessage .. ", Block " .. GUIBranchBlock .. "/" .. branchLength
        end
    elseif action == "pitstop" then
        actionMessage = "Shitter's full, gotta dump"
    elseif action == "checkpoint" then
        actionMessage = "Moving to saved checkpoint"
    elseif action == "home" then
        actionMessage = "Finishing mining, heading home"
    elseif action == "done" then
        actionMessage = "Operation Complete."
    end

    if actionMessage then
        term.setCursorPos(3, 4)
        clearLine()
        write(actionMessage)
    end

    -- total blocks traveled
    term.setCursorPos(3, 6)
    clearLine()
    write("Distance Traveled : " .. GUIMoved)

    -- total ores mined
    term.setCursorPos(3, 7)
    clearLine()
    write("Blocks Collected  : " .. GUICollected)

    -- current fuel level
    term.setCursorPos(3, 8)
    clearLine()
    write("Fuel Level        : " .. turtle.getFuelLevel())

    -- target y level
    term.setCursorPos(3, 9)
    clearLine()
    write("Target Y-Level    : " .. targetY)
end

local function guiFrame()
    term.clear()

    -- side borders
    for i = 1, 13 do
        term.setCursorPos(1, i)
        write("|")
        term.setCursorPos(39, i)
        write("|")
    end

    -- top border
    term.setCursorPos(1, 1)
    write("O-------------------------------------O")

    -- middle line
    term.setCursorPos(1, 5)
    write("O-------------------------------------O")

    -- bottom border
    term.setCursorPos(1, 13)
    write("O-------------------------------------O")

    -- move cursor to bottom
    local _, h = term.getSize()
    term.setCursorPos(1, h)
end

local function setup()
    if DEBUG then
        branchCount = 6
        branchLength = 16
        branchGap = 0
        floorGap = 1
        startY = 63
        minY = 40
        maxY = 44
    else
        while branchCount == nil do
            print("");
            print("How many branches should be mined?")

            local input = read();
            branchCount = tonumber(input)

            if branchCount == nil then
                print("'" .. input .. "' should be a number")
            end
        end

        while branchLength == nil do
            print("");
            print("How long should each branch be?")

            local input = read();
            branchLength = tonumber(input)

            if branchLength == nil then
                print("'" .. input .. "' should be a number")
            end
        end

        if branchCount > 1 then
            while branchGap == nil do
                print("");
                print("How many block gap should there be between branches?")

                local input = read();
                branchGap = tonumber(input)

                if branchGap == nil then
                    print("'" .. input .. "' should be a number")
                end
            end
        end

        while floorGap == nil do
            print("");
            print("How many blocks between layers?")

            local input = read();
            floorGap = tonumber(input)

            if floorGap == nil then
                print("'" .. input .. "' should be a number")
            end
        end

        while startY == nil do
            print("");
            print("What is the startY of the turtle?")

            local input = read();
            startY = tonumber(input)

            if startY == nil then
                print("'" .. input .. "' should be a number")
            end
        end

        while minY == nil do
            print("");
            print("What is the minY?")

            local input = read();
            minY = tonumber(input)

            if minY == nil then
                print("'" .. input .. "' should be a number")
            end
        end

        while maxY == nil do
            print("");
            print("What is the maxY?")

            local input = read();
            maxY = tonumber(input)

            if maxY == nil then
                print("'" .. input .. "' should be a number")
            end
        end
    end

    targetY = minY
    guiFrame()
end

function main()
    setup()

    -- move down to the min y level to start branch mining
    GUIAction = "descend"
    miner.moveTo({
        x = 0,
        y = minY - startY, -- moving to absolute y from relative y
        z = 0,
        f = 1
    }, {
        canDig = true
    })

    local keepGoing = true

    -- mine out all floors
    while keepGoing do
        GUIAction = "branch"

        for i = 1, branchCount do
            GUICurrentBranch = i

            local isEvenBranch = i % 2 == 0

            -- face the branch
            if isEvenBranch then
                miner.turnLeft()
            else
                miner.turnRight()
            end

            miner.branchMine({
                branchLength = branchLength,
                shouldCheckLeft = false,
                shouldCheckRight = false,
                shouldDigRecursively = true
            })

            -- move across the z axis to prepare for the next branch
            if i < branchCount then
                miner.turnTo(1)

                for _ = 1, branchGap + 1 do
                    miner.dig()
                    miner.move()
                end
            end
        end

        -- PREPARE FOR POSSIBLE NEXT FLOOR!

        -- move to vertical shaft
        miner.moveTo({
            x = 0,
            y = miner.getLocation().y,
            z = 0,
            f = 1
        }, {
            canDig = false,
            order = "zxy"
        })

        -- next potential y level to mine out
        targetY = startY + miner.getLocation().y + floorGap + 1

        -- are we at beyond the starting y?
        if targetY >= startY or targetY > maxY then
            keepGoing = false
        else
            -- move up n number of blocks
            GUIAction = "floor"
            miner.moveTo({
                x = 0,
                y = targetY - startY,
                z = 0,
                f = 1
            }, {
                canDig = false
            })
        end
    end

    GUIAction = "home"
    miner.home({
        canDig = true
    })

    miner.unload("up")
end

function listen()
    while true do
        local shouldUpdate = false
        local event, data = os.pullEvent()

        if event == "branch_block" then
            GUIBranchBlock = data
            shouldUpdate = true
        end

        if event == "block_collected" then
            GUICollected = GUICollected + 1
            shouldUpdate = true
        end

        if event == "moved" then
            GUIMoved = GUIMoved + 1
            shouldUpdate = true
        end

        if event == "action_change" then
            shouldUpdate = true
        end

        if event == "pitstop" then
            GUIAction = "pitstop"
            shouldUpdate = true
        end

        if event == "checkpoint" then
            GUIAction = "checkpoint"
            shouldUpdate = true
        end

        if shouldUpdate then
            guiStats()
        end
    end
end

parallel.waitForAny(main, listen)