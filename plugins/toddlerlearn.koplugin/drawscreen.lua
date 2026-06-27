local InputContainer = require("ui/widget/container/inputcontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local TextWidget = require("ui/widget/textwidget")
local Widget = require("ui/widget/widget")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local UIManager = require("ui/uimanager")
local Screen = require("device").screen
local Blitbuffer = require("ffi/blitbuffer")

local TOOLBAR_HEIGHT = 104
local BUTTON_GAP = 8
local BRUSH_WIDTHS = {6, 12, 20}
local TEMPLATES = {"Free", "Trace A", "Trace 1", "Triangle"}
local MAX_STROKES = 100
local MAX_POINTS = 5000

local function paintSegment(bb, x, y, first, second, width, color)
    local dx = second.x - first.x
    local dy = second.y - first.y
    local distance = math.max(math.abs(dx), math.abs(dy))
    local steps = math.max(1, math.ceil(distance / math.max(1, width / 3)))
    local radius = math.max(2, math.floor(width / 2))
    for step = 0, steps do
        local ratio = step / steps
        bb:paintCircle(
            x + math.floor(first.x + dx * ratio + 0.5),
            y + math.floor(first.y + dy * ratio + 0.5),
            radius,
            color
        )
    end
end

local DrawingCanvas = Widget:extend{
    dimen = nil,
    owner = nil,
}

function DrawingCanvas:paintGuide(bb, x, y)
    local template = self.owner:getTemplate()
    if template == "Free" then return end
    local w = self.dimen.w
    local h = self.dimen.h
    local guide = {}
    if template == "Trace A" then
        guide = {
            {{x = w * 0.25, y = h * 0.82}, {x = w * 0.5, y = h * 0.15}},
            {{x = w * 0.5, y = h * 0.15}, {x = w * 0.75, y = h * 0.82}},
            {{x = w * 0.36, y = h * 0.55}, {x = w * 0.64, y = h * 0.55}},
        }
    elseif template == "Trace 1" then
        guide = {
            {{x = w * 0.4, y = h * 0.28}, {x = w * 0.52, y = h * 0.15}},
            {{x = w * 0.52, y = h * 0.15}, {x = w * 0.52, y = h * 0.82}},
            {{x = w * 0.38, y = h * 0.82}, {x = w * 0.66, y = h * 0.82}},
        }
    else
        guide = {
            {{x = w * 0.5, y = h * 0.16}, {x = w * 0.2, y = h * 0.82}},
            {{x = w * 0.2, y = h * 0.82}, {x = w * 0.8, y = h * 0.82}},
            {{x = w * 0.8, y = h * 0.82}, {x = w * 0.5, y = h * 0.16}},
        }
    end
    for _, segment in ipairs(guide) do
        paintSegment(bb, x, y, segment[1], segment[2], 5, Blitbuffer.COLOR_LIGHT_GRAY)
    end
end

function DrawingCanvas:paintTo(bb, x, y)
    bb:paintRect(x, y, self.dimen.w, self.dimen.h, Blitbuffer.COLOR_WHITE)
    self:paintGuide(bb, x, y)
    for _, stroke in ipairs(self.owner.strokes or {}) do
        if #stroke.points == 1 then
            bb:paintCircle(x + stroke.points[1].x, y + stroke.points[1].y,
                math.max(2, math.floor(stroke.width / 2)), Blitbuffer.COLOR_BLACK)
        else
            for index = 2, #stroke.points do
                paintSegment(bb, x, y, stroke.points[index - 1], stroke.points[index],
                    stroke.width, Blitbuffer.COLOR_BLACK)
            end
        end
    end
end

local DrawScreen = InputContainer:extend{
    profile_id = "child1",
}

function DrawScreen:init()
    self.dimen = Geom:new{x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight()}
    self.canvas_dimen = Geom:new{x = 0, y = TOOLBAR_HEIGHT, w = self.dimen.w,
        h = self.dimen.h - TOOLBAR_HEIGHT}
    self.strokes = self.strokes or {}
    self.brush_index = self.brush_index or 2
    self.template_index = self.template_index or 1
    self.point_count = self.point_count or 0
    self.ges_events = {
        DrawTap = {GestureRange:new{ges = "tap", range = self.canvas_dimen}},
        DrawPan = {GestureRange:new{ges = "pan", range = self.canvas_dimen}},
        DrawPanRelease = {GestureRange:new{ges = "pan_release", range = self.canvas_dimen}},
        ModeChooser = {GestureRange:new{ges = "two_finger_tap", range = self.dimen}},
        Close = {GestureRange:new{ges = "two_finger_hold", range = self.dimen}},
    }
    self:renderDrawingScreen()
end

function DrawScreen:getBrushWidth()
    return BRUSH_WIDTHS[self.brush_index]
end

function DrawScreen:getTemplate()
    return TEMPLATES[self.template_index]
end

function DrawScreen:cycleBrush()
    self.brush_index = (self.brush_index % #BRUSH_WIDTHS) + 1
    if self.dimen then self:renderDrawingScreen() end
    return self:getBrushWidth()
end

function DrawScreen:cycleTemplate()
    self.template_index = (self.template_index % #TEMPLATES) + 1
    if self.dimen then self:renderDrawingScreen() end
    return self:getTemplate()
end

function DrawScreen:toCanvasPoint(position)
    if not position then return nil end
    return {
        x = math.max(0, math.min(self.canvas_dimen.w - 1, math.floor(position.x))),
        y = math.max(0, math.min(self.canvas_dimen.h - 1,
            math.floor(position.y - self.canvas_dimen.y))),
    }
end

function DrawScreen:startStroke(position)
    if #self.strokes >= MAX_STROKES or self.point_count >= MAX_POINTS then return false end
    local point = self:toCanvasPoint(position)
    if not point then return false end
    local stroke = {width = self:getBrushWidth(), points = {point}}
    table.insert(self.strokes, stroke)
    self.active_stroke = stroke
    self.point_count = self.point_count + 1
    return true
end

function DrawScreen:addStrokePoint(position)
    if not self.active_stroke or self.point_count >= MAX_POINTS then return false end
    local point = self:toCanvasPoint(position)
    if not point then return false end
    local previous = self.active_stroke.points[#self.active_stroke.points]
    local dx = point.x - previous.x
    local dy = point.y - previous.y
    if dx * dx + dy * dy < 9 then return false end
    table.insert(self.active_stroke.points, point)
    self.point_count = self.point_count + 1
    local margin = self.active_stroke.width
    local region = Geom:new{
        x = math.max(0, math.min(previous.x, point.x) - margin),
        y = math.max(self.canvas_dimen.y,
            self.canvas_dimen.y + math.min(previous.y, point.y) - margin),
        w = math.abs(dx) + margin * 2,
        h = math.abs(dy) + margin * 2,
    }
    if self.dimen then UIManager:setDirty(self, "fast", region) end
    return true
end

function DrawScreen:endStroke(position)
    if not self.active_stroke then return false end
    self:addStrokePoint(position)
    self.active_stroke = nil
    if self.dimen then UIManager:setDirty(self, "partial", self.canvas_dimen) end
    return true
end

function DrawScreen:undo()
    local stroke = table.remove(self.strokes)
    if not stroke then return false end
    self.point_count = math.max(0, self.point_count - #stroke.points)
    self.clear_armed = false
    if self.dimen then self:renderDrawingScreen() end
    return true
end

function DrawScreen:clearDrawing()
    if not self.clear_armed then
        self.clear_armed = true
        if self.dimen then self:renderDrawingScreen() end
        return false
    end
    self.strokes = {}
    self.active_stroke = nil
    self.point_count = 0
    self.clear_armed = false
    if self.dimen then self:renderDrawingScreen() end
    return true
end

function DrawScreen:makeButton(text, callback)
    local width = math.floor((self.dimen.w - BUTTON_GAP * 4) / 5)
    local button = InputContainer:new{dimen = Geom:new{x = 0, y = 0, w = width, h = TOOLBAR_HEIGHT}}
    button.ges_events = {Tap = {GestureRange:new{ges = "tap", range = button.dimen}}}
    button[1] = FrameContainer:new{
        width = width, height = TOOLBAR_HEIGHT, bordersize = 3, padding = 4,
        CenterContainer:new{
            dimen = Geom:new{w = width - 14, h = TOOLBAR_HEIGHT - 14},
            TextWidget:new{text = text, face = Font:getFace("tfont", 24)},
        },
    }
    button.onTap = function() callback() return true end
    return button
end

function DrawScreen:renderDrawingScreen()
    local toolbar = HorizontalGroup:new{align = "center"}
    local controls = {
        {"Modes", function() self:onModeChooser() end},
        {"Brush " .. tostring(self:getBrushWidth()), function() self:cycleBrush() end},
        {self:getTemplate(), function() self:cycleTemplate() end},
        {"Undo", function() self:undo() end},
        {self.clear_armed and "Tap Clear" or "Clear", function() self:clearDrawing() end},
    }
    for index, control in ipairs(controls) do
        table.insert(toolbar, self:makeButton(control[1], control[2]))
        if index < #controls then
            table.insert(toolbar, FrameContainer:new{
                width = BUTTON_GAP, height = TOOLBAR_HEIGHT, bordersize = 0, padding = 0,
                TextWidget:new{text = "", face = Font:getFace("cfont", 8)},
            })
        end
    end
    self.canvas_widget = DrawingCanvas:new{dimen = self.canvas_dimen, owner = self}
    self[1] = FrameContainer:new{
        width = self.dimen.w, height = self.dimen.h, bordersize = 0, padding = 0,
        background = Blitbuffer.COLOR_WHITE,
        require("ui/widget/verticalgroup"):new{align = "center", toolbar, self.canvas_widget},
    }
    UIManager:setDirty(self, "full")
end

function DrawScreen:onDrawTap(_, gesture)
    if self:startStroke(gesture.pos) then self:endStroke(gesture.pos) end
    return true
end

function DrawScreen:onDrawPan(_, gesture)
    if not self.active_stroke then self:startStroke(gesture.start_pos or gesture.pos) end
    self:addStrokePoint(gesture.pos)
    return true
end

function DrawScreen:onDrawPanRelease(_, gesture)
    self:endStroke(gesture.pos)
    return true
end

function DrawScreen:onModeChooser()
    if self.mode_callback then self.mode_callback(self) end
    return true
end

function DrawScreen:onClose()
    return self:onModeChooser()
end

return DrawScreen
