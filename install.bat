@echo off
REM F5 Virtual Server Exporter - Offline Installation Script
REM Supports Python 3.9, 3.10, 3.11, 3.12, 3.13 (32-bit and 64-bit)

echo ============================================================
echo F5 Virtual Server Exporter - Offline Installation
echo ============================================================
echo.

REM Check Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.9+ and add it to PATH
    pause
    exit /b 1
)

echo Python found:
python --version
echo.

REM Get Python version and architecture
for /f "tokens=2 delims= " %%a in ('python --version 2^>^&1') do set PYVER=%%a
for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set PYMAJOR=%%a
    set PYMINOR=%%b
)

REM Detect 32-bit vs 64-bit
python -c "import struct; exit(0 if struct.calcsize('P')*8==64 else 1)"
if errorlevel 1 (
    set PYARCH=win32
) else (
    set PYARCH=win_amd64
)

echo Detected: Python %PYMAJOR%.%PYMINOR% (%PYARCH%)
echo.

REM Upgrade pip first (from local wheel if available, otherwise skip)
echo Upgrading pip...
python -m pip install --upgrade pip >nul 2>&1

REM Install pure Python packages first
echo Installing dependencies...
echo.

echo [1/8] Installing six...
pip install --no-index --find-links=wheels --force-reinstall wheels\six-1.17.0-py2.py3-none-any.whl
if errorlevel 1 goto :error_six

echo [2/8] Installing certifi...
pip install --no-index --find-links=wheels --force-reinstall wheels\certifi-2026.1.4-py3-none-any.whl
if errorlevel 1 goto :error_certifi

echo [3/8] Installing idna...
pip install --no-index --find-links=wheels --force-reinstall wheels\idna-3.11-py3-none-any.whl
if errorlevel 1 goto :error_idna

echo [4/8] Installing urllib3...
pip install --no-index --find-links=wheels --force-reinstall wheels\urllib3-2.6.3-py3-none-any.whl
if errorlevel 1 goto :error_urllib3

echo [5/8] Installing charset_normalizer...
REM Build the wheel filename based on Python version
set CHARSET_WHEEL=wheels\charset_normalizer-3.4.4-cp%PYMAJOR%%PYMINOR%-cp%PYMAJOR%%PYMINOR%-%PYARCH%.whl

echo      Looking for: %CHARSET_WHEEL%
if exist %CHARSET_WHEEL% (
    pip install --no-index --force-reinstall %CHARSET_WHEEL%
    if errorlevel 1 goto :error_charset
) else (
    echo      Wheel not found, trying pip auto-select...
    pip install --no-index --find-links=wheels charset_normalizer
    if errorlevel 1 goto :error_charset
)

echo [6/8] Installing requests...
pip install --no-index --find-links=wheels --force-reinstall wheels\requests-2.32.5-py3-none-any.whl
if errorlevel 1 goto :error_requests

echo [7/8] Installing f5-icontrol-rest...
pip install --no-index --find-links=wheels --force-reinstall wheels\f5_icontrol_rest-1.3.13-py3-none-any.whl
if errorlevel 1 goto :error_f5icontrol

echo [8/8] Installing f5-sdk...
pip install --no-index --find-links=wheels --force-reinstall wheels\f5_sdk-3.0.21-py3-none-any.whl
if errorlevel 1 goto :error_f5sdk

echo.
echo ============================================================
echo Installation complete!
echo ============================================================
echo.
echo Verifying installation...
python -c "import requests; print('  requests: OK')"
python -c "from f5.bigip import ManagementRoot; print('  f5-sdk: OK')"
echo.
echo Next steps:
echo 1. Edit config.json with your F5 credentials and device list
echo 2. Test with: python F5_VS_Exporter.py -v
echo 3. Schedule in Windows Task Scheduler
echo.
pause
exit /b 0

:error_six
echo ERROR: Failed to install six
goto :error_end

:error_certifi
echo ERROR: Failed to install certifi
goto :error_end

:error_idna
echo ERROR: Failed to install idna
goto :error_end

:error_urllib3
echo ERROR: Failed to install urllib3
goto :error_end

:error_charset
echo ERROR: Failed to install charset_normalizer
echo.
echo Available wheels:
dir /b wheels\charset_normalizer*.whl
echo.
echo Your Python: %PYMAJOR%.%PYMINOR% (%PYARCH%)
echo Expected wheel: charset_normalizer-3.4.4-cp%PYMAJOR%%PYMINOR%-cp%PYMAJOR%%PYMINOR%-%PYARCH%.whl
goto :error_end

:error_requests
echo ERROR: Failed to install requests
goto :error_end

:error_f5icontrol
echo ERROR: Failed to install f5-icontrol-rest
goto :error_end

:error_f5sdk
echo ERROR: Failed to install f5-sdk
goto :error_end

:error_end
echo.
echo Installation failed. Please check the error above.
echo.
echo Debug info:
echo   Python version: %PYMAJOR%.%PYMINOR%
echo   Architecture: %PYARCH%
echo   Wheels directory:
dir /b wheels\
pause
exit /b 1
