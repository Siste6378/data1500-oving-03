@echo off
REM ============================================================================
REM TEST-SKRIPT FOR OPPGAVE 1: Docker-oppsett og PostgreSQL-tilkobling
REM Windows CMD versjon
REM ============================================================================
REM
REM Bruk: 
REM   test-oppgave1.cmd
REM
REM eller åpne CMD og kjør:
REM   cd /d C:\path\to\data1500-oving-03
REM   test-oppgave1.cmd
REM
REM ============================================================================

setlocal enabledelayedexpansion

REM Farger (Windows CMD støtter ikke ANSI-farger direkte, så vi bruker tekst)
set "SUCCESS=[OK]"
set "ERROR=[FEIL]"
set "INFO=[INFO]"
set "HEADER=[TEST]"

echo.
echo ========================================
echo %HEADER% Oppgave 1 - Docker-oppsett
echo ========================================

REM Test 1: Docker er installert
echo.
echo %INFO% Test 1: Docker er installert
docker --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Docker ikke funnet. Installer Docker Desktop for Windows.
    exit /b 1
)
for /f "tokens=*" %%A in ('docker --version') do set "DOCKER_VERSION=%%A"
echo %SUCCESS% Docker funnet: %DOCKER_VERSION%

REM Test 2: docker-compose er installert
echo.
echo %INFO% Test 2: docker-compose er installert
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% docker-compose ikke funnet.
    exit /b 1
)
for /f "tokens=*" %%A in ('docker-compose --version') do set "DC_VERSION=%%A"
echo %SUCCESS% docker-compose funnet: %DC_VERSION%

REM Test 3: docker-compose.yml eksisterer
echo.
echo %INFO% Test 3: docker-compose.yml eksisterer
if not exist "docker-compose.yml" (
    echo %ERROR% docker-compose.yml ikke funnet
    exit /b 1
)
echo %SUCCESS% docker-compose.yml funnet

REM Test 4: Start PostgreSQL
echo.
echo %INFO% Test 4: Start PostgreSQL med docker-compose
docker-compose up -d >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Kunne ikke starte docker-compose
    exit /b 1
)
timeout /t 5 /nobreak >nul

REM Test 5: Verifiser at container kjører
echo.
echo %INFO% Test 5: Verifiser at PostgreSQL-container kjører
docker-compose ps | findstr "data1500-postgres.*Up" >nul 2>&1
if errorlevel 1 (
    echo %ERROR% PostgreSQL-container kjører ikke
    docker-compose logs
    exit /b 1
)
echo %SUCCESS% PostgreSQL-container kjører

REM Test 6: Verifiser database-tilkobling
echo.
echo %INFO% Test 6: Verifiser database-tilkobling
docker-compose exec -T postgres psql -U admin -d data1500_db -c "SELECT 1" >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Kunne ikke koble til PostgreSQL
    echo %INFO% Debugging info:
    docker-compose logs postgres
    exit /b 1
)
echo %SUCCESS% Tilkobling til PostgreSQL vellykket

REM Test 7: Verifiser at tabeller eksisterer
echo.
echo %INFO% Test 7: Verifiser at tabeller eksisterer
for /f "tokens=*" %%A in ('docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2^>nul') do set "TABLES=%%A"
set "TABLES=%TABLES: =%"
if "%TABLES%"=="" set "TABLES=0"
if %TABLES% gtr 0 (
    echo %SUCCESS% Tabeller funnet: %TABLES%
) else (
    echo %ERROR% Ingen tabeller funnet
    exit /b 1
)

REM Test 8: Verifiser testdata
echo.
echo %INFO% Test 8: Verifiser testdata
for /f "tokens=*" %%A in ('docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM studenter" 2^>nul') do set "STUDENT_COUNT=%%A"
for /f "tokens=*" %%A in ('docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM programmer" 2^>nul') do set "PROGRAM_COUNT=%%A"
for /f "tokens=*" %%A in ('docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM emner" 2^>nul') do set "EMNE_COUNT=%%A"

set "STUDENT_COUNT=%STUDENT_COUNT: =%"
set "PROGRAM_COUNT=%PROGRAM_COUNT: =%"
set "EMNE_COUNT=%EMNE_COUNT: =%"

if "%STUDENT_COUNT%"=="" set "STUDENT_COUNT=0"
if "%PROGRAM_COUNT%"=="" set "PROGRAM_COUNT=0"
if "%EMNE_COUNT%"=="" set "EMNE_COUNT=0"

if %STUDENT_COUNT% gtr 0 if %PROGRAM_COUNT% gtr 0 if %EMNE_COUNT% gtr 0 (
    echo %SUCCESS% Testdata lastet inn
    echo   - Studenter: %STUDENT_COUNT%
    echo   - Programmer: %PROGRAM_COUNT%
    echo   - Emner: %EMNE_COUNT%
) else (
    echo %ERROR% Testdata ikke lastet inn
    exit /b 1
)

REM Test 9: Verifiser roller
echo.
echo %INFO% Test 9: Verifiser roller
for /f "tokens=*" %%A in ('docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname IN ('admin_role', 'foreleser_role', 'student_role')" 2^>nul') do set "ROLES=%%A"
set "ROLES=%ROLES: =%"
if "%ROLES%"=="" set "ROLES=0"
if %ROLES% equ 3 (
    echo %SUCCESS% Alle roller opprettet
) else (
    echo %ERROR% Ikke alle roller funnet, funnet: %ROLES%
    exit /b 1
)

REM Test 10: Verifiser at foreleser kan koble til
echo.
echo %INFO% Test 10: Verifiser at foreleser_role kan koble til
docker-compose exec -T postgres psql -U foreleser_role -d data1500_db -c "SELECT 1" >nul 2>&1
if errorlevel 1 (
    echo %ERROR% foreleser_role kan ikke koble til
    exit /b 1
)
echo %SUCCESS% foreleser_role kan koble til

REM Test 11: Verifiser at student kan koble til
echo.
echo %INFO% Test 11: Verifiser at student_role kan koble til
docker-compose exec -T postgres psql -U student_role -d data1500_db -c "SELECT 1" >nul 2>&1
if errorlevel 1 (
    echo %ERROR% student_role kan ikke koble til
    exit /b 1
)
echo %SUCCESS% student_role kan koble til

REM Success
echo.
echo ========================================
echo %SUCCESS% ALLE TESTER BESTATT!
echo ========================================

REM Cleanup
echo.
echo %INFO% Stopper PostgreSQL...
docker-compose down >nul 2>&1
echo %SUCCESS% PostgreSQL stoppet

endlocal
exit /b 0
