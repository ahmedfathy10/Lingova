@echo off
cd /d "%~dp0"

set "CODEX_NODE=%LOCALAPPDATA%\OpenAI\Codex\bin\node.exe"

if exist "%CODEX_NODE%" (
  "%CODEX_NODE%" server.js
) else (
  node server.js
)

pause
