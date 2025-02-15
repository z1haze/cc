-- Aware turtle module that tracks location and provides movement methods
local Aware = {}

---Creates a new Aware turtle instance with location tracking and movement capabilities
---@return table instance A new turtle instance with the following methods:
---
--- Movement Methods:
---@field forward fun(distance?: number, canDig?: boolean): boolean Move forward by specified distance
---@field back fun(distance?: number, canDig?: boolean): boolean Move backward by specified distance
---@field up fun(distance?: number, canDig?: boolean): boolean Move up by specified distance
---@field down fun(distance?: number, canDig?: boolean): boolean Move down by specified distance
---@field moveTo fun(x: number, y: number, z: number, f?: number, canDig?: boolean, order?: string): boolean Move to specific coordinates. order defaults to "yxz"
---@field home fun(canDig?: boolean, order?: string): boolean move to home coordinates order defaults to "yxz"
---
--- Rotation Methods:
---@field turnLeft fun(): boolean Turn 90 degrees left
---@field turnRight fun(): boolean Turn 90 degrees right
---@field turnAround fun(): boolean Turn 180 degrees
---@field turnTo fun(n: number|string): boolean Turn to face direction. Accepts numbers 1-4 or strings "x", "-x", "z", "-z"
---
--- Location Methods:
---@field getLocation fun(): table Returns current location {x: number, y: number, z: number, f: number}
---
--- Checkpoint Methods:
---@field checkpoints table Checkpoint management
---@field checkpoints.points table[] Array of saved location checkpoints
---@field checkpoints.add fun() Save current location as checkpoint
---@field checkpoints.pop fun(): table|nil Remove and return last checkpoint
---@field checkpoints.removeLastN fun(n: number): table[] Remove last n checkpoints and return them
function Aware.create()
    local instance = {}
    local home = {x = 0, y = 0, z = 0, f = 1}
    local location = {x = 0, y = 0, z = 0, f = 1}

    instance.checkpoints = {
        points = {
            home
        },

        -- Add a new location to the checkpoints table
        add = function()
            table.insert(instance.checkpoints.points, {
                x = location.x,
                y = location.y,
                z = location.z,
                f = location.f
            })
        end,

        -- Remove the last location in the checkpoints table
        pop = function()
            if #instance.checkpoints.points > 0 then
                return table.remove(instance.checkpoints.points)
            end

            return nil
        end,

        -- Remove the last `N` number of locations from the checkpoints table
        removeLastN = function(n)
            if type(n) ~= "number" then
                return false, "Invalid arguments. n must be a number"
            end

            -- Ensure we don't try to remove more elements than exist
            local count = math.min(n, #instance.checkpoints.points)
            local removed = {}

            for _ = 1, count do
                table.insert(removed, table.remove(instance.checkpoints.points))
            end

            return removed
        end,

        reset = function()
            instance.checkpoints.points = {
                home
            }
        end
    }

    -- Get current location
    function instance.getLocation()
        return {
            x = location.x,
            y = location.y,
            z = location.z,
            f = location.f
        }
    end

    --- ===============================================================
    --- MOVEMENT METHODS
    --- ===============================================================

    -- Move the turtle along an axis, optionally allowing it to dig if it needs to
    local function move(direction, distance, canDig)
        -- default direction
        if not direction then
            direction = "forward"
        end

        -- default distance of 1
        if not distance then
            distance = 1
        end

        -- ensure valid direction
        if direction ~= "forward" and direction ~= "back" and direction ~= "up" and direction ~= "down" then
            error("invalid direction")
        end

        -- for each distance
        for _ = 1, distance do
            -- attempt to move turtle in direction
            while not turtle[direction]() do
                local detectMethod = "detect"
                local digMethod = "dig"
                local attackMethod = "attack"
                local fail = false

                -- if direction is back we need to turn around and face that block
                if direction == "back" then
                    turtle.turnLeft()
                    turtle.turnLeft()
                end

                -- update methods if up or down
                if direction == "up" or direction == "down" then
                    detectMethod = detectMethod .. string.upper(string.sub(direction, 1, 1)) .. string.sub(direction, 2)
                    digMethod = digMethod .. string.upper(string.sub(direction, 1, 1)) .. string.sub(direction, 2)
                    attackMethod = attackMethod .. string.upper(string.sub(direction, 1, 1)) .. string.sub(direction, 2)
                end

                -- detect a block
                if turtle[detectMethod]() then
                    if canDig then
                        -- dig the detected block
                        if not turtle[digMethod]() then
                            fail = true
                        end
                    else
                        -- fail because we dont have permission to dig the block
                        error("I need to dig, but I'm not allowed")
                    end
                else
                    -- since we didnt move, and we didnt detect a block, and we're not out of fuel, must be some entity in the way, attack it!
                    turtle[attackMethod]()
                end

                if direction == "back" then
                    turtle.turnLeft()
                    turtle.turnLeft()
                end

                if fail then
                    return false
                end
            end

            -- update stored location
            if direction == "up" or direction == "down" then
                location.y = direction == "down" and location.y - 1 or location.y + 1
            elseif direction == "forward" or direction == "back" then
                if location.f == 1 then
                    location.z = direction == "back" and location.z + 1 or location.z - 1
                elseif location.f == 2 then
                    location.x = direction == "back" and location.x - 1 or location.x + 1
                elseif location.f == 3 then
                    location.z = direction == "back" and location.z - 1 or location.z + 1
                elseif location.f == 4 then
                    location.x = direction == "back" and location.x + 1 or location.x - 1
                end
            end

            os.queueEvent("location_updated")
        end

        return true
    end

    -- Move the turtle forwards `N` number of blocks, optionally allowing it to dig if it needs to
    function instance.forward(distance, canDig)
        return move("forward", distance, canDig)
    end

    -- Move the turtle backwards `N` number of blocks, optionally allowing it to dig if it needs to
    function instance.back(distance, canDig)
        return move("back", distance, canDig)
    end

    -- Move the turtle up `N` number of blocks, optionally allowing it to dig if it needs to
    function instance.up(distance, canDig)
        return move("up", distance, canDig)
    end

    -- Move the turtle down `N` number of blocks, optionally allowing it to dig if it needs to
    function instance.down(distance, canDig)
        return move("down", distance, canDig)
    end

    -- Explicitly move the turtle along the z-axis to a specified coordinate, optionally allowing the turtle to dig if it needs to
    local function moveToZ(z, canDig, direction)
        if location.z == z then
            return true
        end

        direction = direction or "forward"

        if location.z < z then
            if direction == "back" then
                instance.turnTo("-z")
            else
                instance.turnTo("z")
            end

            return instance.forward(z - location.z, canDig)
        elseif location.z > z then
            if direction == "back" then
                instance.turnTo("z")
            else
                instance.turnTo("-z")
            end

            return instance.forward(location.z - z, canDig)
        end

        return false
    end

    -- Explicitly move the turtle along the x-axis to a specified coordinate, optionally allowing the turtle to dig if it needs to
    local function moveToX(x, canDig, direction)
        if location.x == x then
            return true
        end

        direction = direction or "forward"

        if location.x < x then
            if direction == "back" then
                instance.turnTo("-x") -- we need to increase on x-axis, but we're going backwards so we should be facing negative x
            else
                instance.turnTo("x") -- we need to increase on x-axis, and we're moving forwards so we should be facing positive x
            end

            return instance[direction](x - location.x, canDig)
        elseif location.x > x then
            if direction == "back" then
                instance.turnTo("x") -- we need to decrease on x-axis, but we're going backwards so we should be facing positive x
            else
                instance.turnTo("-x") -- we need to decrease on x-axis, and we're moving forwards so we should be facing negative x
            end

            return instance[direction](location.x - x, canDig)
        end

        return false
    end

    -- Explicitly move the turtle along the y-axis to a specified coordinate, optionally allowing the turtle to dig if it needs to
    local function moveToY(y, canDig)
        if instance.y == y then
            return true
        end

        if instance.y < y then
            return instance.up(y - instance.y, canDig)
        elseif instance.y > y then
            return instance.down(instance.y - y, canDig)
        end

        return false
    end

    -- Move the turtle to a specific location, providing exact coordinates, optionally allowing the turtle to dig if it needs to, and optionally specifying the axis order in which it moves
    function instance.moveTo(location, options)
        if not options.order then
            options.order = "yxz"  -- Default movement order
        end

        if string.len(options.order) ~= 3 then
            error("invalid order length")
        end

        -- Create a mapping for the coordinates
        local coords = {
            x = location.x,
            y = location.y,
            z = location.z
        }

        for i = 1, #options.order do
            local char = options.order:sub(i, i)
            local success

            if char == "x" then
                success = moveToX(coords[char], options.canDig, options.direction)
            elseif char == "y" then
                success = moveToY(coords[char], options.canDig, options.direction)
            elseif char == "z" then
                success = moveToZ(coords[char], options.canDig, options.direction)
            end

            if not success then
                return false
            end
        end

        return instance.turnTo(location.f)
    end

    -- Move the turtle to home
    function instance.home(order, canDig)
        instance.moveTo(home, {
            order = order,
            canDig = canDig
        })
    end


    --- ===============================================================
    --- ROTATION METHODS
    --- ===============================================================

    -- Rotates the turtle 90 degrees to the left
    function instance.turnLeft()
        if turtle.turnLeft() then
            location.f = location.f == 1 and 4 or location.f - 1
            os.queueEvent("location_updated")
            return true
        end

        return false
    end

    -- Rotates the turtle 90 degrees to the right
    function instance.turnRight()
        if turtle.turnRight() then
            location.f = location.f == 4 and 1 or location.f + 1
            os.queueEvent("location_updated")
            return true
        end

        return false
    end

    -- Rotates the turtle 180 degrees
    function instance.turnAround()
        turtle.turnLeft()
        location.f = location.f == 1 and 4 or location.f - 1 
        turtle.turnLeft()
        location.f = location.f == 1 and 4 or location.f - 1
        os.queueEvent("location_updated")

        return true
    end

    -- Rotate the turtle to a specified direction
    function instance.turnTo(n)
        -- for both relative and cardinal directions, these axis always map to correct values
        if type(n) == "string" then
            if n == "x" then
                n = 2
            elseif n == "-x" then
                n = 4
            elseif n == "-z" then
                n = 1
            elseif n == "z" then
                n = 3
            else
                error("Invalid direction string. Must be x, -x, z, or -z")
            end
        end

        if type(n) ~= "number" then
            error("Invalid arguments. n must be a number")
        end

        -- if the calculated face is the same face the turtle is facing, just return
        if n == location.f then
            return false
        end

        local diff = location.f - n

        while n ~= location.f do
            if diff == 1 or diff == -3 then
                turtle.turnLeft()
                location.f = location.f == 1 and 4 or location.f - 1
            else
                turtle.turnRight()
                location.f = location.f == 4 and 1 or location.f + 1
            end
        end

        os.queueEvent("location_updated")

        return true
    end

    return instance
end

return Aware