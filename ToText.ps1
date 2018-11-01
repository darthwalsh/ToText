param(
    [Parameter(Mandatory=$true)]
    [string] $File
)
$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (!(Test-Path $File)) {
  throw "$File doesn't exist!"
}
$extension = [System.IO.Path]::GetExtension($File)
if ($extension -eq ".flac") {
  $flac = $File
} elseif ($extension -eq ".aac") {
  $flac = [System.IO.Path]::GetFileNameWithoutExtension($File) + ".flac"
  
  if (!(Test-Path $flac)) {
    echo "Converting $File to $flac..."
    # gCloud doesn't support AAC, so use FLAC format
    # Use one audio channel, as required by gCloud API
    ffmpeg -loglevel warning -i "$File" -ac 1 "$flac"
  } else { 
    echo "$flac already exists, no need to convert"
  }
} else {
  throw "unsuported extension $extension"
}

$json = [System.IO.Path]::GetFileNameWithoutExtension($File) + ".json"

if (!(Test-Path $json)) {
  gcloud ml speech recognize-long-running --language-code en-US --format json --include-word-time-offsets "$flac" > $json
  if ($LASTEXITCODE -ne 0) {
    throw "gcloud ml speech recognize-long-running failed!"
    # TODO: Need to run i.e. gsutil cp TruncatedTest3.flac gs://whythinkdata/TruncatedTest3.flac
  }
} else { 
  echo "$json already exists"
}

$j = gc -raw $json | ConvertFrom-Json

$txt = [System.IO.Path]::GetFileNameWithoutExtension($File) + " labels.txt"

$j.results.alternatives.words | % { "$($_.startTime -replace "s")`t$($_.endTime -replace "s")`t$($_.word)" } > $txt

echo "Results in `"$txt`""
