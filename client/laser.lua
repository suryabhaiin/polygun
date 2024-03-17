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
-- Function to draw the laser effect
function drawLaser()
	local playerPed    = PlayerPedId()
	lib.showTextUI("COPY : [E] vector3 | [Q] vector4 | [F] coords | [R] Json | [H] Heading", {position = 'top-center'})
    while laserEnabled do
		local color = { r = 106, g = 255, b = 54, a = 200 }
		local position = GetEntityCoords(playerPed)
		local hit, coords, entity = RayCastGamePlayCamera(1000.0)
		-- If entity is found then verify entity
		if IsControlJustReleased(0, 51) then -- Copy Vector3 Coords
			local x = roundcord(coords.x, 2)
			local y = roundcord(coords.y, 2)
			local z = roundcord(coords.z, 2)
			laserEndPoint = string.format('vector3(%s, %s, %s)', x, y, z)
			lib.setClipboard(laserEndPoint)
			lib.notify({
				title = 'Vector3 Copied',
				duration = 7500,
				description = laserEndPoint,
				type = 'success'
			})
		end
		if IsControlJustReleased(0, 52) then -- Copy Vector4 Coords
			local x = roundcord(coords.x, 2)
			local y = roundcord(coords.y, 2)
			local z = roundcord(coords.z, 2)
			local w = roundcord(GetEntityHeading(GetPlayerPed(-1)), 2)
			laserEndPoint = string.format('vector4(%s, %s, %s, %s)', x, y, z, w)
			lib.setClipboard(laserEndPoint)
			lib.notify({
				title = 'Vector3 Copied',
				duration = 7500,
				description = laserEndPoint,
				type = 'success'
			})
		end
		if IsControlJustReleased(0, 45) then -- Copy Coords In json
			local x = roundcord(coords.x, 2)
			local y = roundcord(coords.y, 2)
			local z = roundcord(coords.z, 2)
			local w = roundcord(GetEntityHeading(GetPlayerPed(-1)), 2)
			laserEndPoint = string.format('{x = %s, y = %s, z = %s, w = %s)', x, y, z, w)
			lib.setClipboard(laserEndPoint)
			lib.notify({
				title = 'Vector3 Copied',
				duration = 7500,
				description = laserEndPoint,
				type = 'success'
			})
		end
		if IsControlJustReleased(0, 74) then -- Copy Heading
			laserEndPoint = string.format('%s', roundcord(GetEntityHeading(GetPlayerPed(-1)), 2))
			lib.setClipboard(laserEndPoint)
			lib.notify({
				title = 'Heading Copied',
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
				title = 'Cord Copied',
				duration = 7500,
				description = laserEndPoint,
				type = 'success'
			})
		end
		DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false, false)
		Wait(10)
    end
	lib.hideTextUI()
end


-- Command handler
RegisterCommand("plaser", function()
    laserEnabled = not laserEnabled
    if not laserEnabled then
		lib.setClipboard(laserEndPoint)
		lib.notify({
			title = 'Vector3 Copied',
			duration = 7500,
			description = laserEndPoint,
			type = 'success'
		})
		laserEndPoint = nil
	else
		drawLaser()
	end
end)
