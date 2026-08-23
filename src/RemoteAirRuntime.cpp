#include "RemoteAirRuntime.hpp"
namespace CPM {
RemoteAirRuntime& RemoteAirRuntime::Get(){static RemoteAirRuntime runtime;return runtime;}
void RemoteAirRuntime::Begin(std::int32_t id,float z){std::scoped_lock lock(mutex_);auto [it,inserted]=controllers_.try_emplace(id);it->second.Begin(z);}
AirFrame RemoteAirRuntime::Step(std::int32_t id,float dt){std::scoped_lock lock(mutex_);auto it=controllers_.find(id);return it==controllers_.end()?AirFrame{}:it->second.Update(dt);}
void RemoteAirRuntime::Reset(std::int32_t id,float z){std::scoped_lock lock(mutex_);auto [it,inserted]=controllers_.try_emplace(id);it->second.Reset(z);}
bool RemoteAirRuntime::Snapshot(std::int32_t id,AirFrame& frame)const{std::scoped_lock lock(mutex_);auto it=controllers_.find(id);if(it==controllers_.end())return false;frame=it->second.Frame();return true;}
void RemoteAirRuntime::Remove(std::int32_t id){std::scoped_lock lock(mutex_);controllers_.erase(id);}
void RemoteAirRuntime::Clear(){std::scoped_lock lock(mutex_);controllers_.clear();}
std::size_t RemoteAirRuntime::Count()const{std::scoped_lock lock(mutex_);return controllers_.size();}
}
