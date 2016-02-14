misc
====

Miscellaneous and outdated scripts.
The graveyard.

grouping.py
-----------

Usage: `grouping.py FILE.tab`

Creates a histogram from the runtimes in `FILE.tab`.
Histogram bins are spaced evenly between the minimum and maximum runtimes of any configuration.
The number of BINS is hard-coded near the bottom of the file.


shortest-path.py
----------------

Usage: `shortest-path.py FILE.tab`

Creates the module lattice from the data in `FILE.tab`.
First prints the shortest path (by SUM) from the fully-untyped configuration up to the typed configuration.
Next creates histograms of all paths from untyped to typed.
The histograms are partitioned as in `grouping.py`, but weights are computed using a hard-coded measure.
The number of bins is hard-coded near the bottom of the file.

The measures we currently use are:
- SUM: a path's weight is the sum of its edges' weights
- MAX: a path's weight is the maximum of its edges' weights
- MIN: like MAX, but using minumum weight

module-graph.py
---------------

Usage: `module-graph.py FILE.tab FILE.graph`

Creates the module dependence graph from the specification in `FILE.graph`.

The script expects its input to be a tab-separated file with columns:
    MODULE	INDEX	REQUIRES
The first column should be filenames, like `main.rkt`.
The second column should be an integer index, indicating this file's position in the configuration bitstrings generated by the benchmarking script.
For example, a configuration with one typed module might be marked by the string "0010".
In this case the module with index 2 is the only typed module (marked with a "1").
The last column should be a comma-separated list of filenames.
These should be the files that `MODULE` requires, and are used to draw directed edges in the graph.

After creating the graph, the script draws a few pictures.

boxplot.py
----------

Usage: `boxplot.py FILE.tab`

Create a boxplot representing `FILE.tab`.
Make one box for each level of typed-ness.


violinplot.py
-------------
Usage: `violinplot.py FILE.tab`

Create a violin representing `FILE.tab`.
Identical to `boxplot.py`, but shows the experiments' distribution.


bigpicture.py
-------------
Usage: `bigpicture.py FILE.tab ...`

Creates a violin plot for each argument file, using every single data point in the argument file.
Plots all violins on the same graph, to give a sense of scale.


sampling.py
-----------
Usage: `sampling.py FILE.tab`

Do t-test sampling in `FILE.tab`.
Current, the number of samples is `min(30, num_modules)`, where `num_modules` is the number of modules in the project that `FILE.tab` represents.

edge-violin.py
--------------
Usage: `edge-violin.py FILE.tab`

For all groups of edges, build a violin plot of distributions when this edge is a boundary VS. when the edge is not a boundary.
(Do not bother checking which nodes are typed or untyped, just check if it's a boundary.)

Apply some basic filtering to avoid printing too many graphs.