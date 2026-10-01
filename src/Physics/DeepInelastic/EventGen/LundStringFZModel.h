//____________________________________________________________________________
/*!

\class    genie::LundStringFZModel

\brief    Lund string formation zone model (C. Zhang):
            fz = ( M + nu + sqrt(nu^2 + Q^2) - 2 * nu * z_h ) / ( 2 * kappa )
          with nu = E_nu - E_lepton, z_h = E_hadron / nu, M the nucleon mass
          and kappa the string tension.

\author   C. Zhang (model), J. Tena Vidal <julia.tena-vidal@ific.uv.es>
          Universitat de Valencia

\created  October, 2026

\cpright  Copyright (c) 2003-2027, The GENIE Collaboration
          For the full text of the license visit http://copyright.genie-mc.org
*/
//____________________________________________________________________________

#ifndef _LUND_STRING_FZ_MODEL_H_
#define _LUND_STRING_FZ_MODEL_H_

#include "Physics/DeepInelastic/EventGen/FormationZoneI.h"

namespace genie {

class LundStringFZModel : public FormationZoneI {

public:
  LundStringFZModel();
  LundStringFZModel(string config);
  virtual ~LundStringFZModel() {};

  double MeanFormationZone (const GHepRecord * event, const GHepParticle * hadron) const;

private:
  void LoadConfig (void);

  double fStringTension;  ///< string tension kappa, in GeV/fm
};

}         // genie namespace
#endif    // _LUND_STRING_FZ_MODEL_H_
