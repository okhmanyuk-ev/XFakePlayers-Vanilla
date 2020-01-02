
-- constants
	SLOW_THINK_PERIOD = 1000

	KNIFE_PRIMARY_ATTACK_DISTANCE = HUMAN_WIDTH * 2
	KNIFE_ALTERNATIVE_ATTACK_DISTANCE = KNIFE_PRIMARY_ATTACK_DISTANCE / 1.5

	OBJECTIVE_LOOKING_AREA_OFFSET = 2;

	NEAR_RADIUS = 300
	
-- movement

	SLOW_JUMP_PERIOD = 1000
	SlowJumpTime = 0
	
	ScenarioType = {
		None = 0,
		
		Walking = 1, -- randomly walk on navigation map, nothing more
		Following = 2,
		Collecting = 3,
		
		-- cstrike, czero scenarios:
		SearchingBombPlace = 4,
				
		-- DefendingBomb = 5 -- find and stay near planted c4 at bomb place (terrorist)
							 -- or find and stay near dropped c4 (backpack) (counter-terrorist)
		
		SearchingBomb = 6, -- if bomb was dropped - i need to pick up it (terrorist)
		
		-- EscapingFromBomb = 7 -- fuck you
		
		-- TODO: add hostages rescuing scenarios for cstrike, czero
		
		-- TODO: add VIP escaping scenario for cstrike, czero 
	}
	
	Scenario = ScenarioType.None
	ChainScenarion = ScenarioType.None

	Area = nil
	PrevArea = nil
	IsAreaChanged = false

	Chain = {}
	ChainIndex = 0
	ChainFinalPoint = Vec3.New()

	STUCK_CHECK_PERIOD = 500
	LastStuckMonitorTime = 0

	LastStuckCheckTime = 0
	StuckWarnings = 0
	UnstuckWarnings = 0
	StuckOrigin = Vec3.New()
	TryedToUnstuck = false
	
	FollowingPlayer = nil
	
	DestinationArea = nil
	DestinationSpot = nil
	
	TakingSpotTime = 0
	
	WalkNearArea = nil

-- look

	LookPoint = Vec3.New()
	
-- weapons

	CurrentWeapon = nil
	LastKnownWeapon = nil -- only for hint

	NeedToBuyWeapons = false

-- attack

	LastAttackTime = 0
	
-- tasks

	IsPlantingBomb = false
	IsDefusingBomb = false

	NeedToDestroy = false
	BreakablePosition = Vec3.New()
	
	IsFlashlightRecharging = false
	
	LastScoresCheckTime = 0
	
	CollectPosition = Vec3.New()
	CanCollecting = false
	CollectingBlackList = {}
	LastCollectingEntity = 0
	LastCollectingEntityName = ''
	
-- common
	IsSlowThink = false
	LastSlowThinkTime = 0

	IsSpawned = false

	IsEndOfRound = false

	IsBombPlanted = false
	IsBombDropped = false
	
	Behavior = {
		MoveWhenShooting = true,
		CrouchWhenShooting = false,
		MoveWhenReloading = true,
		AimWhenReloading = true,
		AlternativeKnifeAttack = false,
		ReloadDelay = 0,
		DuckWhenPlantingBomb = false,
		DuckWhenDefusingBomb = false,
		Psycho = false,
		
		PreReflex = 0,
		PostReflex = 0
		
		-- add DoNotWantBeBobmer : drop c4 if we have it, and do not search when it dropped
	}

	-- TODO: 
	--		make entity.lua with entity class, 
	--		put all GetEntity* functions into class,
	--		declare variables as "NearestEnemy = Entity.New()"
	
	NearestEnemy = nil
	NearestLeaderEnemy = nil
	EnemiesNearCount = 0
	HasEnemiesNear = false

	NearestFriend = nil
	NearestLeaderFriend = nil
	FriendsNearCount = 0
	HasFriendsNear = false
	
	NearestPlayer = nil
	NearestLeaderPlayer = nil
	PlayersNearCount = 0
	HasPlayersNear = false

	
	NearestEnemyInField = nil
	NearestLeaderEnemyInField = nil
	EnemiesNearInFieldCount = 0
	HasEnemiesNearInField = false

	NearestFriendInField = nil
	NearestLeaderFriendInField = nil
	FriendsNearInFieldCount = 0
	HasFriendsNearInField = false
	
	NearestPlayerInField = nil
	NearestLeaderPlayerInField = nil
	PlayersNearInFieldCount = 0
	HasPlayersNearInField = false	
	
	
	NearestVisibleEnemy = nil
	NearestVisibleLeaderEnemy = nil
	VisibleEnemiesNearCount = 0
	HasVisibleEnemiesNear = false

	NearestVisibleFriend = nil
	NearestVisibleLeaderFriend = nil
	VisibleFriendsNearCount = 0
	HasVisibleFriendsNear = false
	
	NearestVisiblePlayer = nil
	NearestVisibleLeaderPlayer = nil
	VisiblePlayersNearCount = 0
	HasVisiblePlayersNear = false
	

	NearestVisibleEnemyInField = nil
	NearestVisibleLeaderEnemyInField = nil
	VisibleEnemiesNearInFieldCount = 0
	HasVisibleEnemiesNearInField = false

	NearestVisibleFriendInField = nil
	NearestVisibleLeaderFriendInField = nil
	VisibleFriendsNearInFieldCount = 0
	HasVisibleFriendsNearInField = false
	
	NearestVisiblePlayerInField = nil
	NearestVisibleLeaderPlayerInField = nil
	VisiblePlayersNearInFieldCount = 0
	HasVisiblePlayersNearInField = false
	

	Victim = nil
	LastVictimTime = 0
	LastPreVictimTime = 0
	HasVictim = false

dofile 'ai/utils.lua' 

dofile 'ai/movement.lua' 
dofile 'ai/look.lua' 
dofile 'ai/weapons.lua'
dofile 'ai/attack.lua'
dofile 'ai/tasks.lua'

function Think()
	if IsAlive() then
		if not IsSpawned then
			Spawn()
		end
		
		Movement()
		Look() -- rename to Aim() ?
		Weapons()
		Attack()
		Tasks()
	else
		if IsSpawned then
			Die()
		end
		
		TryToRespawn()
	end
end 

function PreThink()
	IsSlowThink = DeltaTicks(LastSlowThinkTime) >= SLOW_THINK_PERIOD

	if IsSlowThink then
		LastSlowThinkTime = Ticks()
	end
	
	if not IsAlive() then
		return
	end
	
	FindCurrentWeapon()
	FindEnemiesAndFriends()
	FindVictim()
end

function PostThink()
	-- decrease recoil
	
	SetViewAngles((Vec3.New(GetViewAngles()) - Vec3.New(GetPunchAngle())):Unpack())
end

function Spawn()
	IsSpawned = true
	
	NeedToBuyWeapons = true
	
	CollectingBlackList = {}
	CanCollecting = false
	
	Behavior.Randomize()
	ResetObjectiveMovement()
	ResetStuckMonitor()
	
	print 'spawned'
end

function Die()
	IsSpawned = false
	
	print 'died'
end

function TryToRespawn()
	if not IsSlowThink then
		return
	end
	
	if (GetGameDir() == 'valve')
	or (GetGameDir() == 'dmc')
	or (GetGameDir() == 'tfc')
	or (GetGameDir() == 'gearbox') then
		PrimaryAttack()
	end
end