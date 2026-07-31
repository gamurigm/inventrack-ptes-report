param(
    [string]$SourceReport = "..\..\evidencias\report\INFORME_FINAL.md"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$sourcePath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir $SourceReport))
$outputDir = Join-Path $repoRoot "secciones"
$pandoc = Join-Path $env:LOCALAPPDATA "Pandoc\pandoc.exe"

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "No existe el informe fuente: $sourcePath"
}

if (-not (Test-Path -LiteralPath $pandoc)) {
    $pandocCommand = Get-Command pandoc -ErrorAction SilentlyContinue
    if (-not $pandocCommand) {
        throw "Pandoc no esta instalado."
    }
    $pandoc = $pandocCommand.Source
}

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
$source = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8

$parts = [ordered]@{
    "01-contexto" = @("## Resumen Ejecutivo", "## Registro Completo de Comandos")
    "02-registro-comandos" = @("## Registro Completo de Comandos", "## Evidencias")
    "03-inventario-evidencias" = @("## Evidencias", "## G0 - Preparacion del Entorno")
    "04-despliegue-resultados" = @("## G0 - Preparacion del Entorno", "## Matriz de cobertura contra implement.md y plan PTES")
    "05-cobertura" = @("## Matriz de cobertura contra implement.md y plan PTES", "## PTES Fase 1 - Pre-engagement Interactions")
    "06-ptes-fases-1-a-3" = @("## PTES Fase 1 - Pre-engagement Interactions", "## PTES Fase 4 - Vulnerability Analysis")
    "07-ptes-fase-4" = @("## PTES Fase 4 - Vulnerability Analysis", "## PTES Fase 5 - Exploitation")
    "08-ptes-fase-5" = @("## PTES Fase 5 - Exploitation", "## PTES Fase 6 - Post-Exploitation")
    "09-ptes-fase-6" = @("## PTES Fase 6 - Post-Exploitation", "## PTES Fase 7 - Reporting")
}

foreach ($entry in $parts.GetEnumerator()) {
    $startMarker = $entry.Value[0]
    $endMarker = $entry.Value[1]
    if ($entry.Key -eq "09-ptes-fase-6") {
        $start = $source.LastIndexOf($startMarker, [StringComparison]::Ordinal)
    }
    else {
        $start = $source.IndexOf($startMarker, [StringComparison]::Ordinal)
    }
    $end = $source.IndexOf($endMarker, $start + $startMarker.Length, [StringComparison]::Ordinal)

    if ($start -lt 0 -or $end -lt 0) {
        throw "No se encontro el rango $startMarker -> $endMarker"
    }

    $markdown = $source.Substring($start, $end - $start).Trim()
    $tempMarkdown = Join-Path $env:TEMP ("inventrack-" + $entry.Key + ".md")
    $tempTex = Join-Path $env:TEMP ("inventrack-" + $entry.Key + ".tex")

    [System.IO.File]::WriteAllText(
        $tempMarkdown,
        $markdown,
        [System.Text.UTF8Encoding]::new($false)
    )

    & $pandoc --from=gfm --to=latex --wrap=none --syntax-highlighting=none --shift-heading-level-by=-1 --output=$tempTex $tempMarkdown

    if ($LASTEXITCODE -ne 0) {
        throw "Pandoc fallo al convertir $($entry.Key)"
    }

    $latex = Get-Content -LiteralPath $tempTex -Raw -Encoding UTF8
    $latex = $latex.Replace(
        "\begin{verbatim}",
        "\begin{tcolorbox}[codebox]" + [Environment]::NewLine + "\begin{Verbatim}[fontsize=\scriptsize,breaklines=true,breakanywhere=true]"
    )
    $latex = $latex.Replace(
        "\end{verbatim}",
        "\end{Verbatim}" + [Environment]::NewLine + "\end{tcolorbox}"
    )
    $latex = $latex.Replace("{img/", "{evidencias/report/img/")
    $latex = $latex.Replace(
        '\texttt{\{"status":"ok","resultado":2\}}',
        '\texttt{\{status: ok, resultado: 2\}}'
    )

    if ($entry.Key -eq "01-contexto") {

        $latex = $latex.Replace(
            "\begin{longtable}[]{@{}ll@{}}",
            "\captionof{table}{Activos incluidos en el alcance}\label{tab:activos-alcance}" + [Environment]::NewLine + "\begin{longtable}[]{@{}ll@{}}"
        )
    }

    if ($entry.Key -eq "03-inventario-evidencias") {

        $latex = $latex.Replace(
            "\begin{longtable}[]{@{}lllll@{}}",
            "\footnotesize" + [Environment]::NewLine + "\setlength{\tabcolsep}{3pt}" + [Environment]::NewLine + "\captionof{table}{Inventario maestro de evidencias}\label{tab:inventario-evidencias}" + [Environment]::NewLine + "\begin{longtable}[]{@{}>{\raggedright\arraybackslash}p{0.10\linewidth}>{\raggedright\arraybackslash}p{0.12\linewidth}>{\raggedright\arraybackslash}p{0.37\linewidth}>{\raggedright\arraybackslash}p{0.12\linewidth}>{\raggedright\arraybackslash}p{0.21\linewidth}@{}}"
        )
        $latex = $latex.Replace("/", "/\allowbreak{}")
        $latex = $latex.Replace("\_", "\_\allowbreak{}")
    }

    if ($entry.Key -eq "05-cobertura") {

        $latex = $latex.Replace(
            "\begin{longtable}[]{@{}lll@{}}",
            "\small" + [Environment]::NewLine + "\setlength{\tabcolsep}{3pt}" + [Environment]::NewLine + "\captionof{table}{Matriz de cobertura de requisitos y pruebas}\label{tab:matriz-cobertura}" + [Environment]::NewLine + "\begin{longtable}[]{@{}>{\raggedright\arraybackslash}p{0.39\linewidth}>{\raggedright\arraybackslash}p{0.17\linewidth}>{\raggedright\arraybackslash}p{0.36\linewidth}@{}}"
        )
    }

    $target = Join-Path $outputDir ($entry.Key + ".tex")
    [System.IO.File]::WriteAllText(
        $target,
        $latex,
        [System.Text.UTF8Encoding]::new($false)
    )

    Remove-Item -LiteralPath $tempMarkdown, $tempTex -Force
    Write-Host "Generado: $target"
}
