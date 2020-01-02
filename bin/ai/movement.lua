function Movement()
	if IsAttacking() then
		ResetStuckMonitor()
	end
	
	if Behavior.CrouchWhenShooting and ShouldCombatMovementAdditions() and not NeedToDestroy then
		Duck()
	end
	
	if not Behavior.MoveWhenShooting and ShouldCombatMovementAdditions() then
		return
	end

	if not Behavior.MoveWhenReloading and IsReloading() and ShouldCombatMovementAdditions() then
		return
	end

	if IsPlantingBomb then
		return
	end
	
	if IsDefusingBomb then
		return
	end
	
	if HasNavigation() and not Idle then
		ObjectiveMovement()
	else
		PrimitiveMovement()		
	end
		
	if not Idle then
		if HasFriendsNear and (GetDistance(NearestFriend) < 50) then
			MoveOut(NearestFriend)
		end
	else
		if HasPlayersNear and (GetDistance(NearestPlayer) < 50) then
			MoveOut(NearestPlayer)
		end
	end
end

function PrimitiveMovement()
	if HasPlayersNear then
		if GetDistance(NearestPlayer) > 200 then
			MoveTo(NearestPlayer)
		end
	end
end

function ObjectiveMovement()
	if GetMaxSpeed() <= 1 then -- we at freezetime ?
		ResetStuckMonitor()
	end
	
	local A = nil
	
	if HasWorld() then
		A = GetNavArea(GetGroundedOriginEx()) 
	else
		A = GetNavArea()
	end
	
	IsAreaChanged = Area ~= A
	
	if IsAreaChanged then
		PrevArea = Area
		Area = A
	end
	
	if GetNavAreaFlags(Area) & NAV_AREA_CROUCH > 0 then
		Duck()
	end
	
	if IsSlowThink or (Scenario == ScenarioType.None) then
		UpdateScenario()
	end
	
	if Scenario ~= ChainScenario then
		ResetObjectiveMovement()
	end
	
	-- simple
	
	if Scenario == ScenarioType.Walking then
		ObjectiveWalking()
		
	elseif Scenario == ScenarioType.Following then
		ObjectiveFollowing()
		
	elseif Scenario == ScenarioType.Collecting then
		ObjectiveCollecting()	
	
	
	-- specialized
	
	-- cstrike, czero
	
	elseif Scenario == ScenarioType.SearchingBombPlace then
		ObjectiveSearchingBombPlace()
		
	elseif Scenario == ScenarioType.SearchingBomb then
		ObjectiveSearchingBomb()
	
	else
		print('ObjectiveMovement: unknown scenario ' .. Scenario)
	end
end

function ResetObjectiveMovement()
	Chain = {}
	ChainIndex = 1
end

function ResetStuckMonitor()
	StuckWarnings = 0
end

function CheckStuckMonitor()
	if DeltaTicks(LastStuckMonitorTime) < STUCK_CHECK_PERIOD then
		return
	end
	
	LastStuckMonitorTime = Ticks()
	
	if DeltaTicks(LastStuckCheckTime) >= STUCK_CHECK_PERIOD * 2 then
		ResetStuckMonitor()
	end
	
	LastStuckCheckTime = Ticks()
	
	local Divider = 3
	
	if IsCrouching() then
		Divider = 6
	end
	
	if GetDistance(StuckOrigin:Unpack()) < GetMaxSpeed() / Divider then 
		StuckWarnings = StuckWarnings + 1
	else
		StuckWarnings = StuckWarnings - 1
		
		if TryedToUnstuck then
			UnstuckWarnings = UnstuckWarnings + 1
			
			if UnstuckWarnings >= 2 then
				TryedToUnstuck = false
			end
		else
			UnstuckWarnings = 0
		end
	end
	
	if StuckWarnings > 3 then
		StuckWarnings = 3
	end
	
	if StuckWarnings < 0 then
		StuckWarnings = 0
	end
	
	if StuckWarnings >= 3 then
		if TryedToUnstuck then
			ResetObjectiveMovement()
			TryedToUnstuck = false
		else
			DuckJump()
			ResetStuckMonitor()
			TryedToUnstuck = true
		end
	end
	
	StuckOrigin = Vec3.New(GetOrigin())
end

function MoveOnChain(AFinalRadius) -- return false when finished or movement ruined (stucked, moved out of chain)
	CheckStuckMonitor()
	
	if not HasChain() then
		return false
	end

	if ChainIndex > #Chain then
		return false
	end
	
	for I = ChainIndex + 1, #Chain do
		if Area == Chain[I] then
			ChainIndex = I
			break
		end
	end
	
	local Next = Chain[ChainIndex]
	local Last = Chain[#Chain]
	
	if Area == Last then
		local Finished = false
		
		if AFinalRadius then
			Finished = GetGroundedDistance(ChainFinalPoint:Unpack()) < AFinalRadius
		else
			Finished = GetGroundedDistance(ChainFinalPoint:Unpack()) < HUMAN_WIDTH -- default final radius
		end
		
		if Finished then
			return false
		else
			MoveTo(ChainFinalPoint:Unpack())
		end
	else
		if Area == Next then
			ChainIndex = ChainIndex + 1
			MoveOnChain()
		else
			if IsNavAreaConnected(Area, Next) then	
				local Origin = Vec3.New(GetOrigin())
				local BestPoint = Vec3.New()
				
				if ChainIndex == #Chain then
					BestPoint = ChainFinalPoint
				else
					for I = ChainIndex, #Chain - 1 do
						local Finished = false
						local Portal = Vec3.New() 
						
						if IsNavAreaConnected(Chain[I], Chain[I + 1]) then
							Portal = Vec3.New(GetNavAreaPortal(Chain[I], Chain[I + 1]))
						else
							BestPoint = Vec3.New(GetNavAreaCenter(Next))
							break
						end
								
						local Path = Vec2Line.New(Origin.X, Origin.Y, Portal.X, Portal.Y)
						
						for J = ChainIndex + 1, I do
							local Window = Vec3Line.New(GetNavAreaWindowEx(Chain[J - 1], Chain[J]))
							
							if not Window:IsIntersect2D(Path) then
								Finished = true
								break
							end
						end
						
						if Finished then
							break
						end
						
						BestPoint = Portal
					end
				end
				
				local Portal = Vec3.New(GetNavAreaPortal(Area, Next, Origin.X, Origin.Y, Origin.Z, BestPoint.X, BestPoint.Y, BestPoint.Z))
				
				if GetDistance2D(Portal:Unpack()) > HUMAN_WIDTH * 1.5 then
					MoveTo(Portal:Unpack())
				else 
					MoveTo(BestPoint:Unpack())
					
					if ((GetNavAreaFlags(Area) & NAV_AREA_NO_JUMP == 0) and not IsNavAreaBiLinked(Area, Next)) -- to prevent erroneous jumps - we need to add height comparing between two areas
					or (GetNavAreaFlags(Next) & NAV_AREA_JUMP > 0) -- area must be small for working, add checking for area sizes
					or (GetNavAreaFlags(Area) & NAV_AREA_JUMP > 0) then
						SlowDuckJump()
					end
					
					if GetNavAreaFlags(Next) & NAV_AREA_CROUCH > 0 then
						Duck()
					end 
				end
			else
				if IsSlowThink and IsOnGround() then
					return false
				else
					MoveTo(GetNavAreaCenter(Next)) 
				end
			end
		end
	end
	
	return true
end

function BuildChain(ADestination, AHintText)
	ResetObjectiveMovement()
	ResetStuckMonitor()

	Chain = {GetNavChain(Area, GetNavArea(ADestination:Unpack()))}
	
	if HasChain() then
		if AHintText then
			print(AHintText .. ' ' .. GetNavAreaName(Chain[#Chain]))
		end

		ChainFinalPoint = ADestination
		ChainScenario = Scenario
		return true
	else	
		return false
	end
end

function BuildChainToArea(AArea, AHintText)
	return BuildChain(Vec3.New(GetNavAreaCenter(AArea)), AHintText)
end

function ObjectiveMoveTo(ADestination, AFinalRadius) -- return false when finished
	local Finished = false
	
	if AFinalRadius then
		Finished = GetDistance(ADestination:Unpack()) <= AFinalRadius
	else
		Finished = GetDistance(ADestination:Unpack()) <= HUMAN_WIDTH * 1.5
	end

	if Finished then
		return false
	end
	
	if ((ChainFinalPoint ~= ADestination) and IsSlowThink) or (HasChain() and (Chain[#Chain] ~= GetNavArea(ADestination:Unpack()))) then
		ResetObjectiveMovement()
	end
	
	if not MoveOnChain(AFinalRadius) then
		BuildChain(ADestination)
		MoveOnChain(AFinalRadius)
	end
	
	return true
end

function TakeSpot(ADestination) -- return false when spot reached
	if not ObjectiveMoveTo(ADestination, HUMAN_WIDTH_HALF) then
		Duck()
		return false
	end

	if GetGroundedDistance(ADestination:Unpack()) <= 100 then
		Duck()
	end
	
	return true
end

function Follow(ADestination) 
	ObjectiveMoveTo(ADestination, 250) -- TODO: write better code later
end

function IsReachable(ADestination)
	local C = {GetNavChain(Area, GetNavArea(ADestination:Unpack()))}

	return #C > 0
end

----------------------------------------------------
------------------ SCENARIOS -----------------------
----------------------------------------------------

function ObjectiveWalking(AHintText)
	if not MoveOnChain() then
		local S = 'walking to'
		
		if AHintText then
			S = AHintText
		end
		
		BuildChainToArea(GetRandomNavArea(), S)
	end
end

function ObjectiveFollowing() -- test
	if HasPlayersNear then
		Follow(Vec3.New(GetPlayerOrigin(NearestPlayer - 1)))
	end
end

function ObjectiveCollecting()
	if GetDistance(CollectPosition:Unpack()) <= HUMAN_WIDTH * 1.5 then
		CanCollecting = false
	end
	
	if not CanCollecting then
		return
	end
	
	local A = nil
	
	if HasChain() then
		A = Chain[#Chain]
	end
	
	if ((ChainFinalPoint ~= CollectPosition) and IsSlowThink) or (HasChain() and (Chain[#Chain] ~= GetNavArea(CollectPosition:Unpack()))) then
		ResetObjectiveMovement()
	end
	
	if not MoveOnChain() then
		if A == GetNavArea(CollectPosition:Unpack()) then
			table.insert(CollectingBlackList, LastCollectingEntity)
			CanCollecting = false    
		else
			local S = LastCollectingEntityName
			
			if S:sub(1, 2) == 'w_' then
				S = S:sub(3)
			end
			
			BuildChain(CollectPosition, 'collecting ' .. S .. ' at')
		end
	end
end

function ObjectiveSearchingBombPlace()
	if not MoveOnChain() and IsSlowThink then
		if HasWorld() then
			local E = GetWorldRandomEntityByClassName('func_bomb_target')

			if E == nil then
				--do nav searching
				return
			end

			local M = GetModelForEntity(E)
			
			if M == nil then
				-- do nav searching
				return
			end
			
			BuildChain(GetModelGabaritesCenter(M), 'walking to bomb place at')
		else
			-- TODO: 
			-- we can find bomb places by navigation map:
			
			-- - we can randomly walk on every new nav area
			-- and finally reach bomb place (and remember this area)
			
			-- - we can use the nav place names list
			-- and find bomb place by BombplaceA, BombplaceB, BombplaceC fields (also remember it to some array)
			
			-- it is not 100% searching method to find bomb place
			-- but it can work without *.bsp
			
			ObjectiveWalking()
		end
	end
end

function ObjectiveSearchingBomb()
	if not MoveOnChain() and IsSlowThink then -- rebuild only in slowthink
		BuildChain(Vec3.New(GetBombStatePosition()), 'searching bomb at')
	end
end