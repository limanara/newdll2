#include "Native.hpp"
#include "Client.hpp"
#include <RedLib.hpp>
#include <atomic>

namespace CPM {
static std::atomic<Client*> s_client{nullptr};
void SetActiveClient(Client* client){s_client.store(client);}
}

void CPMSubmitState(float x,float y,float z,float forwardX,float forwardY,float aimX,float aimY,float aimZ,
    int32_t locomotion,int32_t detailedLocomotion,int32_t upperBody,int32_t weaponState,int32_t meleeState,int32_t weaponType,
    bool weaponEquipped,bool aiming){
    if(auto* client=CPM::s_client.load())client->SendPlayerState(x,y,z,forwardX,forwardY,aimX,aimY,aimZ,
        locomotion,detailedLocomotion,upperBody,weaponState,meleeState,weaponType,weaponEquipped,aiming);
}

int32_t CPMRemoteCount(){
    if(auto* client=CPM::s_client.load())return static_cast<int32_t>(client->RemoteCount());
    return 0;
}

int32_t CPMRemoteIdAt(int32_t index){
    if(index<0)return -1;
    CPM::Client::RemoteSnapshot snapshot{};
    if(auto* client=CPM::s_client.load();client&&client->RemoteAt(static_cast<std::size_t>(index),snapshot))return static_cast<int32_t>(snapshot.playerId);
    return -1;
}

static bool GetRemote(int32_t id,CPM::Client::RemoteSnapshot& snapshot){
    if(id<0)return false;
    if(auto* client=CPM::s_client.load())return client->RemoteById(static_cast<std::uint32_t>(id),snapshot);
    return false;
}

bool CPMRemoteExists(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot);}
float CPMRemoteX(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.x:0.0f;}
float CPMRemoteY(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.y:0.0f;}
float CPMRemoteZ(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.z:0.0f;}
float CPMRemoteYaw(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.yaw:0.0f;}
float CPMRemoteVelocity(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.velocity:0.0f;}
float CPMRemoteAimX(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.aimX:0.0f;}
float CPMRemoteAimY(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.aimY:0.0f;}
float CPMRemoteAimZ(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.aimZ:0.0f;}
int32_t CPMRemoteLocomotion(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.locomotion:0;}
int32_t CPMRemoteDetailedLocomotion(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.detailedLocomotion:0;}
int32_t CPMRemoteUpperBody(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.upperBody:0;}
int32_t CPMRemoteWeaponState(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.weaponState:0;}
int32_t CPMRemoteMeleeState(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.meleeState:0;}
int32_t CPMRemoteWeaponType(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?snapshot.weaponType:-1;}
bool CPMRemoteWeaponEquipped(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)&&(snapshot.flags&CPM::Protocol::WeaponEquipped)!=0;}
bool CPMRemoteAiming(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)&&(snapshot.flags&CPM::Protocol::Aiming)!=0;}
int32_t CPMRemoteShotEvent(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?static_cast<int32_t>(snapshot.shotEvent):0;}
int32_t CPMRemoteReloadEvent(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?static_cast<int32_t>(snapshot.reloadEvent):0;}
int32_t CPMRemoteMeleeEvent(int32_t id){CPM::Client::RemoteSnapshot snapshot{};return GetRemote(id,snapshot)?static_cast<int32_t>(snapshot.meleeEvent):0;}

RTTI_DEFINE_GLOBALS({
    RTTI_FUNCTION(CPMSubmitState);
    RTTI_FUNCTION(CPMRemoteCount);
    RTTI_FUNCTION(CPMRemoteIdAt);
    RTTI_FUNCTION(CPMRemoteExists);
    RTTI_FUNCTION(CPMRemoteX);
    RTTI_FUNCTION(CPMRemoteY);
    RTTI_FUNCTION(CPMRemoteZ);
    RTTI_FUNCTION(CPMRemoteYaw);
    RTTI_FUNCTION(CPMRemoteVelocity);
    RTTI_FUNCTION(CPMRemoteAimX); RTTI_FUNCTION(CPMRemoteAimY); RTTI_FUNCTION(CPMRemoteAimZ);
    RTTI_FUNCTION(CPMRemoteLocomotion); RTTI_FUNCTION(CPMRemoteDetailedLocomotion);
    RTTI_FUNCTION(CPMRemoteUpperBody); RTTI_FUNCTION(CPMRemoteWeaponState); RTTI_FUNCTION(CPMRemoteMeleeState);
    RTTI_FUNCTION(CPMRemoteWeaponType); RTTI_FUNCTION(CPMRemoteWeaponEquipped); RTTI_FUNCTION(CPMRemoteAiming);
    RTTI_FUNCTION(CPMRemoteShotEvent); RTTI_FUNCTION(CPMRemoteReloadEvent); RTTI_FUNCTION(CPMRemoteMeleeEvent);
});
