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
    private let transformConfirmed: Bool;
    private let hasRemoteAnchor: Bool;
    private let remoteOriginX: Float;
    private let remoteOriginY: Float;
    private let remoteOriginZ: Float;
    private let localAnchor: Vector4;
    private let visualYaw: Float;
    private let commandTick: Int32;
    private let locomotionState: Int32;

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

    private func UpdateRemoteVisual() -> Void {
        let entitySystem: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem();
        if !IsDefined(entitySystem) || !entitySystem.IsReady() {
            return;
        };

        if this.hasRemoteEntity && !CPMRemoteExists(this.remotePlayerID) {
            entitySystem.DeleteEntity(this.remoteEntityID);
            this.hasRemoteEntity = false;
            this.remoteEntityReady = false;
            this.transformConfirmed = false;
            this.hasRemoteAnchor = false;
            this.remotePlayerID = -1;
            this.commandTick = 0;
            this.locomotionState = 0;
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
                this.hasRemoteAnchor = true;
                this.visualYaw = CPMRemoteYaw(this.remotePlayerID);
                this.commandTick = 0;
                this.locomotionState = -1;

                let spec: ref<DynamicEntitySpec> = new DynamicEntitySpec();
                spec.recordID = t"Character.spr_animals_bouncer1_ranged1_omaha_mb";
                spec.appearanceName = n"random";
                spec.position = this.localAnchor;
                spec.orientation = EulerAngles.ToQuat(EulerAngles(0.0, 0.0, CPMRemoteYaw(this.remotePlayerID)));
                spec.persistState = false;
                spec.persistSpawn = false;
                spec.alwaysSpawned = true;
                spec.spawnInView = true;
                spec.active = true;
                spec.tags = [n"CPM.RemotePlayer"];
                this.remoteEntityID = entitySystem.CreateEntity(spec);
                this.hasRemoteEntity = true;
                this.remoteEntityReady = false;
                this.transformConfirmed = false;
            };
        };

        if this.hasRemoteEntity && this.hasRemoteAnchor {
            // A criacao da entidade e assincrona. GetEntity pode retornar null
            // durante alguns frames; por isso aguardamos antes de aplicar o estado.
            let remote: ref<Entity> = entitySystem.GetEntity(this.remoteEntityID);
            if IsDefined(remote) {
                let remotePuppet: ref<NPCPuppet> = remote as NPCPuppet;
                if !this.remoteEntityReady {
                    this.remoteEntityReady = true;
                    if IsDefined(remotePuppet) {
                        // O proxy remoto nao deve bloquear o jogador nem outros NPCs.
                        remotePuppet.GetAIControllerComponent().DisableCollider();
                    };
                };

                let offsetX: Float = CPMRemoteX(this.remotePlayerID) - this.remoteOriginX;
                let offsetY: Float = CPMRemoteY(this.remotePlayerID) - this.remoteOriginY;
                let offsetZ: Float = CPMRemoteZ(this.remotePlayerID) - this.remoteOriginZ;
                let target: Vector4 = Vector4(
                    this.localAnchor.X + offsetX,
                    this.localAnchor.Y + offsetY,
                    this.localAnchor.Z + offsetZ,
                    1.0
                );
                if IsDefined(remotePuppet) {
                    this.UpdateControlledPuppet(remotePuppet, target);
                } else {
                    let remoteObject: ref<GameObject> = remote as GameObject;
                    if IsDefined(remoteObject) {
                        GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(
                            remoteObject,
                            target,
                            EulerAngles(0.0, 0.0, CPMRemoteYaw(this.remotePlayerID))
                        );
                    };
                };

                if !this.transformConfirmed {
                    this.transformConfirmed = true;
                };
            };
        };
    }

    private func UpdateControlledPuppet(remote: ref<NPCPuppet>, target: Vector4) -> Void {
        let current: Vector4 = remote.GetWorldPosition();
        let dx: Float = target.X - current.X;
        let dy: Float = target.Y - current.Y;
        let dz: Float = target.Z - current.Z;
        let distanceSquared: Float = dx * dx + dy * dy + dz * dz;
        let networkYaw: Float = CPMRemoteYaw(this.remotePlayerID);
        let yawDelta: Float = networkYaw - this.visualYaw;

        if yawDelta > 180.0 {
            yawDelta -= 360.0;
        } else {
            if yawDelta < -180.0 {
                yawDelta += 360.0;
            };
        };
        this.visualYaw += yawDelta * 0.22;
        if this.visualYaw >= 360.0 {
            this.visualYaw -= 360.0;
        } else {
            if this.visualYaw < 0.0 {
                this.visualYaw += 360.0;
            };
        };

        // Erro muito grande: correcao imediata para evitar proxy perdido.
        if distanceSquared > 16.0 {
            this.SendTeleport(remote, target, this.visualYaw);
            this.commandTick = 0;
            return;
        };

        let velocity: Float = CPMRemoteVelocity(this.remotePlayerID);
        let nextState: Int32 = 0;
        if velocity > 0.20 {
            if velocity >= 4.20 {
                nextState = 2;
            } else {
                nextState = 1;
            };
        };

        this.commandTick += 1;
        if nextState == 0 {
            // Parado: apenas corrige deriva perceptivel e suaviza a rotacao.
            if distanceSquared > 0.16 || this.commandTick >= 5 {
                let smoothTarget: Vector4 = Vector4(
                    current.X + dx * 0.35,
                    current.Y + dy * 0.35,
                    current.Z + dz * 0.35,
                    1.0
                );
                this.SendTeleport(remote, smoothTarget, this.visualYaw);
                this.commandTick = 0;
            };
        } else {
            // Em movimento, deixa a IA produzir a animacao de andar/correr.
            if this.commandTick >= 5 || nextState != this.locomotionState {
                this.SendMoveCommand(remote, target, nextState == 2);
                this.commandTick = 0;
            };

            // Correcao moderada somente quando a navegacao fica atrasada.
            if distanceSquared > 2.25 {
                let correction: Vector4 = Vector4(
                    current.X + dx * 0.45,
                    current.Y + dy * 0.45,
                    current.Z + dz * 0.45,
                    1.0
                );
                this.SendTeleport(remote, correction, this.visualYaw);
            };
        };
        this.locomotionState = nextState;
    }

    private func SendTeleport(remote: ref<NPCPuppet>, position: Vector4, yaw: Float) -> Void {
        let command: ref<AITeleportCommand> = new AITeleportCommand();
        command.position = position;
        command.rotation = yaw;
        command.doNavTest = false;
        remote.GetAIControllerComponent().SendCommand(command);
    }

    private func SendMoveCommand(remote: ref<NPCPuppet>, position: Vector4, running: Bool) -> Void {
        let worldPosition: WorldPosition;
        WorldPosition.SetVector4(worldPosition, position);
        // AIPositionSpec e uma struct nativa, portanto deve ser criada por valor.
        let positionSpec: AIPositionSpec;
        AIPositionSpec.SetWorldPosition(positionSpec, worldPosition);

        let command: ref<AIMoveToCommand> = new AIMoveToCommand();
        command.movementTarget = positionSpec;
        command.rotateEntityTowardsFacingTarget = false;
        command.ignoreNavigation = false;
        command.desiredDistanceFromTarget = 0.10;
        if running {
            command.movementType = n"Sprint";
        } else {
            command.movementType = n"Walk";
        };
        command.finishWhenDestinationReached = true;
        command.alwaysUseStealth = false;
        remote.GetAIControllerComponent().SendCommand(command);
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
