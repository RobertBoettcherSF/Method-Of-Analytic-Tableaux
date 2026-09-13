with Ada.Containers.Vectors;
with Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body Analytic_Tableaux is

   -- Vector containers for formulas and branches
   package Formula_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Formula);

   type Signed_Formula is record
      Sign : Sign_Kind;
      Form : Formula;
   end record;

   package Signed_Formula_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Signed_Formula);

   -- Free memory helper to prevent leaks
   procedure Free_Formula is new Ada.Unchecked_Deallocation
     (Formula_Rec, Formula);

   ---------------------------------------------------------------------------
   -- Constructors
   ---------------------------------------------------------------------------

   function Make_Var (Name : Character) return Formula is
   begin
      return new Formula_Rec'(Kind => Op_Var, Var_Name => Name);
   end Make_Var;

   function Make_True return Formula is
   begin
      return new Formula_Rec'(Kind => Op_True);
   end Make_True;

   function Make_False return Formula is
   begin
      return new Formula_Rec'(Kind => Op_False);
   end Make_False;

   function Make_Not (Sub : Formula) return Formula is
   begin
      if Sub = null then
         raise Invalid_Formula_Error with "Null sub-formula in Make_Not";
      end if;
      return new Formula_Rec'(Kind => Op_Not, Sub_Formula => Sub);
   end Make_Not;

   function Make_Binary (Op : Operator_Kind; Left, Right : Formula) return Formula is
   begin
      if Left = null or else Right = null then
         raise Invalid_Formula_Error with "Null operand in binary formula constructor";
      end if;
      return new Formula_Rec'(Kind => Op, Left => Left, Right => Right);
   end Make_Binary;

   ---------------------------------------------------------------------------
   -- Validation & String Conversion
   ---------------------------------------------------------------------------

   function Is_Well_Formed (F : Formula) return Boolean is
   begin
      if F = null then
         return False;
      end if;
      case F.Kind is
         when Op_Var =>
            return F.Var_Name in 'A' .. 'Z' or F.Var_Name in 'a' .. 'z';
         when Op_True | Op_False =>
            return True;
         when Op_Not =>
            return F.Sub_Formula /= null and then Is_Well_Formed (F.Sub_Formula);
         when Op_And | Op_Or | Op_Implies | Op_Equiv =>
            return F.Left /= null and then F.Right /= null
              and then Is_Well_Formed (F.Left)
              and then Is_Well_Formed (F.Right);
      end case;
   end Is_Well_Formed;

   function Formula_To_String (F : Formula) return String is
   begin
      if F = null then
         return "[NULL]";
      end if;
      case F.Kind is
         when Op_Var =>
            return "" & F.Var_Name;
         when Op_True =>
            return "TRUE";
         when Op_False =>
            return "FALSE";
         when Op_Not =>
            return "(~" & Formula_To_String (F.Sub_Formula) & ")";
         when Op_And =>
            return "(" & Formula_To_String (F.Left) & " & " & Formula_To_String (F.Right) & ")";
         when Op_Or =>
            return "(" & Formula_To_String (F.Left) & " | " & Formula_To_String (F.Right) & ")";
         when Op_Implies =>
            return "(" & Formula_To_String (F.Left) & " -> " & Formula_To_String (F.Right) & ")";
         when Op_Equiv =>
            return "(" & Formula_To_String (F.Left) & " <-> " & Formula_To_String (F.Right) & ")";
      end case;
   end Formula_To_String;

   ---------------------------------------------------------------------------
   -- Structural Equality Helper
   ---------------------------------------------------------------------------
   function Formulas_Equal (F1, F2 : Formula) return Boolean is
   begin
      if F1 = F2 then
         return True;
      end if;
      if F1 = null or else F2 = null then
         return False;
      end if;
      if F1.Kind /= F2.Kind then
         return False;
      end if;
      case F1.Kind is
         when Op_Var =>
            return F1.Var_Name = F2.Var_Name;
         when Op_True | Op_False =>
            return True;
         when Op_Not =>
            return Formulas_Equal (F1.Sub_Formula, F2.Sub_Formula);
         when Op_And | Op_Or | Op_Implies | Op_Equiv =>
            return Formulas_Equal (F1.Left, F2.Left) and then Formulas_Equal (F1.Right, F2.Right);
      end case;
   end Formulas_Equal;

   ---------------------------------------------------------------------------
   -- Unsigned Tableau Engine
   ---------------------------------------------------------------------------
   function Is_Branch_Closed_Unsigned (Branch : Formula_Vectors.Vector) return Boolean is
   begin
      for I in 1 .. Branch.Last_Index loop
         declare
            Fi : constant Formula := Branch.Element (I);
         begin
            if Fi.Kind = Op_False then
               return True;
            end if;
            for J in I + 1 .. Branch.Last_Index loop
               declare
                  Fj : constant Formula := Branch.Element (J);
               begin
                  if Fj.Kind = Op_False then
                     return True;
                  end if;
                  if Fi.Kind = Op_Not and then Formulas_Equal (Fi.Sub_Formula, Fj) then
                     return True;
                  end if;
                  if Fj.Kind = Op_Not and then Formulas_Equal (Fj.Sub_Formula, Fi) then
                     return True;
                  end if;
               end;
            end loop;
         end;
      end loop;
      return False;
   end Is_Branch_Closed_Unsigned;

   function Expand_Tableau_Unsigned (Branch : Formula_Vectors.Vector) return Boolean is
   begin
      if Is_Branch_Closed_Unsigned (Branch) then
         return False;
      end if;

      -- Alpha rules (non-branching expansions)
      for I in 1 .. Branch.Last_Index loop
         declare
            Fi : constant Formula := Branch.Element (I);
         begin
            -- Double Negation: ~~A -> A
            if Fi.Kind = Op_Not and then Fi.Sub_Formula.Kind = Op_Not then
               declare
                  New_Branch : Formula_Vectors.Vector := Branch;
               begin
                  New_Branch.Append (Fi.Sub_Formula.Sub_Formula);
                  return Expand_Tableau_Unsigned (New_Branch);
               end;
            end if;

            -- Conjunction: A & B -> A, B
            if Fi.Kind = Op_And then
               declare
                  New_Branch : Formula_Vectors.Vector := Branch;
               begin
                  New_Branch.Append (Fi.Left);
                  New_Branch.Append (Fi.Right);
                  return Expand_Tableau_Unsigned (New_Branch);
               end;
            end if;

            -- Negated Disjunction: ~(A | B) -> ~A, ~B
            if Fi.Kind = Op_Not and then Fi.Sub_Formula.Kind = Op_Or then
               declare
                  New_Branch : Formula_Vectors.Vector := Branch;
               begin
                  New_Branch.Append (Make_Not (Fi.Sub_Formula.Left));
                  New_Branch.Append (Make_Not (Fi.Sub_Formula.Right));
                  return Expand_Tableau_Unsigned (New_Branch);
               end;
            end if;

            -- Negated Implication: ~(A -> B) -> A, ~B
            if Fi.Kind = Op_Not and then Fi.Sub_Formula.Kind = Op_Implies then
               declare
                  New_Branch : Formula_Vectors.Vector := Branch;
               begin
                  New_Branch.Append (Fi.Sub_Formula.Left);
                  New_Branch.Append (Make_Not (Fi.Sub_Formula.Right));
                  return Expand_Tableau_Unsigned (New_Branch);
               end;
            end if;
         end;
      end loop;

      -- Beta rules (branching expansions)
      for I in 1 .. Branch.Last_Index loop
         declare
            Fi : constant Formula := Branch.Element (I);
         begin
            -- Disjunction: A | B -> branch1: A | branch2: B
            if Fi.Kind = Op_Or then
               declare
                  Branch1 : Formula_Vectors.Vector := Branch;
                  Branch2 : Formula_Vectors.Vector := Branch;
               begin
                  Branch1.Append (Fi.Left);
                  Branch2.Append (Fi.Right);
                  return Expand_Tableau_Unsigned (Branch1) or else Expand_Tableau_Unsigned (Branch2);
               end;
            end if;

            -- Implication: A -> B -> branch1: ~A | branch2: B
            if Fi.Kind = Op_Implies then
               declare
                  Branch1 : Formula_Vectors.Vector := Branch;
                  Branch2 : Formula_Vectors.Vector := Branch;
               begin
                  Branch1.Append (Make_Not (Fi.Left));
                  Branch2.Append (Fi.Right);
                  return Expand_Tableau_Unsigned (Branch1) or else Expand_Tableau_Unsigned (Branch2);
               end;
            end if;

            -- Negated Conjunction: ~(A & B) -> branch1: ~A | branch2: ~B
            if Fi.Kind = Op_Not and then Fi.Sub_Formula.Kind = Op_And then
               declare
                  Branch1 : Formula_Vectors.Vector := Branch;
                  Branch2 : Formula_Vectors.Vector := Branch;
               begin
                  Branch1.Append (Make_Not (Fi.Sub_Formula.Left));
                  Branch2.Append (Make_Not (Fi.Sub_Formula.Right));
                  return Expand_Tableau_Unsigned (Branch1) or else Expand_Tableau_Unsigned (Branch2);
               end;
            end if;

            -- Equivalence: A <-> B -> (A & B) | (~A & ~B)
            if Fi.Kind = Op_Equiv then
               declare
                  Branch1 : Formula_Vectors.Vector := Branch;
                  Branch2 : Formula_Vectors.Vector := Branch;
               begin
                  Branch1.Append (Fi.Left);
                  Branch1.Append (Fi.Right);
                  Branch2.Append (Make_Not (Fi.Left));
                  Branch2.Append (Make_Not (Fi.Right));
                  return Expand_Tableau_Unsigned (Branch1) or else Expand_Tableau_Unsigned (Branch2);
               end;
            end if;

            -- Negated Equivalence: ~(A <-> B) -> (A & ~B) | (~A & B)
            if Fi.Kind = Op_Not and then Fi.Sub_Formula.Kind = Op_Equiv then
               declare
                  Branch1 : Formula_Vectors.Vector := Branch;
                  Branch2 : Formula_Vectors.Vector := Branch;
               begin
                  Branch1.Append (Fi.Sub_Formula.Left);
                  Branch1.Append (Make_Not (Fi.Sub_Formula.Right));
                  Branch2.Append (Make_Not (Fi.Sub_Formula.Left));
                  Branch2.Append (Fi.Sub_Formula.Right);
                  return Expand_Tableau_Unsigned (Branch1) or else Expand_Tableau_Unsigned (Branch2);
               end;
            end if;
         end;
      end loop;

      return True;
   end Expand_Tableau_Unsigned;

   function Is_Satisfiable_Unsigned (F : Formula) return Boolean is
      Initial_Branch : Formula_Vectors.Vector;
   begin
      Initial_Branch.Append (F);
      return Expand_Tableau_Unsigned (Initial_Branch);
   end Is_Satisfiable_Unsigned;

   function Is_Valid_Unsigned (F : Formula) return Boolean is
   begin
      return not Is_Satisfiable_Unsigned (Make_Not (F));
   end Is_Valid_Unsigned;

   ---------------------------------------------------------------------------
   -- Signed Tableau Engine
   ---------------------------------------------------------------------------
   function Is_Branch_Closed_Signed (Branch : Signed_Formula_Vectors.Vector) return Boolean is
   begin
      for I in 1 .. Branch.Last_Index loop
         declare
            Si : constant Signed_Formula := Branch.Element (I);
         begin
            for J in I + 1 .. Branch.Last_Index loop
               declare
                  Sj : constant Signed_Formula := Branch.Element (J);
               begin
                  if Formulas_Equal (Si.Form, Sj.Form) and then Si.Sign /= Sj.Sign then
                     return True;
                  end if;
               end;
            end loop;
         end;
      end loop;
      return False;
   end Is_Branch_Closed_Signed;

   function Expand_Tableau_Signed (Branch : Signed_Formula_Vectors.Vector) return Boolean is
   begin
      if Is_Branch_Closed_Signed (Branch) then
         return False;
      end if;

      for I in 1 .. Branch.Last_Index loop
         declare
            Sf : constant Signed_Formula := Branch.Element (I);
            F  : constant Formula := Sf.Form;
         begin
            if Sf.Sign = Sign_True then
               if F.Kind = Op_Not then
                  declare
                     New_Branch : Signed_Formula_Vectors.Vector := Branch;
                  begin
                     New_Branch.Append (Signed_Formula'(Sign => Sign_False, Form => F.Sub_Formula));
                     return Expand_Tableau_Signed (New_Branch);
                  end;
               elsif F.Kind = Op_And then
                  declare
                     New_Branch : Signed_Formula_Vectors.Vector := Branch;
                  begin
                     New_Branch.Append (Signed_Formula'(Sign => Sign_True, Form => F.Left));
                     New_Branch.Append (Signed_Formula'(Sign => Sign_True, Form => F.Right));
                     return Expand_Tableau_Signed (New_Branch);
                  end;
               elsif F.Kind = Op_Or then
                  declare
                     Branch1 : Signed_Formula_Vectors.Vector := Branch;
                     Branch2 : Signed_Formula_Vectors.Vector := Branch;
                  begin
                     Branch1.Append (Signed_Formula'(Sign => Sign_True, Form => F.Left));
                     Branch2.Append (Signed_Formula'(Sign => Sign_True, Form => F.Right));
                     return Expand_Tableau_Signed (Branch1) or else Expand_Tableau_Signed (Branch2);
                  end;
               elsif F.Kind = Op_Implies then
                  declare
                     Branch1 : Signed_Formula_Vectors.Vector := Branch;
                     Branch2 : Signed_Formula_Vectors.Vector := Branch;
                  begin
                     Branch1.Append (Signed_Formula'(Sign => Sign_False, Form => F.Left));
                     Branch2.Append (Signed_Formula'(Sign => Sign_True, Form => F.Right));
                     return Expand_Tableau_Signed (Branch1) or else Expand_Tableau_Signed (Branch2);
                  end;
               end if;
            else
               if F.Kind = Op_Not then
                  declare
                     New_Branch : Signed_Formula_Vectors.Vector := Branch;
                  begin
                     New_Branch.Append (Signed_Formula'(Sign => Sign_True, Form => F.Sub_Formula));
                     return Expand_Tableau_Signed (New_Branch);
                  end;
               elsif F.Kind = Op_And then
                  declare
                     Branch1 : Signed_Formula_Vectors.Vector := Branch;
                     Branch2 : Signed_Formula_Vectors.Vector := Branch;
                  begin
                     Branch1.Append (Signed_Formula'(Sign => Sign_False, Form => F.Left));
                     Branch2.Append (Signed_Formula'(Sign => Sign_False, Form => F.Right));
                     return Expand_Tableau_Signed (Branch1) or else Expand_Tableau_Signed (Branch2);
                  end;
               elsif F.Kind = Op_Or then
                  declare
                     New_Branch : Signed_Formula_Vectors.Vector := Branch;
                  begin
                     New_Branch.Append (Signed_Formula'(Sign => Sign_False, Form => F.Left));
                     New_Branch.Append (Signed_Formula'(Sign => Sign_False, Form => F.Right));
                     return Expand_Tableau_Signed (New_Branch);
                  end;
               elsif F.Kind = Op_Implies then
                  declare
                     New_Branch : Signed_Formula_Vectors.Vector := Branch;
                  begin
                     New_Branch.Append (Signed_Formula'(Sign => Sign_True, Form => F.Left));
                     New_Branch.Append (Signed_Formula'(Sign => Sign_False, Form => F.Right));
                     return Expand_Tableau_Signed (New_Branch);
                  end;
               end if;
            end if;
         end;
      end loop;

      return True;
   end Expand_Tableau_Signed;

   function Is_Satisfiable_Signed (F : Formula) return Boolean is
      Initial_Branch : Signed_Formula_Vectors.Vector;
   begin
      Initial_Branch.Append (Signed_Formula'(Sign => Sign_True, Form => F));
      return Expand_Tableau_Signed (Initial_Branch);
   end Is_Satisfiable_Signed;

   function Is_Valid_Signed (F : Formula) return Boolean is
      Initial_Branch : Signed_Formula_Vectors.Vector;
   begin
      Initial_Branch.Append (Signed_Formula'(Sign => Sign_False, Form => F));
      return not Expand_Tableau_Signed (Initial_Branch);
   end Is_Valid_Signed;

end Analytic_Tableaux;
