#pragma once
#include <filesystem>
#include <fstream>
#include <mutex>
#include <string_view>
namespace CPM { class Logger { public: static Logger& Get(); void Open(const std::filesystem::path&); void Info(std::string_view); void Error(std::string_view); private: void Write(std::string_view,std::string_view); std::ofstream file_; std::mutex mutex_; }; }
