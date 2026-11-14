@echo off
echo Looking for a process on port 11434...

set FOUND=0

for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":11434" ^| findstr "LISTENING"') do (
    echo Found process with PID %%P on port 11434, stopping it...
    taskkill /PID %%P /F
    set FOUND=1
)

if %FOUND%==0 (
    echo Nothing is listening on port 11434.
)

echo.
echo Also stopping any Ollama-related processes by name, just in case...
taskkill /IM "ollama.exe" /F >nul 2>&1
taskkill /IM "llama-server.exe" /F >nul 2>&1

echo.
echo Done. Port 11434 should now be free.
pause
