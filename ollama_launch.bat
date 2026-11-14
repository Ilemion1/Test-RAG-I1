@echo off
rem Служебный файл: запускает портативную Ollama и пишет весь её вывод
rem в ollama_log.txt рядом с этим файлом. Не запускайте его напрямую -
rem он вызывается автоматически из start_portable.bat через run_hidden.vbs.
cd /d "%~dp0"
"%~dp0ollama\ollama.exe" serve > "%~dp0ollama_log.txt" 2>&1
