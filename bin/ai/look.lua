
function Look()
	if IsPlantingBomb then
		return
	end
	
	if IsDefusingBomb then
		return
	end

	if HasVictim and ((IsReloading() and Behavior.AimWhenReloading) or not IsReloading()) and not Idle then		
		LookAtEx(Victim)
		return
	end
	
	if NeedToDestroy then
		LookAtEx(BreakablePosition:Unpack())
		return
	end
	
	if (DeltaTicks(LastVictimTime) < Behavior.PostReflex + Behavior.PreReflex) and not Idle then
		return
	end
	
	if HasNavigation() and not Idle then
		ObjectiveLook()
	else
		PrimitiveLook()
	end
	
	LookAtEx(LookPoint:Unpack())
end

function PrimitiveLook()
	local V = Vec3.New(GetVelocity())
		
	if V:Length() == 0 then
		return
	end
	
	LookPoint = Vec3.New(GetOrigin()) + V
end

function ObjectiveLook()
	if not HasChain() then
		return
	end
	
	if not IsAreaChanged and not IsSlowThink then
		return
	end
	
	local ViewArea = nil
	
	for I = 0, GetNavAreaApproachesCount(Area) - 1 do
		for J = #Chain, ChainIndex, -1 do
			A = GetNavAreaApproachHere(Area, I)
			
			if A == Chain[J] then
				ViewArea = A
				break
			end
		end
		
		if ViewArea ~= nil then
			break
		end
	end
	
	if ViewArea == nil then
		if #Chain > ChainIndex + OBJECTIVE_LOOKING_AREA_OFFSET then
			ViewArea = Chain[ChainIndex + OBJECTIVE_LOOKING_AREA_OFFSET]
		else
			ViewArea = Chain[#Chain]
		end
	end

	LookPoint = Vec3.New(GetNavAreaCenter(ViewArea)) + Vec3.New(0, 0, MyHeight())
end