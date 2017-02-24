
#include <IE.au3>
#include <File.au3>
#Include 'lib/HTMLEncode.au3'
#Include 'lib/WinHttp.au3'
#Include 'lib/_XMLDomWrapper.au3'

;; http://www.sitesnes.com/dossiers/masterlist_superfamicom.htm
;; http://www.sitesnes.com/dossiers/masterlist_snespal.htm

Global $xmlFile = 'Nintendo - Super Nintendo Entertainment System\sitesnes.xml'
_SetDebug(False)
_XMLCreateFile($xmlFile, 'datafile', True)
_XMLFileOpen($xmlFile)

Local $url = 'http://www.sitesnes.com/dossiers/masterlist_snespal.htm'
Local $data = HttpGet($url)
$data = StringRegExpReplace($data, '<.*?>', '')
$data = _HTMLDecode($data)
$rows = StringRegExp($data, '(?m)^(.*?) \((.*?)\/(.*?)\/(.*?)\)$', 4)
For $i = 0 To UBound($rows) - 1
   Local $row = $rows[$i]
   Local $attrNames = ['name', 'publisher', 'year', 'serial', 'region']
   Local $attrVals = [$row[1], $row[2], $row[3], $row[4], 'Europe']
   _XMLCreateRootNodeWAttr('rom', $attrNames, $attrVals)
Next

Local $url = 'http://www.sitesnes.com/dossiers/masterlist_superfamicom.htm'
Local $data = HttpGet($url)
$data = StringRegExpReplace($data, '<.*?>', '')
$data = _HTMLDecode($data)
$rows = StringRegExp($data, '(?m)^(.*?) \((.*?)\/(.*?)\): (.*?)$', 4)
For $i = 0 To UBound($rows) - 1
   Local $row = $rows[$i]
   Local $attrNames = ['name', 'publisher', 'year', 'serial', 'region']
   Local $attrVals = [$row[1], $row[2], $row[3], $row[4], 'Japan']
   _XMLCreateRootNodeWAttr('rom', $attrNames, $attrVals)
Next
