#lang scribble/sigplan @nocopyright

@(require "common.rkt"
          racket/vector
          math/statistics)

@authorinfo["Asumu Takikawa" "Northeastern University" "asumu@ccs.neu.edu"]
@authorinfo["Daniel Feltey" "Northeastern University" "dfeltey@ccs.neu.edu"]
@authorinfo["Ben Greenman" "Northeastern University" "types@ccs.neu.edu"]
@authorinfo["Max S. New" "Northeastern University" "maxsnew@ccs.neu.edu"]
@authorinfo["Jan Vitek" "Northeastern University" "j.vitek@ccs.neu.edu"]
@authorinfo["Matthias Felleisen" "Northeastern University" "matthias@ccs.neu.edu"]

@title{Position Paper: Performance Evaluation for Gradual Typing}

@section{The Gradual Typing Promise}

Gradually typed programming languages promise to improve software maintenance.
Using such systems, programmers may selectively add type annotations to their existing
untyped programs. The annotated parts are checked, and run-time contracts or
casts ensure that they safely interact with the remaining untyped portions.

Programmers use gradual type systems in order to realize software engineering
benefits from types such as enforcing documentation, guiding refactoring, and
catching regressions. In addition, the gradual typing promise implies that as
programmers add type annotations, their program will continue to run. This part
of the promise is held up by allowing typed and untyped code to link together with
inserted run-time checks.
For a gradual type system to be a net benefit, it should
also allow gradually typed programs to remain @emph{performant} when they are
run. Therefore, it is
desirable for a gradual type system to promise low overhead for
interoperation.

In our experience, existing gradual type systems
(including the systems we maintain) fail to meet this criterion.
For example, the Typed Racket developers have received bug reports from users who observed
drastic slowdowns after adding types.
Gradual type systems in the literature report slowdowns of 72x@~cite[rsfbv-popl-2015],
10x@~cite[vksb-dls-2014], and 4x@~cite[tfdffthf-ecoop-2015] in programs due to the insertion of
dynamic checks.

To make gradual type systems live up to their promises, we must
(1) diagnose what kinds of programs and what degree of ``typedness'' leads
to performance problems, and (2) identify the tools, language features,
or implementation techniques that will help eliminate the overhead.
For now, we will focus on the diagnostic side and hope to investigate
solutions in the future.

@section{The State of Gradual Type System Evaluation}

Despite the proliferation of the gradual type system literature, there is a dire
lack of performance evaluation efforts.
Several projects have reported on slowdowns on example programs@~cite[rsfbv-popl-2015 vksb-dls-2014 tfdffthf-ecoop-2015]
and others have explored the cost of the checking mechanism itself@~cite[aft-dls-2013]
but these results are difficult to compare and interpret in the broader
context of the software engineering benefits that gradual type systems promise.

In part, this points to a lack of any accepted methodologies for evaluating
gradual type system performance. Such a methodology should provide a systematic
approach to evaluating interoperation overhead.
In the following sections, we propose steps towards a methodology that tries
to discover such overheads by considering the possible configurations that
such a programmer would explore.

@section{Exploring the Program Space}

To work towards a methodology, we need to first understand how gradual type
systems are used. First, programmers do not add type annotations to an entire
program at once. The thesis of gradual typing is that programmers can choose
intermediate states in which some parts of the program are typed and others are
untyped. The specific granularity of these type annotated sections depends on
the gradual type system.

For our evaluation, we focus on Typed Racket because of its
maturity as a gradual type system (it has been in development since 2006).
Typed Racket is a @emph{macro}-level gradual type system, which means
that types are added to the program at module granularity and dynamic checks
are installed at these boundaries between typed and untyped modules. As a result,
Typed Racket does not need to instrument untyped modules at all, which enables
separate compilation within gradually typed programs.

@figure["lattice-example" "Lattice example with five modules"]{
  @(let* ([vec (file->value "zordoz-all-runs.rktd")]
          [vec* (vector-map (λ (p) (cons (mean p) (stddev p))) vec)])
     (scale (make-performance-lattice vec*) 0.7))
}

This is in contract to the @emph{micro}-level approach, in which typed and
untyped code is mixed freely in a program. Variables without type annotations
are assigned the type @tt{Dyn}. These variables induce casts when typed
portions of the program expect more specific types. We comment on the difficulties
of scaling our approach to micro gradual typing in @secref["scale"].

Recognizing that programmers gradually add types to their program, we propose
to look at all of the possible ways in which a programmer would add types to
a program given the macro approach. Specifically, we take existing Racket programs,
come up with type annotations for all of the modules in the program, and then
consider the possible typed/untyped configurations of modules. We
then benchmark all of these possible configurations to determine the performance
overhead of run-time checks by comparing against the original program.

Given n modules in the program, this produces 2@superscript{n} configurations of
the program. We can represent this space of
configurations as a lattice in which the nodes represent a particular configuration
of modules in a program---that is, whether each module is typed or untyped.
An edge between two nodes A and B indicates that configuration A can be turned
into configuration B by adding type annotations to one additional module.
See @figure-ref{lattice-example} for an example of a program lattice. The
bottom of the lattice represents the original, fully untyped program and the top of
the lattice represents the program with types added to all modules.

The labels on the nodes represent the normalized runtimes (mean and standard
deviation) of benchmarks that we run on the whole program. The black and
whtie boxes represent whether a module is typed (black) or untyped (white).
Note that since a program may call out to additional libraries, the top of the
lattice (the fully typed program) may still have run-time overhead.

Paths in the graph that start from the bottom correspond to the timeline
of a hypothetical programmer who is adding types to the program.
Ideally, most configurations of the program have reasonable overhead.
In practice, however, many portions of the lattice will contain regions of poor
performance due to, for example,
tightly coupled modules with dynamic checks on the boundary.

As a first attempt, several of the authors worked on a small-scale
version of this approach in @citet[tfdffthf-ecoop-2015] in the context of
Typed Racket. Following up, we are working on scaling this
evaluation idea to programs with a larger number of modules
(and hence a much larger number of variations) and are
investigating both functional and object-oriented programs. We discuss
the difficulties in scaling our idea in the next section.


@section[#:tag "scale"]{Request for Comments: Scaling the Idea}

The large number of variations, 2@superscript{n} in the number of modules, in
particular makes data visualization and analysis difficult. We are therefore
considering alternatives to the lattice form of visualization such as histograms over
path metrics and heatmaps. This problem is compounded when the idea is applied
to micro-level gradual typing.

While our idea is straightforward for the macro style of gradual typing,
it is not obvious how to apply it to the micro approach that is common in
other systems such as Gradualtalk@~cite[acftd-scp-2013], Reticulated Python,
and Safe TypeScript. Specifically, it is not clear how to set up the space of variations.
For example, type annotations could be toggled by function, by module, or even
by binding site. Picking the latter would lead to a particularly large configuration space
since every variable multiplies the number of variations by two.

@section{Investigating Potential Solutions}

After diagnosing the kinds of overhead found in gradually-typed programs, we intend
to investigate possible solutions. Solutions may come in the form of mitigation,
in which a tool or language feature helps avoid problematic dynamic checks. Alternatively,
the solutions may instead seek to reduce the cost of the checks.

One form of mitigation we have identified is to guide the programmer to good paths
through the state space using techniques such as Feature-specific
Profiling@~cite[saf-cc-2015] with contracts/casts as the target feature.

We also intend to investigate the use of tracing JIT compilation based on the Pycket
work by @citet[bauman-et-al-icfp-2015]. The Pycket authors report dramatic reductions
in contract checking overhead in untyped Racket programs. We are interested in seeing
if tracing also benefits the kinds of contract usages that we see in gradually typed
programs.

@section{Conclusion}

Runtime overhead for gradually-typed programs is a pressing concern as gradual typing
is adopted both by researchers and by industrial groups. However, there are open
questions in both diagnosing where these overheads occur and in solving them.
We propose an idea for a methodology
for diagnosing such overheads by visualizing how adding types to existing programs affects the runtime
along various gradual typing paths. Using the diagnostic information, we hope to
drive efforts in both tooling and compilation for gradually typed languages.

@generate-bibliography[]
