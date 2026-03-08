param(
  [int]$Port = 8787
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Security

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $Root "oura-config.json"
$TokenStorePath = Join-Path $Root "token-store.json"
$StateStorePath = Join-Path $Root "state-store.json"
$UserStorePath = Join-Path $Root "pulseboard-users.json"
$Script:Sessions = @{}

function ConvertTo-PlainText([string]$CipherText) {
  if ([string]::IsNullOrWhiteSpace($CipherText)) { return $null }
  $secure = $CipherText | ConvertTo-SecureString
  $credential = New-Object System.Management.Automation.PSCredential("user", $secure)
  $credential.GetNetworkCredential().Password
}

function Protect-Token([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
  ConvertTo-SecureString -String $Value -AsPlainText -Force | ConvertFrom-SecureString
}

function First-Value {
  param([object[]]$Values)
  foreach ($value in $Values) {
    if ($null -eq $value) { continue }
    if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) { continue }
    return $value
  }
  return $null
}

function New-RandomBytes([int]$Length) {
  $buffer = New-Object byte[] $Length
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)
  $buffer
}

function ConvertTo-Base64Url([byte[]]$Bytes) {
  [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function New-PasswordHash([string]$Password) {
  $salt = New-RandomBytes 16
  $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, 100000)
  $hash = $derive.GetBytes(32)
  [PSCustomObject]@{
    salt = [Convert]::ToBase64String($salt)
    hash = [Convert]::ToBase64String($hash)
    iterations = 100000
  }
}

function Test-Password([string]$Password, $User) {
  if (-not $User) { return $false }
  $salt = [Convert]::FromBase64String($User.salt)
  $expected = [Convert]::FromBase64String($User.hash)
  $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, [int]$User.iterations)
  $actual = $derive.GetBytes($expected.Length)
  [System.Linq.Enumerable]::SequenceEqual($expected, $actual)
}

function Get-UserStore {
  if (-not (Test-Path $UserStorePath)) { return @() }
  $data = Get-Content $UserStorePath -Raw | ConvertFrom-Json
  if ($data -is [System.Array]) { return @($data) }
  if ($null -eq $data) { return @() }
  @($data)
}

function Save-UserStore($Users) {
  ($Users | ConvertTo-Json -Depth 6) | Set-Content $UserStorePath
}

function Find-UserByEmail([string]$Email) {
  $normalized = $Email.Trim().ToLowerInvariant()
  foreach ($user in (Get-UserStore)) {
    if ($user.email -eq $normalized) { return $user }
  }
  return $null
}

function Get-Config {
  if (-not (Test-Path $ConfigPath)) { return $null }
  $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
  if (-not $config.port) { $config | Add-Member -NotePropertyName port -NotePropertyValue $Port -Force }
  if (-not $config.apiBase) { $config | Add-Member -NotePropertyName apiBase -NotePropertyValue "https://api.ouraring.com" -Force }
  if (-not $config.scopes) { $config | Add-Member -NotePropertyName scopes -NotePropertyValue @("daily", "personal", "workout", "session") -Force }
  $config
}

function Get-TokenStore {
  if (-not (Test-Path $TokenStorePath)) { return $null }
  try {
    $raw = Get-Content $TokenStorePath -Raw | ConvertFrom-Json
    [PSCustomObject]@{
      accessToken = ConvertTo-PlainText $raw.accessToken
      refreshToken = ConvertTo-PlainText $raw.refreshToken
      expiresAt = $raw.expiresAt
      scope = $raw.scope
      tokenType = $raw.tokenType
      lastSync = $raw.lastSync
      tokenReadError = $null
    }
  } catch {
    [PSCustomObject]@{
      accessToken = $null
      refreshToken = $null
      expiresAt = $null
      scope = $null
      tokenType = $null
      lastSync = $null
      tokenReadError = "Stored token could not be read. Disconnect and reconnect Oura."
    }
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
  (Get-Content $StateStorePath -Raw | ConvertFrom-Json).state
}

function Clear-State {
  if (Test-Path $StateStorePath) { Remove-Item $StateStorePath -Force }
}

function New-Response($StatusCode, [string]$ContentType, [byte[]]$BodyBytes, $Headers) {
  [PSCustomObject]@{
    StatusCode = $StatusCode
    ContentType = $ContentType
    BodyBytes = $BodyBytes
    Headers = $Headers
  }
}

function Get-StatusText([int]$StatusCode) {
  switch ($StatusCode) {
    200 { "OK" }
    201 { "Created" }
    302 { "Found" }
    400 { "Bad Request" }
    401 { "Unauthorized" }
    404 { "Not Found" }
    405 { "Method Not Allowed" }
    500 { "Internal Server Error" }
    default { "OK" }
  }
}

function ConvertTo-JsonResponse($StatusCode, $Payload, $Headers = @{}) {
  $json = $Payload | ConvertTo-Json -Depth 10
  New-Response $StatusCode "application/json; charset=utf-8" ([System.Text.Encoding]::UTF8.GetBytes($json)) $Headers
}

function ConvertTo-HtmlResponse($StatusCode, [string]$Html, $Headers = @{}) {
  New-Response $StatusCode "text/html; charset=utf-8" ([System.Text.Encoding]::UTF8.GetBytes($Html)) $Headers
}

function ConvertTo-RedirectResponse([string]$Location) {
  New-Response 302 "text/plain; charset=utf-8" ([System.Text.Encoding]::UTF8.GetBytes("Redirecting...")) @{ Location = $Location }
}

function Write-HttpResponse($Client, $Response) {
  $stream = $Client.GetStream()
  $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII, 1024, $true)
  $writer.NewLine = "`r`n"
  $writer.WriteLine("HTTP/1.1 $($Response.StatusCode) $(Get-StatusText $Response.StatusCode)")
  $writer.WriteLine("Content-Type: $($Response.ContentType)")
  $writer.WriteLine("Content-Length: $($Response.BodyBytes.Length)")
  $writer.WriteLine("Connection: close")
  foreach ($header in $Response.Headers.GetEnumerator()) {
    if ($header.Value -is [System.Array]) {
      foreach ($item in $header.Value) { $writer.WriteLine("$($header.Key): $item") }
    } else {
      $writer.WriteLine("$($header.Key): $($header.Value)")
    }
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
  New-Response 200 (Get-ContentType $fullPath) $bytes @{}
}

function Parse-JsonBody($Body) {
  if ([string]::IsNullOrWhiteSpace($Body)) { return $null }
  $Body | ConvertFrom-Json
}

function New-SessionCookie($SessionId) {
  "pulseboard_session=$SessionId; Path=/; HttpOnly; SameSite=Lax"
}

function Clear-SessionCookie() {
  "pulseboard_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0"
}

function Get-CurrentSession($Request) {
  $sessionId = $Request.Cookies["pulseboard_session"]
  if (-not $sessionId) { return $null }
  if ($Script:Sessions.ContainsKey($sessionId)) { return $Script:Sessions[$sessionId] }
  return $null
}

function Get-CurrentUserFromRequest($Request) {
  $session = Get-CurrentSession $Request
  if (-not $session) { return $null }
  Find-UserByEmail $session.email
}

function Require-Auth($Request) {
  $user = Get-CurrentUserFromRequest $Request
  if (-not $user) {
    return @{ ok = $false; response = (ConvertTo-JsonResponse 401 @{ error = "Sign in required." }) }
  }
  return @{ ok = $true; user = $user }
}

function Invoke-OuraTokenRequest($Config, $FormValues) {
  $body = @{}
  foreach ($key in $FormValues.Keys) { $body[$key] = $FormValues[$key] }
  $body.client_id = $Config.clientId
  $body.client_secret = $Config.clientSecret
  Invoke-RestMethod -Method Post -Uri "https://api.ouraring.com/oauth/token" -ContentType "application/x-www-form-urlencoded" -Body $body
}

function Save-TokenResponse($TokenResponse) {
  $existing = Get-TokenStore
  $tokenData = [PSCustomObject]@{
    accessToken = $TokenResponse.access_token
    refreshToken = $TokenResponse.refresh_token
    expiresAt = (Get-Date).ToUniversalTime().AddSeconds([int]$TokenResponse.expires_in).ToString("o")
    scope = $TokenResponse.scope
    tokenType = $TokenResponse.token_type
    lastSync = if ($existing) { $existing.lastSync } else { $null }
  }
  Save-TokenStore $tokenData
  $tokenData
}

function Get-ValidAccessToken($Config) {
  $token = Get-TokenStore
  if (-not $token -or $token.tokenReadError) { throw "No readable Oura token is stored. Disconnect and reconnect Oura." }
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
  (Save-TokenResponse $refreshed).accessToken
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
    @{ ok = $true; response = (Invoke-OuraApi $Config $Path $Query); endpoint = $Path }
  } catch {
    @{ ok = $false; response = @{ data = @() }; endpoint = $Path; error = $_.Exception.Message }
  }
}

function Get-DataArray($ApiResult) {
  if ($null -eq $ApiResult) { return @() }
  $response = if ($ApiResult.response) { $ApiResult.response } else { $ApiResult }
  if ($null -eq $response) { return @() }
  if ($response.PSObject.Properties.Name -contains 'data') { return @($response.data) }
  @($response)
}

function Get-DateKey($Entry) {
  $candidate = First-Value @($Entry.day, $Entry.date, $Entry.summary_date, $Entry.start_datetime, $Entry.start_time)
  if (-not $candidate) { return $null }
  try {
    ([datetime]$candidate).ToUniversalTime().ToString("yyyy-MM-dd")
  } catch {
    $text = $candidate.ToString()
    $text.Substring(0, [Math]::Min(10, $text.Length))
  }
}

function Convert-MetersToMiles($Value) {
  $distance = [double](First-Value @($Value, 0))
  if (-not $distance) { return 0 }
  if ($distance -gt 100) { return [math]::Round($distance / 1609.34, 2) }
  [math]::Round($distance, 2)
}

function Convert-SecondsToMinutes($Value) {
  $duration = [double](First-Value @($Value, 0))
  if (-not $duration) { return 0 }
  if ($duration -gt 300) { return [math]::Round($duration / 60, 1) }
  [math]::Round($duration, 1)
}

function Merge-OuraDaily($SleepResult, $ReadinessResult, $ActivityResult) {
  $byDate = @{}
  foreach ($entry in (Get-DataArray $SleepResult)) {
    $dateKey = Get-DateKey $entry
    if (-not $dateKey) { continue }
    if (-not $byDate.ContainsKey($dateKey)) { $byDate[$dateKey] = [ordered]@{ date = $dateKey } }
    $byDate[$dateKey].sleepScore = $entry.score
    $byDate[$dateKey].hrv = $entry.average_hrv
    $byDate[$dateKey].restingHeartRate = $entry.lowest_heart_rate
  }
  foreach ($entry in (Get-DataArray $ReadinessResult)) {
    $dateKey = Get-DateKey $entry
    if (-not $dateKey) { continue }
    if (-not $byDate.ContainsKey($dateKey)) { $byDate[$dateKey] = [ordered]@{ date = $dateKey } }
    $byDate[$dateKey].readinessScore = $entry.score
  }
  foreach ($entry in (Get-DataArray $ActivityResult)) {
    $dateKey = Get-DateKey $entry
    if (-not $dateKey) { continue }
    if (-not $byDate.ContainsKey($dateKey)) { $byDate[$dateKey] = [ordered]@{ date = $dateKey } }
    $byDate[$dateKey].activityScore = $entry.score
    $byDate[$dateKey].steps = $entry.steps
  }
  @($byDate.Values | Sort-Object date)
}

function Merge-OuraWorkouts($WorkoutResult, $SessionResult) {
  $items = New-Object System.Collections.Generic.List[object]
  foreach ($entry in (Get-DataArray $WorkoutResult)) {
    $dateKey = Get-DateKey $entry
    if (-not $dateKey) { continue }
    $items.Add([PSCustomObject]@{
      date = $dateKey
      type = (First-Value @($entry.activity, $entry.type, $entry.workout_type, "Oura Workout"))
      durationMinutes = Convert-SecondsToMinutes (First-Value @($entry.duration, $entry.total_duration, $entry.duration_in_seconds, 0))
      activeCalories = [double](First-Value @($entry.calories, $entry.total_calories, 0))
      distanceMiles = Convert-MetersToMiles (First-Value @($entry.distance, $entry.total_distance, 0))
      averageHeartRate = [double](First-Value @($entry.average_heart_rate, $entry.heart_rate, 0))
      source = "oura-workout"
    })
  }
  foreach ($entry in (Get-DataArray $SessionResult)) {
    $dateKey = Get-DateKey $entry
    if (-not $dateKey) { continue }
    $sessionType = (First-Value @($entry.type, $entry.activity, $entry.session_type, $entry.name, "Session"))
    $items.Add([PSCustomObject]@{
      date = $dateKey
      type = "$sessionType Session"
      durationMinutes = Convert-SecondsToMinutes (First-Value @($entry.duration, $entry.total_duration, $entry.duration_in_seconds, 0))
      activeCalories = [double](First-Value @($entry.calories, 0))
      distanceMiles = Convert-MetersToMiles (First-Value @($entry.distance, 0))
      averageHeartRate = [double](First-Value @($entry.average_heart_rate, $entry.heart_rate, 0))
      source = "oura-session"
    })
  }
  @($items | Sort-Object date)
}

function Handle-AuthStatus($Request) {
  $user = Get-CurrentUserFromRequest $Request
  ConvertTo-JsonResponse 200 @{
    authenticated = [bool]$user
    hasUsers = ((Get-UserStore).Count -gt 0)
    user = if ($user) { @{ name = $user.name; email = $user.email } } else { $null }
  }
}

function Handle-AuthRegister($Request) {
  $body = Parse-JsonBody $Request.Body
  if (-not $body -or -not $body.email -or -not $body.password -or -not $body.name) {
    return ConvertTo-JsonResponse 400 @{ error = "Name, email, and password are required." }
  }
  if (Find-UserByEmail $body.email) {
    return ConvertTo-JsonResponse 400 @{ error = "An account with that email already exists." }
  }

  $users = Get-UserStore
  $passwordHash = New-PasswordHash $body.password
  $user = [PSCustomObject]@{
    id = [guid]::NewGuid().ToString("N")
    name = $body.name.Trim()
    email = $body.email.Trim().ToLowerInvariant()
    salt = $passwordHash.salt
    hash = $passwordHash.hash
    iterations = $passwordHash.iterations
    createdAt = (Get-Date).ToUniversalTime().ToString("o")
  }
  $users = @($users) + @($user)
  Save-UserStore $users

  $sessionId = ConvertTo-Base64Url (New-RandomBytes 32)
  $Script:Sessions[$sessionId] = @{ email = $user.email; createdAt = (Get-Date).ToUniversalTime().ToString("o") }
  ConvertTo-JsonResponse 201 @{ user = @{ name = $user.name; email = $user.email } } @{ "Set-Cookie" = (New-SessionCookie $sessionId) }
}

function Handle-AuthLogin($Request) {
  $body = Parse-JsonBody $Request.Body
  if (-not $body -or -not $body.email -or -not $body.password) {
    return ConvertTo-JsonResponse 400 @{ error = "Email and password are required." }
  }
  $user = Find-UserByEmail $body.email
  if (-not (Test-Password $body.password $user)) {
    return ConvertTo-JsonResponse 401 @{ error = "Invalid email or password." }
  }

  $sessionId = ConvertTo-Base64Url (New-RandomBytes 32)
  $Script:Sessions[$sessionId] = @{ email = $user.email; createdAt = (Get-Date).ToUniversalTime().ToString("o") }
  ConvertTo-JsonResponse 200 @{ user = @{ name = $user.name; email = $user.email } } @{ "Set-Cookie" = (New-SessionCookie $sessionId) }
}

function Handle-AuthLogout($Request) {
  $sessionId = $Request.Cookies["pulseboard_session"]
  if ($sessionId -and $Script:Sessions.ContainsKey($sessionId)) { $Script:Sessions.Remove($sessionId) }
  ConvertTo-JsonResponse 200 @{ loggedOut = $true } @{ "Set-Cookie" = (Clear-SessionCookie) }
}

function Handle-OuraAuthUrl($Config, $Request) {
  $auth = Require-Auth $Request
  if (-not $auth.ok) { return $auth.response }
  if (-not $Config) {
    return ConvertTo-JsonResponse 500 @{ error = "Missing oura-config.json. Copy oura-config.example.json and fill in your credentials." }
  }
  $state = [guid]::NewGuid().ToString("N")
  Save-State $state
  $scopeString = [string]::Join(' ', @($Config.scopes))
  $authorizationUrl = "https://cloud.ouraring.com/oauth/authorize?response_type=code&client_id=$([System.Web.HttpUtility]::UrlEncode($Config.clientId))&redirect_uri=$([System.Web.HttpUtility]::UrlEncode($Config.redirectUri))&scope=$([System.Web.HttpUtility]::UrlEncode($scopeString))&state=$([System.Web.HttpUtility]::UrlEncode($state))"
  ConvertTo-JsonResponse 200 @{ authorizationUrl = $authorizationUrl }
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

function Handle-OuraStatus($Config, $Request) {
  $auth = Require-Auth $Request
  if (-not $auth.ok) { return $auth.response }
  $token = Get-TokenStore
  $isConnected = [bool]($token -and $token.accessToken -and -not $token.tokenReadError)
  ConvertTo-JsonResponse 200 @{
    configured = [bool]$Config
    connected = $isConnected
    expiresAt = if ($token) { $token.expiresAt } else { $null }
    scope = if ($token) { $token.scope } else { $null }
    lastSync = if ($token) { $token.lastSync } else { $null }
    tokenReadError = if ($token) { $token.tokenReadError } else { $null }
  }
}

function Handle-OuraDisconnect($Request) {
  $auth = Require-Auth $Request
  if (-not $auth.ok) { return $auth.response }
  Clear-TokenStore
  Clear-State
  ConvertTo-JsonResponse 200 @{ disconnected = $true }
}

function Handle-OuraSummary($Config, $Query, $Request) {
  $auth = Require-Auth $Request
  if (-not $auth.ok) { return $auth.response }
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
    $workoutsResult = Invoke-OuraApiOrEmpty $Config "/v2/usercollection/workout" $queryArgs
    $sessionResult = Invoke-OuraApiOrEmpty $Config "/v2/usercollection/session" $queryArgs

    $daily = Merge-OuraDaily $sleep $readiness $activity
    $workouts = Merge-OuraWorkouts $workoutsResult $sessionResult
    $notes = New-Object System.Collections.Generic.List[string]
    if (-not $workoutsResult.ok) { $notes.Add("Workout sync may need the workout scope and a reconnect.") }
    if (-not $sessionResult.ok) { $notes.Add("Session sync may need the session scope and a reconnect.") }

    $token = Get-TokenStore
    if ($token -and -not $token.tokenReadError) {
      $token.lastSync = (Get-Date).ToUniversalTime().ToString("o")
      Save-TokenStore $token
    }

    ConvertTo-JsonResponse 200 @{
      daily = $daily
      workouts = $workouts
      lastSync = (Get-Date).ToUniversalTime().ToString("o")
      notes = @($notes)
      inferredEndpoints = @("/v2/usercollection/workout", "/v2/usercollection/session")
    }
  } catch {
    ConvertTo-JsonResponse 500 @{ error = $_.Exception.Message }
  }
}

function Read-HttpRequest($Client, [int]$Port) {
  $stream = $Client.GetStream()
  $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8, $false, 8192, $true)
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

  $body = ""
  if ($headers.ContainsKey("Content-Length")) {
    $contentLength = [int]$headers["Content-Length"]
    if ($contentLength -gt 0) {
      $buffer = New-Object char[] $contentLength
      $readCount = $reader.ReadBlock($buffer, 0, $contentLength)
      $body = -join $buffer[0..($readCount - 1)]
    }
  }

  $cookieMap = @{}
  if ($headers.ContainsKey("Cookie")) {
    foreach ($part in $headers["Cookie"].Split(';')) {
      $cookie = $part.Trim()
      if (-not $cookie) { continue }
      $pieces = $cookie.Split('=', 2)
      if ($pieces.Length -eq 2) { $cookieMap[$pieces[0]] = $pieces[1] }
    }
  }

  $uri = [Uri]("http://localhost:$Port$target")
  $query = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
  [PSCustomObject]@{
    Method = $method
    Target = $target
    Path = $uri.AbsolutePath
    Query = $query
    Headers = $headers
    Cookies = $cookieMap
    Body = $body
  }
}

$config = Get-Config
if ($config -and $config.port) { $Port = [int]$config.port }
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "PulseBoard server listening at http://localhost:$Port"
Write-Host "Open http://localhost:$Port in your browser"
if (-not $config) { Write-Host "Create oura-config.json from oura-config.example.json to enable Oura OAuth" }

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
        "/api/auth/status" {
          if ($request.Method -ne "GET") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-AuthStatus $request }
          break
        }
        "/api/auth/register" {
          if ($request.Method -ne "POST") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-AuthRegister $request }
          break
        }
        "/api/auth/login" {
          if ($request.Method -ne "POST") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-AuthLogin $request }
          break
        }
        "/api/auth/logout" {
          if ($request.Method -ne "POST") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-AuthLogout $request }
          break
        }
        "/auth/oura/url" {
          if ($request.Method -ne "GET") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraAuthUrl $config $request }
          break
        }
        "/auth/oura/callback" {
          if ($request.Method -ne "GET") { ConvertTo-HtmlResponse 405 "<h1>Method not allowed</h1>" } else { Handle-OuraCallback $config $request.Query }
          break
        }
        "/api/oura/status" {
          if ($request.Method -ne "GET") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraStatus $config $request }
          break
        }
        "/api/oura/disconnect" {
          if ($request.Method -ne "POST") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraDisconnect $request }
          break
        }
        "/api/oura/summary" {
          if ($request.Method -ne "GET") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraSummary $config $request.Query $request }
          break
        }
        "/api/oura/daily" {
          if ($request.Method -ne "GET") { ConvertTo-JsonResponse 405 @{ error = "Method not allowed" } } else { Handle-OuraSummary $config $request.Query $request }
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
