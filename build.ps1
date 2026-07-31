$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = Join-Path $repoRoot "output\pdf"
$tempDir = Join-Path $repoRoot "tmp\pdfs"
$jobName = "INFORME_FINAL_INVENTRACK_PTES"

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Push-Location $repoRoot
try {
    & latexmk `
        -xelatex `
        -interaction=nonstopmode `
        -file-line-error `
        -halt-on-error `
        "-jobname=$jobName" `
        "-outdir=$outputDir" `
        main.tex

    if ($LASTEXITCODE -ne 0) {
        throw "La compilacion LaTeX fallo con codigo $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

Write-Host "PDF generado: $outputDir\$jobName.pdf"
