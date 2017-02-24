
#include 'lib/_XMLDomWrapper.au3'

;; http://www.sitesnes.com/dossiers/masterlist_snespal.htm
;; http://www.angelfire.com/games2/nessie/txt/esneslist2.txt
;; http://www.thegamersdungeon.com/2012/01/buying-nintendo-8-bit-nes-and-16-bit.html
;; http://forum.snesfreaks.com/viewtopic.php?f=164&t=10771

;; snes/nsrtlog.xml
;; /NSRT/Entry[Section[@type="Hashes"]/CRC32/text()="FFF8C139"]/Section[@type="Internal ROM Info"]/GameCode/text()

;; snes/datomatic.xml
;; /datafile/rom[@crc="F2EE11F9"]/@serial
;; <rom serial="SHVC-SA" region="Japan" file="2020 Super Baseball (Japan).sfc" md5="C9027B03A719A547CB2D9BCF9A9A6CBB" crc="E95A3DD7"/>

;; Nintendo - Super Nintendo Entertainment System Parent-Clone (20170205-061329).dat
;; <rom name="Super Sangokushi II (Japan).sfc" size="1048576" crc="0EEA5DC1" md5="A98570CC6F3651BCEA0E54D9CAB6BFD9" sha1="E58BB9C38B6BF2CE0C116E2BBEBD53746B6198AB" status="verified"/>

_SetDebug(False)

$xmlFile = 'Nintendo - Super Nintendo Entertainment System/Nintendo - Super Nintendo Entertainment System Parent-Clone (20170205-061329).dat'
_XMLFileOpen($xmlFile, '', -1, False)

Local $missing = 0
Local $missmatch = 0

Local $lineFormat = '| %-8s | %-17s | %-28s | %-13s | %-13s |'
_LogMessage(StringFormat($lineFormat, 'CRC', 'Region', 'No-Intro', 'NSRT', 'Byuu'))
_LogMessage(StringFormat($lineFormat, '--------', '-----------------', '----------------------------', '-------------', '-------------'))

Local $crcs = _XMLGetValue('//rom/@crc')
If @error == 0 Then

   For $i = 0 To $crcs[0]

	  _LogProgress($i)

	  $crc = $crcs[$i]

	  Local $md5, $sha1, $sha256

	  Local $serialA = ''
	  Local $serialB = ''
	  Local $serialC = ''

	  ;; START NSRT
	  $xmlFile = 'Nintendo - Super Nintendo Entertainment System/nsrtlog.xml'
	  _XMLFileOpen($xmlFile)
	  ;; Get other hashes
	  $nodes = _XMLGetValue('/NSRT/Entry[Section[@type="Hashes"]/CRC32/text()="' & $crc & '"]/Section[@type="Hashes"]/MD5/text()')
	  If @error == 0 Then
		 $md5 = $nodes[1]
	  EndIf
	  $nodes = _XMLGetValue('/NSRT/Entry[Section[@type="Hashes"]/CRC32/text()="' & $crc & '"]/Section[@type="Hashes"]/SHA-1/text()')
	  If @error == 0 Then
		 $sha1 = $nodes[1]
	  EndIf
	  $nodes = _XMLGetValue('/NSRT/Entry[Section[@type="Hashes"]/CRC32/text()="' & $crc & '"]/Section[@type="Hashes"]/SHA-256/text()')
	  If @error == 0 Then
		 $sha256 = $nodes[1]
	  EndIf
	  ;; Get code / serial
	  Local $code = '', $country = '', $video = ''
	  Local $nodes = _XMLGetValue('/NSRT/Entry[Section[@type="Hashes"]/CRC32/text()="' & $crc & '"]/Section[@type="Internal ROM Info"]/GameCode/text()')
	  If @error == 0 Then
		 $code = StringStripWS($nodes[1], 8)
	  EndIf
	  Local $nodes = _XMLGetValue('/NSRT/Entry[Section[@type="Hashes"]/CRC32/text()="' & $crc & '"]/Section[@type="Internal ROM Info"]/Country/text()')
	  If @error == 0 Then
		 $country = $nodes[1]
	  EndIf
	  Local $nodes = _XMLGetValue('/NSRT/Entry[Section[@type="Hashes"]/CRC32/text()="' & $crc & '"]/Section[@type="Internal ROM Info"]/Video/text()')
	  If @error == 0 Then
		 $video = $nodes[1]
	  EndIf
	  If $code <> '' Then
		 $serialB = CreateSerialFromCode($code, $country, $video)
	  EndIf
	  ;; END NSRT

	  ;; START No-Intro
	  $xmlFile = 'Nintendo - Super Nintendo Entertainment System/datomatic.xml'
	  _XMLFileOpen($xmlFile)
	  Local $serials = _XMLGetValue('/datafile/rom[@crc="' & $crc & '"]/@serial')
	  If @error == 0 Then
		 If $serials[0] > 1 Then
			If $serials[0] > 2 Or ( Not StringInStr($serials[1], $serials[2]) And Not StringInStr($serials[2], $serials[1]) ) Then
			   Local $msg = ''
			   For $j = 1 To $serials[0]
				  $msg &= $serials[$j] & ', '
			   Next
			   $msg = StringTrimRight($msg, 2)
			   _LogMessage(StringFormat($lineFormat, $crc, $country, $msg, $serialB, $serialC))
			EndIf
		 EndIf
		 $serialA = $serials[1]
	  EndIf
	  ;; END No-Intro

	  ;; START Byuu
	  $xmlFile = 'Nintendo - Super Nintendo Entertainment System/byuu.xml'
	  _XMLFileOpen($xmlFile)
	  Local $serials = _XMLGetValue('/datafile/rom[@sha256="' & StringLower($sha256) & '"]/@serial')
	  If @error == 0 Then
		 $serialC = $serials[1]
	  EndIf
	  ;; END Byuu


	  If $serialA == '' And $serialB == '' And $serialC == '' Then
		 $missing += 1
	  Else
		 If ( $serialA <> '' And $serialB <> '' And Not StringInStr($serialA, $serialB) ) _
			Or ( $serialB <> '' And $serialC <> '' And Not StringInStr($serialC, $serialB) ) _
			Or ( $serialA <> '' And $serialC <> '' And Not StringInStr($serialA, $serialC) ) _
			Then
			_LogMessage(StringFormat($lineFormat, $crc, $country, $serialA, $serialB, $serialC))
			$missmatch += 1
		 EndIf
	  EndIf

   Next

EndIf

_LogMessage('')
_LogMessage('Missmatch: ' & $missmatch & ', Missing: ' & $missing & ', Total: ' & $crcs[0])


Func CreateSerialFromCode($code, $country, $video)
   Switch $country
   Case "USA"
	  Return 'SNS-' & $code & '-USA'
   Case "Japan"
	  Return 'SHVC-' & $code
   Case "Germ/Aust/Switz"
	  Return 'SNSP-' & $code & '-FRG'
   Case "Euro/Asia/Oceania"
	  Return 'SNSP-' & $code ;& '-EUR'
   Case "France"
	  Return 'SNSP-' & $code & '-FRA'
   Case "Italy"
	  Return 'SNSP-' & $code & '-ITA'
   Case "Spain"
	  Return 'SNSP-' & $code & '-ESP'
   Case "Sweden"
   Case "Finland"
	  Return 'SNSP-' & $code & '-SCN'
   Case "The Netherlands"
	  Return 'SNSP-' & $code & '-HOL'
   Case "South Korea"
	  Return 'SNSP-' & $code & '-KOR'
   Case "Honk Kong/China"
	  Return 'SNSP-' & $code & '-HKV'
   Case "Unknown"
   Case Else
	  Switch $video
	  Case 'NTSC'
		 Return 'SNS-' & $code
	  Case 'PAL'
		 Return 'SNSP-' & $code
	  EndSwitch
   EndSwitch
   Return Null
EndFunc

Func _LogProgress($msg)
   ConsoleWrite('                                ')
   ConsoleWrite(@CR)
   ConsoleWrite($msg)
   ConsoleWrite(@CR)
EndFunc

Func _LogError($msg)
   ConsoleWriteError('ERROR: ' & $msg & @CRLF)
EndFunc

Func _LogWarning($msg)
   ConsoleWriteError('WARNING: ' & $msg & @CRLF)
EndFunc

Func _LogMessage($msg)
   ConsoleWrite($msg & @CRLF)
EndFunc