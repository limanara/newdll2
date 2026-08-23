#pragma once
#include "AirController.hpp"
#include <cstdint>
#include <cstddef>
#include <mutex>
#include <unordered_map>
namespace CPM {
class RemoteAirRuntime {
public:
 static RemoteAirRuntime& Get();
 void Begin(std::int32_t playerID,float groundZ);
 AirFrame Step(std::int32_t playerID,float deltaSeconds);
 void Reset(std::int32_t playerID,float groundZ);
 bool Snapshot(std::int32_t playerID,AirFrame& frame) const;
 void Remove(std::int32_t playerID);
 void Clear();
 [[nodiscard]] std::size_t Count() const;
private:
 mutable std::mutex mutex_;
 std::unordered_map<std::int32_t,AirController> controllers_;
};
}
