# Solicita a senha (se deixar vazio, ele pula a configuração)
$senhaEntrada = Read-Host "Digite a senha do AnyDesk (ou pressione Enter para pular)"

# Inicia as instalações via Winget
Write-Host "Instalando programas..." -ForegroundColor Cyan
winget install --id AnyDeskSoftwareGmbH.AnyDesk -e --accept-source-agreements --accept-package-agreements
winget install --id Google.Chrome -e --accept-source-agreements --accept-package-agreements
winget install --id Mozilla.Firefox -e --accept-source-agreements --accept-package-agreements

# Só configura a senha se a variável não estiver vazia
if (-not [string]::IsNullOrWhiteSpace($senhaEntrada)) {
    Write-Host "Configurando senha do AnyDesk..." -ForegroundColor Yellow
    
    # Converte para o formato que o AnyDesk aceita
    $senhaTexto = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($senhaEntrada | ConvertTo-SecureString -AsPlainText -Force)))
    
    if (Test-Path "C:\Program Files (x86)\AnyDesk\AnyDesk.exe") {
        echo $senhaTexto | & "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --set-password
        Write-Host "Senha configurada!" -ForegroundColor Green
    }
} else {
    Write-Host "Nenhuma senha digitada. Pulando configuracao de acesso nao supervisionado." -ForegroundColor Gray
}

Write-Host "Processo concluido!" -ForegroundColor Green
pause