#!/bin/bash
#
# gevgen_rivet.sh: run GENIE and analyse the events with Rivet as they are generated,
# without storing them (unless --keep-events is given).
#
# gevgen writes HepMC3 (NuHepMC) events into a named pipe and Rivet reads them from it, so the events
# only pass through a small memory buffer. Several jobs (seeds) can run per beam energy; their Rivet
# outputs are merged per energy (as equivalent runs) and then across energies.
#
# Run with -h for the options. See README.md in this directory.

set -u

usage() {
  cat <<'EOF'
Usage: gevgen_rivet.sh -a ANALYSES -p PROBE -t TARGET -e ENERGIES -n NEVENTS [options] -- [gevgen options]

Required:
  -a ANALYSES        Rivet analyses, comma separated (e.g. CLAS_2026_I0000000)
  -p PROBE           probe PDG code (e.g. 11)
  -t TARGET          target PDG code (e.g. 1000060120)
  -e ENERGIES        beam energies in GeV, comma separated (e.g. 1.159,2.257,4.453)
  -n NEVENTS         number of events per job

Options:
  -j, --jobs N       jobs (different seeds) per energy (default 1)
  -P, --parallel N   jobs running at the same time (default: number of CPUs)
  -s, --seed S       seed of the first job; job k of energy i uses S + 1000*i + k (default 1000)
  -r, --run R        gevgen run number (default 0)
  -o, --output DIR   output directory (default ./gevgen_rivet)
  --title TEXT       legend title of the plots (default "GENIE")
  --keep-events      also store the events, gzipped, in each job directory
  --timeout SEC      stop a job after SEC seconds (default 0 = no limit)
  --rivet-args ARGS  options passed to rivet (default "--ignore-beams --weight-nominal CV")
  --setup FILE       source FILE (e.g. the GENIE and Rivet environment setup) before running
  --no-plots         do not run rivet-mkhtml at the end
  -h, --help         this help

Everything after "--" is passed to gevgen, e.g.
  -- --tune G18_10a_02_11b --cross-sections splines.xml --event-generator-list EM

Example:
  gevgen_rivet.sh -a CLAS_2026_I0000000 -p 11 -t 1000060120 -e 1.159,2.257,4.453 -n 100000 -j 4 \
    -- --tune GEM21_11a_00_000 --cross-sections splines.xml --event-generator-list EM
EOF
}

# ---------------------------------------------------------------------------------------------
# Options

ANALYSES=""; PROBE=""; TARGET=""; ENERGIES=""; NEVENTS=""
NJOBS=1; NPARALLEL=""; SEED=1000; RUN=0; OUTDIR="gevgen_rivet"; TITLE="GENIE"
KEEP=0; TIMEOUT=0; RIVET_ARGS="--ignore-beams --weight-nominal CV"; PLOTS=1; SETUP=""
GEVGEN_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    -a) ANALYSES="$2"; shift 2 ;;
    -p) PROBE="$2"; shift 2 ;;
    -t) TARGET="$2"; shift 2 ;;
    -e) ENERGIES="$2"; shift 2 ;;
    -n) NEVENTS="$2"; shift 2 ;;
    -j|--jobs) NJOBS="$2"; shift 2 ;;
    -P|--parallel) NPARALLEL="$2"; shift 2 ;;
    -s|--seed) SEED="$2"; shift 2 ;;
    -r|--run) RUN="$2"; shift 2 ;;
    -o|--output) OUTDIR="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --keep-events) KEEP=1; shift ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --rivet-args) RIVET_ARGS="$2"; shift 2 ;;
    --no-plots) PLOTS=0; shift ;;
    --setup) SETUP="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; GEVGEN_ARGS=("$@"); break ;;
    *) echo "Unknown option: $1 (gevgen options go after --)" >&2; usage >&2; exit 1 ;;
  esac
done

if [ -z "$ANALYSES" ] || [ -z "$PROBE" ] || [ -z "$TARGET" ] || [ -z "$ENERGIES" ] || [ -z "$NEVENTS" ]; then
  usage >&2; exit 1
fi
if [ -n "$SETUP" ]; then
  source "$SETUP" || { echo "Could not source $SETUP" >&2; exit 1; }
fi
# macOS removes DYLD_LIBRARY_PATH when a system program such as /bin/bash starts; restore it from
# LD_LIBRARY_PATH (which GENIE setups usually export too), otherwise gevgen cannot find its libraries
if [ "$(uname)" = "Darwin" ] && [ -z "${DYLD_LIBRARY_PATH:-}" ] && [ -n "${LD_LIBRARY_PATH:-}" ]; then
  export DYLD_LIBRARY_PATH="$LD_LIBRARY_PATH"
fi
if [ -z "$NPARALLEL" ]; then
  NPARALLEL=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
fi
for tool in gevgen rivet rivet-merge mkfifo; do
  command -v $tool > /dev/null || { echo "$tool not found in PATH" >&2; exit 1; }
done
if [ $PLOTS -eq 1 ] && ! command -v rivet-mkhtml > /dev/null; then
  echo "rivet-mkhtml not found in PATH: no plots will be made" >&2; PLOTS=0
fi

mkdir -p "$OUTDIR" || exit 1
OUTDIR=$(cd "$OUTDIR" && pwd)
IFS=',' read -r -a ELIST <<< "$ENERGIES"

# ---------------------------------------------------------------------------------------------
# One job: gevgen -> named pipe -> rivet. Writes "ok" or "failed: <reason>" to the job's status file.

run_job() {
  local energy=$1 seed=$2 dir=$3
  mkdir -p "$dir" && cd "$dir" || return 1
  rm -f events.pipe rivet.pipe events.hepmc3.gz rivet.yoda job.status
  mkfifo events.pipe || { echo "failed: mkfifo" > job.status; return 1; }

  # Rivet reads the events (from the gevgen pipe, or from a second pipe when the events are kept)
  local rivet_input=events.pipe tee_pid=""
  if [ $KEEP -eq 1 ]; then
    mkfifo rivet.pipe || { echo "failed: mkfifo" > job.status; return 1; }
    rivet_input=rivet.pipe
  fi
  rivet -a "$ANALYSES" $RIVET_ARGS -o rivet.yoda "$rivet_input" > rivet.log 2>&1 &
  local rivet_pid=$!
  if [ $KEEP -eq 1 ]; then
    ( cat events.pipe | tee rivet.pipe | gzip > events.hepmc3.gz ) &
    tee_pid=$!
  fi

  gevgen -n "$NEVENTS" -p "$PROBE" -t "$TARGET" -e "$energy" -r "$RUN" --seed "$seed" \
         -o events.pipe,hepmc "${GEVGEN_ARGS[@]}" > gevgen.log 2>&1 &
  local gevgen_pid=$!

  # Watch both: a failure of one side would leave the other one waiting on the pipe forever
  local start=$(date +%s) gevgen_status="" rivet_status="" reason=""
  while true; do
    if [ -z "$gevgen_status" ] && ! kill -0 $gevgen_pid 2>/dev/null; then
      wait $gevgen_pid; gevgen_status=$?
      if [ $gevgen_status -ne 0 ]; then
        reason="gevgen exit $gevgen_status"
        kill $rivet_pid $tee_pid 2>/dev/null
      fi
    fi
    if [ -z "$rivet_status" ] && ! kill -0 $rivet_pid 2>/dev/null; then
      wait $rivet_pid; rivet_status=$?
      if [ -z "$gevgen_status" ]; then   # rivet stopped before gevgen finished
        [ -z "$reason" ] && reason="rivet exit $rivet_status before the end of the events"
        kill $gevgen_pid $tee_pid 2>/dev/null
      fi
    fi
    [ -n "$gevgen_status" ] && [ -n "$rivet_status" ] && break
    if [ "$TIMEOUT" -gt 0 ] && [ $(( $(date +%s) - start )) -gt "$TIMEOUT" ]; then
      reason="timeout after $TIMEOUT s"
      kill $gevgen_pid $rivet_pid $tee_pid 2>/dev/null
    fi
    sleep 2
  done
  [ -n "$tee_pid" ] && wait $tee_pid 2>/dev/null
  rm -f events.pipe rivet.pipe

  if [ -z "$reason" ] && [ "$rivet_status" -ne 0 ]; then reason="rivet exit $rivet_status"; fi
  if [ -z "$reason" ] && [ ! -s rivet.yoda ]; then reason="no rivet output"; fi
  if [ -n "$reason" ]; then echo "failed: $reason" > job.status; else echo "ok" > job.status; fi
}

# ---------------------------------------------------------------------------------------------
# Run all the jobs, at most NPARALLEL at a time

echo "Output directory: $OUTDIR"
for ie in "${!ELIST[@]}"; do
  for (( k = 0; k < NJOBS; k++ )); do
    while [ $(jobs -rp | wc -l) -ge "$NPARALLEL" ]; do sleep 2; done
    energy=${ELIST[$ie]}
    seed=$(( SEED + 1000*ie + k ))
    dir="$OUTDIR/E${energy}GeV/job$k"
    echo "Starting E = $energy GeV, job $k (seed $seed)"
    run_job "$energy" "$seed" "$dir" &
  done
done
wait

# ---------------------------------------------------------------------------------------------
# Merge: jobs of one energy are equivalent runs (rivet-merge -e); the energies are then combined
# (plain rivet-merge), which is right when each energy fills its own histograms

nfailed=0
energy_yodas=()
for energy in "${ELIST[@]}"; do
  edir="$OUTDIR/E${energy}GeV"
  good=()
  for (( k = 0; k < NJOBS; k++ )); do
    st=$(cat "$edir/job$k/job.status" 2>/dev/null || echo "failed: no status")
    if [ "$st" = "ok" ]; then good+=("$edir/job$k/rivet.yoda")
    else echo "E = $energy GeV, job $k $st (see $edir/job$k/*.log)" >&2; nfailed=$((nfailed+1)); fi
  done
  [ ${#good[@]} -eq 0 ] && continue
  if [ ${#good[@]} -eq 1 ]; then cp "${good[0]}" "$edir/merged.yoda"
  else rivet-merge -e -o "$edir/merged.yoda" "${good[@]}" > "$edir/merge.log" 2>&1 || { echo "Merging $edir failed" >&2; continue; }
  fi
  energy_yodas+=("$edir/merged.yoda")
done

if [ ${#energy_yodas[@]} -eq 0 ]; then echo "No successful job" >&2; exit 1; fi
if [ ${#energy_yodas[@]} -eq 1 ]; then cp "${energy_yodas[0]}" "$OUTDIR/rivet.yoda"
else rivet-merge -o "$OUTDIR/rivet.yoda" "${energy_yodas[@]}" > "$OUTDIR/merge.log" 2>&1 || { echo "Final merge failed" >&2; exit 1; }
fi
echo "Rivet output: $OUTDIR/rivet.yoda"

if [ $PLOTS -eq 1 ]; then
  rivet-mkhtml -o "$OUTDIR/plots" "$OUTDIR/rivet.yoda:Title=$TITLE" > "$OUTDIR/mkhtml.log" 2>&1 \
    && echo "Plots: $OUTDIR/plots/index.html" || echo "rivet-mkhtml failed (see $OUTDIR/mkhtml.log)" >&2
fi

[ $nfailed -gt 0 ] && { echo "$nfailed job(s) failed" >&2; exit 2; }
exit 0
