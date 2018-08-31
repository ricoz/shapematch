-----------------------------------------------------------------------------------------
--
-- helper.lua
--
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- CONSTANTS
-----------------------------------------------------------------------------------------

local base_score = 10

local json = require 'json'

local M = {
    -- set to false when building for release
    DEBUG = false,

    BASE_WIDTH = 320,
    BASE_HEIGHT = 480,
    CONTENT_WIDTH = display.actualContentWidth,
    CONTENT_HEIGHT = display.actualContentHeight,
    SMALL_FACTOR = .75,
    TIME_FACTOR = 1000, -- set to 250 for faster testing

    touch_enabled = true,

    -- TODO: rename to something more appropriate
    current_level = 1,

    levels = {
        1, 2,  7,  8, 13, 14,
        3, 4,  9, 10, 15, 16,
        5, 6, 11, 12, 17, 18,
    },

    level_targets = {
        1, 1, 4, 4, 7, 7,
        2, 2, 5, 5, 8, 8,
        3, 3, 6, 6, 9, 9,
    },

    score = 0,
}



function M.p(...)
    if M.DEBUG then
        print(unpack(arg))
    end
end



function M.get_file(filename, base)
    if not base then base = system.ResourceDirectory; end
    local path = system.pathForFile(filename, base)
    local contents
    local file = io.open(path, 'r')
    if file then
       contents = file:read('*a')
       io.close(file) -- close the file after using it
    else
        assert(filename .. ' not found')
    end
    return contents
end

local function get_user_settings()
    local base = system.DocumentsDirectory
    local path = system.pathForFile('settings.json', base)
    local contents
    local file = io.open(path, 'r')
    
    if file then
        contents = file:read('*a')
        io.close(file) -- close the file after using it
    else
        contents = M.get_file('settings.json')
        file = io.open(path, 'w')
        file:write( contents )
        io.close( file )
    end

    M.settings = json.decode(contents)
end

get_user_settings()

-- mute/unmute
if M.settings.is_mute then
    audio.setVolume(0)
end

-- check for new properties
if M.settings.timed_current_score == nil then
    M.settings.timed_current_score = 0
end

function M.save_user_settings()
    local base = system.DocumentsDirectory
    local path = system.pathForFile('settings.json', base)
    local contents = json.encode( M.settings )
    local file = io.open(path, 'w')
    file:write( contents )
    io.close(file)
end



function M.max_shapes()
    return M.current_level + 1
end



function M.scale_delta(width, height)
    return (width / height) * .85
end



function M.scale_factor()
    return 1.0
end



function M.shuffle_table(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end



function M.reduce_score()
    if M.score > 1 then
        M.score = M.score - 1
    end
end


function M.reset_score(current_level)
    current_level = current_level or M.current_level
    level = M.levels[current_level]
    local multiplier = M.level_targets[level]
    M.score = base_score * multiplier
end



function M.stars()
    local level = M.levels[M.current_level]
    local multiplier = M.level_targets[level]
    local perfect_score = base_score * multiplier
    local percent = M.score / perfect_score
    if percent >= .98 then stars = 3
    elseif percent >= .92 then stars = 2
    else stars = 1 end

    return stars
end



function M.targets_remaining()    
    return M.level_targets[M.levels[M.current_level]]
end

return M