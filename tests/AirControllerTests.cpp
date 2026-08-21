#include "AirController.hpp"

#include <cassert>

int main() {
    CPM::AirController controller;
    controller.Begin(7.5f);

    bool rose = false;
    bool fell = false;
    bool landed = false;
    float peak = 7.5f;

    for (int i = 0; i < 300; ++i) {
        const auto frame = controller.Update(0.016f);
        rose = rose || frame.z > 7.55f;
        fell = fell || frame.startedFalling || frame.phase == CPM::AirPhase::Falling;
        landed = landed || frame.touchedGround;
        if (frame.peakZ > peak) peak = frame.peakZ;
    }

    assert(rose);
    assert(fell);
    assert(landed);
    assert(peak > 8.0f);
    assert(controller.Frame().phase == CPM::AirPhase::Grounded);
    assert(controller.Frame().z == 7.5f);
    return 0;
}
