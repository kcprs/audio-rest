# Use SoX (http://sox.sourceforge.net/) to conform audio samples to the required format

# Make file extensions consistent
Get-ChildItem "*.aiff" | Rename-Item -NewName {$_.Name -replace ".aiff", ".aif"}

# Get all .aif files
$files = Get-ChildItem "*.aif"

foreach ($file in $files) {
    # Change bit depth to 16, sample rate to 44.1 kHz and only use the
    # left stereo channel. Normalise to -3 dBFS.
    $newName = $file.Name.Replace(".aif", ".wav").Replace(".stereo", "")
    sox --norm=-3 $file.Name -r 44100 -b 16 $newName remix 1
}