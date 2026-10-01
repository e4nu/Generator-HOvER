//____________________________________________________________________________
/*
 Copyright (c) 2003-2025, The GENIE Collaboration
 For the full text of the license visit http://copyright.genie-mc.org

 J. Tena Vidal <julia.tena-vidal@ific.uv.es>
 Universitat de Valencia
*/
//____________________________________________________________________________

#include "Physics/DeepInelastic/EventGen/FormationZoneI.h"
#include "Framework/Messenger/Messenger.h"
#include "Framework/Numerical/RandomGen.h"

using namespace genie;

//____________________________________________________________________________
FormationZoneI::FormationZoneI() :
Algorithm()
{

}
//____________________________________________________________________________
FormationZoneI::FormationZoneI(string name) :
Algorithm(name)
{

}
//____________________________________________________________________________
FormationZoneI::FormationZoneI(string name, string config) :
Algorithm(name, config)
{

}
//____________________________________________________________________________
double FormationZoneI::FormationZone(
    const GHepRecord * event, const GHepParticle * hadron) const
{
  double fz = this->MeanFormationZone(event, hadron);

  if( fSampleExponential && fz > 0. ) {
    RandomGen * rnd = RandomGen::Instance();
    fz = rnd->RndHadro().Exp(fz);
  }

  LOG("FormationZone", pINFO)
    << "Formation zone for " << hadron->Name() << " = " << fz << " fm";

  return fz;
}
//____________________________________________________________________________
void FormationZoneI::Configure(const Registry & config)
{
  Algorithm::Configure(config);
  this->LoadConfig();
}
//____________________________________________________________________________
void FormationZoneI::Configure(string config)
{
  Algorithm::Configure(config);
  this->LoadConfig();
}
//____________________________________________________________________________
void FormationZoneI::LoadConfig(void)
{
  GetParamDef( "SampleExponential", fSampleExponential, false ) ;
}
//____________________________________________________________________________
