:- include("./policy.pl").
:- use_module(library(http/json)).

% Meta-interpreter
%
% base case, end(leaf) of the proof tree
mi_proof_tree(true, [true]).
% conjunction
mi_proof_tree((A, B), Tree) :-
    !,
    mi_proof_tree(A, TreeA),
    mi_proof_tree(B, TreeB),
    append([TreeA, TreeB], Tree). % is append part of ISO prolog? If not, its source is just a few clauses
% disjunciton
mi_proof_tree((A; _), Tree) :-
    mi_proof_tree(A, Tree).
mi_proof_tree((_; B), Tree) :-
    mi_proof_tree(B, Tree).
% handle built-in predicates
mi_proof_tree(Goal, [State]) :-
    predicate_property(Goal, built_in), % is this prperty part of ISO prolog?
    !,
    call(Goal),
    copy_term(Goal, NewGoal),
    NewGoal = Goal,
    findall((Var, Value), (member(Var, Goal), Var = Value), Substitution),
    State = state{goal:Goal, unification:null, substitution:Substitution, children:[true]}.

% general case
mi_proof_tree(Goal, [State]) :-
    % Goal \= true, %  predicate_property(A, built_in) already filters these, but i don't know if its part of ISO prolog
    % Goal \= (_,_),
    % Goal \= (_\=_), 
    clause(Goal, Body),
    copy_term((Goal, Body), (NewGoal, NewBody)),
    NewGoal = Goal,
    unification_trace(Body, NewBody, Unification),
    mi_proof_tree(Body, Tree),
    findall((Var, Value), (member(Var, Goal), Var = Value), Substitution),
    State = state{goal:Goal,unification:Unification,substitution:Substitution,children:Tree}.

    unification_trace(A, B, []) :- var(A), var(B), !.
unification_trace((A, C), (B, D), [(A, B), (C, D)]) :- !.
unification_trace(A, B, [(A, B)]).






% simply print the proof tree to the terminal
print_proof_tree(A):- 
    mi_proof_tree(A, [Tree]),
    write("Proof tree: "), write(Tree), nl.

prove(A):-
    mi_proof_tree(A,[Tree]),
    json_write(current_output, Tree,[serialize_unknown(true)]).

% print a tree representation of the proof tree to the terminal
print_tree_pretty(Tree):-
    print_tree_pretty(Tree, 0).
print_tree_pretty([true], Indent):-
    tab(Indent),
    write("< "),
    write(true), nl.
print_tree_pretty([state{goal:Goal,unification:U,substitution:S,children:Children}], Indent):- 
    tab(Indent), 
    write( ":> "),
    write(Goal),
    write(" <> "),
    write(U),
    write(" >< "),
    write(S),
    nl,
    NewIndent is Indent + 4,
    print_children_pretty(Children, NewIndent).

print_children_pretty([], _).
print_children_pretty([Child|OtherChildren], Indent):- 
    print_tree_pretty([Child], Indent),
    print_children_pretty(OtherChildren, Indent).



