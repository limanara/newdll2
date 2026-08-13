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
                let orientation: Quaternion = EulerAngles.ToQuat(
                    EulerAngles(0.0, 0.0, CPMRemoteYaw(this.remotePlayerID))
                );
                let transform: WorldTransform;
                WorldTransform.SetPosition(transform, target);
                WorldTransform.SetOrientation(transform, orientation);

                // SetWorldTransform e mantido como fallback visual.
                remote.SetWorldTransform(transform);

                if IsDefined(remotePuppet) {
                    // NPCPuppet tem a transformacao controlada pela IA. Enviar o
                    // deslocamento pelo AIController impede que ele seja anulado.
                    let teleportCommand: ref<AITeleportCommand> = new AITeleportCommand();
                    teleportCommand.position = target;
                    teleportCommand.rotation = CPMRemoteYaw(this.remotePlayerID);
                    teleportCommand.doNavTest = false;
                    remotePuppet.GetAIControllerComponent().SendCommand(teleportCommand);
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
