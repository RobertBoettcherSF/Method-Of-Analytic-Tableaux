-------------------------------------------------------------------------------
-- Package: Analytic_Tableaux
-- Description: Implementation of the Method of Analytic Tableaux for 
--              Propositional Logic (supporting Unsigned and Signed tableaux,
--              Satisfiability, and Validity checking).
-- Ada Version: Ada 2023 (ISO/IEC 8652:2023)
-------------------------------------------------------------------------------

package Analytic_Tableaux is

   -- Custom domain types (Strong Typing)
   type Operator_Kind is (
      Op_Var,
      Op_Not,
      Op_And,
      Op_Or,
      Op_Implies,
      Op_Equiv,
      Op_True,
      Op_False
   );

   type Sign_Kind is (Sign_True, Sign_False);

   type Formula_Rec;
   type Formula is access all Formula_Rec;

   type Formula_Rec (Kind : Operator_Kind) is record
      case Kind is
         when Op_Var =>
            Var_Name : Character;
         when Op_Not =>
            Sub_Formula : Formula;
         when Op_And | Op_Or | Op_Implies | Op_Equiv =>
            Left  : Formula;
            Right : Formula;
         when Op_True | Op_False =>
            null;
      end case;
   end record;

   -- Exceptions
   Invalid_Formula_Error : exception;
   Tableau_Error         : exception;

   -- Formula Constructor Helpers
   function Make_Var (Name : Character) return Formula
     with Pre  => Name in 'A' .. 'Z' or Name in 'a' .. 'z',
          Post => Make_Var'Result /= null;

   function Make_True return Formula
     with Post => Make_True'Result /= null;

   function Make_False return Formula
     with Post => Make_False'Result /= null;

   function Make_Not (Sub : Formula) return Formula
     with Pre  => Sub /= null,
          Post => Make_Not'Result /= null;

   function Make_Binary (Op : Operator_Kind; Left, Right : Formula) return Formula
     with Pre  => Op in Op_And | Op_Or | Op_Implies | Op_Equiv and then Left /= null and then Right /= null,
          Post => Make_Binary'Result /= null;

   -- Utility / Validation functions
   function Is_Well_Formed (F : Formula) return Boolean;
   function Formula_To_String (F : Formula) return String
     with Pre => F /= null;

   -- Core Tableau Variants
   
   -- 1. Unsigned Satisfiability Tableau
   function Is_Satisfiable_Unsigned (F : Formula) return Boolean
     with Pre => F /= null and then Is_Well_Formed (F);

   -- 2. Unsigned Validity Tableau (checks if F is valid by testing unsatisfiability of not F)
   function Is_Valid_Unsigned (F : Formula) return Boolean
     with Pre => F /= null and then Is_Well_Formed (F);

   -- 3. Signed Satisfiability Tableau (using T/F signed formulas)
   function Is_Satisfiable_Signed (F : Formula) return Boolean
     with Pre => F /= null and then Is_Well_Formed (F);

   -- 4. Signed Validity Tableau
   function Is_Valid_Signed (F : Formula) return Boolean
     with Pre => F /= null and then Is_Well_Formed (F);

end Analytic_Tableaux;
