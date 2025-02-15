-- Mining program to efficiently branch mine entire GT styled ore deposits

-- prompt for user input parameters [branchCount, branchLength, branchGap, floorGap, minY, maxY, startX, startY, startZ]

-- calculate fuel needed to complete task
-- consume necessary fuel amounts exists in turtle slots
-- prompt user to continue if not enough fuel in turtle

-- save home location to current location, and facing direction



-- main loop operation
----------------------

-- set target target y level to minY param
-- descend to target y level
-- face right
-- branch mine by digging and moving into the front in front, and if branchGap is 0, check only the block below for a block of interest to possibly mine
-- -- repeat above for the length of the branchLength - 1 (because we started on block 1)
-- -- at the end of the branch, for odd branches, turn right, even branches turn left
-- -- move forward and dig branchGap + 1 spaces
-- -- for odd branches, turn left, for even branches turn right
-- -- repeat branch mine process

-- data collection
-----------------------

-- after every turtle turn, update the facing direction of the turtle position for tracking
-- after every turtle movement, updating the xyz position of the turtle for tracking


-- Position update actions
-- after every position update, insert a new record into the list of points we are tracking


-- Branch mine specifics
---------------------------

-- after completion of an even branch, delete the position record insertions for the last 2 branches
-- because they are not necessary for us to keep in order to path find back to the shaft

write("Miner initializing")
textutils.slowPrint("...", 5)

local Miner = require("Miner")
local miner = Miner.create()

local branchCount = 6
local branchLength = 15
local branchGap = 0
local startY = 104
local minY = 24
local maxY = 29
local floorGap = 1

-- to to perform a pitstop we will iterate backwards through the checkouts
-- we will first update the facing direction, and then we will execute a backwards movement

function main()
    -- move down to the min y level to start branch mining
    miner.moveTo({
        x = 0,
        y = minY - startY, -- moving to absolute y from relative y
        z = 0,
        f = 1
    }, {
        canDig = true
    })

    -- add a checkpoint at the bottom of the shaft
    miner.addCheckpoint()

    local keepGoing = true

    -- mine out all floors
    while keepGoing do
        -- execute branches on current y level
        for i = 1, branchCount do
            local isEvenBranch = i % 2 == 0

            -- face the branch
            if isEvenBranch then
                miner.turnLeft()
            else
                miner.turnRight()
            end

            -- add checkpoint before starting the branch
            miner.addCheckpoint()

            -- each block of the branch will check a checkpoint after it completes
            miner.branchMine({
                branchLength = branchLength,
                shouldCheckUp = false,
                shouldCheckLeft = false,
                shouldCheckRight = false
            })

            -- move across the z axis to prepare for the next branch
            if i < branchCount then
                miner.turnTo(1)
                miner.addCheckpoint()

                for _ = 1, branchGap + 1 do
                    miner.dig()
                    miner.move()
                    miner.addCheckpoint()
                end
            end

            -- how many checkpoints in a branch process?
            -- 1 for facing at the start the branch
            -- 1 for each block in the branch
            -- 1 for the turn at the end of the branch
            -- 1 for each (branchGap + 1)
            -- remove the last 2 branches worth of checkpoints
            if isEvenBranch then
                miner.removeCheckpoints(2 + (2 * branchLength) + 2 + 2)
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
            canDig = false
        })

        -- next potential y level to mine out
        local nextY = startY + miner.getLocation().y + floorGap + 1

        -- are we at beyond the starting y?
        if nextY >= startY or nextY > maxY then
            keepGoing = false

            -- delete all checkpoints except the first one?
            miner.resetCheckpoints()
            -- save a checkpoint for the start of the next floor
            miner.addCheckpoint()
        else
            -- move up n number of blocks
            miner.moveTo({
                x = 0,
                y = nextY - startY,
                z = 0,
                f = 1
            }, {
                canDig = false
            })
        end
    end

    -- finished!
    miner.home()
end

function listen()
    while true do
        local event, location = os.pullEvent()

        if event == "location_updated" then
            print("Rel Location  : " .. textutils.serialize(location))
            print("Actual Y : " .. startY + location.y)
        end
    end
end

parallel.waitForAny(main, listen)