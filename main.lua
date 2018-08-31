-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

display.setStatusBar(display.HiddenStatusBar)
math.randomseed(os.time())

-----------------------------------------------------------------------------------------

local composer = require 'composer'
--local sound = require 'com.alpabeto.sound'
--local helper = require 'com.alpabeto.helper'

-- Code to initialize your app
local scene_options = {
    params = {}
}

audio.reserveChannels(3)

composer.gotoScene('com.alpabeto.menu', scene_options)