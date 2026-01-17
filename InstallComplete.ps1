# 1. Limpeza e Preparação
Write-Host "Resetando fontes do Winget para evitar erros de certificado..." -ForegroundColor Yellow
winget source reset --force
winget source update

# Desativa as notificações do UAC
Write-Host "Desativando avisos do UAC..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0

# Configura o Explorador de Arquivos para abrir em 'Este Computador'
Write-Host "Configurando Explorador para abrir em 'Este Computador'..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

# Desativa a Hibernação completamente
Write-Host "Desativando Hibernação..." -ForegroundColor Yellow
powercfg /hibernate off

# 2. Solicita a senha para o AnyDesk
$senhaEntrada = Read-Host "Digite a senha do AnyDesk (ou Enter para pular)"

# 3. Instalação dos Programas
Write-Host "Iniciando instalacoes via Winget..." -ForegroundColor Cyan

$apps = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "AnyDeskSoftwareGmbH.AnyDesk",
    "Adobe.Acrobat.Reader.64-bit",
    "RARLab.WinRAR"
)

foreach ($app in $apps) {
    Write-Host "Instalando: $app" -ForegroundColor White
    # Adicionado --source winget para ignorar a MS Store e evitar o erro 0x8a15005e
    winget install --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent --locale pt-BR
}

# 4. Configura a senha do AnyDesk se foi digitada
if (-not [string]::IsNullOrWhiteSpace($senhaEntrada)) {
    # Caminho comum do AnyDesk (pode ser x86 ou x64 dependendo da versão)
    $anydeskPath = if (Test-Path "C:\Program Files (x86)\AnyDesk\AnyDesk.exe") { "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" } 
                   else { "C:\Program Files\AnyDesk\AnyDesk.exe" }

    if (Test-Path $anydeskPath) {
        Write-Host "Configurando senha do AnyDesk..." -ForegroundColor Yellow
        echo $senhaEntrada | & $anydeskPath --set-password
        Write-Host "Senha do AnyDesk configurada!" -ForegroundColor Green
    }
}

Write-Host "Tudo pronto!" -ForegroundColor Green
pause