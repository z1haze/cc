-- Miner turtle module that implements Awareness and mining capabilities
local Miner = {}

function Miner.create()
    local instance = {}
    local Aware = require("Aware")
    local aware = Aware.create()

    local junk = {
        ["minecraft:stone"] = true,
        ["minecraft:cobblestone"] = true,
        ["minecraft:deepslate"] = true,
        ["minecraft:cobbled_deepslate"] = true,
        ["minecraft:gravel"] = true,
        ["minecraft:andesite"] = true,
        ["minecraft:granite"] = true,
        ["minecraft:diorite"] = true
    }

    --- ===============================================================
    --- ROTATION METHODS
    --- ===============================================================

    function instance.turnLeft()
        return aware.turnLeft()
    end

    function instance.turnRight()
        return aware.turnRight()
    end

    function instance.turnTo(n)
        return aware.turnTo(n)
    end

    --- ===============================================================
    --- MOVEMENT METHODS
    --- ===============================================================

    local function move(direction)
        if not direction then
            direction = "forward"
        end

        return aware[direction](1, true)
    end

    function instance.move(direction)
        if not direction then
            direction = "forward"
        end

        local moved = false

        while true do
            -- attempt to move the turtle
            moved = move(direction)

            -- if the turtle moved, return true
            if moved then
                break
            end

            -- if the turtle didnt move because of fuel, return false
            if turtle.getFuelLevel() == 0 then
                error("ain't got no gas innit")
            end

            -- if the turtle didnt move because of a block, return false
            local detectResult = detect(direction == "back" and "forward" or direction)

            -- if there is a block in front, that's why it didnt move, return false this is normal
            if detectResult then
                error("couldn't move, but don't know why")
            end

            -- finally, if the turtle didnt move, but he has fuel, and there is no block in his way, some entity is blocking him, so we must smash it
            while true do
                local attackResult = instance.attack(direction)

                if not attackResult then
                    break
                end
            end
        end

        return moved
    end

    function instance.home(canDig)
        aware.home("xzy", canDig or false)
    end

    --- ===============================================================
    --- LOCATION/CHECKPOINT METHODS
    --- ===============================================================

    function instance.resetCheckpoints()
        return aware.checkpoints.reset()
    end

    function instance.addCheckpoint()
        return aware.checkpoints.add()
    end

    function instance.removeCheckpoints(n)
        return aware.checkpoints.removeLastN(n)
    end

    function instance.getLocation()
        return aware.getLocation()
    end

    function instance.moveTo(location, options)
        aware.moveTo(location, options)
    end

    -------------------------------
    -------------------------------
    -------------------------------

    function instance.pitStop()
        for i = #aware.checkpoints.points, 1, -1 do
            local location = aware.checkpoints.points[i]
            aware.moveTo(location, { direction = "back" })
        end
    end

    local function detect(direction)
        if not direction or d == "forward" then
            return turtle.detect()
        elseif direction == "up" then
            return turtle.detectUp()
        elseif direction == "down" then
            return turtle.detectDown()
        end

        return false
    end

    local function inspect(direction)
        if not direction or direction == "forward" then
            return turtle.inspect()
        elseif direction == "up" then
            return turtle.inspectUp()
        elseif direction == "down" then
            return turtle.inspectDown()
        end

        return false
    end

    local function check(direction)
        if detect(direction) then
            local result, block = inspect(direction)

            if result and not junk[block.name] then
                return true
            end
        end

        return false
    end

    function instance.branchMine(data)
        local branchLength = data.branchLength
        local shouldCheckUp = data.shouldCheckUp == nil and true or data.shouldCheckUp
        local shouldCheckDown = data.shouldCheckDown == nil and true or data.shouldCheckDown
        local shouldCheckLeft = data.shouldCheckLeft == nil and true or data.shouldCheckLeft
        local shouldCheckRight = data.shouldCheckRight == nil and true or data.shouldCheckRight

        for _ = 1, branchLength do
            ---- refuel if necessary
            --if turtle.getFuelLevel() < 1000 then
            --    self:useFuel(1000)
            --end
            --
            ---- consolidate partial stacks where possible
            --if #self:getEmptySlots() <= 1 then
            --    self:compact()
            --end
            --
            ---- check if there are empty slots, dump any useless blocks to save space
            --if #self:getEmptySlots() <= 1 then
            --    self:dropTrash()
            --end

            -- if after dump useless blocks the empty space is 1, go unload
            --if #self:getEmptySlots() <= 1 then
            --    self:pitStop()
            --end

            instance.dig()

            if not instance.move() then
                error("Tried to move in branch mine but couldn't")
            end

            -- check the block above
            if shouldCheckUp then
                if check("up") then
                    instance.dig("up")
                end
            end

            -- check the block below
            if shouldCheckDown then
                if check("down") then
                    instance.dig("down")
                end
            end

            if shouldCheckLeft then
                -- check the block to the left
                instance.turnLeft()
                if check() then
                    instance.dig()
                end
                instance.turnRight()
            end

            if shouldCheckRight then
                -- check the block to the right
                instance.turnRight()
                if check() then
                    instance.dig()
                end
                instance.turnLeft()
            end

            -- add checkpoint after each block on the branch
            instance.addCheckpoint()
        end
    end

    function instance.dig(direction)
        if not direction or direction == "forward" then
            return turtle.dig()
        elseif direction == "up" then
            return turtle.digUp()
        elseif direction == "down" then
            return turtle.digDown()
        end

        return false
    end

    function instance.attack(direction)
        if not direction or direction == "forward" then
            return turtle.attack()
        elseif direction == "up" then
            return turtle.attackUp()
        elseif direction == "down" then
            return turtle.attackDown()
        end

        return false
    end

    return instance
end

return Miner