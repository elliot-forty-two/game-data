
@echo on

pushd %~dp0

build\get-tgb-hashes.exe

build\scrape-datomatic.exe

popd
