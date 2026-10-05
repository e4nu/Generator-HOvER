//____________________________________________________________________________
/*!

\class    genie::FormationZoneI

\brief    Abstract base class for hadron formation zone models.
          Implementations provide the mean formation zone of a hadron
          produced in the hadronization of the DIS hadronic system.
          The formation zone returned to the caller is either that mean
          value or, if SampleExponential is set, a value sampled from an
          exponential distribution with that mean. A negative mean
          formation zone is set to 0.

\author   J. Tena Vidal <julia.tena-vidal@ific.uv.es>
          Universitat de Valencia

\created  October, 2026

\cpright  Copyright (c) 2003-2027, The GENIE Collaboration
          For the full text of the license visit http://copyright.genie-mc.org
*/
//____________________________________________________________________________

#ifndef _FORMATION_ZONE_I_H_
#define _FORMATION_ZONE_I_H_

#include "Framework/Algorithm/Algorithm.h"
#include "Framework/GHEP/GHepRecord.h"
#include "Framework/GHEP/GHepParticle.h"

namespace genie {

class FormationZoneI : public Algorithm {

public:
  virtual ~FormationZoneI() {};

  // Formation zone (in fm) for hadron `hadron` of event `event`
  double FormationZone (const GHepRecord * event, const GHepParticle * hadron) const;

  // Mean formation zone (in fm), to be implemented by each model
  virtual double MeanFormationZone (const GHepRecord * event, const GHepParticle * hadron) const = 0;

  void Configure (const Registry & config);
  void Configure (string config);

protected:

  FormationZoneI();
  FormationZoneI(string name);
  FormationZoneI(string name, string config);

  virtual void LoadConfig (void);

  bool fSampleExponential;  ///< sample the formation zone from an exponential with the model mean?
};

}         // genie namespace
#endif    // _FORMATION_ZONE_I_H_
