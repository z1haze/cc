-- Miner turtle module that implements Awareness and mining capabilities
local Miner = {}

function Miner.create(data)
    data = data or {}

    local instance = {}
    local Aware = require("Aware")
    local aware = Aware.create()
    local junk = data.junk or {}

    local storage = {
        name = {
            "immersiveengineering:crate",
            "ironchests:gold_chest"
        },

        tags = {
            ["minecraft:shulker_boxes"] = true,
            ["forge:shulker_boxes"] = true,
            ["forge:chests"] = true,
            ["c:chests"] = true
        }
    }

    local invert = {
        ["forward"] = "back",
        ["back"] = "forward",
        ["up"] = "down",
        ["down"] = "up"
    }

    local movements = {}

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

    function instance.turn(d)
        return aware.turn(d)
    end

    function instance.turnAround()
        return aware.turnAround()
    end

    function instance.turnTo(n)
        return aware.turnTo(n)
    end

    -----------------

    local function detect(direction)
        if not direction or direction == "forward" then
            return turtle.detect()
        elseif direction == "up" then
            return turtle.detectUp()
        elseif direction == "down" then
            return turtle.detectDown()
        end

        return false
    end

    -----------------

    --- ===============================================================
    --- MOVEMENT METHODS
    --- ===============================================================

    local function _move(direction)
        if not direction then
            direction = "forward"
        end

        return aware[direction](1, true)
    end

    function instance.move(direction, _invert)
        direction = direction or "forward"

        if _invert then
            direction = invert[direction]
        end

        local moved = false

        while true do
            -- attempt to move the turtle
            moved = _move(direction)

            -- if the turtle moved, return true
            if moved then
                break
            end

            -- if the turtle didnt move because of fuel, return false
            if turtle.getFuelLevel() == 0 then
                error("OUT OF GAS -- MAYBE PITSTOP WITH WAIT FOR FUEL FLAG?")
            end

            -- if the direction is back, we need to turn around to detect
            if direction == "back" then
                instance.turnAround()
            end

            -- if the turtle didnt move because of a block, return false
            local detectResult = detect(direction == "back" and "forward" or direction)

            -- if there is a block in front, that's why it didnt move, return false this is normal
            if detectResult then
                error("couldn't move, block in the way")
            end

            -- turn the turtle back around
            if direction == "back" then
                aware.turnAround()
            end

            -- finally, if the turtle didnt move, but he has fuel, and there is no block in his way, some entity is blocking him, so we must smash it
            while true do
                -- if the direction is back, we need to turn around to detect
                if direction == "back" then
                    aware.turnAround()
                end

                local attackResult = instance.attack(direction)

                -- turn the turtle back around
                if direction == "back" then
                    direction.turnAround()
                end

                if not attackResult then
                    break
                end
            end
        end

        return moved
    end

    function instance.home(data)
        data = data or {}

        return aware.home(data.order or "xzy", data.canDig or false)
    end

    --- ===============================================================
    --- LOCATION METHODS
    --- ===============================================================

    function instance.getLocation()
        return aware.getLocation()
    end

    function instance.moveTo(location, options)
        aware.moveTo(location, options)
    end

    -------------------------------
    -------------------------------
    -------------------------------

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
    function instance.unload(direction)
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

            if item then
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
        end

        return turtle.select(slot)
    end

    -- traverse the movements logged from the recursiveDig function
    local function traverseMovements(reverse)
        if reverse then
            for i = #movements, 1, -1 do
                local movement = movements[i]

                if movement == "left" then
                    aware.turnRight()
                elseif movement == "right" then
                    aware.turnLeft()
                else
                    instance.move(movements[i], true)
                end
            end
        else
            for i = 1, #movements do
                local movement = movements[i]

                if movement == "left" then
                    aware.turnLeft()
                elseif movement == "right" then
                    aware.turnRight()
                else
                    instance.move(movements[i])
                end
            end
        end
    end

    function instance.pitStop()
        os.queueEvent("pitstop")
        traverseMovements(true)
        aware.setCheckpoint()
        aware.home("zxy", true)

        -- unload into chest, default placement is above turtle
        if not instance.unload("up") then
            error("No storage to unload into")
            return false
        end

        os.queueEvent("checkpoint")
        aware.moveTo(aware.getCheckpoint())
        aware.clearCheckpoint()
        traverseMovements()
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

    local function freeUpSpace()
        ---- refuel if necessary
        if turtle.getFuelLevel() < 1000 then
            aware.useFuel(1000)
        end

        ---- consolidate partial stacks where possible
        if #getEmptySlots() < 2 then
            instance.compact()
        end

        ---- check if there are empty slots, dump any useless blocks to save space
        if #getEmptySlots() < 2 then
            instance.dropTrash()
        end

        ---- if after dump useless blocks the empty space is 1, go unload
        if #getEmptySlots() < 2 then
            instance.pitStop()
            os.queueEvent("branch")
        end
    end

    local function recursiveDig(dir)
        dir = dir or "forward"

        --- helper function to dig blocks recursively in a direction
        --
        -- @param d string: direction
        local function dig(d)
            d = d or "forward"
            instance.dig(d)
            os.queueEvent("block_collected")
            freeUpSpace()
            instance.move(d)
            table.insert(movements, d)
            recursiveDig(d)
            instance.move(d, true) -- moves the inverse
            table.remove(movements)
        end

        --------------------------------- begin recursive checking ---------------------------------

        local positions = { "forward", "left", "right", "up", "down", "back" }

        -- remove the inverse of forward, up, or down, because
        -- we dont need to check the direction we came from
        if dir == "forward" or dir == "up" or dir == "down" then
            local indexToRemove

            for key, v in pairs(positions) do
                if v == invert[dir] then
                    indexToRemove = key
                    break
                end
            end

            positions[indexToRemove] = nil
        end

        -- loop over the remaining directions and handle accordingly
        for _, v in pairs(positions) do
            dir = v

            -- turn to direction
            if v == "left" then
                instance.turn("left")
                table.insert(movements, "left")
            elseif v == "right" then
                instance.turn("right")
                table.insert(movements, "right")
            elseif v == "back" then
                instance.turnAround()
                table.insert(movements, "right")
                table.insert(movements, "right")
            end

            -- for both and right, we just check forward
            -- because we turn to face that direction
            if v == "left" or v == "right" or v == "back" then
                dir = "forward"
            end

            if check(dir) then
                dig(dir)
            end

            -- turn back to front
            if v == "left" then
                instance.turn("right")
                table.remove(movements)
            elseif v == "right" then
                instance.turn("left")
                table.remove(movements)
            elseif v == "back" then
                instance.turnAround()
                table.remove(movements)
                table.remove(movements)
            end
        end

        return true
    end

    local function handleBlock(direction, doRecursiveChecks)
        direction = direction or "forward"

        if check(direction) then
            instance.dig(direction)
            os.queueEvent("block_collected")

            if doRecursiveChecks then
                instance.move(direction)
                table.insert(movements, direction)
                recursiveDig(direction)
                instance.move(direction, true)
                movements = {}
            end
        end
    end

    function instance.branchMine(data)
        local branchLength = data.branchLength
        local shouldCheckUp = data.shouldCheckUp == nil and true or data.shouldCheckUp
        local shouldCheckDown = data.shouldCheckDown == nil and true or data.shouldCheckDown
        local shouldCheckLeft = data.shouldCheckLeft == nil and true or data.shouldCheckLeft
        local shouldCheckRight = data.shouldCheckRight == nil and true or data.shouldCheckRight
        local shouldDigRecursively = data.shouldDigRecursively == nil and false or data.shouldDigRecursively

        for i = 1, branchLength do
            movements = {} -- just in case?

            os.queueEvent("branch_block", i)

            freeUpSpace()

            -- this ensures that if we want branches that are total length of 16 blocks that
            -- that only 15 blocks will be traveled but all 16 blocks will be checked.
            -- this is because the turtle starts on the surface on block 1 and digs down to the
            -- correct y-level and begins branch mining
            -- doing this means that the starting block will get the proper checks too
            if i > 1 then
                instance.dig()

                if not instance.move() then
                    error("Tried to move in branch mine but couldn't")
                end
            end

            -- check the block above
            if shouldCheckUp then
                handleBlock("up", shouldDigRecursively)
            end

            -- check the block below
            if shouldCheckDown then
                handleBlock("down", shouldDigRecursively)
            end

            -- check the block to the left
            if shouldCheckLeft then
                instance.turnLeft()
                handleBlock("forward", shouldDigRecursively)
                instance.turnRight()
            end

            -- check the block to the right
            if shouldCheckRight then
                instance.turnRight()
                handleBlock("forward", shouldDigRecursively)
                instance.turnLeft()
            end
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