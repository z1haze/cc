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

    local storage = {
        name = {
            "immersiveengineering:crate"
        },

        tags = {
            ["minecraft:shulker_boxes"] = true,
            ["forge:shulker_boxes"] = true,
            ["forge:chests"] = true,
            ["c:chests"] = true,
        }
    }

    local fuelReserve = 20000

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

    function instance.checkpoints()
        return aware.checkpoints.points
    end

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

    --- Determine if an item details is a valid storage item
    local function isStorageItem(item)
        if not item then
            return false
        end

        -- iterate through the keys and values of the table, which are block names, and block tags
        for k, v in pairs(storage) do
            -- iterate over the keys and values of each table which are number,string or string,boolean
            for kk, _ in pairs(v) do
                -- check against valid names
                if k == "name" and item.name == v[kk] then
                    return true
                end

                -- check against valid tags
                if k == "tags" and item.tags[kk] then
                    return true
                end
            end
        end

        return false
    end

    --- Drop items in a particular direction
    local function drop(direction, count)
        if not direction or direction == "forward" then
            return turtle.drop(count)
        elseif direction == "up" then
            return turtle.dropUp(count)
        elseif direction == "down" then
            return turtle.dropDown(count)
        end

        return false
    end

    --- Make the turtle unload its entire inventory to the block at a particular direction
    local function unload(direction)
        direction = direction or "forward"

        -- if there is no block in the direction we are unloading, error out
        if not detect(direction) then
            error("I have nowhere to put these items!")
        end

        -- get the details of the block we are supposed to unload into
        local _, details = inspect(direction)

        -- if the item i'm supposed to be unloading into is not a storage item, wtf are you even doing
        if not isStorageItem(details) then
            error("Cannot deposit items into " .. details.name)
        end

        -- cache the slot we already have selected
        local slot = turtle.getSelectedSlot()

        -- an aggregate total of fuel that we choose to keep in the turtle inventory as a fuel reserve
        -- this is needed so once we accumulate enough to meet the fuel reserve, we can dump the rest
        local fuelKept = 0

        for i = 1, 16 do
            local item = turtle.getItemDetail(i)

            local amountToDrop

            -- if the item can be used as fuel, we need to do some extra processing
            -- because we want to keep _some_ fuel in the inventory as a reserve
            if aware.fuelMap[item.name] then
                local amountToKeep = 0

                for j = 1, item.count do
                    -- if we've already kept enough fuel we
                    if fuelKept >= fuelReserve then
                        break
                    end

                    amountToKeep = j
                    fuelKept = fuelKept + aware.fuelMap[item.name]
                end

                amountToDrop = item.count - amountToKeep
            else
                amountToDrop = item.count
            end

            turtle.select(i)

            if not drop(direction, amountToDrop) then
                return false
            end
        end

        return turtle.select(slot)
    end

    function instance.pitStop()
        print("doing a pitstop")
        -- go home backwards

        for i = #aware.checkpoints.points, 1, -1 do
            local loc = aware.checkpoints.points[i]
            local moved = aware.moveTo(loc, {
                direction = "back",
                order = "xzy"
            })

            if not moved then
                print("attempted: " .. loc.x .. " " .. loc.y .. " " .. loc.z .. " " .. loc.f)
                print("current: " .. location.x .. " " .. location.y .. " " .. location.z .. " " .. location.f)
                error("tried to move but couldnt")
            end
        end

        print("moved to home to unload")

        -- unload into chest, default placement is above turtle
        if not unload("up") then
            error("No storage to unload into")
            return false
        end

        -- go back to the last checkpoint
        for i = 1, #aware.checkpoints.points do
            local location = aware.checkpoints.points[i]
            aware.moveTo(location)
        end

        print("moved back to checkpoint")
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

    --- Get a table of slots which are empty in the turtle's inventory
    local function getEmptySlots()
        local t = {}

        for i = 1, 16 do
            if turtle.getItemCount(i) == 0 then
                table.insert(t, i)
            end
        end

        return t
    end

    function instance.branchMine(data)
        local branchLength = data.branchLength
        local shouldCheckUp = data.shouldCheckUp == nil and true or data.shouldCheckUp
        local shouldCheckDown = data.shouldCheckDown == nil and true or data.shouldCheckDown
        local shouldCheckLeft = data.shouldCheckLeft == nil and true or data.shouldCheckLeft
        local shouldCheckRight = data.shouldCheckRight == nil and true or data.shouldCheckRight

        for _ = 1, branchLength do
            ---- refuel if necessary
            if turtle.getFuelLevel() < 1000 then
                aware.useFuel(1000)
            end

            ---- consolidate partial stacks where possible
            if #getEmptySlots() <= 1 then
                instance:compact()
            end

            ---- check if there are empty slots, dump any useless blocks to save space
            if #getEmptySlots() <= 1 then
                instance.dropTrash()
            end

            ---- if after dump useless blocks the empty space is 1, go unload
            if #getEmptySlots() <= 1 then
                instance.pitStop()
            end

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

    --- Consolidate partial stacks of items to save inventory space
    function instance.compact()
        local incompleteStacks = {}

        -- compact stacks
        for i = 1, 16 do
            local item = turtle.getItemDetail(i)

            if item then
                local name = item.name
                local existingSlot = incompleteStacks[name]

                if existingSlot then
                    turtle.select(i)
                    turtle.transferTo(existingSlot)

                    if turtle.getItemCount() > 0 then
                        incompleteStacks[name] = i
                    end
                else
                    incompleteStacks[name] = i
                end
            end
        end
    end

    --- Make the turtle drop any items considered to be trash
    function instance.dropTrash()
        local slot = turtle.getSelectedSlot()

        for i = 1, 16 do
            local item = turtle.getItemDetail(i)

            if item then
                if junk[item.name] then
                    if not turtle.select(i) then
                        return false
                    end
                    if not drop("forward", item.count) then
                        return false
                    end
                end
            end
        end

        return turtle.select(slot)
    end

    return instance
end

return Miner