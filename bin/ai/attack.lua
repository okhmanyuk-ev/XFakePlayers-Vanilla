
function Attack()
	if NeedToDestroy then
		StartAttack()
		return
	end
	
	if Idle then
		return
	end

	if CurrentWeapon == nil then
		return
	end
	
	if not CanAttack() then
		return
	end

	if IsReloading() then
		return
	end
	
	if (DeltaTicks(LastPreVictimTime) < Behavior.PreReflex) and (DeltaTicks(LastVictimTime) < Behavior.PreReflex) then
		return
	end
	
	if DeltaTicks(LastVictimTime) > Behavior.PostReflex then 
		return
	end
	
	StartAttack()
end

function StartAttack()
	LastAttackTime = Ticks()
	
	if GetGameDir() == 'valve' then
		Attack_HL()
	elseif (GetGameDir() == 'cstrike') or (GetGameDir() == 'czero') then
		Attack_CS()
	elseif GetGameDir() == 'hlfx' then
		Attack_HL()
	else
		PrimaryAttack()
	end
end

function Attack_HL()
	local Index = GetWeaponIndex(CurrentWeapon)
	if Index == HL_WEAPON_CROWBAR then
		KnifeAttack()
	elseif CanUseWeapon(CurrentWeapon, true) then
		PrimaryAttack()
	end
end

function Attack_CS()
	local Slot = GetWeaponSlotID(CurrentWeapon)
	
	if (Slot == CS_WEAPON_SLOT_RIFLE) and CanUseWeapon(CurrentWeapon, true) then
		PrimaryAttack()
	elseif Slot == CS_WEAPON_SLOT_PISTOL then
		FastPrimaryAttack()
	elseif Slot == CS_WEAPON_SLOT_KNIFE then
		KnifeAttack(true)
	end
end

function KnifeAttack(CanAlternativeAttack)
	--[[if not HasVictim then
		return
	end
	
	MoveTo(Victim)
	
	if CanAlternativeAttack and Behavior.AlternativeKnifeAttack then
		if GetDistance(Victim) < KNIFE_ALTERNATIVE_ATTACK_DISTANCE then
			SecondaryAttack()
		end
	else
		if GetDistance(Victim) < KNIFE_PRIMARY_ATTACK_DISTANCE then
			PrimaryAttack()
		end	
	end]]
end