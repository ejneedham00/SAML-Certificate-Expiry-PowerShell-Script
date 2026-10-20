Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All"

$Days = 90
$Now = Get-Date
$CutoffDate = $Now.AddDays($Days)

$Results = @()

# Get SAML SSO Enterprise Applications
$SamlApps = Get-MgServicePrincipal -All |
    Where-Object { $_.PreferredSingleSignOnMode -eq "saml" }

foreach ($SP in $SamlApps) {

    foreach ($Cert in $SP.KeyCredentials) {

        if ($Cert.EndDateTime -and $Cert.EndDateTime -le $CutoffDate) {

            $Results += [PSCustomObject]@{
                ApplicationName    = $SP.DisplayName
                ServicePrincipalId = $SP.Id
                AppId              = $SP.AppId
                CertificateExpiry  = $Cert.EndDateTime
                DaysRemaining      = ($Cert.EndDateTime - $Now).TotalDays
                Status             = if ($Cert.EndDateTime -lt $Now) {
                    "Expired"
                }
                else {
                    "Expiring"
                }
            }
        }
    }
}

$Results = $Results | Sort-Object CertificateExpiry

$Results | Format-Table -AutoSize

$CsvPath = ".\SamlCertificatesExpiringWithin90Days.csv"
$Results | Export-Csv $CsvPath -NoTypeInformation

Write-Host "Found $($Results.Count) certificate(s)."
Write-Host "Report exported to $CsvPath"