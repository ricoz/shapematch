local M = {}

local helper = require 'com.alpabeto.helper'
local color = require 'com.alpabeto.color'
local shape = require 'com.alpabeto.shape'
local sound = require 'com.alpabeto.sound'

local touch_enabled = false
local stage = display.currentStage
local parents_group = display.newGroup( )
stage:insert( parents_group )

local y_factor = (helper.CONTENT_HEIGHT - helper.BASE_HEIGHT) / 2

local copy_properties = {
    {x=display.contentCenterX, y=35, width=230, height=14, name='parents_header',},
    {x=display.contentCenterX, y=145, width=95, height=9, name='follow',},
    {x=display.contentCenterX, y=helper.CONTENT_HEIGHT-105, width=175, height=134, name='acknowledgements',},
    {x=display.contentCenterX, y=helper.CONTENT_HEIGHT-15, width=118, height=11, name='copyright',},
}

local button_properties = {
    {x=display.contentCenterX, y=95, width=248, height=64, name='facebook', url='fb://profile/811650298900862',
                                                                             url2='https://m.facebook.com/alpabeto.games',},
    {x=display.contentCenterX-96, y=180, width=64, height=64, name='instagram', url='instagram://user?username=alpabeto',
                                                                                url2='http://j.mp/alpabetogram',},
    {x=display.contentCenterX+96, y=180, width=64, height=64, name='googleplus', url='http://j.mp/alpabetoplus',},
    {x=display.contentCenterX-32, y=180, width=64, height=64, name='twitter', url='twitter://user?screen_name=alpabeto_games',
                                                                              url2='http://j.mp/alpabetot',},
    {x=display.contentCenterX+32, y=180, width=64, height=64, name='tumblr', url='http://j.mp/alpabetotumblr',},
    {x=display.contentCenterX, y=235, width=240, height=30, name='support', url='mailto:support@alpabeto.com?subject=Support%20Request',},
    {x=display.contentCenterX, y=280, width=170, height=30, name='privacy', url='http://j.mp/alpabetoprivacy',},
}

local buttons = {}
local copies = {}

local function create_button(button)
    local button_group = display.newGroup()
    parents_group:insert(button_group)
    button_group:translate(button.x, button.y-y_factor)
    button_group:scale(0.01, 0.01)
    button_group.alpha = 0
    button_group.name = button.name
    button_group.url = button.url
    button_group.url2 = button.url2
    buttons[#buttons+1] = button_group
    local button_icon = display.newImageRect( button_group, 'images/social/' .. button.name .. '.png',button.width, button.height )
    return button_group
end

local function create_copy(copy)
    local copy_group = display.newGroup()
    parents_group:insert(copy_group)
    copy_group:translate(copy.x, copy.y-y_factor)
    copy_group:scale(0.01, 0.01)
    copy_group.alpha = 0
    copies[#copies+1] = copy_group
    local copy_text = display.newImageRect( copy_group, 'images/' .. copy.name .. '.png', copy.width, copy.height )
    return copy_group
end


-- add the dark background
local bg = display.newRect( parents_group, 0, 0, helper.CONTENT_WIDTH, helper.CONTENT_HEIGHT )
bg:translate( display.contentCenterX, display.contentCenterY )
bg:setFillColor( 0, .85 )
bg.alpha = 0
bg:toBack( )

local listener_added = false
function M.close(event)
    if not touch_enabled then return true end
    touch_enabled = false
    bg:removeEventListener( 'tap', M.close )
    listener_added = false

    local transition_counter = #buttons
    for i=#buttons,1,-1 do
        transition.to(buttons[i], {delay=(#buttons-i) * 30, time=250, xScale=0.01, yScale=0.01, alpha=0,
            transition=easing.inBack, onComplete=function(obj)
            transition_counter = transition_counter - 1
            if transition_counter == 0 then
                -- fade the background
                transition.fadeOut( bg, {time=250, onComplete=function()
                    if event and event.callback then
                        event.callback()
                    else
                        display.currentStage.show_parents_button()
                    end
                end} )
            end
        end})
    end

    for i=#copies,1,-1 do
        transition.to(copies[i], {delay=(#copies-i) * 30, time=250, xScale=0.01, yScale=0.01, alpha=0,
            transition=easing.inBack, onComplete=function(obj)
        end})
    end

    return true
end


function M.handle_tap(event)
    local result = system.openURL( event.target.url )
    print( result )
    if not result then
        print( event.target.name, event.target.url, event.target.url2  )
        if event.target.url2 then
            system.openURL( event.target.url2 )
        end
    end
    return true
end

bg:addEventListener( 'touch', function(event)
    if event.phase == 'began' and not listener_added then
        listener_added = true
        bg:addEventListener( 'tap', M.close )
    end
    return true
end )



-- create the buttons
for i=1,#button_properties do
    local button = create_button(button_properties[i])
    button:addEventListener( 'tap', M.handle_tap )
end

-- create the copies
for i=1,#copy_properties do
    local copy = create_copy(copy_properties[i])
end

function M.show()
    local transition_counter = 0
    parents_group:toFront( )

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
        for i=1,#copies do
            transition.scaleTo(copies[i], {delay=(i-1) * 30, time=250, xScale=1, yScale=1, alpha=1,
                transition=easing.outBack, onComplete=function(obj)
            end})
        end
    end} )
end

return M