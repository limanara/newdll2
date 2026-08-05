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
            this.remotePlayerID = -1;
        };

        if !this.hasRemoteEntity && CPMRemoteCount() > 0 {
            this.remotePlayerID = CPMRemoteIdAt(0);
            if this.remotePlayerID >= 0 {
                let spec: ref<DynamicEntitySpec> = new DynamicEntitySpec();
                spec.recordID = t"Character.spr_animals_bouncer1_ranged1_omaha_mb";
                spec.appearanceName = n"random";
                spec.position = new Vector4(CPMRemoteX(this.remotePlayerID), CPMRemoteY(this.remotePlayerID), CPMRemoteZ(this.remotePlayerID), 1.0);
                spec.orientation = EulerAngles.ToQuat(EulerAngles.new(0.0, 0.0, CPMRemoteYaw(this.remotePlayerID)));
                spec.persistState = false;
                spec.persistSpawn = false;
                spec.alwaysSpawned = true;
                spec.spawnInView = true;
                spec.active = true;
                spec.tags = [n"CPM.RemotePlayer"];
                this.remoteEntityID = entitySystem.CreateEntity(spec);
                this.hasRemoteEntity = true;
            };
        };

        if this.hasRemoteEntity {
            let remote: ref<GameObject> = entitySystem.GetEntity(this.remoteEntityID) as GameObject;
            if IsDefined(remote) {
                let target: Vector4 = new Vector4(CPMRemoteX(this.remotePlayerID), CPMRemoteY(this.remotePlayerID), CPMRemoteZ(this.remotePlayerID), 1.0);
                let rotation: EulerAngles = EulerAngles.new(0.0, 0.0, CPMRemoteYaw(this.remotePlayerID));
                GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(remote, target, rotation);
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
