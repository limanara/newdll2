#include "Native.hpp"
#include "Client.hpp"
#include "Logger.hpp"
#include <RedLib.hpp>
#include <atomic>

namespace CPM {
static std::atomic<Client*> s_client{nullptr};
void SetActiveClient(Client* client){s_client.store(client);}
}

void CPMSubmitState(float x,float y,float z,float forwardX,float forwardY){
    if(auto* client=CPM::s_client.load())client->SendPlayerState(x,y,z,forwardX,forwardY);
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

void CPMVisualEvent(int32_t code,int32_t playerId){
    const char* event="evento desconhecido";
    switch(code){
        case 1:event="spawn solicitado";break;
        case 2:event="entidade pronta";break;
        case 3:event="transformacao aplicada";break;
        case 4:event="entidade removida";break;
    }
    CPM::Logger::Get().Info("Visual remoto "+std::to_string(playerId)+": "+event+".");
}

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
    RTTI_FUNCTION(CPMVisualEvent);
});
