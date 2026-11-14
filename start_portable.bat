@echo off
setlocal
cd /d "%~dp0"

rem Portable Ollama models folder (next to this bat file)
set OLLAMA_MODELS=%~dp0ollama_models

rem Ollama tries background calls to ollama.com (update checks, "model
rem recommendations") on startup. On a normal connection these fail fast and
rem are harmless. On some restricted networks (e.g. university Wi-Fi without
rem VPN) those packets are silently dropped instead of refused, so the OS
rem waits a long real network timeout before giving up - which can delay
rem Ollama's startup past our readiness check, even though the bot itself
rem never needs internet (everything runs through localhost:11434).
rem Fix: point HTTP(S)_PROXY at a local port nothing listens on, so any
rem external call fails instantly with "connection refused" instead of
rem hanging. NO_PROXY keeps local traffic (localhost:11434) unaffected.
set HTTP_PROXY=http://127.0.0.1:1
set HTTPS_PROXY=http://127.0.0.1:1
set NO_PROXY=127.0.0.1,localhost

rem WE_STARTED_OLLAMA=1 only if THIS script launched Ollama itself. If Ollama
rem was already running (e.g. the user's own separate install), we must not
rem kill it later when the bot is closed.
set WE_STARTED_OLLAMA=0

rem Check if Ollama is already running on port 11434.
rem Windows PowerShell 5.1's Invoke-RestMethod goes through the SYSTEM proxy
rem (Internet Options / WinINet) - a completely different mechanism from the
rem HTTP(S)_PROXY env vars above. On some networks (university Wi-Fi without
rem VPN) that system proxy doesn't bypass localhost correctly, which can make
rem a local loopback request hang/time out. We explicitly disable proxy use
rem for this call and query 127.0.0.1 directly (skipping "localhost" DNS).
powershell -Command "[System.Net.WebRequest]::DefaultWebProxy = $null; try { Invoke-RestMethod -Uri http://127.0.0.1:11434/api/tags -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo Ollama is already running.
    goto :start_bot
)

echo Starting portable Ollama (hidden, no console window)...
echo Ollama's own log will be written to ollama_log.txt
del "%~dp0ollama_log.txt" >nul 2>&1
set WE_STARTED_OLLAMA=1
wscript.exe "%~dp0run_hidden.vbs" "%~dp0ollama_launch.bat"

echo Waiting for Ollama to become ready...
set WAITED=0
:wait_loop
timeout /t 1 /nobreak >nul
powershell -Command "[System.Net.WebRequest]::DefaultWebProxy = $null; try { Invoke-RestMethod -Uri http://127.0.0.1:11434/api/tags -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel%==0 goto :models_check
set /a WAITED+=1
if %WAITED% GEQ 60 (
    echo [ERROR] Ollama is not responding on localhost:11434 after 60 seconds.
    echo See ollama_log.txt in this folder for details.
    pause
    exit /b 1
)
goto :wait_loop

:models_check
echo Checking that required models are present in ollama_models...
"%~dp0ollama\ollama.exe" list | findstr /C:"nomic-embed-text" >nul
if %errorlevel% neq 0 (
    echo Downloading nomic-embed-text into the portable models folder...
    "%~dp0ollama\ollama.exe" pull nomic-embed-text
)
"%~dp0ollama\ollama.exe" list | findstr /C:"qwen2.5:3b" >nul
if %errorlevel% neq 0 (
    echo Downloading qwen2.5:3b into the portable models folder...
    "%~dp0ollama\ollama.exe" pull qwen2.5:3b
)

:start_bot
echo.
echo Starting bot...
set AUTO_STOP_OLLAMA=%WE_STARTED_OLLAMA%
start "" "%~dp0KonspektBot\KonspektBot.exe"
