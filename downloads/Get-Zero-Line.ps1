param([ValidateSet('debug','release')][string]$Build='debug', [string]$Destination=(Join-Path $PSScriptRoot 'Zero-Line-Playtest'), [switch]$Launch)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$base='https://raw.githubusercontent.com/Raincantfocus/idk-man/zero-line-prototype/downloads/playable/'
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
$manifest=Invoke-RestMethod -Uri ($base+'manifest.json')
$entry=$manifest.$Build
$zip=Join-Path $Destination 'zero-line.zip'
$stream=[IO.File]::Create($zip)
try {
 foreach($part in $entry.parts) {
  $path=Join-Path $Destination $part.name
  Write-Host ('Downloading '+$part.name)
  Invoke-WebRequest -UseBasicParsing -Uri ($base+$part.name) -OutFile $path
  if((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower() -ne $part.sha256) {throw ('Checksum mismatch: '+$part.name)}
  $partStream=[IO.File]::OpenRead($path)
  try {$partStream.CopyTo($stream)} finally {$partStream.Dispose()}
 }
} finally {$stream.Dispose()}
if((Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLower() -ne $entry.zip_sha256) {throw 'Combined archive checksum mismatch'}
Expand-Archive -LiteralPath $zip -DestinationPath $Destination -Force
Write-Host ('Ready: '+(Join-Path $Destination 'zero-line.exe'))
if($Launch){Start-Process -FilePath (Join-Path $Destination 'zero-line.exe') -WorkingDirectory $Destination}
