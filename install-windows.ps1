# ============================================================
# install-windows.ps1 — Formation Ingenierie DevOps Open Source
# CapabilityForge / Tahar ARIB
#
# Prerequis : Windows 10/11 64 bits, 32 Go RAM minimum
# Executer en Admin :
#   powershell -ExecutionPolicy Bypass -File install-windows.ps1
# Executer une seule etape :
#   .\install-windows.ps1 -Step step_02
# ============================================================

param([string]$Step = "all")

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$msg)
    Write-Host "`n$msg" -ForegroundColor Cyan
}

function Write-OK {
    param([string]$msg)
    Write-Host "  ✓ $msg" -ForegroundColor Green
}

function Write-Warn {
    param([string]$msg)
    Write-Host "  ⚠ $msg" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$msg)
    Write-Host "  ✗ $msg" -ForegroundColor Red
}

# ────────────────────────────────────────────────
function step_01_install_chocolatey {
    Write-Step "[01/06] Installation Chocolatey..."

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-OK "Chocolatey deja installe ($(choco --version))"
        return
    }

    Write-Host "  → Telechargement et installation de Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Recharger PATH pour la session courante
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-OK "Chocolatey installe avec succes ($(choco --version))"
    } else {
        Write-Err "Echec de l'installation de Chocolatey. Relancer le script en tant qu'Administrateur."
        exit 1
    }
}

# ────────────────────────────────────────────────
function step_02_install_base_tools {
    Write-Step "[02/06] Outils de base (Git, VS Code, Windows Terminal)..."

    $tools = @(
        @{ Name = "git";              Check = "git --version" },
        @{ Name = "vscode";           Check = "code --version" },
        @{ Name = "windows-terminal"; Check = "wt --version" }
    )

    foreach ($t in $tools) {
        $cmdName = $t.Check.Split()[0]
        if (Get-Command $cmdName -ErrorAction SilentlyContinue) {
            $ver = (Invoke-Expression $t.Check 2>&1 | Select-Object -First 1)
            Write-OK "$($t.Name) deja installe ($ver)"
        } else {
            Write-Host "  → Installation de $($t.Name)..."
            choco install -y $t.Name
        }
    }
}

# ────────────────────────────────────────────────
function step_03_install_docker_desktop {
    Write-Step "[03/06] Docker Desktop..."

    # Verification via la presence du CLI docker
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-OK "Docker Desktop deja installe ($(docker --version))"
        return
    }

    Write-Host "  → Installation de Docker Desktop..."
    choco install -y docker-desktop

    Write-Warn "Un redemarrage Windows peut etre necessaire si c'est la premiere installation."
    Write-Warn "Apres redemarrage, lancer Docker Desktop manuellement et activer WSL2 backend dans Settings > General."
}

# ────────────────────────────────────────────────
function step_04_enable_wsl2 {
    Write-Step "[04/06] Activation WSL2 + Ubuntu 24.04..."

    # Verifier si Ubuntu 24.04 est deja installe (encodage-safe)
    $wslList = wsl --list 2>&1 | Out-String
    if ($wslList -match "Ubuntu") {
        Write-OK "WSL2 + Ubuntu 24.04 deja installes"
        # S assurer que Ubuntu est la distribution par defaut
        wsl --set-default Ubuntu-24.04 2>$null
        return
    }

    # Activer les fonctionnalites Windows requises
    Write-Host "  → Activation de la fonctionnalite Virtual Machine Platform..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    Write-Host "  → Activation de Windows Subsystem for Linux..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

    Write-Host "  → Installation de WSL2 + Ubuntu 24.04..."
    wsl --install -d Ubuntu-24.04

    Write-Warn "Un redemarrage Windows est requis pour finaliser WSL2."
    Write-Warn "Apres redemarrage, Ubuntu 24.04 se lancera automatiquement pour creer votre compte."
}

# ────────────────────────────────────────────────
function step_05_install_vscode_extensions {
    Write-Step "[05/06] Extensions VS Code..."

    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Err "VS Code non trouve. Executer d'abord step_02."
        return
    }

    # 10 extensions listees dans le programme de formation (Ch.2)
    $extensions = @(
        "ms-vscode-remote.remote-wsl",            # Remote - WSL
        "ms-azuretools.vscode-docker",             # Docker
        "ms-kubernetes-tools.vscode-kubernetes-tools", # Kubernetes
        "hashicorp.terraform",                     # OpenTofu / Terraform HCL
        "redhat.ansible",                          # Ansible
        "redhat.vscode-yaml",                      # YAML
        "eamodio.gitlens",                         # GitLens
        "SonarSource.sonarlint-vscode",            # SonarLint
        "GitHub.copilot",                          # GitHub Copilot
        "ms-vscode.makefile-tools"                 # Makefile Tools
    )

    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    foreach ($ext in $extensions) {
        Write-Host "  installe: $ext..."
        $result = & code --install-extension $ext --force 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -or $result -match "successfully installed|already installed") {
            Write-OK "$ext"
        } else {
            Write-Warn "$ext - verifier manuellement dans VS Code"
        }
    }

    $ErrorActionPreference = $prevPref
}

# ────────────────────────────────────────────────
function step_06_validate {
    Write-Step "[06/06] Validation de l'installation Windows..."

    $pass = 0
    $fail = 0

    function Check-Tool {
        param([string]$name, [string]$cmd)
        try {
            $result = Invoke-Expression $cmd 2>&1 | Select-Object -First 1
            Write-Host "  ✓ $name : $result" -ForegroundColor Green
            $script:pass++
        } catch {
            Write-Host "  ✗ $name — NON TROUVE" -ForegroundColor Red
            $script:fail++
        }
    }

    Check-Tool "Chocolatey"      "choco --version"
    Check-Tool "Git"             "git --version"
    Check-Tool "VS Code"         "code --version"
    Check-Tool "Docker"          "docker --version"
    Check-Tool "WSL2"            "wsl --version"

    Write-Host ""
    Write-Host "  Reussis : $pass / Echoues : $fail" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })

    if ($fail -gt 0) {
        Write-Warn "Relancer les etapes manquantes ou redemarrer Windows si WSL2/Docker viennent d'etre installes."
    } else {
        Write-OK "Environnement Windows pret. Lancer install-wsl2.sh dans Ubuntu 24.04."
    }
}

# ────────────────────────────────────────────────
# Dispatcher
# ────────────────────────────────────────────────
$allSteps = @("step_01_install_chocolatey",
              "step_02_install_base_tools",
              "step_03_install_docker_desktop",
              "step_04_enable_wsl2",
              "step_05_install_vscode_extensions",
              "step_06_validate")

if ($Step -eq "all") {
    foreach ($s in $allSteps) { & $s }
} elseif ($allSteps -contains $Step) {
    & $Step
} else {
    Write-Err "Etape inconnue : $Step"
    Write-Host "Etapes disponibles : $($allSteps -join ', ')"
    exit 1
}
