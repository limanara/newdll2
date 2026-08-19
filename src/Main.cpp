#include "Client.hpp"
#include "Config.hpp"
#include "Logger.hpp"
#include "Native.hpp"
#include "Protocol.hpp"
#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>
#include <memory>

static std::unique_ptr<CPM::Client> s_client;

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::v1::PluginHandle,RED4ext::v1::EMainReason reason,const RED4ext::v1::Sdk*){
    if(reason==RED4ext::v1::EMainReason::Load){
        Red::TypeInfoRegistrar::RegisterDiscovered();
        CPM::Logger::Get().Open(CPM::DataDirectory()/"logs"/"CPMClient.log");
        CPM::Logger::Get().Info("CPM Client 0.1.0.5 Native Air + Equip + Melee carregado pelo RED4ext.");
        auto config=CPM::LoadConnection();
        if(!config){CPM::Logger::Get().Error("connection.json ausente ou inválido.");return true;}
        if(config->protocolVersion!=CPM::Protocol::Version){CPM::Logger::Get().Error("Protocolo incompatível.");return true;}
        s_client=std::make_unique<CPM::Client>();
        CPM::SetActiveClient(s_client.get());
        s_client->Start(*config);
    }else if(reason==RED4ext::v1::EMainReason::Unload){
        CPM::SetActiveClient(nullptr);
        if(s_client){s_client->Stop();s_client.reset();}
    }
    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::v1::PluginInfo* info){
    info->name=L"CPM Client";info->author=L"CPM Team";info->version=RED4EXT_V1_SEMVER(0,1,5);
    info->runtime=RED4EXT_V1_RUNTIME_VERSION_LATEST;info->sdk=RED4EXT_V1_SDK_VERSION_CURRENT;
}
RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports(){return RED4EXT_API_VERSION_1;}
