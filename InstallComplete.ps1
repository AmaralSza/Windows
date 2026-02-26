# Função de cores
function Log ($msg) { Write-Host $msg -ForegroundColor Yellow }
function Log-Ok ($msg) { Write-Host $msg -ForegroundColor Green }
function Log-Info ($msg) { Write-Host $msg -ForegroundColor Cyan }

# Versão
Log "Binarius Tech - Soluções em Informática"
Log "Versão 1.9"

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
Log "Configurando Explorador..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

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

# 2. Solicita a senha para o AnyDesk
$senhaEntrada = Read-Host "Digite a senha do AnyDesk (ou Enter para pular)"

# 3. Instalação/Atualização dos Programas
Log-Info "Iniciando instalacoes via Winget..."

$apps = @(
    "AnyDesk.AnyDesk",
    "Google.Chrome",
    "Mozilla.Firefox",
    "Adobe.Acrobat.Reader.64-bit",
    "RARLab.WinRAR"
)

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
    }
}

    # --- CHAMADA DA FUNÇÃO LOGO APÓS INSTALAR O ANYDESK ---
    if ($app -eq "AnyDesk.AnyDesk") {
        Set-AnyDeskPassword -senha $senhaEntrada
    }
}

Log-Ok "Script finalizado com sucesso!"
pause