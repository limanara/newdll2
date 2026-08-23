#include "RemoteAvatarController.hpp"
#include <cassert>
#include <cmath>

int main(){
    CPM::RemoteAvatarController avatar;
    avatar.Initialize(0.0f,0.0f,10.0f,350.0f);

    CPM::RemoteAvatarInput input{};
    input.deltaSeconds=0.02f;
    input.targetX=20.0f;
    input.targetY=0.0f;
    input.targetYaw=10.0f;
    input.groundZ=10.0f;
    input.horizontalSpeed=5.0f;
    input.jumpStarted=true;

    auto frame=avatar.Update(input);
    assert(frame.x>0.0f&&frame.x<=0.101f);
    assert(frame.z>10.0f);
    assert(frame.phase==CPM::AvatarMotionPhase::Rising);
    assert(frame.yaw>350.0f&&frame.yaw<365.0f);

    input.jumpStarted=false;
    bool falling=false,landed=false;
    for(int i=0;i<300;++i){
        frame=avatar.Update(input);
        falling=falling||frame.phase==CPM::AvatarMotionPhase::Falling;
        if(frame.touchedGround){landed=true;break;}
    }
    assert(falling&&landed);
    assert(std::abs(frame.z-10.0f)<0.001f);
    return 0;
}
