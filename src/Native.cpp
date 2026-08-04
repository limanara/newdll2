#include "Native.hpp"
#include "Client.hpp"
#include <RedLib.hpp>
#include <atomic>

namespace CPM {
static std::atomic<Client*> s_client{nullptr};
void SetActiveClient(Client* client){s_client.store(client);}
}

void CPMSubmitState(float x,float y,float z,float forwardX,float forwardY){
    if(auto* client=CPM::s_client.load())client->SendPlayerState(x,y,z,forwardX,forwardY);
}

RTTI_DEFINE_GLOBALS({
    RTTI_FUNCTION(CPMSubmitState);
});
