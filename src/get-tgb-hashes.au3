
#Include "lib/Json.au3"
#Include "lib/Curl.au3"
#Include "lib/Request.au3"
#Include "lib/LibCsv2.au3"

Local $hashesCsv = 'snes\thegamesdb-hashes.csv'
Local $backup = RequestDefault('{agent: "AutoIt/Request", }')

ConsoleWrite('Requesting hash.csv...' & @CRLF)
Local $data = Request('https://raw.githubusercontent.com/sselph/scraper/master/hash.csv')
Local $csv = _CSVRead($data)
FileDelete($hashesCsv)
For $i=0 To UBound($csv) - 1
   $sha1 =  $csv[$i][0]
   $gameId =  $csv[$i][1]
   $sysId =  $csv[$i][2]
   $name =  $csv[$i][3]
   If $sysId == 6 Then
	  $line = '"' & $sha1 & '","' & $gameId & '","' & $name & '"'
	  FileWriteLine($hashesCsv, $line)
   EndIf
   ConsoleWrite('Processed ' & $i & '/' & (UBound($csv) - 1) & ' rows' & @CR)
Next
