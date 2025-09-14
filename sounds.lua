Sounds = {}

-- Homer sounds
Sounds.switchSound = love.audio.newSource("assets/sounds/homer/stomach.wav", "static")

-- Sounds list used by the playPlatformChangeSounds function after switchSound
Sounds.randomSounds = {
    love.audio.newSource("assets/sounds/homer/belly.wav", "static"),
    love.audio.newSource("assets/sounds/homer/dont_hate.wav",  "static"),
    love.audio.newSource("assets/sounds/homer/giant_donuts.wav", "static"),
    love.audio.newSource("assets/sounds/homer/lighter_than_air.wav", "static"),
    love.audio.newSource("assets/sounds/homer/parachute_love.wav", "static"),
    love.audio.newSource("assets/sounds/homer/regular_sized_bites.wav", "static"),
    love.audio.newSource("assets/sounds/homer/spicy_meatball.wav", "static"),
    love.audio.newSource("assets/sounds/homer/super_meatball.wav", "static")
}

local isSoundSequencePlaying = false

function Sounds:playPlatformChangeSounds(e)
    -- In platforms.lua, this is called to play
    if not e.isDead then
        if not isSoundSequencePlaying then
            love.audio.play(self.switchSound)
            isSoundSequencePlaying = true
        end
    else
        -- After player.isDead returns true, stop the sounds
        if isSoundSequencePlaying then
            love.audio.stop(self.switchSound)
            isSoundSequencePlaying = false
        end
    end
end

-- Death sounds are actually Homer talking to Krusty
local soundDirectory = "assets/sounds/krusty/"
local deathSoundFilenames = {"dead1.wav", "dead2.wav", "dead3.wav", "dead4.wav"}
local deathSounds = {}

-- Creates a list of Death Sounds that playRandomDeathSound loads into playerDies
function Sounds:createDeathSounds()
    for i, filename in ipairs(deathSoundFilenames) do
        -- Concatenates a filename for deathSounds table. I wanted to try something
        -- different with these
        local fullPath = soundDirectory .. filename
        deathSounds[i] = love.audio.newSource(fullPath, "static")
    end
end

local currentSoundIndex = 0
function Sounds:playRandomDeathSound()
    -- Check if sounds loaded properly else quit
    if #deathSounds == 0 then return end
    -- initialize a new variable
    local newIndex
    repeat
        -- Loop through the list
        newIndex = love.math.random(1, #deathSounds)
    until newIndex ~= currentSoundIndex

    currentSoundIndex = newIndex
    love.audio.play(deathSounds[currentSoundIndex])
end

-- Helper function to be used in other sheets
function Sounds:playerDies()
    self:playRandomDeathSound()
end

-- Initializes the Sounds file into main
function Sounds:load()
    self:createDeathSounds()

    self.bgMusic = love.audio.newSource( 'assets/sounds/song/Homers_Charge.mp3', 'stream' )
    self.bgMusic:setLooping( true ) --so it doesnt stop
    self.bgMusic:play()
    self.bgMusic:setVolume(0.3)
end

-- Passes the sounds check loop into main update
function Sounds:update(dt)
    -- Checks if switchSound is playing and plays random Homer sounds after
    if isSoundSequencePlaying and not self.switchSound:isPlaying() then
        local randomSound = Sounds.randomSounds[love.math.random(1, #Sounds.randomSounds)]
        love.audio.play(randomSound)
        isSoundSequencePlaying = false
    end
end

return Sounds
