-----------------------------------------------------------------------------------------
--
-- shapes.lua
--
-----------------------------------------------------------------------------------------

local color = require 'com.alpabeto.color'
local helper = require 'com.alpabeto.helper'
local shape = require 'com.alpabeto.shape'
local sound = require 'com.alpabeto.sound'
local options = require 'com.alpabeto.options'

local M = {}

local container
local center


local function random_offscreen(quadrant)
    quadrant = quadrant or math.random(4)
    -- TODO: move magic number 128 to helper
    local half_width = (container.width / 2) + 128
    local half_height = (container.height / 2) + 128
    local origins = {
        -- left
        {x=-half_width, y=math.random(-half_height, half_height)},
        -- top
        {x=math.random(-half_width, half_width), y=-half_height},
        -- right
        {x=half_width, y=math.random(-half_height, half_height)},
        -- bottom
        {x=math.random(-half_width, half_width), y=half_height}
    }
    local origin = origins[quadrant]
    return origin.x, origin.y
end



local function scale()
    -- reset previous size, position and scale adjustments
    container.x, container.y = 0, 0
    container.xScale, container.yScale = 1.0, 1.0
    container:translate(display.contentCenterX, display.contentCenterY)
end



function M.add_goal(spawn_function, except)
    -- clear the container
    container = display.newContainer(helper.CONTENT_WIDTH, helper.CONTENT_HEIGHT)

    scale(helper.current_level)

    center = display.newGroup()
    container:insert(center, true)
    center.y = -(container.height/3.25)
    center:scale(.1,.1)

    local fill = color.random()
    container.target_rgb = fill

    -- create the inset
    local target_shape = shape.random_except(unpack(except))
    target_shape:setFillColor(fill[1], fill[2], fill[3])
    center:insert(target_shape, true)
    target_shape:scale(1.1, 1.1)

    -- create the border and its shadow
    local border = target_shape:clone(true)
    border:setFillColor(fill[1], fill[2], fill[3])
    border.rgb = fill
    center:insert(border, true)
    border.x, border.y = 0, 0

    -- add to center as properties
    center.border = border
    center.goal = target_shape

    local border_shadow = display.newRect(center, border.x, border.y, 156, 156)
    border_shadow:toBack()
    border_shadow:setFillColor(0)
    shape.mask_shape(border.name .. '_shadow', border_shadow)
    border_shadow.is_shadow = true
    border.shadow = border_shadow

    -- create the overlay and its shadow, set aside
    local overlay = target_shape:clone(false, true)
    overlay:setFillColor(fill[1], fill[2], fill[3])
    overlay.rgb = fill
    container:insert(overlay, true)
    overlay.alpha = 0

    local overlay_shadow = display.newRect(container, overlay.x, overlay.y, 156, 156)
    overlay_shadow:toBack()
    overlay_shadow:setFillColor(0)
    overlay_shadow.alpha = 0
    shape.mask_shape(overlay.name .. '_shadow_z2', overlay_shadow)
    overlay_shadow.is_shadow = true
    overlay.shadow = overlay_shadow

    -- perform the setup animations
    transition.scaleTo(center, {time=400, xScale=1, yScale=1, tag='setup',
        transition=easing.outBack, onComplete=function()
        -- detach the overlay
        target_shape.alpha = 0
        border:toBack()
        border.shadow:toBack()

        local shadow = overlay.shadow
        overlay.alpha = 1
        -- shadow.alpha = 1
        local cx, cy = target_shape:localToContent(target_shape.x, target_shape.y)
        overlay.x, overlay.y = overlay:contentToLocal(cx, cy)
        shadow.x, shadow.y = overlay.x, overlay.y
        overlay.anchorX = 0
        shadow.anchorX = 0
        overlay.x = -(overlay.width/2)
        shadow.x = -(shadow.width/2)

        shadow:toFront()
        overlay:toFront()

        local offscreen_y = container.height / 2 + overlay.height / 2
        transition.to(overlay, {time=600, rotation=6, transition=easing.inOutCubic, tag='setup',
            onComplete=function()
            -- move overlay off screen
            transition.to(overlay, {time=400, x=0, y=offscreen_y, rotation=0, anchorX=0.5, tag='setup',
                transition=easing.inOutCubic, onComplete=function()
                timer.performWithDelay(125, function()
                    audio.play(sound.WHOOSH_SOUNDS[math.random(#sound.WHOOSH_SOUNDS)])
                    spawn_function(overlay)
                end)
            end})
        end})

        -- do the same for the shadow
        transition.to(shadow, {time=600, rotation=6, alpha=1, transition=easing.inOutCubic, tag='setup',
            onComplete=function()
            transition.to(shadow, {time=400, x=0, y=offscreen_y, rotation=0, anchorX=0.5, tag='setup',
                transition=easing.inOutCubic, onComplete=function(s)
                s:setMask(nil)
                shape.mask_shape(overlay.name .. '_shadow', s)
            end})
        end})
    end})
    return container
end



function M.start_drag(event)
    display.currentStage:setFocus(event.target)
    event.target.is_focus = true
    local shadow = event.target.shadow
    shadow:toFront()
    event.target:toFront()
end



function M.drag(event)
    local shadow = event.target.shadow
    if not shadow.is_z2 then
        shadow:setMask(nil)
        shape.mask_shape(event.target.name .. '_shadow_z2', shadow)
        shadow.is_z2 = true
    end


    local c = event.target.parent
    local lx, ly = c:contentToLocal(event.x, event.y)
    local lxs, lys = c:contentToLocal(event.xStart, event.yStart)

    local x = (lx - lxs) + event.target.orig_x
    local y = (ly - lys) + event.target.orig_y
    
    event.target.x, event.target.y = x, y
    -- move the shadow as well
    shadow.x, shadow.y = event.target.x, event.target.y
end



function M.reset_drag(event)
    -- move back to original position
    display.currentStage:setFocus(nil)
    event.target.is_focus = nil

    event.target.shadow.alpha = 0
    transition.moveTo(event.target, {time=250, x=event.target.orig_x, y=event.target.orig_y,
        transition=easing.outBack, onComplete=function(obj)
        obj.shadow:setMask(nil)
        shape.mask_shape(event.target.name .. '_shadow', obj.shadow)
        obj.shadow.is_z2 = false
        event.target.shadow.x = event.target.x
        event.target.shadow.y = event.target.y
        obj.shadow.alpha = 1
    end})

    -- local shadow = event.target.shadow
    -- transition.moveTo(shadow, {time=250, x=event.target.orig_x, y=event.target.orig_y,
    --     transition=easing.outBack, onComplete=function(obj)
    --     obj:setMask(nil)
    --     shape.mask_shape(event.target.name .. '_shadow', obj)
    --     shadow.is_z2 = false
    -- end})
end



function M.fail_drag(event)
    helper.reduce_score()
    audio.play(sound.WRONG_SOUND)
    M.reset_drag(event)
end



function M.overlaps(event)
    return event.target:overlaps(center)
end



function M.is_goal(event, next_level, detractors)
    -- hide the cog
    -- display.currentStage.hide_cog()
    options.enabled = false

    display.currentStage:setFocus(nil)
    event.target.is_focus = nil

    if detractors == nil then detractors = {} end
    local payload = event.target
    local border = center.border
    local goal = center.goal

    if payload.name == goal.name and payload:same_fill(border) and payload.is_small == goal.is_small then
        local gx, gy = goal:localToContent(goal.x, goal.y)
        local px, py = container:contentToLocal(gx, gy)
        -- hide the detractors
        for i=1,#detractors do
            timer.performWithDelay(125, function()
                shape.explode(detractors[i])
            end)

            transition.to(detractors[i], {delay=125, time=60,
                xScale=0.01, yScale=0.01, alpha=0,
                onComplete=function(obj)
                if obj and obj.shadow then
                    obj.shadow:removeSelf()
                    obj.shadow = nil
                end
            end})
        end

        transition.to(payload.shadow, {time=125, x=px, y=py, rotation=0})
        transition.to(payload, {time=125, x=px, y=py, rotation=0, onComplete=function()
            audio.play(sound.MATCHED_SOUND)
            shape.explode(payload)
            -- dirty look
            timer.performWithDelay(225, function()
                local stage = display.getCurrentStage()
                -- hide the options menu before capturing the screen
                stage.options.alpha = 0
                if stage.progress_bar then stage.progress_bar.alpha = 0 end
                if stage.scoreboard then stage.scoreboard.alpha = 0 end
                if stage.bestscore then stage.bestscore.alpha = 0 end
                local screen = display.captureScreen()
                stage.options.alpha = 1
                if stage.progress_bar then stage.progress_bar.alpha = 1 end
                if stage.scoreboard then stage.scoreboard.alpha = 1 end
                if stage.bestscore then stage.bestscore.alpha = 1 end
                screen:translate(display.contentCenterX, display.contentCenterY)
                local bg = stage.bg
                if stage.screen then
                    transition.cancel(bg)
                    stage.screen:removeSelf()
                end
                stage:insert(1, screen)
                stage.screen = screen
                bg:setFillColor(payload.fill.r, payload.fill.g, payload.fill.b)
                bg.rgb = payload.rgb
                bg.alpha = 0
                -- cancel previous fade in transition
                transition.cancel(bg)
                transition.to(bg, {time=3000, alpha=.75})
                timer.performWithDelay(500, next_level)
            end)

            -- remove the border and its shadow
            border.shadow:removeSelf()
            border:removeSelf()
            -- hide the payload and remove its shadow
            payload.shadow:removeSelf()
            payload.alpha = 0
        end})
        return true
    end

    return false
end

return M