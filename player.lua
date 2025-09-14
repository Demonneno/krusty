local anim8 = require("libraries.anim8.anim8")
local Platforms = require ("platforms")
local Sounds = require ("sounds")
local Player = {}

local jump, introSound

-- Krusty is IN THE HOUSE!
local function krustyIntro()
    if not introSound:isPlaying() then
        love.audio.play(introSound)
    end
end

-- Load player data
function Player:load()
    -- Player stats
    self.x = 100
    self.y = 100
    self.width = 24
    self.height = 32
    self.speed = 270
    self.gravity = 600
    self.feetOffset = 5
    self.maxFallSpeed = 500

    -- Lives and Scores
    self.lives = 3
    self.score = 0
    self.timeElapsed = 0

    -- Physics and Animation
    self.jumpSpeed = -425
    self.yVelocity = 0
    self.grounded = false
    self.isDead = false
    self.spriteSheet = love.graphics.newImage('assets/player/clown.png')
    self.animation = {current = 'idle', idle = nil, left = nil, right = nil, jump = nil}

    -- Animation Sheets
    local g = anim8.newGrid(self.width, self.height, self.spriteSheet:getWidth(), self.spriteSheet:getHeight(), 0, 0, 1)
    self.animation.jumpPaused = false
    self.jumpPauseFrame = 3
    self.timeSinceLastAnimationFrame = 0
    self.animation.idle = anim8.newAnimation(g('1-6', 3), 0.1)
    self.animation.left = anim8.newAnimation(g('1-7', 1), 0.1)
    self.animation.right = anim8.newAnimation(g('7-1', 1), 0.1)
    self.animation.jump = anim8.newAnimation(g('1-4', 2), 0.2)

    -- Fonts and UI
    self.customFont = love.graphics.newFont("assets/font/Simpson/Simpsonfont.ttf", 32)

    -- Audio
    jump = love.audio.newSource("assets/sounds/krusty/jump.wav", "static")
    jump:setVolume(0.5)

    introSound = love.audio.newSource("assets/sounds/krusty/intro.wav", "static")
    krustyIntro()
end

-- Sound changes for platforms

Player.isSoundSequencePlaying = false

function Player:playPlatformChangeSounds()
    if not self.isDead then -- Assuming you have a boolean `isDead` on your player object
        if not self.isSoundSequencePlaying then
            love.audio.play(Sounds.switchSound)
            self.isSoundSequencePlaying = true
        end
    else
        -- Optionally, if you want to ensure sounds stop or reset when the player dies:
        if self.isSoundSequencePlaying then
            love.audio.stop(Sounds.switchSound)
            self.isSoundSequencePlaying = false
        end
    end
end


-- Checks if Krusty's jump sound is playing and triggers if not
local function krustyJump()
    if not jump:isPlaying() then
        love.audio.play(jump)
    end
end

-- Assign current Animation
function Player:setAnimation(animationName)
    if self.animation.current ~= animationName then
        self.animation.current = animationName
        self.currentAnim = self.animation[animationName]
        if animationName == 'idle' or animationName == 'jump' then
            self.currentAnim:gotoFrame(1)
        end
    end
end

-- This makes sure that collision is detected with a visible platform and that the player
-- offset helps make the player look like they're walking on the cloud instead of above it
function Player:Grounded(platforms, feetOffset, maxFallSpeed, dt)
    for _, platform in ipairs(platforms) do
        if platform.visible and Platforms.rectanglesOverlap(self.x, self.y, self.width, self.height, platform.x, platform.y,
            platform.width, platform.height) then
            if self.yVelocity > 0 then
                self.y = platform.y - self.height + self.feetOffset -- Add an offset here
                self.yVelocity = math.min(self.yVelocity + self.gravity * dt, self.maxFallSpeed)
                self.grounded = true
            end
        end
    end
end

-- Animation function
function Player:jump()
    self:setAnimation('jump')
    -- print("Jump frame after setAnimation:", self.animation.jump and self.animation.jump:frame() or "nil")
end

-- After player dies, reset
function Player:resetPlayer()
    self.x = 400
    self.y = 50
    self.yVelocity = 0
    self.gravity = 400
    self.grounded = false
    self.isDead = false
    self:setAnimation('idle')  -- Reset to idle animation
end

function Player:dies(playerDies, dt)
    -- Check if player has fallen off the screen and count deaths
    if self.y > love.graphics.getHeight() and not self.isDead then
        self.isDead = true
        self.lives = self.lives - 1
        if self.lives > 0 then
            self:resetPlayer()
            -- print("Player died. Lives left: " .. self.lives)
        else
            Sounds:playerDies()
            -- print("Game Over!")
        end
    -- Only reset gravity back to 600 when grounded to make player fall a little
    -- slower upon respawn. Deduct a second for the respawn time lapse
    elseif self.y <= love.graphics.getHeight() then
        self.isDead = false
        if self.grounded then
            self.gravity = 600
        end
        self.timeElapsed = self.timeElapsed + dt
        if self.timeElapsed >= 1 then
            self.score = self.score + 1
            self.timeElapsed = self.timeElapsed - 1
        end
    end
end

function Player:update(Player, dt, platforms)
    -- Physics update
    self.yVelocity = self.yVelocity + self.gravity * dt
    self.y = self.y + self.yVelocity * dt
    self.grounded = false

    -- Player movement and animation control
    local movingRight, movingLeft = love.keyboard.isDown('d', 'right'), love.keyboard.isDown('a', 'left')

    -- Player movement logic
    if movingRight then
        self.x = self.x + self.speed * dt
    elseif movingLeft then
        self.x = self.x - self.speed * dt
    end

    -- Player is falling or has landed
    if self.yVelocity >= 0 then
        self:Grounded(platforms, self.feetOffset, self.maxFallSpeed, dt)
    end

    --  Check Player:dies function in update
    self:dies(playerDies, dt)

    -- Jump and animation logic
    if love.keyboard.isDown('space') and self.grounded then
        krustyJump()
        self.yVelocity = self.jumpSpeed
        self:setAnimation('jump')
    elseif self.grounded then
        if movingRight then
            self:setAnimation('right')
        elseif movingLeft then
            self:setAnimation('left')
        else
            self:setAnimation('idle')
        end
    else
        -- Handle falling or other mid-air states if needed
        if self.animation.current ~= 'jump' then
            self:setAnimation('idle')
        end
    end

    -- Update animations after movement and jump logic
    if self.animation[self.animation.current] then
        self.animation[self.animation.current]:update(dt)
    end

    -- Handle jump pause if needed
    if self.animation.current == 'jump' and not self.animation.jumpPaused and self.animation.jump.frame == self.jumpPauseFrame then
        self.animation.jumpPaused = true
        self.animation.jump:pause()
    elseif self.animation.current == 'jump' and self.animation.jumpPaused and self.yVelocity > 0 then
        self.animation.jumpPaused = false
        self.animation.jump:resume()
    end
end

function Player:draw()

    -- Character sprite reverse logic when walking left
    local scaleX = 2
    if self.animation.current == 'left' or (self.animation.current == 'jump' and love.keyboard.isDown('a', 'left')) then
        scaleX = -2
    end

    -- Draw the current animation
    local currentAnim = self.animation[self.animation.current]

    if self.isDead == false then
        if currentAnim then
            currentAnim:draw(self.spriteSheet, self.x, self.y, 0, scaleX, 2, self.width/2, self.height/2)
        else
            love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
        end
    -- Playe is dead overlay text
    elseif self.isDead == true then
        love.graphics.setFont(self.customFont)
        love.graphics.print("Player Dead", love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2 - 20)
        love.graphics.print("Press 'R' to Restart", love.graphics.getWidth()/2 - 150, love.graphics.getHeight()/2 + 20)

    end

end

return Player


