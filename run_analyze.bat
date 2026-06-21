@echo off
cd /d "D:\evo-os\apps\designwear"
flutter analyze > analyze_output.txt 2>&1
echo Exit code: %ERRORLEVEL% >> analyze_output.txt
echo Done. >> analyze_output.txt
