<h1>Find SAML Signing Certificates Expiring Within 90 Days</h1>

<h2>What it does</h2>

<p>This script is for catching SAML certificate expiries before they cause an SSO outage. It checks every SAML-based enterprise app in your tenant, finds certificates that have expired or will expire within the next 90 days, and lists them in a table and a CSV.</p>

<h2>How it works</h2>

<ol>
  <li>Signs into Microsoft Graph with <code>Connect-MgGraph</code>. It only asks for <code>Application.Read.All</code> and <code>Directory.Read.All</code>, so it's read-only and won't change anything in your tenant.</li>
  <li>Sets up the time window:
    <ul>
      <li><code>$Days</code> is how far ahead to look, set to <code>90</code>. Change this number to widen or narrow the window.</li>
      <li><code>$Now</code> is the current date and time.</li>
      <li><code>$CutoffDate</code> is today plus 90 days. Anything expiring on or before this date gets flagged.</li>
    </ul>
  </li>
  <li>Pulls every service principal in the tenant with <code>Get-MgServicePrincipal -All</code>, then keeps only the ones where <code>PreferredSingleSignOnMode</code> is <code>saml</code>. This filtering happens in PowerShell after everything has been downloaded.</li>
  <li>Loops through each SAML app and checks every certificate in its <code>KeyCredentials</code>. A certificate is flagged if it has an expiry date that falls on or before the cutoff. Certificates that have already expired are included too, no matter how long ago.</li>
  <li>For each flagged certificate, records:
    <ul>
      <li><code>ApplicationName</code> (display name)</li>
      <li><code>ServicePrincipalId</code> (object ID)</li>
      <li><code>AppId</code></li>
      <li><code>CertificateExpiry</code> (the expiry date and time)</li>
      <li><code>DaysRemaining</code> (days between now and expiry, negative if already expired)</li>
      <li><code>Status</code> (<code>Expired</code> if the date has passed, otherwise <code>Expiring</code>)</li>
    </ul>
  </li>
  <li>Sorts the results by expiry date, soonest (or longest expired) first.</li>
  <li>Prints the results as a table with <code>Format-Table</code> and saves them to <code>SamlCertificatesExpiringWithin90Days.csv</code> in whatever folder you ran the script from.</li>
  <li>Prints how many certificates were found and where the report was saved.</li>
</ol>

<h2>Prerequisites</h2>

<ul>
  <li>The Microsoft Graph PowerShell SDK (<code>Microsoft.Graph.Applications</code> module)</li>
  <li>An account that can use <code>Application.Read.All</code> and <code>Directory.Read.All</code></li>
</ul>

<h2>Notes / Limitations</h2>

<ul>
  <li>It only covers <b>SAML SSO enterprise apps</b>. It won't show OIDC or password-based apps, app registration certificates, or client secrets.</li>
  <li>It checks <b>every</b> certificate on the app, not just the active signing certificate. Old, replaced certificates that were never deleted will show up as <code>Expired</code> even though nothing is wrong, so expect some noise.</li>
  <li>Already-expired certificates are included with no lower limit, which can make the report look worse than it is in older tenants.</li>
  <li><code>DaysRemaining</code> is a raw decimal value (e.g. <code>41.7382915</code>), not a whole number. You may want to round it in the output.</li>
  <li>It doesn't include the notification email addresses for each app, so you can't tell from this report who would have been warned.</li>
  <li>Because it downloads all service principals before filtering, it can be slow in a large tenant.</li>
  <li>The CSV export doesn't set an encoding. PowerShell 7 defaults to UTF-8, but Windows PowerShell 5.1 may mangle special characters in app names.</li>
</ul>
