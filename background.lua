local anim8 = require("libraries.anim8.anim8")
Background = {}

-- Load images and animatons
function Background:load()
    -- Assume gBackground is your tile sheet
    self.frameDuration = 0.1  -- Example duration
    self.frameWidth, self.frameHeight = 801, 601
    self.backgroundImage = love.graphics.newImage('assets/background/background.png')

    -- Using anim8 to animate image quads.
    self.gBackground = anim8.newGrid(self.frameWidth, self.frameHeight, self.backgroundImage:getWidth(),
                    self.backgroundImage:getHeight())
    -- Anim8 cycles through 5 images in 2 rows
    self.bgAnimation = anim8.newAnimation(self.gBackground('1-3',1, '1-2',2), .1)
    self.bgAnimation:pause()
    self.bgAnimationRunning = false
    self.bgAnimationStopTime = 0
    self.bgAnimation:pause()
end

-- Helper animation function
function Background:startAnimation()
    if self.bgAnimation then
        self.bgAnimation:resume()
        self.bgAnimationRunning = true
        self.bgAnimationStopTime = love.timer.getTime() * 1.1 + self.bgAnimation.totalDuration
    else
        print("bgAnimation is nil in startAnimation.")
    end
end

-- Helper animation function
function Background:stopAnimation()
    if self.bgAnimation then
        self.bgAnimation:pause()
        self.bgAnimation:gotoFrame(1)  -- Reset to first frame
        self.bgAnimationRunning = false
    else
        print("bgAnimation is nil in stopAnimation.")
    end
end

-- Helper animation function
function Background:update(dt)
    if self.bgAnimationRunning then
        self.bgAnimation:update(dt)
        if love.timer.getTime() >= self.bgAnimationStopTime then
            self:stopAnimation()
        end
    end
end

-- Helper animation function
function Background:draw()
    if self.bgAnimation then
        self.bgAnimation:draw()
    end
end

return Background
