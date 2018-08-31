local M = {enabled=true}

local composer = require( "composer" )
local helper = require 'com.alpabeto.helper'
local color = require 'com.alpabeto.color'
local shape = require 'com.alpabeto.shape'
local sound = require 'com.alpabeto.sound'

local touch_enabled = false
local stage = display.currentStage
local options_group = display.newGroup( )
stage:insert( options_group )

local button_properties = {
    {x=display.contentCenterX-50, y=display.contentCenterY-50, name='home'},
    {x=display.contentCenterX+50, y=display.contentCenterY-50, name= audio.getVolume() > 0 and 'mute' or 'unmute'},

    {x=display.contentCenterX-50, y=display.contentCenterY+50, name='levels'},
    {x=display.contentCenterX+50, y=display.contentCenterY+50, name='replay'},
}

local button_states = {}

button_states['com.alpabeto.menu'] = {home=false, levels=false, replay=false}
button_states['com.alpabeto.level.endless'] = {home=true, levels=false, replay=false}
button_states['com.alpabeto.levels'] = {home=true, levels=false, replay=false}
button_states['com.alpabeto.timed-complete'] = {home=true, levels=false, replay=false}

local buttons = {}

local function create_button(button)
    local button_group = display.newGroup()
    options_group:insert(button_group)
    button_group:translate(button.x, button.y)
    button_group:scale(0.01, 0.01)
    button_group.alpha = 0
    buttons[#buttons+1] = button_group

    local button_icon = shape.create(button.name)
    button_group:insert(button_icon, true)
    button_icon:setFillColor(1)

    local button_bg = shape.create(button.name .. '_bg')
    button_group:insert(1, button_bg)
    button_bg:setFillColor(1,.5)
    
    button_group.icon = button_icon
    button_group.bg = button_bg
    button_group.name = button.name

    return button_group
end


-- add the dark background
local bg = display.newRect( options_group, 0, 0, helper.CONTENT_WIDTH, helper.CONTENT_HEIGHT )
bg:translate( display.contentCenterX, display.contentCenterY )
bg:setFillColor( 0, .85 )
bg.alpha = 0
bg:toBack( )


function M.close(event)
    if not touch_enabled then return true end
    touch_enabled = false

    local transition_counter = #buttons
    for i=#buttons,1,-1 do
        transition.to(buttons[i], {delay=(#buttons-i) * 30, time=250, xScale=0.01, yScale=0.01, alpha=0,
            transition=easing.inBack, onComplete=function(obj)
            transition_counter = transition_counter - 1
            if transition_counter == 0 then
                -- fade the background
                transition.fadeOut( bg, {time=250, onComplete=function()
                    display.currentStage.show_cog()
                end} )
            end
        end})
    end

    return true
end


function M.handle_tap(event)
    if not touch_enabled then return true end

    local button = event.target
    
    local current_scene_name = composer.getSceneName('current')
    local current_scene = composer.getScene(current_scene_name)

    local function goto(next_scene, scene_options)
        -- set menu and levels screen backgrounds always to light color
        color.is_light = true
        color.generate_colors()
        local light_color = color.random_except(stage.bg.rgb)
        stage.bg.rgb = light_color
        transition.cancel(stage.bg.fill)
        transition.to(stage.bg.fill, {time=2000,r=light_color[1], g=light_color[2], b=light_color[3],
            onComplete=function()
        end})

        current_scene.abandon(function()
            if stage.progress_bar then
                if stage.progress_bar.transition then
                    stage.progress_bar.transition.resume()
                end
                transition.cancel( stage.progress_bar )
                transition.fadeOut( stage.progress_bar, {time=250, onComplete=function(obj)
                    if stage.progress_bar.transition then
                        stage.progress_bar.transition.t = nil
                        stage.progress_bar.transition = nil
                    end
                    stage.progress_bar:removeSelf( )
                    stage.progress_bar = nil
                end} )
            end
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
            composer.removeScene(current_scene_name, true)
            composer.gotoScene(next_scene, scene_options)

            timer.performWithDelay( 250, function()
                display.currentStage.show_cog()
            end )
        end)

        M.close()
    end

    if button.name == 'mute' or button.name == 'unmute' then
        button.icon:setMask(nil)
        button.bg:setMask(nil)
        if audio.getVolume() > 0 then
            audio.setVolume(0)
            shape.mask_shape('unmute', button.icon)
            shape.mask_shape('unmute_bg', button.bg)
            helper.settings.is_mute = true
        else
            audio.setVolume(1)
            sound.pop(2)
            shape.mask_shape('mute', button.icon)
            shape.mask_shape('mute_bg', button.bg)
            helper.settings.is_mute = false
        end
        -- save to settings file
        -- TODO: could be dangerous if mute/unmute-ing repeatedly
        helper.save_user_settings()
        return true
    elseif button.name == 'home' and (current_scene_name == 'com.alpabeto.level' or
                                      current_scene_name == 'com.alpabeto.level-complete' or
                                      current_scene_name == 'com.alpabeto.timed-complete' or
                                      current_scene_name == 'com.alpabeto.levels') then
        sound.pop(2)
        goto('com.alpabeto.menu')
        return true
    elseif button.name == 'levels' and (current_scene_name == 'com.alpabeto.level' or
                                        current_scene_name == 'com.alpabeto.level-complete') and
                                        not current_scene.is_endless and not current_scene.is_timed then
        sound.pop(2)
        goto('com.alpabeto.levels')
        return true
    elseif button.name == 'replay' and (current_scene_name == 'com.alpabeto.level' or
                                        current_scene_name == 'com.alpabeto.level-complete') and
                                        not current_scene.is_endless and not current_scene.is_timed then
        sound.pop(2)
        local scene_options = {params={}}
        scene_options.params.current_level = helper.current_level
        scene_options.params.is_endless = false
        helper.reset_score(scene_options.params.current_level)
        goto('com.alpabeto.level', scene_options)
        return true
    end

    return false
end

bg:addEventListener( 'tap', function(event)
    M.close()
    transition.resume( 'setup' )
    return true
end )
-- prevent touch events on the stage
bg:addEventListener( 'touch', function(event) return true end )
for i=1,#button_properties do
    local button = create_button(button_properties[i])
    button:addEventListener( 'tap', M.handle_tap )
end

function M.show()
    local transition_counter = 0
    options_group:toFront( )

    -- set available buttons
    local current_scene_name = composer.getSceneName('current')
    local current_scene = composer.getScene(current_scene_name)
    if current_scene.is_endless or current_scene.is_timed then
        current_scene_name = current_scene_name .. '.endless'
    end
    for i=1,#buttons do
        local button = buttons[i]
        -- reset appearances except for mute button
        if button.name ~= 'mute' and button.name ~= 'unmute' then
            button.bg:setMask(nil)
            shape.mask_shape(button.name .. '_bg', button.bg)
            button.bg:setFillColor(1,.5)
            button.icon.alpha = 1
        end

        local states = button_states[current_scene_name]
        if states and states[button.name] ~= nil then
            local active = states[button.name]
            if not active then
                button.icon.alpha = 0
                button.bg:setMask(nil)
                shape.mask_shape('circle', button.bg)
                button.bg:setFillColor(1,0.15)
            end
        else
        end
    end


    transition.fadeIn( bg, {time=250, onComplete=function()
        for i=1,#buttons do
            transition.scaleTo(buttons[i], {delay=(i-1) * 30, time=250, xScale=1, yScale=1, alpha=1,
                transition=easing.outBack, onComplete=function(obj)
                transition_counter = transition_counter + 1
                if transition_counter == #buttons then
                    touch_enabled = true
                end
            end})
        end
    end} )
end

return M