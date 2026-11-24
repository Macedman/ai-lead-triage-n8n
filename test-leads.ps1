# Sends sample contact-form leads to the n8n "lead" webhook.
#
# Usage:
#   .\test-leads.ps1              # send only the first lead (test URL)
#   .\test-leads.ps1 -All         # send all 6 leads (test URL)
#   .\test-leads.ps1 -All -Prod   # send all 6 to the production URL (workflow must be active)
#
# Test URL (/webhook-test/) only accepts one call each time you click Execute in n8n,
# so use -All together with -Prod after publishing the workflow.
# You can start this script BEFORE clicking Execute: it waits until n8n is listening.

param(
    [switch]$All,
    [switch]$Prod
)

$path = if ($Prod) { 'webhook' } else { 'webhook-test' }
$url  = "http://localhost:5678/$path/lead"

$leads = @(
    @{ name = 'Ana';   email = 'ana@example.com';   message = 'Our site is down and we need help today' }
    @{ name = 'Ben';   email = 'ben@example.com';   message = 'Can you quote a 5-page site for my bakery?' }
    @{ name = 'Carla'; email = 'carla@example.com'; message = 'We want to launch an online store before Black Friday' }
    @{ name = 'Dan';   email = 'dan@example.com';   message = 'How do I change my contact email on the site?' }
    @{ name = 'Spam';  email = 'x@spam.example';    message = 'Cheap SEO backlinks, click here!!!' }
    @{ name = 'Empty'; email = '';                  message = '' }
)

if (-not $All) { $leads = $leads[0..0] }

foreach ($lead in $leads) {
    $body = $lead | ConvertTo-Json -Compress
    Write-Host "-> $($lead.name): $($lead.message)" -ForegroundColor Cyan

    # A 404 on the test URL means n8n isn't listening yet. Keep retrying for up to
    # 2 minutes so you can start this script first and click Execute afterwards.
    $deadline = (Get-Date).AddMinutes(2)
    $waiting = $false
    while ($true) {
        try {
            $res = Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Body $body
            Write-Host "   reply: $($res | ConvertTo-Json -Compress)" -ForegroundColor Green
            break
        } catch {
            $status = $_.Exception.Response.StatusCode.value__
            if ($status -eq 404 -and -not $Prod -and (Get-Date) -lt $deadline) {
                if (-not $waiting) {
                    Write-Host "   n8n isn't listening yet - click Execute in n8n now (waiting up to 2 min)..." -ForegroundColor Yellow
                    $waiting = $true
                }
                Start-Sleep -Seconds 2
                continue
            }
            Write-Host "   failed: $($_.Exception.Message)" -ForegroundColor Red
            break
        }
    }
}
