#pragma once
#include "AirController.hpp"
#include <cstdint>

namespace CPM {

enum class AvatarMotionPhase : std::uint8_t {
    Grounded,
    Rising,
    Falling,
    Landing
};

struct RemoteAvatarInput {
    float deltaSeconds = 0.0f;
    float targetX = 0.0f;
    float targetY = 0.0f;
    float targetYaw = 0.0f;
    float groundZ = 0.0f;
    float horizontalSpeed = 0.0f;
    bool jumpStarted = false;
};

struct RemoteAvatarFrame {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float yaw = 0.0f;
    float verticalVelocity = 0.0f;
    AvatarMotionPhase phase = AvatarMotionPhase::Grounded;
    bool startedFalling = false;
    bool touchedGround = false;
};

class RemoteAvatarController {
public:
    void Initialize(float x, float y, float z, float yaw);
    RemoteAvatarFrame Update(const RemoteAvatarInput& input);
    [[nodiscard]] const RemoteAvatarFrame& Frame() const noexcept;

private:
    static float Approach(float value, float target, float maximumDelta);
    static float ApproachAngle(float value, float target, float maximumDelta);
    RemoteAvatarFrame frame_{};
    AirController air_{};
    bool initialized_ = false;
};

} // namespace CPM
