# gevgen_rivet.sh: GENIE events analysed by Rivet without storing them

`gevgen_rivet.sh` runs `gevgen` and analyses the events with [Rivet](https://rivet.hepforge.org) while
they are generated, as PYTHIA does with its Rivet interface. `gevgen` writes HepMC3 (NuHepMC) events
into a named pipe and Rivet reads them from it: each event only passes through a small memory
buffer, so any number of events can be compared with data without keeping event files. With
`--keep-events` the events are also stored, gzipped.

For each beam energy it runs one or more jobs with different seeds, merges their Rivet outputs, then
merges the energies and makes the plots with `rivet-mkhtml`.

## Requirements

- GENIE built with HepMC3 output (`./configure --enable-hepmc3`), i.e. `gevgen -o <file>,hepmc`.
- Rivet 4 (`rivet`, `rivet-merge`, `rivet-mkhtml` in the `PATH`) and the analyses to run
  (`RIVET_ANALYSIS_PATH`, and `RIVET_DATA_PATH` for the reference data).
- The splines for the requested probe, target and energies.

## Usage

```bash
$GENIE/src/scripts/rivet/gevgen_rivet.sh -a ANALYSES -p PROBE -t TARGET -e ENERGIES -n NEVENTS [options] -- [gevgen options]
```

Example: the e4nu 1p1π analysis on carbon at the three CLAS beam energies, 4 jobs of 100k events
per energy:

```bash
gevgen_rivet.sh -a CLAS_2026_I0000000 -p 11 -t 1000060120 -e 1.159,2.257,4.453 -n 100000 -j 4 \
  -o e4nu_1p1pi --title "GENIE GEM21-11a" \
  -- --tune GEM21_11a_00_000 --cross-sections e_C12_splines.xml --event-generator-list EM
```

| Option | |
|---|---|
| `-a` | Rivet analyses, comma separated |
| `-p`, `-t` | probe and target PDG codes |
| `-e` | beam energies in GeV, comma separated |
| `-n` | events per job |
| `-j N` | jobs (seeds) per energy (default 1) |
| `-P N` | jobs running at the same time (default: number of CPUs) |
| `-s S` | seed of the first job; job k of energy i uses S + 1000 i + k (default 1000) |
| `-r R` | gevgen run number (default 0) |
| `-o DIR` | output directory (default `./gevgen_rivet`) |
| `--title TEXT` | legend title of the plots (default `GENIE`) |
| `--keep-events` | also store the events as `events.hepmc3.gz` in each job directory |
| `--timeout SEC` | stop a job after SEC seconds (default: no limit) |
| `--rivet-args ARGS` | options for `rivet` (default `--ignore-beams --weight-nominal CV`) |
| `--setup FILE` | file sourced before running (e.g. the GENIE and Rivet environment) |
| `--no-plots` | do not run `rivet-mkhtml` |

Everything after `--` goes to `gevgen` (tune, splines, event generator list, message thresholds, ...).

The default `--rivet-args` are needed for NuHepMC events: Rivet does not always recognise the beams
(the target nucleus is not flagged as a beam particle), and GENIE calls its nominal weight `CV`.

## Output

```
DIR/
  rivet.yoda                 all energies, merged
  plots/index.html           rivet-mkhtml plots
  E<energy>GeV/merged.yoda   jobs of one energy, merged
  E<energy>GeV/job<k>/       rivet.yoda, gevgen.log, rivet.log, job.status (and events.hepmc3.gz)
```

The jobs of one energy are statistically equivalent and are merged with `rivet-merge -e`. The energies
are then combined with a plain `rivet-merge`, which is right when each energy fills its own histograms
(as in analyses with one set of histograms per beam energy).

## Failures

If `gevgen` stops with an error, Rivet is stopped too, and the other way round, so that no job waits
forever on its pipe. A failed job is reported with its reason (`job.status`), it is left out of the
merging, and the script exits with code 2. A job that ends because `gevgen` crashed after writing
some events is also reported as failed, rather than merged with fewer events.

## Notes

- **macOS:** the system removes `DYLD_LIBRARY_PATH` when `/bin/bash` starts. The script restores it
  from `LD_LIBRARY_PATH` if needed; otherwise use `--setup` with the GENIE environment script.
- **Minimum Q²:** the events must cover the Q² range of the analysis. Check the minimum Q² of the
  GENIE build (`kMinQ2Limit` in `src/Framework/Conventions/Controls.h`) and of the splines. In the
  HOvER branches it is 0.95 GeV², too high for analyses at lower Q² such as the e4nu ones at
  1.159 and 2.257 GeV.
- The pipe only saves storage: the events are still written as HepMC3 text and read back by Rivet,
  which costs much less than generating them.
