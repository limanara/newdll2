#pragma once

#include <cstdint>

namespace CPM {

enum class AirPhase : std::uint8_t {
    Grounded,
    Rising,
    Falling,
    Landing
};

struct AirControllerConfig {
    float launchVelocity = 5.6f;
    float gravity = -12.8f;
    float landingRecoverySeconds = 0.18f;
    float maximumStepSeconds = 0.10f;
};

struct AirFrame {
    AirPhase phase = AirPhase::Grounded;
    float z = 0.0f;
    float verticalVelocity = 0.0f;
    float peakZ = 0.0f;
    bool startedFalling = false;
    bool touchedGround = false;
};

class AirController {
public:
    explicit AirController(AirControllerConfig config = {});

    void Begin(float groundZ);
    AirFrame Update(float deltaSeconds);
    void Reset(float groundZ);

    [[nodiscard]] const AirFrame& Frame() const noexcept;
    [[nodiscard]] float GroundZ() const noexcept;

private:
    AirControllerConfig config_;
    AirFrame frame_;
    float groundZ_ = 0.0f;
    float landingTime_ = 0.0f;
};

} // namespace CPM
