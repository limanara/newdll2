#include "RemoteAvatarController.hpp"
#include <algorithm>
#include <cmath>

namespace CPM {

void RemoteAvatarController::Initialize(float x,float y,float z,float yaw){
    frame_={};
    frame_.x=x;frame_.y=y;frame_.z=z;frame_.yaw=yaw;
    air_.Reset(z);
    initialized_=true;
}

float RemoteAvatarController::Approach(float value,float target,float maximumDelta){
    return value<target?std::min(value+maximumDelta,target):std::max(value-maximumDelta,target);
}

float RemoteAvatarController::ApproachAngle(float value,float target,float maximumDelta){
    float delta=std::remainder(target-value,360.0f);
    return value+std::clamp(delta,-maximumDelta,maximumDelta);
}

RemoteAvatarFrame RemoteAvatarController::Update(const RemoteAvatarInput& input){
    if(!initialized_)Initialize(input.targetX,input.targetY,input.groundZ,input.targetYaw);
    const float dt=std::clamp(input.deltaSeconds,0.0f,0.10f);
    const float maxDistance=std::max(0.0f,input.horizontalSpeed)*dt;
    frame_.x=Approach(frame_.x,input.targetX,maxDistance);
    frame_.y=Approach(frame_.y,input.targetY,maxDistance);
    frame_.yaw=ApproachAngle(frame_.yaw,input.targetYaw,720.0f*dt);

    if(input.jumpStarted&&frame_.phase==AvatarMotionPhase::Grounded){
        air_.Begin(input.groundZ);
    }

    const AirFrame airFrame=air_.Update(dt);
    frame_.z=airFrame.z;
    frame_.verticalVelocity=airFrame.verticalVelocity;
    frame_.startedFalling=airFrame.startedFalling;
    frame_.touchedGround=airFrame.touchedGround;
    frame_.phase=static_cast<AvatarMotionPhase>(airFrame.phase);
    return frame_;
}

const RemoteAvatarFrame& RemoteAvatarController::Frame()const noexcept{return frame_;}

} // namespace CPM
