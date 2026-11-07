$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://localhost:8765/')
$listener.Start()
Write-Output 'Serving on http://localhost:8765/'
while ($listener.IsListening) {
  $context = $listener.GetContext()
  try {
    $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }
    $path = Join-Path $root $relative
    if (Test-Path -LiteralPath $path -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($path)
      $context.Response.ContentType = switch ([System.IO.Path]::GetExtension($path)) {
        '.html' { 'text/html; charset=utf-8' }
        '.css' { 'text/css; charset=utf-8' }
        '.js' { 'application/javascript; charset=utf-8' }
        default { 'application/octet-stream' }
      }
      $context.Response.ContentLength64 = $bytes.Length
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $context.Response.StatusCode = 404
    }
  } catch {
    $context.Response.StatusCode = 500
  } finally {
    $context.Response.Close()
  }
}
