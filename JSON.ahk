; AHK v1
; Example ===================================================================================
; ===========================================================================================

; a := Object(), b := Object(), c := Object(), d := Object(), e := Object(), f := Object() ; Object() is more technically correct than {} but both will work.

; d["g"] := 1, d["h"] := 2, d["i"] := ["purple","pink","pippy red"]
; e["g"] := 1, e["h"] := 2, e["i"] := Object("1","test1","2","test2","3","test3")
; f["g"] := 1, f["h"] := 2, f["i"] := [1,2,Object("a",1.0009,"b",2.0003,"c",3.0001)]

; a["test1"] := "test11", a["d"] := d
; b["test3"] := "test33", b["e"] := e
; c["test5"] := "test55", c["f"] := ""

; myObj := Object()
; myObj["a"] := a, myObj["b"] := b, myObj["c"] := c, myObj["test7"] := "test77", myObj["test8"] := "test88"

; g := ["blue","green","red"], myObj["h"] := g ; add linear array for testing

; q := Chr(34)
; textData2 := Jxon_dump(myObj,4) ; ===> convert array to JSON
; msgbox % "XML Breakdown:`r`n===========================================`r`n(Should match second breakdown.)`r`n`r`n" textData2

; newObj := Jxon_load(textData2) ; ===> convert JSON back to array

; textData3 := Jxon_dump(newObj,4) ; ===> break down array into 2D layout again, should be identical
; msgbox % "Second Breakdown:`r`n===========================================`r`n(should be identical to first breakdown)`r`n`r`n" textData3

; ExitApp

; ===========================================================================================
; End Example ; =============================================================================
; ===========================================================================================

; originally posted by user coco on AutoHotkey.com
; https://github.com/cocobelgica/AutoHotkey-JSON

Jxon_Load(ByRef src, args*) {
	static q := Chr(34)
	
	key := "", is_key := false
	stack := [ tree := [] ]
	is_arr := Object(tree, 1) ; ahk v1                    ; orig -> is_arr := { (tree): 1 }
	next := q "{[01234567890-tfn"
	pos := 0
	
	while ( (ch := SubStr(src, ++pos, 1)) != "" ) {
		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch, true) {
			testArr := StrSplit(SubStr(src, 1, pos), "`n")
			ln := testArr.Length()
			
			col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

			msg := Format("{}: line {} col {} (char {})"
			,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
			  : (next == "'")     ? "Unterminated string starting at"
			  : (next == "\")     ? "Invalid \escape"
			  : (next == ":")     ? "Expecting ':' delimiter"
			  : (next == q)       ? "Expecting object key enclosed in double quotes"
			  : (next == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
			  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			  : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
			    , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
			, ln, col, pos)

			throw Exception(msg, -1, ch)
		}
		
		is_array := is_arr[obj := stack[1]] 
		
		if i := InStr("{[", ch) { ; start new object / map?
			val := (i = 1) ? Object() : Array()	; ahk v1
			
			is_array ? obj.Push(val) : obj[key] := val
			stack.InsertAt(1,val)
			
			is_arr[val] := !(is_key := ch == "{")
			next := q (is_key ? "}" : "{[]0123456789-tfn")
		} else if InStr("}]", ch) {
			stack.RemoveAt(1)
			next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
		} else if InStr(",:", ch) {
			is_key := (!is_array && ch == ",")
			next := is_key ? q : q "{[0123456789-tfn"
		} else { ; string | number | true | false | null
			if (ch == q) { ; string
				i := pos
				while i := InStr(src, q,, i+1) {
					val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
					if (SubStr(val, 0) != "\")
						break
				}
				if !i ? (pos--, next := "'") : 0
					continue

				pos := i ; update pos

				  val := StrReplace(val,    "\/",  "/")
				val := StrReplace(val, "\" . q,    q)
				, val := StrReplace(val,    "\b", "`b")
				, val := StrReplace(val,    "\f", "`f")
				, val := StrReplace(val,    "\n", "`n")
				, val := StrReplace(val,    "\r", "`r")
				, val := StrReplace(val,    "\t", "`t")

				i := 0
				while i := InStr(val, "\",, i+1) {
					if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
						continue 2

					xxxx := Abs("0x" . SubStr(val, i+2, 4)) ; \uXXXX - JSON unicode escape sequence
					if (A_IsUnicode || xxxx < 0x100)
						val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
				}
				
				if is_key {
					key := val, next := ":"
					continue
				}
			} else { ; number | true | false | null
				val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
				
				static number := "number", integer := "integer", float := "float"
				if val is %number%
				{
					if val is %integer%
						val += 0
					if val is %float%
						val += 0
					else if (val == "true" || val == "false")
						val := %val% + 0
					else if (val == "null")
						val := ""
					else if is_key {					; else if (pos--, next := "#")
						pos--, next := "#"					; continue
						continue
					}
				}
				
				pos += i-1
			}
			
			is_array ? obj.Push(val) : obj[key] := val
			next := obj == tree ? "" : is_array ? ",]" : ",}"
		}
	}
	
	return tree[1]
}

Jxon_Dump(obj, indent:="", lvl:=1) {
	static q := Chr(34), chunkType := ""
	
	if IsObject(obj) {
		is_array := 0
		for k in obj
			is_array := k == A_Index
		until !is_array
		memType := is_array ? "Array" : "Map"
		
		if (memType ? (memType != "Object" And memType != "Map" And memType != "Array") : (ObjGetCapacity(obj) == ""))
			throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))
		
		static integer := "integer"
		if indent is integer ; %integer%
		{
			if (indent < 0)
				throw Exception("Indent parameter must be a postive integer.", -1, indent)
			spaces := indent, indent := ""
			If (A_AhkVersion < 2) {
				Loop %spaces% ; ===> changed
					indent .= " "
			} Else {
				Loop spaces ; ===> changed
					indent .= " "
			}
		}
		indt := ""
		lpCount := indent ? lvl : 0
		Loop %lpCount%
			indt .= indent

		lvl += 1, out := "" ; Make #Warn happy
		for k, v in obj {
			if IsObject(k) || (k == "")
				throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
			
			if !is_array ;// key ; ObjGetCapacity([k], 1)
				chunkType := "key", out .= (ObjGetCapacity([k]) ? Jxon_Dump(k) : q k q) (indent ? ": " : ":") ; token + padding
			Else
                chunkType := "value" ; need to check when calling Jxon_Dump() internally, if chunkType is a key or value
			
            out .= Jxon_Dump(v, indent, lvl) ; value
				.  ( indent ? ",`n" . indt : "," ) ; token + indent
		}

		if (out != "") {
			out := Trim(out, ",`n" . indent)
			if (indent != "")
				out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
		}
		
		return is_array ? "[" . out . "]" : "{" . out . "}"
	} else { ; Number
		copyObj := obj + 0
        If (copyObj = obj And chunkType != "key")
			return obj
		Else {
            obj := StrReplace(obj,"\","\\")
			obj := StrReplace(obj,"`t","\t")
			obj := StrReplace(obj,"`r","\r")
			obj := StrReplace(obj,"`n","\n")
			obj := StrReplace(obj,"`b","\b")
			obj := StrReplace(obj,"`f","\f")
			obj := StrReplace(obj,"/","\/")
			obj := StrReplace(obj,q,"\" q)
			return q obj q
		}
	}
}