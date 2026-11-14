@echo off
:loop
git add .
git commit -m "Auto update"
git push
timeout /t 300 /nobreak
goto loop