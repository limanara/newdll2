#include "Logger.hpp"
#include <chrono>
#include <format>
namespace CPM {
Logger& Logger::Get(){static Logger value;return value;}
void Logger::Open(const std::filesystem::path& p){std::filesystem::create_directories(p.parent_path());file_.open(p,std::ios::app);}
void Logger::Info(std::string_view t){Write("INFO",t);} void Logger::Error(std::string_view t){Write("ERROR",t);}
void Logger::Write(std::string_view level,std::string_view text){std::scoped_lock lock(mutex_);if(!file_)return;const auto now=std::chrono::floor<std::chrono::seconds>(std::chrono::system_clock::now());file_<<std::format("[{:%F %T}] [{}] {}\n",now,level,text);file_.flush();}
}
