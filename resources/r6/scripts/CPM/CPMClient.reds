module CPM

public static native func CPMSubmitState(x: Float, y: Float, z: Float, forwardX: Float, forwardY: Float) -> Void

public class CPMTelemetryCallback extends DelayCallback {
    private let player: wref<PlayerPuppet>;

    public func SetPlayer(player: ref<PlayerPuppet>) -> Void {
        this.player = player;
    }

    public func Call() -> Void {
        if IsDefined(this.player) {
            let position: Vector4 = this.player.GetWorldPosition();
            let forward: Vector4 = this.player.GetWorldForward();
            CPMSubmitState(position.X, position.Y, position.Z, forward.X, forward.Y);
            GameInstance.GetDelaySystem(this.player.GetGame()).DelayCallback(this, 0.05);
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
