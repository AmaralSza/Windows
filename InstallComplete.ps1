# 1. Limpeza e Preparação do Winget
Write-Host "Resetando fontes do Winget para corrigir erros de certificado..." -ForegroundColor Yellow
winget source reset --force
winget source update

# Limpa processos que podem travar a instalação
Write-Host "Limpando instaladores parciais..." -ForegroundColor Yellow
Stop-Process -Name "AppInstallerPython" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Desativa as notificações do UAC
Write-Host "Desativando avisos do UAC..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0

# Configura o Explorador para abrir em 'Este Computador'
Write-Host "Configurando Explorador..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

# Desativa a Hibernação
powercfg /hibernate off

# 2. Solicita a senha para o AnyDesk
$senhaEntrada = Read-Host "Digite a senha do AnyDesk (ou Enter para pular)"

# 3. Instalação dos Programas
Write-Host "Iniciando instalacoes via Winget..." -ForegroundColor Cyan

# Lista simplificada para maior compatibilidade
$apps = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "AnyDeskSoftwareGmbH.AnyDesk",
    "Adobe.Acrobat.Reader.64-bit",
    "RARLab.WinRAR"
)

foreach ($app in $apps) {
    Write-Host "Instalando/Atualizando: $app" -ForegroundColor White
    
    # Removido --scope machine e --architecture para deixar o Winget decidir o melhor instalador
    # Mantido --source winget para evitar o erro de certificado da MS Store
    winget install --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent --upgrade --force

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Tentando instalar $app sem filtros de fonte..." -ForegroundColor Gray
        winget install --id $app -e --accept-source-agreements --accept-package-agreements --silent
    }
}

# 4. Configura a senha do AnyDesk
if (-not [string]::IsNullOrWhiteSpace($senhaEntrada)) {
    # Procura o executável em ambos os locais possíveis
    $anydeskPath = Get-ChildItem -Path "C:\Program Files*\AnyDesk\AnyDesk.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1

    if ($anydeskPath) {
        Write-Host "Configurando senha do AnyDesk em: $anydeskPath" -ForegroundColor Yellow
        $senhaEntrada | & $anydeskPath --set-password
        Write-Host "Senha do AnyDesk configurada!" -ForegroundColor Green
    }
}

Write-Host "Script finalizado!" -ForegroundColor Green
pause