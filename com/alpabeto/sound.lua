-----------------------------------------------------------------------------------------
--
-- sound.lua
--
-----------------------------------------------------------------------------------------

local M = {
    MATCHED_SOUND = audio.loadSound('sounds/Super Simple Button.mp3'),
    WRONG_SOUND = audio.loadSound('sounds/Oops App Sound.mp3'),
    LEVELUP_SOUND = audio.loadSound('sounds/Magical Game Sound.mp3'),
    POP_SOUNDS = {
                    audio.loadSound('sounds/pop1.wav'),
                    audio.loadSound('sounds/pop2.wav'),
                    audio.loadSound('sounds/pop3.wav'),
                    audio.loadSound('sounds/pop4.wav'),
    },
    WIN_SOUND_PERFECT = audio.loadSound('sounds/Positive Game Win 1.wav'),
    WIN_SOUND = audio.loadSound('sounds/Positive Game Win 2.wav'),

    BG_MUSIC_INTRO = audio.loadStream('music/intro.mp3'), -- FINAL CHOICE (part of http://audiojungle.net/item/children-fun-pack/7640011)
    CHANNEL_INTRO = 1,
    BG_MUSIC_LEVEL = audio.loadStream('music/level.mp3'), -- FINAL CHOICE
    CHANNEL_LEVEL = 2,
    BG_MUSIC_FINISH = audio.loadStream('music/finish.mp3'), -- FINAL CHOICE (part of http://audiojungle.net/item/children-fun-pack/7640011)
    CHANNEL_FINISH = 3,
}

-- type is 1 to 4
function M.pop(type)
    if type == nil then
        audio.play(M.POP_SOUNDS[math.random(#M.POP_SOUNDS)])
    else
        audio.play(M.POP_SOUNDS[type])
    end
end

M.WHOOSH_SOUNDS = {
    audio.loadSound('sounds/Bamboo Button Click 1.mp3'),
    audio.loadSound('sounds/Bamboo Button Click 2.mp3'),
}

return M