param(
  [int]$Port = 8787
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Web

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $Root "oura-config.json"
$TokenStorePath = Join-Path $Root "token-store.json"
$StateStorePath = Join-Path $Root "state-store.json"

function ConvertTo-PlainText([string]$CipherText) {
  if ([string]::IsNullOrWhiteSpace($CipherText)) { return $null }
  $secure = $CipherText | ConvertTo-SecureString
  $credential = New-Object System.Management.Automation.PSCredential("user", $secure)
  return $credential.GetNetworkCredential().Password
}

function Protect-Token([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
  return ConvertTo-SecureString -String $Value -AsPlainText -Force | ConvertFrom-SecureString
}

function Get-Config {
  if (-not (Test-Path $ConfigPath)) { return $null }
  $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
  if (-not $config.port) { $config | Add-Member -NotePropertyName port -NotePropertyValue $Port -Force }
  if (-not $config.apiBase) { $config | Add-Member -NotePropertyName apiBase -NotePropertyValue "https://api.ouraring.com" -Force }
  if (-not $config.scopes) { $config | Add-Member -NotePropertyName scopes -NotePropertyValue @("daily", "personal") -Force }
  return $config
}

function Get-TokenStore {
  if (-not (Test-Path $TokenStorePath)) { return $null }
  $raw = Get-Content $TokenStorePath -Raw | ConvertFrom-Json
  [PSCustomObject]@{
    accessToken = ConvertTo-PlainText $raw.accessToken
    refreshToken = ConvertTo-PlainText $raw.refreshToken
    expiresAt = $raw.expiresAt
    scope = $raw.scope
    tokenType = $raw.tokenType
    lastSync = $raw.lastSync
  }
}

function Save-TokenStore($TokenData) {
  $payload = [ordered]@{
    accessToken = Protect-Token $TokenData.accessToken
    refreshToken = Protect-Token $TokenData.refreshToken
    expiresAt = $TokenData.expiresAt
    scope = $TokenData.scope
    tokenType = $TokenData.tokenType
    lastSync = $TokenData.lastSync
  }
  ($payload | ConvertTo-Json) | Set-Content $TokenStorePath
}

function Clear-TokenStore {
  if (Test-Path $TokenStorePath) { Remove-Item $TokenStorePath -Force }
}

function Save-State($State) {
  @{ state = $State; createdAt = (Get-Date).ToUniversalTime().ToString("o") } | ConvertTo-Json | Set-Content $StateStorePath
}

function Get-State {
  if (-not (Test-Path $StateStorePath)) { return $null }
  return (Get-Content $StateStorePath -Raw | ConvertFrom-Json).state
}

function Clear-State {
  if (Test-Path $StateStorePath) { Remove-Item $StateStorePath -Force }
}

function New-Response($StatusCode, [string]$ContentType, [byte[]]$BodyBytes, $Headers) {
  return [PSCustomObject]@{
    StatusCode = $StatusCode
    ContentType = $ContentType
    BodyBytes = $BodyBytes
    Headers = $Headers
  }
}

function Get-StatusText([int]$StatusCode) {
  switch ($StatusCode) {
    200 { "OK" }
    302 { "Found" }
    400 { "Bad Request" }
    404 { "Not Found" }
    405 { "Method Not Allowed" }
    500 { "Internal Server Error" }
    default { "OK" }
  }
}

function ConvertTo-JsonResponse($StatusCode, $Payload) {
  $json = $Payload | ConvertTo-Json -Depth 8
  return New-Response $StatusCode "application/json; charset=utf-8" ([System.Text.Encoding]::UTF8.GetBytes($json)) @{}
}

function ConvertTo-HtmlResponse($StatusCode, [string]$Html) {
  return New-Response $StatusCode "text/html; charset=utf-8" ([System.Text.Encoding]::UTF8.GetBytes($Html)) @{}
}

function ConvertTo-RedirectResponse([string]$Location) {
  return New-Response 302 "text/plain; charset=utf-8" ([System.Text.Encoding]::UTF8.GetBytes("Redirecting...")) @{ Location = $Location }
}

function Write-HttpResponse($Client, $Response) {
  $stream = $Client.GetStream()
  $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII, 1024, $true)
  $writer.NewLine = "`r`n"
  $statusText = Get-StatusText $Response.StatusCode
  $writer.WriteLine("HTTP/1.1 $($Response.StatusCode) $statusText")
  $writer.WriteLine("Content-Type: $($Response.ContentType)")
  $writer.WriteLine("Content-Length: $($Response.BodyBytes.Length)")
  $writer.WriteLine("Connection: close")
  foreach ($header in $Response.Headers.GetEnumerator()) {
    $writer.WriteLine("$($header.Key): $($header.Value)")
  }
  $writer.WriteLine("")
  $writer.Flush()
  $stream.Write($Response.BodyBytes, 0, $Response.BodyBytes.Length)
  $stream.Flush()
}

function Get-ContentType([string]$Path) {
  switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    ".html" { "text/html; charset=utf-8" }
    ".js" { "application/javascript; charset=utf-8" }
    ".css" { "text/css; charset=utf-8" }
    ".json" { "application/json; charset=utf-8" }
    ".png" { "image/png" }
    ".jpg" { "image/jpeg" }
    ".jpeg" { "image/jpeg" }
    ".svg" { "image/svg+xml" }
    default { "application/octet-stream" }
  }
}

function Get-FileResponse([string]$RelativePath) {
  $sanitized = $RelativePath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
  if ([string]::IsNullOrWhiteSpace($sanitized)) { $sanitized = "index.html" }
  $fullPath = Join-Path $Root $sanitized
  if (-not (Test-Path $fullPath)) {
    return ConvertTo-JsonResponse 404 @{ error = "Not found" }
  }
  $bytes = [System.IO.File]::ReadAllBytes($fullPath)
  return New-Response 200 (Get-ContentType $fullPath) $bytes @{}
}

function Invoke-OuraTokenRequest($Config, $FormValues) {
  $body = @{}
  foreach ($key in $FormValues.Keys) { $body[$key] = $FormValues[$key] }
  $body.client_id = $Config.clientId
  $body.client_secret = $Config.clientSecret
  Invoke-RestMethod -Method Post -Uri "https://api.ouraring.com/oauth/token" -ContentType "application/x-www-form-urlencoded" -Body $body
}

function Save-TokenResponse($TokenResponse) {
  $tokenData = [PSCustomObject]@{
    accessToken = $TokenResponse.access_token
    refreshToken = $TokenResponse.refresh_token
    expiresAt = (Get-Date).ToUniversalTime().AddSeconds([int]$TokenResponse.expires_in).ToString("o")
    scope = $TokenResponse.scope
    tokenType = $TokenResponse.token_type
    lastSync = (Get-TokenStore).lastSync
  }
  Save-TokenStore $tokenData
  return $tokenData
}

function Get-ValidAccessToken($Config) {
  $token = Get-TokenStore
  if (-not $token) { throw "No Oura token is stored yet. Connect Oura first." }
  if (-not $token.expiresAt) { return $token.accessToken }

  $expiresAt = [datetime]::Parse($token.expiresAt).ToUniversalTime()
  if ($expiresAt -gt (Get-Date).ToUniversalTime().AddMinutes(2)) {
    return $token.accessToken
  }
  if (-not $token.refreshToken) {
    throw "Stored Oura token has expired and no refresh token is available. Reconnect Oura."
  }

  $refreshed = Invoke-OuraTokenRequest $Config @{
    grant_type = "refresh_token"
    refresh_token = $token.refreshToken
  }
  return (Save-TokenResponse $refreshed).accessToken
}

function Invoke-OuraApi($Config, [string]$Path, $Query) {
  $token = Get-ValidAccessToken $Config
  $queryString = ""
  if ($Query) {
    $pairs = foreach ($key in $Query.Keys) {
      if ($null -ne $Query[$key] -and "$($Query[$key])" -ne "") {
        "{0}={1}" -f [System.Web.HttpUtility]::UrlEncode($key), [System.Web.HttpUtility]::UrlEncode([string]$Query[$key])
      }
    }
    $queryString = ($pairs | Where-Object { $_ }) -join "&"
  }
  $uri = "$($Config.apiBase)$Path"
  if ($queryString) { $uri = "$uri`?$queryString" }
  Invoke-RestMethod -Method Get -Uri $uri -Headers @{ Authorization = "Bearer $token" }
}

function Invoke-OuraApiOrEmpty($Config, [string]$Path, $Query) {
  try {
    return Invoke-OuraApi $Config $Path $Query
  } catch {
    return @{ data = @(); error = $_.Exception.Message }
  }
}

function Get-DataArray($Response) {
  if ($null -eq $Response) { return @() }
  if ($Response.PSObject.Properties.Name -contains 'data') { return @($Response.data) }
  return @($Response)
}

function Merge-OuraDaily($SleepResponse, $ReadinessResponse, $ActivityResponse) {
  $byDate = @{}

  foreach ($entry in (Get-DataArray $SleepResponse)) {
    $dateKey = $entry.day
    if (-not $dateKey -and $entry.PSObject.Properties.Name -contains 'summary_date') { $dateKey = $entry.summary_date }
    if (-not $dateKey) { continue }
    if (-not $byDate.ContainsKey($dateKey)) { $byDate[$dateKey] = [ordered]@{ date = $dateKey } }
    $byDate[$dateKey].sleepScore = $entry.score
    $byDate[$dateKey].hrv = $entry.average_hrv
    $byDate[$dateKey].restingHeartRate = $entry.lowest_heart_rate
  }

  foreach ($entry in (Get-DataArray $ReadinessResponse)) {
    $dateKey = $entry.day
    if (-not $dateKey) { continue }
    if (-not $byDate.ContainsKey($dateKey)) { $byDate[$dateKey] = [ordered]@{ date = $dateKey } }
    $byDate[$dateKey].readinessScore = $entry.score
  }

  foreach ($entry in (Get-DataArray $ActivityResponse)) {
    $dateKey = $entry.day
    if (-not $dateKey) { continue }
    if (-not $byDate.ContainsKey($dateKey)) { $byDate[$dateKey] = [ordered]@{ date = $dateKey } }
    $byDate[$dateKey].activityScore = $entry.score
    $byDate[$dateKey].steps = $entry.steps
  }

  return @($byDate.Values | Sort-Object date)
}

function Handle-OuraAuthUrl($Config) {
  if (-not $Config) {
    return ConvertTo-JsonResponse 500 @{ error = "Missing oura-config.json. Copy oura-config.example.json and fill in your credentials." }
  }

  $state = [guid]::NewGuid().ToString("N")
  Save-State $state
  $scopeString = [string]::Join(' ', @($Config.scopes))
  $authorizationUrl = "https://cloud.ouraring.com/oauth/authorize?response_type=code&client_id=$([System.Web.HttpUtility]::UrlEncode($Config.clientId))&redirect_uri=$([System.Web.HttpUtility]::UrlEncode($Config.redirectUri))&scope=$([System.Web.HttpUtility]::UrlEncode($scopeString))&state=$([System.Web.HttpUtility]::UrlEncode($state))"
  return ConvertTo-JsonResponse 200 @{ authorizationUrl = $authorizationUrl }
}

function Handle-OuraCallback($Config, $Query) {
  if (-not $Config) {
    return ConvertTo-HtmlResponse 500 "<h1>Missing configuration</h1><p>Create oura-config.json before using OAuth.</p>"
  }

  if ($Query["error"]) {
    return ConvertTo-HtmlResponse 400 "<h1>Oura authorization failed</h1><p>$($Query['error'])</p>"
  }

  $code = $Query["code"]
  $state = $Query["state"]
  if (-not $code) {
    return ConvertTo-HtmlResponse 400 "<h1>Missing authorization code</h1>"
  }

  $expectedState = Get-State
  Clear-State
  if (-not $expectedState -or $expectedState -ne $state) {
    return ConvertTo-HtmlResponse 400 "<h1>Invalid OAuth state</h1><p>Restart the Oura connect flow and try again.</p>"
  }

  try {
    $tokenResponse = Invoke-OuraTokenRequest $Config @{
      grant_type = "authorization_code"
      code = $code
      redirect_uri = $Config.redirectUri
    }
    Save-TokenResponse $tokenResponse | Out-Null
    return ConvertTo-RedirectResponse "/?oura=connected"
  } catch {
    return ConvertTo-HtmlResponse 500 "<h1>Token exchange failed</h1><p>$($_.Exception.Message)</p>"
  }
}

function Handle-OuraStatus($Config) {
  $token = Get-TokenStore
  return ConvertTo-JsonResponse 200 @{
    configured = [bool]$Config
    connected = [bool]$token
    expiresAt = $token.expiresAt
    scope = $token.scope
    lastSync = $token.lastSync
  }
}

function Handle-OuraDisconnect {
  Clear-TokenStore
  Clear-State
  return ConvertTo-JsonResponse 200 @{ disconnected = $true }
}

function Handle-OuraDaily($Config, $Query) {
  if (-not $Config) {
    return ConvertTo-JsonResponse 500 @{ error = "Missing oura-config.json. Copy oura-config.example.json and fill in your credentials." }
  }

  $startDate = $Query["start_date"]
  $endDate = $Query["end_date"]
  if (-not $startDate -or -not $endDate) {
    return ConvertTo-JsonResponse 400 @{ error = "Query params start_date and end_date are required." }
  }

  try {
    $queryArgs = @{ start_date = $startDate; end_date = $endDate }
    $sleep = Invoke-OuraApiOrEmpty $Config "/v2/usercollection/daily_sleep" $queryArgs
    $readiness = Invoke-OuraApiOrEmpty $Config "/v2/usercollection/daily_readiness" $queryArgs
    $activity = Invoke-OuraApiOrEmpty $Config "/v2/usercollection/daily_activity" $queryArgs
    $daily = Merge-OuraDaily $sleep $readiness $activity

    $token = Get-TokenStore
    if ($token) {
      $token.lastSync = (Get-Date).ToUniversalTime().ToString("o")
      Save-TokenStore $token
    }

    return ConvertTo-JsonResponse 200 @{
      daily = $daily
      lastSync = (Get-Date).ToUniversalTime().ToString("o")
      notes = @(
        "Uses Oura OAuth authorization code flow.",
        "Daily endpoint paths are scaffolded for Oura API v2 usercollection daily resources."
      )
    }
  } catch {
    return ConvertTo-JsonResponse 500 @{ error = $_.Exception.Message }
  }
}

function Read-HttpRequest($Client, [int]$Port) {
  $stream = $Client.GetStream()
  $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 8192, $true)
  $requestLine = $reader.ReadLine()
  if ([string]::IsNullOrWhiteSpace($requestLine)) { return $null }

  $parts = $requestLine.Split(' ')
  if ($parts.Length -lt 2) { return $null }
  $method = $parts[0]
  $target = $parts[1]
  $headers = @{}

  while ($true) {
    $line = $reader.ReadLine()
    if ([string]::IsNullOrEmpty($line)) { break }
    $colonIndex = $line.IndexOf(':')
    if ($colonIndex -gt 0) {
      $name = $line.Substring(0, $colonIndex).Trim()
      $value = $line.Substring($colonIndex + 1).Trim()
      $headers[$name] = $value
    }
  }

  $uri = [Uri]("http://localhost:$Port$target")
  $query = [System.Web.HttpUtility]::ParseQueryString($uri.Query)

  return [PSCustomObject]@{
    Method = $method
    Target = $target
    Path = $uri.AbsolutePath
    Query = $query
    Headers = $headers
  }
}

$config = Get-Config
if ($config -and $config.port) { $Port = [int]$config.port }

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "PulseBoard server listening at http://localhost:$Port"
Write-Host "Open http://localhost:$Port in your browser"
if (-not $config) {
  Write-Host "Create oura-config.json from oura-config.example.json to enable Oura OAuth"
}

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $request = Read-HttpRequest $client $Port
      if (-not $request) {
        Write-HttpResponse $client (ConvertTo-JsonResponse 400 @{ error = "Malformed request" })
        continue
      }

      $response = switch ($request.Path) {
        "/auth/oura/url" {
          if ($request.Method -ne "GET") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraAuthUrl $config }
          break
        }
        "/auth/oura/callback" {
          if ($request.Method -ne "GET") { ConvertTo-HtmlResponse 405 "<h1>Method not allowed</h1>" } else { Handle-OuraCallback $config $request.Query }
          break
        }
        "/api/oura/status" {
          if ($request.Method -ne "GET") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraStatus $config }
          break
        }
        "/api/oura/disconnect" {
          if ($request.Method -ne "POST") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraDisconnect }
          break
        }
        "/api/oura/daily" {
          if ($request.Method -ne "GET") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraDaily $config $request.Query }
          break
        }
        "/" { Get-FileResponse "index.html"; break }
        default { Get-FileResponse $request.Path; break }
      }

      Write-HttpResponse $client $response
    } catch {
      try {
        Write-HttpResponse $client (ConvertTo-JsonResponse 500 @{ error = $_.Exception.Message })
      } catch {}
    } finally {
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
