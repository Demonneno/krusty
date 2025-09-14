package.path = package.path .. ";./?.lua;./lib/?.lua"
local Background = require("background")
local Player = require ("player")
local Platforms = require ("platforms")
local Sounds = require("sounds")

-- To help reduce redundancies when initiating random()
math.randomseed(os.time())
math.random(); math.random(); math.random()

-- Constants
local WINDOW_WIDTH, WINDOW_HEIGHT = 800, 600

-- Local variables within functions that are needed for other functions
local platforms,  font, highScore

-- tracks a high score into a local file
-- Borrowed logic from How to LÖVE
local function loadHighScore()
    if love.filesystem.getInfo("score.txt") then  -- Check if the file exists
        local content = love.filesystem.read("score.txt")
        return tonumber(content) or 0 -- Convert to number or return 0 if file is empty or not number
    else
        return 0  -- Return 0 if file does not exist
    end
end

-- Writes a new high score into file
-- Borrowed logic from How to LÖVE
local function saveHighScore(score)
    local file = love.filesystem.newFile("score.txt")
    file:open("w")  -- 'w' for write mode
    file:write(tostring(score))
    file:close()
end

function love.load()
    -- A simplistic take on entities vs How to LÖVE's class
    -- Informative videos on YouTube from @DevJeeper
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    Background:load()
    Platforms:load()
    Player:load()
    -- print("Player in update:", Player)

    Sounds:load()

    -- Stock font
    font = love.graphics.newFont(16)

    -- Custom font
    Player.score = 0

    -- make sure sprites don't look fuzzy due to scaling
    Player.spriteSheet:setFilter("nearest", "nearest")
    Platforms.tilesetImage:setFilter("nearest", "nearest")
    Background.backgroundImage:setFilter("nearest", "nearest")

    -- Returns new platforms based on the function on load
    platforms = Platforms.createPlatforms(40, 64, 192, 30)  -- (numPlatforms, minWidth, maxWidth, minGap)
end

-- Keys to control game and reset player
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit(0)
    elseif Player.isDead == true then
        if key == 'r' then
            -- Reset the game
            Player.alive = true
            Player.yVelocity = 0
            Player.score = 0
            Player.lives = 3
            Player.x = 400
            Player.y = 100
            Player.isDead = false
        end
    elseif Player.isDead == false then
        if key == 'r' then
            love.load()
        end
    end
end

-- This runs our continuously updated game data
function love.update(dt)
    -- Import files
    Platforms:update(dt, platforms, Player)
    Player:update(Player, dt, platforms)
    Sounds:update()  -- Manage sound sequence

    -- Updating the shake effect outside of platforms seems smoother
    Platforms.updateShake(dt)

    -- Update animations
    if Background.bgAnimation then
        Background.bgAnimation:update(dt)
        -- A timer condition check to pause animations and reset animation frame
        if Background.bgAnimationRunning and love.timer.getTime() >= Background.bgAnimationStopTime then
            Background.bgAnimation:pause()
            Background.bgAnimation:gotoFrame(1)
            Background.bgAnimationRunning = false
            -- print("Animation has ended.")
        end
    end

    -- Setting a new high score and duplicating player's current live score to high score
    if Player.score > loadHighScore() then
        saveHighScore(Player.score)
        highScore = Player.score
    end

    -- Keep player on screen horizontally
    Player.x = math.max(0, math.min(Player.x, love.graphics.getWidth() - Player.width))
end

highScore = loadHighScore()

function love.draw()it's a
    -- static objects (no screen shake)
    love.graphics.push()
    Background.bgAnimation:draw(Background.backgroundImage, 0, 0)


    -- UI with lives in upper left corner
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.print("Lives: " .. math.max(Player.lives, 0), 10, 10)
    love.graphics.print("Score: " .. Player.score, 100, 10)
    love.graphics.print("High Score: " .. highScore, 300, 10)

    -- UI with button info
    love.graphics.printf(" Left: A or Left Arrow\n Right: D or Right Arrow\n Jump: Space Bar\n Exit: Esc\n Restart: R", 600, 10, 400, 'left')

    love.graphics.pop()
    -- begin screenshake objects
    love.graphics.push()
    Platforms:draw(platforms)

    -- Reset colors so platform color change doesn't affect other objects
    love.graphics.setColor(1, 1, 1)

    love.graphics.pop()
    -- Make sure player's drawn on top of all objects
    Player:draw()
end
