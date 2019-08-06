#requires -Modules GoogleCloud

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")] # Intended to be used on console
param(
    [Parameter(Mandatory=$true)]
    [string] $File,
    [switch] $NoCache = $false
)
$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ($NoCache) {
  Write-Host -ForegroundColor DarkGray  "Skipping all cached values..."
}

if (!(Test-Path $File)) {
  throw "$File doesn't exist!"
}
$extension = [System.IO.Path]::GetExtension($File)
$supportedConversions = @(".aac", ".mp3")
if ($extension -eq ".flac") {
  $flac = $File
} elseif ($extension -in $supportedConversions) {
  $flac = [System.IO.Path]::GetFileNameWithoutExtension($File) + ".flac"

  if (!(Test-Path $flac) -or $NoCache) {
    Write-Host -ForegroundColor DarkGray  "Converting $File to $flac..."
    # gCloud doesn't support AAC, so use FLAC format
    # Use one audio channel, as required by gCloud API
    ffmpeg -loglevel warning -i "$File" -ac 1 "$flac"
  }
} else {
  throw "unsuported extension $extension"
}

$hash = (Get-FileHash -Path $flac -Algorithm "SHA256").Hash
$cloudFile = "temp_$hash.flac"
$gsPath = "gs://whythinkdata/$cloudFile"

if (!(Test-GcsObject -Bucket whythinkdata -ObjectName $cloudFile) -or $NoCache) {
  Write-Host -ForegroundColor DarkGray "Writing $flac to $gsPath"
  Write-GcsObject -Bucket whythinkdata -ObjectName $cloudFile -File $flac -Force
}

$json = [System.IO.Path]::GetFileNameWithoutExtension($File) + ".json"

if (!(Test-Path $json) -or $NoCache) {
  Write-Host -ForegroundColor DarkGray "Running gcloud ml speech"
  gcloud ml speech recognize-long-running --language-code en-US --format json --include-word-time-offsets "$gsPath" > $json
  if ($LASTEXITCODE -ne 0) {
    if ((get-item $json).Length -eq 0) {
      Remove-Item $json
    }
    throw "gcloud ml speech recognize-long-running failed!"
  }
}

$txt = [System.IO.Path]::GetFileNameWithoutExtension($File) + " labels.txt"

if (!(Test-Path $txt) -or $NoCache) {
  Write-Host -ForegroundColor DarkGray "Converting JSON to TXT labels"
  $j = gc -raw $json | ConvertFrom-Json
  $j.results.alternatives.words | % { "$($_.startTime -replace "s")`t$($_.endTime -replace "s")`t$($_.word)" } > $txt
}

echo "Results in `"$txt`""
