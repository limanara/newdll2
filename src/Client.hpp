#pragma once
#include "Config.hpp"
#include <atomic>
#include <chrono>
#include <mutex>
#include <thread>
#include <winsock2.h>
namespace CPM {
class Client {
public:
    bool Start(const ConnectionConfig&);
    void Stop();
    void SendPlayerState(float x, float y, float z, float forwardX, float forwardY);
private:
    void Run(ConnectionConfig);
    void HandlePacket(const char* data,int bytes);
    std::atomic_bool running_{false};
    std::atomic_bool connected_{false};
    std::atomic_uint32_t playerId_{0};
    std::atomic_uint32_t sequence_{0};
    std::thread worker_;
    std::mutex socketMutex_;
    SOCKET socket_{INVALID_SOCKET};
    sockaddr_in server_{};
    std::mutex stateMutex_;
    bool hasPreviousState_{false};
    float previousX_{}, previousY_{}, previousZ_{};
    std::chrono::steady_clock::time_point previousTime_{};
};
}
