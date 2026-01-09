# 1. Solicita a senha ao usuário de forma segura
$promptSenha = Read-Host "Digite a senha para o acesso nao supervisionado do AnyDesk" -AsSecureString

# Converte a senha segura para texto simples para o AnyDesk entender
$senhaTexto = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($promptSenha))

# 2. Instalação dos Programas
Write-Host "Iniciando instalacoes..." -ForegroundColor Cyan

winget install --id AnyDeskSoftwareGmbH.AnyDesk -e --accept-package-agreements
winget install --id Google.Chrome -e
winget install --id Mozilla.Firefox -e

# 3. Configura a senha no AnyDesk usando a entrada do usuário
Write-Host "Configurando senha do AnyDesk..." -ForegroundColor Yellow

if (Test-Path "C:\Program Files (x86)\AnyDesk\AnyDesk.exe") {
    echo $senhaTexto | & "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --set-password
    Write-Host "Senha configurada com sucesso!" -ForegroundColor Green
} else {
    Write-Host "Erro: Executavel do AnyDesk nao encontrado para configurar a senha." -ForegroundColor Red
}

Write-Host "Processo concluido!" -ForegroundColor Green
pause