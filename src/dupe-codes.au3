
#include 'lib/_XMLDomWrapper.au3'
#Include "lib/_Dictionary.au3"

_SetDebug(False)

$xmlFile = '../snes/Nintendo - Super Nintendo Entertainment System Parent-Clone (20170205-061329).dat'
_XMLFileOpen($xmlFile)

$map = _InitDictionary()

Local $crcs = _XMLGetValue('//rom/@crc')
If @error == 0 Then
   For $i = 0 To $crcs[0]
	  Local $crc32 = $crcs[$i]
	  Local $code = StringRight($crc32, 6)
;~ 	  ConsoleWrite($i & @CR)
	  If _ItemExists($map, $code) Then
		 ConsoleWrite('Dupe: ' & $code & @CRLF)
	  Else
		 _AddItem($map, $code, $crc32)
	  EndIf
   Next
EndIf
