-----------------------------------------------------------------------------------------
--
-- shape.lua
--
-----------------------------------------------------------------------------------------

local physics = require 'physics'
local helper = require 'com.alpabeto.helper'
local color = require 'com.alpabeto.color'
local json = require 'json'

local shape_width_height = 128

local M = {}

local shape_names = {
    {'square',},
    {'circle',},
    {'square', 'circle',},
    {'square', 'circle',},
    {'square', 'circle', 'triangle',},
    {'square', 'circle', 'triangle',},
    {'square', 'circle', 'triangle', 'rectangle',},
    {'square', 'circle', 'triangle', 'rectangle',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval', 'pentagon',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval', 'pentagon',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval', 'pentagon', 'hexagon',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval', 'pentagon', 'hexagon',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval', 'pentagon', 'hexagon', 'octagon',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval', 'pentagon', 'hexagon', 'octagon',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval', 'pentagon', 'hexagon', 'octagon', 'rhombus',},
    {'square', 'circle', 'triangle', 'rectangle', 'oval', 'pentagon', 'hexagon', 'octagon', 'rhombus',},
}

-- temporarily hide the newly created shapes in this fully transparent display group
local temp_group = display.newGroup()
temp_group.alpha = 0

local particle = json.decode(helper.get_file('explosion.rg'))
local emitters = {}

local function list()
    local shapes = shape_names[helper.current_level]

    local shapes_copy = {}
    for i=1,#shapes do
        shapes_copy[i] = shapes[i]
    end

    return shapes_copy
end



function M.mask_shape(shape_name, shape_image)
    local mask
    if display.imageSuffix == '@4x' then
        mask = graphics.newMask('images/' .. shape_name .. '_mask@4x.png')
        shape_image:setMask(mask)
        shape_image.maskScaleX, shape_image.maskScaleY = 0.25, 0.25
    elseif display.imageSuffix == '@3x' then
        mask = graphics.newMask('images/' .. shape_name .. '_mask@3x.png')
        shape_image:setMask(mask)
        shape_image.maskScaleX, shape_image.maskScaleY = 0.3333333333, 0.3333333333
    elseif display.imageSuffix == '@2x' then
        mask = graphics.newMask('images/' .. shape_name .. '_mask@2x.png')
        shape_image:setMask(mask)
        shape_image.maskScaleX, shape_image.maskScaleY = 0.5, 0.5
    else
        mask = graphics.newMask('images/' .. shape_name .. '_mask.png')
        shape_image:setMask(mask)
    end
end



local function create_shape(shape_name)
    local shape_image
    shape_image = display.newRect(temp_group, 0, 0, shape_width_height, shape_width_height )
    M.mask_shape(shape_name, shape_image)
    return shape_image
end



local function random_shape()
    local level_shape_names = shape_names[helper.current_level]
    local shape_name = level_shape_names[math.random(#level_shape_names)]
    return shape_name, create_shape(shape_name)
end



local function overlaps(self, shape)
    if shape == nil then return false end

    local hw = shape_width_height / 2
    local hh = shape_width_height / 2
    return self.x > -hw and self.x < hw
            and self.y > -hh + shape.y and self.y < hh + shape.y
end



local function same_fill(self, shape)
    return self.fill.r == shape.fill.r
    and self.fill.g == shape.fill.g
    and self.fill.b == shape.fill.b
end


local function clone(self, as_border)

    local name = self.name
    if as_border then name = name .. '_goal' end
    local new_shape = create_shape(name)
    new_shape.name = name
    new_shape.clone = clone
    new_shape.overlaps = overlaps
    new_shape.same_fill = same_fill
    new_shape.is_small = self.is_small
    return new_shape
end



function M.create(name)
    local new_shape = create_shape(name)
    new_shape.name = name
    new_shape.clone = clone
    new_shape.overlaps = overlaps
    new_shape.same_fill = same_fill
    new_shape.is_small = false
    return new_shape
end



function M.random()
    local name, new_shape = random_shape()
    new_shape.name = name
    new_shape.clone = clone
    new_shape.overlaps = overlaps
    new_shape.is_small = false
    new_shape.same_fill = same_fill
    return new_shape
end



function M.random_except(...)
    local shapes = list()

    -- handle single shape
    if #shapes == 1 then
        return M.create(shapes[1])
    end

    for k,v in ipairs(arg) do
        for i=#shapes,1,-1 do
            local shape = shapes[i]
            if shape == v.name then
                table.remove(shapes, i)
            end
        end
    end

    local shape = shapes[math.random(#shapes)]
    return M.create(shape)
end



function M.small(name)
    local new_shape = create_shape(name)
    new_shape.width = new_shape.width * helper.SMALL_FACTOR
    new_shape.height = new_shape.height * helper.SMALL_FACTOR
    new_shape.name = name
    new_shape.clone = clone
    new_shape.overlaps = overlaps
    new_shape.same_fill = same_fill
    new_shape.is_small = true
    return new_shape
end



function M.explode(shape, fill)
    local image
    local x, y
    if shape then
        image = 'images/' .. shape.name .. '.png'
        fill = fill or shape.rgb
        x, y = shape:localToContent(0, 0)
    else
        local names = shape_names[#shape_names]
        local name = names[math.random(#names)]
        fill = fill or color.random()
        image = 'images/' .. name .. '.png'
        x, y = math.random( helper.CONTENT_WIDTH ), math.random( helper.CONTENT_HEIGHT )
    end

    particle.textureFileName = image

    particle.startColorRed = fill[1]
    particle.startColorGreen = fill[2]
    particle.startColorBlue = fill[3]

    particle.finishColorRed = fill[1]
    particle.finishColorGreen = fill[2]
    particle.finishColorBlue = fill[3]

    -- reduce max particles on higher levels
    local level = helper.levels[helper.current_level]
    local level_target = helper.level_targets[level]
    particle.maxParticles = 55 - level_target * 4

    local startColorAlphas =  {0.25, 0.50, 0.75}
    local finishColorAlphas = {0.10, 0.175, 0.25}
    particle.startColorAlpha = 1
    particle.finishColorAlpha = 1
    if shape == nil then
        particle.startColorAlpha = startColorAlphas[math.random(3)]
        particle.finishColorAlpha = finishColorAlphas[math.random(3)]
    end

    local emitter = display.newEmitter(particle)
    emitter.x, emitter.y = x, y

    -- add to emitter list for cleaning later
    emitters[#emitters+1] = emitter
end


-- TODO: Call at the end of a level
function M.clean_explosions()
    for i=1,#emitters do
        local emitter = emitters[i]
        -- emitter:removeSelf()
        emitter:stop( )
        timer.performWithDelay( 250, function()
            emitter:removeSelf( )
        end )
    end
    emitters = {}
end


return M