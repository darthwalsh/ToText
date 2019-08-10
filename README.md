# ToText

Script to wrap use google [speech-to-text](https://cloud.google.com/speech-to-text/) to give text overlay when editing in Audacity. 

## Install

You'll need powershell/pwsh and the GoogleCloud module. Also have ffmpeg and gcloud on the path.

You also want to create a GCS bucket called `whythinkdata`.

## Usage

For your audio file, run:

```powershell
.\ToText.ps1 "C:\Audio\Recording.mp3"
```

This will take a while, maybe half as long as your podcast. It will create a file `Recording.txt` in the same folder.

When it's done, in Audacity click File > Import > Labels and choose `C:\Audio\Recording.txt`.
