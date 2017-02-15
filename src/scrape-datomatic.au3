
#include <Constants.au3>
#include <String.au3>
#include <Math.au3>
#include <IE.au3>
#include <File.au3>
#Include "lib/Json.au3"
#Include "lib/Curl.au3"
#Include "lib/Request.au3"

Global $datomaticCsv = 'snes\datomatic.csv'
Global $htmlDir = 'datomatic\html\'

InitHTTP()
FetchHTML()
FetchPage('0441')
FetchPage('0841')
FetchPage('3656')

FileDelete($datomaticCsv)
FileWriteLine($datomaticCsv, '"Description","Media Serial","Region","File","Size","MD5","CRC32"')
Local $file
$files = _FileListToArray($htmlDir, '*', $FLTA_FILES)
For $i = 1 To $files[0]
   $file = $files[$i]
   $html = FileRead($htmlDir & $file)
   _ParseHTML($html)
   ConsoleWrite('Processed ' & $i & '/' & $files[0] & ' files' & @CR)
Next

FileDelete('cookie.txt')

Func InitHTTP()
   ;; Init HTTP session, do one request to get a PHPSESSID
   Local $Backup = RequestDefault('{agent: "AutoIt/Request", cookiefile: "cookie.txt", cookiejar: "cookie.txt", }')
   Local $Data = Request('http://datomatic.no-intro.org/')
EndFunc

Func FetchHTML()
   For $p = 0 To 17
	  ConsoleWrite('Page ' & $p & @CR)
	  ;; Do Search
	  $sPD = 'sel_s=Nintendo+-+Super+Nintendo+Entertainment+System&'
	  $sPD &= 'where=2&searchme=Search&pageSel=' & $p & '&element=Titles&sort=Name&order=Ascending'
	  Local $oReceived = Request('http://datomatic.no-intro.org/?page=search', $sPD)

	  ;; Get ID
	  $ids = StringRegExp($oReceived, '"?page=show_record&s=49&n=([0-9]{1,8})"', 3)
	  For $i = 0 To UBound($ids) - 1
		 FetchPage($ids[$i])
	  Next ; IDs loop
   Next
EndFunc

Func FetchPage($id)
   DirCreate($htmlDir)
   Local $htmlFile = $htmlDir & $id & '.html'
   If Not FileExists($htmlFile) Then
	  Local $html = Request('http://datomatic.no-intro.org/?page=show_record&s=49&n=' & $id)
	  ConsoleWrite($htmlFile & @CR)
	  FileWrite($htmlFile, $html)
   EndIf
EndFunc

Func _ParseHTML($html)
   Local $o_htmlfile = ObjCreate('HTMLFILE')
   If Not IsObj($o_htmlfile) Then Return SetError(-1)

   $o_htmlfile.open()
   $o_htmlfile.write($html)
   $o_htmlfile.close()

   Local $otrs = _IETagnameGetCollection($o_htmlfile, 'TR')
   If Not isobj($otrs) Then
	  Return SetError(-2)
   EndIf

   Local $entryBlock = False
   Local $prevBuffer = ''
   Local $buffer = ''
   Local $newArray[7]
   Local $array = $newArray
   Local $col = 0
   Local $nextIsDesc = False
   Local $description
   for $otr in $otrs
	  Local $otds = _IETagnameGetCollection($otr, 'TD')
	  if not isobj($otds) then return seterror(-3) EndIf
	  $valueStart = False
	  $trclass = StringStripWS($otr.classname, 3)
	  If $trclass == 'green' Or $trclass == 'orange' Or $trclass == 'red' Then
		 If StringLen($array[6]) > 0 Then
			$array[0] = $description
			For $s In $array
			   $buffer &= '"' & StringReplace($s, '"', '""') & '",'
			Next
			$buffer = StringTrimRight($buffer, 1)
			If $buffer <> $prevBuffer Or $prevBuffer == '' Then
			   FileWriteLine($datomaticCsv, $buffer)
			EndIf
			$prevBuffer = $buffer
			$buffer = ''
			$array = $newArray
		 EndIf
	  EndIf

	  If StringStripWS($otr.classname, 3) == 'romname_section' Then
		 $nextIsDesc = True
	  EndIf

	  for $otd in $otds
		 $text = StringStripWS($otd.innertext, 3)

		 If $nextIsDesc Then
			$description = $text
			$nextIsDesc = False
		 EndIf

		 If $entryBlock And $valueStart Then
			If $col == 1 Then
			   If StringLeft($text, 2) == 'M/' Then
				  $text = StringTrimLeft($text, 2)
			   EndIf
			   If StringRight($text, 2) == '-1' Then
				  $text = StringTrimRight($text, 2)
			   EndIf
			   If StringRight($text, 2) == '-2' Then
				  $text = StringTrimRight($text, 2)
			   EndIf
			   If StringLower($text) == 'unk' Then
				  $text = ''
			   EndIf
			EndIf
			$array[$col] = $text
			$valueStart = False
		 EndIf

		 Select
		 Case $text == 'Redumps'
			$entryBlock = True
		 Case $text == 'Dump sources'
			$entryBlock = True
		 Case $text == 'Media Serial:'
			$valueStart = True
			$col = 1
		 Case $text == 'Region:'
			$valueStart = True
			$col = 2
		 Case $text == 'File:'
			$valueStart = True
			$col = 3
		 Case $text == 'Size:'
			$valueStart = True
			$col = 4
		 Case $text == 'MD5:'
			$valueStart = True
			$col = 5
		 Case $text == 'CRC32:'
			$valueStart = True
			$col = 6
		 EndSelect

	  Next
   Next

   If StringLen($array[6]) > 0 Then
	  $array[0] = $description
	  For $s In $array
		 $buffer &= '"' & StringReplace($s, '"', '""') & '",'
	  Next
	  $buffer = StringTrimRight($buffer, 1)
	  If $buffer <> $prevBuffer Or $prevBuffer == "" Then
		 FileWriteLine($datomaticCsv, $buffer)
	  EndIf
	  $prevBuffer = $buffer
	  $buffer = ""
	  $array = $newArray
   EndIf

EndFunc

