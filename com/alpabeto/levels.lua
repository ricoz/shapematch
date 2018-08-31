local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be
-- executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------

-- local forward references should go here

local color = require 'com.alpabeto.color'
local helper = require 'com.alpabeto.helper'
local shape = require 'com.alpabeto.shape'
local sound = require 'com.alpabeto.sound'

local touch_enabled = true
local stage = display.getCurrentStage()

local containers

local rows = {-2, 0, 2}
local cols = 6

local next_level = {
    params = {}
}

-- scrolling
local has_scrolled = false

-- initialize later after translating the containers group object
local page_positions

-- -------------------------------------------------------------------------------



local function scroll(event)
    if event.phase == 'moved' then
        if has_scrolled then return true end

        if event.xStart < event.x and event.x - event.xStart >= 20 then
            helper.p('swipe to right')
            has_scrolled = true

            local old_x = containers.x
            if old_x >= page_positions[1] then
                helper.p('on page 1, do not scroll')
                return true
            elseif old_x <= page_positions[1] and old_x > page_positions[2] then
                helper.p('on page 1, do not scroll')
                return true
            elseif old_x <= page_positions[2] and old_x > page_positions[3] then
                helper.p('on page 2, scroll to page 1')
                containers.x = page_positions[1]
            elseif old_x <= page_positions[3] and old_x > page_positions[4] then
                helper.p('on page 3, scroll to page 2')
                containers.x = page_positions[2]
            elseif old_x > page_positions[4] then
                helper.p('on page 3, scroll to page 2')
                containers.x = page_positions[2]
            end

            transition.from( containers, {time=200, x=old_x,
                transition=easing.outBack, onComplete=function()
            end})
        elseif event.xStart > event.x and event.xStart - event.x >= 20 then
            helper.p('swipe to left')
            has_scrolled = true

            local old_x = containers.x
            if old_x >= page_positions[1] then
                helper.p('on page 1, scroll to page 2')
                containers.x = page_positions[2]
            elseif old_x <= page_positions[1] and old_x > page_positions[2] then
                helper.p('on page 1, scroll to page 2')
                containers.x = page_positions[2]
            elseif old_x <= page_positions[2] and old_x > page_positions[3] then
                helper.p('on page 2, scroll to page 3')
                containers.x = page_positions[3]
            elseif old_x <= page_positions[3] and old_x > page_positions[4] then
                helper.p('on page 3, do not scroll')
                return true
            elseif old_x > page_positions[4] then
                helper.p('on page 3, do not scroll')
                return true
            end

            transition.from( containers, {time=200, x=old_x,
                transition=easing.outBack, onComplete=function()
            end})
        end
    elseif event.phase == 'ended' or event.phase == 'cancelled' then
        has_scrolled = false
    end
    return true
end

function scene.abandon(callback)
    local container_indexes = {}
    for i=1,containers.numChildren do container_indexes[i] = i end
    helper.shuffle_table(container_indexes)

    for i=1,containers.numChildren do
        local container = containers[i]
        transition.cancel(container)
        transition.to(container, {delay=container_indexes[i] * 15, time=300, alpha=0,
            xScale=0.01, yScale=0.01, transition=easing.inBack, onComplete=function()
            -- call once after the last transition has finished
            if i == #rows * cols then -- 18
                callback()
            end
        end})
    end

    return true
end


-- "scene:create()"
function scene:create( event )

    local scene_group = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "scene_group", add touch listeners, etc.

    touch_enabled = true
    color.is_light = true
    color.generate_colors()

    -- create the level containers
    containers = display.newGroup()
    scene_group:insert(containers)


    local fill = {1,1,1}
    local wh = 116
    for row=1,#rows do
        for col=1,cols do
            local square = shape.create('level')
            local container = display.newSnapshot( wh, wh )
            containers:insert( container )
            container.group:insert(square, true)
            container.square = square
            square:setFillColor(1)
            container.to_alpha = .65

            container.x = (col-1) * square.width + square.width/2
            container.y = (square.height/2) * rows[row]

            container:scale(.01,.01)
            container.alpha = 0
        end
    end

    local cw = containers[1].square.width
    containers:translate(display.contentCenterX - cw, display.contentCenterY)
    page_positions = {
        containers.x,
        (containers.x - (helper.BASE_WIDTH - cw/2)),
        (containers.x - (helper.BASE_WIDTH - cw/2) * 2),
        (containers.x - (helper.BASE_WIDTH - cw/2) * 3),
    }

    if not audio.isChannelPlaying(sound.CHANNEL_INTRO) then
        -- came from level complete scene or level scene
        audio.fadeOut({channel=sound.CHANNEL_LEVEL, time=500})
        audio.fadeOut({channel=sound.CHANNEL_FINISH, time=500})
        audio.rewind(sound.BG_MUSIC_INTRO)
        audio.play(sound.BG_MUSIC_INTRO, {channel=sound.CHANNEL_INTRO, loops=-1})
        audio.setVolume(0.5, {channel=sound.CHANNEL_INTRO})
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

        local cw = containers[1].square.width

        local locations = {
            {{x=0,y=0,scale=1/2},}, -- level 1

            {{x=0,y=0,scale=1/2},}, -- level 2

            {{x=cw/-6,y=cw/-6,scale=1/3},
             {x=cw/6,y=cw/-6,scale=1/3},
             {x=cw/-6,y=cw/6,scale=1/3},
             {x=cw/6,y=cw/6,scale=1/3},}, -- level 7

            {{x=cw/-6,y=cw/-6,scale=1/3},
             {x=cw/6,y=cw/-6,scale=1/3},
             {x=cw/-6,y=cw/6,scale=1/3},
             {x=cw/6,y=cw/6,scale=1/3},}, -- level 8

            {{x=cw/-4,y=cw/-10,scale=1/4},
             {x=0,y=cw/-5,scale=1/4},
             {x=cw/4,y=cw/-10,scale=1/4},
             {x=0,y=0,scale=1/4},
             {x=cw/-4,y=cw/10,scale=1/4},
             {x=0,y=cw/5,scale=1/4},
             {x=cw/4,y=cw/10,scale=1/4},}, -- level 13

            {{x=cw/-4.5,y=cw/-10,scale=1/4},
             {x=0,y=cw/-5,scale=1/4},
             {x=cw/4.5,y=cw/-10,scale=1/4},
             {x=0,y=0,scale=1/4},
             {x=cw/-4.5,y=cw/10,scale=1/4},
             {x=0,y=cw/5,scale=1/4},
             {x=cw/4.5,y=cw/10,scale=1/4},}, -- level 14

            {{x=cw/-6,y=0, scale=1/2},
             {x=cw/6,y=0, scale=1/2},}, -- level 3

            {{x=cw/-6,y=0, scale=1/2},
             {x=cw/6,y=0, scale=1/2},}, -- level 4

            {{x=cw/-5,y=cw/-5,scale=1/3},
             {x=cw/5,y=cw/-5,scale=1/3},
             {x=0,y=0,scale=1/3},
             {x=cw/-5,y=cw/5,scale=1/3},
             {x=cw/5,y=cw/5,scale=1/3},}, -- level 9

            {{x=cw/-5,y=cw/-5,scale=1/3},
             {x=cw/5,y=cw/-5,scale=1/3},
             {x=0,y=0,scale=1/3},
             {x=cw/-5,y=cw/5,scale=1/3},
             {x=cw/5,y=cw/5,scale=1/3},}, -- level 10

            {{x=cw/-4.5, y=cw/-5,scale=1/4},
             {x=0, y=cw/-5,scale=1/4},
             {x=cw/4.5, y=cw/-5,scale=1/4},
             {x=cw/-9, y=0,scale=1/4},
             {x=cw/9, y=0,scale=1/4},
             {x=cw/-4.5, y=cw/5,scale=1/4},
             {x=0, y=cw/5,scale=1/4},
             {x=cw/4.5, y=cw/5,scale=1/4},}, -- level 15

             {{x=cw/-4.5, y=cw/-5,scale=1/4},
             {x=0, y=cw/-5,scale=1/4},
             {x=cw/4.5, y=cw/-5,scale=1/4},
             {x=cw/-9, y=0,scale=1/4},
             {x=cw/9, y=0,scale=1/4},
             {x=cw/-4.5, y=cw/5,scale=1/4},
             {x=0, y=cw/5,scale=1/4},
             {x=cw/4.5, y=cw/5,scale=1/4},}, -- level 16

             {{x=0,y=cw/-6,scale=1/2},
             {x=cw/-6,y=cw/6,scale=1/2},
             {x=cw/6,y=cw/6,scale=1/2},}, -- level 5

             {{x=0,y=cw/-6,scale=1/2},
             {x=cw/-6,y=cw/6,scale=1/2},
             {x=cw/6,y=cw/6,scale=1/2},}, -- level 6

            {{x=cw/-4.5, y=cw/-8,scale=1/4},
             {x=0, y=cw/-8,scale=1/4},
             {x=cw/4.5, y=cw/-8,scale=1/4},
             {x=cw/-4.5, y=cw/8,scale=1/4},
             {x=0, y=cw/8,scale=1/4},
             {x=cw/4.5, y=cw/8,scale=1/4},}, -- level 11

             {{x=cw/-4.5, y=cw/-8,scale=1/4},
             {x=0, y=cw/-8,scale=1/4},
             {x=cw/4.5, y=cw/-8,scale=1/4},
             {x=cw/-4.5, y=cw/8,scale=1/4},
             {x=0, y=cw/8,scale=1/4},
             {x=cw/4.5, y=cw/8,scale=1/4},}, -- level 12

             {{x=cw/-4.5, y=cw/-5,scale=1/4},
             {x=0, y=cw/-5,scale=1/4},
             {x=cw/4.5, y=cw/-5,scale=1/4},
             {x=cw/-4.5, y=0,scale=1/4},
             {x=0, y=0,scale=1/4},
             {x=cw/4.5, y=0,scale=1/4},
             {x=cw/-4.5, y=cw/5,scale=1/4},
             {x=0, y=cw/5,scale=1/4},
             {x=cw/4.5, y=cw/5,scale=1/4},}, -- level 17

             {{x=cw/-4.5, y=cw/-5,scale=1/4},
             {x=0, y=cw/-5,scale=1/4},
             {x=cw/4.5, y=cw/-5,scale=1/4},
             {x=cw/-4.5, y=0,scale=1/4},
             {x=0, y=0,scale=1/4},
             {x=cw/4.5, y=0,scale=1/4},
             {x=cw/-4.5, y=cw/5,scale=1/4},
             {x=0, y=cw/5,scale=1/4},
             {x=cw/4.5, y=cw/5,scale=1/4},}, -- level 18
        }

        -- add the shapes, stars and locks
        for i=1,#locations do
            local location = locations[i]
            helper.current_level = helper.levels[i]
            local container = containers[i]
            container.level = i
            -- ensure unique color per square
            color.generate_colors()

            local shapes = {}
            local colors = {stage.bg.rgb}
            local s = shape.random()
            local c

            -- same color for even numbered levels
            local same_color_mode = helper.levels[i] % 2 == 0
            for i=1,#location do
                if same_color_mode then
                    if i == 1 then c = color.random_except(unpack(colors)) end
                    s = shape.random_except(unpack(shapes))
                    shapes[i] = s
                else
                    c = color.random_except(unpack(colors))
                    colors[i] = c
                end

                local clone
                if not same_color_mode then -- same shape mode
                    clone = s:clone()
                else
                    clone = shapes[i]
                end

                -- pastel
                -- clone:setFillColor((c[1]+1)/2, (c[2]+1)/2, (c[3]+1)/2)
                clone:setFillColor(c[1], c[2], c[3])
                container.group:insert(clone, true)
                clone:scale(location[i].scale,location[i].scale)
                clone.x = location[i].x
                clone.y = location[i].y
            end

            -- show lock
            local locked = not helper.settings.unlocked_levels[helper.current_level]
            if locked then
                -- remove shapes except rounded square background
                for i=container.group.numChildren,2,-1 do
                    container.group[i]:removeSelf( )
                    container.group[i] = nil
                end

                container.square:setMask( nil )
                shape.mask_shape('level_lock', container.square)
                container.to_alpha = .25

                local function show_lock(event)
                    event.target:removeEventListener('tap', show_lock)
                    audio.play(sound.WRONG_SOUND)

                    -- shake
                    transition.to(event.target, {time=60, rotation=10, onComplete=function(obj)
                        transition.to(obj, {time=60, rotation=-10, onComplete=function(obj)
                            transition.to(obj, {time=60, rotation=10, onComplete=function(obj)
                                transition.to(obj, {time=60, rotation=0, onComplete=function(obj)
                                    obj:addEventListener('tap', show_lock)
                                end})
                            end})
                        end})
                    end})
                end
                container:addEventListener('tap', show_lock)
            else
                local function select(event)
                    if not touch_enabled then return true end
                    touch_enabled = false
                    sound.pop(2)
                    -- hide the cog
                    stage.hide_cog()
                    event.target:removeEventListener('tap', select)
                    next_level.params.current_level = helper.levels[container.level]
                    helper.reset_score(next_level.params.current_level)
                    scene.abandon(function()
                        composer.removeScene('com.alpabeto.levels', true)
                        composer.gotoScene('com.alpabeto.level', next_level)
                    end)
                end

                container:addEventListener('tap', select)
            end
            
            -- add stars
             local star_locations = {
                {{x=0, y=cw/2-16,scale=.2},},
                {{x=cw/-16, y=cw/2-16,scale=.2},
                 {x=cw/16, y=cw/2-16,scale=.2},},
                {{x=cw/-8, y=cw/2-16,scale=.2},
                 {x=0, y=cw/2-16,scale=.2},
                 {x=cw/8, y=cw/2-16,scale=.2},},
            }

            local num_stars = 0
            if helper.settings.level_stars[helper.current_level] ~= nil then
                num_stars = helper.settings.level_stars[helper.current_level]
            end
            -- local stars_snapshot = display.newSnapshot(container, cw, cw)
            for i=1,num_stars do
                local locations = star_locations[num_stars]

                star_outline = display.newRect(container.group, locations[i].x, locations[i].y, 128, 128)
                shape.mask_shape('star_goal', star_outline)
                star_outline:setFillColor(1)
                star_outline:scale(locations[i].scale, locations[i].scale)

                local star = shape.create('star')
                local gold = color.gold
                star:setFillColor(gold[1], gold[2], gold[3])
                container.group:insert(star, true)
                star.x = locations[i].x
                star.y = locations[i].y
                star:scale(locations[i].scale, locations[i].scale)
            end

            if not same_color_mode then s:removeSelf() end

            -- show the containers, move to appropriate page
            local pos = 1
            local last_level = 0
            while helper.settings.unlocked_levels[last_level+1] do
                last_level = last_level + 1
            end

            if last_level > 6 and last_level < 13 then
                pos = 2
            elseif last_level > 12 then
                pos = 3
            end
            containers.x = page_positions[pos]
            container:invalidate( )
            transition.to(container, {delay=(i-1) * 15, time=400, xScale=1, yScale=1, alpha=container.to_alpha,
                transition=easing.outBack, onComplete=function()
                if container.level == 18 then
                    stage:addEventListener( 'touch', scroll )
                end
            end})
        end
        helper.current_level = 1
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

    stage:removeEventListener( 'touch', scroll )
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene