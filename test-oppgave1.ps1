# ============================================================================
# TEST-SKRIPT FOR OPPGAVE 1: Docker-oppsett og PostgreSQL-tilkobling
# Windows PowerShell versjon
# ============================================================================
# 
# Bruk: 
#   PowerShell -ExecutionPolicy Bypass -File test-oppgave1.ps1
# 
# eller åpne PowerShell og kjør:
#   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
#   .\test-oppgave1.ps1
#
# ============================================================================

# Farger for output
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$NC = "`e[0m"

# Hjelpefunksjoner
function Write-Success {
    param([string]$Message)
    Write-Host "$GREEN✓ $Message$NC"
}

function Write-Error {
    param([string]$Message)
    Write-Host "$RED✗ $Message$NC"
}

function Write-Info {
    param([string]$Message)
    Write-Host "$YELLOW$Message$NC"
}

function Write-Header {
    param([string]$Message)
    Write-Host "`n$YELLOW========================================$NC"
    Write-Host "$YELLOW$Message$NC"
    Write-Host "$YELLOW========================================$NC"
}

# Helper function to safely convert output to string and trim
function Get-TrimmedOutput {
    param([object]$Output)
    
    if ($Output -is [System.Management.Automation.ErrorRecord]) {
        return $Output.Exception.Message
    }
    
    if ($Output -is [array] -and $Output.Count -gt 0) {
        return ([string]$Output[0]).Trim()
    }
    
    return ([string]$Output).Trim()
}

# Start
Write-Header "TEST: Oppgave 1 - Docker-oppsett"

# Test 1: Docker er installert
Write-Info "`nTest 1: Docker er installert"
try {
    $dockerVersion = docker --version
    Write-Success "Docker funnet: $dockerVersion"
} catch {
    Write-Error "Docker ikke funnet. Installer Docker Desktop for Windows."
    exit 1
}

# Test 2: docker-compose er installert
Write-Info "`nTest 2: docker-compose er installert"
try {
    $dcVersion = docker-compose --version
    Write-Success "docker-compose funnet: $dcVersion"
} catch {
    Write-Error "docker-compose ikke funnet."
    exit 1
}

# Test 3: docker-compose.yml eksisterer
Write-Info "`nTest 3: docker-compose.yml eksisterer"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dockerComposeFile = Join-Path $scriptDir "docker-compose.yml"

if (Test-Path $dockerComposeFile) {
    Write-Success "docker-compose.yml funnet"
} else {
    Write-Error "docker-compose.yml ikke funnet"
    exit 1
}

# Test 4: Start PostgreSQL
Write-Info "`nTest 4: Start PostgreSQL med docker-compose"
Push-Location $scriptDir
try {
    docker-compose up -d 2>&1 | Out-Null
    Start-Sleep -Seconds 5
} catch {
    Write-Error "Kunne ikke starte docker-compose"
    exit 1
}

# Test 5: Verifiser at container kjører
Write-Info "`nTest 5: Verifiser at PostgreSQL-container kjører"
$psStatus = docker-compose ps 2>&1
if ($psStatus -match "data1500-postgres.*Up") {
    Write-Success "PostgreSQL-container kjører"
} else {
    Write-Error "PostgreSQL-container kjører ikke"
    docker-compose logs 2>&1
    exit 1
}

# Test 6: Verifiser database-tilkobling
Write-Info "`nTest 6: Verifiser database-tilkobling"
try {
    $result = docker-compose exec -T postgres psql -U admin -d data1500_db -c "SELECT 1" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Tilkobling til PostgreSQL vellykket"
    } else {
        Write-Error "Kunne ikke koble til PostgreSQL"
        Write-Info "Debugging info:"
        docker-compose logs postgres 2>&1
        exit 1
    }
} catch {
    Write-Error "Kunne ikke koble til PostgreSQL: $_"
    exit 1
}

# Test 7: Verifiser at tabeller eksisterer
Write-Info "`nTest 7: Verifiser at tabeller eksisterer"
try {
    $output = docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2>&1
    $tables = Get-TrimmedOutput $output
    
    if ([int]$tables -gt 0) {
        Write-Success "Tabeller funnet: $tables"
    } else {
        Write-Error "Ingen tabeller funnet"
        exit 1
    }
} catch {
    Write-Error "Kunne ikke verifisere tabeller: $_"
    exit 1
}

# Test 8: Verifiser testdata
Write-Info "`nTest 8: Verifiser testdata"
try {
    $studentOutput = docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM studenter" 2>&1
    $studentCount = Get-TrimmedOutput $studentOutput
    
    $programOutput = docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM programmer" 2>&1
    $programCount = Get-TrimmedOutput $programOutput
    
    $emneOutput = docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM emner" 2>&1
    $emneCount = Get-TrimmedOutput $emneOutput
    
    if ([int]$studentCount -gt 0 -and [int]$programCount -gt 0 -and [int]$emneCount -gt 0) {
        Write-Success "Testdata lastet inn"
        Write-Host "  - Studenter: $studentCount"
        Write-Host "  - Programmer: $programCount"
        Write-Host "  - Emner: $emneCount"
    } else {
        Write-Error "Testdata ikke lastet inn"
        exit 1
    }
} catch {
    Write-Error "Kunne ikke verifisere testdata: $_"
    exit 1
}

# Test 9: Verifiser roller
Write-Info "`nTest 9: Verifiser roller"
try {
    $rolesOutput = docker-compose exec -T postgres psql -U admin -d data1500_db -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname IN ('admin_role', 'foreleser_role', 'student_role')" 2>&1
    $roles = Get-TrimmedOutput $rolesOutput
    
    if ([int]$roles -eq 3) {
        Write-Success "Alle roller opprettet"
    } else {
        Write-Error "Ikke alle roller funnet (funnet: $roles)"
        exit 1
    }
} catch {
    Write-Error "Kunne ikke verifisere roller: $_"
    exit 1
}

# Test 10: Verifiser at foreleser kan koble til
Write-Info "`nTest 10: Verifiser at foreleser_role kan koble til"
try {
    $result = docker-compose exec -T postgres psql -U foreleser_role -d data1500_db -c "SELECT 1" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "foreleser_role kan koble til"
    } else {
        Write-Error "foreleser_role kan ikke koble til"
        exit 1
    }
} catch {
    Write-Error "Kunne ikke teste foreleser_role: $_"
    exit 1
}

# Test 11: Verifiser at student kan koble til
Write-Info "`nTest 11: Verifiser at student_role kan koble til"
try {
    $result = docker-compose exec -T postgres psql -U student_role -d data1500_db -c "SELECT 1" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "student_role kan koble til"
    } else {
        Write-Error "student_role kan ikke koble til"
        exit 1
    }
} catch {
    Write-Error "Kunne ikke teste student_role: $_"
    exit 1
}

# Success
Write-Host "`n$GREEN========================================$NC"
Write-Host "$GREEN✓ ALLE TESTER BESTÅTT!$NC"
Write-Host "$GREEN========================================$NC"

# Cleanup
Write-Info "`nStopper PostgreSQL..."
docker-compose down 2>&1 | Out-Null
Write-Success "PostgreSQL stoppet"

Pop-Location
