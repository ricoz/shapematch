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

local stars

local hw = helper.BASE_WIDTH / 2
local hh = helper.BASE_HEIGHT / 2
local cw = helper.BASE_WIDTH
local ch = helper.BASE_HEIGHT
local padding = 128 * 1.5

local from_locations = {
    {{x= 0,            y=hh+padding}},

    {{x=-(hw+padding), y=ch/4},
     {x= hw+padding,   y=ch/4},},

    {{x=-(hw+padding), y=ch/4},
     {x= 0,            y=hh+padding},
     {x= hw+padding,   y=ch/4},},
}

local to_locations = {
    {{x= 0,      y=0}},

    {{x=cw/-7,   y=0},
     {x=cw/ 7,   y=0}},

    {{x=cw/-3.5, y=0},
     {x= 0,      y=0},
     {x=cw/ 3.5, y=0}},
}
-- -------------------------------------------------------------------------------



-- "scene:create()"
function scene:create( event )
    audio.fadeOut({channel=sound.CHANNEL_LEVEL, time=500})
    audio.setVolume(0.5, {channel=sound.CHANNEL_FINISH})
    audio.rewind(sound.BG_MUSIC_FINISH)
    audio.play(sound.BG_MUSIC_FINISH, {channel=sound.CHANNEL_FINISH, loops=0, fadein=500})

    local scene_group = self.view
    local container = display.newContainer(scene_group, helper.CONTENT_WIDTH, helper.CONTENT_HEIGHT)
    local num_stars = helper.stars()
    touch_enabled = true

    -- add a darker background
    local bg = display.newRect(container, 0, 0, container.width, container.height)
    bg:setFillColor(0, .35)
    scene.bg = bg

    -- unlock levels and add the higher star
    helper.settings.unlocked_levels[helper.current_level + 1] = true
    if num_stars > helper.settings.level_stars[helper.current_level] then
        helper.settings.level_stars[helper.current_level] = num_stars
    end
    -- then save to file
    helper.save_user_settings()

    -- Initialize the scene here.
    -- Example: add display objects to "scene_group", add touch listeners, etc.

    local params = event.params

    -- create the stars
    stars = {}
    for i=1,num_stars do
        local star = display.newRect(container,
                                     from_locations[num_stars][i].x, from_locations[num_stars][i].y, 128, 128)
        shape.mask_shape('star', star)
        star:scale(0.01, 0.01)
        star:setFillColor(color.gold[1], color.gold[2], color.gold[3])
        star.rgb = color.gold
        star.alpha = 0
        star.name = 'star'
        stars[i] = star
    end


    -- create the next button
    local next_button_group = display.newGroup()
    container:insert(next_button_group)
    next_button_group:translate(0, 50)
    next_button_group:scale(0.01, 0.01)
    next_button_group.alpha = 0

    local next_button_arrow = display.newRect(next_button_group, 0, 0, 70, 70)
    shape.mask_shape('next', next_button_arrow)
    next_button_arrow:setFillColor(1)

    local next_button = shape.create('circle')
    next_button_group:insert(1, next_button)
    next_button:setFillColor(1, .5)

    scene.next_button = next_button

    container:translate(display.contentCenterX, display.contentCenterY)
end



function scene.abandon(callback)
    if not touch_enabled then return true end
    touch_enabled = false

    local time = 250

    -- hide the cog
    options.enabled = false


    local transition_count = 0

    transition.fadeOut(scene.bg)

    for i=1,#stars do
        transition.cancel( stars[i] )
        transition.to(stars[i], {delay=(i-1)*60, time=time, xScale=0.01, yScale=0.01, alpha=0,
            transition=easing.inBack, onComplete=function()
            transition_count = transition_count + 1
            if transition_count == #stars then
                transition.cancel( scene.next_button.parent )
                transition.to(scene.next_button.parent, {time=time, xScale=0.01, yScale=0.01, alpha=0,
                    transition=easing.inBack, onComplete=function()
                    callback()
                end})
            end
        end})
    end
end



local function goto_next()
    next_level.params.current_level = helper.current_level + 1
    helper.reset_score(next_level.params.current_level)

    composer.removeScene('com.alpabeto.level-complete', true)
    composer.gotoScene('com.alpabeto.level', next_level)
end



local function tap_next(event)
    event.target:removeEventListener('tap', tap_next)
    sound.pop(2)
    scene.abandon(goto_next)
end



local function show_button()
    local time = 300
    for i=1,#stars do
        transition.moveBy(stars[i], {delay=time, time=time, transition=easing.outBack, y=-50,})
    end

    transition.to(scene.next_button.parent, {delay=time, time=time, xScale=1, yScale=1, alpha=1,
        transition=easing.outBack, onComplete=function(button)
        button:addEventListener('tap', tap_next)
    end})
end


local function celebrate_finish()
    if helper.current_level == 18 then
        local num_stars = helper.stars()
        helper.settings.is_levels_complete = true
        helper.save_user_settings()

        goto_next = function()
            -- set menu and levels screen backgrounds always to light color
            color.is_light = true
            color.generate_colors()
            local light_color = color.random_except(stage.bg.rgb)
            stage.bg.rgb = light_color
            transition.cancel(stage.bg.fill)
            transition.to(stage.bg.fill, {time=1000,r=light_color[1], g=light_color[2], b=light_color[3],
                onComplete=function()
            end})

            composer.removeScene('com.alpabeto.level-complete', true)
            composer.gotoScene('com.alpabeto.menu')
        end

        -- add random explosions until the music stops at 1 minute 16 seconds
        color.is_light = true
        local c = color.random()
        
        -- timer.performWithDelay( 250, function() shape.clean_explosions() end, -1 )
        
        local randomizing_timer = timer.performWithDelay( 1000, function()
            c = color.random()
        end, -1 )

        timer.performWithDelay( 300, function(event)
            if event.count >= 175 then
                timer.cancel( event.source )
                timer.cancel( randomizing_timer )
                shape.clean_explosions()
            end
            helper.current_level = 1
            shape.explode(nil, c)
            helper.current_level = 18
        end , -1 )
    end
end


-- "scene:show()"
function scene:show( event )

    local scene_group = self.view
    local phase = event.phase
    local current_level = helper.current_level

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
    elseif ( phase == "did" ) then
        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.

        -- show the cog
        stage.show_cog()

        local num_stars = helper.stars()
        local transition_count = 0
        for i=1,num_stars do
            transition.to(stars[i], {delay=i * 200, time=250, xScale=1, yScale=1, alpha=1,
                x=to_locations[num_stars][i].x, y=to_locations[num_stars][i].y, transition=easing.outCirc,
                onComplete=function(s)
                helper.current_level = 1
                shape.explode(s)
                helper.current_level = current_level
                transition_count = transition_count + 1
                -- add rotation every few seconds
                local star = stars[i]
                star.rot = {is_cw=true, factor=72}
                timer.performWithDelay(4000, function()
                    transition.to(star, {time=600, transition=easing.outBack,
                        rotation=star.rot.factor, onComplete=function(s)
                        if s.rot.factor >= 360 then s.rot.is_cw = false
                        elseif s.rot.factor <= 0 then s.rot.is_cw = true end
                        if s.rot.is_cw then
                            s.rot.factor = s.rot.factor + 72    
                        else
                            s.rot.factor = s.rot.factor - 72
                        end
                    end})
                end, -1)
                if num_stars == 1 then
                    -- first and last star
                    audio.play(sound.WIN_SOUND)
                    show_button()
                    celebrate_finish()
                elseif transition_count == 1 then
                    -- perform on the first star
                    if helper.stars() < 3 then
                        audio.play(sound.WIN_SOUND)
                    else
                        audio.play(sound.WIN_SOUND_PERFECT)
                    end
                elseif transition_count == num_stars then
                    -- perform on the last star
                    show_button()
                    celebrate_finish()
                end
                -- add tap event handlers
                local function explode(event)
                    sound.pop(math.random() > .5 and 1 or 4)
                    event.target:removeEventListener('tap', explode)
                    transition.cancel( event.target )
                    transition.scaleBy(event.target, {time=60, xScale=-.25, yScale=-.25,
                        onComplete=function(s)
                        helper.current_level = 1
                        shape.explode(s)
                        helper.current_level = current_level
                        s.alpha = 0
                        num_stars = num_stars - 1
                        if num_stars == 0 then
                            scene.abandon(goto_next)
                        end
                    end})
                end
                star:addEventListener('tap', explode)
            end})
        end
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