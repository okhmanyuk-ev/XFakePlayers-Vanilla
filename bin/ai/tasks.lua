
function Tasks()
	BuyWeapons()
	ActivateFlashlight()
	CheckScores()
	PlantBomb()
	DefuseBomb()
	FindBreakables() 
	FindItemsToCollect()
end

function BuyWeapons()
	if not IsSlowThink then
		return
	end
	
	if not NeedToBuyWeapons then
		return
	end
	
	if (GetGameDir() ~= 'cstrike') and (GetGameDir() ~= 'czero') then
		return
	end

	local Icon = FindStatusIconByName('buyzone') -- also, we can using world to find buyzone
	
	if Icon == nil then
		return
	end
	
	if GetStatusIconStatus(Icon) == 0 then -- byuzone icon is not on screen
		return
	end
	
	ExecuteCommand('autobuy')
	
	NeedToBuyWeapons = false
end

function ActivateFlashlight()
	if not IsSlowThink then
		return
	end

	if IsFlashlightRecharging then
		if GetFlashBat() >= 95 then
			IsFlashlightRecharging = false
		end
	else
		if GetFlashBat() <= 5 then
			IsFlashlightRecharging = true
		end		
	end
	
	local NeedFlashligth = false
	
	-- TODO: add Behavior.UseFlashlight with 85% chance
	
	if (GetHideWeapon() & HIDEHUD_FLASHLIGHT == 0) and not IsFlashlightRecharging then
		if string.len(GetLightStyle(0)) ~= 0 then
			local S = string.sub(GetLightStyle(0), 1, 1)
			
			-- 'a' - black map
			-- 'm' - default lightning
			-- 'z' - full bright
			
			if (S == 'a') or (S == 'b') or (S == 'c') then -- "s in ['a'..'c']" ?
				NeedFlashligth = true
			end
		end
	end
	
	if (NeedFlashligth and not IsFlashlightActive()) or (not NeedFlashligth and IsFlashlightActive()) then
		ExecuteCommand('impulse 100')
	end
end

function CheckScores() 
	if not IsSlowThink then
		return
	end
	
	if DeltaTicks(LastScoresCheckTime) < 5000 then
		return
	end
	
	LastScoresCheckTime = Ticks()
	
	PressButton(Button.SCORE) -- tab button
end

function PlantBomb()
	if not IsSlowThink and not IsPlantingBomb then
		return
	end
	
	IsPlantingBomb = false

	if (GetGameDir() ~= 'cstrike') and (GetGameDir() ~= 'czero') then	
		return
	end
	
	local Icon = FindStatusIconByName('c4') -- also, we can using world to find c4 zone
	
	if Icon == nil then
		return
	end
	
	if GetStatusIconStatus(Icon) ~= 2 then -- c4 icon is not flashing
		return
	end

	IsPlantingBomb = true

	if Behavior.DuckWhenPlantingBomb then
		Duck()
	end
	
	if GetWeaponAbsoluteIndex() ~= CS_WEAPON_C4 then
		ChooseWeapon(GetWeaponByAbsoluteIndex(CS_WEAPON_C4))
	else
		PrimaryAttack() 
	end
end

function DefuseBomb()
	if not IsSlowThink and not IsDefusingBomb then
		return
	end

	IsDefusingBomb = false

	if (GetGameDir() ~= 'cstrike') and (GetGameDir() ~= 'czero') then	
		return
	end
	
	if GetPlayerTeam(GetClientIndex()) ~= 'CT' then
		return
	end
	
	local C4 = FindActiveEntityByModelName('models/w_c4')
	
	if C4 == nil then
		return
	end
	
	if GetGroundedDistance(C4) > 50 then
		return 
	end

	IsDefusingBomb = true

	LookAtEx(C4)

	if Behavior.DuckWhenDefusingBomb then
		Duck()
	end

	if GetGroundedDistance(C4) > 25 then
		MoveTo(C4)
	end

	PressButton(Button.USE)
end

function FindBreakables()
	if not IsSlowThink then
		return
	end
	
	if not HasWorld() then
		return
	end
	
	-- TODO: we need to destroy objects only when this objects prevent our path

	-- TODO: add Behavior.WantToDestroyBreakables
	
	-- TODO: check de_prodigy_cz
	
	NeedToDestroy = false
	
	local Distance = MAX_UNITS

	for I = 0, GetEntitiesCount() - 1 do
		if not IsPlayerIndex(I) then
			if IsEntityActive(I) then
				local R = FindResourceByIndex(GetEntityModelIndex(I), RT_MODEL)
				
				if R ~= nil then
					local S = GetResourceName(R)
					
					if S:sub(1, 1) == '*' then
						local E = GetWorldEntity('model', GetResourceName(R))
					
						if E ~= nil then
							if GetWorldEntityField(E, 'classname') == 'func_breakable' then 
								if GetWorldEntityField(E, 'spawnflags') == '' then -- TODO: add extended flag checking 
									
									-- TODO: add entity health checking here
									-- try to break only if health less or equals 200
									
									local J = tonumber(S:sub(2))
									local C = GetModelGabaritesCenter(J)
									
									-- TODO: add explosion radius checking here
									
									-- TODO: add Behavior.DestroyExplosions
									
									if (GetDistance(C:Unpack()) < Distance) and IsVisible(C:Unpack()) then
										BreakablePosition = C
										NeedToDestroy = true
										Distance = GetDistance(C:Unpack())
									end	
								end
							end
						end
					end
				end
			end
		end
	end
end

function FindItemsToCollect()
	if not IsSlowThink and not ((Scenario == ScenarioType.Collecting) and not CanCollecting) then -- instant search after picking up
		return
	end
	
	if not HasWorld() then
		return
	end

	if Scenario == ScenarioType.Collecting and CanCollecting then -- already collecting something
		return
	end
	
	-- TODO: add Behavior.WantToCollectItems

	CanCollecting = false
	
	local Distance = MAX_UNITS
	
	for I = 0, GetEntitiesCount() - 1 do
		if not IsPlayerIndex(I) then
			if IsEntityActive(I) then
				
				-- TODO: recode blacklist checking to dedicated function ?
				
				local InBlackList = false 
				
				for J = 1, #CollectingBlackList do -- TODO: recode this line to foreach
					if I == CollectingBlackList[J] then
						InBlackList = true
						break
					end
				end
				
				if not InBlackList then
					local R = FindResourceByIndex(GetEntityModelIndex(I), RT_MODEL)
					
					if R ~= nil then
						local S = GetResourceName(R)
						
						if S:sub(1, 1) ~= '*' then	
							S = S:match('(.+)%..+')
							S = S:sub(8) -- TODO: delete this line, and make universal 'match' search
							
							if ShouldPickUpItem(S) and (GetDistance(I) < Distance) then
								if IsReachable(Vec3.New(GetEntityOrigin(I))) then
									CollectPosition = Vec3.New(GetEntityOrigin(I))
									CanCollecting = true
									LastCollectingEntity = I
									LastCollectingEntityName = S
									Distance = GetDistance(I)
								else
									table.insert(CollectingBlackList, I)
								end
							end
						else
							table.insert(CollectingBlackList, I)
						end
					else
						table.insert(CollectingBlackList, I)
					end
				end
			end
		end
	end
end