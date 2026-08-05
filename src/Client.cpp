#include "Client.hpp"
#include "Logger.hpp"
#include "Protocol.hpp"
#include <chrono>
#include <cmath>
#include <format>
#include <random>
#include <ws2tcpip.h>
namespace CPM {
bool Client::Start(const ConnectionConfig& c){if(running_.exchange(true))return false;worker_=std::thread(&Client::Run,this,c);return true;}
void Client::Stop(){running_=false;connected_=false;{std::scoped_lock lock(socketMutex_);if(socket_!=INVALID_SOCKET){closesocket(socket_);socket_=INVALID_SOCKET;}}if(worker_.joinable())worker_.join();WSACleanup();Logger::Get().Info("CPM Client finalizado.");}

void Client::SendPlayerState(float x,float y,float z,float forwardX,float forwardY){
    if(!connected_)return;
    float velocity=0.0f;
    const auto now=std::chrono::steady_clock::now();
    {
        std::scoped_lock lock(stateMutex_);
        if(hasPreviousState_){
            const float dt=std::chrono::duration<float>(now-previousTime_).count();
            if(dt>0.001f){const float dx=x-previousX_,dy=y-previousY_,dz=z-previousZ_;velocity=std::sqrt(dx*dx+dy*dy+dz*dz)/dt;}
        }
        previousX_=x;previousY_=y;previousZ_=z;previousTime_=now;hasPreviousState_=true;
    }
    constexpr float RadToDeg=57.29577951308232f;
    const float yaw=std::atan2(forwardY,forwardX)*RadToDeg;
    const Protocol::PlayerState state{playerId_.load(),sequence_.fetch_add(1),x,y,z,yaw,velocity,0};
    const auto packet=Protocol::Make(Protocol::Type::PlayerState,state);
    std::scoped_lock lock(socketMutex_);
    if(socket_!=INVALID_SOCKET)sendto(socket_,reinterpret_cast<const char*>(&packet),sizeof(packet),0,reinterpret_cast<const sockaddr*>(&server_),sizeof(server_));
}

void Client::HandlePacket(const char* data,int bytes){
    if(bytes<static_cast<int>(sizeof(Protocol::Header)))return;
    const auto* header=reinterpret_cast<const Protocol::Header*>(data);
    if(!Protocol::Valid(*header,bytes))return;
    if(header->type==Protocol::Type::PlayerState&&header->payloadSize==sizeof(Protocol::PlayerState)){
        const auto* state=reinterpret_cast<const Protocol::PlayerState*>(data+sizeof(Protocol::Header));
        if(state->playerId==playerId_.load())return;
        if((state->sequence%20)==0)Logger::Get().Info(std::format("Remoto {} | Seq {} | X {:.2f} Y {:.2f} Z {:.2f} | Rot {:.1f} | Vel {:.2f}",state->playerId,state->sequence,state->x,state->y,state->z,state->yaw,state->velocity));
    }else if(header->type==Protocol::Type::PlayerLeft&&header->payloadSize==sizeof(Protocol::PlayerLeft)){
        const auto* left=reinterpret_cast<const Protocol::PlayerLeft*>(data+sizeof(Protocol::Header));
        Logger::Get().Info(std::format("Player remoto {} desconectou.",left->playerId));
    }
}

void Client::Run(ConnectionConfig c){WSADATA d{};if(WSAStartup(MAKEWORD(2,2),&d)!=0){Logger::Get().Error("WSAStartup falhou.");running_=false;return;}{std::scoped_lock lock(socketMutex_);socket_=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);}if(socket_==INVALID_SOCKET){Logger::Get().Error("Não foi possível criar o socket UDP.");running_=false;return;}DWORD timeout=3000;setsockopt(socket_,SOL_SOCKET,SO_RCVTIMEO,reinterpret_cast<const char*>(&timeout),sizeof(timeout));server_={};server_.sin_family=AF_INET;server_.sin_port=htons(c.port);if(inet_pton(AF_INET,c.address.c_str(),&server_.sin_addr)!=1){addrinfo hints{};hints.ai_family=AF_INET;hints.ai_socktype=SOCK_DGRAM;addrinfo* r{};if(getaddrinfo(c.address.c_str(),nullptr,&hints,&r)!=0||!r){Logger::Get().Error("Endereço do servidor inválido.");running_=false;return;}server_.sin_addr=reinterpret_cast<sockaddr_in*>(r->ai_addr)->sin_addr;freeaddrinfo(r);}Logger::Get().Info(std::format("Conectando a {}:{}...",c.address,c.port));const auto nonce=(static_cast<std::uint64_t>(std::random_device{}())<<32)|std::random_device{}();const auto hello=Protocol::Make(Protocol::Type::Hello,Protocol::Hello{nonce});sendto(socket_,reinterpret_cast<const char*>(&hello),sizeof(hello),0,reinterpret_cast<sockaddr*>(&server_),sizeof(server_));Protocol::Packet<Protocol::Welcome> welcome{};sockaddr_in source{};int size=sizeof(source);const int received=recvfrom(socket_,reinterpret_cast<char*>(&welcome),sizeof(welcome),0,reinterpret_cast<sockaddr*>(&source),&size);if(received!=sizeof(welcome)||!Protocol::Valid(welcome.header,received)||welcome.header.type!=Protocol::Type::Welcome){Logger::Get().Error("Servidor não respondeu ao handshake CPM.");running_=false;return;}playerId_=welcome.payload.playerId;connected_=true;timeout=250;setsockopt(socket_,SOL_SOCKET,SO_RCVTIMEO,reinterpret_cast<const char*>(&timeout),sizeof(timeout));Logger::Get().Info(std::format("Conectado. Player ID: {}. Telemetria 0.0.3 ativa.",welcome.payload.playerId));char packet[512];while(running_){sockaddr_in remote{};int remoteSize=sizeof(remote);const int count=recvfrom(socket_,packet,sizeof(packet),0,reinterpret_cast<sockaddr*>(&remote),&remoteSize);if(count>0)HandlePacket(packet,count);else if(WSAGetLastError()!=WSAETIMEDOUT&&running_)std::this_thread::sleep_for(std::chrono::milliseconds(10));}}
}
