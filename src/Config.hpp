#pragma once
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
namespace CPM { struct ConnectionConfig{std::string address;std::uint16_t port{};std::string serverName;std::uint16_t protocolVersion{};}; std::filesystem::path DataDirectory(); std::optional<ConnectionConfig> LoadConnection(); }
