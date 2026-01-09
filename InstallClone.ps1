# 1. Desativa as notificações do UAC (evita pop-ups de confirmação)
Write-Host "Desativando avisos do UAC..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0

# Configura o Explorador de Arquivos para abrir em 'Este Computador'
Write-Host "Configurando Explorador para abrir em 'Este Computador'..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

# 2. Solicita a senha para o AnyDesk
$senhaEntrada = Read-Host "Digite a senha do AnyDesk (ou Enter para pular)"

# 3. Instalação dos Programas (com todos os aceites automáticos)
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
    winget install --id $app -e --accept-source-agreements --accept-package-agreements --silent
}

# 4. Configura a senha do AnyDesk se foi digitada
if (-not [string]::IsNullOrWhiteSpace($senhaEntrada)) {
    $senhaTexto = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($senhaEntrada | ConvertTo-SecureString -AsPlainText -Force)))
    if (Test-Path "C:\Program Files (x86)\AnyDesk\AnyDesk.exe") {
        echo $senhaTexto | & "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --set-password
        Write-Host "Senha do AnyDesk configurada!" -ForegroundColor Green
    }
}

Write-Host "Tudo pronto!" -ForegroundColor Green
pause