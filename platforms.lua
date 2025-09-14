local anim8 = require("libraries.anim8.anim8")
local Platforms = {}
local background = require("background")
Sounds = require("sounds")

-- Screen
local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()

-- Loading the clouds aka tilesetImage for the platforms
function Platforms:load()
    -- Platform dimensions
    self.tilesetImage = love.graphics.newImage('assets/platform/cloud.png')
    self.tileWidth = 32 -- Example width, adjust based on your tileset
    self.tileHeight = 32 -- Example height, adjust based on your tileset
    self.imageWidth = self.tilesetImage:getWidth()
    self.imageHeight = self.tilesetImage:getHeight()
    self.gPlatform = anim8.newGrid(self.tileWidth, self.tileHeight, self.imageWidth, self.imageHeight, 0, 0, 1)

    -- Platform tile positions in sheet
    self.tilePositions = {
        left = 2,
        middle = 3,
        right = 4
    }
end

-- Checks for platforms overlapping each other. It's what How to LÖVE taught us to
-- use as a simple collision system. In this case, I'm checking where clouds are being
-- created with the createPlatforms function
function Platforms.rectanglesOverlap(x1, y1, w1, h1, x2, y2, w2, h2)
    if x1 + w1 > x2 and x1 < x2 + w2 and y1 + h1 > y2 and y1 < y2 + h2 then
        return true
    end
    return false
end

-- This started off a lot simpler and I'm not going to lie, there is a decent bit of help from
-- Grok on this one to use the random creation. This creates my platforms or clouds and are
-- built through main's load. In main, this is referenced by "platforms" which then passes the
-- size ranges for this function to work within the boundaries therein.
function Platforms.createPlatforms(numPlatforms, minWidth, maxWidth, minGap)
    local platforms = {}
    local bottomHalf = screenHeight / 2

    -- This loop randomly seeds different width platforms that work a min of 64 pixels (32pixels for the
    -- left side of the cloud and 32 for the right at the least). This also works in increments of
    -- 32 to make sure the clouds aren't clipping the images.
    -- Every now and then, I get a random clipped image and I just can't figure out why. I'll keep
    -- Debugging but with nearly a month of building this game, I've decided it's best to move forward
    -- with submitting.
    for i = 1, numPlatforms do
        local width = math.max(minWidth, math.ceil(love.math.random(minWidth, maxWidth) / 64) * 64)
        local height = 32

        -- logic here is to check if a new platform does overlap an old one. If so, the idea would be
        -- to make one of the two (randomly selected) invisible. This would be handled in other code.
        local function doesOverlap(newX, newY, newWidth)
            for _, platform in ipairs(platforms) do
                if Platforms.rectanglesOverlap(newX, newY, newWidth, height, platform.x, platform.y, platform.width, platform.height) then
                    return platform -- Return the overlapping platform instead of just true
                end
            end
            return false
        end

        -- This is my loop limit for trying to make things work nicely with each other. Otherwise
        -- I'd get a delayed white screen on startup.
        local maxAttempts = 200
        local attempt = 0
        local x, y, overlappingPlatform

        -- Keep trying to make things work neatly within the screen. This seems to work against me
        -- But it's the only soluation I could come up with for the time being. Here, we're storing
        -- an overlapping boolean (true/false) based on the repeat function and adding to the attempt
        -- counter until successful or max is reached.
        repeat
            x = love.math.random(0, screenWidth - width)
            y = love.math.random(bottomHalf - 150, screenHeight - height)
            overlappingPlatform = doesOverlap(x, y, width)
            attempt = attempt + 1
        until not overlappingPlatform or attempt >= maxAttempts

        -- This is my other attempt to contain the overlapping platforms. In this, I'm attempting to
        -- create a system where the overlapping platforms will merge into one, taking on the size of
        -- either the bigger one or limiting itself to the left edge of one to the right edge of the
        -- other
        if attempt < maxAttempts then
            if overlappingPlatform then
                -- Merge Platforms
                local newWidth = math.max(overlappingPlatform.width, x + width - overlappingPlatform.x)
                -- Assigns a new width based on the marge and modifies the x of the leftmost position
                -- of either the new or old platform
                -- This took a lot of searching to figure out how to make this work. Love's documentation
                -- doesn't cover the lua functions and it gets confusing which is which at times...
                overlappingPlatform.width = newWidth
                overlappingPlatform.x = math.min(overlappingPlatform.x, x)
                -- Then I remmeber Love's math is literally love.math!  Phew. I added this to debug, but
                -- it didn't seem to matter enough to remove it. So here it lives.
                overlappingPlatform.color = {love.math.random(), love.math.random(), love.math.random()} -- Optionally change color when merging
            else
                -- This builds my platforms table. The toggle interval shouldn't be incorporated,
                -- but the idea was to actually toggle the predetermined platforms. This created a
                -- lot of problems that i'll revisit once I have more time. For now, it just exists.
                table.insert(platforms, {
                    x = x,
                    y = y,
                    width = width,
                    height = height,
                    color = {love.math.random(), love.math.random(), love.math.random()},
                    visible = true,
                    toggleInterval = love.math.random(1, 4)
                })
            end
        end
    end

    -- Sorting the platforms by x
    table.sort(platforms, function(a, b) return a.x < b.x end)

    -- Adjust positions to ensure minimum gap hence it starts at 2 to check a gap
    for i = 2, #platforms do
        platforms[i].x = math.max(platforms[i].x, platforms[i-1].x + platforms[i-1].width + minGap)
    end

    -- Return the table full of platforms
    return platforms
end

-- Shake effects expands on How to LOVE's method
Platforms.shakeMagnitude = 10
Platforms.shakeDuration = .75
Platforms.shakeTimer = Platforms.shakeDuration
Platforms.shakeDirection = 1
Platforms.screenShakeOffset = {x = 0, y = 0}

-- Shake clouds
function Platforms.startShake(duration, magnitude)
    Platforms.shakeDuration = duration
    Platforms.shakeMagnitude = magnitude
    Platforms.shakeTimer = 0
    Platforms.shakeDirection = Platforms.shakeDirection * -1
end

-- This is meant to create a less linear feeling to the shakes. Instead of not having control of
-- the intesity, i wanted to make the movements more erratic. A timer based on duration will keep
-- the effect more or less synchronized to the bgAnimation trigger`
function Platforms.updateShake(dt)
    if Platforms.shakeTimer < Platforms.shakeDuration then
        Platforms.shakeTimer = Platforms.shakeTimer + dt
        local progress = Platforms.shakeTimer / Platforms.shakeDuration

        -- Adding randomness with math.random for each axis
        local randomX = love.math.random(-1, 1)
        local randomY = love.math.random(-1, 1)

        -- Calculate shake with random component
        local shakeValue = Platforms.shakeMagnitude * math.sin(progress * math.pi * 4) * math.exp(-progress * 2)
        Platforms.screenShakeOffset.x = shakeValue * randomX
        Platforms.screenShakeOffset.y = shakeValue * randomY

        if Platforms.shakeTimer >= Platforms.shakeDuration then
            Platforms.screenShakeOffset.x = 0
            Platforms.screenShakeOffset.y = 0
            -- Reset Timer to the length of Duration for use as soon as the effect is completed
            Platforms.shakeTimer = Platforms.shakeDuration
        end
    end
end

-- Cloud animation and color variables
local colorChangeInterval = love.math.random(2, 9)
local timeSinceLastColorChange = 0
local timeSinceLastVisibilityChange = 0
local colorChangePreOffset = 0.5 -- for example, 0.5 seconds before visibility change
local currentlyVisiblePlatforms = {}

-- This section took me weeks to complete. This is a bit much for me and once again relied on Grok,
-- DevJeeper's videos, and the LOVE Wiki to try and piece this one together. The effects handled here
-- Are a trifecta of shakes, visibility, color changes, and triggers for audio and bgAnimation.
-- It's painful to look at in ways, but it was much harder for me to break the function apart and get
-- the results that I expected. Which wasn't expected at all!
function Platforms:update(dt, platforms, Player)
    -- Tracks last changes in delta time
    timeSinceLastColorChange = timeSinceLastColorChange + dt
    timeSinceLastVisibilityChange = timeSinceLastVisibilityChange + dt

        -- Color change logic here, independent of visibility change by the preOffset as a visual
        -- cue for the player
    if timeSinceLastColorChange > (colorChangeInterval - colorChangePreOffset) then
        timeSinceLastColorChange = 0
        -- borrowed some of my love.math.random to switch up colors on updates
        for _, platform in ipairs(platforms) do
            platform.color = {love.math.random(), love.math.random(), love.math.random()}
        end
    end

    -- The Random Color Change Interval doubles up as a random platform change interval as well.
    if timeSinceLastVisibilityChange > colorChangeInterval then
        timeSinceLastVisibilityChange = 0

        local visibleCount = 0
        local platformsToToggle = {}

        -- Determine visibility status without changing positions
        for _, platform in ipairs(platforms) do
            if platform.visible then
                -- Platform is visible, check if it should stay visible based on its position
                -- I have a lot of platforms drawing offscreen, likely due to the collisions, so
                -- this is my failsafe to try and avoid the game drawing nothing onscreen
                if platform.x + platform.width < 0 or platform.x > screenWidth or
                   platform.y + platform.height < 0 or platform.y > screenHeight then
                    platform.visible = false
                else
                    visibleCount = visibleCount + 1
                    table.insert(currentlyVisiblePlatforms, platform)
                end
            -- Platforms that aren't fully visible are allowed. This creates more room for platforms
            elseif platform.x >= -platform.width and platform.x < screenWidth and
                   platform.y >= 0 and platform.y < screenHeight then
                -- Platforms in the "toggleable" zone, not changing their position here
                table.insert(platformsToToggle, platform)
            end
        end

        -- Toggle visibility logic
        for _, platform in ipairs(platforms) do
            -- this should help it make it a bit more random to develop a platform
            if love.math.random() > 0.7 then
                if platform.visible then
                    platform.visible = false
                    visibleCount = visibleCount - 1
                elseif #platformsToToggle > 0 then
                    local index = love.math.random(1, #platformsToToggle)
                    platformsToToggle[index].visible = true
                    visibleCount = visibleCount + 1
                    table.remove(platformsToToggle, index)
                end
            end
        end

        -- Ensure at least one platform is visible
        if visibleCount == 0 and #platforms > 0 then
            local randomIndex = love.math.random(1, #platforms)
            platforms[randomIndex].visible = true
            visibleCount = 1
        end

        print("Visible platforms after toggle:", visibleCount)
        -- Reintroduce shake effect and sound
        if visibleCount > 0 then
            -- Assuming Sounds:playPlatformChangeSounds is a function to play sounds related to platform changes
            Sounds:playPlatformChangeSounds(Player)
        end

        -- Start or update the shake effect
        self.startShake(self.shakeDuration, self.shakeMagnitude)

        for _, platform in ipairs(platforms) do
            if platform.visible or (platform.x > screenWidth - platform.width or platform.x < 0 or platform.y < 0 or platform.y > screenHeight) then
                print(string.format("Platform at X: %d, Y: %d, Width: %d, Height: %d, Visible: %s",
                    platform.x, platform.y, platform.width, platform.height, tostring(platform.visible)))
            end
        end

        -- Reset for the next cycle
        colorChangeInterval = love.math.random(3, 12)

        -- Trigger background animation
        if background.bgAnimation and not background.bgAnimationRunning then
            background.bgAnimation:resume()
            background.bgAnimationRunning = true
            background.bgAnimationStopTime = love.timer.getTime() * 1.1 + background.bgAnimation.totalDuration
        end
    end
end

function Platforms:draw(platforms)
    -- Apply shake
    love.graphics.translate(Platforms.screenShakeOffset.x, Platforms.screenShakeOffset.y)
    -- Image scale variable
    local scaleFactor = 2

    -- helper to try and pixel align images. I found this online in a Love2D forum to try and overcome the
    -- random borders visibly poking through animations
    function self.snapToPixel(pos)
        return math.floor(pos + 0.5)
    end

    -- loops through my visible platforms to assign colors and images
    for _, platform in ipairs(platforms) do
        if platform.visible then
            love.graphics.setColor(platform.color)

            -- Checks if a middle tile can fit between a left/right tile
            local middleTiles = math.floor((platform.width - 2 * self.tileWidth * scaleFactor) / (self.tileWidth * scaleFactor))
            -- Attempts to prevent tile borders from showing with screenshake
            local currentX, currentY = self.snapToPixel(platform.x + Platforms.screenShakeOffset.x), self.snapToPixel(platform.y + Platforms.screenShakeOffset.y)

            -- Draws a tile and tracks the end of it for the next tile
            local function drawTile(quad)
                love.graphics.draw(self.tilesetImage, quad, currentX, currentY, 0, scaleFactor, scaleFactor)
                currentX = currentX + self.tileWidth * scaleFactor
            end

            -- Draw tiles using anim8
            drawTile(self.gPlatform(self.tilePositions.left, 1)[1])
            for _ = 1, middleTiles do
                drawTile(self.gPlatform(self.tilePositions.middle, 1)[1])
            end
            if middleTiles >= 0 then
                drawTile(self.gPlatform(self.tilePositions.right, 1)[1])
            end
        end
    end
end

return Platforms
