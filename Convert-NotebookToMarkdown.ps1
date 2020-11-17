[cmdletbinding()]
param(
    [ValidatePattern("^.+\.ipynb$")]
    [string]
    $NotebookFilePath 
)

$ErrorActionPreference = 'Stop'

$convertedFileName = $NotebookFilePath.Replace(".ipynb", ".md") 

# You'll need Anaconda3, and install nbconvert: via `conda install nbconvert`
# Anaconda Powershell console is needed to run jupyter commands safely.
# The Anaconda PowerShell console on windows does this under the hood:
# I only added the convert step, and changed the call to Powershell.exe to pwsh to make it faster.
$command = "& '${HOME}\anaconda3\shell\condabin\conda-hook.ps1' ;" + 
           "conda activate '${HOME}\anaconda3';" + 
           # This line is to actually convert the jupyter file, within the Anaconda Console
           "jupyter nbconvert $NotebookFilePath --to HTML"
pwsh -ExecutionPolicy ByPass -Command $command

$file = Get-Content $convertedFileName -Raw

# remove carriage returns, leave only newlines
$file = $file -replace "`r`n", "`n"

# iteratively replace double newlines by single newline
do {
    $oldFileLength = $file.Length
    $file = $file -Replace "`n`n", "`n"
} while ($file.Length -ne $oldFileLength)

# replace C# code fence tag by powershell
$file = $file -replace "``````C#`n#!pwsh", "`n``````powershell"

# put extra linebreak after code fence-end markings
$file = $file -replace "```````n", ("```````n`n")

# replace indented code block start with code fence of type text
$file = $file -replace "(?<=`n)`n\s{5}`n", "`n``````text`n"

# replace end of indented code block with code fence close
$file = $file -replace "`n(\s{5}`n)+", "`n```````n`n"

# make sure headings get an empty line above and below them. 
# we only do this for headings with 2 #-signs or more, otherwise we would affect powershell comments too
$file = $file -replace "(?<!`n)`n(?=##+ )", "`n`n"
$file = $file -replace "(?<=#{2,4} (\w\s?)*)`n", "`n`n"

# make sure the heading at the start of the file gets an empty line below it as well
$file = $file -replace "(?<=\A# (\w\s?)*)`n", "`n`n"

# add header
$file = $file -replace "\A#", @"
---
description: By Jos Koelewijn (@Jawz_84)
---

#
"@

# add footer
$file = $file -replace "`n\Z", @"
`n`nI hope you found this useful. Please feel free to reach out to me if you have questions. You can [ping me on Twitter](https://www.twitter.com/Jawz_84), or drop me a message on the PowerShell Discord server.`n`n
"@


$file | Set-Content $convertedFileName -Force
