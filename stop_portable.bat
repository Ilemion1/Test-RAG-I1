@echo off
echo Stopping KonspektBot and portable Ollama...

taskkill /IM "KonspektBot.exe" /F >nul 2>&1
taskkill /IM "ollama.exe" /F >nul 2>&1

echo Done.
pause
