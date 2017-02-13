
@echo on
set AUT2EXE="C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe"

mkdir build
%AUT2EXE% /in src\compare-data.au3 /out build\compare-data.exe /console
%AUT2EXE% /in src\scrape-datomatic.au3 /out build\scrape-datomatic.exe /console
%AUT2EXE% /in src\get-tgb-hashes.au3 /out build\get-tgb-hashes.exe /console
