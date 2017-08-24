-- WORDS, a Latin dictionary, by Colonel William Whitaker (USAF, Retired)
--
-- Copyright William A. Whitaker (1936–2010)
--
-- This is a free program, which means it is proper to copy it and pass
-- it on to your friends. Consider it a developmental item for which
-- there is no charge. However, just for form, it is Copyrighted
-- (c). Permission is hereby freely given for any and all use of program
-- and data. You can sell it as your own, but at least tell me.
--
-- This version is distributed without obligation, but the developer
-- would appreciate comments and suggestions.
--
-- All parts of the WORDS system, source code and data files, are made freely
-- available to anyone who wishes to use them, for whatever purpose.

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Latin_Utils.Strings_Package; use Latin_Utils.Strings_Package;
use Latin_Utils;
with Latin_Utils.Config; use Latin_Utils.Config;
with Support_Utils.Word_Parameters; use Support_Utils.Word_Parameters;
with Words_Engine.Initialization;
with Input_Processor;
with Ada.Exceptions; use Ada;

procedure Words_Main (Configuration : Configuration_Type) is
   Argument_Error : exception;

begin
   Suppress_Preface := True;
   Words_Engine.Initialization.Initialize_Engine;

   if 1 <= Ada.Command_Line.Argument_Count
     and Ada.Command_Line.Argument_Count < 3
   then
      At_Least_One_Argument :
      declare
         Input_Name : constant String := Trim (Ada.Command_Line.Argument (1));
         --Single parameter: an Input file.
         --WORDS infile
      begin
         --  Try file name, not raises NAME_ERROR
         Open (Input, In_File, Input_Name);
         Method := Command_Line_Files;
         Set_Input (Input);

         if Ada.Command_Line.Argument_Count = 1  then
            One_Argument :
            begin
               Set_Output (Ada.Text_IO.Standard_Output);
               Input_Processor.Process_Input (Configuration);
            end One_Argument;

         --With two Arguments the options are: Inputfile and Outputfile,
         --WORDS infile outfile
         elsif Ada.Command_Line.Argument_Count = 2 then -- INPUT and OUTPUT
            Two_Arguments :
            declare
               Output_Name : constant String :=
                 Trim (Ada.Command_Line.Argument (2));
            begin
               Create (Output, Out_File, Output_Name);
               Set_Output (Output);

               Output_Screen_Size := Integer'Last;
               --  No additional Arguments, so just go to PARSE now
               Input_Processor.Process_Input (Configuration);

               Close (Output);
            exception                            --  Triggers on OUTPUT  !!!
               when NE : Name_Error  =>          --  Raised NAME_ERROR therefore
                  Ada.Text_IO.Put_Line
                    (Ada.Text_IO.Standard_Error,
                     Ada.Exceptions.Exception_Message (NE));

            end Two_Arguments;
         end if;

      exception                  --  Triggers on INPUT
         when NE : Name_Error  =>          --  Raised NAME_ERROR therefore
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               Ada.Exceptions.Exception_Message (NE));
      end At_Least_One_Argument;

   elsif Ada.Command_Line.Argument_Count = 0 then
      Set_Input (Ada.Text_IO.Standard_Input);
      Set_Output (Ada.Text_IO.Standard_Output);
      Input_Processor.Process_Input (Configuration);

   else    --  More than three Arguments
         Exceptions.Raise_Exception
           (Argument_Error'Identity, "Too many arguments");
   end if;
end Words_Main;
