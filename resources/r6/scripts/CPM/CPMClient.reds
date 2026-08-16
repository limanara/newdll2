public static native func CPMSubmitState(x: Float, y: Float, z: Float, forwardX: Float, forwardY: Float,
    aimX: Float, aimY: Float, aimZ: Float, locomotion: Int32, detailedLocomotion: Int32,
    upperBody: Int32, weaponState: Int32, meleeState: Int32, weaponType: Int32,
    weaponEquipped: Bool, aiming: Bool) -> Void
public static native func CPMRemoteCount() -> Int32
public static native func CPMRemoteIdAt(index: Int32) -> Int32
public static native func CPMRemoteExists(playerID: Int32) -> Bool
public static native func CPMRemoteX(playerID: Int32) -> Float
public static native func CPMRemoteY(playerID: Int32) -> Float
public static native func CPMRemoteZ(playerID: Int32) -> Float
public static native func CPMRemoteYaw(playerID: Int32) -> Float
public static native func CPMRemoteVelocity(playerID: Int32) -> Float
public static native func CPMRemoteAimX(playerID: Int32) -> Float
public static native func CPMRemoteAimY(playerID: Int32) -> Float
public static native func CPMRemoteAimZ(playerID: Int32) -> Float
public static native func CPMRemoteLocomotion(playerID: Int32) -> Int32
public static native func CPMRemoteDetailedLocomotion(playerID: Int32) -> Int32
public static native func CPMRemoteUpperBody(playerID: Int32) -> Int32
public static native func CPMRemoteWeaponState(playerID: Int32) -> Int32
public static native func CPMRemoteMeleeState(playerID: Int32) -> Int32
public static native func CPMRemoteWeaponType(playerID: Int32) -> Int32
public static native func CPMRemoteWeaponEquipped(playerID: Int32) -> Bool
public static native func CPMRemoteAiming(playerID: Int32) -> Bool
public static native func CPMRemoteShotEvent(playerID: Int32) -> Int32
public static native func CPMRemoteReloadEvent(playerID: Int32) -> Int32
public static native func CPMRemoteMeleeEvent(playerID: Int32) -> Int32

public class CPMRemoteVisual extends IScriptable {
    private let player: wref<PlayerPuppet>;
    private let playerID: Int32;
    private let entityID: EntityID;
    private let hasEntity: Bool;
    private let remoteOriginX: Float;
    private let remoteOriginY: Float;
    private let remoteOriginZ: Float;
    private let localAnchor: Vector4;
    private let visualPosition: Vector4;
    private let visualYaw: Float;
    private let locomotionState: Int32;
    private let locomotionCandidate: Int32;
    private let locomotionCandidateTicks: Int32;
    private let lastDetailedLocomotion: Int32;
    private let lastCrouched: Bool;
    private let lastAiming: Bool;
    private let lastShotEvent: Int32;
    private let lastReloadEvent: Int32;
    private let lastMeleeEvent: Int32;
    private let activeMoveCommand: ref<AIMoveToCommand>;
    private let activeAimCommand: ref<AIAimAtTargetCommand>;
    private let activeShootCommand: ref<AIShootCommand>;
    private let activeMeleeCommand: ref<AIMeleeAttackCommand>;
    private let weaponRequested: Bool;
    private let meleeResetTicks: Int32;
    private let reloadTicks: Int32;
    private let airborne: Bool;

    public func Initialize(player: ref<PlayerPuppet>, playerID: Int32, slot: Int32) -> Void {
        this.player = player;
        this.playerID = playerID;
        this.remoteOriginX = CPMRemoteX(playerID);
        this.remoteOriginY = CPMRemoteY(playerID);
        this.remoteOriginZ = CPMRemoteZ(playerID);
        let playerPosition: Vector4 = player.GetWorldPosition();
        let playerForward: Vector4 = player.GetWorldForward();
        let playerRight: Vector4 = Vector4(-playerForward.Y, playerForward.X, 0.0, 0.0);
        let sideOffset: Float = Cast<Float>(slot) * 1.75 - 3.5;
        let frontOffset: Float = 4.0;
        this.localAnchor = playerPosition + playerForward * frontOffset + playerRight * sideOffset;
        this.localAnchor.W = 1.0;
        this.visualPosition = this.localAnchor;
        this.visualYaw = CPMRemoteYaw(playerID);
        this.locomotionState = -1;
        this.locomotionCandidate = 0;
        this.locomotionCandidateTicks = 0;
        this.lastDetailedLocomotion = -1;
        this.lastCrouched = false;
        this.lastAiming = false;
        this.lastShotEvent = CPMRemoteShotEvent(playerID);
        this.lastReloadEvent = CPMRemoteReloadEvent(playerID);
        this.lastMeleeEvent = CPMRemoteMeleeEvent(playerID);
        this.weaponRequested = false;
        this.meleeResetTicks = 0;
        this.reloadTicks = 0;
        this.airborne = false;
        this.Spawn();
    }

    public func GetPlayerID() -> Int32 { return this.playerID; }

    public func Destroy() -> Void {
        if this.hasEntity {
            let entitySystem: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem();
            if IsDefined(entitySystem) { entitySystem.DeleteEntity(this.entityID); };
            this.hasEntity = false;
        };
    }

    public func Update() -> Void {
        if !CPMRemoteExists(this.playerID) { return; };
        if !this.hasEntity {
            this.Spawn();
            return;
        };
        let entitySystem: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem();
        if !IsDefined(entitySystem) || !entitySystem.IsReady() { return; };
        let remote: ref<Entity> = entitySystem.GetEntity(this.entityID);
        if !IsDefined(remote) { return; };
        let remoteObject: ref<GameObject> = remote as GameObject;
        let remotePuppet: ref<NPCPuppet> = remote as NPCPuppet;
        if !IsDefined(remoteObject) || !IsDefined(remotePuppet) { return; };
        let target: Vector4 = Vector4(
            this.localAnchor.X + CPMRemoteX(this.playerID) - this.remoteOriginX,
            this.localAnchor.Y + CPMRemoteY(this.playerID) - this.remoteOriginY,
            this.localAnchor.Z + CPMRemoteZ(this.playerID) - this.remoteOriginZ,
            1.0
        );
        this.UpdateLocomotion(remotePuppet, target);
        this.UpdateNetworkStates(remotePuppet);
        this.InterpolateTransform(remoteObject, target);
    }

    private func UpdateNetworkStates(remote: ref<NPCPuppet>) -> Void {
        let detailed: Int32 = CPMRemoteDetailedLocomotion(this.playerID);
        let crouched: Bool = CPMRemoteLocomotion(this.playerID) == 1 || detailed == 3 || detailed == 30;
        if (crouched && !this.lastCrouched) || (!crouched && this.lastCrouched) {
            let stance: ref<AnimFeature_Stance> = new AnimFeature_Stance();
            if crouched { stance.SetStanceState(animStanceState.Crouch); }
            else { stance.SetStanceState(animStanceState.Stand); };
            AnimationControllerComponent.ApplyFeature(remote, n"Stance", stance);
            this.lastCrouched = crouched;
        };
        this.UpdateAirState(remote, detailed);
        let aiming: Bool = CPMRemoteAiming(this.playerID);
        if aiming {
            let aim: ref<AnimFeature_Aim> = new AnimFeature_Aim();
            let aimPoint: Vector4 = Vector4(
                this.visualPosition.X + CPMRemoteAimX(this.playerID) * 20.0,
                this.visualPosition.Y + CPMRemoteAimY(this.playerID) * 20.0,
                this.visualPosition.Z + CPMRemoteAimZ(this.playerID) * 20.0,
                1.0
            );
            aim.Aim(aimPoint);
            AnimationControllerComponent.ApplyFeature(remote, n"NonCombatAim", aim);
        };
        if aiming && !this.lastAiming {
            this.StartAim(remote);
        } else {
            if !aiming && this.lastAiming {
                this.StopAim(remote);
            };
        };
        this.lastAiming = aiming;
        if CPMRemoteWeaponEquipped(this.playerID) && !this.weaponRequested {
            let equip: ref<AIEquipCommand> = new AIEquipCommand();
            equip.slotId = t"AttachmentSlots.WeaponRight";
            equip.itemId = t"Items.Preset_Omaha_Default";
            equip.failIfItemNotFound = false;
            equip.durationOverride = 0.50;
            remote.GetAIControllerComponent().SendCommand(equip);
            this.weaponRequested = true;
        };
        let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(remote);
        let shotEvent: Int32 = CPMRemoteShotEvent(this.playerID);
        if shotEvent != this.lastShotEvent {
            this.ExecuteShot(remote);
            this.lastShotEvent = shotEvent;
        };
        let reloadEvent: Int32 = CPMRemoteReloadEvent(this.playerID);
        if reloadEvent != this.lastReloadEvent {
            this.ExecuteReload(remote, weapon);
            this.lastReloadEvent = reloadEvent;
        };
        let meleeEvent: Int32 = CPMRemoteMeleeEvent(this.playerID);
        if meleeEvent != this.lastMeleeEvent {
            this.ExecuteMelee(remote);
            this.lastMeleeEvent = meleeEvent;
        };
        if this.reloadTicks > 0 {
            this.reloadTicks -= 1;
            if this.reloadTicks == 0 && IsDefined(weapon) {
                weapon.StopReload(gameweaponReloadStatus.Standard);
                WeaponObject.TriggerWeaponEffects(weapon, gamedataFxAction.ExitReload);
                AnimationControllerComponent.PushEventToReplicate(weapon, n"ReloadEnd");
                AnimationControllerComponent.PushEventToReplicate(remote, n"ReloadEnd");
            };
        };
        if this.meleeResetTicks > 0 {
            this.meleeResetTicks -= 1;
            if this.meleeResetTicks == 0 {
                let resetMelee: ref<AnimFeature_QuickMelee> = new AnimFeature_QuickMelee();
                resetMelee.state = 0;
                AnimationControllerComponent.ApplyFeature(remote, n"QuickMelee", resetMelee);
            };
        };
    }

    private func UpdateAirState(remote: ref<NPCPuppet>, detailed: Int32) -> Void {
        if detailed == this.lastDetailedLocomotion { return; };
        let jumping: Bool = detailed == 18 || detailed == 19 || detailed == 20 || detailed == 21;
        let falling: Bool = detailed == 14;
        let landing: Bool = detailed >= 23 && detailed <= 27;
        if jumping || falling {
            let air: ref<AnimFeature_PlayerLocomotionStateMachine> = new AnimFeature_PlayerLocomotionStateMachine();
            air.inAirState = true;
            AnimationControllerComponent.ApplyFeature(remote, n"LocomotionStateMachine", air);
            if jumping {
                AnimationControllerComponent.PushEventToReplicate(remote, n"Jump");
            } else {
                AnimationControllerComponent.PushEventToReplicate(remote, n"InAir");
            };
            this.airborne = true;
        };
        if landing {
            let landingFeature: ref<AnimFeature_Landing> = new AnimFeature_Landing();
            landingFeature.type = 1;
            landingFeature.impactSpeed = -6.0;
            AnimationControllerComponent.ApplyFeature(remote, n"Landing", landingFeature);
            AnimationControllerComponent.PushEventToReplicate(remote, n"Land");
            let ground: ref<AnimFeature_PlayerLocomotionStateMachine> = new AnimFeature_PlayerLocomotionStateMachine();
            ground.inAirState = false;
            AnimationControllerComponent.ApplyFeature(remote, n"LocomotionStateMachine", ground);
            this.airborne = false;
        };
        this.lastDetailedLocomotion = detailed;
    }

    private func PlayerReference() -> EntityReference {
        let communityEntryNames: array<CName>;
        return CreateEntityReference("#player", communityEntryNames);
    }

    private func StartAim(remote: ref<NPCPuppet>) -> Void {
        this.StopAim(remote);
        let command: ref<AIAimAtTargetCommand> = new AIAimAtTargetCommand();
        command.targetOverridePuppetRef = this.PlayerReference();
        command.duration = -1.0;
        if remote.GetAIControllerComponent().SendCommand(command) {
            this.activeAimCommand = command;
        };
    }

    private func StopAim(remote: ref<NPCPuppet>) -> Void {
        if IsDefined(this.activeAimCommand) {
            remote.GetAIControllerComponent().StopExecutingCommand(this.activeAimCommand, true);
            this.activeAimCommand = null;
        };
    }

    private func ExecuteShot(remote: ref<NPCPuppet>) -> Void {
        if IsDefined(this.activeShootCommand) {
            remote.GetAIControllerComponent().StopExecutingCommand(this.activeShootCommand, true);
            this.activeShootCommand = null;
        };
        let command: ref<AIShootCommand> = new AIShootCommand();
        command.targetOverridePuppetRef = this.PlayerReference();
        command.duration = 0.35;
        command.once = true;
        if remote.GetAIControllerComponent().SendCommand(command) {
            this.activeShootCommand = command;
        };
    }

    private func ExecuteReload(remote: ref<NPCPuppet>, weapon: ref<WeaponObject>) -> Void {
        if !IsDefined(weapon) { return; };
        weapon.StartReload(2.0);
        WeaponObject.TriggerWeaponEffects(weapon, gamedataFxAction.EnterReload);
        AnimationControllerComponent.PushEventToReplicate(weapon, n"Reload");
        AnimationControllerComponent.PushEventToReplicate(remote, n"Reload");
        this.reloadTicks = 40;
    }

    private func ExecuteMelee(remote: ref<NPCPuppet>) -> Void {
        this.StopAim(remote);
        if IsDefined(this.activeMeleeCommand) {
            remote.GetAIControllerComponent().StopExecutingCommand(this.activeMeleeCommand, true);
            this.activeMeleeCommand = null;
        };
        let command: ref<AIMeleeAttackCommand> = new AIMeleeAttackCommand();
        command.targetOverridePuppetRef = this.PlayerReference();
        command.duration = 1.50;
        if remote.GetAIControllerComponent().SendCommand(command) {
            this.activeMeleeCommand = command;
        };
        let quickMelee: ref<AnimFeature_QuickMelee> = new AnimFeature_QuickMelee();
        quickMelee.state = 1;
        AnimationControllerComponent.ApplyFeature(remote, n"QuickMelee", quickMelee);
        AnimationControllerComponent.PushEventToReplicate(remote, n"MeleeAttack");
        this.meleeResetTicks = 20;
    }

    private func Spawn() -> Void {
        let entitySystem: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem();
        if !IsDefined(entitySystem) || !entitySystem.IsReady() { return; };
        let spec: ref<DynamicEntitySpec> = new DynamicEntitySpec();
        spec.recordID = t"Character.spr_animals_bouncer1_ranged1_omaha_mb";
        spec.appearanceName = n"random";
        spec.position = this.localAnchor;
        let spawnAngles: EulerAngles;
        spawnAngles.Pitch = 0.0;
        spawnAngles.Roll = 0.0;
        spawnAngles.Yaw = this.visualYaw;
        spec.orientation = EulerAngles.ToQuat(spawnAngles);
        spec.persistState = false;
        spec.persistSpawn = false;
        spec.alwaysSpawned = true;
        spec.spawnInView = true;
        spec.active = true;
        spec.tags = [n"CPM.RemotePlayer"];
        this.entityID = entitySystem.CreateEntity(spec);
        this.hasEntity = true;
    }

    private func UpdateLocomotion(remote: ref<NPCPuppet>, target: Vector4) -> Void {
        let requestedState: Int32 = 0;
        let networkLocomotion: Int32 = CPMRemoteLocomotion(this.playerID);
        let detailed: Int32 = CPMRemoteDetailedLocomotion(this.playerID);
        let specialAction: Bool = detailed == 14 || detailed >= 18 && detailed <= 27 || CPMRemoteAiming(this.playerID) ||
            CPMRemoteWeaponState(this.playerID) == 2 || CPMRemoteWeaponState(this.playerID) == 8 ||
            CPMRemoteMeleeEvent(this.playerID) != this.lastMeleeEvent;
        if specialAction {
            this.StopLocomotion(remote);
            this.locomotionState = 0;
            this.locomotionCandidate = 0;
            this.locomotionCandidateTicks = 0;
            return;
        };
        if networkLocomotion == 1 || detailed == 3 || detailed == 30 { requestedState = 3; }
        else { if networkLocomotion == 2 || networkLocomotion == 11 || detailed == 4 { requestedState = 2; }
        else { if CPMRemoteVelocity(this.playerID) > 0.20 { requestedState = 1; }; }; };
        if requestedState != this.locomotionCandidate {
            this.locomotionCandidate = requestedState;
            this.locomotionCandidateTicks = 1;
        } else { this.locomotionCandidateTicks += 1; };
        if this.locomotionState < 0 || this.locomotionCandidateTicks >= 10 {
            if this.locomotionState != this.locomotionCandidate {
                this.locomotionState = this.locomotionCandidate;
                if this.locomotionState > 0 {
                    this.StartLocomotionAnimation(remote, target, this.locomotionState == 2, this.locomotionState == 3);
                } else { this.StopLocomotion(remote); };
            };
        };
    }

    private func StopLocomotion(remote: ref<NPCPuppet>) -> Void {
        if IsDefined(this.activeMoveCommand) {
            remote.GetAIControllerComponent().StopExecutingCommand(this.activeMoveCommand, true);
            this.activeMoveCommand = null;
        };
    }

    private func StartLocomotionAnimation(remote: ref<NPCPuppet>, target: Vector4, running: Bool, crouched: Bool) -> Void {
        this.StopLocomotion(remote);
        let dx: Float = target.X - this.visualPosition.X;
        let dy: Float = target.Y - this.visualPosition.Y;
        let animationTarget: Vector4 = Vector4(target.X + dx * 40.0, target.Y + dy * 40.0, target.Z, 1.0);
        let worldPosition: WorldPosition;
        WorldPosition.SetVector4(worldPosition, animationTarget);
        let positionSpec: AIPositionSpec;
        AIPositionSpec.SetWorldPosition(positionSpec, worldPosition);
        let command: ref<AIMoveToCommand> = new AIMoveToCommand();
        command.movementTarget = positionSpec;
        command.rotateEntityTowardsFacingTarget = false;
        command.ignoreNavigation = true;
        command.desiredDistanceFromTarget = 0.05;
        command.finishWhenDestinationReached = false;
        command.alwaysUseStealth = crouched;
        if running { command.movementType = moveMovementType.Sprint; }
        else { command.movementType = moveMovementType.Walk; };
        remote.GetAIControllerComponent().SendCommand(command);
        this.activeMoveCommand = command;
    }

    private func InterpolateTransform(remote: ref<GameObject>, target: Vector4) -> Void {
        let dx: Float = target.X - this.visualPosition.X;
        let dy: Float = target.Y - this.visualPosition.Y;
        let dz: Float = target.Z - this.visualPosition.Z;
        let distanceSquared: Float = dx * dx + dy * dy + dz * dz;
        if distanceSquared > 225.0 { this.visualPosition = target; }
        else {
            this.visualPosition.X += dx * 0.18;
            this.visualPosition.Y += dy * 0.18;
            this.visualPosition.Z += dz * 0.18;
            this.visualPosition.W = 1.0;
        };
        let networkYaw: Float = CPMRemoteYaw(this.playerID);
        let yawDelta: Float = networkYaw - this.visualYaw;
        if yawDelta > 180.0 { yawDelta -= 360.0; }
        else { if yawDelta < -180.0 { yawDelta += 360.0; }; };
        this.visualYaw += yawDelta * 0.18;
        let visualAngles: EulerAngles;
        visualAngles.Pitch = 0.0;
        visualAngles.Roll = 0.0;
        visualAngles.Yaw = this.visualYaw;
        GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(
            remote, this.visualPosition, visualAngles
        );
    }
}

public class CPMTelemetryCallback extends DelayCallback {
    private let player: wref<PlayerPuppet>;
    private let remotes: array<ref<CPMRemoteVisual>>;

    public func SetPlayer(player: ref<PlayerPuppet>) -> Void { this.player = player; }

    public func Call() -> Void {
        if IsDefined(this.player) {
            let position: Vector4 = this.player.GetWorldPosition();
            let forward: Vector4 = this.player.GetWorldForward();
            let blackboard: ref<IBlackboard> = this.player.GetPlayerStateMachineBlackboard();
            let locomotion: Int32 = blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Locomotion);
            let detailedLocomotion: Int32 = blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.LocomotionDetailed);
            let upperBody: Int32 = blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody);
            let weaponState: Int32 = blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Weapon);
            let meleeState: Int32 = blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.MeleeWeapon);
            let activeWeapon: ref<WeaponObject> = GameObject.GetActiveWeapon(this.player);
            let weaponType: Int32 = -1;
            let weaponEquipped: Bool = IsDefined(activeWeapon);
            if weaponEquipped { weaponType = EnumInt(activeWeapon.GetWeaponRecord().ItemType().Type()); };
            CPMSubmitState(position.X, position.Y, position.Z, forward.X, forward.Y,
                forward.X, forward.Y, forward.Z, locomotion, detailedLocomotion, upperBody,
                weaponState, meleeState, weaponType, weaponEquipped, upperBody == 6);
            this.SynchronizeRemotes();
            GameInstance.GetDelaySystem(this.player.GetGame()).DelayCallback(this, 0.05);
        };
    }

    private func SynchronizeRemotes() -> Void {
        let index: Int32 = ArraySize(this.remotes) - 1;
        while index >= 0 {
            let visual: ref<CPMRemoteVisual> = this.remotes[index];
            if !CPMRemoteExists(visual.GetPlayerID()) {
                visual.Destroy();
                ArrayErase(this.remotes, index);
            };
            index -= 1;
        };
        let remoteCount: Int32 = CPMRemoteCount();
        let remoteIndex: Int32 = 0;
        while remoteIndex < remoteCount {
            let remoteID: Int32 = CPMRemoteIdAt(remoteIndex);
            if remoteID >= 0 && !this.ContainsRemote(remoteID) {
                let remote: ref<CPMRemoteVisual> = new CPMRemoteVisual();
                remote.Initialize(this.player, remoteID, ArraySize(this.remotes));
                ArrayPush(this.remotes, remote);
            };
            remoteIndex += 1;
        };
        let updateIndex: Int32 = 0;
        while updateIndex < ArraySize(this.remotes) {
            this.remotes[updateIndex].Update();
            updateIndex += 1;
        };
    }

    private func ContainsRemote(playerID: Int32) -> Bool {
        let index: Int32 = 0;
        while index < ArraySize(this.remotes) {
            if this.remotes[index].GetPlayerID() == playerID { return true; };
            index += 1;
        };
        return false;
    }
}

@addField(PlayerPuppet)
private let cpmTelemetryStarted: Bool;

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
    let result: Bool = wrappedMethod();
    if !this.cpmTelemetryStarted {
        this.cpmTelemetryStarted = true;
        let callback: ref<CPMTelemetryCallback> = new CPMTelemetryCallback();
        callback.SetPlayer(this);
        GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(callback, 0.50);
    };
    return result;
}
