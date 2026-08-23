#include "RemoteAirRuntime.hpp"
#include <cassert>
#include <cmath>
int main(){
 auto& r=CPM::RemoteAirRuntime::Get();r.Clear();r.Begin(10,7.0f);r.Begin(20,40.0f);assert(r.Count()==2);
 auto a=r.Step(10,0.05f),b=r.Step(20,0.05f);assert(a.z>7.0f&&b.z>40.0f);assert(std::abs((b.z-a.z)-33.0f)<0.001f);
 CPM::AirFrame s{};assert(r.Snapshot(10,s)&&s.phase==CPM::AirPhase::Rising);assert(!r.Snapshot(99,s));
 bool landed=false;for(int i=0;i<300;++i){auto f=r.Step(10,0.02f);if(f.phase==CPM::AirPhase::Landing||f.phase==CPM::AirPhase::Grounded){landed=true;assert(std::abs(f.z-7.0f)<0.001f);break;}}assert(landed);
 r.Remove(10);assert(r.Count()==1);r.Clear();assert(r.Count()==0);return 0;
}
