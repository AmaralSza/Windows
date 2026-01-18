# Versão
Write-Host "Versão 1.4" -ForegroundColor Yellow

# --- FUNÇÃO PARA CONFIGURAR SENHA DO ANYDESK (Declarada no início para ser reconhecida) ---
function Set-AnyDeskPassword {
    param($senha)
    if (-not [string]::IsNullOrWhiteSpace($senha)) {
        Write-Host "Aguardando instalação finalizar para aplicar senha..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
        $anydeskPath = Get-ChildItem -Path "C:\Program Files*\AnyDesk\AnyDesk.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
        
        if ($anydeskPath) {
            Write-Host "Configurando senha do AnyDesk..." -ForegroundColor Yellow
            $senha | & $anydeskPath --set-password
            Write-Host "Senha do AnyDesk configurada!" -ForegroundColor Green
        }
    }
}

# 1. Limpeza e Preparação do Winget
Write-Host "Resetando fontes do Winget..." -ForegroundColor Yellow
winget source reset --force
winget source update

# Limpa processos que podem travar a instalação
Write-Host "Limpando instaladores parciais..." -ForegroundColor Yellow
Stop-Process -Name "AppInstallerPython" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Desativa as notificações do UAC
Write-Host "Desativando avisos do UAC..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0

# Configura o Explorador de Arquivos para abrir em 'Este Computador'
Write-Host "Configurando Explorador..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

# Desativa a Hibernação
powercfg /hibernate off

# 2. Solicita a senha para o AnyDesk
$senhaEntrada = Read-Host "Digite a senha do AnyDesk (ou Enter para pular)"

# 3. Instalação/Atualização dos Programas
Write-Host "Iniciando instalacoes via Winget..." -ForegroundColor Cyan

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
    winget upgrade --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -ne 0) {
        winget install --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent
    }

    # --- CHAMADA DA FUNÇÃO LOGO APÓS INSTALAR O ANYDESK ---
    if ($app -eq "AnyDesk.AnyDesk") {
        Set-AnyDeskPassword -senha $senhaEntrada
    }
}

Write-Host "Script finalizado com sucesso!" -ForegroundColor Green
pause