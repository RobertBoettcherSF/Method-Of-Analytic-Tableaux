with Ada.Text_IO; use Ada.Text_IO;
with Analytic_Tableaux; use Analytic_Tableaux;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   Put_Line ("=== STARTING ANALYTIC TABLEAUX TEST SUITE ===");

   -- TEST 1 — Formula Constructors and Well-Formedness
   Put_Line ("TEST 1 — Formula Constructors and Well-Formedness");
   declare
      V_P : constant Formula := Make_Var ('P');
      T_F : constant Formula := Make_True;
      F_F : constant Formula := Make_False;
   begin
      Check ("1.1 Variable P is well-formed", Is_Well_Formed (V_P));
      Check ("1.2 True constant is well-formed", Is_Well_Formed (T_F));
      Check ("1.3 False constant is well-formed", Is_Well_Formed (F_F));
   end;

   -- TEST 2 — Formula String Representation
   Put_Line ("TEST 2 — Formula String Representation");
   declare
      F1 : constant Formula := Make_Binary (Op_And, Make_Var ('A'), Make_Var ('B'));
      F2 : constant Formula := Make_Not (Make_Var ('C'));
      F3 : constant Formula := Make_Binary (Op_Or, Make_True, Make_False);
   begin
      Check ("2.1 Conjunction string is non-empty", Formula_To_String (F1)'Length > 0);
      Check ("2.2 Negation string is non-empty", Formula_To_String (F2)'Length > 0);
      Check ("2.3 Binary operation string is non-empty", Formula_To_String (F3)'Length > 0);
   end;

   -- TEST 3 — Unsigned Satisfiability: Single Variable
   Put_Line ("TEST 3 — Unsigned Satisfiability: Single Variable");
   declare
      V_A : constant Formula := Make_Var ('A');
   begin
      Check ("3.1 Single variable P is satisfiable", Is_Satisfiable_Unsigned (V_A));
      Check ("3.2 Negation of P is satisfiable", Is_Satisfiable_Unsigned (Make_Not (V_A)));
      Check ("3.3 Well-formedness holds for variable", Is_Well_Formed (V_A));
   end;

   -- TEST 4 — Unsigned Satisfiability: Conjunction
   Put_Line ("TEST 4 — Unsigned Satisfiability: Conjunction");
   declare
      Conj : constant Formula := Make_Binary (Op_And, Make_Var ('A'), Make_Var ('B'));
   begin
      Check ("4.1 Conjunction A & B is satisfiable", Is_Satisfiable_Unsigned (Conj));
      Check ("4.2 Conjunction is well-formed", Is_Well_Formed (Conj));
      Check ("4.3 Sub-formula A is satisfiable", Is_Satisfiable_Unsigned (Make_Var ('A')));
   end;

   -- TEST 5 — Unsigned Satisfiability: Contradiction
   Put_Line ("TEST 5 — Unsigned Satisfiability: Contradiction");
   declare
      Contra : constant Formula := Make_Binary (Op_And, Make_Var ('A'), Make_Not (Make_Var ('A')));
   begin
      Check ("5.1 Contradiction A & ~A is unsatisfiable", not Is_Satisfiable_Unsigned (Contra));
      Check ("5.2 Contradiction formula is well-formed", Is_Well_Formed (Contra));
      Check ("5.3 Negation of contradiction is satisfiable", Is_Satisfiable_Unsigned (Make_Not (Contra)));
   end;

   -- TEST 6 — Unsigned Validity: Law of Excluded Middle (A | ~A)
   Put_Line ("TEST 6 — Unsigned Validity: Law of Excluded Middle");
   declare
      LEM : constant Formula := Make_Binary (Op_Or, Make_Var ('A'), Make_Not (Make_Var ('A')));
   begin
      Check ("6.1 Law of Excluded Middle is valid (unsigned)", Is_Valid_Unsigned (LEM));
      Check ("6.2 LEM formula is well-formed", Is_Well_Formed (LEM));
      Check ("6.3 Negation of LEM is unsatisfiable", not Is_Satisfiable_Unsigned (Make_Not (LEM)));
   end;

   -- TEST 7 — Unsigned Validity: Non-Tautology (A & B)
   Put_Line ("TEST 7 — Unsigned Validity: Non-Tautology");
   declare
      And_Form : constant Formula := Make_Binary (Op_And, Make_Var ('A'), Make_Var ('B'));
   begin
      Check ("7.1 A & B is not a valid tautology", not Is_Valid_Unsigned (And_Form));
      Check ("7.2 A & B is satisfiable", Is_Satisfiable_Unsigned (And_Form));
      Check ("7.3 Well-formed check passes", Is_Well_Formed (And_Form));
   end;

   -- TEST 8 — Signed Satisfiability
   Put_Line ("TEST 8 — Signed Satisfiability");
   declare
      Imply_Form : constant Formula := Make_Binary (Op_Implies, Make_Var ('A'), Make_Var ('B'));
   begin
      Check ("8.1 Implication A -> B is signed-satisfiable", Is_Satisfiable_Signed (Imply_Form));
      Check ("8.2 Implication is well-formed", Is_Well_Formed (Imply_Form));
      Check ("8.3 Negated implication is signed-satisfiable", Is_Satisfiable_Signed (Make_Not (Imply_Form)));
   end;

   -- TEST 9 — Signed Validity: Modus Ponens ((A & (A -> B)) -> B)
   Put_Line ("TEST 9 — Signed Validity: Modus Ponens");
   declare
      MP : constant Formula := Make_Binary (Op_Implies,
                                Make_Binary (Op_And, Make_Var ('A'), Make_Binary (Op_Implies, Make_Var ('A'), Make_Var ('B'))),
                                Make_Var ('B'));
   begin
      Check ("9.1 Modus Ponens is valid (signed)", Is_Valid_Signed (MP));
      Check ("9.2 Modus Ponens is valid (unsigned)", Is_Valid_Unsigned (MP));
      Check ("9.3 Modus Ponens formula is well-formed", Is_Well_Formed (MP));
   end;

   -- TEST 10 — Signed Validity: Non-Valid Formula (A -> B)
   Put_Line ("TEST 10 — Signed Validity: Non-Valid Formula");
   declare
      Impl : constant Formula := Make_Binary (Op_Implies, Make_Var ('A'), Make_Var ('B'));
   begin
      Check ("10.1 A -> B is not valid (signed)", not Is_Valid_Signed (Impl));
      Check ("10.2 A -> B is satisfiable (signed)", Is_Satisfiable_Signed (Impl));
      Check ("10.3 Well-formed check passes", Is_Well_Formed (Impl));
   end;

   -- TEST 11 — Complex Propositional Formula (De Morgan's Equivalence)
   Put_Line ("TEST 11 — Complex Propositional Formula (De Morgan)");
   declare
      Demorgan : constant Formula := Make_Binary (Op_Equiv,
                                     Make_Not (Make_Binary (Op_And, Make_Var ('A'), Make_Var ('B'))),
                                     Make_Binary (Op_Or, Make_Not (Make_Var ('A')), Make_Not (Make_Var ('B'))));
   begin
      Check ("11.1 De Morgan law is valid (unsigned)", Is_Valid_Unsigned (Demorgan));
      Check ("11.2 De Morgan law is valid (signed)", Is_Valid_Signed (Demorgan));
      Check ("11.3 De Morgan formula is well-formed", Is_Well_Formed (Demorgan));
   end;

   -- TEST 12 — Edge Cases and Error Handling (Expected Exceptions)
   Put_Line ("TEST 12 — Edge Cases and Error Handling");
   declare
      Ex_Caught : Boolean := False;
   begin
      begin
         declare
            Bad_Not : constant Formula := Make_Not (null);
         begin
            null;
         end;
      exception
         when Invalid_Formula_Error =>
            Ex_Caught := True;
      end;
      Check ("12.1 Null sub-formula in Make_Not raises Invalid_Formula_Error", Ex_Caught);
      Check ("12.2 Is_Well_Formed returns false for null formula", not Is_Well_Formed (null));
      Check ("12.3 Formula_To_String handles null gracefully", Formula_To_String (null) = "[NULL]");
   end;

   -- TEST 13 — Equivalence and Biconditional Operator
   Put_Line ("TEST 13 — Equivalence and Biconditional Operator");
   begin
      Check ("13.1 A <-> A is valid", Is_Valid_Unsigned (Make_Binary (Op_Equiv, Make_Var ('A'), Make_Var ('A'))));
      Check ("13.2 A <-> A is signed-valid", Is_Valid_Signed (Make_Binary (Op_Equiv, Make_Var ('A'), Make_Var ('A'))));
      Check ("13.3 A <-> A is satisfiable", Is_Satisfiable_Unsigned (Make_Binary (Op_Equiv, Make_Var ('A'), Make_Var ('A'))));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
