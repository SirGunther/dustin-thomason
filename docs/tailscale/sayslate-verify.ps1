# SaySlate endpoint verification. Prints status lines only; the token is never printed or written.
$ErrorActionPreference = 'Stop'
$model = 'google/gemma-4-12b-qat'
$token = $env:LM_API_TOKEN
if (-not $token) {
    $sec = Read-Host 'Paste LM Studio API token (hidden)' -AsSecureString
    $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}
$dns = ((& 'C:\Program Files\Tailscale\tailscale.exe' status --json | ConvertFrom-Json).Self.DNSName).TrimEnd('.')
$tailBase = "https://$dns/v1"
$localBase = 'http://127.0.0.1:1234/v1'

Add-Type -AssemblyName System.Net.Http
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(90)

function Send($method, $url, $withToken, $body) {
    $req = New-Object System.Net.Http.HttpRequestMessage($method, $url)
    if ($withToken) { $req.Headers.TryAddWithoutValidation('Authorization', "Bearer $token") | Out-Null }
    if ($body) { $req.Content = New-Object System.Net.Http.StringContent($body, [Text.Encoding]::UTF8, 'application/json') }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try { $res = $client.SendAsync($req).GetAwaiter().GetResult() } catch { return @{ code = 'ERR'; body = $_.Exception.GetBaseException().Message; secs = $sw.Elapsed.TotalSeconds } }
    @{ code = [int]$res.StatusCode; body = $res.Content.ReadAsStringAsync().GetAwaiter().GetResult(); secs = $sw.Elapsed.TotalSeconds }
}
function ModelListed($r) { try { [bool](($r.body | ConvertFrom-Json).data.id -contains $model) } catch { $false } }

$r = Send 'GET' "$localBase/models" $true $null;  "V1 local models + token   : HTTP $($r.code)  model listed: $(ModelListed $r)"
$r = Send 'GET' "$localBase/models" $false $null; "V2 local models, no token : HTTP $($r.code)"
$r = Send 'GET' "$tailBase/models" $true $null;   "V3 tailnet models + token : HTTP $($r.code)  model listed: $(ModelListed $r)  ($([math]::Round($r.secs,1))s)"
$r = Send 'GET' "$tailBase/models" $false $null;  "V4 tailnet models, no token: HTTP $($r.code)"

$msg = @{ role = 'user'; content = 'Correct the grammar of this sentence and return only the corrected sentence: this are a simple test sentence.' }
$schema = @{ type = 'json_schema'; json_schema = @{ name = 'sayslate_result'; strict = $true; schema = @{ type = 'object'; properties = @{ text = @{ type = 'string' } }; required = @('text'); additionalProperties = $false } } }
$body = @{ model = $model; messages = @($msg); response_format = $schema } | ConvertTo-Json -Depth 10
$r = Send 'POST' "$tailBase/chat/completions" $true $body
$ok = $false; $text = ''
try { $text = (((($r.body | ConvertFrom-Json).choices[0].message.content) | ConvertFrom-Json).text); $ok = ($text -is [string]) -and $text.Length -gt 0 } catch {}
"V5 structured chat + token: HTTP $($r.code)  parsed {text}: $ok  elapsed: $([math]::Round($r.secs,1))s  text: $text"
if (-not $ok) {
    $body2 = @{ model = $model; messages = @($msg) } | ConvertTo-Json -Depth 10
    $r = Send 'POST' "$tailBase/chat/completions" $true $body2
    "V5b plain chat + token    : HTTP $($r.code)  elapsed: $([math]::Round($r.secs,1))s"
}
$token = $null; $client.Dispose()
