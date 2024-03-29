------------------------------------------------------------------------------------------
-- AUTOSCROLL WITH MOUSE WHEEL BUTTON
-- timginter @ GitHub
------------------------------------------------------------------------------------------

-- id of mouse wheel button
local mouseScrollButtonId = 2

-- scroll speed and direction config
local scrollSpeedMultiplier = 0.15
local scrollSpeedHorizontalMultiplier = scrollSpeedMultiplier
local scrollSpeedVerticalMultiplier = scrollSpeedMultiplier
local scrollSpeedSquareAcceleration = false
local scrollSpeedPowerFactor = 2
local reverseVerticalScrollDirection = false
local mouseScrollTimerDelay = 0.01
local fractionalScrolling = true

-- circle config
local mouseScrollCircleRad = 10
local mouseScrollCircleDeadZone = 5

------------------------------------------------------------------------------------------

local mouseScrollCircle = nil
local mouseScrollTimer = nil
local mouseScrollStartPos = 0
local mouseScrollDragPosX = nil
local mouseScrollDragPosY = nil
local mouseScrollFractionX = 0
local mouseScrollFractionY = 0

overrideScrollMouseDown = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown }, function(e)
    -- uncomment line below to see the ID of pressed button
    --print(e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber']))

    if e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber']) == mouseScrollButtonId then
        -- remove circle if exists
        if mouseScrollCircle then
            mouseScrollCircle:delete()
            mouseScrollCircle = nil
        end

        -- stop timer if running
        if mouseScrollTimer then
            mouseScrollTimer:stop()
            mouseScrollTimer = nil
        end

        -- save mouse coordinates
        mouseScrollStartPos = hs.mouse.absolutePosition()
        mouseScrollDragPosX = mouseScrollStartPos.x
        mouseScrollDragPosY = mouseScrollStartPos.y

        -- start scroll timer
        mouseScrollTimer = hs.timer.doAfter(mouseScrollTimerDelay, mouseScrollTimerFunction)

        -- don't send scroll button down event
        return true
    end
end)

overrideScrollMouseUp = hs.eventtap.new({ hs.eventtap.event.types.otherMouseUp }, function(e)
    if e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber']) == mouseScrollButtonId then
        -- send original button up event if released within 'mouseScrollCircleDeadZone' pixels of original position and scroll circle doesn't exist
        mouseScrollPos = hs.mouse.absolutePosition()
        xDiff = math.abs(mouseScrollPos.x - mouseScrollStartPos.x)
        yDiff = math.abs(mouseScrollPos.y - mouseScrollStartPos.y)
        if (xDiff < mouseScrollCircleDeadZone and yDiff < mouseScrollCircleDeadZone) and not mouseScrollCircle then
            -- disable scroll mouse override
            overrideScrollMouseDown:stop()
            overrideScrollMouseUp:stop()

            -- send scroll mouse click
            hs.eventtap.otherClick(e:location(), mouseScrollButtonId)

            -- re-enable scroll mouse override
            overrideScrollMouseDown:start()
            overrideScrollMouseUp:start()
        end

        -- remove circle if exists
        if mouseScrollCircle then
            mouseScrollCircle:delete()
            mouseScrollCircle = nil
        end

        -- stop timer if running
        if mouseScrollTimer then
            mouseScrollTimer:stop()
            mouseScrollTimer = nil
        end

        -- don't send scroll button up event
        return true
    end
end)

overrideScrollMouseDrag = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDragged }, function(e)
    -- sanity check
    if mouseScrollDragPosX == nil or mouseScrollDragPosY == nil then
        return true
    end

    -- update mouse coordinates
    mouseScrollDragPosX = mouseScrollDragPosX + e:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
    mouseScrollDragPosY = mouseScrollDragPosY + e:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])

    -- don't send scroll button drag event
    return true
end)

function mouseScrollTimerFunction()
    -- sanity check
    if mouseScrollDragPosX ~= nil and mouseScrollDragPosY ~= nil then
        -- get cursor position difference from original click
        xDiff = math.abs(mouseScrollDragPosX - mouseScrollStartPos.x)
        yDiff = math.abs(mouseScrollDragPosY - mouseScrollStartPos.y)

        -- draw circle if not yet drawn and cursor moved more than 'mouseScrollCircleDeadZone' pixels
        if mouseScrollCircle == nil and (xDiff > mouseScrollCircleDeadZone or yDiff > mouseScrollCircleDeadZone) then
            mouseScrollCircle = hs.drawing.circle(hs.geometry.rect(mouseScrollStartPos.x - mouseScrollCircleRad, mouseScrollStartPos.y - mouseScrollCircleRad, mouseScrollCircleRad * 2, mouseScrollCircleRad * 2))
            mouseScrollCircle:setStrokeColor({["red"]=0.3, ["green"]=0.3, ["blue"]=0.3, ["alpha"]=1})
            mouseScrollCircle:setFill(false)
            mouseScrollCircle:setStrokeWidth(1)
            mouseScrollCircle:show()
        end

        -- send scroll event if cursor moved more than circle's radius
        if xDiff > mouseScrollCircleRad or yDiff > mouseScrollCircleRad then
            -- get real xDiff and yDiff
            deltaX = mouseScrollDragPosX - mouseScrollStartPos.x
            deltaY = mouseScrollDragPosY - mouseScrollStartPos.y
            signX = deltaX > 0 and 1 or (deltaX == 0 and 0 or -1)
            signY = deltaY > 0 and 1 or (deltaY == 0 and 0 or -1)

            -- create "no scroll row/column" to allow scroll only horizontally or vertically
            deltaX = deltaX - signX * math.min(xDiff, mouseScrollCircleRad)
            deltaY = deltaY - signY * math.min(yDiff, mouseScrollCircleRad)

            -- use 'scrollSpeedHorizontalMultiplier' and 'scrollSpeedVerticalMultiplier'
            deltaX = deltaX * scrollSpeedHorizontalMultiplier
            deltaY = deltaY * scrollSpeedVerticalMultiplier

            -- square for better scroll acceleration
            if scrollSpeedSquareAcceleration then
                deltaX = math.abs(deltaX) ^ scrollSpeedPowerFactor * signX
                deltaY = math.abs(deltaY) ^ scrollSpeedPowerFactor * signY
            end

            -- save the fractions if scrolling speed is lower than 1
            if fractionalScrolling then
                if -1 < deltaX and deltaX < 1 then
                    mouseScrollFractionX = mouseScrollFractionX + deltaX
                    if mouseScrollFractionX > 1 or mouseScrollFractionX < -1 then
                        deltaX = mouseScrollFractionX
                        mouseScrollFractionX = 0
                    else
                        deltaX = 0
                    end
                end
                if -1 < deltaY and deltaY < 1 then
                    mouseScrollFractionY = mouseScrollFractionY + deltaY
                    if mouseScrollFractionY > 1 or mouseScrollFractionY < -1 then
                        deltaY = mouseScrollFractionY
                        mouseScrollFractionY = 0
                    else
                        deltaY = 0
                    end
                end
            end

            -- if both X and Y are 0, then skip the update
            if deltaX ~= 0 or deltaY ~= 0 then
                -- math.ceil / math.floor - scroll event accepts only integers
                deltaXRounding = math.ceil
                deltaYRounding = math.ceil

                if deltaX < 0 then
                    deltaXRounding = math.floor
                end
                if deltaY < 0 then
                    deltaYRounding = math.floor
                end

                deltaX = deltaXRounding(deltaX)
                deltaY = deltaYRounding(deltaY)

                -- reverse Y scroll if 'reverseVerticalScrollDirection' set to true
                if reverseVerticalScrollDirection then
                    deltaY = deltaY * -1
                end

                -- send scroll event
                hs.eventtap.event.newScrollEvent({-deltaX, deltaY}, {}, 'pixel'):post()
            end
        end
    end

    -- restart timer
    mouseScrollTimer = hs.timer.doAfter(mouseScrollTimerDelay, mouseScrollTimerFunction)
end

-- start override functions
overrideScrollMouseDown:start()
overrideScrollMouseUp:start()
overrideScrollMouseDrag:start()

------------------------------------------------------------------------------------------
-- END OF AUTOSCROLL WITH MOUSE WHEEL BUTTON
------------------------------------------------------------------------------------------
