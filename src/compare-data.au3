
#include <File.au3>

Local $data = FileRead("snes\datomatic.csv")
$c = 0

$oXML = ObjCreate("Microsoft.XMLDOM")
$xml = FileRead("Nintendo - Super Nintendo Entertainment System (20170205-061329_RC).dat")
$oXML.loadxml($xml)
ConsoleWrite($oXML.parseError.reason & $oXML.parseError.line & @CR)
For $oRom in $oXML.selectNodes("//rom")
   $title = $oRom.getAttribute('name')
   $hash = $oRom.getAttribute('crc32')
   If Not StringInStr($data, $hash) Then
	  ConsoleWrite('Missing ' & $hash & ': ' & $title & @CR)
	  $c += 1
   EndIf
Next

ConsoleWrite('Missing ' & $c & ' total' & @CR)
