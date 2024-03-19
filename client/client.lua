local RESULT, HEADING, ENTITY, NAME, COORDS, PREVIOUS, ZONE, PREVIOUSZONE, SCALEX, SCALEY, SCALEZ
local laserEnabled = false
local laserEndPoint = nil
local hashes_file = LoadResourceFile(GetCurrentResourceName(), "hashes.json")
local hashes = json.decode(hashes_file)
lib.hideTextUI()
local function round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local RotationToDirection = function(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end
local RayCastGamePlayCamera = function(distance)
    -- Checks to see if the Gameplay Cam is Rendering or another is rendering (no clip functionality)
    local currentRenderingCam = false
    if not IsGameplayCamRendering() then
        currentRenderingCam = GetRenderingCam()
    end

    local cameraRotation = not currentRenderingCam and GetGameplayCamRot() or GetCamRot(currentRenderingCam, 2)
    local cameraCoord = not currentRenderingCam and GetGameplayCamCoord() or GetCamCoord(currentRenderingCam)
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local _, b, c, _, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

local function parseBox(zone)
	return
			"{\n"
			..
			"\tcoords = " ..
			"vector3(" ..
			tostring(round(zone.center.x, 2)) ..
			", " .. tostring(round(zone.center.y, 2)) .. ", " .. tostring(round(zone.center.z, 2)) .. "),\n"
			.. "\tlength = " .. tostring(SCALEX) .. ",\n"
			.. "\twidth = " .. tostring(SCALEY) .. ",\n"
			.. "\tname = \"" .. zone.name .. "\",\n"
			.. "\theading = " .. tostring(HEADING) .. ",\n"
			.. "\tminZ = " .. tostring(round(zone.minZ, 2)) .. ",\n"
			.. "\tmaxZ = " .. tostring(round(zone.maxZ, 2)) .. ",\n"
			.. "}\n"
end

local function destoryZone()
	if ZONE then ZONE:destroy() end
end

local function drawEntityZone()
	destoryZone()
	if DoesEntityExist(ENTITY) then
		ZONE = EntityZone:Create(ENTITY, {
			name = NAME,
			debugPoly = true,
			useZ = true,
			scale = scale or { SCALEX, SCALEY, SCALEZ }
		})
	end
end

function createEntity()
	local input = lib.inputDialog('Create Zone', {
		{type = 'input', label = 'Zone Name', description = 'Enter Zone name', required = true, min = 4, max = 16, default = "boxzone_"..tostring(math.random(1111,9999))},
		{type = 'number', label = 'Width X', description = 'Enter width size',  required = true, icon = 'hashtag', default = 2},
		{type = 'number', label = 'Height Y', description = 'Enter height size',  required = true, icon = 'hashtag', default = 2},
		{type = 'number', label = 'Height Z', description = 'Enter height for Z',  required = true, icon = 'hashtag', default = 2},
	})
	if not input then return end
	local modelName = "prop_parking_sign_1"
	NAME = input[1]
	SCALEX = input[2]
	SCALEY = input[3]
	SCALEZ = input[4]
	if DoesEntityExist(ENTITY) then
		if GetEntityModel(entity) == GetHashKey("prop_parking_sign_1") then
			DeleteEntity(ENTITY)
		end
	end
	ENTITY = nil
    RequestModel(modelName)
    while not HasModelLoaded(modelName) do
        Wait(500)
    end
    ENTITY = CreateObject(modelName, laserEndPoint.x, laserEndPoint.y, laserEndPoint.z, true, true, true)
	SetEntityHeading(ENTITY, HEADING)
	SetEntityAlpha(ENTITY, 0, false)
	FreezeEntityPosition(ENTITY, true)
	SetEntityCompletelyDisableCollision(ENTITY, false)
	Wait(100)
	drawEntityZone()
end

function saveZone()
	if not Config.loopOn or not ZONE or ZONE == PREVIOUSZONE then return end
	PREVIOUSZONE = ZONE
	if ZONE then
		local text = parseBox(ZONE)
		if Config.clipboard then lib.setClipboard(text) end
		TriggerServerEvent('polygun:save', ZONE, text)
		lib.notify({
			title = 'Box Zone Saved',
			duration = 7500,
			description = 'Check zones.txt inside the polygun resource',
			type = 'success'
		})
		if laserEnabled then
			if DoesEntityExist(ENTITY) then
				DeleteEntity(ENTITY)
			end
		end
	end
	ENTITY = nil
	destoryZone()
	Wait(300)
	RESULT = nil
	laserEnabled = false
end

CreateThread(function()                                  -- Create the thread.
	while true do                                                  -- Loop it infinitely.
		local pause = 250
		local player = PlayerId()
		local playerPed    = PlayerPedId()
		-- If infos are off, set loop to every 250ms. Eats less resources.
		if Config.loopOn then                                        -- If the info is on then...
			pause = 5                                                  -- Only loop every 5ms (equivalent of 200fps).
			if IsPlayerFreeAiming(player) then                         -- If the player is free-aiming (update texts)...
				if RESULT then
					RESULT = nil
				end
				local start = GetPedBoneCoords(PlayerPedId(), 57005, 0.0, 0.0, 0.0)
				local result, entity = GetEntityPlayerIsFreeAimingAt(player) -- Get what the player is aiming at. This isn't actually the function, that's below the thread.
				if result then
					RESULT = result
					ENTITY = entity
					COORDS = GetEntityCoords(ENTITY)
				end
			end
				if RESULT then
					local heading = GetEntityHeading(ENTITY)
					local model = GetEntityModel(ENTITY)
					NAME = hashes[tostring(model)] or 'unknown'
					if Config.debugText then
						DrawInfos("Coordinates: " .. COORDS, "Heading: " .. heading, "Hash: " .. model, "Name: " .. NAME)
					end
					HEADING =heading
					if ENTITY ~= PREVIOUS then
						SCALEX = 1.0
						SCALEY = 1.0
						SCALEZ = 1.0
						drawEntityZone()
						PREVIOUS = ENTITY
					end
					if IsControlJustPressed(0, 241) or IsDisabledControlPressed(1, 241) then -- Scroll Up
						SCALEX = SCALEX + Config.addX
						SCALEY = SCALEY + Config.addY
						SCALEZ = SCALEZ + Config.addZ
						drawEntityZone()
					end
					if IsControlJustPressed(0, 242) or IsDisabledControlPressed(1, 242) then -- Scroll down
						SCALEX = SCALEX - Config.subX
						SCALEY = SCALEY - Config.subY
						SCALEZ = SCALEZ - Config.subZ
						drawEntityZone()
					end

					if IsControlPressed(1, Config.addXControl) or IsDisabledControlPressed(1, Config.addXControl) then -- Up Arrow
						SCALEX = SCALEX + Config.addX
						drawEntityZone()
					end
					if IsControlPressed(1, Config.subXControl) or IsDisabledControlPressed(1, Config.subXControl) then -- Down Arrow
						SCALEX = SCALEX - Config.subZ
						drawEntityZone()
					end

					if IsControlPressed(1, Config.subYControl) or IsDisabledControlPressed(1, Config.subYControl) then -- Left Arrow
						SCALEY = SCALEY - Config.subY
						drawEntityZone()
					end
					if IsControlPressed(1, Config.addYControl) or IsDisabledControlPressed(1, Config.addYControl) then -- Right Arrow
						SCALEY = SCALEY + Config.addY
						drawEntityZone()
					end

					if IsControlPressed(1, Config.addZControl) or IsDisabledControlPressed(1, Config.addZControl) then -- Page Up
						SCALEZ = SCALEZ + Config.addZ
						drawEntityZone()
					end
					if IsControlPressed(1, Config.subZControl) or IsDisabledControlPressed(1, Config.subZControl) then -- Page Down
						SCALEZ = SCALEZ - Config.subZ
						drawEntityZone()
					end
				else
					local color = { r = 0, g = 255, b = 0, a = 200 }
					local position = GetEntityCoords(playerPed)
					local hit, coords, entity = RayCastGamePlayCamera(1000.0)
					local heading = GetEntityHeading(GetPlayerPed(-1))
					local x = round(coords.x, 2)
					local y = round(coords.y, 2)
					local z = round(coords.z, 2)
					local w = round(heading, 2)
					HEADING = w
					if IsControlJustReleased(0, 58) then -- G add zone
						laserEndPoint = coords
						createEntity()
						Wait(1000)
					end
					if IsControlJustReleased(0, 51) then -- Copy Vector3 Coords
						laserEndPoint = string.format('vector3(%s, %s, %s)', x, y, z)
						lib.setClipboard(laserEndPoint)
						lib.notify({
							title = 'Vector 3 Copy',
							duration = 7500,
							description = laserEndPoint,
							type = 'success'
						})
					end
					if IsControlJustReleased(0, 52) then -- Copy Vector4 Coords
						laserEndPoint = string.format('vector4(%s, %s, %s, %s)', x, y, z, w)
						lib.setClipboard(laserEndPoint)
						lib.notify({
							title = 'Vector 4 Copy',
							duration = 7500,
							description = laserEndPoint,
							type = 'success'
						})
					end

					if IsControlJustReleased(0, 306) then --N  Copy Coords

						laserEndPoint = string.format('vector2(%s, %s)', x, y)
						lib.setClipboard(laserEndPoint)
						lib.notify({
							title = 'Vector 2 Copy',
							duration = 7500,
							description = laserEndPoint,
							type = 'success'
						})
					end
					if IsControlJustReleased(0, 45) then -- Copy Coords In json

						laserEndPoint = string.format('{x = %s, y = %s, z = %s, w = %s)', x, y, z, w)
						lib.setClipboard(laserEndPoint)
						lib.notify({
							title = 'Json Copy',
							duration = 7500,
							description = laserEndPoint,
							type = 'success'
						})
					end
					if IsControlJustReleased(0, 74) then -- Copy Heading
						laserEndPoint = string.format('%s', w)
						lib.setClipboard(laserEndPoint)
						lib.notify({
							title = 'Heading Copy',
							duration = 7500,
							description = laserEndPoint,
							type = 'success'
						})
					end

					if IsControlJustReleased(0, 75) then -- Copy Coords without vetor
						local x = round(coords.x, 2)
						local y = round(coords.y, 2)
						local z = round(coords.z, 2)
						laserEndPoint = string.format('%s, %s, %s', x, y, z)
						lib.setClipboard(laserEndPoint)
						lib.notify({
							title = 'Coordinate Copy',
							duration = 7500,
							description = laserEndPoint,
							type = 'success'
						})
					end
					if IsControlJustPressed(0, 241) or IsDisabledControlPressed(1, 241) then -- Scroll Up
						SCALEX = SCALEX + Config.addX
						SCALEY = SCALEY + Config.addY
						SCALEZ = SCALEZ + Config.addZ
						drawEntityZone()
					end
					if IsControlJustPressed(0, 242) or IsDisabledControlPressed(1, 242) then -- Scroll down
						SCALEX = SCALEX - Config.subX
						SCALEY = SCALEY - Config.subY
						SCALEZ = SCALEZ - Config.subZ
						drawEntityZone()
					end

					if IsControlPressed(1, Config.addXControl) or IsDisabledControlPressed(1, Config.addXControl) then -- Up Arrow
						SCALEX = SCALEX + Config.addX
						drawEntityZone()
					end
					if IsControlPressed(1, Config.subXControl) or IsDisabledControlPressed(1, Config.subXControl) then -- Down Arrow
						SCALEX = SCALEX - Config.subZ
						drawEntityZone()
					end

					if IsControlPressed(1, Config.subYControl) or IsDisabledControlPressed(1, Config.subYControl) then -- Left Arrow
						SCALEY = SCALEY - Config.subY
						drawEntityZone()
					end
					if IsControlPressed(1, Config.addYControl) or IsDisabledControlPressed(1, Config.addYControl) then -- Right Arrow
						SCALEY = SCALEY + Config.addY
						drawEntityZone()
					end

					if IsControlPressed(1, Config.addZControl) or IsDisabledControlPressed(1, Config.addZControl) then -- Page Up
						SCALEZ = SCALEZ + Config.addZ
						drawEntityZone()
					end
					if IsControlPressed(1, Config.subZControl) or IsDisabledControlPressed(1, Config.subZControl) then -- Page Down
						SCALEZ = SCALEZ - Config.subZ
						drawEntityZone()
					end
					DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
					DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false, false)
				end
				if IsControlJustReleased(0, 73) then -- Xsave zone
					saveZone()
					Wait(1000)
				end

		end
		Wait(pause)
	end
end)

-- Ends the function.
-- Function to draw the text.
function DrawInfos(...)
	local args = { ... }

	local ypos = Config.ypos
	for k, v in pairs(args) do
		SetTextColour(255, 255, 255, 255) -- Color
		SetTextFont(0)                   -- Font
		SetTextScale(0.4, 0.4)           -- Scale
		SetTextWrap(0.0, 1.0)            -- Wrap the text
		SetTextCentre(false)             -- Align to center(?)
		SetTextDropshadow(0, 0, 0, 0, 255) -- Shadow. Distance, R, G, B, Alpha.
		SetTextEdge(50, 0, 0, 0, 255)    -- Edge. Width, R, G, B, Alpha.
		SetTextOutline()                 -- Necessary to give it an outline.
		SetTextEntry("STRING")
		AddTextComponentString(v)
		DrawText(0.015, ypos) -- Position
		ypos = ypos + 0.028
	end
end

-- Creating the function to toggle the info.
ToggleInfos = function()           -- "ToggleInfos" is a function
	Config.loopOn = not Config.loopOn -- Switch them around
	if laserEnabled then
		laserEndPoint = nil
		if DoesEntityExist(ENTITY) then
			DeleteEntity(ENTITY)
		end
		laserEnabled = false
		destoryZone()
	end
end                                -- Ending the function here.

RegisterNetEvent('polygun:runpolygun', function()
	destoryZone()
	ToggleInfos()
	if Config.loopOn then
		lib.notify({
			title = 'Info',
			duration = 7500,
			description = 'Get Gun In hand and aim to entity',
			type = 'success'
		})
		RESULT = nil
		lib.showTextUI("CONTROLS : [N] vector2 | [E] vector3 | [Q] vector4 | [F] coords | [R] Json | [H] Heading | [G] Add Zone | [X] Save Zone", {position = 'top-center'})
	else
		lib.hideTextUI()
	end
end)