//____________________________________________________________________________
/*
 Copyright (c) 2003-2025, The GENIE Collaboration
 For the full text of the license visit http://copyright.genie-mc.org

 C. Zhang (model)
 J. Tena Vidal <julia.tena-vidal@ific.uv.es>
 Universitat de Valencia
*/
//____________________________________________________________________________

#include <TMath.h>

#include "Physics/DeepInelastic/EventGen/LundStringFZModel.h"
#include "Framework/Conventions/Constants.h"
#include "Framework/Messenger/Messenger.h"

using namespace genie;
using namespace genie::constants;

//____________________________________________________________________________
LundStringFZModel::LundStringFZModel() :
FormationZoneI("genie::LundStringFZModel")
{

}
//____________________________________________________________________________
LundStringFZModel::LundStringFZModel(string config) :
FormationZoneI("genie::LundStringFZModel", config)
{

}
//____________________________________________________________________________
double LundStringFZModel::MeanFormationZone(
    const GHepRecord * event, const GHepParticle * hadron) const
{
  // Energy and momentum transfer, from the probe and final state lepton.
  // (The running kinematics stored in the interaction summary are cleared
  //  once the kinematics are selected, so they are not used here.)
  const TLorentzVector & k1 = *(event->Probe()->P4());
  const TLorentzVector & k2 = *(event->FinalStatePrimaryLepton()->P4());
  TLorentzVector q = k1 - k2;

  double nu = q.E();
  double Q2 = -1 * q.M2();

  if( nu <= 0. ) {
    LOG("FormationZone", pWARN)
      << "Non-positive energy transfer (nu = " << nu << " GeV)"
      << " - Setting formation zone to 0";
    return 0.;
  }

  double zh = hadron->E() / nu;
  double fz = 0.5 * ( kNucleonMass + nu + TMath::Sqrt(nu*nu + Q2) - 2.*nu*zh ) / fStringTension;

  LOG("FormationZone", pDEBUG)
    << "Lund string formation zone (nu = " << nu << " GeV, Q2 = " << Q2
    << " GeV^2, zh = " << zh << ") = " << fz << " fm";

  return fz;
}
//____________________________________________________________________________
void LundStringFZModel::LoadConfig(void)
{
  FormationZoneI::LoadConfig();

  GetParam( "FZONE-StringTension", fStringTension ) ;
  assert(fStringTension > 0.);
}
//____________________________________________________________________________
