#lang scribble/manual

@(require (for-label karp/problem-definition
                     karp/reduction
                     karp/lib/graph
                     karp/lib/cnf)
          scribble/example
          scribble-math)

@(define 3-SAT @${\rm 3\text{-}S{\small AT}})
@(define I-SET @${\rm I{\small NDEPENDENT}\text{-}S{\small ET}})

@title[#:tag "ch:quickstart" #:style (with-html5 manual-doc-style)]{Getting Started with Karp by Example: 3sat to independent-set}

In this short guide we will formulate the reduction
from @3-SAT to @I-SET in Karp.

Recall that a decision problem is a problem that has answer "yes" or "no". A decision problem
is in @${NP} if there exists short certificates for instances with "yes" answer.

A (Karp) reduction from NP @${X} to @${Y} is a transformation that takes an instance of
@${X} and produces an instance of @${Y} in polynomial time that preserves the yes/no answer.

A runnable and testable reduction in Karp from decision problem @racketid[X] to decision
problem @racketid[Y] consists of four parts:
@itemize{
  @item{The @italic{problem definition of decision} problem @racketid[X] and @racketid[Y].}
  @item{The @italic{forward instance construction} that transforms any @racketid[X]-instance
  to an @racketid[Y]-instance.}
  @item{The @italic{forward certificate construction} that transforms any certificate of a given
 @racketid[X]-instance @racketid[x] to a certificate of the @racketid[Y]-instance obtained by applying 
 @italic{forward instance construction} @racketid[x].}
  @item{The @italic{backward certificate construction} that transforms any certificate of the
  @racketid[Y]-instance obtained by applying @italic{forward instance construction} to a given
 @racketid[X]-instance @racketid[x] back to a certificate of @racketid[x].}
}

The @italic{forward instance construction} is the (Karp) "reduction" in the usual sense and
the two certificate constructions serve as the proof of yes/no answers are preserved.

@section{Problem Definitions}

The definition of a decision problem in Karp is written in the sublangauge:
@racketmod[karp/problem-definition]

@subsection{3-Sat}
The problem definition of @3-SAT is given below:
@codeblock[
   #:indent 0
  "#lang karp/problem-definition

  ; importing the karp cnf and mapping libraries
  (require karp/lib/cnf
           karp/lib/mapping)

  ; problem structure definition
  (decision-problem
            #:name 3sat
            #:instance ([φ is-a (cnf #:arity 3)])
            #:certificate (mapping #:from (variables-of φ)
                                   #:to (the-set-of boolean)))

 ; verifier definition
 (define-3sat-verifier a-inst c^3sat
   (∀ [C ∈ (clauses-of (φ a-inst))]
      (∃ [l ∈ (literals-of C)]
         (or (and
              (positive-literal? l) (c^3sat (underlying-var l)))
             (and
              (negative-literal? l) (not (c^3sat (underlying-var l))))))))"
 ]
The definition of a problem consists of two parts:
@itemlist[#:style 'ordered
          @item{Problem structure definition:
          @racket[decision-problem] defines a problem along with its instance and
          certificate data structure.}
          @item{Verifier definition: Defining the problem structure enables
           the @racketid[define-3sat-verifier] form used to define the certificate verifier of
           @racketid[3sat]. A verifier is a function that takes an instance and an alleged
           certificate, checking if the certificate is indeed a certificate of the instance.
           The body of the verifier should produce a Boolean.
           }]

After the problem @racketid[3sat] is defined, the constructors and the
certificate solver of @racketid[3sat] instances are enabled: 
@codeblock[
 #:keep-lang-line? #f
 "#lang karp/problem-definition
 (define foo (create-3sat-instance
     ([φ
       (cnf ('x1 ∨ 'x2 ∨ 'x3)
            ((¬'x1) ∨ (¬'x2) ∨ (¬'x3))
            ((¬'x1) ∨ (¬'x2) ∨ 'x3))])))
 (define foo-cert (mapping ('x1 ~> #f) ('x2 ~> #t) ('x3 ~> #f)))
 (3sat-verifier foo foo-cert) ;#t
 (define foo-non-cert (mapping ('x1 ~> #t) ('x2 ~> #t) ('x3 ~> #t)))
 (3sat-verifier foo foo-cert) ;#f
 (define foo-cert2 (3sat-solver foo))
 (3sat-verifier foo foo-cert2) ;#t"
]

@subsection{Independent Set}

In a similar manner, the @I-SET problem can be defined as follows:
@codeblock[
 #:indent 0
 "#lang karp/problem-definition

(require karp/lib/graph)

; problem structure definition
(decision-problem
          #:name iset
          #:instance ([G is-a (graph #:undirected)]
                      [k is-a natural])
          #:certificate (subset-of (vertices-of G)))

 ; verifier definition
 (define-iset-verifier a-inst c^iset
  (and
   (>= (set-size c^iset) (k a-inst))
   (∀ [u ∈ c^iset]
     (∀ [v ∈ (neighbors (G a-inst) u)]
       (set-∉ v c^iset)))))"
 ]

The definition of independent set uses the Karp graph
library. A graph can be created as follows:
@codeblock[
 #:keep-lang-line? #f
 "#lang karp/problem-definition
 (define V1 (set 'x1 'x2 'x3 'x4))
 (define E1 (set ('x1 . -e- . 'x2)
                 ('x1 . -e- . 'x3)
                 ('x3 . -e- . 'x4)
                 ('x2 . -e- . 'x3)))
 (define G1 (create-graph V1 E1))
 "
]
We can then create an independent set from the graph
and play around with it:
@codeblock[
 #:keep-lang-line? #f
 "#lang karp/problem-definition
 (define/iset-instance iset-inst1 ([G G1] [k 2]))
 (iset-verifier iset-inst1 (set 'x1 'x4)) #; #t
 (iset-verifier iset-inst1 (set 'x1 'x3)) #; #f
 (define c^iset1 (iset-solver iset-inst1))
 (iset-verifier iset-inst1 c^iset1) #; #t
 "
]

@section{Reduction}
The remaining part of the reduction in Karp is defined using the sublangauge
@racketmod[karp/reduction]
The three constructions are defined using @racket[define-forward-instance-construction],
@racket[define-forward-certificate-construction] and @racket[define-backward-certificate-construction]
respectively.
                                                             
@codeblock[
 #:indent 0
 "#lang karp/reduction
 ; importing the problem definitions and the libraries.
 (require (union-in \"3sat.karp\" \"iset.karp\")
          karp/lib/cnf
          karp/lib/graph
          karp/lib/mapping-reduction)"
]

Recall that in a correct reduction from @3-SAT to @I-SET
constructs a @I-SET instance from a given @3-SAT instance in the following steps:

@itemlist[ #:style 'ordered
@item{First, create a vertices for each literals in each clause of the @3-SAT instance:
@image["figures/1.png"
       #:scale 0.2]{V}}

@item{Then, adding the set of edges @${E1} that connects the vertices that correspond to
literals that are negation of each other:
@image["figures/2.png"
       #:scale 0.2]}

@item{Next, adding the set of edges @${E2} that connects the vertices that correspond to
literals in the same clause.
@image["figures/3.png"
       #:scale 0.2]}

@item{Finally, putting the graph together and set the threshold @${k} to be the number
of clauses, we get the @I-SET instance.}
]

The Karp code for the procedure is shown below:
@racketblock[
 (define-forward-instance-construction
  #:from 3sat #:to iset
  (3sat->iset-v1 a-3sat-inst)

  (define Cs (clauses-of (φ a-3sat-inst)))
  ; creating the node for the graph
  (define V (for/set {(el l i) for [l ∈ C] for [(C #:index i) ∈ Cs]}))
  ; creating the set E1 for the graph
  (define E1
    (for/set {((el l1 i) . -e- . (el l2 j))
              for [l1 ∈ (literals-of C1)] for [l2 ∈ (literals-of C2)]
              for [(C1 #:index i) ∈ Cs] for [(C2 #:index j) ∈ Cs]
              if (literal-neg-of? l1 l2)}))
  ; creating the set E2 for the graph
  (define E2
    (for/set {((el (fst p) i) . -e- . (el (snd p) i))
              for [p ∈ (all-pairs-in (literals-of C))]
              for [(C #:index i) ∈ Cs]}))

  ; commenting out the E2 to introduce a mistake
  (create-iset-instance ([G (create-graph V (set-∪ E1 E2))]
                         [k (set-size Cs)])))]
The code shown above defines a instance transformation function with name
@racket[3sat->iset-v1] which takes one arguement @racket[a-3sat-inst].

In the definition of @racketid[E1], we create the vertices
as abstract elements @racketid[el] with first subscript being
the literal itself and the second subscript being the index
of the clause in the CNF the literal comes from.

@racket[[(C #:index i) ∈ Cs]] binds the index of the current element in question
@racket[C] in set @racket[Cs] to @racket[i].

@racket[((el l1 i) . -e- . (el l2 j))] creates an (undirected) edge with endpoints 
@racket[(el l1 i)] and @racket[(el l2 j)].

@subsection{Forward Certificate Construction}

The forward certificate construction maps a certificate of the from-problem
instance to a certificate of the to-problem. It serves as a proof that
a no-instance is always transformed to a no-instance.

To construct a certificate of @I-SET from a certificate of @3-SAT,
we find one literal in each clause of the CNF and pick the vertices
corresponding to these literals to form the certificate.
@image["figures/4.png"
       #:scale 0.2]

The Karp code of which is shown below:
@racketblock[
 (define-forward-certificate-construction
  #:from 3sat #:to iset
  (3sat->iset->>-cert-v1 s->t-constr a-3sat-inst c^sat)

  ; getting the set of vertices from the assignment
  (for/set
     {(el
        (find-one [l ∈ C] s.t.
          (or
            (and (positive-literal? l)
                 (c^sat (underlying-var l)))
            (and (negative-literal? l)
                 (not (c^sat (underlying-var l))))))
        i)
       for [(C #:index i) in (φ a-3sat-inst)]}))]
The code snippet defines a transformation function with name
@racket[3sat->iset->>-cert-v1] that expects three arguments:
@itemlist{@item{an instance transformation function @racket[s->t-constr]}@item{a @racket[3sat] instance @racket[a-3sat-inst]}@item{a @racket[3sat] certificate @racket[c^sat],
  which is a mapping from the variables of @racket[a-3sat-inst] to booleans}}
 It returns a @racket[iset] certificate, which is a subset of vertices.

@subsection{Backward Certificate Construction}

The backward certificate construction maps a certificate of the to-problem
instance back to a certificate of the from-problem. It serves as a proof that
a yes-instance is always transformed to a yes-instance.

To construct a @3-SAT certificate from a @I-SET certificate:
We first find those variables that should be assigned to true.
Each of these variable must be the underlying variable of some
positive literal and the vertex correponding to the literal is
in the independent set. We then create a mapping with these
variables mapped to true and all other variables mapped to false.
(The illustration is the same as the previous one)

The procedure is decribed in Karp as follows:
@racketblock[
(define-backward-certificate-construction
  #:from 3sat #:to iset 
  (3sat->iset-<<-cert-v1 s->t-constr a-3sat-inst c^iset)

  (define X (variables-of (φ a-3sat-inst)))
  ; mapping back from vertices to assignments
  (define X-True
    (for/set {x for [x ∈ X]
                if (∃ [v in c^iset]
                      (and
                       (positive-literal? (_1s v))
                       (equal? (underlying-var (_1s v)) x)))}))
  (mapping
   [x ∈ X-True] ~> #t
   [x ∈ (set-minus X X-True)] ~> #f))]

To extract the corresponding literal from the vertex, we
use @racket[_1s] to get the first subscript of the vertex,
which is an abstract element as we defined in the instance construction.

@subsection{Testing Reductions}
We now have all parts of a runnable and testable reduction ready, we can
random test the reduction with @racket[check-reduction] by suppplying it
with the three transformation functions we just defined.
@racketblock[(check-reduction #:from 3sat #:to iset
                 3sat->iset-v1 3sat->iset->>-cert-v1 3sat->iset-<<-cert-v1)]

To see how a buggy reduction can be caught by the random testing,
omitting the @racket[E2] in the instance construction and rerun
the @racket[check-reduction]. @racket[(get-counterexample)] can be used
to access the @3-SAT instance found as counterexample in the latest
run of the @racket[check-reduction]. To reproduce the testing result
to help debugging, a random seed can be specified by adding an extra
option @racket[#:random-seed] to @racket[check-reduction].
