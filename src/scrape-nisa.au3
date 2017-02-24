
#NoTrayIcon

#include <File.au3>
#Include "lib/_XMLDomWrapper.au3"
#Include "lib/Json.au3"
#Include "lib/Curl.au3"
#Include "lib/Request.au3"
#Include "lib/LibCsv2.au3"
#Include "lib/_Dictionary.au3"

;; Systems
Global $systems[36][2] = [ _
	  [21, 'Nintendo - Game Boy'], _
	  [22, 'Nintendo - Game Boy Color'], _
	  [23, 'Nintendo - Game Boy Advance'], _
	  [24, 'Nintendo - Nintendo Entertainment System'], _
	  [25, 'Nintendo - Super Nintendo Entertainment System'], _
	  [19, 'Nintendo - Nintendo 64'], _
	  [20, 'Nintendo - Nintendo DS'], _
	  [26, 'Nintendo - Pokemon Mini'], _
	  [27, 'Nintendo - Virtual Boy'], _
	  [1, 'Atari 5200'], _
	  [2, 'Atari Lynx'], _
	  [3, 'Atari Jaguar'], _
	  [4, 'Bandai WonderSwan'], _
	  [5, 'Bandai WS Color'], _
	  [6, 'Coleco ColecoVision'], _
	  [12, 'Emerson Arcadia'], _
	  [13, 'Entex Adv. Vision'], _
	  [14, 'Fairchild Channel F'], _
	  [42, 'GamePark GP32'], _
	  [15, 'GCE Vectrex'], _
	  [43, 'Hartung Game Master'], _
	  [44, 'Magnavox Odyssey2'], _
	  [18, 'NEC PC Engine'], _
	  [39, 'NEC SuperGrafx'], _
	  [29, 'RCA Studio II'], _
	  [30, 'Sega GameGear'], _
	  [31, 'Sega Megadrive'], _
	  [40, 'Sega 32X'], _
	  [32, 'Sega Master System'], _
	  [33, 'Sega Game 1000'], _
	  [41, 'Sega PICO'], _
	  [34, 'SNK NeoGeo Pocket'], _
	  [35, 'SNK NG Pocket Color'], _
	  [36, 'Tiger Game.Com'], _
	  [37, 'Vtech Creativision'], _
	  [38, 'Watara Supervision'] _
   ]

;; Filters
Global $filters[] = ['1', 'ab', 'cd', 'ef', 'gh', 'ij', 'kl', 'mn', 'op', 'qr', 'st', 'uv', 'wx', 'yz']

;; Folders
Global $dataDir = 'data\'
Global $datDir = 'datsets\'
Global $nisaDir = 'nisa\'
Global $htmlDir = $nisaDir & 'html\'

DirCreate($dataDir)
DirCreate($datDir)
DirCreate($nisaDir)
DirCreate($htmlDir)

;; HTTP
Local $backup = RequestDefault('{agent: "AutoIt/Request", refer: "http://no-intro.dlgsoftware.net/", }')

;; Loop systems
For $i = 0 To UBound($systems) - 1
   Local $sysId = $systems[$i][0]
   Local $sysName = $systems[$i][1]

   _LogMessage('System ID: ' & $sysId)

   ;; Loop filters
   For $j = 0 To UBound($filters) - 1
	  Local $filter = $filters[$j]

	  _LogMessage('Filter: ' & $filter)

	  ;; Get page
	  Local $data
	  If FileExists($htmlDir & $sysId & '-' & $filter & '.html') Then
		 $data = FileRead($htmlDir & $sysId & '-' & $filter & '.html')
	  Else
		 $data = Request('http://no-intro.dlgsoftware.net/main.php?modulo=juegos&sistema=' & $sysId & '&lang=1&filtro=' & $filter)
		 If @extended == 200 Then
			FileWrite($htmlDir & $sysId & '-' & $filter & '.html', $data)
		 EndIf
	  EndIf

	  $ids = StringRegExp($data, "'ficha\.php\?id=([0-9]*)&lang=1'", 3)
	  For $k = 0 To UBound($ids) - 1
		 Local $gameId = $ids[$k]

		 _LogMessage('Game ID: ' & $gameId)

		 Local $data
		 If FileExists($htmlDir & $gameId & '.html') Then
			$data = FileRead($htmlDir & $gameId & '.html')
		 Else
			$data = Request('http://no-intro.dlgsoftware.net/ficha.php?id=' & $gameId & '&lang=1')
			FileWrite($htmlDir & $gameId & '.html', $data)
		 EndIf

;~ 		 $crc = StringRegExp($data, "<strong>ROM CRC : <\/strong>([0-9a-zA-Z]{8,8})<br\/><br\/>", 3)[0]

		 $imgs = StringRegExp($data, "'http:\/\/no-intro-archive\.dlgsoftware\.net\/(?:screenshots\/|getResizedImage\.php\?imagen=)(.*\/[0-9a-zA-Z]{8,8}\.(?:png|jpg|jpeg|gif))'", 3)
		 For $l = 0 To UBound($imgs) - 1
			Local $img = $imgs[$l]

			_LogMessage($img)

			If $img <> 'no_image.png' Then

			   Local $imgDir = $nisaDir & $sysName & '\' & StringSplit($img, '/')[2] & '\'
			   Local $imgFile = StringSplit($img, '/')[3]
			   DirCreate($imgDir)

			   If Not FileExists($imgDir & $imgFile) Then
				  Local $data = Request('http://no-intro-archive.dlgsoftware.net/screenshots/' & StringReplace($img, ' ', '%20'))
				  Local $returnCode = @extended
				  If $returnCode == 200 Then
					 FileWrite($imgDir & $imgFile, $data)
				  Else
					 _LogMessage('Request returned code ' & $returnCode)
				  EndIf
			   EndIf

			EndIf

		 Next
	  Next

   Next


Next



Func _LogMessage($msg)
   ConsoleWrite($msg & @CRLF)
EndFunc