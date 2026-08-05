#pragma once
#include <cstddef>
#include <cstdint>
#include <type_traits>
namespace CPM::Protocol {
constexpr std::uint32_t Magic=0x43435954; constexpr std::uint16_t Version=1;
enum class Type:std::uint16_t{Hello=1,Welcome=2,PlayerState=3,PlayerLeft=4};
#pragma pack(push,1)
struct Header{std::uint32_t magic{Magic};std::uint16_t version{Version};Type type{};std::uint32_t payloadSize{};};
struct Hello{std::uint64_t nonce{};}; struct Welcome{std::uint32_t playerId{};};
struct PlayerState{std::uint32_t playerId{},sequence{};float x{},y{},z{},yaw{},velocity{};std::uint8_t flags{};};
struct PlayerLeft{std::uint32_t playerId{};};
template<class T>struct Packet{Header header;T payload;};
#pragma pack(pop)
template<class T>Packet<T> Make(Type type,const T& payload){static_assert(std::is_trivially_copyable_v<T>);return{{Magic,Version,type,sizeof(T)},payload};}
inline bool Valid(const Header& h,std::size_t bytes){return h.magic==Magic&&h.version==Version&&bytes==sizeof(Header)+h.payloadSize;}
}
