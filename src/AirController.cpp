#include "AirController.hpp"

#include <algorithm>

namespace CPM {

AirController::AirController(AirControllerConfig config) : config_(config) {}

void AirController::Begin(float groundZ) {
    groundZ_ = groundZ;
    landingTime_ = 0.0f;
    frame_ = {};
    frame_.phase = AirPhase::Rising;
    frame_.z = groundZ;
    frame_.peakZ = groundZ;
    frame_.verticalVelocity = config_.launchVelocity;
}

AirFrame AirController::Update(float deltaSeconds) {
    frame_.startedFalling = false;
    frame_.touchedGround = false;
    const float dt = std::clamp(deltaSeconds, 0.0f, config_.maximumStepSeconds);

    if (frame_.phase == AirPhase::Rising || frame_.phase == AirPhase::Falling) {
        frame_.verticalVelocity += config_.gravity * dt;
        frame_.z += frame_.verticalVelocity * dt;
        frame_.peakZ = std::max(frame_.peakZ, frame_.z);

        if (frame_.phase == AirPhase::Rising && frame_.verticalVelocity <= 0.0f) {
            frame_.phase = AirPhase::Falling;
            frame_.startedFalling = true;
        }

        if (frame_.phase == AirPhase::Falling && frame_.z <= groundZ_) {
            frame_.z = groundZ_;
            frame_.verticalVelocity = 0.0f;
            frame_.phase = AirPhase::Landing;
            frame_.touchedGround = true;
            landingTime_ = 0.0f;
        }
    } else if (frame_.phase == AirPhase::Landing) {
        landingTime_ += dt;
        if (landingTime_ >= config_.landingRecoverySeconds) {
            frame_.phase = AirPhase::Grounded;
        }
    }

    return frame_;
}

void AirController::Reset(float groundZ) {
    groundZ_ = groundZ;
    landingTime_ = 0.0f;
    frame_ = {};
    frame_.z = groundZ;
    frame_.peakZ = groundZ;
}

const AirFrame& AirController::Frame() const noexcept { return frame_; }
float AirController::GroundZ() const noexcept { return groundZ_; }

} // namespace CPM
