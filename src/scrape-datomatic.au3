
#include <IE.au3>
#include <File.au3>
#Include 'lib/Json.au3'
#Include 'lib/Curl.au3'
#Include 'lib/Request.au3'
#Include 'lib/_XMLDomWrapper.au3'

;; name, id, pages, extras
Global $systems[][4] = [ _
	  ['Nintendo - Game Boy Advance', 23, 14, ''], _
	  ['Nintendo - Nintendo Entertainment System', 45, 13, ''], _
	  ['Nintendo - Game Boy', 46, 8, ''], _
	  ['Nintendo - Game Boy Color', 47, 7, ''], _
	  ['Nintendo - Super Nintendo Entertainment System', 49, 17, '0441,0841,3656'], _
	  ['Nintendo - Pokemon Mini', 14, 0, ''] _
   ]

_SetDebug(False)
_IEErrorNotify(False)

;; Init HTTP session, do one request to get a PHPSESSID
Local $Backup = RequestDefault('{agent: "AutoIt/Request", cookiefile: "cookie.txt", cookiejar: "cookie.txt", }')
Local $Data = Request('http://datomatic.no-intro.org/')

For $s = 0 To UBound($systems) - 1
   Local $sysName = $systems[$s][0]
   Local $sysId = $systems[$s][1]
   Local $sysPages = $systems[$s][2]
   Local $sysExtras = StringSplit($systems[$s][2], ',', 2)

   Local $htmlDir = $sysName & '\html\datomatic\'
   Local $xmlFile = $sysName & '\datomatic.xml'

   DirCreate($sysName)
   DirCreate($htmlDir)

   ClearLine()
   ConsoleWrite($sysName & @CRLF)

   _XMLCreateFile($xmlFile, 'datafile', True)
   _XMLFileOpen($xmlFile)

   ;; Fetch Pages
   For $p = 0 To $sysPages
	  ClearLine()
	  ConsoleWrite('Page ' & $p & @CR)
	  ;; Do Search
	  $sPD = 'sel_s=' & StringReplace($sysName, ' ', '+')
	  $sPD &= '&where=2&searchme=Search&pageSel=' & $p & '&element=Titles&sort=Name&order=Ascending'
	  Local $oReceived = Request('http://datomatic.no-intro.org/?page=search', $sPD)
	  ;; Get IDs
	  $ids = StringRegExp($oReceived, '"?page=show_record&s=' & $sysId & '&n=([0-9]{1,8})"', 3)
	  For $i = 0 To UBound($ids) - 1
		 FetchPage($sysId, $ids[$i])
	  Next ; IDs loop
   Next

   ;; Fetch extra pages
   For $p = 0 To UBound($sysExtras) - 1
	  FetchPage($sysId, $sysExtras[$p])
   Next ; IDs loop

   Local $file
   $files = _FileListToArray($htmlDir, '*', $FLTA_FILES)
   For $i = 1 To $files[0]
	  $file = $files[$i]
	  $html = FileRead($htmlDir & $file)
	  _ParseHTML($html)
	  ClearLine()
	  ConsoleWrite('Processed ' & $i & '/' & $files[0] & ' files' & @CR)
   Next

Next

FileDelete('cookie.txt')


;; Functions

Func ClearLine()
   ConsoleWrite('                                                                                                 ' & @CR)
EndFunc

Func FetchPage($sysId, $id)
   DirCreate($htmlDir)
   Local $htmlFile = $htmlDir & $id & '.html'
   If Not FileExists($htmlFile) Then
	  Local $html = Request('http://datomatic.no-intro.org/?page=show_record&s=' & $sysId & '&n=' & $id)
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
	  if not isobj($otds) then return seterror(-3)
	  $valueStart = False
	  $trclass = StringStripWS($otr.classname, 3)
	  If $trclass == 'green' Or $trclass == 'orange' Or $trclass == 'red' Then
		 If StringLen($array[6]) > 0 Then
			$array[0] = $description
			FlushBuffer($array)
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
;~ 				  $text = StringTrimRight($text, 2)
			   EndIf
			   If StringRight($text, 2) == '-2' Then
;~ 				  $text = StringTrimRight($text, 2)
			   EndIf
			   If StringLower($text) == 'none' Then
				  $text = ''
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
	  FlushBuffer($array)
	  $array = $newArray
   EndIf

EndFunc

Func FlushBuffer($array)
   _XMLFileOpen($xmlFile)
   _XMLGetPath('//rom[@crc="' & $array[6] & '" and @serial="' & $array[1] & '"]')
   If @error == 1 And StringLen($array[1]) > 0 Then
	  Local $attrNames = ['serial', 'region', 'file', 'md5', 'crc']
	  Local $attrValues = [$array[1], $array[2], $array[3], $array[5], $array[6]]
	  _XMLCreateRootNodeWAttr('rom', $attrNames, $attrValues)
   EndIf
EndFunc
