#include "Config.hpp"
#include <cstdlib>
#include <fstream>
#include <regex>
#include <sstream>
namespace CPM {
std::filesystem::path DataDirectory(){if(const char* p=std::getenv("LOCALAPPDATA"))return std::filesystem::path(p)/"CPM";return std::filesystem::current_path()/"CPM";}
static std::optional<std::string> Text(const std::string& j,const char* k){std::smatch m;std::regex p(std::string("\\\"")+k+"\\\"\\s*:\\s*\\\"([^\\\"]+)\\\"");if(std::regex_search(j,m,p))return m[1].str();return std::nullopt;}
static std::optional<unsigned long> Number(const std::string& j,const char* k){std::smatch m;std::regex p(std::string("\\\"")+k+"\\\"\\s*:\\s*([0-9]+)");if(std::regex_search(j,m,p))return std::stoul(m[1].str());return std::nullopt;}
std::optional<ConnectionConfig> LoadConnection(){std::ifstream f(DataDirectory()/"connection.json");if(!f)return std::nullopt;std::ostringstream s;s<<f.rdbuf();auto j=s.str();auto a=Text(j,"address");auto p=Number(j,"port");auto v=Number(j,"protocolVersion");if(!a||!p||*p<1||*p>65535||!v)return std::nullopt;return ConnectionConfig{*a,static_cast<std::uint16_t>(*p),Text(j,"serverName").value_or("CPM Server"),static_cast<std::uint16_t>(*v)};}
}
