//____________________________________________________________________________
/*
 Copyright (c) 2003-2025, The GENIE Collaboration
 For the full text of the license visit http://copyright.genie-mc.org

 J. Tena Vidal <julia.tena-vidal@ific.uv.es>
 Universitat de Valencia
*/
//____________________________________________________________________________

#include "Physics/DeepInelastic/EventGen/StandardFZModel.h"
#include "Framework/Messenger/Messenger.h"
#include "Framework/ParticleData/PDGUtils.h"
#include "Framework/Utils/PhysUtils.h"

using namespace genie;
using namespace genie::utils;

//____________________________________________________________________________
StandardFZModel::StandardFZModel() :
FormationZoneI("genie::StandardFZModel")
{

}
//____________________________________________________________________________
StandardFZModel::StandardFZModel(string config) :
FormationZoneI("genie::StandardFZModel", config)
{

}
//____________________________________________________________________________
double StandardFZModel::MeanFormationZone(
    const GHepRecord * event, const GHepParticle * hadron) const
{
  GHepParticle * hadronic_system = event->FinalStateHadronicSystem();
  TVector3 p3hadr = hadronic_system->P4()->Vect(); // (px,py,pz)

  double ct0 = pdg::IsNucleon(hadron->Pdg()) ? fct0nucleon : fct0pion;

  return phys::FormationZone(hadron->Mass(), *(hadron->P4()), p3hadr, ct0, fK);
}
//____________________________________________________________________________
void StandardFZModel::LoadConfig(void)
{
  FormationZoneI::LoadConfig();

  GetParam( "FZONE-ct0pion",    fct0pion    ) ;
  GetParam( "FZONE-ct0nucleon", fct0nucleon ) ;
  GetParam( "FZONE-KPt2",       fK          ) ;

  LOG("FormationZone", pDEBUG) << "ct0pion     = " << fct0pion    << " fermi";
  LOG("FormationZone", pDEBUG) << "ct0nucleon  = " << fct0nucleon << " fermi";
  LOG("FormationZone", pDEBUG) << "K(pt^2) = " << fK;
}
//____________________________________________________________________________
