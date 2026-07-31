param(
    [string]$RepositoryUrl = "https://github.com/gamurigm/inventrack-ptes-report"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$evidenceRoot = Join-Path $repoRoot "evidencias"
$target = Join-Path $repoRoot "anexos\anexo-a-mapa-evidencias.tex"

if (-not (Test-Path -LiteralPath $evidenceRoot)) {
    throw "No existe la carpeta de evidencias: $evidenceRoot"
}

function Get-Description([System.IO.FileInfo]$file) {
    switch ($file.Extension.ToLowerInvariant()) {
        ".txt" { return "Salida textual de comandos o respuestas." }
        ".md" { return "Documento de analisis o alcance." }
        ".html" { return "Reporte HTML generado por herramienta." }
        ".png" { return "Captura visual incorporada al informe." }
        ".xml" { return "Salida estructurada para trazabilidad." }
        ".nmap" { return "Resultado legible de Nmap." }
        ".gnmap" { return "Resultado grepable de Nmap." }
        default { return "Archivo tecnico de evidencia." }
    }
}

$files = Get-ChildItem -LiteralPath $evidenceRoot -Recurse -File |
    Where-Object {
        $_.Length -gt 0 -and
        $_.Name -ne "E04-" -and
        $_.Name -match "^[\x20-\x7E]+$"
    } |
    Sort-Object FullName

$builder = [System.Text.StringBuilder]::new()
[void]$builder.AppendLine("\chapter{Mapa de evidencias}")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("Las evidencias completas se encuentran en el repositorio publico:")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("\begin{center}")
[void]$builder.AppendLine("\href{$RepositoryUrl/tree/main/evidencias}{$RepositoryUrl/tree/main/evidencias}")
[void]$builder.AppendLine("\end{center}")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("Cada entrada presenta la ruta relativa exacta. Los enlaces abren el archivo correspondiente en GitHub. Se excluyen del mapa artefactos temporales vacios, incompletos o con nombres no portables; los archivos fuente no se alteran.")

$groups = $files | Group-Object {
    $relative = $_.DirectoryName.Substring($evidenceRoot.Length).TrimStart("\")
    if ([string]::IsNullOrWhiteSpace($relative)) {
        "raiz"
    }
    else {
        $relative.Replace("\", "/")
    }
}

foreach ($group in $groups) {
    [void]$builder.AppendLine("")
    $bookmarkName = $group.Name.Replace("_", " ")
    [void]$builder.AppendLine("\section{\texorpdfstring{\nolinkurl{$($group.Name)}}{$bookmarkName}}")
    [void]$builder.AppendLine("\begin{itemize}[leftmargin=1.2em]")

    foreach ($file in $group.Group) {
        $relative = $file.FullName.Substring($repoRoot.Length).TrimStart("\").Replace("\", "/")
        $url = "$RepositoryUrl/blob/main/$relative"
        $description = Get-Description $file

        [void]$builder.AppendLine("  \item \href{$url}{\nolinkurl{$relative}}\\")
        [void]$builder.AppendLine("  {\small $description}")
    }

    [void]$builder.AppendLine("\end{itemize}")
}

[System.IO.File]::WriteAllText(
    $target,
    $builder.ToString(),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Mapa generado con $($files.Count) archivos: $target"
