local RESULT, HEADING, ENTITY, NAME, COORDS, PREVIOUS, ZONE, PREVIOUSZONE, SCALEX, SCALEY, SCALEZ
local laserEnabled = false
local laserEndPoint = nil
lib.hideTextUI()
local function roundcord(value, numDecimalPlaces)
	if not numDecimalPlaces then return math.floor(value + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((value * power) + 0.5) / (power)
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
			tostring(roundcord(zone.center.x, 2)) ..
			", " .. tostring(roundcord(zone.center.y, 2)) .. ", " .. tostring(roundcord(zone.center.z, 2)) .. "),\n"
			.. "\tlength = " .. tostring(SCALEX) .. ",\n"
			.. "\twidth = " .. tostring(SCALEY) .. ",\n"
			.. "\tname = \"" .. zone.name .. "\",\n"
			.. "\theading = " .. tostring(HEADING) .. ",\n"
			.. "\tminZ = " .. tostring(roundcord(zone.minZ, 2)) .. ",\n"
			.. "\tmaxZ = " .. tostring(roundcord(zone.maxZ, 2)) .. ",\n"
			.. "}\n"
end

local function destoryZone()
	if ZONE then ZONE:destroy() end
end

local function drawEntityZone()
	destoryZone()
	ZONE = EntityZone:Create(ENTITY, {
		name = NAME,
		debugPoly = true,
		useZ = true,
		scale = scale or { SCALEX, SCALEY, SCALEZ }
	})
end

function createEntity()
	local input = lib.inputDialog('Dialog title', {
		{type = 'input', label = 'Zone Name', description = 'Enter Zone name', required = true, min = 4, max = 16},
		{type = 'number', label = 'Width X', description = 'Enter width size',  required = true, icon = 'hashtag'},
		{type = 'number', label = 'Height Y', description = 'Enter height size',  required = true, icon = 'hashtag'},
		{type = 'number', label = 'Height Z', description = 'Enter height for Z',  required = true, icon = 'hashtag'},
	  })
	if not input then return end
	print(json.encode(input), input[1], input[2])
	local modelName = "prop_parking_sign_1"
	NAME = input[1]
	SCALEX = input[2]
	SCALEY = input[3]
	SCALEZ = input[4]
	if DoesEntityExist(ENTITY) then
		DeleteEntity(ENTITY)
	end
    RequestModel(modelName)
    while not HasModelLoaded(modelName) do
        Wait(500)
    end
    ENTITY = CreateObject(modelName, laserEndPoint.x, laserEndPoint.y, laserEndPoint.z, true, true, true)
	SetEntityHeading(ENTITY, HEADING)
	Wait(100)
	drawEntityZone()
end

function saveZone()
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
		if DoesEntityExist(ENTITY) then
			DeleteEntity(ENTITY)
		end
		destoryZone()
	end
end

-- Function to draw the laser effect
function drawLaser()
	local playerPed    = PlayerPedId()
	lib.showTextUI("CONTROLS : [N] vector2 | [E] vector3 | [Q] vector4 | [F] coords | [R] Json | [H] Heading | [G] Add Zone | [X] Save Zone", {position = 'top-center'})
    while laserEnabled do
		local color = { r = 255, g = 255, b = 255, a = 200 }
		local position = GetEntityCoords(playerPed)
		local hit, coords, entity = RayCastGamePlayCamera(1000.0)
		local heading = GetEntityHeading(GetPlayerPed(-1))
		local x = roundcord(coords.x, 2)
		local y = roundcord(coords.y, 2)
		local z = roundcord(coords.z, 2)
		local w = roundcord(heading, 2)
		HEADING = w
		if IsControlJustReleased(0, 73) then --save zone
			saveZone()
			Wait(1000)
		end
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
			local x = roundcord(coords.x, 2)
			local y = roundcord(coords.y, 2)
			local z = roundcord(coords.z, 2)
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
		Wait(10)
    end
	lib.hideTextUI()
end

RegisterNetEvent('polygun:runlaser', function()
	laserEnabled = not laserEnabled
    if not laserEnabled then
		laserEndPoint = nil
		if DoesEntityExist(ENTITY) then
			DeleteEntity(ENTITY)
		end
		destoryZone()
		-- If the vehicle does exist, delete the vehicle entity from the game world.


	else
		drawLaser()
	end
end)