public static native func CPMSubmitState(x: Float, y: Float, z: Float, forwardX: Float, forwardY: Float) -> Void
public static native func CPMRemoteCount() -> Int32
public static native func CPMRemoteIdAt(index: Int32) -> Int32
public static native func CPMRemoteExists(playerID: Int32) -> Bool
public static native func CPMRemoteX(playerID: Int32) -> Float
public static native func CPMRemoteY(playerID: Int32) -> Float
public static native func CPMRemoteZ(playerID: Int32) -> Float
public static native func CPMRemoteYaw(playerID: Int32) -> Float
public static native func CPMRemoteVelocity(playerID: Int32) -> Float

public class CPMTelemetryCallback extends DelayCallback {
    private let player: wref<PlayerPuppet>;
    private let remotePlayerID: Int32;
    private let remoteEntityID: EntityID;
    private let hasRemoteEntity: Bool;
    private let remoteEntityReady: Bool;
    private let hasRemoteAnchor: Bool;
    private let remoteOriginX: Float;
    private let remoteOriginY: Float;
    private let remoteOriginZ: Float;
    private let localAnchor: Vector4;
    private let visualPosition: Vector4;
    private let visualYaw: Float;
    private let locomotionState: Int32;
    private let locomotionCandidate: Int32;
    private let locomotionCandidateTicks: Int32;

    public func SetPlayer(player: ref<PlayerPuppet>) -> Void {
        this.player = player;
    }

    public func Call() -> Void {
        if IsDefined(this.player) {
            let position: Vector4 = this.player.GetWorldPosition();
            let forward: Vector4 = this.player.GetWorldForward();
            CPMSubmitState(position.X, position.Y, position.Z, forward.X, forward.Y);
            this.UpdateRemoteVisual();
            GameInstance.GetDelaySystem(this.player.GetGame()).DelayCallback(this, 0.05);
        };
    }

    private func ResetRemote() -> Void {
        this.hasRemoteEntity = false;
        this.remoteEntityReady = false;
        this.hasRemoteAnchor = false;
        this.remotePlayerID = -1;
        this.locomotionState = -1;
        this.locomotionCandidate = 0;
        this.locomotionCandidateTicks = 0;
    }

    private func UpdateRemoteVisual() -> Void {
        let entitySystem: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem();
        if !IsDefined(entitySystem) || !entitySystem.IsReady() {
            return;
        };

        if this.hasRemoteEntity && !CPMRemoteExists(this.remotePlayerID) {
            entitySystem.DeleteEntity(this.remoteEntityID);
            this.ResetRemote();
        };

        if !this.hasRemoteEntity && CPMRemoteCount() > 0 {
            this.remotePlayerID = CPMRemoteIdAt(0);
            if this.remotePlayerID >= 0 {
                let playerPosition: Vector4 = this.player.GetWorldPosition();
                let playerForward: Vector4 = this.player.GetWorldForward();
                this.remoteOriginX = CPMRemoteX(this.remotePlayerID);
                this.remoteOriginY = CPMRemoteY(this.remotePlayerID);
                this.remoteOriginZ = CPMRemoteZ(this.remotePlayerID);
                this.localAnchor = playerPosition + playerForward * 3.0;
                this.localAnchor.W = 1.0;
                this.visualPosition = this.localAnchor;
                this.visualYaw = CPMRemoteYaw(this.remotePlayerID);
                this.hasRemoteAnchor = true;
                this.locomotionState = -1;
                this.locomotionCandidate = 0;
                this.locomotionCandidateTicks = 0;

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
                this.remoteEntityID = entitySystem.CreateEntity(spec);
                this.hasRemoteEntity = true;
                this.remoteEntityReady = false;
            };
        };

        if !this.hasRemoteEntity || !this.hasRemoteAnchor {
            return;
        };

        let remote: ref<Entity> = entitySystem.GetEntity(this.remoteEntityID);
        if !IsDefined(remote) {
            return;
        };

        let remoteObject: ref<GameObject> = remote as GameObject;
        let remotePuppet: ref<NPCPuppet> = remote as NPCPuppet;
        if !IsDefined(remoteObject) || !IsDefined(remotePuppet) {
            return;
        };
        this.remoteEntityReady = true;

        let target: Vector4 = Vector4(
            this.localAnchor.X + CPMRemoteX(this.remotePlayerID) - this.remoteOriginX,
            this.localAnchor.Y + CPMRemoteY(this.remotePlayerID) - this.remoteOriginY,
            this.localAnchor.Z + CPMRemoteZ(this.remotePlayerID) - this.remoteOriginZ,
            1.0
        );

        this.UpdateLocomotion(remotePuppet, target);
        this.InterpolateTransform(remoteObject, target);
    }

    private func UpdateLocomotion(remote: ref<NPCPuppet>, target: Vector4) -> Void {
        let velocity: Float = CPMRemoteVelocity(this.remotePlayerID);
        let requestedState: Int32 = 0;
        if velocity > 0.20 {
            if velocity >= 4.20 {
                requestedState = 2;
            } else {
                requestedState = 1;
            };
        };

        if requestedState != this.locomotionCandidate {
            this.locomotionCandidate = requestedState;
            this.locomotionCandidateTicks = 1;
        } else {
            this.locomotionCandidateTicks += 1;
        };

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
        let animationTarget: Vector4 = Vector4(
            target.X + dx * 40.0,
            target.Y + dy * 40.0,
            target.Z,
            1.0
        );
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
        if running {
            command.movementType = moveMovementType.Sprint;
        } else {
            command.movementType = moveMovementType.Walk;
        };
        remote.GetAIControllerComponent().SendCommand(command);
    }

    private func InterpolateTransform(remote: ref<GameObject>, target: Vector4) -> Void {
        let dx: Float = target.X - this.visualPosition.X;
        let dy: Float = target.Y - this.visualPosition.Y;
        let dz: Float = target.Z - this.visualPosition.Z;
        let distanceSquared: Float = dx * dx + dy * dy + dz * dz;

        // Spawn/recovery only. Normal motion never uses AITeleportCommand.
        if distanceSquared > 225.0 {
            this.visualPosition = target;
        } else {
            this.visualPosition.X += dx * 0.18;
            this.visualPosition.Y += dy * 0.18;
            this.visualPosition.Z += dz * 0.18;
            this.visualPosition.W = 1.0;
        };

        let networkYaw: Float = CPMRemoteYaw(this.remotePlayerID);
        let yawDelta: Float = networkYaw - this.visualYaw;
        if yawDelta > 180.0 {
            yawDelta -= 360.0;
        } else {
            if yawDelta < -180.0 {
                yawDelta += 360.0;
            };
        };
        this.visualYaw += yawDelta * 0.18;

        GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(
            remote,
            this.visualPosition,
            EulerAngles(0.0, 0.0, this.visualYaw)
        );
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
