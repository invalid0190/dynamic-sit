local cooldown = false
local isUsing = false
local debugPoints = {}
local currentSitData = nil -- For persistent debug visualization

-- PERSISTENT DEBUG HELPERS
local function AddDebugPoint(p1, p2, color, type)
    if not Config.Debug then return end
    table.insert(debugPoints,
        { p1 = p1, p2 = p2, color = color or { 255, 0, 0 }, type = type, time = GetGameTimer() + 15000 })
end

CreateThread(function()
    while true do
        Wait(0)
        if Config.Debug then
            -- 1. Draw temporary raycast points
            if #debugPoints > 0 then
                local now = GetGameTimer()
                for i = #debugPoints, 1, -1 do
                    local p = debugPoints[i]
                    if now > p.time then
                        table.remove(debugPoints, i)
                    else
                        if p.type == "line" then
                            DrawLine(p.p1.x, p.p1.y, p.p1.z, p.p2.x, p.p2.y, p.p2.z, p.color[1], p.color[2], p.color[3],
                                255)
                        end
                    end
                end
            end

            -- 2. Draw persistent sit markers and text
            if isUsing and currentSitData then
                local hit = currentSitData.hit
                local edge = currentSitData.edge
                local spawn = currentSitData.spawn
                local off = currentSitData.off
                local style = currentSitData.style

                -- Live Player Position
                local pPos = GetEntityCoords(PlayerPedId())
                local relX = pPos.x - edge.x
                local relY = pPos.y - edge.y
                local relZ = pPos.z - edge.z

                -- Visual Markers
                DrawMarker(28, hit.x, hit.y, hit.z, 0, 0, 0, 0, 0, 0, 0.1, 0.1, 0.1, 0, 255, 0, 200, false, false, 2) -- Hit (Green)
                DrawMarker(28, edge.x, edge.y, edge.z, 0, 0, 0, 0.12, 0.12, 0.12, 255, 255, 0, 200, false, false, 2)  -- Edge (Yellow)
                DrawMarker(28, spawn.x, spawn.y, spawn.z, 0, 0, 0, 0.15, 0.15, 0.15, 255, 0, 0, 200, false, false, 2) -- Target (Red)

                -- Info Text
                local msg = string.format(
                    "Style: %s\nTarget: F %.2f | Z %.2f\n[LIVE OFFSET FROM YELLOW]\nX: %.2f | Y: %.2f | Z: %.2f",
                    style, off.forward, off.z, relX, relY, relZ)
                DrawText3D(pPos.x, pPos.y, pPos.z + 1.2, msg)
            end
        end
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.08, 41, 11, 41, 90)
    end
end

-- ANIMATION LOADER
local function LoadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

-- GROUND SAFETY check
local function GetSafeZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 1.0, 0)
    return found and groundZ or z
end

-- ADVANCED RAYCAST SYSTEM
local function DetectSurface()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local bestHit = nil

    -- 1. MULTI-RAY VERTICAL SWEEP (Priority 1: Detect walls/benches/props directly)
    local sweepFound = nil
    local highestHitZOff = 0.0
    local shortestDist = 999.0
    local heights = { -0.5, -0.4, -0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3, 0.5, 0.7, 1.0, 1.5 }
    local right = vector3(-forward.y, forward.x, 0.0)
    for _, zOff in ipairs(heights) do
        for _, hOff in ipairs({ 0.0, -0.15, 0.15 }) do
            local startPos = vector3(coords.x + right.x * hOff, coords.y + right.y * hOff, coords.z + zOff)
            local endPos = startPos + (forward * 0.8)
            local ray = StartShapeTestRay(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z, 31, ped, 0)
            local _res, _hit, _hitCoords, _normal, _entity = GetShapeTestResult(ray)
            if _hit == 1 then
                if zOff > highestHitZOff then highestHitZOff = zOff end
                local dist = #(coords - _hitCoords)
                if dist < shortestDist then
                    shortestDist = dist
                    sweepFound = { hitCoords = _hitCoords, normal = _normal, entity = _entity, zOff = zOff }
                end
            end
            if Config.Debug then AddDebugPoint(startPos, endPos, { 255, 0, 0 }, "line") end
        end
    end
    if sweepFound then
        bestHit = sweepFound
        bestHit.highestHitZOff = highestHitZOff
        bestHit.cameFromSweep = true
    end

    -- 2. EDGE-STANDING (Priority 2: Detect low walls directly)
    if not bestHit then
        local edgeStart = vector3(coords.x, coords.y, coords.z + 0.5)
        local edgeEnd = edgeStart + (forward * 0.7) + vector3(0, 0, -1.0)
        local edgeRay = StartShapeTestRay(edgeStart.x, edgeStart.y, edgeStart.z, edgeEnd.x, edgeEnd.y, edgeEnd.z, 31, ped,
            0)
        local _res, _hit, _hitCoords, _normal, _entity = GetShapeTestResult(edgeRay)

        if _hit == 1 then
            local groundStart = edgeStart + (forward * 1.0)
            local groundEnd = groundStart + vector3(0, 0, -2.0)
            local gRay = StartShapeTestRay(groundStart.x, groundStart.y, groundStart.z, groundEnd.x, groundEnd.y,
                groundEnd.z, 31, ped, 0)
            local _, gHit = GetShapeTestResult(gRay)
            if Config.Debug then AddDebugPoint(groundStart, groundEnd, { 0, 255, 0 }, "line") end
            if not gHit or gHit == 0 then
                bestHit = { hitCoords = _hitCoords, edge = _hitCoords, normal = -forward, entity = _entity, highestHitZOff = 0.0, cameFromSweep = false, cameFromStanding = true }
            end
        end
        if Config.Debug then AddDebugPoint(edgeStart, edgeEnd, { 255, 120, 0 }, "line") end
    end

    -- 3. EDGE-LOOKOUT (Priority 3: Detect drop-offs/roof edges)
    if not bestHit then
        local foundFloorOnce = false
        -- START SCAN FROM BEHIND THE PLAYER (-1.0m) TO ESTABLISH FLOOR BASELINE
        for i = -10, 15 do
            local dist = i * 0.1
            local scanStart = coords + (forward * dist) + vector3(0, 0, 0.45)
            local scanEnd = scanStart + vector3(0, 0, -2.2)

            -- Multi-height check to ensure we hit the 1-sided collision
            local ray = StartShapeTestRay(scanStart.x, scanStart.y, scanStart.z, scanEnd.x, scanEnd.y, scanEnd.z, 31, ped,
                0)
            local _res, _hit = GetShapeTestResult(ray)

            if _hit == 1 then
                foundFloorOnce = true
            elseif _hit == 0 and foundFloorOnce then
                -- REAL DROP FOUND (Must be in front of player range)
                local skip = false
                if dist < 0.05 then skip = true end -- Too close to feet, could be clipping

                if not skip then
                    local foundExact = false
                    for back = 1, 10 do
                        local subDist = dist - (back * 0.01)
                        local subStart = coords + (forward * subDist) + vector3(0, 0, 0.45)
                        local subEnd = subStart + vector3(0, 0, -1.2)
                        local subRay = StartShapeTestRay(subStart.x, subStart.y, subStart.z, subEnd.x, subEnd.y, subEnd
                            .z, 31, ped, 0)
                        local _, subHit = GetShapeTestResult(subRay)
                        if subHit == 1 then
                            local finalEdge = coords + (forward * subDist)
                            bestHit = { hitCoords = finalEdge, edge = finalEdge, normal = -forward, entity = 0, highestHitZOff = 0.0, cameFromSweep = false }
                            foundExact = true
                            break
                        end
                    end
                    if not foundExact then
                        local finalEdge = coords + (forward * (dist - 0.1))
                        bestHit = { hitCoords = finalEdge, edge = finalEdge, normal = -forward, entity = 0, highestHitZOff = 0.0, cameFromSweep = false }
                    end
                    break
                end
            end
            if Config.Debug then AddDebugPoint(scanStart, scanEnd, { 255, 0, 0 }, "line") end
        end
    end

    -- 4. FINAL GROUND FALLBACK (Priority 4)
    local isGround = false
    if not bestHit then
        local gStart = coords + vector3(0, 0, 0.5)
        local gEnd = coords + vector3(0, 0, -1.0)
        local gRay = StartShapeTestRay(gStart.x, gStart.y, gStart.z, gEnd.x, gEnd.y, gEnd.z, 31, ped, 0)
        local _, gHit, gHitCoords = GetShapeTestResult(gRay)
        if gHit == 1 then
            bestHit = { hitCoords = gHitCoords, normal = forward * -1.0, entity = 0, edge = gHitCoords, highestHitZOff = 0.0, cameFromSweep = false }
            isGround = true
        else
            return nil
        end
    end

    local hitCoords = bestHit.hitCoords
    local normal = bestHit.normal
    local entity = bestHit.entity
    local highestHitZOff = bestHit.highestHitZOff or 0.0

    -- 5. EDGE SCAN (Surface detection for non-ground hits)
    local bestTop = bestHit.edge
    if not isGround and not bestTop then
        local highestZ = -99.0
        for i = 0, 18 do
            local depth = (i - 3) * 0.04
            local testPoint = hitCoords + (forward * depth)
            local downStart = vector3(testPoint.x, testPoint.y, hitCoords.z + 1.5)
            local downEnd = vector3(testPoint.x, testPoint.y, hitCoords.z - 1.0)
            local ray2 = StartShapeTestRay(downStart.x, downStart.y, downStart.z, downEnd.x, downEnd.y, downEnd.z, 31,
                ped, 0)
            local _, hit2, topCoords, topNormal, entity2 = GetShapeTestResult(ray2)
            if Config.Debug then AddDebugPoint(downStart, downEnd, { 255, 255, 0 }, "line") end
            if hit2 == 1 then
                local hDiff = topCoords.z - hitCoords.z
                if topCoords.z > highestZ and hDiff < 0.8 and hDiff > -0.4 then
                    highestZ = topCoords.z
                    bestTop = topCoords
                end
            end
        end
    end

    local isLeanFallback = false
    if not bestTop then
        if #(coords - hitCoords) < 1.0 then
            bestTop = vector3(hitCoords.x, hitCoords.y, hitCoords.z)
            isLeanFallback = true
        else
            return nil
        end
    end
    if Config.Debug then AddDebugPoint(bestTop, nil, "edge") end

    -- 6. FALL-CHECK: Vertical ray from seat down
    local isFallLedge = false
    if not isGround then
        local downRayStart = vector3(bestTop.x, bestTop.y, bestTop.z + 0.1)
        local downRayEnd = vector3(bestTop.x, bestTop.y, bestTop.z - 2.5)
        local downRay = StartShapeTestRay(downRayStart.x, downRayStart.y, downRayStart.z, downRayEnd.x, downRayEnd.y,
            downRayEnd.z, 31, ped, 0)
        local _, hitDown, hitDownCoords = GetShapeTestResult(downRay)
        local fallDist = (hitDown == 1) and #(downRayStart - hitDownCoords) or 3.0
        if hitDown == 0 or fallDist > 0.9 then
            isFallLedge = true
        end
        if Config.Debug then AddDebugPoint(downRayStart, downRayEnd, { 0, 255, 255 }, "line") end
    end

    return {
        hitCoords = hitCoords,
        edge = bestTop,
        normal = normal,
        entity = entity ~= 0 and entity or 0,
        isLeanFallback = isLeanFallback,
        highestHitZOff = highestHitZOff,
        isFallLedge = isFallLedge,
        cameFromSweep = bestHit.cameFromSweep or false,
        cameFromStanding = bestHit.cameFromStanding or false,
        isGround = isGround
    }
end

-- MAIN COMMAND
RegisterCommand("sit", function()
    if cooldown or isUsing then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end

    local data = DetectSurface()
    if not data then return end

    local playerCoords = GetEntityCoords(ped)
    local playerHeading = GetEntityHeading(ped)
    local hitCoords = data.hitCoords
    local edge = data.edge

    local diff = vector3(playerCoords.x - hitCoords.x, playerCoords.y - hitCoords.y, 0.0)
    local normal = norm(diff)
    if #diff < 0.01 then normal = GetEntityForwardVector(ped) * -1.0 end

    local groundZ = GetSafeZ(playerCoords.x, playerCoords.y, playerCoords.z)
    local height = edge.z - groundZ
    local style, offset

    -- Style classification (Priority: Physical Objects > Falls > Ground)
    if not data.isGround and not data.isFallLedge and data.highestHitZOff >= 1.0 then
        style = "lean"
    elseif data.cameFromSweep or data.cameFromStanding then
        style = "ledge" -- Consolidating Bench and Ledge
    elseif data.isFallLedge then
        style = "edge_fall"
    elseif data.isGround then
        style = "ground"
    else
        style = "ledge"
    end
    offset = Config.Offsets[style] or Config.Offsets.ledge

    -- Final Calibration Logic
    local sitOffset = offset.forward
    if style == "edge_fall" then sitOffset = 0.25 end -- Snap exactly to the detected brink

    local forwardOffset = (style == "lean") and 0.12 or sitOffset
    local zOffset = offset.z or 0.0
    local spawnPos = vector3(
        hitCoords.x + (normal.x * forwardOffset),
        hitCoords.y + (normal.y * forwardOffset),
        edge.z - zOffset
    )
    if style == "lean" then spawnPos = vector3(spawnPos.x, spawnPos.y, playerCoords.z) end

    local finalHeading = GetHeadingFromVector_2d(normal.x, normal.y)

    -- Face THE FALL: Rotate 180 degrees if we are sitting ON a wall/edge looking out
    if style == "edge_fall" then
        finalHeading = (finalHeading + 180.0) % 360.0
    end


    local selectedScenario = nil
    if style == "bench" or style == "ledge" or style == "edge_fall" then
        selectedScenario = Config.Scenarios[math.random(#Config.Scenarios)]
        FreezeEntityPosition(ped, true) -- HIGH STABILITY PRE-TELEPORT FREEZE
        SetEntityCollision(ped, false, false)
        SetEntityHeading(ped, finalHeading)
        SetEntityCoords(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)
        Wait(50)
        TaskStartScenarioInPlace(ped, selectedScenario, 0, true)
        SetEntityCollision(ped, true, true)
    elseif style == "lean" then
        selectedScenario = "WORLD_HUMAN_LEANING"
        TaskStartScenarioAtPosition(ped, selectedScenario, spawnPos.x, spawnPos.y, spawnPos.z, finalHeading, 0, true,
            true)
    elseif style == "ground" then
        selectedScenario = "WORLD_HUMAN_PICNIC"
        TaskStartScenarioAtPosition(ped, selectedScenario, spawnPos.x, spawnPos.y, spawnPos.z, finalHeading, 0, true,
            true)
    else
        selectedScenario = "WORLD_HUMAN_PICNIC"
        TaskStartScenarioAtPosition(ped, selectedScenario, spawnPos.x, spawnPos.y, spawnPos.z, finalHeading, 0, true,
            true)
    end


    LocalPlayer.state:set('sitData', {
        coords = spawnPos,
        heading = finalHeading,
        scenario = selectedScenario
    }, true)
    isUsing = true
    currentSitData = {
        hit = hitCoords,
        edge = edge,
        spawn = spawnPos,
        off = offset,
        style = style,
        origCoords =
            playerCoords,
        origHeading = playerHeading
    }
    cooldown = true
    SetTimeout(1500, function() cooldown = false end)
end)

function norm(v)
    local m = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    if m < 0.0001 then return vector3(0, 0, 0) end
    return vector3(v.x / m, v.y / m, v.z / m)
end

local function ResetPlayer()
    local ped = PlayerPedId()
    if not isUsing then return end
    FreezeEntityPosition(ped, false)

    if currentSitData and currentSitData.style == "edge_fall" and currentSitData.origCoords then
        -- Teleport back to safety for edge falls
        local oc = currentSitData.origCoords
        SetEntityCoords(ped, oc.x, oc.y, oc.z, false, false, false, false)
        if currentSitData.origHeading then
            SetEntityHeading(ped, currentSitData.origHeading)
        end
    end

    -- Let GTA handle the proper native scenario exit for others, but clear tasks
    ClearPedTasks(ped)

    isUsing = false
    currentSitData = nil
    LocalPlayer.state:set('sitData', nil, true)
end

RegisterCommand("stand", ResetPlayer)

CreateThread(function()
    while true do
        Wait(500)
        if isUsing then
            if IsControlPressed(0, 32) or IsControlPressed(0, 33) or IsControlPressed(0, 34) or IsControlPressed(0, 35) then
                ResetPlayer()
            end
        end
    end
end)

AddStateBagChangeHandler("sitData", nil, function(bagName, key, value, _unused, replicated)
    local playerID = GetPlayerFromStateBagName(bagName)
    if playerID == 0 then return end

    local player = GetPlayerFromServerId(playerID)
    if player == -1 then return end

    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return end

    if ped == PlayerPedId() then return end

    if value then
        SetEntityCoords(ped, value.coords.x, value.coords.y, value.coords.z, false, false, false, false)
        SetEntityHeading(ped, value.heading)
        TaskStartScenarioInPlace(ped, value.scenario, 0, true)
    else
        ClearPedTasks(ped)
    end
end)

RegisterCommand("test_ledge", function()
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SEAT_LEDGE", 0, true)
end)

RegisterCommand("clear_ledge", function()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    ClearPedTasksImmediately(ped)
    isUsing = false
    currentSitData = nil
end)
