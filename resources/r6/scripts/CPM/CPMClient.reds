public static native func CPMSubmitState(x: Float, y: Float, z: Float, forwardX: Float, forwardY: Float,
    aimX: Float, aimY: Float, aimZ: Float, locomotion: Int32, detailedLocomotion: Int32,
    upperBody: Int32, weaponState: Int32, meleeState: Int32, weaponType: Int32,
    weaponEquipped: Bool, aiming: Bool) -> Void
public static native func CPMReportVisualAction(playerID: Int32, action: Int32, state: Int32) -> Void
public static native func CPMReportAirSample(playerID: Int32, phase: Int32, networkZ: Float, actualZ: Float, startZ: Float, peakZ: Float) -> Void
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
    private let controllerPrepared: Bool;
    private let lastMoveCommandState: Int32;
    private let lastMeleeCommandState: Int32;
    private let weaponRequested: Bool;
    private let weaponUnequipRequested: Bool;
    private let meleeResetTicks: Int32;
    private let reloadTicks: Int32;
    private let airborne: Bool;
    private let meleePending: Bool;
    private let meleeGuardTicks: Int32;
    private let holsterGuardTicks: Int32;
    private let airPhase: Int32;
    private let airTicks: Int32;
    private let airStartZ: Float;
    private let airPeakZ: Float;
    private let lastAirZ: Float;

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
        this.weaponUnequipRequested = false;
        this.meleeResetTicks = 0;
        this.reloadTicks = 0;
        this.airborne = false;
        this.meleePending = false;
        this.meleeGuardTicks = 0;
        this.holsterGuardTicks = 0;
        this.airPhase = 0;
        this.airTicks = 0;
        this.airStartZ = 0.0;
        this.airPeakZ = 0.0;
        this.lastAirZ = 0.0;
        this.controllerPrepared = false;
        this.lastMoveCommandState = -999;
        this.lastMeleeCommandState = -999;
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
        if !this.controllerPrepared {
            // 0.3.0.0: keep the character controller/collider active so the
            // engine can process a real PhysicalImpulseEvent and gravity.
            remotePuppet.GetAIControllerComponent().ForceTickNextFrame();
            this.controllerPrepared = true;
            CPMReportVisualAction(this.playerID, 1, 1);
        };
        let detailed: Int32 = CPMRemoteDetailedLocomotion(this.playerID);
        let networkZ: Float = this.localAnchor.Z + CPMRemoteZ(this.playerID) - this.remoteOriginZ;
        let target: Vector4 = Vector4(
            this.localAnchor.X + CPMRemoteX(this.playerID) - this.remoteOriginX,
            this.localAnchor.Y + CPMRemoteY(this.playerID) - this.remoteOriginY,
            networkZ,
            1.0
        );
        this.UpdateLocomotion(remotePuppet, target);
        this.UpdateNetworkStates(remotePuppet);
        if this.airborne { this.ApplyAirTransform(remotePuppet, target); }
        else { this.InterpolateTransform(remoteObject, target); };
        this.ReportCommandStates(remotePuppet);
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
        let remoteWeaponEquipped: Bool = CPMRemoteWeaponEquipped(this.playerID);
        if remoteWeaponEquipped && !this.weaponRequested {
            // 0.1.0.6: guarantee that the visual puppet really owns the test weapon
            // before asking the AI controller to draw it.
            let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(remote.GetGame());
            let testWeaponID: ItemID = ItemID.FromTDBID(t"Items.Preset_Omaha_Default");
            if IsDefined(transactionSystem) && transactionSystem.GetItemQuantity(remote, testWeaponID) <= 0 {
                transactionSystem.GiveItem(remote, testWeaponID, 1);
            };
            let equip: ref<AIEquipCommand> = new AIEquipCommand();
            equip.slotId = t"AttachmentSlots.WeaponRight";
            equip.itemId = t"Items.Preset_Omaha_Default";
            equip.failIfItemNotFound = false;
            equip.durationOverride = 0.35;
            remote.GetAIControllerComponent().SendCommand(equip);
            this.weaponRequested = true;
            this.weaponUnequipRequested = false;
            AnimationControllerComponent.PushEventToReplicate(remote, n"Equip");
        };
        if !remoteWeaponEquipped {
            if this.weaponRequested && !this.weaponUnequipRequested {
                this.UnequipWeapon(remote);
                this.holsterGuardTicks = 8;
            };
            if this.holsterGuardTicks > 0 {
                this.holsterGuardTicks -= 1;
                if this.holsterGuardTicks == 0 {
                    this.ForceHolster(remote);
                };
            };
            this.weaponRequested = false;
        } else {
            this.holsterGuardTicks = 0;
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
            this.PrepareMelee(remote, weapon);
            this.lastMeleeEvent = meleeEvent;
        };
        if this.meleePending && this.meleeGuardTicks > 0 {
            let activeMeleeWeapon: ref<WeaponObject> = GameObject.GetActiveWeapon(remote);
            if !IsDefined(activeMeleeWeapon) {
                this.meleeGuardTicks = 0;
            } else {
                this.meleeGuardTicks -= 1;
                if this.meleeGuardTicks == 10 {
                    this.UnequipWeapon(remote);
                    this.ForceHolster(remote);
                };
            };
            if this.meleeGuardTicks == 0 {
                this.meleePending = false;
                this.ExecuteMelee(remote);
            };
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

        if jumping && !this.airborne {
            this.ForceStanding(remote);
            this.StopLocomotion(remote);
            let position: Vector4 = remote.GetWorldPosition();
            this.airStartZ = position.Z;
            this.airPeakZ = position.Z;
            this.lastAirZ = position.Z;
            this.airTicks = 0;
            this.airPhase = 1;
            this.airborne = true;

            let impulse: ref<PhysicalImpulseEvent> = new PhysicalImpulseEvent();
            impulse.radius = 0.50;
            impulse.worldPosition.X = position.X;
            impulse.worldPosition.Y = position.Y;
            impulse.worldPosition.Z = position.Z + 0.80;
            impulse.worldImpulse.X = CPMRemoteAimX(this.playerID) * 35.0;
            impulse.worldImpulse.Y = CPMRemoteAimY(this.playerID) * 35.0;
            impulse.worldImpulse.Z = 450.0;
            remote.QueueEvent(impulse);

            AnimationControllerComponent.PushEventToReplicate(remote, n"Jump");
            AnimationControllerComponent.PushEventToReplicate(remote, n"InAir");
            CPMReportVisualAction(this.playerID, 3, 2);
            CPMReportAirSample(this.playerID, this.airPhase, CPMRemoteZ(this.playerID), position.Z, this.airStartZ, this.airPeakZ);
        };

        if falling && this.airborne {
            this.airPhase = 2;
            AnimationControllerComponent.PushEventToReplicate(remote, n"InAir");
            AnimationControllerComponent.PushEventToReplicate(remote, n"Fall");
            CPMReportVisualAction(this.playerID, 4, 2);
        };

        if landing && this.airborne {
            this.airPhase = 3;
            CPMReportVisualAction(this.playerID, 5, 1);
        };
        this.lastDetailedLocomotion = detailed;
    }

    private func ForceStanding(remote: ref<NPCPuppet>) -> Void {
        let stance: ref<AnimFeature_Stance> = new AnimFeature_Stance();
        stance.SetStanceState(animStanceState.Stand);
        AnimationControllerComponent.ApplyFeature(remote, n"Stance", stance);
        this.lastCrouched = false;
    }

    private func UnequipWeapon(remote: ref<NPCPuppet>) -> Void {
        let unequip: ref<AIUnequipCommand> = new AIUnequipCommand();
        unequip.slotId = t"AttachmentSlots.WeaponRight";
        unequip.durationOverride = 0.25;
        let accepted: Bool = remote.GetAIControllerComponent().SendCommand(unequip);
        if accepted { CPMReportVisualAction(this.playerID, 7, 1); }
        else { CPMReportVisualAction(this.playerID, 7, -1); };
        this.weaponUnequipRequested = true;
        AnimationControllerComponent.PushEventToReplicate(remote, n"Unequip");
    }

    private func ForceHolster(remote: ref<NPCPuppet>) -> Void {
        let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(remote.GetGame());
        if !IsDefined(transactionSystem) {
            CPMReportVisualAction(this.playerID, 7, 6);
            return;
        };
        let removed: Bool = transactionSystem.RemoveItemFromSlot(
            remote, t"AttachmentSlots.WeaponRight", true, false, true
        );
        let slotEmpty: Bool = transactionSystem.IsSlotEmpty(remote, t"AttachmentSlots.WeaponRight");
        if removed || slotEmpty {
            CPMReportVisualAction(this.playerID, 7, 5);
        } else {
            CPMReportVisualAction(this.playerID, 7, 6);
        };
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

    private func PrepareMelee(remote: ref<NPCPuppet>, weapon: ref<WeaponObject>) -> Void {
        this.StopAim(remote);
        this.StopLocomotion(remote);
        if IsDefined(this.activeShootCommand) {
            remote.GetAIControllerComponent().StopExecutingCommand(this.activeShootCommand, true);
            this.activeShootCommand = null;
        };
        if IsDefined(this.activeMeleeCommand) {
            remote.GetAIControllerComponent().StopExecutingCommand(this.activeMeleeCommand, true);
            this.activeMeleeCommand = null;
        };
        if this.reloadTicks > 0 && IsDefined(weapon) {
            weapon.StopReload(gameweaponReloadStatus.Standard);
            WeaponObject.TriggerWeaponEffects(weapon, gamedataFxAction.ExitReload);
            AnimationControllerComponent.PushEventToReplicate(weapon, n"ReloadEnd");
            AnimationControllerComponent.PushEventToReplicate(remote, n"ReloadEnd");
            this.reloadTicks = 0;
        };
        this.lastAiming = false;
        this.MoveIntoMeleeRange(remote);
        this.ForceStanding(remote);
        this.UnequipWeapon(remote);
        this.ForceHolster(remote);
        this.weaponRequested = false;
        this.meleePending = true;
        // Allow the real unequip command to clear WeaponRight before punching.
        this.meleeGuardTicks = 20;
    }

    private func ExecuteMelee(remote: ref<NPCPuppet>) -> Void {
        this.StopAim(remote);
        if IsDefined(this.activeMeleeCommand) {
            remote.GetAIControllerComponent().StopExecutingCommand(this.activeMeleeCommand, true);
            this.activeMeleeCommand = null;
        };
        let command: ref<AIMeleeAttackCommand> = new AIMeleeAttackCommand();
        command.targetOverridePuppetRef = this.PlayerReference();
        command.duration = 3.00;
        if remote.GetAIControllerComponent().SendCommand(command) {
            this.activeMeleeCommand = command;
            CPMReportVisualAction(this.playerID, 11, 1);
        } else {
            CPMReportVisualAction(this.playerID, 11, -1);
        };
        let quickMelee: ref<AnimFeature_QuickMelee> = new AnimFeature_QuickMelee();
        quickMelee.state = 1;
        AnimationControllerComponent.ApplyFeature(remote, n"QuickMelee", quickMelee);
        AnimationControllerComponent.PushEventToReplicate(remote, n"QuickMelee");
        AnimationControllerComponent.PushEventToReplicate(remote, n"MeleeAttack");
        AnimationControllerComponent.PushEventToReplicate(remote, n"Attack");
        this.meleeResetTicks = 24;
    }

    private func Spawn() -> Void {
        let entitySystem: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem();
        if !IsDefined(entitySystem) || !entitySystem.IsReady() { return; };
        let spec: ref<DynamicEntitySpec> = new DynamicEntitySpec();
        spec.recordID = t"Character.animals_bouncer2_melee2_fists_mb";
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
        let airAction: Bool = detailed == 14 || detailed >= 18 && detailed <= 27;
        let specialAction: Bool = CPMRemoteAiming(this.playerID) ||
            CPMRemoteWeaponState(this.playerID) == 2 || CPMRemoteWeaponState(this.playerID) == 8 ||
            CPMRemoteMeleeEvent(this.playerID) != this.lastMeleeEvent || this.meleePending;
        if specialAction {
            this.StopLocomotion(remote);
            this.locomotionState = 0;
            this.locomotionCandidate = 0;
            this.locomotionCandidateTicks = 0;
            return;
        };
        if airAction {
            requestedState = 1;
        } else {
            if networkLocomotion == 1 || detailed == 3 || detailed == 30 { requestedState = 3; }
            else { if networkLocomotion == 2 || networkLocomotion == 11 || detailed == 4 { requestedState = 2; }
            else { if CPMRemoteVelocity(this.playerID) > 0.20 { requestedState = 1; }; }; };
        };
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
        if remote.GetAIControllerComponent().SendCommand(command) {
            this.activeMoveCommand = command;
            CPMReportVisualAction(this.playerID, 2, 1);
        } else {
            this.activeMoveCommand = null;
            CPMReportVisualAction(this.playerID, 2, -1);
        };
    }

    private func ApplyAirTransform(remote: ref<NPCPuppet>, target: Vector4) -> Void {
        // Never teleport during flight. The engine owns Z through impulse,
        // gravity and the character collider; we only observe and diagnose it.
        let actual: Vector4 = remote.GetWorldPosition();
        this.airTicks += 1;
        if actual.Z > this.airPeakZ { this.airPeakZ = actual.Z; };
        if this.airPhase == 1 && actual.Z < this.lastAirZ - 0.01 {
            this.airPhase = 2;
            AnimationControllerComponent.PushEventToReplicate(remote, n"Fall");
            CPMReportVisualAction(this.playerID, 4, 2);
        };
        this.visualPosition = actual;
        this.visualPosition.W = 1.0;
        if this.airTicks % 5 == 0 {
            CPMReportAirSample(this.playerID, this.airPhase, CPMRemoteZ(this.playerID), actual.Z, this.airStartZ, this.airPeakZ);
        };
        let grounded: Bool = actual.Z <= this.airStartZ + 0.12 && this.airTicks > 5;
        if this.airPhase == 3 && (grounded || this.airTicks >= 60) {
            let landingFeature: ref<AnimFeature_Landing> = new AnimFeature_Landing();
            landingFeature.type = 1;
            landingFeature.impactSpeed = -7.0;
            AnimationControllerComponent.ApplyFeature(remote, n"Landing", landingFeature);
            AnimationControllerComponent.PushEventToReplicate(remote, n"Land");
            AnimationControllerComponent.PushEventToReplicate(remote, n"Landing");
            this.ForceStanding(remote);
            this.airborne = false;
            this.airPhase = 0;
            if grounded {
                CPMReportVisualAction(this.playerID, 5, 5);
            } else {
                CPMReportVisualAction(this.playerID, 5, 6);
            };
        };
        this.lastAirZ = actual.Z;
        remote.GetAIControllerComponent().ForceTickNextFrame();
    }

    private func MoveIntoMeleeRange(remote: ref<NPCPuppet>) -> Void {
        let playerPosition: Vector4 = this.player.GetWorldPosition();
        let playerForward: Vector4 = this.player.GetWorldForward();
        let meleePosition: Vector4 = playerPosition + playerForward * 1.60;
        let meleeAngles: EulerAngles = Quaternion.ToEulerAngles(this.player.GetWorldOrientation());
        meleeAngles.Yaw += 180.0;
        GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(remote, meleePosition, meleeAngles);
        this.visualPosition = meleePosition;
        remote.GetAIControllerComponent().ForceTickNextFrame();
        CPMReportVisualAction(this.playerID, 12, 5);
    }

    private func ReportCommandStates(remote: ref<NPCPuppet>) -> Void {
        if IsDefined(this.activeMoveCommand) {
            let moveState: Int32 = EnumInt(remote.GetAIControllerComponent().GetCommandState(this.activeMoveCommand));
            if moveState != this.lastMoveCommandState {
                this.lastMoveCommandState = moveState;
                CPMReportVisualAction(this.playerID, 2, moveState);
            };
        };
        if IsDefined(this.activeMeleeCommand) {
            let meleeState: Int32 = EnumInt(remote.GetAIControllerComponent().GetCommandState(this.activeMeleeCommand));
            if meleeState != this.lastMeleeCommandState {
                this.lastMeleeCommandState = meleeState;
                CPMReportVisualAction(this.playerID, 11, meleeState);
            };
        };
    }

    private func InterpolateTransform(remote: ref<GameObject>, target: Vector4) -> Void {
        let dx: Float = target.X - this.visualPosition.X;
        let dy: Float = target.Y - this.visualPosition.Y;
        let dz: Float = target.Z - this.visualPosition.Z;
        let distanceSquared: Float = dx * dx + dy * dy + dz * dz;
        let networkMoving: Bool = CPMRemoteVelocity(this.playerID) > 0.20;
        if networkMoving && distanceSquared <= 100.0 {
            this.visualPosition = remote.GetWorldPosition();
            return;
        };
        if distanceSquared > 100.0 { this.visualPosition = target; }
        else {
            this.visualPosition.X += dx * 0.18;
            this.visualPosition.Y += dy * 0.18;
            if this.airborne { this.visualPosition.Z = target.Z; }
            else { this.visualPosition.Z += dz * 0.18; };
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
