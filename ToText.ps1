param(
    [Parameter(Mandatory=$true)]
    [string] $File
)
$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (!(Test-Path $File)) {
  throw "$File doesn't exist!"
}
if ([System.IO.Path]::GetExtension($File) -ne ".aac") {
  throw "expected extension .AAC"
}

$flac = [System.IO.Path]::GetFileNameWithoutExtension($File) + ".flac"

if (!(Test-Path $flac)) {
  echo "Converting $File to $flac..."
  ffmpeg -loglevel warning -i "$File" -ac 1 "$flac"
  # gCloud doesn't support AAC, so use FLAC format
  # Use one audio channel, as required by gCloud API
} else { 
  echo "$flac already exists"
}

$json = [System.IO.Path]::GetFileNameWithoutExtension($File) + ".json"

if (!(Test-Path $json)) {
  gcloud ml speech recognize-long-running --language-code en-US --format json --include-word-time-offsets "$flac" > $json
} else { 
  echo "$json already exists"
}

$j = gc -raw $json | ConvertFrom-Json

$txt = [System.IO.Path]::GetFileNameWithoutExtension($File) + " labels.txt"

$j.results.alternatives.words | % { "$($_.startTime -replace "s")`t$($_.endTime -replace "s")`t$($_.word)" } > $txt
