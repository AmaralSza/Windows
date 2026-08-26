# --- DEFINIÇÃO DO ARQUIVO DE LOG ---
$LogPath = Join-Path -Path $PSScriptRoot -ChildPath "log.txt"

# Cria/Sobrescreve o arquivo no início da execução
"======================================================" | Out-File -FilePath $LogPath -Force -Encoding utf8
"Binarius Tech - Soluções em Informática - Instalação"   | Out-File -FilePath $LogPath -Append -Encoding utf8
"Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"    | Out-File -FilePath $LogPath -Append -Encoding utf8
"======================================================" | Out-File -FilePath $LogPath -Append -Encoding utf8

# --- FUNÇÕES DE CORES E LOG ---
function Write-CustomLog {
    param(
        [string]$msg,
        [string]$nivel = "INFO",
        [ConsoleColor]$color = [ConsoleColor]::White
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    "[$timestamp][$nivel] $msg" | Out-File -FilePath $LogPath -Append -Encoding utf8
    Write-Host $msg -ForegroundColor $color
}

function Log ($msg) { Write-CustomLog -msg $msg -nivel "INFO" -color Yellow }
function Log-Ok ($msg) { Write-CustomLog -msg $msg -nivel "SUCESSO" -color Green }
function Log-Info ($msg) { Write-CustomLog -msg $msg -nivel "AVISO" -color Cyan }
function Log-Err ($msg) { Write-CustomLog -msg $msg -nivel "ERRO" -color Red }

# Cabeçalho no Terminal
Clear-Host
Log "=========================================="
Log "Binarius Tech - Soluções em Informática"
Log "Versão 1.27"
Log "=========================================="

# --- FUNÇÃO PARA DOWNLOAD COM BARRA DE PROGRESSO VISUAL ---
function Download-ComProgresso {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$OutFile,
        [string]$Descricao = "Baixando arquivo..."
    )
    
    $webClient = New-Object System.Net.WebClient
    
    $eventHandler = {
        $percent = $EventArgs.ProgressPercentage
        $mbRecebidos = [Math]::Round($EventArgs.BytesReceived / 1MB, 2)
        $mbTotal = [Math]::Round($EventArgs.TotalBytesToReceive / 1MB, 2)
        
        if ($mbTotal -gt 0) {
            Write-Progress -Activity $Descricao -Status "$percent% concluído ($mbRecebidos MB de $mbTotal MB)" -PercentComplete $percent
        } else {
            Write-Progress -Activity $Descricao -Status "$mbRecebidos MB baixados" -PercentComplete -1
        }
    }
    
    Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action $eventHandler | Out-Null
    
    try {
        $webClient.DownloadFileAsync((New-Object System.Uri($Uri)), $OutFile)
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 100
        }
        Write-Progress -Activity $Descricao -Completed
        "Download concluído: $Uri -> $OutFile" | Out-File -FilePath $LogPath -Append -Encoding utf8
    } catch {
        "Erro no download de $Uri : $_" | Out-File -FilePath $LogPath -Append -Encoding utf8
    } finally {
        $webClient.Dispose()
        Get-EventSubscriber | Where-Object { $_.SourceObject -eq $webClient } | Unregister-Event
    }
}

# --- FUNÇÃO PARA CONFIGURAR SENHA DO ANYDESK ---
function Set-AnyDeskPassword {
    param($senha)
    if (-not [string]::IsNullOrWhiteSpace($senha)) {
        Start-Sleep -Seconds 5
        $anydeskPath = Get-ChildItem -Path "C:\Program Files*\AnyDesk\AnyDesk.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
        
        if ($anydeskPath) {
            Log "Configurando senha do AnyDesk..."
            $senha | & $anydeskPath --set-password *>> $LogPath
            Log-Ok "Senha do AnyDesk configurada!"
        }
    }
}

# --- VERIFICAÇÃO DO WINGET ---
Log "Verificando disponibilidade do Winget..."
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    
    Log "Winget nao encontrado. Instalando dependencias (WindowsAppRuntime)..."
    
    $depUrl = "https://aka.ms/windowsappsdk/1.6/1.6.241105002/windowsappruntimeinstall-x64.exe"
    Download-ComProgresso -Uri $depUrl -OutFile "$env:TEMP\runtime.exe" -Descricao "Baixando WindowsAppRuntime"
    Start-Process -FilePath "$env:TEMP\runtime.exe" -ArgumentList "--quiet" -Wait
    
    Log "Baixando instalador oficial do Winget..."
    $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Download-ComProgresso -Uri $url -OutFile "$env:TEMP\winget.msixbundle" -Descricao "Baixando Winget MSIXBundle"
    
    Log "Instalando Winget..."
    Add-AppxPackage "$env:TEMP\winget.msixbundle" *>> $LogPath
}

# --- LIMPEZA E PREPARAÇÃO ---
Log "Resetando fontes do Winget..."
winget source reset --force *>> $LogPath
winget source update *>> $LogPath

Log "Limpando processos parciais..."
Stop-Process -Name "AppInstallerPython" -ErrorAction SilentlyContinue *>> $LogPath
Start-Sleep -Seconds 2

# --- AJUSTES DO SISTEMA ---
Log "Desativando avisos do UAC..."
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 *>> $LogPath

Log "Configurando Explorador para o usuário real..."
$userSID = (Get-WmiObject Win32_ComputerSystem).UserName
if ($userSID) {
    $userSID = (New-Object System.Security.Principal.NTAccount($userSID)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $regPath = "Registry::HKEY_USERS\$userSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "LaunchTo" -Value 1 *>> $LogPath
        Log-Ok "Configuração do Explorador aplicada ao perfil do usuário."
    }
} else {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 *>> $LogPath
}

Log "Configurando Energia e Tampa..."
powercfg /hibernate off *>> $LogPath
powercfg /x -standby-timeout-ac 0 *>> $LogPath
powercfg /x -standby-timeout-dc 0 *>> $LogPath
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0 *>> $LogPath
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0 *>> $LogPath
powercfg /s SCHEME_CURRENT *>> $LogPath

# --- PERGUNTA SOBRE A INSTALAÇÃO DO ANYDESK ---
$instalarAnyDesk = Read-Host "Deseja instalar o AnyDesk? (S/N)"
$senhaEntrada = ""
if ($instalarAnyDesk -match '^[SsYy]') {
    $senhaEntrada = Read-Host "Digite a senha do AnyDesk (ou Enter para pular)"
}

# --- INSTALAÇÃO DOS PROGRAMAS ---
Log-Info "Iniciando instalacoes dos programas..."

$apps = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "Adobe.Acrobat.Reader.64-bit",
    "RARLab.WinRAR"
)

if ($instalarAnyDesk -match '^[SsYy]') {
    $apps = @("AnyDesk.AnyDesk") + $apps
}

foreach ($app in $apps) {
    Write-Host "`nProcessando: $app" -ForegroundColor White
    
    # Execução silenciosa no terminal com saída gravada no log.txt
    winget install --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent --locale pt-BR *>> $LogPath
    
    if ($LASTEXITCODE -eq 0) {
        Log-Ok "$app instalado com sucesso!"
    } else {
        winget install --id $app -e --source winget --accept-source-agreements --accept-package-agreements --silent *>> $LogPath
        
        if ($LASTEXITCODE -eq 0) {
            Log-Ok "$app instalado com sucesso!"
        } else {
            # Fallback direto do Google Chrome
            if ($app -eq "Google.Chrome") {
                Log "Winget falhou no hash do Chrome. Baixando MSI corporativo direto..."
                $chromeMsi = "$env:TEMP\chrome.msi"
                try {
                    Download-ComProgresso -Uri "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" -OutFile $chromeMsi -Descricao "Baixando Google Chrome (MSI)"
                    Start-Process msiexec.exe -ArgumentList "/i `"$chromeMsi`" /qn /norestart" -Wait
                    Remove-Item $chromeMsi -Force -ErrorAction SilentlyContinue
                    Log-Ok "Google Chrome instalado via MSI!"
                } catch {
                    Log-Err "Falha crítica ao instalar o Google Chrome via MSI."
                }
            } else {
                Log-Err "Erro ao instalar $app (Consulte log.txt para detalhes)."
            }
        }
    }

    if ($app -eq "AnyDesk.AnyDesk") {
        Set-AnyDeskPassword -senha $senhaEntrada
    }
}

Log-Ok "`nScript finalizado com sucesso! Detalhes salvos em: $LogPath"
pause