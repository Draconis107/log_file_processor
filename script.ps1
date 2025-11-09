# Use index file to download log files
Invoke-WebRequest -Uri "https://files.singular-devops.com/challenges/01-applogs/index.txt" -OutFile "index.txt"
$indexFile = Get-Content "index.txt"
$folderPath = "logs"
if (-not (Test-Path -Path $folderPath -PathType Container)) {
    New-Item -Path $folderPath -ItemType Directory
}
foreach ($fileName in $indexFile) {
    $downloadLink = "https://files.singular-devops.com/challenges/01-applogs/" + $fileName
    Invoke-WebRequest -Uri $downloadLink -OutFile ("logs\" + $fileName)
}

# Process log files and create report.json
$report = New-Object System.Collections.ArrayList
foreach ($fileName in $indexFile) {
    # Possible improvement - log object (class)?
    $ColumnNames = "date", "type", "service", "message"
    $log = Import-Csv -Path ("logs\" + $fileName) -Header $ColumnNames

    # Set date
    # Can also extract date from filename
    $dateArray = $log[0].date -split "-"
    $reportDate = $dateArray[0] + " - " + $dateArray[1]

    # Get counts of different log types
    # Possible improvement - pipelines?
    $infoCount = 0
    $warningCount = 0
    $errorCount = 0
    foreach ($line in $log) {
        switch -wildcard ($line.type) {
            "*info*" { 
                $infoCount++
                break
             }
            "*warning*" { 
                $warningCount++ 
                break
            }
            "*error*" { 
                $errorCount++ 
                break
            }
            # Don't know if this will ever be a usecase?
            # Default { $unknown++ }
        }
    }

    # Calculate stats
    $warningPercentageChange = 0
    $errorPercentageChange = 0 
    if ($report.Count -gt 0) {
        $previous = $report[($report.Count - 1)]
        if ($previous.warningCount -gt 0) {
            $warningPercentageChange = [Math]::Round(((($warningCount - $previous.warningCount) / $previous.warningCount) * 100), 2)
        } else {
            $warningPercentageChange = 100
        }
        if ($previous.errorCount -gt 0) {
            $errorPercentageChange = [Math]::Round(((($errorCount - $previous.errorCount) / $previous.errorCount) * 100), 2) 
        } else {
            $errorPercentageChange = 100
        }
    }

    # Add to report object
    # Possible improvement - report object (class)?
    $report.Add([PSCustomObject]@{
        date = $reportDate
        infoCount = $infoCount
        warningCount = $warningCount
        errorCount = $errorCount
        warningPercentageChange = [string]$warningPercentageChange + "%"
        errorPercentageChange = [string]$errorPercentageChange + "%"
    }) 

}

# Save report as JSON
$folderPath = "report"
if (-not (Test-Path -Path $folderPath -PathType Container)) {
    New-Item -Path $folderPath -ItemType Directory
}
$report | ConvertTo-Json | Set-Content -Path "report\report.json"

# Generate HTML file
$html = @"
<html>
<body>
<h1>Report</h1>
"@

foreach ($month in $report) {
    $html += ("<h3>" + $month.date + "</h3>")
    $html += ("<p> Info: " + $month.infoCount + "</p>")
    $html += ("<p> Warning: " + $month.warningCount + " | Change from last month: " + $month.warningPercentageChange + "</p>")
    $html += ("<p> Error: " + $month.errorCount + " | Change from last month: " + $month.errorPercentageChange + "</p>")
}

$html += @"
</body>
</html>
"@

Set-Content -Path "report\index.html" $html