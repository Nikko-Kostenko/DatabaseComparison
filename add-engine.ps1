param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "status")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$TestRun = "run-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)

# Configuration
$BaseDir = $PSScriptRoot
$EngineScripts = @{
    "PostgreSQL" = Join-Path $BaseDir "postgres\postgres-manage.ps1"
    "MySQL" = Join-Path $BaseDir "mysql\mysql-manage.ps1"
    "MariaDB" = Join-Path $BaseDir "mariadb\mariadb-manage.ps1"
    "DB2" = Join-Path $BaseDir "db2\db2-manage.ps1"
}

$EngineVersions = @{
    "PostgreSQL" = "15.4"
    "MySQL" = "8.0"
    "MariaDB" = "10.11"
    "DB2" = "11.5.8.0"
}

function Start-AllEngines {
    param (
        [string]$TestRunId
    )
    
    Write-Host "Starting all database engines with test run ID: $TestRunId" -ForegroundColor Cyan
    Write-Host "------------------------------------------------" -ForegroundColor Cyan
    
    foreach ($engine in $EngineScripts.Keys) {
        $scriptPath = $EngineScripts[$engine]
        $version = $EngineVersions[$engine]
        
        if (Test-Path $scriptPath) {
            Write-Host "Starting $engine version $version..." -ForegroundColor Cyan
            & $scriptPath -Action start -Version $version -TestRun $TestRunId
            Write-Host "------------------------------------------------" -ForegroundColor Cyan
        } else {
            Write-Host "Script not found for $engine: $scriptPath" -ForegroundColor Red
        }
    }
    
    Write-Host "All engines started." -ForegroundColor Green
}

function Stop-AllEngines {
    Write-Host "Stopping all database engines..." -ForegroundColor Cyan
    Write-Host "------------------------------------------------" -ForegroundColor Cyan
    
    foreach ($engine in $EngineScripts.Keys) {
        $scriptPath = $EngineScripts[$engine]
        
        if (Test-Path $scriptPath) {
            Write-Host "Stopping $engine..." -ForegroundColor Cyan
            & $scriptPath -Action stop
            Write-Host "------------------------------------------------" -ForegroundColor Cyan
        } else {
            Write-Host "Script not found for $engine: $scriptPath" -ForegroundColor Red
        }
    }
    
    Write-Host "All engines stopped." -ForegroundColor Green
}

function Get-EngineStatus {
    Write-Host "Checking status of all database engines..." -ForegroundColor Cyan
    Write-Host "------------------------------------------------" -ForegroundColor Cyan
    
    foreach ($engine in $EngineScripts.Keys) {
        $version = $EngineVersions[$engine]
        $containerName = ($engine -replace "SQL", "sql").ToLower() + "-" + $version
        
        Write-Host "Checking $engine ($containerName)..." -ForegroundColor Cyan
        
        $container = docker ps -a --filter "name=$containerName" --format "{{.ID}}|{{.Status}}|{{.Ports}}"
        
        if ($container) {
            $containerInfo = $container -split "\|"
            $status = $containerInfo[1]
            $ports = $containerInfo[2]
            
            if ($status -match "Up") {
                Write-Host "  Status: RUNNING" -ForegroundColor Green
                Write-Host "  Details: $status" -ForegroundColor Cyan
                Write-Host "  Ports: $ports" -ForegroundColor Cyan
            } else {
                Write-Host "  Status: STOPPED" -ForegroundColor Yellow
                Write-Host "  Details: $status" -ForegroundColor Cyan
            }
        } else {
            Write-Host "  Status: NOT FOUND" -ForegroundColor Red
        }
        
        Write-Host "------------------------------------------------" -ForegroundColor Cyan
    }
}

# Main script execution
switch ($Action.ToLower()) {
    "start" {
        Start-AllEngines -TestRunId $TestRun
    }
    "stop" {
        Stop-AllEngines
    }
    "status" {
        Get-EngineStatus
    }
}