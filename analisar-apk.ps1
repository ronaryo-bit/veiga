# Analise local do APK Veiga Digital Play. Nenhum arquivo e enviado para a internet.
# Execute arrastando seu APK para executar_analise.bat.
param(
  [Parameter(Mandatory=$true,Position=0)][ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})][string]$ApkPath
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$apk=(Resolve-Path -LiteralPath $ApkPath).Path
if([IO.Path]::GetExtension($apk).ToLowerInvariant() -ne '.apk'){
  throw 'Selecione um arquivo APK.'
}
$base=Join-Path $env:USERPROFILE 'Documents\VeigaDigitalPlay'
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $base ('Inspecao-'+$stamp)
New-Item -ItemType Directory -Path $out -Force | Out-Null
$report=New-Object System.Collections.Generic.List[string]
$report.Add('VEIGA DIGITAL PLAY - DIAGNOSTICO DO APK')
$report.Add('Arquivo: '+[IO.Path]::GetFileName($apk))
$report.Add('Tamanho: '+(Get-Item -LiteralPath $apk).Length+' bytes')
$report.Add('SHA-256: '+(Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash)
$report.Add('Data: '+(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
$report.Add('')
$archive=[IO.Compression.ZipFile]::OpenRead($apk)
try{
  $entries=@($archive.Entries)
  $names=@($entries | ForEach-Object { $_.FullName })
  $report.Add('Arquivos internos: '+$entries.Count)
  $report.Add('DEX: '+(@($names | Where-Object {$_ -match '^classes\d*\.dex$'}).Count))
  $report.Add('Bibliotecas nativas: '+(@($names | Where-Object {$_ -match '^lib/[^/]+/[^/]+\.so$'}).Count))
  $report.Add('Possiveis arquivos de assinatura v1: '+(@($names | Where-Object {$_ -match '^META-INF/.*\.(RSA|DSA|EC)$'}).Count))
  $report.Add('')
  $report.Add('AVISO: assinaturas v2/v3 nao podem ser validadas apenas verificando o conteudo ZIP.')
  $report.Add('AVISO: nao e possivel recuperar a chave privada de assinatura do arquivo APK.')
  $report.Add('')
  $report.Add('Pasta de assets:')
  $names | Where-Object {$_ -match '^assets/'} | Select-Object -First 200 | ForEach-Object { $report.Add('  '+$_) }
  $report.Add('')
  $report.Add('Recursos de layouts:')
  $names | Where-Object {$_ -match '^res/(layout|drawable|mipmap|xml)/'} | Select-Object -First 200 | ForEach-Object {$report.Add('  '+$_)}
  $report.Add('')
  $report.Add('Principais bibliotecas:')
  $names | Where-Object {$_ -match '^lib/'} | Select-Object -First 150 | ForEach-Object {$report.Add('  '+$_)}
  $names | Set-Content -Path (Join-Path $out 'arquivos-internos.txt') -Encoding UTF8

  # Copia somente arquivos de interface legiveis, sem executar codigos no APK.
  $assetsOut=Join-Path $out 'assets-extraidos'
  New-Item -ItemType Directory -Path $assetsOut -Force | Out-Null
  $saved=0
  foreach($entry in $entries){
    $n=$entry.FullName
    if($n -notmatch '^assets/.+\.(html|htm|css|js|json|svg|xml|txt)$') { continue }
    if($entry.Length -gt 2097152){ continue }
    $relative=$n.Substring(7).Replace('/','\')
    $target=[IO.Path]::GetFullPath((Join-Path $assetsOut $relative))
    $root=[IO.Path]::GetFullPath($assetsOut)
    if(-not $target.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){continue}
    $dir=[IO.Path]::GetDirectoryName($target)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target,$true)
    $saved++
  }
  $report.Add('Assets de texto extraidos: '+$saved)
}finally{$archive.Dispose()}

function Write-ToolResult([string]$name,[string[]]$args,[string]$file){
  $cmd=Get-Command $name -ErrorAction SilentlyContinue
  if(!$cmd){
    $report.Add($name+': nao encontrado; etapa opcional nao realizada.')
    return
  }
  $report.Add($name+': '+$cmd.Source)
  try {
    & $cmd.Source @args 2>&1 | Out-String -Width 350 | Set-Content -Path $file -Encoding UTF8
    $report.Add($name+': verifique '+[IO.Path]::GetFileName($file))
  }catch{
    $report.Add($name+': falhou: '+$_.Exception.Message)
  }
}
Write-ToolResult 'aapt' @('dump','badging',$apk) (Join-Path $out 'manifesto-e-versao.txt')
Write-ToolResult 'apksigner' @('verify','--verbose','--print-certs',$apk) (Join-Path $out 'assinatura.txt')
if(Get-Command 'apktool' -ErrorAction SilentlyContinue){
  $report.Add('Decodificando resources e smali com Apktool...')
  try{
    & apktool d -f $apk -o (Join-Path $out 'apktool') 2>&1 | Out-String | Set-Content -Path (Join-Path $out 'apktool-log.txt')
    $report.Add('Apktool: verifique a pasta apktool.')
  }catch{$report.Add('Apktool: '+$_.Exception.Message)}
}
if(Get-Command 'jadx' -ErrorAction SilentlyContinue){
  $report.Add('Recuperando Java aproximado com JADX...')
  try{
    & jadx --no-res -d (Join-Path $out 'jadx') $apk 2>&1 | Out-String | Set-Content -Path (Join-Path $out 'jadx-log.txt')
    $report.Add('JADX: verifique a pasta jadx. Codigo nao equivale ao projeto fonte original.')
  }catch{$report.Add('JADX: '+$_.Exception.Message)}
}

# Ferramentas locais baixadas opcionalmente via preparar-ferramentas.ps1.
$toolDir=Join-Path $PSScriptRoot 'ferramentas'
$java=Get-Command 'java' -ErrorAction SilentlyContinue
$apkJar=Join-Path $toolDir 'apktool_3.0.3.jar'
$jadxBat=Join-Path $toolDir 'jadx\bin\jadx.bat'
if($java -and (Test-Path -LiteralPath $apkJar) -and !(Test-Path -LiteralPath (Join-Path $out 'apktool'))){
  $report.Add('Apktool oficial (jar): analisando recursos e smali...')
  try{
    & $java.Source -jar $apkJar d -f $apk -o (Join-Path $out 'apktool') 2>&1 | Out-String |
      Set-Content -Path (Join-Path $out 'apktool-log.txt')
  }catch{$report.Add('Apktool jar falhou: '+$_.Exception.Message)}
}
if((Test-Path -LiteralPath $jadxBat) -and !(Test-Path -LiteralPath (Join-Path $out 'jadx'))){
  $report.Add('JADX oficial: gerando Java aproximado...')
  try{
    & $jadxBat --no-res -d (Join-Path $out 'jadx') $apk 2>&1 | Out-String |
      Set-Content -Path (Join-Path $out 'jadx-log.txt')
  }catch{$report.Add('JADX falhou: '+$_.Exception.Message)}
}
$report.Add('')
$report.Add('PRIVACIDADE: o diagnostico pode conter URLs e tokens; revise antes de compartilhar.')
$report | Set-Content -Path (Join-Path $out 'RESUMO.txt') -Encoding UTF8
Write-Host ''
Write-Host 'ANALISE LOCAL CONCLUIDA' -ForegroundColor Green
Write-Host ('Pasta: '+$out)
Write-Host 'Abra RESUMO.txt para ver os resultados.'
