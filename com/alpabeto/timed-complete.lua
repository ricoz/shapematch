local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be
-- executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------

-- local forward references should go here

local helper = require 'com.alpabeto.helper'
local color = require 'com.alpabeto.color'
local shapes = require 'com.alpabeto.shapes'
local shape = require 'com.alpabeto.shape'
local sound = require 'com.alpabeto.sound'
local options = require 'com.alpabeto.options'

local touch_enabled = true
local stage = display.getCurrentStage()

local next_level = {
    params = {}
}

local hw = helper.BASE_WIDTH / 2
local hh = helper.BASE_HEIGHT / 2
local cw = helper.BASE_WIDTH
local ch = helper.BASE_HEIGHT

local padding = 64 * 1.5

local num_height = 64
local num_widths = {}
num_widths['0'] = 51
num_widths['1'] = 41
num_widths['2'] = 47
num_widths['3'] = 47
num_widths['4'] = 54
num_widths['5'] = 48
num_widths['6'] = 49
num_widths['7'] = 49
num_widths['8'] = 50
num_widths['9'] = 49

local num_small_height = 11
local num_small_widths = {}
num_small_widths['0'] = 9
num_small_widths['1'] = 7
num_small_widths['2'] = 8
num_small_widths['3'] = 8
num_small_widths['4'] = 9
num_small_widths['5'] = 8
num_small_widths['6'] = 8
num_small_widths['7'] = 8
num_small_widths['8'] = 8
num_small_widths['9'] = 8
-- -------------------------------------------------------------------------------

local function update_scoreboard(score)
    -- score = 7890
    local delay = 15
    local current_score = 0
    timer.performWithDelay( delay, function(event)
        -- clear previous score
        scene.scoreboard.group[1]:removeSelf( )
        local score_group = display.newGroup( )
        scene.scoreboard.group:insert( score_group )

        local count = event.count
        if score > 75 and score <= 200 then
            count = event.count*2
        elseif score > 200 and score <= 400 then
            count = event.count*4
        elseif score > 400 and score <= 5000 then
            count = event.count^2
        elseif score > 5000 then
            count = event.count^3
        end

        if count > score then
            count = score
        end

        local pos = 0
        local total_width = 0
        local first_width = 0
        for c in string.gmatch(count, '.') do
            if pos == 0 then first_width = num_widths[c] end
            local num = display.newImageRect( score_group, 'images/' .. c .. '.png', num_widths[c], num_height )
            num:setFillColor(color.gold[1], color.gold[2], color.gold[3])
            num.anchorX = 0
            num.x = total_width - first_width/2
            total_width = total_width + num_widths[c]
            pos = pos + 1
        end
        score_group.x = total_width / pos / -2 * (pos-1)

        if current_score == score then
            timer.cancel( event.source )
            if scene.score > helper.settings.timed_high_score then
                audio.play(sound.WIN_SOUND_PERFECT)
            elseif scene.score > 0 then
                audio.play(sound.WIN_SOUND)
            end

            if score > 0 then
                local star = shape.create('star')
                star.rgb = color.gold
                star.alpha = 0
                star.x = display.contentCenterX
                star.y = display.contentCenterY
                shape.explode(star)
                star:removeSelf( )
                star = nil
            end

            scene.show_button()
        end

        current_score = count
        scene.scoreboard:invalidate( )
    end, -1 )
end


-- "scene:create()"
function scene:create( event )
    audio.fadeOut({channel=sound.CHANNEL_LEVEL, time=500})
    audio.setVolume(0.5, {channel=sound.CHANNEL_FINISH})
    audio.rewind(sound.BG_MUSIC_FINISH)
    audio.play(sound.BG_MUSIC_FINISH, {channel=sound.CHANNEL_FINISH, loops=0, fadein=500})

    local scene_group = self.view
    touch_enabled = true

    -- add a darker background
    local bg = display.newRect(scene_group, 0, 0, helper.CONTENT_WIDTH, helper.CONTENT_HEIGHT)
    bg:translate( display.contentCenterX, display.contentCenterY )
    bg:setFillColor(0, .35)
    scene.bg = bg

    -- Initialize the scene here.
    -- Example: add display objects to "scene_group", add touch listeners, etc.

    local params = event.params
    scene.score = params.score
    helper.current_level = 1

    -- show the final score
    scene.scoreboard = display.newSnapshot( scene_group, helper.CONTENT_WIDTH, 100 )
    scene.scoreboard:translate( display.contentCenterX, display.contentCenterY )
    -- local bg = display.newRect( scene.scoreboard.group, 0, 0, helper.CONTENT_WIDTH, 100 )
    -- bg:setFillColor( 0, .5 )
    scene.scoreboard.alpha = 0

    -- create the replay button
    local replay_button_group = display.newGroup()
    replay_button_group:translate( display.contentCenterX, display.contentCenterY )
    scene_group:insert(replay_button_group)
    replay_button_group:translate(0, 50)
    replay_button_group:scale(0.01, 0.01)
    replay_button_group.alpha = 0

    local replay_button_icon = display.newRect(replay_button_group, 0, 0, 70, 70)
    shape.mask_shape('replay', replay_button_icon)
    replay_button_icon:setFillColor(1)

    local replay_button = shape.create('circle')
    replay_button_group:insert(1, replay_button)
    replay_button:setFillColor(1, .5)

    scene.replay_button = replay_button
end



function scene.abandon(callback)
    if not touch_enabled then return true end
    touch_enabled = false

    local time = 250
    options.enabled = false
    transition.fadeOut(scene.bg)

    -- hide score
    if scene.scoreboard then
        transition.to( scene.scoreboard, {time=time, xScale=0.01, yScale=0.01, alpha=0,
            transition=easing.inBack, onComplete=function()
            scene.scoreboard:removeSelf( )
            scene.scoreboard = nil
            transition.to(scene.replay_button.parent, {time=time, xScale=0.01, yScale=0.01, alpha=0,
                transition=easing.inBack, onComplete=function()
                callback()
            end})
        end} )

        if scene.hs then
            transition.cancel(scene.hs)
            transition.fadeOut( scene.hs, {time=time, onComplete=function()
                scene.hs:removeSelf( )
                scene.hs = nil
            end} )
        end
    end
end



local function replay()
    color.is_light = true
    local light_color = color.random_except(stage.bg.rgb)
    stage.bg.rgb = light_color
    transition.cancel(stage.bg.fill)
    transition.to(stage.bg.fill, {time=1000,r=light_color[1], g=light_color[2], b=light_color[3],
        onComplete=function()
    end})
    next_level.params.current_level = math.random(3,18)
    next_level.params.is_endless = false
    next_level.params.is_timed = true
    composer.removeScene('com.alpabeto.timed-complete', true)
    composer.gotoScene('com.alpabeto.level', next_level)
end



local function tap_replay(event)
    event.target:removeEventListener('tap', tap_replay)
    sound.pop(2)
    scene.abandon(replay)
end



function celebrate_finish()
    -- add random explosions until the music stops at 1 minute 16 seconds
    -- celebrate only if new high score

    if scene.score <= helper.settings.timed_high_score then
        -- save whatever needs to be saved
        helper.save_user_settings()
        return
    end

    helper.settings.timed_high_score = scene.score
    helper.save_user_settings()

    color.is_light = true
    local c = color.random()
    
    local randomizing_timer = timer.performWithDelay( 1000, function()
        c = color.random()
    end, -1 )

    timer.performWithDelay( 300, function(event)
        if event.count >= 175 then
            timer.cancel( event.source )
            timer.cancel( randomizing_timer )
            shape.clean_explosions()
        end
        shape.explode(nil, c)
    end , -1 )
end


function scene.show_button()
    local time = 300
    transition.moveBy(scene.scoreboard, {delay=time, time=time, y=-50,
        transition=easing.outBack, onComplete=function(obj)
    end})

    transition.to(scene.replay_button.parent, {delay=time, time=time, xScale=1, yScale=1, alpha=1,
        transition=easing.outBack, onComplete=function(button)
        button:addEventListener('tap', tap_replay)
        celebrate_finish()
    end})

    local offset = 110
    if scene.score > helper.settings.timed_high_score then
        scene.hs = display.newImageRect( scene.view, 'images/nhs.png', 90, 14 )
        scene.hs:setFillColor(color.gold[1], color.gold[2], color.gold[3])
        scene.hs:translate( display.contentCenterX, display.contentCenterY )
        scene.hs:translate( 0, -offset )
        scene.hs:scale(0.01, 0.01)
        scene.hs.alpha = 0

        scene.hs.fade_in_params = {
            time=1000,
            alpha=1,
            onComplete=function()
                transition.to( scene.hs, scene.hs.fade_out_params )
            end,
        }

        scene.hs.fade_out_params = {
            time=1000,
            alpha=.25,
            onComplete=function()
                transition.to( scene.hs, scene.hs.fade_in_params )
            end,
        }

        transition.to(scene.hs, {delay=time, time=time, xScale=1, yScale=1, alpha=1,
            transition=easing.outBack, onComplete=function()
            transition.to( scene.hs, scene.hs.fade_out_params )
        end})
    else
        scene.hs = display.newGroup( )
        -- scene.hs:translate( display.contentCenterX, display.contentCenterY )
        scene.hs.alpha = 0
        scene.view:insert( scene.hs )

        local you_scored = display.newImageRect( scene.hs, 'images/you_scored.png', 57, 14 )
        you_scored:setFillColor(color.gold[1], color.gold[2], color.gold[3])
        you_scored:translate( display.contentCenterX, display.contentCenterY )
        you_scored:translate( 0, -offset )

        if helper.settings.timed_high_score > 0 then
            
            local high_score_group = display.newGroup( )
            high_score_group:translate( display.contentCenterX, display.contentCenterY )
            scene.hs:insert( high_score_group )
            local high_score_label = display.newImageRect( high_score_group, 'images/high_score.png', 36, 11 )
            -- high_score_label:setFillColor(color.gold[1], color.gold[2], color.gold[3])
            high_score_label:setFillColor(1)
            high_score_label:translate( 0, offset )
            high_score_label.anchorX = 0

            local total_width = high_score_label.width + 2
            for c in string.gmatch(helper.settings.timed_high_score, '.') do
                local num = display.newImageRect( high_score_group, 'images/' .. c .. '_small.png', num_small_widths[c], num_small_height )
                -- num:setFillColor(color.gold[1], color.gold[2], color.gold[3])
                num:setFillColor( 1 )
                num.anchorX = 0
                num.y = offset
                num.x = total_width
                total_width = total_width + num_small_widths[c]
            end

            high_score_group.x = high_score_group.x-total_width/2
        end

        transition.fadeIn(scene.hs, {delay=time, time=time, onComplete=function()
        end})
    end
end


-- "scene:show()"
function scene:show( event )

    local scene_group = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
    elseif ( phase == "did" ) then
        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.

        -- show the cog
        stage.show_cog()

        local num = display.newImageRect( scene.scoreboard.group, 'images/0.png', num_widths['0'], num_height )
        num:setFillColor(color.gold[1], color.gold[2], color.gold[3])
        scene.scoreboard:invalidate( )

        transition.fadeIn(scene.scoreboard, {time=250, onComplete=function()
            update_scoreboard(scene.score)
        end})

        -- update_scoreboard(scene.score)
    end
end



-- "scene:hide()"
function scene:hide( event )

    local scene_group = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is on screen (but is about to go off screen).
        -- Insert code here to "pause" the scene.
        -- Example: stop timers, stop animation, stop audio, etc.

    elseif ( phase == "did" ) then
        -- Called immediately after scene goes off screen.
    end
end



-- "scene:destroy()"
function scene:destroy( event )

    local scene_group = self.view

    -- Called prior to the removal of scene's view ("scene_group").
    -- Insert code here to clean up the scene.
    -- Example: remove display objects, save state, etc.

    audio.fadeOut({channel=sound.CHANNEL_FINISH, time=500})

    -- stop all timers
    for k,v in pairs(timer._runlist) do
        timer.cancel(v)
    end

    shape.clean_explosions()
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene