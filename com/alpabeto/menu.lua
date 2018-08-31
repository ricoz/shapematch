local composer = require 'composer'

local scene = composer.newScene()

local color = require 'com.alpabeto.color'
local helper = require 'com.alpabeto.helper'
local shape = require 'com.alpabeto.shape'
local sound = require 'com.alpabeto.sound'
local options = require 'com.alpabeto.options'
local parents = require 'com.alpabeto.parents'

-- -----------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be
-- executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------

-- local forward references should go here
local next_level = {
    params = {
        current_level = 1,
    }
}
local letters = {}
local num_letters
local scale_factor = .7
local title
local Shape_Match = {'a', 'h', 'p', 'S', 'e',
                     't', 'a', 'c', 'M', 'h',}

local touch_enabled = true
local stage = display.getCurrentStage()

local function play(event)
    if not touch_enabled then return true end
    touch_enabled = false

    -- hide the cog
    stage.hide_cog()

    local button_name = ''
    if event then
        event.target:removeEventListener('tap', play)
        button_name = event.target.name
    end

    -- stop existing timers and transitions
    for k,v in pairs(timer._runlist) do
         timer.cancel(v)
    end

    sound.pop(2)
    
    for i=1,#scene.buttons do
        transition.to(scene.buttons[i], {delay=(i-1) * 60, time=300, xScale=0.01, yScale=0.01, alpha=0,
            transition=easing.inBack, onComplete=function(obj)
            obj:removeSelf()
        end})
    end
        

    for i=1,#letters do
        local letter = letters[i]
        transition.scaleTo(letter, {delay=(i-1) * 40, time=300, xScale=0.01, yScale=0.01, alpha=0,
            transition=easing.inBack, onComplete=function()
            letter:removeSelf()
        end})
    end

    transition.to( stage.parents, {time=250, alpha=0, xScale=0.01, yScale=0.01,
        transition=easing.inBack, onComplete=function(obj)
        obj:removeEventListener( 'touch', obj.handle_parents_touch )
    end} )

    transition.to( stage.parents_reminder, {time=250, alpha=0, xScale=0.01, yScale=0.01,
        transition=easing.inBack, onComplete=function(obj)
    end} )

    for i=stage.dots.numChildren,1,-1 do
        transition.cancel(stage.dots[i])
        stage.dots[i]:scale(0.01, 0.01)
        stage.dots[i].alpha = 0
    end

    timer.performWithDelay(#letters * 80, function()
        composer.removeScene('com.alpabeto.menu', true)
        if button_name == 'play_endless' then
            next_level.params.current_level = math.random(3,18)
            next_level.params.is_endless = true
            next_level.params.is_timed = false
            composer.gotoScene('com.alpabeto.level', next_level)
        elseif button_name == 'play_timed' then
            next_level.params.current_level = math.random(3,18)
            next_level.params.is_endless = false
            next_level.params.is_timed = true
            composer.gotoScene('com.alpabeto.level', next_level)
        else
            next_level.params.is_endless = false
            composer.gotoScene('com.alpabeto.levels', next_level)
        end
    end)
end



local function create_play_buttons()
    local time = 300
    -- move the title away from the center
    transition.moveBy(title, {time=time, transition=easing.outBack, y=-75,})

    scene.buttons = {}

    local buttons ={
        {x=display.contentCenterX, y=display.contentCenterY + 50, name='play_levels', locked=false,},
        {x=display.contentCenterX-80, y=display.contentCenterY + 50, name='play_timed', locked=true,},
        {x=display.contentCenterX+80, y=display.contentCenterY + 50, name='play_endless', locked=true,},
    }

    local reminder = display.newImageRect( scene.view, 'images/reminder.png', 100, 40 )
    reminder.x = display.contentCenterX - 35
    reminder.y = display.contentCenterY + 105
    reminder:setFillColor( 1, .5 )
    reminder:scale(0.01, 0.01)
    reminder.alpha = 0

    local reminder_visible = false
    local reminder_enabled = true
    local function remind(event)
        if reminder_visible and reminder_enabled then
            -- shake
            audio.play(sound.WRONG_SOUND)
            reminder_enabled = false
            local angle = 5
            transition.to(reminder, {time=60, rotation=angle, onComplete=function(obj)
                transition.to(obj, {time=60, rotation=-angle, onComplete=function(obj)
                    transition.to(obj, {time=60, rotation=angle, onComplete=function(obj)
                        transition.to(obj, {time=60, rotation=0, onComplete=function(obj)
                            reminder_enabled = true
                        end})
                    end})
                end})
            end})
        elseif reminder_enabled then
            audio.play(sound.WRONG_SOUND)
            reminder_enabled = false
            transition.to( reminder, {time=250, alpha=1, xScale=1, yScale=1,
                transition=easing.outBack, onComplete=function()
                    reminder_enabled = true
                    reminder_visible = true
            end} )
        end
    end

    -- create the play buttons using dark colors
    color.is_light = false
    for i=1,#buttons do
        local button_group = display.newGroup()
        scene.view:insert(button_group)
        button_group:translate(buttons[i].x, buttons[i].y)
        button_group:scale(0.01, 0.01)
        button_group.alpha = 0
        scene.buttons[#scene.buttons+1] = button_group

        local button_bg = shape.create(buttons[i].name .. '_bg')
        button_group:insert(button_bg)
        button_bg.name = buttons[i].name

        local button_icon
        local listener
        if buttons[i].name ~= 'play_levels' and not helper.settings.is_levels_complete then
            button_icon = shape.create('lock')
            button_icon:setFillColor(1,0.25)
            button_bg:setFillColor(1,.25)
            listener = remind
        else
            button_icon = shape.create(buttons[i].name)
            button_icon:setFillColor(1)
            button_bg:setFillColor(1,.5)
            listener = function(event)
                if reminder_visible then
                    transition.to( reminder, {time=250, alpha=0, xScale=0.01, yScale=0.01,
                        transition=easing.inBack, onComplete=function()
                        reminder_visible = false
                    end} )
                end
                play(event)
            end
        end
        button_group:insert(button_icon, true)

        transition.scaleTo(button_group, {delay=(i-1) * 60, time=time, xScale=1, yScale=1, alpha=1,
            transition=easing.outBack, onComplete=function()
            button_bg:addEventListener('tap', listener)
        end})
    end
    color.is_light = not color.is_light
end
-- -------------------------------------------------------------------------------

-- "scene:create()"
function scene:create( event )

    local scene_group = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "scene_group", add touch listeners, etc.

    if not audio.isChannelPlaying(sound.CHANNEL_INTRO) then
        -- came from level complete scene or level scene
        audio.fadeOut({channel=sound.CHANNEL_LEVEL, time=500})
        audio.fadeOut({channel=sound.CHANNEL_FINISH, time=500})
        audio.rewind(sound.BG_MUSIC_INTRO)
        audio.setVolume(0.5, {channel=sound.CHANNEL_INTRO})
        audio.play(sound.BG_MUSIC_INTRO, {channel=sound.CHANNEL_INTRO, loops=-1, fadein=1000})
    end

    touch_enabled = true

    if stage.bg == nil then
        local bg =  shape.random()
        bg:setMask(nil)
        bg.width = helper.CONTENT_WIDTH
        bg.height = helper.CONTENT_HEIGHT
        color.is_light = true
        -- local light_color = color.random()
        -- bg:setFillColor(light_color[1], light_color[2], light_color[3])
        -- bg.rgb = light_color
        bg:setFillColor(color.DEFAULT_BG[1], color.DEFAULT_BG[2], color.DEFAULT_BG[3])
        bg.rgb = color.DEFAULT_BG
        stage:insert(1, bg, true)
        bg.x, bg.y = display.contentCenterX, display.contentCenterY
        stage.bg = bg
    end

    title = display.newContainer(scene_group,
        helper.CONTENT_WIDTH / scale_factor, helper.CONTENT_HEIGHT / scale_factor)
    title:scale(scale_factor, scale_factor)
    title:translate(helper.BASE_WIDTH / 2, helper.BASE_HEIGHT / 2)

    -- create the game title using dark colors
    color.is_light = false
    local used_colors = {}
    for i=1,#Shape_Match do
        local letter = Shape_Match[i]
        letters[i] = shape.create(letter)
        letters[i].name = letter
        title:insert(letters[i], true)
        letters[i].x, letters[i].y = helper.BASE_WIDTH / 2, helper.BASE_HEIGHT / 2
        local letter_color = color.random_except(unpack(used_colors))
        used_colors[#used_colors+1] = letter_color
        -- pastel
        local r,g,b = (letter_color[1]+.3)/2, (letter_color[2]+.3)/2, (letter_color[3]+.3)/2
        letters[i]:setFillColor(r,g,b)
        -- letters[i]:setFillColor(letter_color[1], letter_color[2], letter_color[3], .75)
        -- letters[i]:setFillColor(letter_color[1], letter_color[2], letter_color[3])
        letters[i].rgb = {r,g,b}
    end
    -- reset to light for the levels screen
    color.is_light = not color.is_light

    num_letters = #letters

    local x_factor = (helper.CONTENT_WIDTH - helper.BASE_WIDTH) / 2
    local y_factor = (helper.CONTENT_HEIGHT - helper.BASE_HEIGHT) / 2

    -- create the options button
    if stage.options == nil then
        local cog_button = display.newRect(stage, 30-x_factor, helper.CONTENT_HEIGHT-25-y_factor, 36, 36)
        shape.mask_shape('options_cog', cog_button)
        cog_button:setFillColor(1, 0.75)
        cog_button.isHitTestMasked = false
        cog_button.alpha = 0
        cog_button:scale(0.01, 0.01)

        local time = 250

        local function tap_cog(event)
            touch_enabled = false
            if not options.enabled then return true end
            sound.pop(2)
            stage.hide_cog(options.show)
            if stage.progress_bar and stage.progress_bar.transition then
                stage.progress_bar.transition.pause()
            end

            transition.pause( 'setup' )
        end

        stage.show_cog = function()
            if cog_button.alpha < 1 and stage.progress_bar and stage.progress_bar.transition then
                stage.progress_bar.transition.resume()
            end
            options.enabled = true
            transition.to( cog_button, {time=time, alpha=1, xScale=1, yScale=1,
                transition=easing.outBack, onComplete=function()
                cog_button:addEventListener('tap', tap_cog)
                touch_enabled = true
            end} )
        end

        stage.hide_cog = function(callback)
            options.enabled = false
            transition.to( cog_button, {time=time, alpha=0, xScale=0.01, yScale=0.01,
                transition=easing.inBack, onComplete=function()
                if callback then callback() end
            end} )
        end

        cog_button.tap_cog = tap_cog
        stage.options = cog_button
    else
        -- show the cog
        stage.show_cog()
    end

    local counter = 0
    local source = nil
    local reminder_locked = false

    local function handle_parents_touch(event)
        if event.phase == 'began' then
            display.currentStage:setFocus(event.target)
            event.target.is_focus = true

            -- start counter
            transition.to(stage.dots[1], {time=500, alpha=1, xScale=1, yScale=1,})
            source = timer.performWithDelay( 500, function(t)
                transition.to(stage.dots[counter+2], {time=500, alpha=1, xScale=1, yScale=1,})
                counter = t.count
                if t.count >= 10 then
                    timer.cancel( t.source )
                    source = nil
                    counter = 0
                    touch_enabled = false
                    event.target:removeEventListener( 'touch', handle_parents_touch )
                    display.currentStage:setFocus(nil)
                    event.target.is_focus = nil

                    transition.to( event.target, {time=250, alpha=0, xScale=0.01, yScale=0.01,
                        transition=easing.inBack, onComplete=function()
                        sound.pop(2)
                        parents.show()
                    end} )

                    transition.to( stage.parents_reminder, {time=250, alpha=0, xScale=0.01, yScale=0.01,
                        transition=easing.inBack, onComplete=function()
                    end} )

                    for i=stage.dots.numChildren,1,-1 do
                        transition.cancel(stage.dots[i])
                        transition.to(stage.dots[i], {delay=(11-i)*60, time=125, alpha=0, xScale=0.01, yScale=0.01,})
                    end
                    
                end
            end, -1 )
        elseif event.phase == 'ended' or event.phase == 'cancelled' then
            display.currentStage:setFocus(nil)
            event.target.is_focus = nil
            for i=stage.dots.numChildren,1,-1 do
                transition.cancel( stage.dots[i] )
                stage.dots[i]:scale(0.01, 0.01)
                stage.dots[i].alpha = 0
            end
            if counter < 10 then
                if stage.parents_reminder.alpha < 1 and not reminder_locked then
                    transition.cancel( stage.parents_reminder )
                    reminder_locked = true
                    audio.play(sound.WRONG_SOUND)
                    transition.to( stage.parents_reminder, {time=250, alpha=1, xScale=1, yScale=1,
                        transition=easing.outBack, onComplete=function()
                        reminder_locked = false
                    end} )
                elseif not reminder_locked then
                    reminder_locked = true
                    -- shake
                    audio.play(sound.WRONG_SOUND)
                    local angle = 5
                    transition.to(stage.parents_reminder, {time=60, rotation=angle, onComplete=function(obj)
                        transition.to(obj, {time=60, rotation=-angle, onComplete=function(obj)
                            transition.to(obj, {time=60, rotation=angle, onComplete=function(obj)
                                transition.to(obj, {time=60, rotation=0, onComplete=function(obj)
                                    reminder_locked = false
                                end})
                            end})
                        end})
                    end})
                end
            end

            if source then
                timer.cancel( source )
                source = nil
            end
            counter = 0
            display.currentStage:setFocus(nil)
            event.target.is_focus = nil
        end
        return true
    end

    -- create the parents button
    if stage.parents == nil then
        local parents_button = display.newImageRect( stage, 'images/parents.png', 80, 30 )
        -- local parents_button = display.newRect( stage, 0, 0, 70, 20 )
        -- shape.mask_shape('parents', parents_button)
        parents_button:translate( helper.CONTENT_WIDTH-x_factor-45, helper.CONTENT_HEIGHT-20-y_factor )
        parents_button:setFillColor(1, 0.5)
        parents_button.isHitTestMasked = false
        parents_button.alpha = 0
        parents_button:scale(0.01, 0.01)
        stage.parents = parents_button
        stage.parents.handle_parents_touch = handle_parents_touch

        -- add reminder
        local parents_reminder = display.newImageRect( stage, 'images/parents_reminder.png', 140, 40 )
        parents_reminder:translate( helper.CONTENT_WIDTH-x_factor-103, helper.CONTENT_HEIGHT-32-y_factor )
        parents_reminder:setFillColor( 1, .5 )
        parents_reminder:scale(0.01, 0.01)
        parents_reminder.alpha = 0
        stage.parents_reminder = parents_reminder

        -- add dots
        local dots = display.newGroup( )
        stage:insert( dots )
        for i=1,10 do
            local dot = display.newImageRect( dots, 'images/dot.png', 6, 6 )
            dot:translate( helper.CONTENT_WIDTH-x_factor-(7*(11-i))-7, helper.CONTENT_HEIGHT-40-y_factor )
            dot:setFillColor( 1, 0.5 )
            dot:scale(0.01, 0.01)
            dot.alpha = 0
        end
        stage.dots = dots

        stage.show_parents_button = function()
            transition.to( stage.parents, {time=250, alpha=1, xScale=1, yScale=1,
                transition=easing.outBack, onComplete=function(obj)
                obj:addEventListener( 'touch', handle_parents_touch )
                touch_enabled = true
            end} )
        end
    end
end


-- "scene:show()"
function scene:show( event )

    local scene_group = self.view
    local phase = event.phase
    local ax = 350 / 2
    local ay = 141 / 2

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
        local hw = title.width / 2
        local hh = title.height / 2
        local padding = 150

        local from = {
            {x=175-ax, y=-(hh + padding)}, -- top (a)
            {x=-(hw+padding), y=-(hh + padding)}, -- top left (h)
            {x=hw+padding, y=-(hh + padding)}, -- top right (p)
            {x=-(hw+padding), y=31-ay,}, -- left (S)
            {x=hw+padding, y=40-ay}, -- right (e)

            {x=194-ax, y=hh + padding}, -- bottom (t)
            {x=-(hw+padding), y=hh + padding}, -- bottom left (a)
            {x=hw+padding, y=hh + padding}, -- bottom right (c)
            {x=-(hw+padding), y=112-ay}, -- left (M)
            {x=hw+padding, y=112-ay}, -- right (h)
        }

        for i=1,#letters do
            letters[i].x, letters[i].y = from[i].x, from[i].y
            letters[i].off_x, letters[i].off_y = from[i].x, from[i].y
        end
    elseif ( phase == "did" ) then
        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.

        stage.show_cog()
        stage.show_parents_button()

        local to = {
            {x=175-ax, y=35-ay,}, -- (a)
            {x=101-ax, y=30-ay,}, -- (h)
            {x=248-ax, y=46-ay,}, -- (p)
            {x=30-ax, y=31-ay,}, -- (S)
            {x=319-ax, y=40-ay,}, -- (e)
            
            {x=194-ax, y=111-ay,}, -- (t)
            {x=130-ax, y=117-ay,}, -- (a)
            {x=254-ax, y=113-ay,}, -- (c)
            {x=41-ax, y=112-ay,}, -- (M)
            {x=323-ax, y=112-ay,}, -- (h)
        }

        -- animate letters towards the center
        for i=1,#letters do
            local letter = letters[i]
            transition.to(letter, {delay=(i-1) * 60, time=250, x=to[i].x, y=to[i].y,
                transition=easing.outCirc, onComplete=function()
                local function explode(event)
                    sound.pop(math.random() > .5 and 1 or 4)
                    transition.scaleBy(event.target, {time=60, xScale=-.25, yScale=-.25,
                        onComplete=function()
                        num_letters = num_letters - 1
                        if num_letters == 0 then
                            play()
                        end
                        shape.explode(event.target)
                        event.target.alpha = 0
                    end})
                end
                letter:addEventListener('tap', explode)
            end})
        end

        timer.performWithDelay((#letters+3) * 80, function()
            create_play_buttons()
        end)
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