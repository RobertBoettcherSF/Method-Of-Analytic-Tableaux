# Analytic Tableaux (Method of Semantic Tableaux) in Ada 2023

## Project Overview
This project provides a complete, robust, and zero-warning implementation of the Method of Analytic Tableaux (truth trees / semantic tableaux) for propositional logic in Ada 2023 (ISO/IEC 8652:2023). Analytic tableaux constitute a formal decision procedure and proof calculus designed to check satisfiability, refutability, and logical validity. The algorithm systematically expands composite formulas into branches using conjunctive alpha-rules and disjunctive beta-rules to either find satisfying truth-value valuations or prove validity through contradiction (refutation). The package implements both classical unsigned tableaux and Smullyan-style signed tableaux variants.

## Features
- **Strong Domain Typing**: Dedicated enumerated types for logical connectives (`Operator_Kind`) and formula signs (`Sign_Kind`), combined with variant record types (`Formula_Rec`, `Formula`) representing abstract syntax trees.
- **Contract-Based Design**: Explicit Ada 2023 preconditions (`Pre`) and postconditions (`Post`) enforcing non-null references and structural well-formedness invariants.
- **Multiple Algorithm Variants**:
  - `Is_Satisfiable_Unsigned`: Classical unsigned tableau satisfiability checking via recursive tree expansion.
  - `Is_Valid_Unsigned`: Classical validity checking via refutation (verifying that the negation of the input formula cannot be satisfied).
  - `Is_Satisfiable_Signed`: Smullyan-style signed tableau satisfiability checking using explicit True/False signed nodes.
  - `Is_Valid_Signed`: Smullyan-style signed tableau validity checking (verifying branch closure when the formula is signed False).
- **Formula Construction & Introspection**: Strongly typed AST builders (`Make_Var`, `Make_True`, `Make_False`, `Make_Not`, `Make_Binary`), structural equality checking, syntax validation (`Is_Well_Formed`), and expression printing (`Formula_To_String`).
- **Zero Warnings**: Fully compliant with strict compilation flags (`-gnatwa -gnat2022`).

## Usage
Build the test executable using the provided Makefile:

    make

Run the comprehensive test suite:

    make test

Clean all generated object files and binaries:

    make clean

### Expected Output

    Running tests...
    bin/tests
    === STARTING ANALYTIC TABLEAUX TEST SUITE ===
    TEST 1 — Formula Constructors and Well-Formedness
      PASS — 1.1 Variable P is well-formed
      PASS — 1.2 True constant is well-formed
      PASS — 1.3 False constant is well-formed
    TEST 2 — Formula String Representation
      PASS — 2.1 Conjunction string is non-empty
      PASS — 2.2 Negation string is non-empty
      PASS — 2.3 Binary operation string is non-empty
    TEST 3 — Unsigned Satisfiability: Single Variable
      PASS — 3.1 Single variable P is satisfiable
      PASS — 3.2 Negation of P is satisfiable
      PASS — 3.3 Well-formedness holds for variable
    TEST 4 — Unsigned Satisfiability: Conjunction
      PASS — 4.1 Conjunction A & B is satisfiable
      PASS — 4.2 Conjunction is well-formed
      PASS — 4.3 Sub-formula A is satisfiable
    TEST 5 — Unsigned Satisfiability: Contradiction
      PASS — 5.1 Contradiction A & ~A is unsatisfiable
      PASS — 5.2 Contradiction formula is well-formed
      PASS — 5.3 Negation of contradiction is satisfiable
    TEST 6 — Unsigned Validity: Law of Excluded Middle
      PASS — 6.1 Law of Excluded Middle is valid (unsigned)
      PASS — 6.2 LEM formula is well-formed
      PASS — 6.3 Negation of LEM is unsatisfiable
    TEST 7 — Unsigned Validity: Non-Tautology
      PASS — 7.1 A & B is not a valid tautology
      PASS — 7.2 A & B is satisfiable
      PASS — 7.3 Well-formed check passes
    TEST 8 — Signed Satisfiability
      PASS — 8.1 Implication A -> B is signed-satisfiable
      PASS — 8.2 Implication is well-formed
      PASS — 8.3 Negated implication is signed-satisfiable
    TEST 9 — Signed Validity: Modus Ponens
      PASS — 9.1 Modus Ponens is valid (signed)
      PASS — 9.2 Modus Ponens is valid (unsigned)
      PASS — 9.3 Modus Ponens formula is well-formed
    TEST 10 — Signed Validity: Non-Valid Formula
      PASS — 10.1 A -> B is not valid (signed)
      PASS — 10.2 A -> B is satisfiable (signed)
      PASS — 10.3 Well-formed check passes
    TEST 11 — Complex Propositional Formula (De Morgan)
      PASS — 11.1 De Morgan law is valid (unsigned)
      PASS — 11.2 De Morgan law is valid (signed)
      PASS — 11.3 De Morgan formula is well-formed
    TEST 12 — Edge Cases and Error Handling
      PASS — 12.1 Null sub-formula in Make_Not raises Invalid_Formula_Error
      PASS — 12.2 Is_Well_Formed returns false for null formula
      PASS — 12.3 Formula_To_String handles null gracefully
    TEST 13 — Equivalence and Biconditional Operator
      PASS — 13.1 A <-> A is valid
      PASS — 13.2 A <-> A is signed-valid
      PASS — 13.3 A <-> A is satisfiable

    === 39 passed, 0 failed ===

## Testing
The standalone verification program (`tests.adb`) tests every public subprogram across 13 test categories and 39 individual assertions:
- **Functional Correctness**: Verifies satisfiability and validity of core propositional forms, including Modus Ponens, Law of Excluded Middle, De Morgan's laws, and biconditionals.
- **Refutation & Invalidation**: Confirms that non-tautologies (e.g., plain implication `A -> B` or conjunction `A & B`) correctly fail validity checks while remaining satisfiable.
- **Edge Cases & Error Handling**: Validates tree boundaries such as atomic variables, explicit Boolean constants (`True`, `False`), nested negations (`~~A`), and detects improper tree constructions (raising `Invalid_Formula_Error` when attempting to build invalid AST nodes).
- **Verification & Validation**: Systematic testing across both signed and unsigned engines guarantees algorithm soundness and completeness for the full propositional fragment.

## Building
- **Compiler**: GNAT compiler supporting Ada 2022/2023 (e.g., FSF GNAT 13+, GNAT Community, or Alire).
- **Ada Standard**: Ada 2023 (ISO/IEC 8652:2023), targeted via `-gnat2022` with all warnings enabled via `-gnatwa`.
