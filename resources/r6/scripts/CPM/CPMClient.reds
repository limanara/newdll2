public static native func CPMSubmitState(x: Float, y: Float, z: Float, forwardX: Float, forwardY: Float) -> Void
public static native func CPMRemoteCount() -> Int32
public static native func CPMRemoteIdAt(index: Int32) -> Int32
public static native func CPMRemoteExists(playerID: Int32) -> Bool
public static native func CPMRemoteX(playerID: Int32) -> Float
public static native func CPMRemoteY(playerID: Int32) -> Float
public static native func CPMRemoteZ(playerID: Int32) -> Float
public static native func CPMRemoteYaw(playerID: Int32) -> Float
public static native func CPMRemoteVelocity(playerID: Int32) -> Float

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
        this.InterpolateTransform(remoteObject, target);
    }

    private func Spawn() -> Void {
        let entitySystem: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem();
        if !IsDefined(entitySystem) || !entitySystem.IsReady() { return; };
        let spec: ref<DynamicEntitySpec> = new DynamicEntitySpec();
        spec.recordID = t"Character.spr_animals_bouncer1_ranged1_omaha_mb";
        spec.appearanceName = n"random";
        spec.position = this.localAnchor;
        spec.orientation = EulerAngles.ToQuat(EulerAngles(0.0, 0.0, this.visualYaw));
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
        let velocity: Float = CPMRemoteVelocity(this.playerID);
        let requestedState: Int32 = 0;
        if velocity > 0.20 {
            if velocity >= 4.20 { requestedState = 2; } else { requestedState = 1; };
        };
        if requestedState != this.locomotionCandidate {
            this.locomotionCandidate = requestedState;
            this.locomotionCandidateTicks = 1;
        } else { this.locomotionCandidateTicks += 1; };
        if this.locomotionState < 0 || this.locomotionCandidateTicks >= 10 {
            if this.locomotionState != this.locomotionCandidate {
                this.locomotionState = this.locomotionCandidate;
                if this.locomotionState > 0 {
                    this.StartLocomotionAnimation(remote, target, this.locomotionState == 2);
                };
            };
        };
    }

    private func StartLocomotionAnimation(remote: ref<NPCPuppet>, target: Vector4, running: Bool) -> Void {
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
        command.alwaysUseStealth = false;
        if running { command.movementType = moveMovementType.Sprint; }
        else { command.movementType = moveMovementType.Walk; };
        remote.GetAIControllerComponent().SendCommand(command);
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
        GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(
            remote, this.visualPosition, EulerAngles(0.0, 0.0, this.visualYaw)
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
            CPMSubmitState(position.X, position.Y, position.Z, forward.X, forward.Y);
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
