# Times how long it takes a person to triage the six sample leads BY HAND,
# so the README can compare manual vs automated time with real numbers.
#
# For each lead, do what the workflow does, for real:
#   1. read the message
#   2. decide category (sales/support/spam) and urgency (1-5)
#   3. write a one-sentence summary
#   4. add a row to the Google Sheet
#   5. post it in the right Slack channel (skip Slack for spam)
# Press Enter when you finish each lead. Nothing is sent anywhere.
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\time-manual-triage.ps1

$leads = @(
    @{ name = 'Ana';   email = 'ana@example.com';   message = 'Our site is down and we need help today' }
    @{ name = 'Ben';   email = 'ben@example.com';   message = 'Can you quote a 5-page site for my bakery?' }
    @{ name = 'Carla'; email = 'carla@example.com'; message = 'We want to launch an online store before Black Friday' }
    @{ name = 'Dan';   email = 'dan@example.com';   message = 'How do I change my contact email on the site?' }
    @{ name = 'Spam';  email = 'x@spam.example';    message = 'Cheap SEO backlinks, click here!!!' }
    @{ name = 'Empty'; email = '';                  message = '' }
)

Write-Host "Manual triage timer: 6 leads. Do all 5 steps for each one, then press Enter." -ForegroundColor Cyan
Read-Host "Have the Sheet and Slack open, then press Enter to start" | Out-Null

$times = @()
$i = 0
foreach ($lead in $leads) {
    $i++
    Write-Host ""
    Write-Host "Lead $i/6" -ForegroundColor Yellow
    Write-Host "  Name:    $($lead.name)"
    Write-Host "  Email:   $($lead.email)"
    Write-Host "  Message: $($lead.message)"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Read-Host "  ...triage it, then press Enter" | Out-Null
    $sw.Stop()
    $times += $sw.Elapsed.TotalSeconds
    Write-Host ("  took {0:N0} s" -f $sw.Elapsed.TotalSeconds) -ForegroundColor Green
}

$avg = ($times | Measure-Object -Average).Average
Write-Host ""
Write-Host ("Average per lead (manual): {0:N0} s  ({1:N1} min)" -f $avg, ($avg / 60)) -ForegroundColor Cyan
Write-Host ("Total for 6 leads:         {0:N0} s" -f ($times | Measure-Object -Sum).Sum) -ForegroundColor Cyan
Write-Host "Automated (from n8n Executions): about 7.6 s per lead, with no person needed."
