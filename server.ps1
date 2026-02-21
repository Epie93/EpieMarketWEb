# Serveur HTTP simple avec PowerShell
$ports = @(8000, 8001, 8080)
$listener = New-Object System.Net.HttpListener
$port = $null

foreach ($p in $ports) {
    try {
        $url = "http://localhost:$p/"
        $listener.Prefixes.Clear()
        $listener.Prefixes.Add($url)
        $listener.Start()
        $port = $p
        break
    }
    catch {
        if ($_.Exception.Message -like "*conflit*" -or $_.Exception.Message -like "*conflict*") {
            Write-Host "[ATTENTION] Port $p occupe, essai suivant..." -ForegroundColor Yellow
        }
        else { throw }
    }
}

if (-not $port) {
    Write-Host "[ERREUR] Aucun port disponible (8000, 8001, 8080). Ferme l'autre instance." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Serveur demarre sur http://localhost:$port/" -ForegroundColor Green
Write-Host "[INFO] Fichiers depuis: $PSScriptRoot" -ForegroundColor Cyan
Start-Process "http://localhost:$port/"
Write-Host ""

function Get-MimeType {
    param([string]$filePath)
    $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
    $mimeTypes = @{
        '.html' = 'text/html; charset=utf-8'
        '.htm' = 'text/html; charset=utf-8'
        '.css' = 'text/css'
        '.js' = 'application/javascript'
        '.json' = 'application/json'
        '.png' = 'image/png'
        '.jpg' = 'image/jpeg'
        '.jpeg' = 'image/jpeg'
        '.gif' = 'image/gif'
        '.svg' = 'image/svg+xml'
        '.webp' = 'image/webp'
        '.ico' = 'image/x-icon'
        '.woff' = 'font/woff'
        '.woff2' = 'font/woff2'
        '.ttf' = 'font/ttf'
        '.eot' = 'application/vnd.ms-fontobject'
        '.xml' = 'application/xml'
        '.pdf' = 'application/pdf'
    }
    if ($mimeTypes.ContainsKey($extension)) {
        return $mimeTypes[$extension]
    }
    return 'application/octet-stream'
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $localPath = $request.Url.LocalPath
        if ($localPath -eq '/') {
            $localPath = '/index.html'
        }

        $filePath = Join-Path $PSScriptRoot $localPath.TrimStart('/')
        $filePath = [System.IO.Path]::GetFullPath($filePath)
        $rootPath = [System.IO.Path]::GetFullPath($PSScriptRoot)

        if (-not $filePath.StartsWith($rootPath)) {
            $response.StatusCode = 403
            $buffer = [System.Text.Encoding]::UTF8.GetBytes('403 Forbidden')
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = 'text/plain'
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        if (Test-Path $filePath -PathType Leaf) {
            try {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $content.Length
                $response.ContentType = Get-MimeType $filePath
                $response.StatusCode = 200
                $response.OutputStream.Write($content, 0, $content.Length)
                $fileName = [System.IO.Path]::GetFileName($filePath)
                Write-Host "[200] $localPath" -ForegroundColor Green
            }
            catch {
                $response.StatusCode = 500
                $buffer = [System.Text.Encoding]::UTF8.GetBytes('500 Internal Server Error')
                $response.ContentLength64 = $buffer.Length
                $response.ContentType = 'text/plain'
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "[500] Erreur $localPath" -ForegroundColor Red
            }
        }
        else {
            $response.StatusCode = 404
            $buffer = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = 'text/plain'
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            Write-Host "[404] $localPath" -ForegroundColor Yellow
        }

        $response.Close()
    }
}
finally {
    try {
        if ($listener -and $listener.IsListening) { $listener.Stop() }
    }
    catch { }
    Write-Host ""
    Write-Host "[INFO] Serveur arrete" -ForegroundColor Yellow
}
