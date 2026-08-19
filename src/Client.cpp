#include "Client.hpp"
#include "Logger.hpp"
#include <chrono>
#include <cmath>
#include <format>
#include <random>
#include <algorithm>
#include <vector>
#include <ws2tcpip.h>

namespace CPM {
using Clock=std::chrono::steady_clock;

std::uint64_t Client::NowMs(){return std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now().time_since_epoch()).count();}

bool Client::Start(const ConnectionConfig& config){
    if(running_.exchange(true))return false;
    sessionToken_=(static_cast<std::uint64_t>(std::random_device{}())<<32)|std::random_device{}();
    worker_=std::thread(&Client::Run,this,config);return true;
}

void Client::Stop(){
    running_=false;connected_=false;
    {std::scoped_lock lock(socketMutex_);if(socket_!=INVALID_SOCKET){closesocket(socket_);socket_=INVALID_SOCKET;}}
    if(worker_.joinable())worker_.join();WSACleanup();Logger::Get().Info("CPM Client finalizado.");
}

void Client::SendHello(){
    const auto packet=Protocol::Make(Protocol::Type::Hello,Protocol::Hello{sessionToken_});
    std::scoped_lock lock(socketMutex_);if(socket_!=INVALID_SOCKET){sendto(socket_,reinterpret_cast<const char*>(&packet),sizeof(packet),0,reinterpret_cast<const sockaddr*>(&server_),sizeof(server_));sentPackets_++;}
}

void Client::SendHeartbeat(){
    const auto packet=Protocol::Make(Protocol::Type::Heartbeat,Protocol::Heartbeat{playerId_.load(),sessionToken_,NowMs()});
    std::scoped_lock lock(socketMutex_);if(socket_!=INVALID_SOCKET){sendto(socket_,reinterpret_cast<const char*>(&packet),sizeof(packet),0,reinterpret_cast<const sockaddr*>(&server_),sizeof(server_));sentPackets_++;}
}

void Client::SendPlayerState(float x,float y,float z,float forwardX,float forwardY,float aimX,float aimY,float aimZ,
    std::int32_t locomotion,std::int32_t detailedLocomotion,std::int32_t upperBody,std::int32_t weaponState,
    std::int32_t meleeState,std::int32_t weaponType,bool weaponEquipped,bool aiming){
    if(!connected_)return;
    float velocity=0.0f;const auto now=Clock::now();
    {std::scoped_lock lock(stateMutex_);if(hasPreviousState_){const float dt=std::chrono::duration<float>(now-previousTime_).count();if(dt>0.001f){const float dx=x-previousX_,dy=y-previousY_,dz=z-previousZ_;velocity=std::sqrt(dx*dx+dy*dy+dz*dz)/dt;}}previousX_=x;previousY_=y;previousZ_=z;previousTime_=now;hasPreviousState_=true;}
    constexpr float RadToDeg=57.29577951308232f;float yaw=std::atan2(forwardY,forwardX)*RadToDeg;if(yaw<0.0f)yaw+=360.0f;
    std::uint32_t shotEvent,reloadEvent,meleeEvent;
    {std::scoped_lock lock(stateMutex_);
        if(weaponState==8&&previousWeaponState_!=8)++shotEvent_;
        if((weaponState==2&&previousWeaponState_!=2)||(upperBody==3&&previousUpperBody_!=3))++reloadEvent_;
        if(meleeState>=11&&meleeState<=21&&meleeState!=previousMeleeState_)++meleeEvent_;
        previousDetailed_=detailedLocomotion;previousUpperBody_=upperBody;previousWeaponState_=weaponState;previousMeleeState_=meleeState;
        shotEvent=shotEvent_;reloadEvent=reloadEvent_;meleeEvent=meleeEvent_;
    }
    std::uint16_t flags=0;if(weaponEquipped)flags|=Protocol::WeaponEquipped;if(aiming)flags|=Protocol::Aiming;
    const Protocol::PlayerState state{playerId_.load(),sequence_.fetch_add(1),x,y,z,yaw,velocity,aimX,aimY,aimZ,
        static_cast<std::int16_t>(locomotion),static_cast<std::int16_t>(detailedLocomotion),static_cast<std::int16_t>(upperBody),
        static_cast<std::int16_t>(weaponState),static_cast<std::int16_t>(meleeState),static_cast<std::int16_t>(weaponType),flags,
        shotEvent,reloadEvent,meleeEvent};const auto packet=Protocol::Make(Protocol::Type::PlayerState,state);
    std::scoped_lock lock(socketMutex_);if(socket_!=INVALID_SOCKET){sendto(socket_,reinterpret_cast<const char*>(&packet),sizeof(packet),0,reinterpret_cast<const sockaddr*>(&server_),sizeof(server_));sentPackets_++;}
}

std::size_t Client::RemoteCount(){
    std::scoped_lock lock(remotesMutex_);
    return remotes_.size();
}

bool Client::RemoteAt(std::size_t index,RemoteSnapshot& snapshot){
    std::scoped_lock lock(remotesMutex_);
    if(index>=remotes_.size())return false;
    std::vector<std::uint32_t> ids;ids.reserve(remotes_.size());
    for(const auto& [id,remote]:remotes_)ids.push_back(id);
    std::sort(ids.begin(),ids.end());
    const auto it=remotes_.find(ids[index]);if(it==remotes_.end())return false;
    const auto& state=it->second.state;
    snapshot={state.playerId,state.x,state.y,state.z,state.yaw,state.velocity,state.aimX,state.aimY,state.aimZ,state.locomotion,state.detailedLocomotion,state.upperBody,state.weaponState,state.meleeState,state.weaponType,state.flags,state.shotEvent,state.reloadEvent,state.meleeEvent};
    return true;
}

bool Client::RemoteById(std::uint32_t playerId,RemoteSnapshot& snapshot){
    std::scoped_lock lock(remotesMutex_);
    const auto it=remotes_.find(playerId);if(it==remotes_.end())return false;
    const auto& state=it->second.state;
    snapshot={state.playerId,state.x,state.y,state.z,state.yaw,state.velocity,state.aimX,state.aimY,state.aimZ,state.locomotion,state.detailedLocomotion,state.upperBody,state.weaponState,state.meleeState,state.weaponType,state.flags,state.shotEvent,state.reloadEvent,state.meleeEvent};
    return true;
}

void Client::HandlePacket(const char* data,int bytes){
    if(bytes<static_cast<int>(sizeof(Protocol::Header)))return;const auto* header=reinterpret_cast<const Protocol::Header*>(data);if(!Protocol::Valid(*header,bytes))return;
    receivedPackets_++;lastServerPacket_=Clock::now();
    if(header->type==Protocol::Type::Welcome&&header->payloadSize==sizeof(Protocol::Welcome)){
        const auto* welcome=reinterpret_cast<const Protocol::Welcome*>(data+sizeof(Protocol::Header));const bool wasConnected=connected_.exchange(true);playerId_=welcome->playerId;
        Logger::Get().Info(std::format("{} ao CPM Server. Player ID: {}. Sessão {:016X}.",wasConnected?"Sessão confirmada":"Conectado",welcome->playerId,sessionToken_));
    }else if(header->type==Protocol::Type::Pong&&header->payloadSize==sizeof(Protocol::Pong)){
        const auto* pong=reinterpret_cast<const Protocol::Pong*>(data+sizeof(Protocol::Header));const auto now=NowMs();pingMs_=static_cast<std::uint32_t>(now>=pong->clientTimeMs?now-pong->clientTimeMs:0);
    }else if(header->type==Protocol::Type::PlayerState&&header->payloadSize==sizeof(Protocol::PlayerState)){
        const auto* state=reinterpret_cast<const Protocol::PlayerState*>(data+sizeof(Protocol::Header));if(state->playerId==playerId_.load())return;
        std::scoped_lock lock(remotesMutex_);auto& remote=remotes_[state->playerId];
        if(remote.receivedPackets>0&&state->sequence>remote.lastSequence+1)remote.lostPackets+=state->sequence-remote.lastSequence-1;
        const auto old=remote.state;
        if(remote.receivedPackets>0){
            if(old.locomotion!=state->locomotion||old.detailedLocomotion!=state->detailedLocomotion)
                Logger::Get().Info(std::format("Remoto {} | Locomocao {} detalhe {}",state->playerId,state->locomotion,state->detailedLocomotion));
            if(old.flags!=state->flags||old.upperBody!=state->upperBody||old.weaponState!=state->weaponState)
                Logger::Get().Info(std::format("Remoto {} | Combate flags {} upper {} weapon {} tipo {}",state->playerId,state->flags,state->upperBody,state->weaponState,state->weaponType));
            if(old.shotEvent!=state->shotEvent)Logger::Get().Info(std::format("Remoto {} | Evento tiro {}",state->playerId,state->shotEvent));
            if(old.reloadEvent!=state->reloadEvent)Logger::Get().Info(std::format("Remoto {} | Evento recarga {}",state->playerId,state->reloadEvent));
            if(old.meleeEvent!=state->meleeEvent)Logger::Get().Info(std::format("Remoto {} | Evento melee {}",state->playerId,state->meleeEvent));
        }
        remote.state=*state;remote.lastSequence=state->sequence;remote.receivedPackets++;remote.lastSeen=Clock::now();
        if((state->sequence%100)==0)Logger::Get().Info(std::format("Remoto {} | Seq {} | X {:.2f} Y {:.2f} Z {:.2f} | Rot {:.1f} | Vel {:.2f}",state->playerId,state->sequence,state->x,state->y,state->z,state->yaw,state->velocity));
    }else if(header->type==Protocol::Type::PlayerLeft&&header->payloadSize==sizeof(Protocol::PlayerLeft)){
        const auto* left=reinterpret_cast<const Protocol::PlayerLeft*>(data+sizeof(Protocol::Header));std::scoped_lock lock(remotesMutex_);remotes_.erase(left->playerId);Logger::Get().Info(std::format("Player remoto {} desconectou.",left->playerId));
    }
}

void Client::Run(ConnectionConfig config){
    WSADATA data{};if(WSAStartup(MAKEWORD(2,2),&data)!=0){Logger::Get().Error("WSAStartup falhou.");running_=false;return;}
    {std::scoped_lock lock(socketMutex_);socket_=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);}if(socket_==INVALID_SOCKET){Logger::Get().Error("Não foi possível criar o socket UDP.");running_=false;return;}
    DWORD timeout=100;setsockopt(socket_,SOL_SOCKET,SO_RCVTIMEO,reinterpret_cast<const char*>(&timeout),sizeof(timeout));server_={};server_.sin_family=AF_INET;server_.sin_port=htons(config.port);
    if(inet_pton(AF_INET,config.address.c_str(),&server_.sin_addr)!=1){addrinfo hints{};hints.ai_family=AF_INET;hints.ai_socktype=SOCK_DGRAM;addrinfo* result{};if(getaddrinfo(config.address.c_str(),nullptr,&hints,&result)!=0||!result){Logger::Get().Error("Endereço do servidor inválido.");running_=false;return;}server_.sin_addr=reinterpret_cast<sockaddr_in*>(result->ai_addr)->sin_addr;freeaddrinfo(result);}
    Logger::Get().Info(std::format("CPM 0.2.0.0 Native Movement + Command Diagnostics conectando a {}:{}...",config.address,config.port));
    auto lastHello=Clock::now()-std::chrono::seconds(5),lastHeartbeat=lastHello,lastStats=Clock::now();lastServerPacket_=Clock::now();char packet[512];
    while(running_){
        const auto now=Clock::now();
        if(!connected_&&now-lastHello>=std::chrono::seconds(2)){SendHello();lastHello=now;}
        if(connected_&&now-lastHeartbeat>=std::chrono::seconds(2)){SendHeartbeat();lastHeartbeat=now;}
        if(connected_&&now-lastServerPacket_>=std::chrono::seconds(7)){connected_=false;Logger::Get().Error("Servidor sem resposta. Iniciando reconexão automática.");lastHello=Clock::now()-std::chrono::seconds(5);}
        sockaddr_in remote{};int remoteSize=sizeof(remote);const int count=recvfrom(socket_,packet,sizeof(packet),0,reinterpret_cast<sockaddr*>(&remote),&remoteSize);if(count>0)HandlePacket(packet,count);
        if(now-lastStats>=std::chrono::seconds(10)){
            std::size_t active=0;std::uint64_t lost=0;{std::scoped_lock lock(remotesMutex_);for(auto it=remotes_.begin();it!=remotes_.end();){if(now-it->second.lastSeen>std::chrono::seconds(15))it=remotes_.erase(it);else{active++;lost+=it->second.lostPackets;++it;}}}
            Logger::Get().Info(std::format("Status | Conectado {} | Ping {} ms | Remotos {} | Enviados {} | Recebidos {} | Perdas remotas {}",connected_.load()?"sim":"não",pingMs_.load(),active,sentPackets_.load(),receivedPackets_.load(),lost));lastStats=now;
        }
    }
}
}
