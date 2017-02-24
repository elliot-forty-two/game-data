
#include <IE.au3>
#include <File.au3>
#Include 'lib/WinHttp.au3'
#Include 'lib/_XMLDomWrapper.au3'

Global $xmlFile = 'Nintendo - Super Nintendo Entertainment System\byuu.xml'

;~ _SetDebug(False)
_XMLCreateFile($xmlFile, 'datafile', True)
_XMLFileOpen($xmlFile)

_IEErrorNotify(False)

Local $regions[12] = ['KOR', 'CAN', 'ESP', 'EUR', 'FAH', 'FRA', 'FRG', 'ITA', 'LTN', 'NOE', 'UKV', 'USA']
For $i = 0 To UBound($regions) - 1
   Local $url = 'https://preservation.byuu.org/Super+Nintendo+%28' & $regions[$i] & '%29'
   Local $data = HttpGet($url)

   ConsoleWrite($regions[$i] & @CRLF)

   Local $o_htmlfile = ObjCreate('HTMLFILE')
   If Not IsObj($o_htmlfile) Then ContinueLoop

   $o_htmlfile.open()
   $o_htmlfile.write($data)
   $o_htmlfile.close()

   Local $otrs = _IETagnameGetCollection($o_htmlfile, 'TR')
   If Not isobj($otrs) Then ContinueLoop

   Local $k = 0
   for $otr in $otrs
	  Local $otds = _IETagnameGetCollection($otr, 'TD')
	  if not isobj($otds) then ContinueLoop

	  $k += 1
	  ConsoleWrite($k & @CR)

	  Local $array[6] = ['', '', '', '', '', '']
	  Local $j = 0

	  for $otd in $otds
		 $text = StringStripWS($otd.innertext, 3)
		 $array[$j] = $text
		 $j += 1
	  Next

	  If $array[0] <> '' Then
		 Local $attrNames = ['name', 'serial', 'revision', 'board', 'size', 'sha256']
		 _XMLCreateRootNodeWAttr('rom', $attrNames, $array)
	  EndIf

   Next ; TR

Next ; Region
