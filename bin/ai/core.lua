-- ai core file

--[[
	TODO: 	
		hostages using in CS, CZ
		health & armor recharging stations using in HL
		react to svc_event: we need to choose shootable weapon instead knife, if we heard shoots near
]]

	Idle = false -- objectives disabled
	Friendly = false -- only objectives

dofile 'ai/vector.lua' 
dofile 'ai/shared.lua'
dofile 'ai/protocol.lua'  -- see this file to get help

dofile 'ai/think.lua'

function Initialization()
	math.randomseed(os.time())

	LastKnownWeapon = GetWeaponByAbsoluteIndex(GetWeaponAbsoluteIndex())
	IsSpawned = IsAlive()
	
	if GetGameDir() == 'dmc' then
		ExecuteCommand('_firstspawn') 
	end
	
	if (GetGameDir() == 'valve') 
	or (GetGameDir() == 'dmc') 
	or (GetGameDir() == 'gearbox') then
		if not IsTeamPlay() then
			if GetGameDir() == 'gearbox' then
				ExecuteCommand('model ' .. OPFOR_PLAYER_MODELS[math.random(#OPFOR_PLAYER_MODELS)])
			else
				ExecuteCommand('model ' .. HL_PLAYER_MODELS[math.random(#HL_PLAYER_MODELS)])
			end
		end
		
		ExecuteCommand('topcolor ' .. math.random(255))
		ExecuteCommand('bottomcolor ' .. math.random(255))
	end
	
	if Idle then
		print 'Idle mode'
	end
end

function Finalization()
	-- write something here
end

function Frame() 
	if GetIntermission() ~= 0 then -- end of map ?
		return
	end
	
	if IsPaused() then
		return
	end
	
	PreThink()
	Think()
	PostThink()
end	

function OnTrigger(ATrigger)
	if ATrigger == 'RoundStart' then
		IsEndOfRound = false
		Spawn()
	elseif ATrigger == 'RoundEnd' then
		IsEndOfRound = true
		IsBombPlanted = false
	elseif ATrigger == 'BombPlanted' then
		IsBombPlanted = true
	elseif ATrigger == 'BombDropped' then
		IsBombDropped = true
	elseif ATrigger == 'BombPickedUp' then
		IsBombDropped = false
	else
		print('OnTrigger: unknown trigger "' .. ATrigger .. '"')
	end
end

function OnSound(AIndex, AEntity, AChannel, AVolume, APitch, AAttenuation, AFlags, X, Y, Z)
	local R = FindResourceByIndex(AIndex, RT_SOUND)
	
	if R == nil then
		return
	end
	
	--print(GetResourceName(R)) -- .. '[' .. Vec3.New(X, Y, Z) .. ']')
	
	--[[

00:12:57 - 191) Name: "weapons/c4_beep1.wav", Index: 187, Type: 0, Size: 66232, Flags: 0, MD5: 0
00:12:57 - 192) Name: "weapons/c4_beep2.wav", Index: 188, Type: 0, Size: 66220, Flags: 0, MD5: 0
00:12:57 - 193) Name: "weapons/c4_beep3.wav", Index: 189, Type: 0, Size: 66202, Flags: 0, MD5: 0
00:12:57 - 194) Name: "weapons/c4_beep4.wav", Index: 190, Type: 0, Size: 66226, Flags: 0, MD5: 0
00:12:57 - 195) Name: "weapons/c4_beep5.wav", Index: 191, Type: 0, Size: 66206, Flags: 0, MD5: 0	
	
	]]
end