# Função de cores
function Log ($msg) { Write-Host $msg -ForegroundColor Yellow }
function Log-Ok ($msg) { Write-Host $msg -ForegroundColor Green }
function Log-Info ($msg) { Write-Host $msg -ForegroundColor Cyan }

# Versão
Log "Binarius Tech - Soluções em Informática"
Log "Versão 1.21"

# --- FUNÇÃO PARA CONFIGURAR SENHA DO ANYDESK ---
function Set-AnyDeskPassword {
    param($senha)
    if (-not [string]::IsNullOrWhiteSpace($senha)) {
        Write-Host "Aguardando instalação finalizar..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
        $anydeskPath = Get-ChildItem -Path "C:\Program Files*\AnyDesk\AnyDesk.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
        
        if ($anydeskPath) {
            Log "Configurando senha do AnyDesk..."
            $senha | & $anydeskPath --set-password
            Log-Ok "Senha do AnyDesk configurada!"
        }
    }
}

Log "Verificando disponibilidade do Winget..."
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    
    Log "Winget nao encontrado. Instalando dependencias (WindowsAppRuntime)..."
    $ProgressPreference = 'SilentlyContinue'
    
    # 1. Instala o WindowsAppRuntime (Necessário para o erro 0x80073CF3)
    $depUrl = "https://aka.ms/windowsappsdk/1.6/1.6.241105002/windowsappruntimeinstall-x64.exe"
    Invoke-WebRequest -Uri $depUrl -OutFile "$env:TEMP\runtime.exe"
    Start-Process -FilePath "$env:TEMP\runtime.exe" -ArgumentList "--quiet" -Wait
    
    Log "Baixando instalador oficial do Winget..."
    $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\winget.msixbundle"
    
    Log "Instalando Winget..."
    Add-AppxPackage "$env:TEMP\winget.msixbundle"
    $ProgressPreference = 'Continue'
}

# 1. Limpeza e Preparação
Log "Resetando fontes do Winget..."
winget source reset --force
winget source update

# Limpa processos que podem travar a instalação
Log "Limpando instaladores parciais..."
Stop-Process -Name "AppInstallerPython" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Desativa as notificações do UAC
Log "Desativando avisos do UAC..."
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0

# Configura o Explorador de Arquivos para abrir em 'Este Computador'
Log "Configurando Explorador para o usuário real..."
# Descobre o SID do usuário logado no console
$userSID = (Get-WmiObject Win32_ComputerSystem).UserName
if ($userSID) {
    $userSID = (New-Object System.Security.Principal.NTAccount($userSID)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $regPath = "Registry::HKEY_USERS\$userSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "LaunchTo" -Value 1
        Log-Ok "Configuracao aplicada ao perfil do usuario logado."
    }
} else {
    # Fallback caso a detecção falhe (aplica no HKCU padrão)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
}

# --- CONFIGURAÇÕES DE ENERGIA E Hibernação
Log "Configurando Energia e Tampa..."
# Desativa a Hibernação
powercfg /hibernate off
# Nunca suspender (Tomada e Bateria)
powercfg /x -standby-timeout-ac 0
powercfg /x -standby-timeout-dc 0
# Fechar a tampa = Nada a fazer (Tomada e Bateria)
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
# Aplica as configurações
powercfg /s SCHEME_CURRENT

# --- PERGUNTA SOBRE A INSTALAÇÃO DO ANYDESK ---
$instalarAnyDesk = Read-Host "Deseja instalar o AnyDesk? (S/N)"
$senhaEntrada = ""
if ($instalarAnyDesk -match '^[SsYy]') {
    $senhaEntrada = Read-Host "Digite a senha do AnyDesk (ou Enter para pular)"
}

# 3. Instalação/Atualização dos Programas
Log-Info "Iniciando instalacoes via Winget..."

$apps = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "Adobe.Acrobat.Reader.64-bit",
    "RARLab.WinRAR"
)

# Adiciona o AnyDesk na lista caso o usuário tenha optado por instalar
if ($instalarAnyDesk -match '^[SsYy]') {
    $apps = @("AnyDesk.AnyDesk") + $apps
}

foreach ($app in $apps) {
    Write-Host "Processando: $app" -ForegroundColor White
    
    # Tenta Upgrade ou Install
    winget upgrade --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent --locale pt-BR
    if ($LASTEXITCODE -ne 0) {
        # Tenta instalar com locale
        winget install --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent --locale pt-BR

        # Se falhar, tenta sem o locale
        if (-not $?) {
            Log "Instalação com locale falhou. Tentando padrão..."
            winget install --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent
            
            # --- CORREÇÃO ESPECÍFICA PARA O GOOGLE CHROME (ERRO DE HASH) ---
            if ($LASTEXITCODE -ne 0 -and $app -eq "Google.Chrome") {
                Log "Winget falhou no hash do Chrome. Baixando instalador MSI direto do Google..."
                $chromeMsi = "$env:TEMP\chrome.msi"
                $progAntigo = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" -OutFile $chromeMsi
                $ProgressPreference = $progAntigo
                Start-Process msiexec.exe -ArgumentList "/i `"$chromeMsi`" /qn /norestart" -Wait
                Remove-Item $chromeMsi -Force -ErrorAction SilentlyContinue
                Log-Ok "Google Chrome instalado via MSI!"
            }
            # -------------------------------------------------------------
        }
    }

    # --- CHAMADA DA FUNÇÃO LOGO APÓS INSTALAR O ANYDESK ---
    if ($app -eq "AnyDesk.AnyDesk") {
        Set-AnyDeskPassword -senha $senhaEntrada
    }
}

Log-Ok "Script finalizado com sucesso!"
pause