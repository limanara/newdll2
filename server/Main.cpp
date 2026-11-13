#include "Protocol.hpp"
#include <atomic>
#include <chrono>
#include <cstdint>
#include <format>
#include <cmath>
#include <unordered_set>
#include <cstring>
#include <iostream>
#include <unordered_map>
#include <winsock2.h>
#include <ws2tcpip.h>

namespace {
using Clock=std::chrono::steady_clock;
std::atomic_bool g_running{true};
BOOL WINAPI OnConsole(DWORD){g_running=false;return TRUE;}
constexpr float StreamRadius=180.0f;
constexpr float StreamRadiusSq=StreamRadius*StreamRadius;
bool Nearby(const CPM::Protocol::PlayerState& a,const CPM::Protocol::PlayerState& b){
    const float dx=a.x-b.x,dy=a.y-b.y,dz=a.z-b.z;
    return dx*dx+dy*dy+dz*dz<=StreamRadiusSq;
}
bool Finite(const CPM::Protocol::PlayerState& s){
    return std::isfinite(s.x)&&std::isfinite(s.y)&&std::isfinite(s.z)&&std::isfinite(s.yaw)&&std::isfinite(s.velocity)&&std::isfinite(s.aimX)&&std::isfinite(s.aimY)&&std::isfinite(s.aimZ);
}
std::uint64_t NowMs(){return std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now().time_since_epoch()).count();}
std::uint64_t EndpointKey(const sockaddr_in& value){return (static_cast<std::uint64_t>(value.sin_addr.s_addr)<<16)|ntohs(value.sin_port);}
std::string Address(const sockaddr_in& value){char ip[INET_ADDRSTRLEN]{};inet_ntop(AF_INET,&value.sin_addr,ip,sizeof(ip));return std::format("{}:{}",ip,ntohs(value.sin_port));}
struct Session{
    std::uint32_t id{};std::uint64_t token{};sockaddr_in endpoint{};Clock::time_point lastSeen{};bool active{true};bool hasState{false};
    CPM::Protocol::PlayerState state{};std::uint64_t received{};std::uint64_t relayed{};std::unordered_set<std::uint32_t> visible;
};
}

int main(int argc,char** argv){
    const auto port=static_cast<std::uint16_t>(argc>1?std::stoi(argv[1]):11777);SetConsoleCtrlHandler(OnConsole,TRUE);
    WSADATA data{};if(WSAStartup(MAKEWORD(2,2),&data)!=0){std::cerr<<"WSAStartup falhou.\n";return 1;}
    const SOCKET handle=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);if(handle==INVALID_SOCKET){std::cerr<<"Socket UDP falhou.\n";WSACleanup();return 1;}
    sockaddr_in local{};local.sin_family=AF_INET;local.sin_addr.s_addr=INADDR_ANY;local.sin_port=htons(port);
    if(bind(handle,reinterpret_cast<sockaddr*>(&local),sizeof(local))==SOCKET_ERROR){std::cerr<<"Nao foi possivel abrir a porta "<<port<<".\n";closesocket(handle);WSACleanup();return 1;}
    std::unordered_map<std::uint64_t,Session> sessions;std::unordered_map<std::uint64_t,std::uint64_t> endpoints;std::uint32_t nextId=1;std::uint64_t totalPackets=0,totalRelayed=0,invalidPackets=0;auto lastStats=Clock::now();
    std::cout<<"========================================\n CPM SERVER 0.2.0.1 SMOOTH AIR + FORCED HOLSTER + MELEE RANGE\n========================================\n";
    std::cout<<"Servidor UDP ativo na porta "<<port<<". CTRL+C encerra.\n\n";
    while(g_running){
        fd_set set;FD_ZERO(&set);FD_SET(handle,&set);timeval wait{0,100000};
        if(select(0,&set,nullptr,nullptr,&wait)>0){
            char bytes[512];sockaddr_in remote{};int remoteSize=sizeof(remote);const int count=recvfrom(handle,bytes,sizeof(bytes),0,reinterpret_cast<sockaddr*>(&remote),&remoteSize);totalPackets++;
            if(count<static_cast<int>(sizeof(CPM::Protocol::Header))){invalidPackets++;continue;}
            const auto* header=reinterpret_cast<const CPM::Protocol::Header*>(bytes);if(!CPM::Protocol::Valid(*header,count)){invalidPackets++;continue;}const auto endpointKey=EndpointKey(remote);
            if(header->type==CPM::Protocol::Type::Hello&&header->payloadSize==sizeof(CPM::Protocol::Hello)){
                const auto* hello=reinterpret_cast<const CPM::Protocol::Hello*>(bytes+sizeof(CPM::Protocol::Header));auto it=sessions.find(hello->nonce);
                if(it==sessions.end()){Session session{nextId++,hello->nonce,remote,Clock::now(),true,false};it=sessions.emplace(hello->nonce,session).first;std::cout<<"Player "<<it->second.id<<" conectado | sessao "<<std::format("{:016X}",hello->nonce)<<" | "<<Address(remote)<<".\n";}
                else{endpoints.erase(EndpointKey(it->second.endpoint));it->second.endpoint=remote;it->second.lastSeen=Clock::now();if(!it->second.active)std::cout<<"Player "<<it->second.id<<" reconectado com a mesma sessao.\n";it->second.active=true;}
                endpoints[endpointKey]=hello->nonce;const auto welcome=CPM::Protocol::Make(CPM::Protocol::Type::Welcome,CPM::Protocol::Welcome{it->second.id});sendto(handle,reinterpret_cast<const char*>(&welcome),sizeof(welcome),0,reinterpret_cast<const sockaddr*>(&remote),sizeof(remote));

            }else if(header->type==static_cast<CPM::Protocol::Type>(7)&&header->payloadSize==0){
                // Consulta de teste SOMENTE local: nunca exponha coordenadas pela rede.
                if(ntohl(remote.sin_addr.s_addr)!=INADDR_LOOPBACK){invalidPackets++;continue;}
                const Session* target=nullptr;
                for(const auto& [token,candidate]:sessions){
                    if(!candidate.active||!candidate.hasState)continue;
                    if(!target||candidate.lastSeen>target->lastSeen)target=&candidate;
                }
                if(target){
                    struct TestPosition{float x,y,z,yaw;};
                    const TestPosition pos{target->state.x,target->state.y,target->state.z,target->state.yaw};
                    const auto reply=CPM::Protocol::Make(static_cast<CPM::Protocol::Type>(8),pos);
                    sendto(handle,reinterpret_cast<const char*>(&reply),sizeof(reply),0,reinterpret_cast<const sockaddr*>(&remote),sizeof(remote));
                }
            }else if(header->type==CPM::Protocol::Type::Heartbeat&&header->payloadSize==sizeof(CPM::Protocol::Heartbeat)){
                const auto* heartbeat=reinterpret_cast<const CPM::Protocol::Heartbeat*>(bytes+sizeof(CPM::Protocol::Header));auto it=sessions.find(heartbeat->sessionToken);
                if(it!=sessions.end()){
                    endpoints.erase(EndpointKey(it->second.endpoint));it->second.endpoint=remote;endpoints[endpointKey]=heartbeat->sessionToken;if(!it->second.active)std::cout<<"Player "<<it->second.id<<" reativado pelo heartbeat.\n";it->second.active=true;it->second.lastSeen=Clock::now();
                    const auto pong=CPM::Protocol::Make(CPM::Protocol::Type::Pong,CPM::Protocol::Pong{it->second.id,heartbeat->clientTimeMs,NowMs()});sendto(handle,reinterpret_cast<const char*>(&pong),sizeof(pong),0,reinterpret_cast<const sockaddr*>(&remote),sizeof(remote));
                }
            }else if(header->type==CPM::Protocol::Type::PlayerState&&header->payloadSize==sizeof(CPM::Protocol::PlayerState)){
                const auto endpoint=endpoints.find(endpointKey);if(endpoint==endpoints.end())continue;auto session=sessions.find(endpoint->second);if(session==sessions.end()||!session->second.active)continue;
                CPM::Protocol::PlayerState incoming{};
                std::memcpy(&incoming,bytes+sizeof(CPM::Protocol::Header),sizeof(incoming));
                auto& sender=session->second;
                if(!Finite(incoming)) {invalidPackets++;continue;}
                if(sender.hasState && static_cast<std::int32_t>(incoming.sequence-sender.state.sequence)<=0)continue;
                incoming.playerId=sender.id;
                sender.state=incoming;sender.hasState=true;sender.lastSeen=Clock::now();sender.received++;
                const auto packet=CPM::Protocol::Make(CPM::Protocol::Type::PlayerState,incoming);
                for(auto& [token,other]:sessions){
                    if(token==session->first||!other.active||!other.hasState)continue;
                    const bool close=Nearby(incoming,other.state);
                    const bool previouslyVisible=other.visible.contains(sender.id);
                    if(close){
                        sendto(handle,reinterpret_cast<const char*>(&packet),sizeof(packet),0,reinterpret_cast<const sockaddr*>(&other.endpoint),sizeof(other.endpoint));
                        other.visible.insert(sender.id);sender.relayed++;totalRelayed++;
                        if(!sender.visible.contains(other.id)){
                            const auto reciprocal=CPM::Protocol::Make(CPM::Protocol::Type::PlayerState,other.state);
                            sendto(handle,reinterpret_cast<const char*>(&reciprocal),sizeof(reciprocal),0,reinterpret_cast<const sockaddr*>(&sender.endpoint),sizeof(sender.endpoint));
                            sender.visible.insert(other.id);
                        }
                    }else if(previouslyVisible){
                        const auto left=CPM::Protocol::Make(CPM::Protocol::Type::PlayerLeft,CPM::Protocol::PlayerLeft{sender.id});
                        sendto(handle,reinterpret_cast<const char*>(&left),sizeof(left),0,reinterpret_cast<const sockaddr*>(&other.endpoint),sizeof(other.endpoint));
                        other.visible.erase(sender.id);
                        if(sender.visible.erase(other.id)){
                            const auto reciprocal=CPM::Protocol::Make(CPM::Protocol::Type::PlayerLeft,CPM::Protocol::PlayerLeft{other.id});
                            sendto(handle,reinterpret_cast<const char*>(&reciprocal),sizeof(reciprocal),0,reinterpret_cast<const sockaddr*>(&sender.endpoint),sizeof(sender.endpoint));
                        }
                    }
                }
            }else invalidPackets++;
        }
        const auto now=Clock::now();
        for(auto& [token,session]:sessions)if(session.active&&now-session.lastSeen>std::chrono::seconds(8)){
            session.active=false;endpoints.erase(EndpointKey(session.endpoint));
            const auto left=CPM::Protocol::Make(CPM::Protocol::Type::PlayerLeft,CPM::Protocol::PlayerLeft{session.id});
            for(auto& [otherToken,other]:sessions){
                if(otherToken!=token){
                    if(other.active&&other.visible.contains(session.id))sendto(handle,reinterpret_cast<const char*>(&left),sizeof(left),0,reinterpret_cast<const sockaddr*>(&other.endpoint),sizeof(other.endpoint));
                    other.visible.erase(session.id);
                }
            }
            session.visible.clear();std::cout<<"Player "<<session.id<<" ficou inativo (sessao preservada).\n";
        }
        if(now-lastStats>=std::chrono::seconds(10)){
            std::size_t active=0;for(const auto& [token,session]:sessions)if(session.active)active++;
            std::cout<<"STATUS | ativos "<<active<<" | sessoes "<<sessions.size()<<" | recebidos "<<totalPackets<<" | relay "<<totalRelayed<<" | invalidos "<<invalidPackets<<"\n";lastStats=now;
        }
    }
    closesocket(handle);WSACleanup();std::cout<<"Servidor encerrado.\n";return 0;
}
