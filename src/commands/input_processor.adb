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

with Ada.Text_IO;
with Latin_Utils.Strings_Package; use Latin_Utils.Strings_Package;
with Latin_Utils.Latin_File_Names; use Latin_Utils.Latin_File_Names;
with Support_Utils.Word_Parameters; use Support_Utils.Word_Parameters;
with Latin_Utils.Inflections_Package; use Latin_Utils.Inflections_Package;
with Latin_Utils.Dictionary_Package; use Latin_Utils.Dictionary_Package;
with Support_Utils.Word_Support_Package; use Support_Utils.Word_Support_Package;
with Latin_Utils.Preface;
with Words_Engine.Word_Package; use Words_Engine.Word_Package;
use Latin_Utils;

with Words_Engine.Parse; use Words_Engine.Parse;

pragma Elaborate (Support_Utils.Word_Parameters);

package body Input_Processor is
   -- use Inflections_Package.Integer_IO;
   -- use Inflection_Record_IO;
   use Ada.Text_IO;

   procedure Delete_If_Open (Filename : String;
                             Dict_Name : Dictionary_Kind) is
   begin
      begin
         if Dict_IO.Is_Open (Dict_File (Dict_Name)) then
            Dict_IO.Delete (Dict_File (Dict_Name));
         else
            Dict_IO.Open (Dict_File (Dict_Name), Dict_IO.In_File,
                          Add_File_Name_Extension
                            (Dict_File_Name, Filename));
            Dict_IO.Delete (Dict_File (Dict_Name));
         end if;
      exception when others => null;
      end;   --  not there, so don't have to DELETE
   end Delete_If_Open;

   -- Get and handle a line of Input
   -- return value says whether there is more Input, i.e. False -> quit
   function Get_Input_Line (Configuration : Configuration_Type) return Boolean
   is
      Blank_Line : constant String (1 .. 2500) := (others => ' ');
      Line : String (1 .. 2500) := (others => ' ');
      L : Integer := 0;
   begin
      --  Block to manipulate file of lines
      if Name (Current_Input) = Name (Standard_Input) then
         Scroll_Line_Number :=
           Integer (Ada.Text_IO.Line (Ada.Text_IO.Standard_Output));
         Preface.New_Line;
         Preface.Put ("=>");
      end if;

      Line := Blank_Line;
      Get_Line (Line, L);
      if (L = 0) or else (Trim (Line (1 .. L)) = "")  then
         --  INPUT is file

         --LINE_NUMBER := LINE_NUMBER + 1;
         --  Count blank lines in file
         if End_Of_File (Current_Input) then
            Set_Input (Standard_Input);
            Close (Input);
         end if;
      end if;

      if Trim (Line (1 .. L)) /= "" then
         -- Not a blank line so L (1) (in file Input)
         Preface.New_Line;
         Preface.Put_Line (Line (1 .. L));

         if Words_Mode (Write_Output_To_File)     then
            if not Config.Suppress_Preface     then
               New_Line (Output);
               Ada.Text_IO.Put_Line (Output, Line (1 .. L));
            end if;
         end if;
         --  Count lines to be parsed
         Line_Number := Line_Number + 1;

         Words_Engine.Parse.Parse_Line (Configuration, Line (1 .. L));
      end if;

      return True;

   exception
      when End_Error =>
         raise Give_Up;
      when Status_Error =>
         --  The end of the Input file resets to CON:
         Put_Line ("Raised STATUS_ERROR");
         return False;
   end Get_Input_Line;

   procedure Process_Input (Configuration : Configuration_Type) is
   begin
      while Get_Input_Line (Configuration) loop
         null;
      end loop;

      begin
         Stem_Io.Open (Stem_File (Local), Stem_Io.In_File,
                       Add_File_Name_Extension (Stem_File_Name,
                         "LOCAL"));
         --  Failure to OPEN will raise an exception, to be handled below
         if Stem_Io.Is_Open (Stem_File (Local)) then
            Stem_Io.Delete (Stem_File (Local));
         end if;
      exception
         when others =>
            null;      --  If cannot OPEN then it does not exist, so is deleted
      end;
      --  The rest of this might be overkill, it might have been done elsewhere

      Delete_If_Open ("LOCAL", Local);
      Delete_If_Open ("ADDONS", Addons);
      Delete_If_Open ("UNIQUE", Unique);

   exception
      when Storage_Error  =>    --  Have tried at least twice, fail
         Preface.Put_Line ("Continuing STORAGE_ERROR Exception in PARSE");
         Preface.Put_Line ("If insufficient memory in DOS, try removing TSRs");
      when Give_Up  =>
         Preface.Put_Line ("Giving up!");
      when others  =>
         Preface.Put_Line ("Unexpected exception raised in PARSE");
   end Process_Input;

end Input_Processor;
