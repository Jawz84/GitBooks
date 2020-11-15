[cmdletbinding()]
param(
    [ValidatePattern("^.+\.ipynb$")]
    [string]
    $NotebookFilePath 
)

$ErrorActionPreference = 'Stop'

# You'll need Anaconda3, and install nbconvert: via `conda install nbconvert`

if ($env:Path -notmatch "anaconda3") {
    $env:Path += ";${HOME}\anaconda3\Scripts"
}

$convertedFileName = $NotebookFilePath.Replace(".ipynb", ".md") 

jupyter nbconvert $NotebookFilePath --to markdown

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

# make sure headings get an empty line below them. 
# we only do this for headings with 2 #-signs or more, otherwise we would affect powershell comments too
$file = $file -replace "(?<=#{2,4} (\w\s?)*)`n", "`n`n"

# make sure the heading at the start of the file gets an empty line below it as well
$file = $file -replace "(?<=\A# (\w\s?)*)`n", "`n`n"

$condensedConvertedFileName = $convertedFileName.Replace(".md", ".condensed.md")

$file | Set-Content $condensedConvertedFileName -Force
Get-Content $condensedConvertedFileName
