
-- movement utils

function HasChain()
	if type(Chain) ~= 'table' then
		return false
	else
		return #Chain > 0
	end
end
	
function SlowDuckJump()
	if DeltaTicks(SlowJumpTime) < SLOW_JUMP_PERIOD then
		return
	end
	
	if not IsOnGround() then
		return
	end
	
	DuckJump()
	
	SlowJumpTime = Ticks()
end

function UpdateScenario()
	Scenario = ScenarioType.Walking
	
	if CanCollecting then
		Scenario = ScenarioType.Collecting
		return
	end
	
	if IsEndOfRound then
		return
	end
	
	if (GetGameDir() == 'cstrike') or (GetGameDir() == 'czero') then
		if GetPlayerTeam(GetClientIndex()) == 'TERRORIST' then
			
			if IsWeaponExists(CS_WEAPON_C4) then
				Scenario = ScenarioType.SearchingBombPlace
			elseif IsBombDropped then
				Scenario = ScenarioType.SearchingBomb 
			end
		
		elseif GetPlayerTeam(GetClientIndex()) == 'CT' then
			
			if IsBombPlanted then
				Scenario = ScenarioType.SearchingBombPlace
			end
			
		end
	elseif GetGameDir() == 'valve' then
		--Scenario = ScenarioType.SearchingItems
	end
end

function ResetScenarion()
	Scenario = ScenarioType.None
end

-- weapon utils	
	
function FindCurrentWeapon()
	CurrentWeapon = GetWeaponByAbsoluteIndex(GetWeaponAbsoluteIndex())

	if (LastKnownWeapon ~= CurrentWeapon) and (CurrentWeapon ~= 0) and (LastKnownWeapon ~= 0) then
		print('choosed: ' .. GetWeaponNameEx(CurrentWeapon))
	end

	LastKnownWeapon = CurrentWeapon
end

function FindHeaviestWeaponInSlot(ASlot)
	local Weapon = nil
	local Weight = -1
	
	-- TODO: add ammo checking
	
	for I = 0, GetWeaponsCount() - 1 do
		if IsWeaponExists(GetWeaponIndex(I)) then
			if GetWeaponSlotID(I) == ASlot then
				if GetWeaponWeight(I) > Weight then
					Weapon = I
					Weight = GetWeaponWeight(I)
				end
			end
		end
	end
	
	return Weapon
end

function FindHeaviestWeapon()
	local Weapon = nil
	local Weight = -1
	
	for I = 0, GetWeaponsCount() - 1 do
		if IsWeaponExists(GetWeaponIndex(I)) then
			if GetWeaponWeight(I) > Weight then
				Weapon = I
				Weight = GetWeaponWeight(I)
			end
		end
	end
	
	return Weapon
end

function FindHeaviestUsableWeapon(IsInstant)
	local Weapon = nil
	local Weight = -1
	
	for I = 0, GetWeaponsCount() - 1 do
		if IsWeaponExists(GetWeaponIndex(I)) then
			if CanUseWeapon(I, IsInstant) then
				if GetWeaponWeight(I) > Weight then
					Weapon = I
					Weight = GetWeaponWeight(I)
				end
			end
		end
	end
	
	return Weapon
end

function ChooseWeapon(AWeapon)
	if not IsSlowThink then
		return
	end
	
	if AWeapon == nil then
		return
	end
	
	if AWeapon == CurrentWeapon then
		return
	end
	
	ExecuteCommand(GetWeaponName(AWeapon))
end

function GetWeaponClip(AWeapon)
	if not HasWeaponData(GetWeaponIndex(AWeapon)) then
		return 0
	end
	
	return GetWeaponDataField(GetWeaponIndex(AWeapon), WeaponDataField.Clip)
end

function HasWeaponClip(AWeapon)
	return GetWeaponClip(AWeapon) > 0
end

function GetWeaponPrimaryAmmo(AWeapon) 
	return GetAmmo(GetWeaponPrimaryAmmoID(AWeapon))
end

function HasWeaponPrimaryAmmo(AWeapon)
	return GetWeaponPrimaryAmmo(AWeapon) > 0
end

function GetWeaponSecondaryAmmo(AWeapon)
	return GetAmmo(GetWeaponSecondaryAmmoID(AWeapon))
end

function HasWeaponSeconadryAmmo(AWeapon)
	return GetWeaponSecondaryAmmo(AWeapon) > 0
end

function CanUseWeapon(AWeapon, IsInstant)
	if AWeapon == nil then
		return false
	end
	
	local Clip = GetWeaponClip(AWeapon)
	local PrimaryAmmo = GetWeaponPrimaryAmmo(AWeapon)
	local SecondaryAmmo = GetWeaponSecondaryAmmo(AWeapon)
	
	if Clip ~= WEAPON_NOCLIP then -- weapon can be reloaded
		if IsInstant then
			return Clip > 0
		else
			return Clip + PrimaryAmmo + SecondaryAmmo > 0
		end
	else
		return PrimaryAmmo > 0
	end
end

function GetWeaponMaxClip(AWeapon)
	if (GetGameDir() == 'cstrike') or (GetGameDir() == 'czero') then
		return CSWeapons[GetWeaponIndex(AWeapon)].MaxClip
	elseif GetGameDir() == 'valve' then
		return HLWeapons[GetWeaponIndex(AWeapon)].MaxClip
	else
		print 'GetWeaponMaxClip(AWeapon) does not support this game modification'
		return nil
	end
end

function GetWeaponWeight(AWeapon)
	if (GetGameDir() == 'cstrike') or (GetGameDir() == 'czero') then
		return CSWeapons[GetWeaponIndex(AWeapon)].Weight
	elseif GetGameDir() == 'valve' then
		return HLWeapons[GetWeaponIndex(AWeapon)].Weight
	else
		print 'GetWeaponWeight(AWeapon) does not support this game modification'
		return nil
	end	
end

function IsWeaponFullyLoaded(AWeapon)
	if AWeapon == nil then
		return true
	end
	
	if GetGameDir() == 'dmc' then
		return true
	end
 
	local Clip = GetWeaponClip(AWeapon)
	
	if Clip == WEAPON_NOCLIP then
		return true
	end
	
	if not HasWeaponPrimaryAmmo(AWeapon) then
		return true
	end

	return Clip >= GetWeaponMaxClip(AWeapon)
end

function IsWeaponFullPrimaryAmmo(AWeapon)
	return GetWeaponPrimaryAmmo(AWeapon) >= GetWeaponPrimaryAmmoMaxAmount(AWeapon)
end

function IsWeaponFullPrimaryAmmoAbs(AIndex)
	return IsWeaponFullPrimaryAmmo(GetWeaponByAbsoluteIndex(AIndex))
end

function IsWeaponFullSecondaryAmmo(AWeapon)
	return GetWeaponSecondaryAmmo(AWeapon) >= GetWeaponSecondaryAmmoMaxAmount(AWeapon)
end

function IsWeaponFullSecondaryAmmoAbs(AIndex)
	return IsWeaponFullSecondaryAmmo(GetWeaponByAbsoluteIndex(AIndex))
end

function NeedReloadWeapon(AWeapon)
	return not IsWeaponFullyLoaded(AWeapon)
end

function CanReload()
	-- TODO: write something here
	
	return true
end

-- attack

function IsAttacking()
	return DeltaTicks(LastAttackTime) < 500 -- fix
end

-- common utils

function Behavior.Randomize()
	Behavior.MoveWhenShooting = Chance(50)
	Behavior.CrouchWhenShooting = Chance(50)
	Behavior.MoveWhenReloading = Chance(50)
	Behavior.AimWhenReloading = Chance(50)
	Behavior.AlternativeKnifeAttack = Chance(50)
	Behavior.ReloadDelay = math.random(1000, 10000)
	Behavior.DuckWhenPlantingBomb = Chance(50)
	Behavior.DuckWhenDefusingBomb = Chance(50)
	Behavior.Psycho = Chance(5)
	
	Behavior.PreReflex = math.random(50, 200)
	Behavior.PostReflex = math.random(250, 750)
end

function MyHeight()
	if IsCrouching() then
		return HUMAN_HEIGHT_DUCK
	else
		return HUMAN_HEIGHT_STAND
	end
end

function IsEnemy(player_index)
	if Friendly then
		return false
	end
	
	if IsTeamPlay() --[[and not FriendlyFire]] then
		if (GetGameDir() == 'tfc') or (GetGameDir() == 'dod') then
			-- dod & tfc are not using absolute team names, we need to compare team indexes from entities array
		
			local T1 = GetEntityTeam(GetClientIndex() + 1)
			local T2 = GetEntityTeam(player_index + 1)
			
			return T1 ~= T2
		else 		
			-- we can compare team names from players array for all other mods
		
			local T1 = GetPlayerTeam(GetClientIndex())
			local T2 = GetPlayerTeam(player_index)
			
			return T1 ~= T2
		end
	else
		if GetGameDir() == 'svencoop' then
			return false
		else
			return true
		end
	end
end

function IsPlayerPriority(APlayer)
	return APlayer < GetClientIndex()
end

function FindEnemiesAndFriends()
	NearestEnemy = nil;
	NearestLeaderEnemy = nil;
	EnemiesNearCount = 0;

	NearestFriend = nil;
	NearestLeaderFriend = nil;
	FriendsNearCount = 0;
	
	NearestPlayer = nil
	NearestLeaderPlayer = nil
	PlayersNearCount = 0
	
	local EnemyDistance = MAX_UNITS
	local EnemyKills = 0

	local FriendDistance = MAX_UNITS
	local FriendKills = 0
	
	local PlayerDistance = MAX_UNITS
	local PlayerKills = 0
	
	NearestEnemyInField = nil
	NearestLeaderEnemyInField = nil
	EnemiesNearInFieldCount = 0
	
	NearestFriendInField = nil
	NearestLeaderFriendInField = nil
	FriendsNearInFieldCount = 0
	
	NearestPlayerInField = nil
	NearestLeaderPlayerInField = nil
	PlayersNearInFieldCount = 0
	
	local EnemyInFieldDistance = MAX_UNITS
	local EnemyInFieldKills = 0

	local FriendInFieldDistance = MAX_UNITS
	local FriendInFieldKills = 0
	
	local PlayerInFieldDistance = MAX_UNITS
	local PlayerInFieldKills = 0
	
	NearestVisibleEnemy = nil;
	NearestVisibleLeaderEnemy = nil;
	VisibleEnemiesNearCount = 0;

	NearestVisibleFriend = nil;
	NearestVisibleLeaderFriend = nil;
	VisibleFriendsNearCount = 0;
	
	NearestVisiblePlayer = nil
	NearestVisibleLeaderPlayer = nil
	VisiblePlayersNearCount = 0
	
	local VisibleEnemyDistance = MAX_UNITS
	local VisibleEnemyKills = 0

	local VisibleFriendDistance = MAX_UNITS
	local VisibleFriendKills = 0
	
	local VisiblePlayerDistance = MAX_UNITS
	local VisiblePlayerKills = 0		

	NearestVisibleEnemyInField = nil
	NearestVisibleLeaderEnemyInField = nil
	VisibleEnemiesNearInFieldCount = 0

	NearestVisibleFriendInField = nil
	NearestVisibleLeaderFriendInField = nil
	VisibleFriendsNearInFieldCount = 0
	
	NearestVisiblePlayerInField = nil
	NearestVisibleLeaderPlayerInField = nil
	VisiblePlayersNearInFieldCount = 0
	
	local VisibleEnemyInFieldDistance = MAX_UNITS
	local VisibleEnemyInFieldKills = 0

	local VisibleFriendInFieldDistance = MAX_UNITS
	local VisibleFriendInFieldKills = 0
	
	local VisiblePlayerInFieldDistance = MAX_UNITS
	local VisiblePlayerInFieldKills = 0		
	
	for I = 1, GetPlayersCount() do
		if I ~= GetClientIndex() + 1 then
			if --[[IsEntityActive(I)]] GetPlayerOrigin(I - 1) ~= 0 then -- player may be on radar
				if IsPlayerAlive(I - 1) then
					if InFieldOfView(I) then
						PlayersNearInFieldCount = PlayersNearInFieldCount + 1
						
						if GetDistance(I) < PlayerInFieldDistance then
							PlayerInFieldDistance = GetDistance(I)
							NearestPlayerInField = I
						end
							
						if GetPlayerKills(I - 1) > PlayerInFieldKills then
							PlayerInFieldKills = GetPlayerKills(I - 1)
							NearestLeaderPlayerInField = I
						end

						if IsEnemy(I - 1) then
							EnemiesNearInFieldCount = EnemiesNearInFieldCount + 1
						
							if GetDistance(I) < EnemyInFieldDistance then
								EnemyInFieldDistance = GetDistance(I)
								NearestEnemyInField = I
							end
						
							if GetPlayerKills(I - 1) > EnemyInFieldKills then
								EnemyInFieldKills = GetPlayerKills(I - 1)
								NearestLeaderEnemyInField = I
							end					
						else
							FriendsNearInFieldCount = FriendsNearInFieldCount + 1
						
							if GetDistance(I) < FriendInFieldDistance then
								FriendInFieldDistance = GetDistance(I)
								NearestFriendInField = I
							end
						
							if GetPlayerKills(I - 1) > FriendInFieldKills then
								FriendInFieldKills = GetPlayerKills(I - 1)
								NearestLeaderFriendInField = I
							end	
						end
					end
					
					PlayersNearCount = PlayersNearCount + 1
					
					if GetDistance(I) < PlayerDistance then
						PlayerDistance = GetDistance(I)
						NearestPlayer = I
					end
						
					if GetPlayerKills(I - 1) > PlayerKills then
						PlayerKills = GetPlayerKills(I - 1)
						NearestLeaderPlayer = I
					end

					if IsEnemy(I - 1) then
						EnemiesNearCount = EnemiesNearCount + 1
					
						if GetDistance(I) < EnemyDistance then
							EnemyDistance = GetDistance(I)
							NearestEnemy = I
						end
					
						if GetPlayerKills(I - 1) > EnemyKills then
							EnemyKills = GetPlayerKills(I - 1)
							NearestLeaderEnemy = I
						end					
					else
						FriendsNearCount = FriendsNearCount + 1
					
						if GetDistance(I) < FriendDistance then
							FriendDistance = GetDistance(I)
							NearestFriend = I
						end
					
						if GetPlayerKills(I - 1) > FriendKills then
							FriendKills = GetPlayerKills(I - 1)
							NearestLeaderFriend = I
						end	
					end
					
					if HasWorld() then
						if IsVisible(I)then
							if InFieldOfView(I) then
								VisiblePlayersNearInFieldCount = VisiblePlayersNearInFieldCount + 1
							
								if GetDistance(I) < VisiblePlayerInFieldDistance then
									VisiblePlayerInFieldDistance = GetDistance(I)
									NearestVisiblePlayerInField = I
								end
									
								if GetPlayerKills(I - 1) > VisiblePlayerInFieldKills then
									VisiblePlayerInFieldKills = GetPlayerKills(I - 1)
									NearestVisibleLeaderPlayerInField = I
								end

								if IsEnemy(I - 1) then
									VisibleEnemiesNearInFieldCount = VisibleEnemiesNearInFieldCount + 1
								
									if GetDistance(I) < VisibleEnemyInFieldDistance then
										VisibleEnemyInFieldDistance = GetDistance(I)
										NearestVisibleEnemyInField = I
									end
								
									if GetPlayerKills(I - 1) > VisibleEnemyInFieldKills then
										VisibleEnemyInFieldKills = GetPlayerKills(I - 1)
										NearestVisibleLeaderEnemyInField = I
									end					
								else
									VisibleFriendsNearInFieldCount = VisibleFriendsNearInFieldCount + 1
								
									if GetDistance(I) < VisibleFriendInFieldDistance then
										VisibleFriendInFieldDistance = GetDistance(I)
										NearestVisibleFriendInField = I
									end
								
									if GetPlayerKills(I - 1) > VisibleFriendInFieldKills then
										VisibleFriendInFieldKills = GetPlayerKills(I - 1)
										NearestVisibleLeaderFriendInField = I
									end	
								end
							end
						
							VisiblePlayersNearCount = VisiblePlayersNearCount + 1
							
							if GetDistance(I) < VisiblePlayerDistance then
								VisiblePlayerDistance = GetDistance(I)
								NearestVisiblePlayer = I
							end
								
							if GetPlayerKills(I - 1) > VisiblePlayerKills then
								VisiblePlayerKills = GetPlayerKills(I - 1)
								NearestVisibleLeaderPlayer = I
							end

							if IsEnemy(I - 1) then
								VisibleEnemiesNearCount = VisibleEnemiesNearCount + 1
							
								if GetDistance(I) < VisibleEnemyDistance then
									VisibleEnemyDistance = GetDistance(I)
									NearestVisibleEnemy = I
								end
							
								if GetPlayerKills(I - 1) > VisibleEnemyKills then
									VisibleEnemyKills = GetPlayerKills(I - 1)
									NearestVisibleLeaderEnemy = I
								end					
							else
								VisibleFriendsNearCount = VisibleFriendsNearCount + 1
							
								if GetDistance(I) < VisibleFriendDistance then
									VisibleFriendDistance = GetDistance(I)
									NearestVisibleFriend = I
								end
							
								if GetPlayerKills(I - 1) > VisibleFriendKills then
									VisibleFriendKills = GetPlayerKills(I - 1)
									NearestVisibleLeaderFriend = I
								end	
							end
						end
					end
				end
			end			
		end
	end
	
	HasEnemiesNear = EnemiesNearCount > 0
	HasFriendsNear = FriendsNearCount > 0
	HasPlayersNear = PlayersNearCount > 0
	
	HasEnemiesNearInField = EnemiesNearInFieldCount > 0
	HasFriendsNearInField = FriendsNearInFieldCount > 0
	HasPlayersNearInField = PlayersNearInFieldCount > 0		
	
	HasVisibleEnemiesNear = VisibleEnemiesNearCount > 0
	HasVisibleFriendsNear = VisibleFriendsNearCount > 0
	HasVisiblePlayersNear = VisiblePlayersNearCount > 0	
	
	HasVisibleEnemiesNearInField = VisibleEnemiesNearInFieldCount > 0
	HasVisibleFriendsNearInField = VisibleFriendsNearInFieldCount > 0
	HasVisiblePlayersNearInField = VisiblePlayersNearInFieldCount > 0
end

function FindVictim()
	if not HasWorld() then
		return
	end
	
	Victim = NearestVisibleEnemyInField
	
	HasVictim = Victim ~= nil
	
	if HasVictim then
		LastVictimTime = Ticks()
	else	
		LastPreVictimTime = Ticks()
	end
end

function FindStatusIconByName(AName)
	for I = 0, GetStatusIconsCount() - 1 do
		if GetStatusIconName(I) == AName then
			return I
		end
	end
		
	return nil
end

function FindResourceByIndex(AIndex, AType)
	for I = 0, GetResourcesCount() - 1 do
		if GetResourceType(I) == AType then
			if GetResourceIndex(I) == AIndex then
				return I
			end
		end
	end
	
	return nil
end

function FindActiveEntityByModelName(AModelName)
	for I = 0, GetEntitiesCount() - 1 do
		if IsEntityActive(I) then
			local R = FindResourceByIndex(GetEntityModelIndex(I), RT_MODEL)
			
			if R ~= nil then
				if string.sub(GetResourceName(R), 1, string.len(AModelName)) == AModelName then
					return I
				end
			end
		end
	end
	
	return nil
end

function GetModelGabaritesCenter(AModel)
	local MinS = Vec3.New(GetWorldModelMinS(AModel))
	local MaxS = Vec3.New(GetWorldModelMaxS(AModel))
	
	local D = Vec3Line.New(MinS.X, MinS.Y, MinS.Z, MaxS.X, MaxS.Y, MaxS.Z)
	
	return D:Center()
end

function GetWalkSpeed()
	if (GetGameDir() == 'cstrike') or (GetGameDir() == 'czero') then
		return 130
	else
		print('GetWalkSpeed: unknown mod')
	end
end

function HasLongJump()
	return string.find(GetClientPhysInfo(), '\\slj\\1') ~= nil
end

function ShouldCombatMovementAdditions()
	return (DeltaTicks(LastVictimTime) < Behavior.PostReflex + Behavior.PreReflex) and not Idle 
end

function ShouldPickUpItem(S)
	if GetGameDir() == 'valve' then
		if (S == 'w_weaponbox') 

		or ((S == 'w_medkit') and (GetHealth() < 100))
		or ((S == 'w_battery') and (GetBattery() < 100)) 
		
		or ((S == 'w_longjump') and not HasLongJump())
		
		or ((S == 'w_9mmar') and (not IsWeaponExists(HL_WEAPON_MP5) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_MP5)))
		or ((S == 'w_9mmhandgun') and (not IsWeaponExists(HL_WEAPON_GLOCK) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_GLOCK)))
		or ((S == 'w_357') and (not IsWeaponExists(HL_WEAPON_PYTHON) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_PYTHON)))
		or ((S == 'w_crossbow') and (not IsWeaponExists(HL_WEAPON_CROSSBOW) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_CROSSBOW)))
		or ((S == 'w_crowbar') and (not IsWeaponExists(HL_WEAPON_CROWBAR) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_CROWBAR)))
		or ((S == 'w_egon') and (not IsWeaponExists(HL_WEAPON_EGON) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_EGON)))
		or ((S == 'w_gauss') and (not IsWeaponExists(HL_WEAPON_GAUSS) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_GAUSS)))
		or ((S == 'w_grenade') and (not IsWeaponExists(HL_WEAPON_HANDGRENADE) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_HANDGRENADE)))
		or ((S == 'w_hgun') and (not IsWeaponExists(HL_WEAPON_HORNETGUN) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_HORNETGUN)))
		or ((S == 'w_rpg') and (not IsWeaponExists(HL_WEAPON_RPG) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_RPG)))
		or ((S == 'w_satchel') and (not IsWeaponExists(HL_WEAPON_SATCHEL) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_SATCHEL)))
		or ((S == 'w_shotgun') and (not IsWeaponExists(HL_WEAPON_SHOTGUN)  or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_SHOTGUN)))
		or ((S == 'w_sqknest') and (not IsWeaponExists(HL_WEAPON_SNARK) or not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_SNARK)))
		
		or ((S == 'w_9mmarclip') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_MP5))
		or ((S == 'w_9mmclip') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_GLOCK))
		or ((S == 'w_357ammo') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_PYTHON))
		or ((S == 'w_357ammobox') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_PYTHON))
		or ((S == 'w_argrenade') and not IsWeaponFullSecondaryAmmoAbs(HL_WEAPON_MP5))
		--or ((S == 'w_chainammo') and not IsWeaponFullPrimaryAmmoAbs()) -- i do not know what is it. TODO: check
		or ((S == 'w_crossbow_clip') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_CROSSBOW))
		or ((S == 'w_gaussammo') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_GAUSS))
		or ((S == 'w_rpgammo') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_RPG))
		or ((S == 'w_shotbox') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_SHOTGUN))
		--or ((S == 'w_shotshell') and not IsWeaponFullPrimaryAmmoAbs(HL_WEAPON_SHOTGUN)) -- need confirmation
		then
			return true
		end
	elseif (GetGameDir() == 'cstrike') or (GetGameDir() == 'czero') then
		if ((S == 'w_c4') and (GetPlayerTeam(GetClientIndex()) == 'CT')) -- planted c4
		or ((S == 'w_backpack') and (GetPlayerTeam(GetClientIndex()) == 'TERRORIST')) -- dropped c4
		
		or ((S == 'w_assault') and (GetBattery() < 100))
		or ((S == 'w_kevlar') and (GetBattery() < 100)) -- TODO: add helm checking
		
		or ((FindHeaviestWeaponInSlot(CS_WEAPON_SLOT_RIFLE) == nil) 
			and ((S == 'w_ak47')
			or (S == 'w_aug')
			or (S == 'w_awp')
			or (S == 'w_famas')
			or (S == 'w_g3sg1')
			or (S == 'w_galil')
			or (S == 'w_m3')
			or (S == 'w_m4a1')
			or (S == 'w_m249')
			or (S == 'w_mac10')
			or (S == 'w_mp5')
			or (S == 'w_p90')
			or (S == 'w_scout')
			or (S == 'w_sg550')
			or (S == 'w_sg552')
			or (S == 'w_tmp')
			or (S == 'w_ump45')
			or (S == 'w_xm1014')))
			
		or ((FindHeaviestWeaponInSlot(CS_WEAPON_SLOT_PISTOL) == nil)
			and ((S == 'w_deagle')
			or (S == 'w_elite')
			or (S == 'w_fiveseven')
			or (S == 'w_glock18')
			or (S == 'w_p228')
			or (S == 'w_usp')))
				
		--[[
		TODO:
			w_flashbang
			w_hegrenade
			w_knife
			w_shield
			w_smokegrenade
			w_thighpack !!!
		]]
		then
			return true
		end
	elseif GetGameDir() == 'dmc' then
		if ((S == 'armour_g') and (GetBattery() < 100))
		or ((S == 'armour_y') and (GetBattery() < 150))
		or ((S == 'armour_r') and (GetBattery() < 200))
		
		or ((S == 'w_medkit') and (GetHealth() < 100))
		or ((S == 'w_medkits') and (GetHealth() < 100))
		or ((S == 'w_medkitl') and (GetHealth() < 200))
		
		or (S == 'pow_invis')
		or (S == 'pow_invuln')
		or (S == 'pow_quad')
		
		or (S == 'backpack')
		
		--or (S == 'b_nail0')
		--or (S == 'b_nail1')
		
		--or (S == 'g_light')
		--or (S == 'g_nail')
		--or (S == 'g_nail2')
		--or (S == 'g_rock')
		--or (S == 'g_rock2')
		--or (S == 'g_shot2')
		
		--or (S == 'grenade')
		
		--or (S == 'w_battery')
		--or (S == 'w_batteryl')
		
		--or (S == 'w_rpgammo')
		--or (S == 'w_rpgammo_big')
		
		--or (S == 'w_shotbox')
		--or (S == 'w_shotbox_big')
		then
			return true
		end
	end
	
	return false
end