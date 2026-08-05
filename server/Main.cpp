#include "Protocol.hpp"
#include <atomic>
#include <chrono>
#include <csignal>
#include <cstdint>
#include <format>
#include <iostream>
#include <unordered_map>
#include <vector>
#include <winsock2.h>
#include <ws2tcpip.h>

namespace {
std::atomic_bool g_running{true};
BOOL WINAPI OnConsole(DWORD){g_running=false;return TRUE;}
std::uint64_t Key(const sockaddr_in& value){return (static_cast<std::uint64_t>(value.sin_addr.s_addr)<<16)|ntohs(value.sin_port);}
std::string Address(const sockaddr_in& value){char ip[INET_ADDRSTRLEN]{};inet_ntop(AF_INET,&value.sin_addr,ip,sizeof(ip));return std::format("{}:{}",ip,ntohs(value.sin_port));}
struct ClientInfo{std::uint32_t id{};sockaddr_in endpoint{};std::chrono::steady_clock::time_point lastSeen{};bool hasState{false};};
}

int main(int argc,char** argv){
    const auto port=static_cast<std::uint16_t>(argc>1?std::stoi(argv[1]):11777);
    SetConsoleCtrlHandler(OnConsole,TRUE);
    WSADATA data{};if(WSAStartup(MAKEWORD(2,2),&data)!=0){std::cerr<<"WSAStartup falhou.\n";return 1;}
    const SOCKET socketHandle=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);if(socketHandle==INVALID_SOCKET){std::cerr<<"Socket UDP falhou.\n";return 1;}
    sockaddr_in local{};local.sin_family=AF_INET;local.sin_addr.s_addr=INADDR_ANY;local.sin_port=htons(port);
    if(bind(socketHandle,reinterpret_cast<sockaddr*>(&local),sizeof(local))==SOCKET_ERROR){std::cerr<<"Nao foi possivel abrir a porta "<<port<<".\n";closesocket(socketHandle);WSACleanup();return 1;}
    std::unordered_map<std::uint64_t,ClientInfo> clients;std::uint32_t nextId=1;
    std::cout<<"========================================\n       CPM SERVER 0.0.3\n========================================\n";
    std::cout<<"Servidor UDP ativo na porta "<<port<<". CTRL+C encerra.\n\n";
    while(g_running){
        fd_set readSet;FD_ZERO(&readSet);FD_SET(socketHandle,&readSet);timeval wait{0,100000};
        if(select(0,&readSet,nullptr,nullptr,&wait)>0){
            char bytes[512];sockaddr_in remote{};int remoteSize=sizeof(remote);
            const int count=recvfrom(socketHandle,bytes,sizeof(bytes),0,reinterpret_cast<sockaddr*>(&remote),&remoteSize);
            if(count>=static_cast<int>(sizeof(CPM::Protocol::Header))){
                const auto* header=reinterpret_cast<const CPM::Protocol::Header*>(bytes);const auto key=Key(remote);
                if(CPM::Protocol::Valid(*header,count)&&header->type==CPM::Protocol::Type::Hello&&header->payloadSize==sizeof(CPM::Protocol::Hello)){
                    auto it=clients.find(key);if(it==clients.end()){ClientInfo info{nextId++,remote,std::chrono::steady_clock::now(),false};it=clients.emplace(key,info).first;std::cout<<"Player "<<info.id<<" conectado de "<<Address(remote)<<".\n";}else it->second.lastSeen=std::chrono::steady_clock::now();
                    const auto welcome=CPM::Protocol::Make(CPM::Protocol::Type::Welcome,CPM::Protocol::Welcome{it->second.id});sendto(socketHandle,reinterpret_cast<const char*>(&welcome),sizeof(welcome),0,reinterpret_cast<sockaddr*>(&remote),sizeof(remote));
                }else if(CPM::Protocol::Valid(*header,count)&&header->type==CPM::Protocol::Type::PlayerState&&header->payloadSize==sizeof(CPM::Protocol::PlayerState)){
                    auto it=clients.find(key);
                    if(it==clients.end()){
                        ClientInfo info{nextId++,remote,std::chrono::steady_clock::now(),true};
                        it=clients.emplace(key,info).first;
                        std::cout<<"Player "<<info.id<<" reconectado pela telemetria de "<<Address(remote)<<".\n";
                    }
                    it->second.lastSeen=std::chrono::steady_clock::now();it->second.hasState=true;auto* state=reinterpret_cast<CPM::Protocol::PlayerState*>(bytes+sizeof(CPM::Protocol::Header));state->playerId=it->second.id;
                    if((state->sequence%100)==0)std::cout<<"Player "<<state->playerId<<" seq "<<state->sequence<<" | jogadores "<<clients.size()<<"\n";
                    for(const auto& [otherKey,other]:clients)if(otherKey!=key)sendto(socketHandle,bytes,count,0,reinterpret_cast<const sockaddr*>(&other.endpoint),sizeof(other.endpoint));
                }
            }
        }
        const auto now=std::chrono::steady_clock::now();std::vector<std::uint64_t> expired;
        for(const auto& [key,client]:clients){const auto limit=client.hasState?std::chrono::seconds(10):std::chrono::seconds(300);if(now-client.lastSeen>limit)expired.push_back(key);}
        for(const auto key:expired){const auto id=clients.at(key).id;const auto left=CPM::Protocol::Make(CPM::Protocol::Type::PlayerLeft,CPM::Protocol::PlayerLeft{id});for(const auto& [otherKey,other]:clients)if(otherKey!=key)sendto(socketHandle,reinterpret_cast<const char*>(&left),sizeof(left),0,reinterpret_cast<const sockaddr*>(&other.endpoint),sizeof(other.endpoint));std::cout<<"Player "<<id<<" desconectado por timeout.\n";clients.erase(key);}
    }
    closesocket(socketHandle);WSACleanup();std::cout<<"Servidor encerrado.\n";return 0;
}
