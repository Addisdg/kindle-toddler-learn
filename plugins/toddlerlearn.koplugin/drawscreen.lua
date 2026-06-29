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
local GUIDANCE_HEIGHT = 46
local BUTTON_GAP = 8
local TOOLBAR_BUTTONS = 6
local BRUSH_WIDTHS = {4, 7, 11, 16, 23, 32}
local ERASER_WIDTH = 44
local TOOL_COUNT = #BRUSH_WIDTHS + 1
local TEMPLATES = {
    "Free", "Trace A", "Trace B", "Trace C", "Trace D", "Trace E", "Trace F",
    "Trace 0", "Trace 1", "Trace 2", "Trace 3", "Trace 4", "Trace 5",
    "Triangle", "Square", "Circle", "Face", "House", "Mirror",
}
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

local function paintPath(bb, x, y, points, width, color)
    for index = 2, #points do
        paintSegment(bb, x, y, points[index - 1], points[index], width, color)
    end
end

local function paintTracePath(bb, x, y, points)
    paintPath(bb, x, y, points, 7, Blitbuffer.COLOR_LIGHT_GRAY)
    local start = points[1]
    bb:paintCircle(x + math.floor(start.x + 0.5), y + math.floor(start.y + 0.5),
        11, Blitbuffer.COLOR_LIGHT_GRAY)
end

local function ellipsePath(cx, cy, rx, ry)
    local points = {}
    for step = 0, 32 do
        local angle = math.pi * 2 * step / 32
        points[#points + 1] = {x = cx + math.cos(angle) * rx, y = cy + math.sin(angle) * ry}
    end
    return points
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
    elseif template == "Trace B" then
        guide = {
            {{x = w * 0.3, y = h * 0.15}, {x = w * 0.3, y = h * 0.84}},
        }
        paintTracePath(bb, x, y, {
            {x = w * 0.3, y = h * 0.15}, {x = w * 0.58, y = h * 0.15},
            {x = w * 0.7, y = h * 0.25}, {x = w * 0.58, y = h * 0.47},
            {x = w * 0.3, y = h * 0.47},
        })
        paintTracePath(bb, x, y, {
            {x = w * 0.3, y = h * 0.47}, {x = w * 0.6, y = h * 0.47},
            {x = w * 0.72, y = h * 0.63}, {x = w * 0.58, y = h * 0.84},
            {x = w * 0.3, y = h * 0.84},
        })
    elseif template == "Trace C" then
        paintTracePath(bb, x, y, {
            {x = w * 0.72, y = h * 0.22}, {x = w * 0.58, y = h * 0.13},
            {x = w * 0.36, y = h * 0.2}, {x = w * 0.25, y = h * 0.5},
            {x = w * 0.36, y = h * 0.8}, {x = w * 0.58, y = h * 0.87},
            {x = w * 0.72, y = h * 0.78},
        })
    elseif template == "Trace D" then
        guide = {{{x = w * 0.3, y = h * 0.15}, {x = w * 0.3, y = h * 0.84}}}
        paintTracePath(bb, x, y, {
            {x = w * 0.3, y = h * 0.15}, {x = w * 0.55, y = h * 0.15},
            {x = w * 0.72, y = h * 0.32}, {x = w * 0.72, y = h * 0.67},
            {x = w * 0.55, y = h * 0.84}, {x = w * 0.3, y = h * 0.84},
        })
    elseif template == "Trace E" then
        guide = {
            {{x = w * 0.3, y = h * 0.15}, {x = w * 0.3, y = h * 0.84}},
            {{x = w * 0.3, y = h * 0.15}, {x = w * 0.72, y = h * 0.15}},
            {{x = w * 0.3, y = h * 0.49}, {x = w * 0.62, y = h * 0.49}},
            {{x = w * 0.3, y = h * 0.84}, {x = w * 0.72, y = h * 0.84}},
        }
    elseif template == "Trace F" then
        guide = {
            {{x = w * 0.3, y = h * 0.15}, {x = w * 0.3, y = h * 0.84}},
            {{x = w * 0.3, y = h * 0.15}, {x = w * 0.72, y = h * 0.15}},
            {{x = w * 0.3, y = h * 0.49}, {x = w * 0.62, y = h * 0.49}},
        }
    elseif template == "Trace 0" then
        paintTracePath(bb, x, y, ellipsePath(w * 0.5, h * 0.5, w * 0.22, h * 0.35))
    elseif template == "Trace 1" then
        guide = {
            {{x = w * 0.4, y = h * 0.28}, {x = w * 0.52, y = h * 0.15}},
            {{x = w * 0.52, y = h * 0.15}, {x = w * 0.52, y = h * 0.82}},
            {{x = w * 0.38, y = h * 0.82}, {x = w * 0.66, y = h * 0.82}},
        }
    elseif template == "Trace 2" then
        paintTracePath(bb, x, y, {
            {x = w * 0.32, y = h * 0.28}, {x = w * 0.42, y = h * 0.15},
            {x = w * 0.62, y = h * 0.17}, {x = w * 0.7, y = h * 0.32},
            {x = w * 0.62, y = h * 0.48}, {x = w * 0.3, y = h * 0.82},
            {x = w * 0.72, y = h * 0.82},
        })
    elseif template == "Trace 3" then
        paintTracePath(bb, x, y, {
            {x = w * 0.32, y = h * 0.2}, {x = w * 0.55, y = h * 0.14},
            {x = w * 0.7, y = h * 0.27}, {x = w * 0.55, y = h * 0.48},
            {x = w * 0.7, y = h * 0.65}, {x = w * 0.57, y = h * 0.84},
            {x = w * 0.32, y = h * 0.78},
        })
    elseif template == "Trace 4" then
        guide = {
            {{x = w * 0.64, y = h * 0.84}, {x = w * 0.64, y = h * 0.15}},
            {{x = w * 0.64, y = h * 0.15}, {x = w * 0.28, y = h * 0.6}},
            {{x = w * 0.28, y = h * 0.6}, {x = w * 0.74, y = h * 0.6}},
        }
    elseif template == "Trace 5" then
        paintTracePath(bb, x, y, {
            {x = w * 0.7, y = h * 0.16}, {x = w * 0.34, y = h * 0.16},
            {x = w * 0.3, y = h * 0.48}, {x = w * 0.56, y = h * 0.45},
            {x = w * 0.72, y = h * 0.58}, {x = w * 0.65, y = h * 0.8},
            {x = w * 0.34, y = h * 0.84},
        })
    elseif template == "Triangle" then
        guide = {
            {{x = w * 0.5, y = h * 0.16}, {x = w * 0.2, y = h * 0.82}},
            {{x = w * 0.2, y = h * 0.82}, {x = w * 0.8, y = h * 0.82}},
            {{x = w * 0.8, y = h * 0.82}, {x = w * 0.5, y = h * 0.16}},
        }
    elseif template == "Square" then
        guide = {
            {{x = w * 0.24, y = h * 0.22}, {x = w * 0.76, y = h * 0.22}},
            {{x = w * 0.76, y = h * 0.22}, {x = w * 0.76, y = h * 0.78}},
            {{x = w * 0.76, y = h * 0.78}, {x = w * 0.24, y = h * 0.78}},
            {{x = w * 0.24, y = h * 0.78}, {x = w * 0.24, y = h * 0.22}},
        }
    elseif template == "Circle" then
        paintTracePath(bb, x, y, ellipsePath(w * 0.5, h * 0.5, w * 0.28, h * 0.34))
    elseif template == "Face" then
        paintPath(bb, x, y, ellipsePath(w * 0.5, h * 0.48, w * 0.27, h * 0.34),
            5, Blitbuffer.COLOR_LIGHT_GRAY)
        paintPath(bb, x, y, ellipsePath(w * 0.41, h * 0.4, 9, 12),
            5, Blitbuffer.COLOR_LIGHT_GRAY)
        paintPath(bb, x, y, ellipsePath(w * 0.59, h * 0.4, 9, 12),
            5, Blitbuffer.COLOR_LIGHT_GRAY)
    elseif template == "House" then
        guide = {
            {{x = w * 0.28, y = h * 0.42}, {x = w * 0.28, y = h * 0.82}},
            {{x = w * 0.28, y = h * 0.82}, {x = w * 0.72, y = h * 0.82}},
            {{x = w * 0.72, y = h * 0.82}, {x = w * 0.72, y = h * 0.42}},
            {{x = w * 0.44, y = h * 0.82}, {x = w * 0.44, y = h * 0.62}},
            {{x = w * 0.44, y = h * 0.62}, {x = w * 0.56, y = h * 0.62}},
            {{x = w * 0.56, y = h * 0.62}, {x = w * 0.56, y = h * 0.82}},
        }
    else
        local center = math.floor(w / 2)
        for top = math.floor(h * 0.08), math.floor(h * 0.92), 34 do
            paintSegment(bb, x, y,
                {x = center, y = top},
                {x = center, y = math.min(top + 18, math.floor(h * 0.92))},
                4, Blitbuffer.COLOR_LIGHT_GRAY)
        end
    end
    for _, segment in ipairs(guide) do
        paintSegment(bb, x, y, segment[1], segment[2], 7, Blitbuffer.COLOR_LIGHT_GRAY)
        bb:paintCircle(x + math.floor(segment[1].x + 0.5),
            y + math.floor(segment[1].y + 0.5), 11, Blitbuffer.COLOR_LIGHT_GRAY)
    end
end

function DrawingCanvas:paintStroke(bb, x, y, stroke, mirrored)
    local color = stroke.eraser and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
    local function pointAt(index)
        local point = stroke.points[index]
        if not mirrored then return point end
        return {x = self.dimen.w - 1 - point.x, y = point.y}
    end
    if #stroke.points == 1 then
        local point = pointAt(1)
        bb:paintCircle(x + point.x, y + point.y,
            math.max(2, math.floor(stroke.width / 2)), color)
    else
        for index = 2, #stroke.points do
            paintSegment(bb, x, y, pointAt(index - 1), pointAt(index), stroke.width, color)
        end
    end
end

function DrawingCanvas:paintTo(bb, x, y)
    bb:paintRect(x, y, self.dimen.w, self.dimen.h, Blitbuffer.COLOR_WHITE)
    self:paintGuide(bb, x, y)
    for _, stroke in ipairs(self.owner.strokes or {}) do
        self:paintStroke(bb, x, y, stroke, false)
        if stroke.mirror then self:paintStroke(bb, x, y, stroke, true) end
    end
end

local DrawScreen = InputContainer:extend{
    profile_id = "child1",
}

function DrawScreen:init()
    self.dimen = Geom:new{x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight()}
    self.canvas_dimen = Geom:new{x = 0, y = TOOLBAR_HEIGHT + GUIDANCE_HEIGHT,
        w = self.dimen.w, h = self.dimen.h - TOOLBAR_HEIGHT - GUIDANCE_HEIGHT}
    self.strokes = self.strokes or {}
    self.brush_index = self.brush_index or 4
    self.template_index = self.template_index or 1
    self.point_count = self.point_count or 0
    self.redo_strokes = self.redo_strokes or {}
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
    return BRUSH_WIDTHS[self.brush_index] or ERASER_WIDTH
end

function DrawScreen:getToolLabel()
    if self.brush_index > #BRUSH_WIDTHS then return "Eraser" end
    return "Brush " .. tostring(self:getBrushWidth())
end

function DrawScreen:getTemplate()
    return TEMPLATES[self.template_index]
end

function DrawScreen:getTemplateInstruction()
    local template = self:getTemplate()
    if string.sub(template, 1, 5) == "Trace" then
        return "Start at a dot and follow the gray line"
    elseif template == "Face" then
        return "Finish the face"
    elseif template == "House" then
        return "Add a roof and finish the house"
    elseif template == "Mirror" then
        return "Draw on one side to make a mirror picture"
    elseif template == "Free" then
        return "Draw anything you imagine"
    end
    return "Start at a dot and follow the shape"
end

function DrawScreen:cycleBrush()
    self.brush_index = (self.brush_index % TOOL_COUNT) + 1
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
    local stroke = {
        width = self:getBrushWidth(),
        eraser = self.brush_index > #BRUSH_WIDTHS,
        mirror = self:getTemplate() == "Mirror",
        points = {point},
    }
    table.insert(self.strokes, stroke)
    self.redo_strokes = {}
    self.active_stroke = stroke
    self.point_count = self.point_count + 1
    return true
end

function DrawScreen:addStrokePoint(position)
    if not self.active_stroke or self.point_count >= MAX_POINTS then return false end
    local point = self:toCanvasPoint(position)
    if not point then return false end
    local previous = self.active_stroke.points[#self.active_stroke.points]
    local raw_dx = point.x - previous.x
    local raw_dy = point.y - previous.y
    if raw_dx * raw_dx + raw_dy * raw_dy < 4 then return false end
    point = {
        x = math.floor((previous.x + point.x * 4) / 5 + 0.5),
        y = math.floor((previous.y + point.y * 4) / 5 + 0.5),
    }
    local dx = point.x - previous.x
    local dy = point.y - previous.y
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
    if self.dimen then
        UIManager:setDirty(self, "fast", region)
        if self.active_stroke.mirror then
            UIManager:setDirty(self, "fast", Geom:new{
                x = math.max(0, self.canvas_dimen.w - region.x - region.w),
                y = region.y,
                w = region.w,
                h = region.h,
            })
        end
    end
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
    table.insert(self.redo_strokes, stroke)
    self.point_count = math.max(0, self.point_count - #stroke.points)
    self.clear_armed = false
    if self.dimen then self:renderDrawingScreen() end
    return true
end

function DrawScreen:redo()
    local stroke = self.redo_strokes[#self.redo_strokes]
    if not stroke or #self.strokes >= MAX_STROKES
            or self.point_count + #stroke.points > MAX_POINTS then
        return false
    end
    table.remove(self.redo_strokes)
    table.insert(self.strokes, stroke)
    self.point_count = self.point_count + #stroke.points
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
    self.redo_strokes = {}
    self.clear_armed = false
    if self.dimen then self:renderDrawingScreen() end
    return true
end

function DrawScreen:makeButton(text, callback)
    local width = math.floor((self.dimen.w - BUTTON_GAP * (TOOLBAR_BUTTONS - 1))
        / TOOLBAR_BUTTONS)
    local button = InputContainer:new{dimen = Geom:new{x = 0, y = 0, w = width, h = TOOLBAR_HEIGHT}}
    button.ges_events = {Tap = {GestureRange:new{ges = "tap", range = button.dimen}}}
    button[1] = FrameContainer:new{
        width = width, height = TOOLBAR_HEIGHT, bordersize = 3, padding = 4,
        CenterContainer:new{
            dimen = Geom:new{w = width - 14, h = TOOLBAR_HEIGHT - 14},
            TextWidget:new{text = text, face = Font:getFace("tfont", 22)},
        },
    }
    button.onTap = function() callback() return true end
    return button
end

function DrawScreen:renderDrawingScreen()
    local toolbar = HorizontalGroup:new{align = "center"}
    local controls = {
        {"Modes", function() self:onModeChooser() end},
        {self:getToolLabel(), function() self:cycleBrush() end},
        {self:getTemplate(), function() self:cycleTemplate() end},
        {"Undo", function() self:undo() end},
        {"Redo", function() self:redo() end},
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
    local guidance = CenterContainer:new{
        dimen = Geom:new{w = self.dimen.w, h = GUIDANCE_HEIGHT},
        TextWidget:new{text = self:getTemplateInstruction(), face = Font:getFace("tfont", 22)},
    }
    self.canvas_widget = DrawingCanvas:new{dimen = self.canvas_dimen, owner = self}
    self[1] = FrameContainer:new{
        width = self.dimen.w, height = self.dimen.h, bordersize = 0, padding = 0,
        background = Blitbuffer.COLOR_WHITE,
        require("ui/widget/verticalgroup"):new{
            align = "center", toolbar, guidance, self.canvas_widget,
        },
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
