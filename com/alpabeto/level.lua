local composer = require 'composer'

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

local shape_container
local targets_remaining
local targets_completed = {}

local next_level = {
    params = {}
}

local detractors
local time_is_up

local num_height = 11
local num_widths = {}
num_widths['0'] = 9
num_widths['1'] = 7
num_widths['2'] = 8
num_widths['3'] = 8
num_widths['4'] = 9
num_widths['5'] = 8
num_widths['6'] = 8
num_widths['7'] = 8
num_widths['8'] = 8
num_widths['9'] = 8

local function update_scoreboard(score)
    local plus_points = score - helper.settings.timed_current_score
    local current_score = helper.settings.timed_current_score
    helper.settings.timed_current_score = score
    helper.save_user_settings()

    timer.performWithDelay( 60, function(event)
        -- clear previous score
        stage.scoreboard.group[2]:removeSelf( )
        local score_group = display.newGroup( )
        stage.scoreboard.group:insert( score_group )

        current_score = current_score + 1
        local pos = 0
        for c in string.gmatch(current_score, '.') do
            local num = display.newImageRect( score_group, 'images/' .. c .. '_small.png', num_widths[c], num_height )
            num.x = pos * 8 + stage.scoreboard.group[1].width + 5
            pos = pos + 1
        end
        stage.scoreboard:invalidate( )
    end, plus_points )
end



local function goto_next()
    if time_is_up then return end

    -- reduce remaining shapes to solve
    targets_remaining = targets_remaining - 1
    if next_level.params.is_endless or next_level.params.is_timed then
        next_level.params.current_level = math.random(3,18)
        -- next_level.params.current_level = 17
        next_level.params.targets_remaining = nil
        next_level.params.targets_completed = {}
        composer.removeScene('com.alpabeto.level', true)
        composer.gotoScene('com.alpabeto.level', next_level)
    elseif targets_remaining == 0 then
        local level_options = {
            effect = 'fade',
            time = 500,
            params={},
        }
        composer.removeScene('com.alpabeto.level', true)
        composer.gotoScene('com.alpabeto.level-complete', level_options)
    else
        next_level.params.current_level = helper.current_level
        next_level.params.targets_remaining = targets_remaining
        next_level.params.targets_completed = targets_completed
        composer.removeScene('com.alpabeto.level', true)
        composer.gotoScene('com.alpabeto.level', next_level)
    end
end



local function select(event)
    if not touch_enabled then return true end

    if event.phase == 'began' then
        transition.cancel(event.target)
        shapes.start_drag(event)
    elseif event.target.is_focus then
        if event.phase == 'moved' then
            if scene.abandoning then return true end
            if shapes.overlaps(event) then
                if shapes.is_goal(event, goto_next, detractors) then
                    touch_enabled = false
                    -- update score if in timed mode
                    if scene.is_timed and stage.progress_bar.transition then
                        transition.cancel(stage.progress_bar)
                        stage.progress_bar.transition.t = nil
                        local current_level = helper.levels[helper.current_level]
                        local level_target = helper.level_targets[current_level]
                        update_scoreboard(helper.settings.timed_current_score + level_target)
                        if stage.progress_bar.width > 0 then
                            transition.to( stage.progress_bar, {time=400, width=helper.CONTENT_WIDTH, onComplete=function(obj)
                            end} )
                        end
                    end
                else
                    shapes.fail_drag(event)
                end
            else
                shapes.drag(event)
            end
        elseif event.phase == 'ended' or event.phase == 'cancelled' then
            -- just in case the move failed to detect
            if shapes.overlaps(event) then
                if shapes.is_goal(event, goto_next, detractors) then
                    touch_enabled = false
                    -- update score if in timed mode
                    if scene.is_timed and stage.progress_bar.transition then
                        transition.cancel(stage.progress_bar)
                        stage.progress_bar.transition.t = nil
                        local current_level = helper.levels[helper.current_level]
                        local level_target = helper.level_targets[current_level]
                        update_scoreboard(helper.settings.timed_current_score + level_target)
                        if stage.progress_bar.width > 0 then
                            transition.to( stage.progress_bar, {time=400, width=helper.CONTENT_WIDTH, onComplete=function(obj)
                            end} )
                        end
                    end
                else
                    shapes.fail_drag(event)
                end
            else
                shapes.reset_drag(event)
            end
        end
    end
    return true
end



-- called at the end of the goal animation setup
local function spawn(shape_target)
    local container = shape_target.parent
    targets_completed[#targets_completed + 1] = shape_target

    local hw = container.width / 2
    local hh = container.height / 2
    local cw = container.width
    local ch = container.height
    local padding = shape_target.width * 1.5

    local from_locations = {
        {{x=0, y=ch+padding}}, -- level 1

        {{x=0, y=ch+padding}}, -- level 2

        {{x=-(hw+padding), y=ch/4},
         {x=  hw+padding,  y=ch/4},}, -- level 3

        {{x=-(hw+padding), y=ch/4},
         {x= hw+padding,   y=ch/4},}, -- level 4

        {{x=-(hw+padding), y=ch/4},
         {x=0,             y=hh+padding},
         {x= hw+padding,   y=ch/4},}, -- level 5

        {{x=-(hw+padding), y=ch/4},
         {x=0,             y=hh+padding},
         {x= hw+padding,   y=ch/4},}, -- level 6

        {{x=-(hw+padding), y=ch/8},
         {x=-(hw+padding), y=ch/2.75},
         {x=  hw+padding,  y=ch/8},
         {x=  hw+padding,  y=ch/2.75},}, -- level 7

        {{x=-(hw+padding), y=ch/8},
         {x=-(hw+padding), y=ch/2.75},
         {x=  hw+padding,  y=ch/8},
         {x=  hw+padding,  y=ch/2.75},}, -- level 8

        {{x=-(hw+padding), y=ch/16},
         {x=-(hw+padding), y=ch/2.75},
         {x=0,             y=hh+padding},
         {x= hw+padding,   y=ch/16},
         {x= hw+padding,   y=ch/2.75},}, -- level 9

        {{x=-(hw+padding), y=ch/16},
         {x=-(hw+padding), y=ch/2.75},
         {x=0,             y=hh+padding},
         {x= hw+padding,   y=ch/16},
         {x= hw+padding,   y=ch/2.75},}, -- level 10

        {{x=-(hw+padding), y=ch/8},
         {x=0,             y=hh+padding},
         {x= hw+padding,   y=ch/8},
         {x=-(hw+padding), y=ch/2.75},
         {x=0,             y=hh+padding},
         {x= hw+padding,   y=ch/2.75},}, -- level 11

        {{x=-(hw+padding), y=ch/8},
         {x=0,             y=hh+padding},
         {x= hw+padding,   y=ch/8},
         {x=-(hw+padding), y=ch/2.75},
         {x=0,             y=hh+padding},
         {x= hw+padding,   y=ch/2.75},}, -- level 12

        {{x=-(hw+padding), y=-10+40},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=-10+40},
         {x=0,             y=hh+padding},
         {x=-(hw+padding), y=ch/2.7-40},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=ch/2.7-40},}, -- level 13

        {{x=-(hw+padding), y=-10+40},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=-10+40},
         {x=0,             y=hh+padding},
         {x=-(hw+padding), y=ch/2.7-40},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=ch/2.7-40},}, -- level 14

        {{x=-(hw+padding), y=-10},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=-10},
         {x=-(hw+padding), y=ch/5.6},
         {x=  hw+padding,  y=ch/5.6},
         {x=-(hw+padding), y=ch/2.7},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=ch/2.7},}, -- level 15

        {{x=-(hw+padding), y=-10},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=-10},
         {x=-(hw+padding), y=ch/5.6},
         {x=  hw+padding,  y=ch/5.6},
         {x=-(hw+padding), y=ch/2.7},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=ch/2.7},}, -- level 16

        {{x=-(hw+padding), y=-10},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=-10},
         {x=-(hw+padding), y=ch/5.6},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=ch/5.6},
         {x=-(hw+padding), y=ch/2.7},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=ch/2.7},}, -- level 17

        {{x=-(hw+padding), y=-10},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=-10},
         {x=-(hw+padding), y=ch/5.6},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=ch/5.6},
         {x=-(hw+padding), y=ch/2.7},
         {x=0,             y=hh+padding},
         {x=  hw+padding,  y=ch/2.7},}, -- level 18
    }

    local to_locations = {
        {{x=0, y=ch/4},}, -- level 1

        {{x=0, y=ch/4},}, -- level 2

        {{x=cw/-4, y=ch/4},
         {x=cw/ 4, y=ch/4},}, -- level 3

        {{x=cw/-4, y=ch/4},
         {x=cw/ 4, y=ch/4},}, -- level 4

        {{x=cw/-3, y=ch/4},
         {x=0,     y=ch/4},
         {x=cw/ 3, y=ch/4},}, -- level 5

        {{x=cw/-3, y=ch/4},
         {x=0,     y=ch/4},
         {x=cw/ 3, y=ch/4},}, -- level 6

        {{x=cw/ -4, y=ch/8},
         {x=cw/ -4, y=ch/2.75},
         {x=cw/  4, y=ch/8},
         {x=cw/  4, y=ch/2.75},}, -- level 7

        {{x=cw/ -4, y=ch/8},
         {x=cw/ -4, y=ch/2.75},
         {x=cw/  4, y=ch/8},
         {x=cw/  4, y=ch/2.75},}, -- level 8

        {{x=cw/-3.25, y=ch/16},
         {x=cw/-3.25, y=ch/2.75},
         {x=0,        y=ch/4.75},
         {x=cw/ 3.25, y=ch/16},
         {x=cw/ 3.25, y=ch/2.75},}, -- level 9

        {{x=cw/-3.25, y=ch/16},
         {x=cw/-3.25, y=ch/2.75},
         {x=0,        y=ch/4.75},
         {x=cw/ 3.25, y=ch/16},
         {x=cw/ 3.25, y=ch/2.75},}, -- level 10

        {{x=cw/-3, y=ch/8},
         {x=0,     y=ch/8},
         {x=cw/ 3, y=ch/8},
         {x=cw/-3, y=ch/2.75},
         {x=0,     y=ch/2.75},
         {x=cw/ 3, y=ch/2.75},}, -- level 11

        {{x=cw/-3, y=ch/8},
         {x=0,     y=ch/8},
         {x=cw/ 3, y=ch/8},
         {x=cw/-3, y=ch/2.75},
         {x=0,     y=ch/2.75},
         {x=cw/ 3, y=ch/2.75},}, -- level 12

        {{x=cw/-3, y=-10+40},
         {x=0,     y=-10},
         {x=cw/ 3, y=-10+40},
         {x=0,     y=ch/5.6},
         {x=cw/-3, y=ch/2.7-40},
         {x=0,     y=ch/2.7},
         {x=cw/ 3, y=ch/2.7-40},}, -- level 13

        {{x=cw/-3, y=-10+40},
         {x=0,     y=-10},
         {x=cw/ 3, y=-10+40},
         {x=0,     y=ch/5.6},
         {x=cw/-3, y=ch/2.7-40},
         {x=0,     y=ch/2.7},
         {x=cw/ 3, y=ch/2.7-40},}, -- level 14

        {{x=cw/-3, y=-10},
         {x=0,     y=-10},
         {x=cw/ 3, y=-10},
         {x=cw/-5, y=ch/5.6},
         {x=cw/ 5, y=ch/5.6},
         {x=cw/-3, y=ch/2.7},
         {x=0,     y=ch/2.7},
         {x=cw/ 3, y=ch/2.7},}, -- level 15

        {{x=cw/-3, y=-10},
         {x=0,     y=-10},
         {x=cw/ 3, y=-10},
         {x=cw/-5, y=ch/5.6},
         {x=cw/ 5, y=ch/5.6},
         {x=cw/-3, y=ch/2.7},
         {x=0,     y=ch/2.7},
         {x=cw/ 3, y=ch/2.7},}, -- level 16

        {{x=cw/-3, y=-10},
         {x=0,     y=-10},
         {x=cw/ 3, y=-10},

         {x=cw/-3, y=ch/5.6},
         {x=0,     y=ch/5.6},
         {x=cw/ 3, y=ch/5.6},

         {x=cw/-3, y=ch/2.7},
         {x=0,     y=ch/2.7},
         {x=cw/ 3, y=ch/2.7},}, -- level 17

        {{x=cw/-3, y=-10},
         {x=0,     y=-10},
         {x=cw/ 3, y=-10},

         {x=cw/-3, y=ch/5.6},
         {x=0,     y=ch/5.6},
         {x=cw/ 3, y=ch/5.6},

         {x=cw/-3, y=ch/2.7},
         {x=0,     y=ch/2.7},
         {x=cw/ 3, y=ch/2.7},}, -- level 18
    }

    local shapes = {shape_target}
    local colors = {shape_target.rgb}
    local s = shape_target
    local c = shape_target.rgb
    local same_color_mode = helper.current_level % 2 == 0
    local location = from_locations[helper.current_level]

    for i=1,#location-1 do
        if same_color_mode then
            s = shape.random_except(unpack(shapes))
            shapes[#shapes+1] = s
        else
            c = color.random_except(unpack(colors))
            colors[#colors+1] = c
        end

        local clone
        if not same_color_mode then -- same shape mode
            clone = s:clone()
            shapes[#shapes+1] = clone
        else
            clone = s
        end

        clone:setFillColor(c[1], c[2], c[3])
        clone.rgb = c
        container:insert(clone, true)
        detractors[i] = clone

        -- add the shadows
        local shadow = display.newRect(container, clone.x, clone.y, 156, 156)
        shadow:toBack()
        shadow:setFillColor(0)
        shape.mask_shape(clone.name .. '_shadow', shadow)
        shadow.is_shadow = true
        clone.shadow = shadow
    end

    -- create the shuffler and transitions
    local indexes = {}
    for i=1,#shapes do
        indexes[i] = i
    end
    helper.shuffle_table(indexes)

    local from = from_locations[helper.current_level]
    local to = to_locations[helper.current_level]

    local transition_counter = 0
    for i=1,#indexes do
        local index = indexes[i]
        local s = shapes[index]
        s.x = from[i].x
        s.y = from[i].y
        s.orig_x = to[i].x
        s.orig_y = to[i].y

        s.shadow.x = from[i].x
        s.shadow.y = from[i].y

        s:addEventListener('touch', select)

        transition.to(s, {delay=(i-1) * 60, time=400, x=to[i].x, y=to[i].y, tag='setup',
            transition=easing.outBack, onComplete=function(obj)
            transition_counter = transition_counter + 1
            
            if transition_counter == #indexes and scene.is_timed and stage.progress_bar then
                if stage.progress_bar.transition == nil then
                    stage.progress_bar.transition = {
                        t = nil,
                        pause = function()
                            if stage.progress_bar.transition.t then
                                transition.pause(stage.progress_bar.transition.t)
                            end
                        end,
                        resume = function()
                            if stage.progress_bar.transition.t then
                                transition.resume( stage.progress_bar.transition.t )
                            else
                                stage.progress_bar.transition.t = transition.to( stage.progress_bar, stage.progress_bar.transition.params )
                            end
                            options.enabled = true
                        end,
                    }
                    stage.progress_bar.transition.params = {
                        time=10000,
                        width=0,
                        onComplete=function(obj)
                            time_is_up = true
                            scene.abandon(function()
                                -- hide progress bar
                                transition.cancel( stage.progress_bar )
                                transition.fadeOut( stage.progress_bar, {time=250, onComplete=function(obj)
                                    stage.progress_bar.transition.t = nil
                                    stage.progress_bar.transition = nil
                                    stage.progress_bar:removeSelf( )
                                    stage.progress_bar = nil
                                end} )
                                -- hide score
                                if stage.scoreboard then
                                    transition.fadeOut( stage.scoreboard, {time=250, onComplete=function(obj)
                                        stage.scoreboard:removeSelf( )
                                        stage.scoreboard = nil
                                    end} )
                                end
                                if stage.bestscore then
                                    transition.fadeOut( stage.bestscore, {time=250, onComplete=function(obj)
                                        stage.bestscore:removeSelf( )
                                        stage.bestscore = nil
                                    end} )
                                end
                                local level_options = {
                                    effect = 'fade',
                                    time = 500,
                                    params={
                                        score=helper.settings.timed_current_score
                                    },
                                }
                                helper.settings.timed_current_score = 0
                                composer.removeScene('com.alpabeto.level', true)
                                composer.gotoScene('com.alpabeto.timed-complete', level_options)
                            end)
                        end,
                    }

                    -- add the score board
                    if stage.scoreboard == nil then
                        local snapshot = display.newSnapshot( stage, 156, 16 )
                        stage.scoreboard = snapshot
                        snapshot:translate( (helper.CONTENT_WIDTH - helper.BASE_WIDTH) / -2 + 10,
                            (helper.CONTENT_HEIGHT - helper.BASE_HEIGHT) / -2 + 25 )

                        -- add the label
                        local score_label = display.newImageRect( snapshot.group, 'images/score.png', 45, 11 )
                        score_label.anchorX = 0

                        -- initial score of zero
                        local score_group = display.newGroup( )
                        stage.scoreboard.group:insert( score_group )

                        local pos = 0
                        for c in string.gmatch(helper.settings.timed_current_score, '.') do
                            local num = display.newImageRect( score_group, 'images/' .. c .. '_small.png', num_widths[c], num_height )
                            num.anchorX = 0
                            num.x = pos * 8 + score_label.width + 1
                            pos = pos + 1
                        end

                        snapshot.alpha = 0
                        snapshot:setFillColor( stage.progress_bar.fill.r, stage.progress_bar.fill.g, stage.progress_bar.fill.b )

                        transition.fadeIn( snapshot, {time=250} )
                    end

                    -- add the best score
                    if stage.bestscore == nil then
                        local best_snapshot = display.newSnapshot( stage, 156, 16 )
                        stage.bestscore = best_snapshot

                        -- add the best label
                        local high_score_label = display.newImageRect( best_snapshot.group, 'images/high_score.png', 36, 11 )
                        high_score_label.anchorX = 0

                        -- add the high score
                        local pos = 0
                        local total_num_width = 0
                        for c in string.gmatch(helper.settings.timed_high_score, '.') do
                            local num = display.newImageRect( best_snapshot.group, 'images/' .. c .. '_small.png', num_widths[c], num_height )
                            num.anchorX = 0
                            num.x = pos * 8 + high_score_label.width + 1
                            total_num_width = total_num_width + 8
                            pos = pos + 1
                        end
                        
                        best_snapshot.alpha = 0
                        best_snapshot:setFillColor(1, .75)
                        best_snapshot.width = high_score_label.width + total_num_width + 1
                        best_snapshot.group.x = best_snapshot.width/-2
                        best_snapshot.anchorX = 1
                        best_snapshot.x = helper.CONTENT_WIDTH - 10 - ((helper.CONTENT_WIDTH - helper.BASE_WIDTH) / 2)
                        best_snapshot.y = (helper.CONTENT_HEIGHT - helper.BASE_HEIGHT) / -2 + 25
                        transition.fadeIn( best_snapshot, {time=250} )
                    end
                end

                -- decreasing time
                stage.progress_bar.transition.params.time = (10 - (helper.settings.timed_current_score/100)) * helper.TIME_FACTOR

                if stage.progress_bar.transition.params.time < 500 then
                    stage.progress_bar.transition.params.time = 500
                end
                
                -- pause if options is visible
                if options.enabled  then
                    options.enabled = false
                    stage.progress_bar.transition.resume()
                end
            end
        end})

        -- timer.performWithDelay( 400 + ((i-1) * 60), function()
        --     if s then
        --         s:addEventListener('touch', select)
        --     end
        -- end )

        transition.to(s.shadow, {delay=(i-1) * 60, time=400, x=to[i].x, y=to[i].y, tag='setup',
            transition=easing.outBack, onComplete=function()
        end})
    end
end



-- -------------------------------------------------------------------------------


-- "scene:create()"
function scene:create( event )
    local scene_group = self.view
    scene.abandoning = false

    detractors = {}
    time_is_up = false

    for i=scene_group.numChildren,1,-1 do
        scene_group[i]:removeSelf()
        scene_group[i] = nil
    end

    local params = event.params
    helper.current_level = params.current_level

    next_level.params.is_endless = params.is_endless
    scene.is_endless = params.is_endless

    next_level.params.is_timed = params.is_timed
    scene.is_timed = params.is_timed

    color.is_light = not color.is_light
    
    color.generate_colors(9)

    if params.targets_remaining then
        targets_remaining = params.targets_remaining
    else
        targets_remaining = helper.targets_remaining()
    end

    targets_completed = {}
    if params.targets_completed then
        targets_completed = params.targets_completed
    end

    -- Initialize the scene here.
    -- Example: add display objects to "scene_group", add touch listeners, etc.

    if not audio.isChannelPlaying(sound.CHANNEL_LEVEL) then
        -- came from levels scene
        audio.fadeOut({channel=sound.CHANNEL_INTRO, time=500})
        audio.rewind(sound.BG_MUSIC_LEVEL)
        audio.setVolume(0.5, {channel=sound.CHANNEL_LEVEL})
        audio.play(sound.BG_MUSIC_LEVEL, {channel=sound.CHANNEL_LEVEL, loops=-1, fadein=1000})
    end

    touch_enabled = true
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

        shape_container = shapes.add_goal(spawn, targets_completed)
        scene_group:insert(shape_container)

        if scene.is_timed then
            if stage.progress_bar == nil then
                stage.progress_bar = display.newRect( stage, display.contentCenterX, 0, helper.CONTENT_WIDTH, 15)
                stage.progress_bar.anchorX = 0
                stage.progress_bar.anchorY = 0
                stage.progress_bar:translate( -(helper.CONTENT_WIDTH/2), (helper.CONTENT_HEIGHT - helper.BASE_HEIGHT) / -2 )
                stage.progress_bar:setFillColor( stage.bg.rgb[1], stage.bg.rgb[2], stage.bg.rgb[3] )
                stage.progress_bar.width = 0

                transition.to( stage.progress_bar, {time=400, width=helper.CONTENT_WIDTH, onComplete=function(obj)
                end} )
            end

            local fill = shape_container.target_rgb
            transition.to( stage.progress_bar.fill, {time=400, r=fill[1], g=fill[2], b=fill[3],
                onComplete=function(obj)
            end} )

            if stage.scoreboard then
                transition.to( stage.scoreboard.fill, {time=400, r=fill[1], g=fill[2], b=fill[3],
                    onComplete=function(obj)
                end} )
            end
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

    shape.clean_explosions()
end


function scene.abandon(callback)
    scene.abandoning = true
    local time = 250
    local delay = 30
    local num_children = shape_container.numChildren
    for i=1,shape_container.numChildren do
        if shape_container[i] ~= nil then
            local shadow = shape_container[i].shadow
            if shadow ~= nil then
                transition.cancel(shadow)
                transition.to(shadow, {delay=(i-1)*delay, time=time, xScale=0.01, yScale=0.01, alpha=0,
                    transition=easing.inBack, onComplete=function(obj)
                end})
            end
            transition.cancel(shape_container[i])
            transition.to(shape_container[i], {delay=(i-1)*delay, time=time, xScale=0.01, yScale=0.01, alpha=0,
                transition=easing.inBack, onComplete=function(obj)
            end})
        end
    end

    timer.performWithDelay( time + (num_children * delay), callback )
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene