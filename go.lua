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

local Miner = require("Miner")
local miner = Miner.create()

local branchCount = 6
local branchLength = 15
local branchGap = 2
local minY = -48
local maxY = 32

-- how many do we have for an odd branch from the north facing position at the start of a branch?
-- 1 for facing right before starting the branch
-- 1 for each block in the branch
-- 1 for the left turn at the end of the branch
-- 1 for each (branchGap + 1)
-- 1 + 15 + 1 + 1

-- how many for an even branch?
-- 1 for facing left before starting the branch
-- 1 for each block in the branch
-- 1 for the right turn at the end of the branch
-- 1 for each (branchGap + 1)
-- 1 + 15 + 1 + 1

-- so we remove 36 checkpoints after completing an even branch

-- to to perform a pitstop we will iterate backwards through the checkouts
-- we will first update the facing direction, and then we will execute a backwards movement

function main()
    miner.moveTo(0, minY, 0, 1)
    miner.addCheckpoint()

    while true do
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

            miner.branchMine({
                branchLength = branchLength,
                shouldCheckUp = false,
                shouldCheckLeft = false,
                shouldCheckRight = false
            })

            -- get in position for the next branch
            if i < branchCount then
                miner.turnTo(1)
                miner.addCheckpoint()

                for _ = 1, branchGap + 1 do
                    miner.dig()
                    miner:move()
                    miner.addCheckpoint()
                end
            end
        end
    end
end