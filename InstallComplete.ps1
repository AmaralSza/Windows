# 1. Limpeza e Preparação do Winget
Write-Host "Resetando fontes do Winget e desabilitando MSStore para evitar erros de certificado..." -ForegroundColor Yellow
# Força o uso apenas do repositório oficial do Winget para evitar o erro 0x8a15005e
winget source disable msstore
winget source reset --force
winget source update

# Limpa processos que podem travar a instalação
Write-Host "Limpando instaladores parciais..." -ForegroundColor Yellow
Stop-Process -Name "AppInstallerPython" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Desativa as notificações do UAC (evita pop-ups durante a instalação)
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
    
    # --id: usa o ID exato
    # -e: exige correspondência exata
    # --source winget: ignora a loja da Microsoft (MSStore)
    # --scope machine: instala para todos os usuários (evita erros de permissão)
    winget install --id $app -e --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent --locale pt-BR

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Aviso: Ocorreu um problema ao instalar $app, mas o script continuará." -ForegroundColor DarkYellow
    }
}

# Reativa a MSStore ao final (opcional, remova se preferir manter desativada)
winget source enable msstore

# 4. Configura a senha do AnyDesk se foi digitada
if (-not [string]::IsNullOrWhiteSpace($senhaEntrada)) {
    $anydeskPath = if (Test-Path "C:\Program Files (x86)\AnyDesk\AnyDesk.exe") { "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" } 
                   else { "C:\Program Files\AnyDesk\AnyDesk.exe" }

    if (Test-Path $anydeskPath) {
        Write-Host "Configurando senha do AnyDesk..." -ForegroundColor Yellow
        $senhaEntrada | & $anydeskPath --set-password
        Write-Host "Senha do AnyDesk configurada!" -ForegroundColor Green
    } else {
        Write-Host "AnyDesk não encontrado para configurar a senha." -ForegroundColor Red
    }
}

Write-Host "Tudo pronto!" -ForegroundColor Green
pause