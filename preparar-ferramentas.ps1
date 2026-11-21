# Download opcional de ferramentas oficiais para recuperar codigo e recursos.
# Nao envia o APK para nenhum servidor.
$ErrorActionPreference = 'Stop'
$dir=Join-Path $PSScriptRoot 'ferramentas'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$tools=@(
 @{
   Name='Apktool 3.0.3'
   Uri='https://github.com/iBotPeaches/Apktool/releases/download/v3.0.3/apktool_3.0.3.jar'
   File='apktool_3.0.3.jar'
   Sha='dbf930b076c6b9be08d57c449cacefc3bdd6b71ebd59b3066fc0e1f5b14f9423'
 },
 @{
   Name='JADX 1.5.7'
   Uri='https://github.com/skylot/jadx/releases/download/v1.5.7/jadx-1.5.7.zip'
   File='jadx-1.5.7.zip'
   Sha='1755e4242ade71a077438723689f404079592ec7764a3a0572f98fef94ebcbf3'
 }
)
foreach($tool in $tools){
 $dest=Join-Path $dir $tool.File
 $valid=$false
 if(Test-Path -LiteralPath $dest){
   $valid=([string](Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash).ToLowerInvariant() -eq $tool.Sha
 }
 if(!$valid){
   Write-Host ('Baixando '+$tool.Name+' do repositorio oficial...') -ForegroundColor Cyan
   [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
   Invoke-WebRequest -UseBasicParsing -Uri $tool.Uri -OutFile $dest
   $sum=([string](Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash).ToLowerInvariant()
   if($sum -ne $tool.Sha){Remove-Item -LiteralPath $dest -Force;throw ('SHA256 divergente: '+$tool.Name)}
 }
 Write-Host ('SHA256 verificado: '+$tool.Name) -ForegroundColor Green
}
$zip=Join-Path $dir 'jadx-1.5.7.zip'
$jadx=Join-Path $dir 'jadx'
if(!(Test-Path -LiteralPath (Join-Path $jadx 'bin\jadx.bat'))){
 Expand-Archive -LiteralPath $zip -DestinationPath $jadx -Force
}
if(!(Get-Command java -ErrorAction SilentlyContinue)){
 Write-Host 'AVISO: Java 17 ou superior nao localizado. Instale JDK antes da decompilacao.' -ForegroundColor Yellow
}else{
 Write-Host 'Java encontrado. Ferramentas prontas.' -ForegroundColor Green
}
