with ARM_Output,
     ARM_Contents,
     Ada.Text_IO,
     Ada.Exceptions,
     Ada.Strings.Fixed,
     Ada.Strings.Maps;
package body ARM_Corr is

    --
    -- Ada reference manual formatter (ARM_Form).
    --
    -- This package defines the text output object.
    -- Output objects are responsible for implementing the details of
    -- a particular format.
    --
    -- ---------------------------------------
    -- Copyright 2000, 2002, 2004, 2005, 2006, 2007, 2011, 2012
    --   AXE Consultants. All rights reserved.
    -- P.O. Box 1512, Madison WI  53701
    -- E-Mail: randy@rrsoftware.com
    --
    -- ARM_Form is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU General Public License version 3
    -- as published by the Free Software Foundation.
    --
    -- AXE CONSULTANTS MAKES THIS TOOL AND SOURCE CODE AVAILABLE ON AN "AS IS"
    -- BASIS AND MAKES NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE ACCURACY,
    -- CAPABILITY, EFFICIENCY, MERCHANTABILITY, OR FUNCTIONING OF THIS TOOL.
    -- IN NO EVENT WILL AXE CONSULTANTS BE LIABLE FOR ANY GENERAL,
    -- CONSEQUENTIAL, INDIRECT, INCIDENTAL, EXEMPLARY, OR SPECIAL DAMAGES,
    -- EVEN IF AXE CONSULTANTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
    -- DAMAGES.
    --
    -- A copy of the GNU General Public License is available in the file
    -- gpl-3-0.txt in the standard distribution of the ARM_Form tool.
    -- Otherwise, see <http://www.gnu.org/licenses/>.
    --
    -- If the GPLv3 license is not satisfactory for your needs, a commercial
    -- use license is available for this tool. Contact Randy at AXE Consultants
    -- for more information.
    --
    -- ---------------------------------------
    --
    -- Edit History:
    --
    --  6/ 2/05 - RLB - Created package from text and HTML versions.
    --  1/11/06 - RLB - Eliminated dispatching Create in favor of tailored
    --			versions.
    --  1/18/06 - RLB - Added additional styles.
    --  2/ 8/06 - RLB - Added additional parameters to the table command.
    --  2/10/06 - RLB - Added even more additional parameters to the
    --			table command.
    --		- RLB - Added picture command.
    --  9/22/06 - RLB - Added missing with.
    --  9/25/06 - RLB - Handled optional renaming of TOC.
    --		- RLB - Added Last_Column_Width to Start_Table.
    -- 10/13/06 - RLB - Added Local_Link_Start and Local_Link_End to allow
    --			formatting in the linked text.
    --  2/ 9/07 - RLB - Changed comments on AI_Reference.
    --  2/13/07 - RLB - Revised to separate style and indent information
    --			for paragraphs.
    -- 12/18/07 - RLB - Added Plain_Annex.
    -- 12/19/07 - RLB - Added limited colors to Text_Format.
    -- 10/18/11 - RLB - Changed to GPLv3 license.
    -- 10/25/11 - RLB - Added old insertion version to Revised_Clause_Header.
    --  8/31/12 - RLB - Added Output_Path.
    -- 10/18/12 - RLB - Added additional hanging styles.
    -- 11/26/12 - RLB - Added subdivision names to Clause_Header and
    --			Revised_Clause_Header.

    LINE_LENGTH : constant := 78;
	-- Maximum intended line length.

    Special_Set : constant Ada.Strings.Maps.Character_Set :=
         Ada.Strings.Maps."or" (Ada.Strings.Maps.To_Set ('>'),
           Ada.Strings.Maps.To_Set ('@'));

    procedure Create (Output_Object : in out Corr_Output_Type;
		      File_Prefix : in String;
		      Output_Path : in String;
		      Title : in String := "") is
	-- Create an Output_Object for a document.
	-- The prefix of the output file names is File_Prefix - this
	-- should be no more then 5 characters allowed in file names.
	-- The result files will be written to Output_Path.
	-- The title of the document is Title.
    begin
	if Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Already valid object");
	end if;
	Output_Object.Is_Valid := True;
	Ada.Strings.Fixed.Move (Target => Output_Object.File_Prefix,
				Source => File_Prefix);
	Ada.Strings.Fixed.Move (Target => Output_Object.Output_Path,
				Source => Output_Path);
        Output_Object.Output_Path_Len := Output_Path'Length;
	-- We don't use the title.
    end Create;


    procedure Close (Output_Object : in out Corr_Output_Type) is
	-- Close an Output_Object. No further output to the object is
	-- allowed after this call.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Ada.Text_IO.Is_Open (Output_Object.Output_File) then
	    Ada.Text_IO.Close (Output_Object.Output_File);
	end if;
	Output_Object.Is_Valid := False;
    end Close;


    procedure Section (Output_Object : in out Corr_Output_Type;
		       Section_Title : in String;
		       Section_Name : in String) is
	-- Start a new section. The title is Section_Title (this is
	-- intended for humans). The name is Section_Name (this is
	-- intended to be suitable to be a portion of a file name).
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Section in paragraph");
	end if;
	if Ada.Text_IO.Is_Open (Output_Object.Output_File) then
	    Ada.Text_IO.Close (Output_Object.Output_File);
	end if;
	-- Create a new file for this section:
	Ada.Text_IO.Create (Output_Object.Output_File, Ada.Text_IO.Out_File,
            Output_Object.Output_Path(1..Output_Object.Output_Path_Len) &
	        Ada.Strings.Fixed.Trim (Output_Object.File_Prefix, Ada.Strings.Right) &
		"-Corr-" & Section_Name & ".TXT");
	Ada.Text_IO.New_Line (Output_Object.Output_File);
    end Section;


    procedure Set_Columns (Output_Object : in out Corr_Output_Type;
			   Number_of_Columns : in ARM_Output.Column_Count) is
	-- Set the number of columns.
	-- Raises Not_Valid_Error if in a paragraph.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"In paragraph");
	end if;
	-- No columns in text format.
    end Set_Columns;


    procedure Make_Indent (Output_Object : in out Corr_Output_Type) is
	-- Internal:
	-- Output the appropriate indent after a New_Line or Put_Line.
    begin
--Ada.Text_IO.Put_Line("Make_Indent: Amount=" & Natural'Image(Output_Object.Indent_Amount));
        for I in 1 .. Output_Object.Indent_Amount loop
	    Ada.Text_IO.Put (Output_Object.Output_File, ' ');
        end loop;
        Output_Object.Char_Count := Output_Object.Indent_Amount;
        Output_Object.Out_Char_Count := Output_Object.Indent_Amount;
	Output_Object.Output_Buffer_Space_Before := False;
    end Make_Indent;


    procedure Spill (Output_Object : in out Corr_Output_Type) is
	-- Internal:
	-- Empty the output buffer in preperation for a New_Line or Put_Line.
    begin
        if Output_Object.Output_Buffer_Space_Before then
	    Ada.Text_IO.Put (Output_Object.Output_File, ' ');
	    Output_Object.Char_Count := Output_Object.Char_Count + 1; -- Count the space.
	    Output_Object.Out_Char_Count := Output_Object.Out_Char_Count + 1; -- Count the space.
        end if;
	if Output_Object.Output_Buffer_Len /= 0 then
	    Ada.Text_IO.Put (Output_Object.Output_File,
		Output_Object.Output_Buffer (1 .. Output_Object.Output_Buffer_Len));
--Ada.Text_IO.Put_Line("Spill: Len=" & Natural'Image(Output_Object.Output_Buffer_Len) &
--     " Space added=" &  Boolean'Image(Output_Object.Output_Buffer_Space_Before) & " Text=" &
--     Output_Object.Output_Buffer (1 .. Output_Object.Output_Buffer_Len));
	    Output_Object.Output_Buffer_Len := 0;
	    Output_Object.Out_Char_Count := Output_Object.Out_Char_Count +
		Output_Object.Output_Buffer_Len;
	end if;
        Output_Object.Output_Buffer_Space_Before := False;
    end Spill;


    procedure Buffer (Output_Object : in out Corr_Output_Type;
		      Char : in Character) is
	-- Internal:
	-- Add Char to the output buffer. Char will *not* be a word break
	-- character.
    begin
	if Output_Object.Output_Buffer_Len = Output_Object.Output_Buffer'Last then
	    -- Oops, buffer is full. Spill it, and this character.
--Ada.Text_IO.Put_Line("** Buffer overflow!!");
	    Spill (Output_Object);
	    Ada.Text_IO.Put (Output_Object.Output_File, Char);
	    Output_Object.Char_Count := Output_Object.Char_Count + 1;
	    Output_Object.Out_Char_Count := Output_Object.Out_Char_Count + 1;
	    return;
	end if;
	Output_Object.Output_Buffer_Len := Output_Object.Output_Buffer_Len + 1;
	Output_Object.Output_Buffer(Output_Object.Output_Buffer_Len) := Char;
        Output_Object.Char_Count := Output_Object.Char_Count + 1;
    end Buffer;


    procedure Buffer (Output_Object : in out Corr_Output_Type;
		      Str : in String) is
	-- Internal:
	-- Add Char to the output buffer. String will *not* include a word
	-- break character.
    begin
	if Output_Object.Output_Buffer_Len+Str'Length >= Output_Object.Output_Buffer'Last then
	    -- Oops, buffer is full. Spill it.
--Ada.Text_IO.Put_Line("** Buffer overflow!!");
	    Spill (Output_Object);
	end if;
	Output_Object.Output_Buffer(Output_Object.Output_Buffer_Len+1..Output_Object.Output_Buffer_Len+Str'Length)
	    := Str;
	Output_Object.Output_Buffer_Len := Output_Object.Output_Buffer_Len + Str'Length;
        Output_Object.Char_Count := Output_Object.Char_Count + Str'Length;
    end Buffer;


    procedure Start_Paragraph (Output_Object : in out Corr_Output_Type;
			       Style     : in ARM_Output.Paragraph_Style_Type;
			       Indent    : in ARM_Output.Paragraph_Indent_Type;
			       Number    : in String;
			       No_Prefix : in Boolean := False;
			       Tab_Stops : in ARM_Output.Tab_Info := ARM_Output.NO_TABS;
			       No_Breaks : in Boolean := False;
			       Keep_with_Next : in Boolean := False;
			       Space_After : in ARM_Output.Space_After_Type
				   := ARM_Output.Normal;
			       Justification : in ARM_Output.Justification_Type
				   := ARM_Output.Default) is
	-- Start a new paragraph. The style and indent of the paragraph is as
	-- specified. The (AA)RM paragraph number (which might include update
	-- and version numbers as well: [12.1/1]) is Number. If the format is
	-- a type with a prefix (bullets, hangining items), the prefix is
	-- omitted if No_Prefix is true. Tab_Stops defines the tab stops for
	-- the paragraph. If No_Breaks is True, we will try to avoid page breaks
	-- in the paragraph. If Keep_with_Next is true, we will try to avoid
	-- separating this paragraph and the next one. (These may have no
	-- effect in formats that don't have page breaks). Space_After
	-- specifies the amount of space following the paragraph. Justification
	-- specifies the text justification for the paragraph. Not_Valid_Error
	-- is raised if Tab_Stops /= NO_TABS for a hanging or bulleted format.
	use type ARM_Output.Paragraph_Indent_Type;
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Already in paragraph");
	end if;
	Output_Object.Is_In_Paragraph := True;
	Output_Object.Is_Hanging := False;
	Output_Object.Saw_Hang_End := False;
	Output_Object.Char_Count := 0;
	Output_Object.Out_Char_Count := 0;
	Output_Object.Output_Buffer_Space_Before := False; -- Nothing in it or on the line.
	Output_Object.Output_Buffer_Len := 0;
        Output_Object.Font := ARM_Output.Default;
        Output_Object.Is_Bold := False;
        Output_Object.Is_Italic := False;
        Output_Object.Size := 0;
        Output_Object.Para_Style := Style;
        Output_Object.Para_Indent := Indent;
        Output_Object.Is_Fixed_Format := False;

	if Output_Object.Clause_Len /= 0 and then
	   Number /= "" then
	    Ada.Text_IO.New_Line (Output_Object.Output_File);
	    Ada.Text_IO.Put (Output_Object.Output_File, "!paragraph ");
	    Ada.Text_IO.Put (Output_Object.Output_File, Output_Object.Clause_Num(1..Output_Object.Clause_Len));
	    Ada.Text_IO.Put (Output_Object.Output_File, '(');
	    Ada.Text_IO.Put (Output_Object.Output_File, Number);
	    Ada.Text_IO.Put (Output_Object.Output_File, ") [");
	    Ada.Text_IO.Put (Output_Object.Output_File, ARM_Output.Paragraph_Style_Type'Image(Style) &
		        " :" & ARM_Output.Paragraph_Indent_Type'Image(Indent));
	    Ada.Text_IO.Put_Line (Output_Object.Output_File, "]");
	    Ada.Text_IO.New_Line (Output_Object.Output_File);
	else
	    Ada.Text_IO.New_Line (Output_Object.Output_File);
	end if;

        Output_Object.Indent_Amount := Integer(Indent)*4 + 2;

	case Style is
	    when ARM_Output.Normal =>
		if Indent = 0 then
		    null; -- %% Temp.
		    Output_Object.Indent_Amount := 0; -- %% Temp.
		elsif Indent = 3 then
	            Ada.Text_IO.Put (Output_Object.Output_File, "@xindent<");
	            Output_Object.Char_Count := 9;
		    Output_Object.Indent_Amount := 0; -- %% Temp.
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;
	    when ARM_Output.Wide_Above => null;
		if Indent = 0 then
		    null; -- %% Temp.
		    Output_Object.Indent_Amount := 0; -- %% Temp.
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Small =>
		if Indent = 1 then -- Notes.
	            Ada.Text_IO.Put (Output_Object.Output_File, "@xindent<@s9<");
	            Output_Object.Char_Count := 13;
		    Output_Object.Indent_Amount := 0; -- %% Temp.
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;
	    when ARM_Output.Small_Wide_Above =>
		null; -- ** TBD (Unknown cases).

	    when ARM_Output.Header =>
		null; -- ** TBD (Unknown cases).

	    when ARM_Output.Small_Header =>
		if Indent = 1 then -- Notes Header.
		    null;
		    --Output_Object.Indent_Amount := 6; --** TBD.
        	else -- Unknown case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Index => null; --** TBD.
	    when ARM_Output.Syntax_Summary => null; --** TBD.
	    when ARM_Output.Title =>
		null; -- ** TBD (Unknown cases).

	    when ARM_Output.Examples =>
		if Indent = 1 then
	            Ada.Text_IO.Put (Output_Object.Output_File, "@xcode<");
	            Output_Object.Char_Count := 7;
		    Output_Object.Is_Fixed_Format := True;
		    Output_Object.Indent_Amount := 0; -- %% Temp.
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Small_Examples => null; --** TBD.

	    when ARM_Output.Swiss_Examples =>
		if Indent = 1 then
	            Ada.Text_IO.Put (Output_Object.Output_File, "@xcode<");
	            Output_Object.Char_Count := 7;
		    Output_Object.Is_Fixed_Format := True;
		    Output_Object.Indent_Amount := 0; -- %% Temp.
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Small_Swiss_Examples => null; --** TBD.

	    when ARM_Output.Bulleted =>
		if Indent = 1 then
		    Output_Object.Indent_Amount := 0; -- %% Temp.
		    if No_Prefix then
	                Ada.Text_IO.Put (Output_Object.Output_File, "@xindent<");
	                Output_Object.Char_Count := 9;
		    else
	                Ada.Text_IO.Put (Output_Object.Output_File, "@xbullet<");
	                Output_Object.Char_Count := 9;
		    end if;
		else -- Unknown/unimplemented case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Nested_Bulleted => null; --** TBD.

	    when ARM_Output.Small_Bulleted => null; --** TBD.

	    when ARM_Output.Small_Nested_Bulleted => null; --** TBD.

	    when ARM_Output.Giant_Hanging => null; --** TBD.

	    when ARM_Output.Wide_Hanging =>
		if Indent = 3 then
		    Output_Object.Indent_Amount := 0; -- %% Temp.
		    Output_Object.Is_Hanging := True;
		    if No_Prefix then
		        Output_Object.Saw_Hang_End := True;
		        Output_Object.Char_Count := 0;
		    else -- Has prefix
		        -- No units on first line.
		        Output_Object.Saw_Hang_End := False;
		        Ada.Text_IO.Put (Output_Object.Output_File, "@xhang<@xterm<");
		        Output_Object.Char_Count := 14;
		    end if;
		else -- Unknown/unimplemented case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Medium_Hanging => null; --** TBD.

	    when ARM_Output.Narrow_Hanging => null; --** TBD.

	    when ARM_Output.Hanging_in_Bulleted => null; --** TBD.

	    when ARM_Output.Small_Giant_Hanging => null; --** TBD.

	    when ARM_Output.Small_Wide_Hanging => null; --** TBD.

	    when ARM_Output.Small_Medium_Hanging => null; --** TBD.

	    when ARM_Output.Small_Narrow_Hanging => null; --** TBD.

	    when ARM_Output.Small_Hanging_in_Bulleted => null; --** TBD.

	    when ARM_Output.Enumerated => null; --** TBD.

	    when ARM_Output.Small_Enumerated => null; --** TBD.

	end case;

	if Output_Object.Indent_Amount > 6 then
	    for I in 1 .. (Output_Object.Indent_Amount-6)/4 loop
	        Ada.Text_IO.Put (Output_Object.Output_File, "    ");
	        Output_Object.Char_Count := Output_Object.Char_Count + 4;
	    end loop;
	end if;

	case Style is
	    when ARM_Output.Normal | ARM_Output.Wide_Above |
		 ARM_Output.Small | ARM_Output.Small_Wide_Above |
		 ARM_Output.Header | ARM_Output.Small_Header |
		 ARM_Output.Index | ARM_Output.Syntax_Summary |
		 ARM_Output.Title |
		 ARM_Output.Examples | ARM_Output.Small_Examples |
		 ARM_Output.Swiss_Examples | ARM_Output.Small_Swiss_Examples =>
		Output_Object.Tab_Stops := Tab_Stops;
		    -- We'll expand proportional stops here (text characters
		    -- are larger than the variable ones these are set up for).
		for I in 1 .. Tab_Stops.Number loop
		    if ARM_Output."=" (Tab_Stops.Stops(I).Kind,
				       ARM_Output.Left_Proportional) then
		        Output_Object.Tab_Stops.Stops(I).Stop :=
				(Tab_Stops.Stops(I).Stop * 5 / 4) + Output_Object.Indent_Amount;
		    else
		        Output_Object.Tab_Stops.Stops(I).Stop :=
				Tab_Stops.Stops(I).Stop + Output_Object.Indent_Amount;
		    end if;
		end loop;
	    when ARM_Output.Bulleted | ARM_Output.Nested_Bulleted |
		 ARM_Output.Small_Bulleted | ARM_Output.Small_Nested_Bulleted |
		 ARM_Output.Giant_Hanging | ARM_Output.Wide_Hanging |
		 ARM_Output.Medium_Hanging | ARM_Output.Narrow_Hanging |
		 ARM_Output.Hanging_in_Bulleted |
		 ARM_Output.Small_Giant_Hanging | ARM_Output.Small_Wide_Hanging |
		 ARM_Output.Small_Medium_Hanging | ARM_Output.Small_Narrow_Hanging |
		 ARM_Output.Small_Hanging_in_Bulleted |
		 ARM_Output.Enumerated | ARM_Output.Small_Enumerated =>
		if Tab_Stops.Number /= 0 then
	            Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		        "Tabs in hanging/bulleted paragraph");
		end if;
	end case;
	Output_Object.Out_Char_Count := Output_Object.Char_Count;

	-- Note: No_Breaks, Keep_with_Next, and Justification have no effect
	-- here.
--Ada.Text_IO.Put_Line ("Start_Paragraph - Indent=" & Natural'Image(Output_Object.Indent_Amount) & " Cnt=" &
--    Natural'Image(Output_Object.Char_Count));
    end Start_Paragraph;


    procedure End_Paragraph (Output_Object : in out Corr_Output_Type) is
	-- End a paragraph.
	use type ARM_Output.Paragraph_Indent_Type;
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
	case Output_Object.Para_Style is
	    when ARM_Output.Normal =>
		if Output_Object.Para_Indent = 0 then
		    null;
		elsif Output_Object.Para_Indent = 3 then
		    Buffer (Output_Object, '>');
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;
	    when ARM_Output.Wide_Above => null;
		if Output_Object.Para_Indent = 0 then
		    null; -- %% Temp.
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Small =>
		if Output_Object.Para_Indent = 1 then -- Notes.
		    Buffer (Output_Object, ">>");
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;
	    when ARM_Output.Small_Wide_Above =>
		null; -- ** TBD (Unknown cases).

	    when ARM_Output.Header =>
		null; -- ** TBD (Unknown cases).

	    when ARM_Output.Small_Header =>
		if Output_Object.Para_Indent = 1 then -- Notes Header.
		    null;
        	else -- Unknown case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Index => null; --** TBD.
	    when ARM_Output.Syntax_Summary => null; --** TBD.
	    when ARM_Output.Title => null; --** TBD.
	    when ARM_Output.Examples =>
		if Output_Object.Para_Indent = 1 then
		    Buffer (Output_Object, '>');
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Small_Examples => null; --** TBD.

	    when ARM_Output.Swiss_Examples =>
		if Output_Object.Para_Indent = 1 then
		    Buffer (Output_Object, '>');
		else -- Unknown case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Small_Swiss_Examples => null; --** TBD.

	    when ARM_Output.Bulleted =>
		if Output_Object.Para_Indent = 1 then
		    Buffer (Output_Object, '>');
		else -- Unknown/unimplemented case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Nested_Bulleted => null; --** TBD.

	    when ARM_Output.Small_Bulleted => null; --** TBD.

	    when ARM_Output.Small_Nested_Bulleted => null; --** TBD.

	    when ARM_Output.Giant_Hanging => null; --** TBD.

	    when ARM_Output.Wide_Hanging =>
		if Output_Object.Para_Indent = 3 then
		    Buffer (Output_Object, '>');
		else -- Unknown/unimplemented case.
		    null; -- ** Tbd.
		end if;

	    when ARM_Output.Medium_Hanging => null; --** TBD.

	    when ARM_Output.Narrow_Hanging => null; --** TBD.

	    when ARM_Output.Hanging_in_Bulleted => null; --** TBD.

	    when ARM_Output.Small_Giant_Hanging => null; --** TBD.

	    when ARM_Output.Small_Wide_Hanging => null; --** TBD.

	    when ARM_Output.Small_Medium_Hanging => null; --** TBD.

	    when ARM_Output.Small_Narrow_Hanging => null; --** TBD.

	    when ARM_Output.Small_Hanging_in_Bulleted => null; --** TBD.

	    when ARM_Output.Enumerated => null; --** TBD.

	    when ARM_Output.Small_Enumerated => null; --** TBD.

	end case;

	if Output_Object.Output_Buffer_Len /= 0 then
	    Spill (Output_Object);
	end if;
	Output_Object.Is_In_Paragraph := False;
	Ada.Text_IO.New_Line (Output_Object.Output_File, 2); -- Double space paragraphs.
    end End_Paragraph;


    procedure Category_Header (Output_Object : in out Corr_Output_Type;
			       Header_Text : String) is
	-- Output a Category header (that is, "Legality Rules",
	-- "Dynamic Semantics", etc.)
	-- (Note: We did not use a enumeration here to insure that these
	-- headers are spelled the same in all output versions).
	-- Raises Not_Valid_Error if in a paragraph.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Header in paragraph");
	end if;
	Ada.Text_IO.New_Line (Output_Object.Output_File);
	Ada.Text_IO.Put_Line (Output_Object.Output_File, "!subheader");
	Ada.Text_IO.Put (Output_Object.Output_File, "@i<@s8<");
	if Ada.Strings.Fixed.Count (Header_Text, Special_Set) = 0 then
            Ada.Text_IO.Put (Output_Object.Output_File, Header_Text);
	else
	    for I in Header_Text'Range loop
		if Header_Text(I) = '>' then
	            Ada.Text_IO.Put (Output_Object.Output_File, "@>");
		elsif Header_Text(I) = '@' then
	            Ada.Text_IO.Put (Output_Object.Output_File, "@@");
		else
	            Ada.Text_IO.Put (Output_Object.Output_File, Header_Text(I));
		end if;
	    end loop;
	end if;
	Ada.Text_IO.Put (Output_Object.Output_File, ">>");
	Ada.Text_IO.New_Line (Output_Object.Output_File);
	Output_Object.Char_Count := 0;
	Output_Object.Out_Char_Count := 0;
    end Category_Header;


    procedure Clause_Header (Output_Object     : in out Corr_Output_Type;
			     Header_Text       : in String;
			     Level	       : in ARM_Contents.Level_Type;
			     Clause_Number     : in String;
			     Top_Level_Subdivision_Name : in ARM_Output.Top_Level_Subdivision_Name_Kind;
			     No_Page_Break     : in Boolean := False) is
	-- Output a Clause header. The level of the header is specified
	-- in Level. The Clause Number is as specified; the top-level (and
	-- other) subdivision names are as specified. These should appear in
	-- the table of contents.
	-- For hyperlinked formats, this should generate a link target.
	-- If No_Page_Break is True, suppress any page breaks.
	-- Raises Not_Valid_Error if in a paragraph.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Header in paragraph");
	end if;
        Ada.Text_IO.New_Line (Output_Object.Output_File);

	Output_Object.Clause_Len := Clause_Number'Length;
	Output_Object.Clause_Num(1..Output_Object.Clause_Len) :=
	    Clause_Number;
	-- Special for table of contents:
	if Clause_Number = "" and then
		(Header_Text = "Table of Contents" or else
		 Header_Text = "Contents") then
	    Ada.Text_IO.Put (Output_Object.Output_File,
			       "!clause ");
	    Ada.Text_IO.Put_Line (Output_Object.Output_File,
			       Header_Text);
	    Ada.Text_IO.New_Line (Output_Object.Output_File, 2);
	    Output_Object.Char_Count := 0;
	    Output_Object.Out_Char_Count := 0;
	    return;
	end if;

        Ada.Text_IO.Put (Output_Object.Output_File,
			 "!clause ");
	case Level is
	    when ARM_Contents.Plain_Annex =>
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Clause_Number); -- Note: Clause_Number includes "Annex"
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Header_Text);
	    when ARM_Contents.Normative_Annex =>
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Clause_Number); -- Note: Clause_Number includes "Annex"
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   "(normative)");
		Ada.Text_IO.New_Line (Output_Object.Output_File);
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Header_Text);
	    when ARM_Contents.Informative_Annex =>
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Clause_Number); -- Note: Clause_Number includes "Annex"
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   "(informative)");
		Ada.Text_IO.New_Line (Output_Object.Output_File);
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Header_Text);
	    when ARM_Contents.Section =>
		case Top_Level_Subdivision_Name is
		    when ARM_Output.Chapter =>
		        Ada.Text_IO.Put_Line (Output_Object.Output_File,
					      "Chapter " & Clause_Number & ": " & Header_Text);
		    when ARM_Output.Section =>
		        Ada.Text_IO.Put_Line (Output_Object.Output_File,
					      "Section " & Clause_Number & ": " & Header_Text);
		    when ARM_Output.Clause =>
		        Ada.Text_IO.Put_Line (Output_Object.Output_File,
					      Clause_Number & "   " & Header_Text);
		end case;
	    when ARM_Contents.Unnumbered_Section =>
	        if Header_Text /= "" then
		    Ada.Text_IO.Put_Line (Output_Object.Output_File,
				       Header_Text);
	        end if;
	    when ARM_Contents.Clause | ARM_Contents.Subclause |
		 ARM_Contents.Subsubclause =>
	        Ada.Text_IO.Put_Line (Output_Object.Output_File,
				      Clause_Number & ' ' & Header_Text);
	    when ARM_Contents.Dead_Clause =>
		raise Program_Error; -- No headers for dead clauses.
	end case;
	Ada.Text_IO.New_Line (Output_Object.Output_File, 2);
	Output_Object.Char_Count := 0;
	Output_Object.Out_Char_Count := 0;
	-- We don't have any page breaks here to suppress.
    end Clause_Header;


    procedure Revised_Clause_Header
			    (Output_Object     : in out Corr_Output_Type;
			     New_Header_Text   : in String;
			     Old_Header_Text   : in String;
			     Level	       : in ARM_Contents.Level_Type;
			     Clause_Number     : in String;
			     Version	       : in ARM_Contents.Change_Version_Type;
			     Old_Version       : in ARM_Contents.Change_Version_Type;
			     Top_Level_Subdivision_Name : in ARM_Output.Top_Level_Subdivision_Name_Kind;
        		     No_Page_Break     : in Boolean := False) is
	-- Output a revised clause header. Both the original and new text will
	-- be output. The level of the header is specified in Level. The Clause
	-- Number is as specified; the top-level (and other) subdivision names
	-- are as specified. These should appear in the table of contents.
	-- For hyperlinked formats, this should generate a link target.
	-- Version is the insertion version of the new text; Old_Version is
	-- the insertion version of the old text.
	-- If No_Page_Break is True, suppress any page breaks.
	-- Raises Not_Valid_Error if in a paragraph.
	function Header_Text return String is
	    -- Note: Version and Old_Version are not used.
	begin
	    return '{' & New_Header_Text & "} [" & Old_Header_Text & ']';
	end Header_Text;
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Header in paragraph");
	end if;
        Ada.Text_IO.New_Line (Output_Object.Output_File);

	Output_Object.Clause_Len := Clause_Number'Length;
	Output_Object.Clause_Num(1..Output_Object.Clause_Len) :=
	    Clause_Number;
	-- Special for table of contents:
	if Clause_Number = "" and then
		(Header_Text = "Table of Contents" or else -- Ada 95 format
		 Header_Text = "Contents") then -- ISO 2004 format.
            Ada.Text_IO.Put (Output_Object.Output_File,
			     "!clause ");
	    Ada.Text_IO.Put_Line (Output_Object.Output_File,
			       Header_Text);
	    Ada.Text_IO.New_Line (Output_Object.Output_File, 2);
	    Output_Object.Char_Count := 0;
	    Output_Object.Out_Char_Count := 0;
	    return;
	end if;

        Ada.Text_IO.Put (Output_Object.Output_File,
			 "!clause ");
	case Level is
	    when ARM_Contents.Plain_Annex =>
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Clause_Number); -- Note: Clause_Number includes "Annex"
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Header_Text);
	    when ARM_Contents.Normative_Annex =>
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Clause_Number); -- Note: Clause_Number includes "Annex"
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   "(normative)");
		Ada.Text_IO.New_Line (Output_Object.Output_File);
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Header_Text);
	    when ARM_Contents.Informative_Annex =>
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Clause_Number); -- Note: Clause_Number includes "Annex"
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   "(informative)");
		Ada.Text_IO.New_Line (Output_Object.Output_File);
		Ada.Text_IO.Put_Line (Output_Object.Output_File,
				   Header_Text);
	    when ARM_Contents.Section =>
		case Top_Level_Subdivision_Name is
		    when ARM_Output.Chapter =>
		        Ada.Text_IO.Put_Line (Output_Object.Output_File,
					      "Chapter " & Clause_Number & ": " & Header_Text);
		    when ARM_Output.Section =>
		        Ada.Text_IO.Put_Line (Output_Object.Output_File,
					      "Section " & Clause_Number & ": " & Header_Text);
		    when ARM_Output.Clause =>
		        Ada.Text_IO.Put_Line (Output_Object.Output_File,
					      Clause_Number & "   " & Header_Text);
		end case;

	    when ARM_Contents.Unnumbered_Section =>
	        if Header_Text /= "" then
		    Ada.Text_IO.Put_Line (Output_Object.Output_File,
				       Header_Text);
	        end if;
	    when ARM_Contents.Clause | ARM_Contents.Subclause |
		 ARM_Contents.Subsubclause =>
	        Ada.Text_IO.Put_Line (Output_Object.Output_File,
				      Clause_Number & ' ' & Header_Text);
	    when ARM_Contents.Dead_Clause =>
		raise Program_Error; -- No headers for dead clauses.
	end case;
	Ada.Text_IO.New_Line (Output_Object.Output_File, 2);
	Output_Object.Char_Count := 0;
	Output_Object.Out_Char_Count := 0;
	-- We don't have any page breaks here to suppress.
    end Revised_Clause_Header;


    procedure TOC_Marker (Output_Object : in out Corr_Output_Type;
			  For_Start : in Boolean) is
	-- Mark the start (if For_Start is True) or end (if For_Start is
	-- False) of the table of contents data. Output objects that
	-- auto-generate the table of contents can use this to do needed
	-- actions.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	null; -- We don't care about this.
    end TOC_Marker;


    procedure New_Page (Output_Object : in out Corr_Output_Type;
			Kind : ARM_Output.Page_Kind_Type := ARM_Output.Any_Page) is
	-- Output a page break.
	-- Note that this has no effect on non-printing formats.
	-- Any_Page breaks to the top of the next page (whatever it is);
	-- Odd_Page_Only breaks to the top of the odd-numbered page;
	-- Soft_Page allows a page break but does not force one (use in
	-- "No_Breaks" paragraphs.)
	-- Raises Not_Valid_Error if in a paragraph if Kind = Any_Page or
	-- Odd_Page, and if not in a paragraph if Kind = Soft_Page.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	case Kind is
	    when ARM_Output.Any_Page | ARM_Output.Odd_Page_Only =>
		if Output_Object.Is_In_Paragraph then
		    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
			"Page in paragraph");
		end if;
		Ada.Text_IO.New_Line (Output_Object.Output_File, 2);
	    when ARM_Output.Soft_Page =>
		if not Output_Object.Is_In_Paragraph then
		    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
			"Soft page not in paragraph");
		end if;
		null; -- No page breaks.
		Spill (Output_Object);
	end case;
    end New_Page;


    procedure New_Column (Output_Object : in out Corr_Output_Type) is
	-- Output a column break.
	-- Raises Not_Valid_Error if in a paragraph, or if the number of
	-- columns is 1.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"New column in paragraph");
	end if;
	-- No columns in text format.
	Ada.Text_IO.New_Line (Output_Object.Output_File);
    end New_Column;


    procedure Start_Table (Output_Object : in out Corr_Output_Type;
			   Columns : in ARM_Output.Column_Count;
			   First_Column_Width : in ARM_Output.Column_Count;
			   Last_Column_Width : in ARM_Output.Column_Count;
			   Alignment : in ARM_Output.Column_Text_Alignment;
			   No_Page_Break : in Boolean;
			   Has_Border : in Boolean;
			   Small_Text_Size : in Boolean;
			   Header_Kind : in ARM_Output.Header_Kind_Type) is
	-- Starts a table. The number of columns is Columns; the first
	-- column has First_Column_Width times the normal column width, and
	-- the last column has Last_Column_Width times the normal column width.
	-- Alignment is the horizontal text alignment within the columns.
	-- No_Page_Break should be True to keep the table intact on a single
	-- page; False to allow it to be split across pages.
	-- Has_Border should be true if a border is desired, false otherwise.
	-- Small_Text_Size means that the contents will have the AARM size;
	-- otherwise it will have the normal size.
	-- Header_Kind determines whether the table has headers.
	-- This command starts a paragraph; the entire table is a single
	-- paragraph. Text will be considered part of the caption until the
	-- next table marker call.
	-- Raises Not_Valid_Error if in a paragraph.
    begin
	-- Alignment, No_Page_Break, Border, Small_Text_Size, and Header_Kind
	-- not used here.
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Table in paragraph");
	end if;

	Output_Object.Tab_Stops.Number := Columns;
	declare
	     Column_Units : constant ARM_Output.Column_Count :=
		Columns+First_Column_Width+Last_Column_Width-2;
	     Width : Natural :=
		(72/(Column_Units));
	begin
	    if Column_Units <= 3 then -- Keep it from getting too wide.
		Width := 22;
	    end if;
	    for I in 1 .. Columns loop
	        Output_Object.Tab_Stops.Stops(I) := (Kind => ARM_Output.Left_Fixed,
						     Stop => Width*(I+First_Column_Width-1)+10);
	    end loop;
	end;

	Output_Object.Indent_Amount := 10;
        Ada.Text_IO.Put (Output_Object.Output_File, "          ");
	Output_Object.Char_Count := 10;
	Output_Object.Out_Char_Count := 10;

	Output_Object.Is_In_Paragraph := True;
	Output_Object.Is_In_Table := True;
    end Start_Table;


    procedure Table_Marker (Output_Object : in out Corr_Output_Type;
			    Marker : in ARM_Output.Table_Marker_Type) is
	-- Marks the end of an entity in a table.
	-- If Marker is End_Caption, the table caption ends and the
	--	future text is part of the table header.
	-- If Marker is End_Header, the table header ends and the
	--	future text is part of the table body.
	-- If Marker is End_Row, a row in the table is completed, and another
	--	row started.
	-- If Marker is End_Row_Next_Is_Last, a row in the table is completed,
	--	and another row started. That row is the last row in the table.
	-- If Marker is End_Item, an item in the table header or body is ended,
	--	and another started.
	-- If Marker is End_Table, the entire table is finished.
	-- Raises Not_Valid_Error if not in a table.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if (not Output_Object.Is_In_Paragraph) or (not Output_Object.Is_In_Table) then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Table marker not in table");
	end if;
	case Marker is
	    when ARM_Output.End_Item =>
		-- Just tab over one row:
		Spill (Output_Object);
		Ada.Text_IO.Put_Line (Output_Object.Output_File, " ");
	        Output_Object.Char_Count := Output_Object.Char_Count + 1;
	        Output_Object.Out_Char_Count := Output_Object.Out_Char_Count + 1;
		for I in 1 .. Output_Object.Tab_Stops.Number loop
		    if Output_Object.Tab_Stops.Stops(I).Stop > Output_Object.Char_Count then
			for J in Output_Object.Char_Count+1 .. Output_Object.Tab_Stops.Stops(I).Stop-1 loop
		            Ada.Text_IO.Put_Line (Output_Object.Output_File, " ");
		            Output_Object.Char_Count := Output_Object.Char_Count + 1;
		            Output_Object.Out_Char_Count := Output_Object.Out_Char_Count + 1;
			end loop;
		    end if;
		end loop;

	    when ARM_Output.End_Caption =>
		Spill (Output_Object);
		Ada.Text_IO.New_Line (Output_Object.Output_File, 2);
	        Ada.Text_IO.Put (Output_Object.Output_File, "          ");
		Output_Object.Char_Count := 10;
		Output_Object.Out_Char_Count := 10;
	    when ARM_Output.End_Header =>
		Spill (Output_Object);
		Ada.Text_IO.New_Line (Output_Object.Output_File, 2);
	        Ada.Text_IO.Put (Output_Object.Output_File, "          ");
		Output_Object.Char_Count := 10;
		Output_Object.Out_Char_Count := 10;
	    when ARM_Output.End_Row | ARM_Output.End_Row_Next_Is_Last =>
		Spill (Output_Object);
		Ada.Text_IO.New_Line (Output_Object.Output_File, 1);
	        Ada.Text_IO.Put (Output_Object.Output_File, "          ");
		Output_Object.Char_Count := 10;
		Output_Object.Out_Char_Count := 10;
	    when ARM_Output.End_Table =>
		Spill (Output_Object);
		Output_Object.Is_In_Paragraph := False;
		Output_Object.Is_In_Table := False;
		Ada.Text_IO.New_Line (Output_Object.Output_File);
		Output_Object.Tab_Stops := ARM_Output.NO_TABS;
	end case;
    end Table_Marker;


    procedure Separator_Line (Output_Object : in out Corr_Output_Type;
			      Is_Thin : Boolean := True) is
	-- Output a separator line. It is thin if "Is_Thin" is true.
	-- Raises Not_Valid_Error if in a paragraph.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Separator in paragraph");
	end if;
	Ada.Text_IO.New_Line (Output_Object.Output_File);
	if Is_Thin then
	    Ada.Text_IO.Put_Line (Output_Object.Output_File, "---------------------------------------------------------------------");
	else
	    Ada.Text_IO.Put_Line (Output_Object.Output_File, "=====================================================================");
	end if;
	Ada.Text_IO.New_Line (Output_Object.Output_File);
    end Separator_Line;


    -- Text output: These are only allowed after a Start_Paragraph and
    -- before any End_Paragraph. Raises Not_Valid_Error if not allowed.

    procedure Ordinary_Text (Output_Object : in out Corr_Output_Type;
			     Text : in String) is
	-- Output ordinary text.
	-- The text must end at a word break, never in the middle of a word.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
--Ada.Text_IO.Put_Line ("Ordinary_Text: Cnt=" & Natural'Image(Output_Object.Char_Count) &
--" Buffer=" & Natural'Image(Output_Object.Output_Buffer_Len));
	if Output_Object.Char_Count + Text'Length >= LINE_LENGTH - 2 and then
	   Output_Object.Out_Char_Count > Output_Object.Indent_Amount then
	    -- We want a line break here if the line is too long and something was output:
	    Ada.Text_IO.New_Line (Output_Object.Output_File);
	    Make_Indent (Output_Object);
	    --Output_Object.Output_Buffer_Space_Before := False;
	        -- Start of line, this is done by Make_Indent.
	    Spill (Output_Object);
	else
	    Spill (Output_Object);
	end if;
	if Ada.Strings.Fixed.Count (Text, Special_Set) = 0 then
            Ada.Text_IO.Put (Output_Object.Output_File, Text);
            Output_Object.Char_Count := Output_Object.Char_Count + Text'Length;
            Output_Object.Out_Char_Count := Output_Object.Out_Char_Count + Text'Length;
	else
	    for I in Text'Range loop
		if Text(I) = '>' then
	            Ada.Text_IO.Put (Output_Object.Output_File, "@>");
	            Output_Object.Char_Count := Output_Object.Char_Count + 2;
	            Output_Object.Out_Char_Count := Output_Object.Out_Char_Count + 2;
		elsif Text(I) = '@' then
	            Ada.Text_IO.Put (Output_Object.Output_File, "@@");
	            Output_Object.Char_Count := Output_Object.Char_Count + 2;
	            Output_Object.Out_Char_Count := Output_Object.Out_Char_Count + 2;
		else
	            Ada.Text_IO.Put (Output_Object.Output_File, Text(I));
	            Output_Object.Char_Count := Output_Object.Char_Count + 1;
	            Output_Object.Out_Char_Count := Output_Object.Out_Char_Count + 1;
		end if;
	    end loop;
	end if;
        Output_Object.Output_Buffer_Space_Before := False; -- No space between
							   -- this and any following text.
    end Ordinary_Text;


    procedure Ordinary_Character (Output_Object : in out Corr_Output_Type;
			          Char : in Character) is
	-- Output an ordinary character.
	-- Spaces will be used to break lines as needed.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;

	if Output_Object.Char_Count >= LINE_LENGTH and then
	   Output_Object.Out_Char_Count > Output_Object.Indent_Amount then
	    -- Insert a break here if anything has been output (but don't
	    -- Spill the buffer):
--Ada.Text_IO.Put_Line ("Ordinary_Char [Break, no spill]: Cnt=" & Natural'Image(Output_Object.Char_Count));
	    Ada.Text_IO.New_Line (Output_Object.Output_File);
	    Make_Indent (Output_Object);
	    --Output_Object.Output_Buffer_Space_Before := False;
		-- Start of line, this is done by Make_Indent.
		-- Note that this may make the space disappear.
	    -- Add the contents of the buffer to the character count for this line:
	    Output_Object.Char_Count := Output_Object.Char_Count +
		Output_Object.Output_Buffer_Len;
	    if Char = '>' then
	        Buffer (Output_Object, "@>");
	    elsif Char = '@' then
	        Buffer (Output_Object, "@@");
	    elsif Char /= ' ' then
	        Buffer (Output_Object, Char);
	    else -- Break character, spill on the new line:
		if Output_Object.Output_Buffer_Len /= 0 then
	            Spill (Output_Object); -- Output the buffer up to the space.
	            Output_Object.Output_Buffer_Space_Before := True; -- Mid-line now.
	        -- else nothing in buffer, so nothing to output; just skip it.
	        end if;
	    end if;
	elsif Char = ' ' then
	    -- Break character, and it fits on this line:
	    if Output_Object.Output_Buffer_Len /= 0 then
--Ada.Text_IO.Put_Line ("Ordinary_Char [Space spill]: Cnt=" & Natural'Image(Output_Object.Char_Count));
	        Spill (Output_Object); -- Output the buffer up to the space.
	        Output_Object.Output_Buffer_Space_Before := True; -- Mid-line now.
	    else -- nothing in buffer.
		-- nothing to output. But make sure we display a space before
		-- the next item.
	        Output_Object.Output_Buffer_Space_Before := True; -- Mid-line now.
	    end if;
        elsif Char = '>' then
	    Buffer (Output_Object, "@>");
        elsif Char = '@' then
	    Buffer (Output_Object, "@@");
	else
	    Buffer (Output_Object, Char);
	end if;
    end Ordinary_Character;


    procedure Hard_Space (Output_Object : in out Corr_Output_Type) is
	-- Output a hard space. No line break should happen at a hard space.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
	if Output_Object.Is_Fixed_Format then
	    -- In this format, all spaces are hard spaces.
	    Buffer (Output_Object, ' ');
	else -- A hard space command.
	    Buffer (Output_Object, "@ ");
	end if;
    end Hard_Space;


    procedure Line_Break (Output_Object : in out Corr_Output_Type) is
	-- Output a line break. This does not start a new paragraph.
	-- This corresponds to a "<BR>" in HTML.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
--Ada.Text_Io.Put_Line ("Line_Break");
	if Output_Object.Is_Fixed_Format then
	    -- In this format, all line breaks are significant.
	    null;
	else -- A hard space command.
            Buffer (Output_Object, "@hr");
	end if;
	if Output_Object.Output_Buffer_Len /= 0 then
	    Spill (Output_Object);
	end if;
	Ada.Text_IO.New_Line (Output_Object.Output_File);
        Make_Indent (Output_Object);
    end Line_Break;


    procedure Index_Line_Break (Output_Object : in out Corr_Output_Type;
				Clear_Keep_with_Next : in Boolean) is
	-- Output a line break for the index. This does not start a new
	-- paragraph in terms of spacing. This corresponds to a "<BR>"
	-- in HTML. If Clear_Keep_with_Next is true, insure that the next
	-- line does not require the following line to stay with it.
	-- Raises Not_Valid_Error if the paragraph is not in the index format.
    begin
	Line_Break (Output_Object);
    end Index_Line_Break;


    procedure Soft_Line_Break (Output_Object : in out Corr_Output_Type) is
	-- Output a soft line break. This is a place (in the middle of a
	-- "word") that we allow a line break. It is usually used after
	-- underscores in long non-terminals.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
--	if Output_Object.Char_Count >= LINE_LENGTH - 10 then
--	    if Output_Object.Output_Buffer_Len /= 0 then
--	        Spill (Output_Object);
--	    end if;
--	    Ada.Text_IO.New_Line (Output_Object.Output_File);
--            Make_Indent (Output_Object);
--	-- else we don't need a line break.
--	end if;
	null; -- Ignore this, there is no counterpart in Corrigendum formatting.
    end Soft_Line_Break;


    procedure Soft_Hyphen_Break (Output_Object : in out Corr_Output_Type) is
	-- Output a soft line break, with a hyphen. This is a place (in the middle of
	-- a "word") that we allow a line break. If the line break is used,
	-- a hyphen will be added to the text.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
--	if Output_Object.Char_Count >= LINE_LENGTH - 8 then
--	    Spill (Output_Object);
--	    Ada.Text_IO.Put_Line (Output_Object.Output_File, "-"); -- Add the hyphen and break.
--            Make_Indent (Output_Object);
--	-- else we don't need a line break.
--	end if;
	null; -- Ignore this, there is no counterpart in Corrigendum formatting.
    end Soft_Hyphen_Break;


    procedure Tab (Output_Object : in out Corr_Output_Type) is
	-- Output a tab, inserting space up to the next tab stop.
	-- Raises Not_Valid_Error if the paragraph was created with
	-- Tab_Stops = ARM_Output.NO_TABS.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
	if ARM_Output."="(Output_Object.Tab_Stops, ARM_Output.NO_TABS) then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Tab, but none set");
	end if;
	-- We use the tab stops as characters here, and fixed and proportional
	-- stops are treated identically.
	-- Find the first stop greater than the current character count. (After
	-- writing a space).
--Ada.Text_IO.Put_Line ("Tab");
        Buffer (Output_Object, "@tab");
	Output_Object.Output_Buffer_Space_Before := False; -- Spaces needed were output.
    end Tab;


    procedure Special_Character (Output_Object : in out Corr_Output_Type;
			         Char : in ARM_Output.Special_Character_Type) is
	-- Output an special character.
    begin
	--** Could use Latin1 and Unicode equivalents for most of these.
	case Char is
	    when ARM_Output.EM_Dash =>
		Buffer (Output_Object, "@emdash");
	    when ARM_Output.EN_Dash =>
		Buffer (Output_Object, "@endash");
	    when ARM_Output.GEQ =>
		Ordinary_Text (Output_Object, ">="); -- Not available in Corrigendum, use the Ada one.
	    when ARM_Output.LEQ =>
		Ordinary_Text (Output_Object, "<="); -- Not available in Corrigendum, use the Ada one.
	    when ARM_Output.NEQ =>
		Ordinary_Text (Output_Object, "/="); -- Not available in Corrigendum, use the Ada one.
	    when ARM_Output.PI =>
		Buffer (Output_Object, "@pi");
	    when ARM_Output.Left_Ceiling =>
		Ordinary_Text (Output_Object, "Ceiling("); -- Not available in Corrigendum.
	    when ARM_Output.Right_Ceiling =>
		Ordinary_Text (Output_Object, ")"); -- Not available in Corrigendum.
	    when ARM_Output.Left_Floor =>
		Ordinary_Text (Output_Object, "Floor("); -- Not available in Corrigendum.
	    when ARM_Output.Right_Floor =>
		Ordinary_Text (Output_Object, ")"); -- Not available in Corrigendum.
	    when ARM_Output.Thin_Space =>
		Ordinary_Text (Output_Object, " "); -- Not available in Corrigendum.
	    when ARM_Output.Left_Quote =>
		Buffer (Output_Object, "@lquote");
	    when ARM_Output.Right_Quote =>
		Buffer (Output_Object, "@rquote");
	    when ARM_Output.Left_Double_Quote =>
		Ordinary_Text (Output_Object, """"); -- Not available in Corrigendum, use double quote.
	    when ARM_Output.Right_Double_Quote =>
		Ordinary_Text (Output_Object, """"); -- Not available in Corrigendum, use double quote.
	    when ARM_Output.Small_Dotless_I =>
		Ordinary_Text (Output_Object, "i"); -- Not available in Corrigendum, use the nearest text.
	    when ARM_Output.Capital_Dotted_I =>
		Ordinary_Text (Output_Object, "I"); -- Not available in Corrigendum, use the nearest text.
	end case;
    end Special_Character;


    procedure Unicode_Character (Output_Object : in out Corr_Output_Type;
			         Char : in ARM_Output.Unicode_Type) is
	-- Output a Unicode character, with code position Char.
	Char_Code : constant String := ARM_Output.Unicode_Type'Image(Char);
    begin
	-- We don't check, but we assume this is not a normal character.
	Buffer (Output_Object, "@unicode<" & Char_Code(2..Char_Code'Last) & ">");
    end Unicode_Character;


    procedure End_Hang_Item (Output_Object : in out Corr_Output_Type) is
	-- Marks the end of a hanging item. Call only once per paragraph.
	-- Raises Not_Valid_Error if the paragraph style is not in
	-- Text_Prefixed_Style_Subtype, or if this has already been
	-- called for the current paragraph, or if the paragraph was started
	-- with No_Prefix = True.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
	if not Output_Object.Is_Hanging then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not a hanging paragraph");
	end if;
	if Output_Object.Saw_Hang_End then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Already saw the end of the hanging part");
	end if;
	Output_Object.Saw_Hang_End := True;

        Buffer (Output_Object, ">"); -- Close @Xterm<
    end End_Hang_Item;


    procedure Text_Format (Output_Object : in out Corr_Output_Type;
			   Format : in ARM_Output.Format_Type) is
	-- Change the text format so that all of the properties are as specified.
	-- Note: Changes to these properties ought be stack-like; that is,
	-- Bold on, Italic on, Italic off, Bold off is OK; Bold on, Italic on,
	-- Bold off, Italic off should be avoided (as separate commands).
	use type ARM_Output.Change_Type;
	use type ARM_Output.Location_Type;
	use type ARM_Output.Size_Type;
	-- Note: We ignore colors here, no colors in !Corrigendum markup.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;

	if not Format.Bold and Output_Object.Is_Bold then
	    Buffer (Output_Object, '>');
	    Output_Object.Is_Bold := False;
	end if;

	if not Format.Italic and Output_Object.Is_Italic then
	    Buffer (Output_Object, '>');
	    Output_Object.Is_Italic := False;
	end if;

	if Format.Size /= Output_Object.Size then
	    if Output_Object.Size /= 0 then
	        Buffer (Output_Object, '>');
	    end if;
	end if;

	if Format.Location /= Output_Object.Location then
	    if Output_Object.Location /= ARM_Output.Normal then
	        --Buffer (Output_Object, '>');
		null; -- Corrigendum doesn't support this.
	    end if;
	end if;

	if ARM_Output."/=" (Format.Font, Output_Object.Font) then
	    case Output_Object.Font is
		when ARM_Output.Default => null;
		when ARM_Output.Fixed =>
		    Buffer (Output_Object, '>');
		when ARM_Output.Roman =>
		    Buffer (Output_Object, '>');
		when ARM_Output.Swiss =>
		    Buffer (Output_Object, '>');
	    end case;
	end if;

	-- For the intended purpose, there should be no Change commands.
	if Format.Change /= Output_Object.Change then
	    if Format.Change = ARM_Output.Both then
		-- Open only the one(s) needed:
	        case Output_Object.Change is
		    -- Note: Version is not used.
		    when ARM_Output.Insertion =>
			-- Open the deletion:
		        Buffer(Output_Object, '[');
		    when ARM_Output.Deletion =>
			-- Open the insertion:
		        Buffer(Output_Object, '{');
		    when ARM_Output.None =>
		        Buffer(Output_Object, '{');
		        Buffer(Output_Object, '[');
		    when ARM_Output.Both =>
		        null;
	        end case;
	    elsif Output_Object.Change = ARM_Output.Both then
		-- Close only the one(s) needed:
	        case Format.Change is
		    -- Note: Version is not used.
		    when ARM_Output.Insertion =>
			-- Close the deletion:
		        Buffer(Output_Object, ']');
		    when ARM_Output.Deletion =>
			-- Close the insertion:
		        Buffer(Output_Object, '}');
		    when ARM_Output.None =>
		        Buffer(Output_Object, ']');
		        Buffer(Output_Object, '}');
		    when ARM_Output.Both =>
		        null;
	        end case;
	    else -- Both can't get here.
	        case Output_Object.Change is
		    when ARM_Output.Insertion =>
		        Buffer(Output_Object, '}');
		    when ARM_Output.Deletion =>
		        Buffer(Output_Object, ']');
		    when ARM_Output.None =>
		        null;
		    when ARM_Output.Both =>
		        Buffer(Output_Object, ']');
		        Buffer(Output_Object, '}');
	        end case;
	        case Format.Change is
		    -- Note: Version is not used.
		    when ARM_Output.Insertion =>
		        Buffer(Output_Object, '{');
		    when ARM_Output.Deletion =>
		        Buffer(Output_Object, '[');
		    when ARM_Output.None =>
		        null;
		    when ARM_Output.Both =>
		        Buffer(Output_Object, '{');
		        Buffer(Output_Object, '[');
	        end case;
	    end if;
	    Output_Object.Change := Format.Change;
	end if;
	if ARM_Output."/=" (Format.Font, Output_Object.Font) then
	    case Format.Font is
		when ARM_Output.Default => null;
		when ARM_Output.Fixed =>
		    Buffer (Output_Object, "@fc<");
		when ARM_Output.Roman =>
		    Buffer (Output_Object, "@ft<");
		when ARM_Output.Swiss =>
		    Buffer (Output_Object, "@fa<");
	    end case;
	    Output_Object.Font := Format.Font;
	end if;

	if Format.Location /= Output_Object.Location then
	    case Format.Location is
		when ARM_Output.Superscript =>
		    --Buffer (Output_Object, "@+<");
		    null; -- Corrigendum doesn't support this.
		when ARM_Output.Subscript =>
		    --Buffer (Output_Object, "@+<");
		    null; -- Corrigendum doesn't support this.
		when ARM_Output.Normal =>
		    null;
	    end case;
	    Output_Object.Location := Format.Location;
	end if;

	if Format.Size /= Output_Object.Size then
	    if Format.Size < 0 then
		Buffer (Output_Object, "@s" & Character'Val(10+Format.Size+Character'Pos('0')) & '<');
	    else
		Buffer (Output_Object, "@s1" & Character'Val(Format.Size+Character'Pos('0')) & '<');
	    end if;
	    Output_Object.Size := Format.Size;
	end if;

	if Format.Italic and (not Output_Object.Is_Italic) then
	    Buffer (Output_Object, "@i<");
	    Output_Object.Is_Italic := True;
	end if;
	if Format.Bold and (not Output_Object.Is_Bold) then
	    Buffer (Output_Object, "@b<");
	    Output_Object.Is_Bold := True;
	end if;

    end Text_Format;


    procedure Clause_Reference (Output_Object : in out Corr_Output_Type;
				Text : in String;
				Clause_Number : in String) is
	-- Generate a reference to a clause in the standard. The text of
	-- the reference is "Text", and the number of the clause is
	-- Clause_Number. For hyperlinked formats, this should generate
	-- a link; for other formats, the text alone is generated.
    begin
	Ordinary_Text (Output_Object, Text); -- Nothing special in this format.
    end Clause_Reference;


    procedure Index_Target (Output_Object : in out Corr_Output_Type;
			    Index_Key : in Natural) is
	-- Generate a index target. This marks the location where an index
	-- reference occurs. Index_Key names the index item involved.
	-- For hyperlinked formats, this should generate a link target;
	-- for other formats, nothing is generated.
    begin
	if not Output_Object.Is_Valid then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not valid object");
	end if;
	if not Output_Object.Is_In_Paragraph then
	    Ada.Exceptions.Raise_Exception (ARM_Output.Not_Valid_Error'Identity,
		"Not in paragraph");
	end if;
	null; -- Nothing to do for plain text.
    end Index_Target;


    procedure Index_Reference (Output_Object : in out Corr_Output_Type;
			       Text : in String;
			       Index_Key : in Natural;
			       Clause_Number : in String) is
	-- Generate a reference to an index target in the standard. The text
	-- of the reference is "Text", and Index_Key and Clause_Number denotes
	-- the target. For hyperlinked formats, this should generate
	-- a link; for other formats, the text alone is generated.
    begin
	Ordinary_Text (Output_Object, Text); -- Nothing special in this format.
    end Index_Reference;


    procedure DR_Reference (Output_Object : in out Corr_Output_Type;
			    Text : in String;
			    DR_Number : in String) is
	-- Generate a reference to an DR from the standard. The text
	-- of the reference is "Text", and DR_Number denotes
	-- the target. For hyperlinked formats, this should generate
	-- a link; for other formats, the text alone is generated.
    begin
	Ordinary_Text (Output_Object, Text); -- Nothing special in this format.
    end DR_Reference;


    procedure AI_Reference (Output_Object : in out Corr_Output_Type;
			    Text : in String;
			    AI_Number : in String) is
	-- Generate a reference to an AI from the standard. The text
	-- of the reference is "Text", and AI_Number denotes
	-- the target (in unfolded format). For hyperlinked formats, this
	-- should generate a link; for other formats, the text alone is
	-- generated.
    begin
	Ordinary_Text (Output_Object, Text); -- Nothing special in this format.
    end AI_Reference;


    procedure Local_Target (Output_Object : in out Corr_Output_Type;
			    Text : in String;
			    Target : in String) is
	-- Generate a local target. This marks the potential target of local
	-- links identified by "Target". Text is the text of the target.
	-- For hyperlinked formats, this should generate a link target;
	-- for other formats, only the text is generated.
    begin
	Ordinary_Text (Output_Object, Text); -- Nothing special in this format.
    end Local_Target;


    procedure Local_Link (Output_Object : in out Corr_Output_Type;
			  Text : in String;
			  Target : in String;
			  Clause_Number : in String) is
	-- Generate a local link to the target and clause given.
	-- Text is the text of the link.
	-- For hyperlinked formats, this should generate a link;
	-- for other formats, only the text is generated.
    begin
	Ordinary_Text (Output_Object, Text); -- Nothing special in this format.
    end Local_Link;


    procedure Local_Link_Start (Output_Object : in out Corr_Output_Type;
				Target : in String;
				Clause_Number : in String) is
	-- Generate a local link to the target and clause given.
	-- The link will surround text until Local_Link_End is called.
	-- Local_Link_End must be called before this routine can be used again.
	-- For hyperlinked formats, this should generate a link;
	-- for other formats, only the text is generated.
    begin
	null; -- No link, nothing to do.
    end Local_Link_Start;


    procedure Local_Link_End (Output_Object : in out Corr_Output_Type;
			      Target : in String;
			      Clause_Number : in String) is
	-- End a local link for the target and clause given.
	-- This must be in the same paragraph as the Local_Link_Start.
	-- For hyperlinked formats, this should generate a link;
	-- for other formats, only the text is generated.
    begin
	null; -- No link, nothing to do.
    end Local_Link_End;


    procedure URL_Link (Output_Object : in out Corr_Output_Type;
			Text : in String;
			URL : in String) is
	-- Generate a link to the URL given.
	-- Text is the text of the link.
	-- For hyperlinked formats, this should generate a link;
	-- for other formats, only the text is generated.
    begin
	Ordinary_Text (Output_Object, Text); -- Nothing special in this format.
    end URL_Link;


    procedure Picture  (Output_Object : in out Corr_Output_Type;
			Name  : in String;
			Descr : in String;
			Alignment : in ARM_Output.Picture_Alignment;
			Height, Width : in Natural;
			Border : in ARM_Output.Border_Kind) is
	-- Generate a picture.
	-- Name is the (simple) file name of the picture; Descr is a
	-- descriptive name for the picture (it will appear in some web
	-- browsers).
	-- We assume that it is a .GIF or .JPG and that it will be present
	-- in the same directory as the input files and the same directory as
	-- the .HTML output files.
	-- Alignment specifies the picture alignment.
	-- Height and Width specify the picture size in pixels.
	-- Border specifies the kind of border.
    begin
	Ordinary_Text (Output_Object, "[Picture: " & Name &
	  " - " & Descr & "]");
    end Picture;

end ARM_Corr;
