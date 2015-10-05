Gradual Typing Performance
==========================

Data & code for our POPL 2015 submission.

- To compile the paper, run `cd paper; make`.
- To run a benchmark, run `./run.sh benchmarks/NAME`, where `NAME` is a folder in the `benchmarks/` directory.
  Results will be saved under the  `./benchmarks` directory.
- To view results for a set of benchmarks, run `./view.rkt FILE.rktd ...` for a list of `.rktd` files generated by the `run.sh` script.


Reproducing our Results
-----------------------
1. Execute the `./run-all.sh` script. _Warning:_ this may take over 6 months.
2. Run `./view.rkt benchmarks/*.rktd` to see the output.


Sub-Folders
-----------
- `benchmarks` Source code for our benchmark projects.
- `paper` Source for our paper.
- `tools` Utilities for generating benchmark configurations and running experiments.
