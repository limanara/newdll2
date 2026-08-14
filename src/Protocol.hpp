#pragma once
#include <cstddef>
#include <cstdint>
#include <type_traits>
namespace CPM::Protocol {
constexpr std::uint32_t Magic=0x43435954; constexpr std::uint16_t Version=2;
enum class Type:std::uint16_t{Hello=1,Welcome=2,PlayerState=3,PlayerLeft=4,Heartbeat=5,Pong=6};
#pragma pack(push,1)
struct Header{std::uint32_t magic{Magic};std::uint16_t version{Version};Type type{};std::uint32_t payloadSize{};};
struct Hello{std::uint64_t nonce{};}; struct Welcome{std::uint32_t playerId{};};
enum PlayerFlags:std::uint16_t{WeaponEquipped=1u<<0,Aiming=1u<<1};
struct PlayerState{
    std::uint32_t playerId{},sequence{};
    float x{},y{},z{},yaw{},velocity{};
    float aimX{},aimY{},aimZ{};
    std::int16_t locomotion{},detailedLocomotion{},upperBody{},weaponState{},meleeState{},weaponType{};
    std::uint16_t flags{};
    std::uint32_t shotEvent{},reloadEvent{},meleeEvent{};
};
static_assert(sizeof(PlayerState)==66,"CPM PlayerState v2 precisa ter 66 bytes");
struct PlayerLeft{std::uint32_t playerId{};};
struct Heartbeat{std::uint32_t playerId{};std::uint64_t sessionToken{};std::uint64_t clientTimeMs{};};
struct Pong{std::uint32_t playerId{};std::uint64_t clientTimeMs{};std::uint64_t serverTimeMs{};};
template<class T>struct Packet{Header header;T payload;};
#pragma pack(pop)
template<class T>Packet<T> Make(Type type,const T& payload){static_assert(std::is_trivially_copyable_v<T>);return{{Magic,Version,type,sizeof(T)},payload};}
inline bool Valid(const Header& h,std::size_t bytes){return h.magic==Magic&&h.version==Version&&bytes==sizeof(Header)+h.payloadSize;}
}
