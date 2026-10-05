//____________________________________________________________________________
/*!

\class    genie::StandardFZModel

\brief    GENIE's standard formation zone model, previously hardcoded in
          DISHadronicSystemGenerator:
            fz = |p| * ct0 * m / (m^2 + K * pT^2)
          where pT is the hadron momentum transverse to the hadronic
          system direction and ct0 depends on whether the hadron is a
          nucleon or not.

\author   J. Tena Vidal <julia.tena-vidal@ific.uv.es>
          Universitat de Valencia

\created  October, 2026

\cpright  Copyright (c) 2003-2027, The GENIE Collaboration
          For the full text of the license visit http://copyright.genie-mc.org
*/
//____________________________________________________________________________

#ifndef _STANDARD_FZ_MODEL_H_
#define _STANDARD_FZ_MODEL_H_

#include "Physics/DeepInelastic/EventGen/FormationZoneI.h"

namespace genie {

class StandardFZModel : public FormationZoneI {

public:
  StandardFZModel();
  StandardFZModel(string config);
  virtual ~StandardFZModel() {};

  double MeanFormationZone (const GHepRecord * event, const GHepParticle * hadron) const;

private:
  void LoadConfig (void);

  double fct0pion;     ///< formation zone (c * formation time) - for pions
  double fct0nucleon;  ///< formation zone (c * formation time) - for nucleons
  double fK;           ///< param multiplying pT^2 in formation zone calculation
};

}         // genie namespace
#endif    // _STANDARD_FZ_MODEL_H_
