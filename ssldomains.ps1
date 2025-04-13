function Get-SSLCertificateInfo {
    param(
        [string]$domain,
        [System.Text.StringBuilder]$reportBuilder
    )

    try {
        $request = [System.Net.HttpWebRequest]::Create("https://$domain")
        $request.Method = "GET"
        $request.Timeout = 5000
        $request.AllowAutoRedirect = $false
        $response = $request.GetResponse()
        $response.Close()

        $certificate = $request.ServicePoint.Certificate
        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certificate

        $expiryDate = $cert2.NotAfter
        $now = Get-Date
        $daysLeft = ($expiryDate - $now).Days

        $status = if ($daysLeft -lt 30) { "⚠️ СКОРО ИСТЕКАЕТ!" } else { "✅ OK" }

        $reportBuilder.AppendLine("Домен: $domain") | Out-Null
        $reportBuilder.AppendLine("Истекает: $($expiryDate.ToString("dd.MM.yyyy HH:mm"))") | Out-Null
        $reportBuilder.AppendLine("Осталось дней: $daysLeft") | Out-Null
        $reportBuilder.AppendLine("Статус: $status") | Out-Null
        $reportBuilder.AppendLine("Проверено: $((Get-Date).ToString("dd.MM.yyyy HH:mm"))") | Out-Null
        $reportBuilder.AppendLine("".PadRight(50, "-")) | Out-Null
    }
    catch {
        $reportBuilder.AppendLine("Домен: $domain") | Out-Null
        $reportBuilder.AppendLine("Ошибка при проверке: $_") | Out-Null
        $reportBuilder.AppendLine("".PadRight(50, "-")) | Out-Null
    }
}

# === Подготовка отчёта ===
$domainList = Get-Content -Path ".\domains.txt"
$report = New-Object System.Text.StringBuilder

$report.AppendLine("== ОТЧЁТ ПО SSL-СЕРТИФИКАТАМ ==") | Out-Null
$report.AppendLine("Дата отчёта: $(Get-Date -Format 'dd.MM.yyyy HH:mm')") | Out-Null
$report.AppendLine("".PadRight(50, "=")) | Out-Null

foreach ($domain in $domainList) {
    if (-not [string]::IsNullOrWhiteSpace($domain)) {
        Get-SSLCertificateInfo -domain $domain.Trim() -reportBuilder $report
    }
}

# === Сохраняем отчёт в .txt ===
$txtPath = ".\ssl_report.txt"
$report.ToString() | Out-File -FilePath $txtPath -Encoding UTF8

# === Отправка письма через SMTP (STARTTLS) ===

# SMTP параметры
$smtpServer = "сервер"
$smtpPort = порт
$from = "почта"
$to = "sпочта"
$subject = "SSL-сертификаты: текстовый отчёт"
$body = "Здравствуйте! Во вложении находится текстовый отчёт по SSL-сертификатам."

# Учетные данные
$securePassword = ConvertTo-SecureString "ПАРОЛЬ" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($from, $securePassword)

# Отправка через STARTTLS (порт 587)
Send-MailMessage -From $from `
                 -To $to `
                 -Subject $subject `
                 -Body $body `
                 -SmtpServer $smtpServer `
                 -Port $smtpPort `
                 -Credential $credentials `
                 -Attachments $txtPath `
                 -DeliveryNotificationOption OnFailure `
                 -Encoding UTF8

Write-Host "`n📬 Отчёт успешно отправлен с $from на $to через STARTTLS (${smtpServer}:$smtpPort)"
