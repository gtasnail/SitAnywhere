local Enabled = false
local CooldownActive = false
local Enable = false
local toggle = false

RegisterCommand("sit", function(source, args, rawCommand)
	if Enable == false then
		Toggle(true)
	else
		Toggle(false)
	end
end,false)


function SomeNotify(message)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(message)
	DrawNotification(0,1)
end


function Draw3DText(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end
local rot1 = 0
local hidden = false
function Toggle(Enabled)	
	Enable = Enabled
	TriggerEvent('chat:addMessage', {
		color = {255, 0, 100},
		args = {'Sit Anywhere', Enabled and 'on' or 'off'}
	})
	if Enabled then
		ToggleSitting()
		while Enabled do
			Wait(0)
			local player = PlayerPedId()
			local coords = GetEntityCoords(player)
			if not hidden then
				Draw3DText(coords.x, coords.y, coords.z+1.65, 'Press ~b~[E]~w~ to Hide/Show text')
				Draw3DText(coords.x, coords.y, coords.z+1.35, '~g~~h~Controls')
				Draw3DText(coords.x, coords.y, coords.z+1.20, 'Arrow Left/Right to adjust')
				Draw3DText(coords.x, coords.y, coords.z+1.05, 'WASD Movement (Use Easy Noclip) Space/Shift Up and Down')
				Draw3DText(coords.x, coords.y, coords.z+0.90, '[~o~Up~w~/~o~Down Arrow~w~] to change mode!')
			end
			if IsControlJustPressed(0, 38) then
				hidden = not hidden
			end
			if Enable == false then
				ToggleSitting()
				break
			end
		end
	end
end



local MOVE_UP_KEY = 340
local MOVE_DOWN_KEY = 321
local CHANGE_SPEED_KEY = 21
local MOVE_LEFT_RIGHT = 30
local MOVE_UP_DOWN = 31
local NOCLIP_TOGGLE_KEY = 289
local NO_CLIP_NORMAL_SPEED = 0.05
local NO_CLIP_FAST_SPEED = 0.05
local ENABLE_NO_CLIP_SOUND = true
local eps = 0.01
local RESSOURCE_NAME = GetCurrentResourceName();
local isSitting = false
local speed = NO_CLIP_NORMAL_SPEED
local input = vector3(0, 0, 0)
local previousVelocity = vector3(0, 0, 0)
local breakSpeed = 10.0;
local offset = vector3(0, 0, 1);
local SittingEntity = playerPed;

local function IsControlAlwaysPressed(inputGroup, control)
    return IsControlPressed(inputGroup, control) or IsDisabledControlPressed(inputGroup, control)
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function IsPedDrivingVehicle(ped, veh)
    return ped == GetPedInVehicleSeat(veh, -1);
end

local function MoveInNoClip()
    local forward, right, up, c = GetEntityMatrix(SittingEntity);
    previousVelocity = Lerp(previousVelocity,
        (((right * input.x * speed) + (up * -input.z * speed) + (forward * -input.y * speed))), Timestep() * breakSpeed);
    c = c + previousVelocity
    SetEntityCoords(SittingEntity, c - offset, true, true, true, false)

end
local startcoords = vector3(0,0,0)
local function SetNoClip(val)
    if (isSitting ~= val) then
        local playerPed = PlayerPedId()
        SittingEntity = playerPed;
        if IsPedInAnyVehicle(playerPed, false) then
			SomeNotify('~r~You can\'t use this in a vehicle')
			Wait(0)
			ToggleSitting()
			Toggle(false)
        end
        local isVeh = IsEntityAVehicle(SittingEntity);
        isSitting = val;
        if ENABLE_NO_CLIP_SOUND then
            if isSitting then
                PlaySoundFromEntity(-1, "SELECT", playerPed, "HUD_LIQUOR_STORE_SOUNDSET", 0, 0)
            else
                PlaySoundFromEntity(-1, "CANCEL", playerPed, "HUD_LIQUOR_STORE_SOUNDSET", 0, 0)
            end
        end
        SetUserRadioControlEnabled(not isSitting);
        if (isSitting) then
            CreateThread(function()
                local clipped = SittingEntity
                local pPed = playerPed;
                local isClippedVeh = isVeh;
				local startpitch, startroll, startyaw = table.unpack(GetEntityRotation(clipped))
				local pitch = startpitch
				local roll = startroll
				local yaw = startyaw
				local mode = 1
				local modetext = nil
				local ClippedEntityCoords = GetEntityCoords(clipped)
				startcoords = ClippedEntityCoords
				print(startcoords..' Starting Point')
                if not isClippedVeh then
                    ClearPedTasksImmediately(pPed)
                end
                while isSitting do

					local startpoint = #(GetEntityCoords(clipped) - startcoords)
					if startpoint >= Config.DistanceAllowed then
						SomeNotify('~r~Went to far')
						Wait(0)
						Toggle(false)
						ToggleSitting()
					end
                    Wait(0);
                    FreezeEntityPosition(clipped, true);
					SetEntityDynamic(clipped, false)
                    SetEntityCollision(clipped, false, false);
					SetEntityCompletelyDisableCollision(clipped, false, false)
                    input = vector3(GetControlNormal(0, MOVE_LEFT_RIGHT), GetControlNormal(0, MOVE_UP_DOWN), (IsControlAlwaysPressed(1, MOVE_UP_KEY) and 1) or ((IsControlAlwaysPressed(1, MOVE_DOWN_KEY) and -1) or 0))
					if IsUsingKeyboard(0) then

						--Controls here
						if IsControlJustPressed(0, Config.ModeSwitchUp) then
							mode = mode+1
							if mode >= 5 then
								mode = 1
							end
						end
						if IsControlJustPressed(0, Config.ModeSwitchDown) then
							mode = mode+ -1
							if mode <= 0 then
								mode = 4
							end
						end
						if mode == 1 then
							modetext = 'Easy Movement'
							local head1, head2, head3   = table.unpack(GetGameplayCamRot(0))
							yaw = head3
							roll = head2
							pitch = head1
						end
						if mode == 2 then
							modetext = 'Pitch Control'
							if IsControlPressed(0, Config.IncreaseKey) then
								pitch = pitch+1.0
							end
							if IsControlPressed(0, Config.DecreaseKey) then
								pitch = pitch+ -1.0
							end
						elseif mode == 3 then
							modetext = 'Roll Control'
							if IsControlPressed(0, Config.IncreaseKey) then
								roll = roll+1.0
							end
							if IsControlPressed(0, Config.DecreaseKey) then
								roll = roll+ -1.0
							end
						elseif mode == 4 then
							modetext = 'Yaw Control'
							if IsControlPressed(0, Config.IncreaseKey) then
								yaw = yaw+1.0
							end
							if IsControlPressed(0, Config.DecreaseKey) then
								yaw = yaw+ -1.0
							end
						end
						--------------------
						local Pcoords = GetEntityCoords(clipped)
						if not hidden then
							Draw3DText(Pcoords.x, Pcoords.y, Pcoords.z+1.5, 'Mode: ~o~'..modetext..'(~b~'..mode..'~o~)~w~ Distance: ~b~'..string.format("%01.2f",startpoint)..' ~g~Pitch: ~r~'..math.floor(pitch)..' ~g~Roll: ~r~'..math.floor(roll)..' ~g~Yaw: ~r~'..math.floor(yaw))
						end
					else
						if not hidden then
							local Pcoords = GetEntityCoords(playerPed)
							Draw3DText(Pcoords.x, Pcoords.y, Pcoords.z+1.5, '~r~Please use Keyboard')
						end
					end
					SetEntityRotation(playerPed, pitch, roll, yaw, 0, false)
                    MoveInNoClip();
                end
                Wait(0);
                FreezeEntityPosition(clipped, false);
                SetEntityCollision(clipped, true, true);
				SetEntityCompletelyDisableCollision(clipped, true, true)
				SetEntityCoords(clipped, startcoords)
                Wait(500);
				if (IsPedFalling(clipped) and math.abs(1 - GetEntityHeightAboveGround(clipped)) > eps) then
					while (IsPedStopped(clipped) or not IsPedFalling(clipped)) and not isSitting do
						Wait(0);
					end
				end
				while not isSitting do
					Wait(0);
					if (not IsPedFalling(clipped)) and (not IsPedRagdoll(clipped)) then

					end
				end
            end)
        else
            ResetEntityAlpha(SittingEntity)
        end
    end
end

function ToggleSitting()
    return SetNoClip(not isSitting)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == RESSOURCE_NAME then
        SetNoClip(false);
        FreezeEntityPosition(SittingEntity, false);
        SetEntityCollision(SittingEntity, true, true);
        ResetEntityAlpha(SittingEntity);
    end
end)
