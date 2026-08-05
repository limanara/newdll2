#pragma once
#include "Config.hpp"
#include "Protocol.hpp"
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <winsock2.h>

namespace CPM {
class Client {
public:
    struct RemoteSnapshot {
        std::uint32_t playerId{};
        float x{},y{},z{},yaw{},velocity{};
    };
    bool Start(const ConnectionConfig&);
    void Stop();
    void SendPlayerState(float x,float y,float z,float forwardX,float forwardY);
    std::size_t RemoteCount();
    bool RemoteAt(std::size_t index,RemoteSnapshot& snapshot);
    bool RemoteById(std::uint32_t playerId,RemoteSnapshot& snapshot);
private:
    struct RemotePlayer {
        Protocol::PlayerState state{};
        std::uint32_t lastSequence{};
        std::uint64_t receivedPackets{};
        std::uint64_t lostPackets{};
        std::chrono::steady_clock::time_point lastSeen{};
    };
    void Run(ConnectionConfig);
    void SendHello();
    void SendHeartbeat();
    void HandlePacket(const char*,int);
    static std::uint64_t NowMs();
    std::atomic_bool running_{false};
    std::atomic_bool connected_{false};
    std::atomic_uint32_t playerId_{0};
    std::atomic_uint32_t sequence_{0};
    std::atomic_uint64_t sentPackets_{0};
    std::atomic_uint64_t receivedPackets_{0};
    std::atomic_uint32_t pingMs_{0};
    std::uint64_t sessionToken_{0};
    std::thread worker_;
    std::mutex socketMutex_;
    SOCKET socket_{INVALID_SOCKET};
    sockaddr_in server_{};
    std::mutex stateMutex_;
    bool hasPreviousState_{false};
    float previousX_{},previousY_{},previousZ_{};
    std::chrono::steady_clock::time_point previousTime_{};
    std::mutex remotesMutex_;
    std::unordered_map<std::uint32_t,RemotePlayer> remotes_;
    std::chrono::steady_clock::time_point lastServerPacket_{};
};
}
