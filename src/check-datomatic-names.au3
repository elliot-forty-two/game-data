
#include <Array.au3>
#include <String.au3>
#include 'lib/LibCsv2.au3'

Global $dataDir = 'snes\'
Global $datomaticCsv = $dataDir & 'datomatic.csv'

Global $idArr[1]

Local $csv = _CSVReadFile($datomaticCsv)
For $i=1 To UBound($csv) - 1

   ;; "Description","Media Serial","Region","File","Size","MD5","CRC32"

   $desc = $csv[$i][0]
   $file = $csv[$i][3]
   $size = $csv[$i][4]
   $crc32 = $csv[$i][6]
   $id = $size & StringRight($crc32, 6)
   If _ArraySearch($idArr, $id) == -1 Then
	  _ArrayAdd($idArr, $id)
	  ConsoleWrite(UBound($idArr) & @CR)
   Else
	  ConsoleWrite('ID collision: ' & $id & @CRLF)
   EndIf

   ContinueLoop

   If Not StringInStr($file, '(USA)') Then
	  ContinueLoop
   EndIf

   $name = StringTrimRight($file, 4)
   $name = StringRegExpReplace($name, '[\(\[].*[\)\]]', '')
   $name = StringStripWS($name, $STR_STRIPTRAILING)

   If StringInStr($name, ', The') Then
	  $name = 'The ' & StringReplace($name, ', The', '')
   EndIf
   If StringInStr($name, ', An') Then
	  $name = 'An ' & StringReplace($name, ', An', '')
   EndIf
   $name = StringReplace($name, ' - ', ': ')

   Local $short = $name
   If StringLen($short) > 32 Then
	  ;; Try just the sub-title
	  If StringInStr($short, ': ') Then
		 $arr = StringSplit($short, ': ', $STR_ENTIRESPLIT)
		 $short = $arr[$arr[0]]
	  EndIf
	  ;; Try removing duplicate words
	  If StringLen($short) > 32 Then
		 Local $c = 0
		 For $s In StringSplit($short, ' ')
			$c += StringLen($s) + 1
			If StringLen($s) > 3 And StringInStr($short, $s, 0, 1, $c) Then
			   $short = StringReplace($short, ' ' & $s, '', -1)
			EndIf
		 Next
	  EndIf
	  ;; Try removing on 'The '
	  If StringLen($short) > 32 And StringLeft($short, 4) == 'The ' Then
		 $short = StringMid($short, 4)
	  EndIf

	  If StringLen($short) <= 32 Then
		 ConsoleWrite($name & ' -> ' & $short & @CRLF)
	  EndIf
   EndIf
   If StringLen($short) > 32 Then
	  ConsoleWrite($name & ' -> ' & StringLeft($short, 31) & '...' & @CRLF)
   EndIf

   Local $long = $name
   If StringLen($long) > 64 Then
	  ConsoleWrite('WARNING: Long name > 64 chars' & @CRLF)
   EndIf
Next
