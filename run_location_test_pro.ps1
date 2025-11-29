$deviceID = "emulator-5554"
$packageName = "com.example.pbl6mobile"
$remoteDir = "/storage/emulated/0/Download/test_result"
$localReportDir = ".\bao_cao_test\location"
$xmlReportFile = "$localReportDir\location_report.xml"
$htmlReportFile = "$localReportDir\location_report.html"

if (-not (Test-Path -Path $localReportDir)) {
    New-Item -ItemType Directory -Path $localReportDir | Out-Null
}

$installed = dart pub global list | Select-String "junitreport"
if (-not $installed) {
    Write-Host "Activating junitreport tool..." -ForegroundColor Cyan
    dart pub global activate junitreport
}

Write-Host "Granting permissions..." -ForegroundColor Cyan
adb -s $deviceID shell pm grant $packageName android.permission.WRITE_EXTERNAL_STORAGE
adb -s $deviceID shell pm grant $packageName android.permission.READ_EXTERNAL_STORAGE

Write-Host "Running Location Test..." -ForegroundColor Yellow
Write-Host "(Please wait for Flutter to build and run the test...)" -ForegroundColor DarkGray

flutter test integration_test/tests/e2e_location_work_test.dart -d $deviceID --machine | dart pub global run junitreport:tojunit --output $xmlReportFile

Write-Host "Pulling internal Excel report..." -ForegroundColor Cyan
adb -s $deviceID pull "$remoteDir/." "$localReportDir"

if (Test-Path $xmlReportFile) {
    Write-Host "Converting XML to Professional HTML Report..." -ForegroundColor Cyan

    $xslContent = @'
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" indent="yes" doctype-system="about:legacy-compat"/>
<xsl:template match="/">
<html>
<head>
    <title>Location Work Test Report</title>
    <meta charset="UTF-8"/>
    <style>
        body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f0f2f5; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 1200px; margin: 0 auto; background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }

        header { border-bottom: 2px solid #eee; padding-bottom: 20px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; }
        h1 { margin: 0; color: #1a73e8; font-size: 24px; }
        .timestamp { color: #888; font-size: 14px; }

        .dashboard { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 20px; }
        .card { padding: 15px; border-radius: 8px; color: white; text-align: center; }
        .card h3 { margin: 0; font-size: 32px; font-weight: bold; }
        .card p { margin: 5px 0 0; font-size: 14px; opacity: 0.9; }
        .bg-total { background: linear-gradient(135deg, #6c757d, #495057); }
        .bg-pass { background: linear-gradient(135deg, #28a745, #218838); }
        .bg-fail { background: linear-gradient(135deg, #dc3545, #c82333); }
        .bg-rate { background: linear-gradient(135deg, #17a2b8, #138496); }

        .controls { margin-bottom: 15px; display: flex; gap: 10px; align-items: center; }
        input[type="text"] { padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px; flex-grow: 1; }
        button { padding: 8px 15px; border: none; border-radius: 4px; cursor: pointer; font-weight: 500; transition: 0.2s; }
        .btn-all { background: #6c757d; color: white; }
        .btn-pass { background: #28a745; color: white; }
        .btn-fail { background: #dc3545; color: white; }
        button:hover { opacity: 0.9; transform: translateY(-1px); }

        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th { background-color: #f8f9fa; padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6; color: #495057; }
        td { padding: 12px; border-bottom: 1px solid #dee2e6; vertical-align: top; }
        tr:hover { background-color: #f8f9fa; }

        .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; text-transform: uppercase; }
        .badge-pass { background-color: #d4edda; color: #155724; }
        .badge-fail { background-color: #f8d7da; color: #721c24; }
        .badge-error { background-color: #fff3cd; color: #856404; }

        .error-preview { color: #dc3545; font-size: 0.9em; margin-top: 5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 600px; cursor: pointer; }
        .error-full { display: none; background: #2d2d2d; color: #f8f8f2; padding: 10px; border-radius: 4px; margin-top: 5px; font-family: monospace; font-size: 12px; white-space: pre-wrap; }

        .duration { color: #666; font-size: 0.9em; }
    </style>
    <script>
    <![CDATA[
        function filterTable(status) {
            var rows = document.querySelectorAll("tbody tr");
            rows.forEach(row => {
                if (status === 'all') {
                    row.style.display = "";
                } else if (row.classList.contains(status)) {
                    row.style.display = "";
                } else {
                    row.style.display = "none";
                }
            });
        }

        function searchTable() {
            var input = document.getElementById("searchInput");
            var filter = input.value.toUpperCase();
            var rows = document.querySelectorAll("tbody tr");
            rows.forEach(row => {
                var text = row.innerText.toUpperCase();
                if (text.indexOf(filter) > -1) {
                    row.style.display = "";
                } else {
                    row.style.display = "none";
                }
            });
        }

        function toggleError(id) {
            var el = document.getElementById(id);
            if (el.style.display === "block") {
                el.style.display = "none";
            } else {
                el.style.display = "block";
            }
        }
    ]]>
    </script>
</head>
<body>
    <div class="container">
        <header>
            <h1>Location Work Integration Test Report</h1>
            <div class="timestamp">Generated: <xsl:value-of select="//testsuite/@timestamp"/></div>
        </header>

        <xsl:variable name="total" select="sum(//testsuite/@tests)"/>
        <xsl:variable name="failures" select="sum(//testsuite/@failures)"/>
        <xsl:variable name="errors" select="sum(//testsuite/@errors)"/>
        <xsl:variable name="passed" select="$total - $failures - $errors"/>
        <xsl:variable name="successRate" select="format-number($passed div $total, '#%')"/>

        <div class="dashboard">
            <div class="card bg-total">
                <h3><xsl:value-of select="$total"/></h3>
                <p>Total Tests</p>
            </div>
            <div class="card bg-pass">
                <h3><xsl:value-of select="$passed"/></h3>
                <p>Passed</p>
            </div>
            <div class="card bg-fail">
                <h3><xsl:value-of select="$failures + $errors"/></h3>
                <p>Failed / Errors</p>
            </div>
            <div class="card bg-rate">
                <h3><xsl:value-of select="$successRate"/></h3>
                <p>Success Rate</p>
            </div>
        </div>

        <div class="controls">
            <button class="btn-all" onclick="filterTable('all')">Show All</button>
            <button class="btn-pass" onclick="filterTable('status-passed')">Only Passed</button>
            <button class="btn-fail" onclick="filterTable('status-failed')">Only Failed</button>
            <input type="text" id="searchInput" onkeyup="searchTable()" placeholder="Search test case name..."/>
        </div>

        <table>
            <thead>
                <tr>
                    <th style="width: 50%">Test Case</th>
                    <th style="width: 15%">Duration</th>
                    <th style="width: 15%">Status</th>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="//testcase">
                    <xsl:variable name="statusClass">
                        <xsl:choose>
                            <xsl:when test="failure or error">status-failed</xsl:when>
                            <xsl:otherwise>status-passed</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <tr class="{$statusClass}">
                        <td>
                            <strong><xsl:value-of select="@name"/></strong>
                            <div style="font-size:0.8em; color:#888"><xsl:value-of select="@classname"/></div>

                            <xsl:if test="failure or error">
                                <xsl:variable name="id" select="generate-id()"/>
                                <div class="error-preview" onclick="toggleError('{$id}')">
                                    <xsl:value-of select="failure/@message | error/@message"/> (Click to expand)
                                </div>
                                <div id="{$id}" class="error-full">
                                    <xsl:value-of select="failure | error"/>
                                </div>
                            </xsl:if>
                        </td>
                        <td class="duration"><xsl:value-of select="@time"/>s</td>
                        <td>
                            <xsl:choose>
                                <xsl:when test="failure">
                                    <span class="badge badge-fail">Failed</span>
                                </xsl:when>
                                <xsl:when test="error">
                                    <span class="badge badge-error">Error</span>
                                </xsl:when>
                                <xsl:otherwise>
                                    <span class="badge badge-pass">Passed</span>
                                </xsl:otherwise>
                            </xsl:choose>
                        </td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </div>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
'@

    try {
        $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.Load($xmlReportFile)

        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xslContent))
        $xslt.Load($reader)

        $writer = [System.Xml.XmlTextWriter]::Create($htmlReportFile)
        $xslt.Transform($xmlDoc, $null, $writer)
        $writer.Close()

        Write-Host "Detailed HTML Report created: $htmlReportFile" -ForegroundColor Green
        Invoke-Item $htmlReportFile
    } catch {
        Write-Host "Failed to generate HTML: $_" -ForegroundColor Red
    }
} else {
    Write-Host "XML Report not found. Test might have failed completely." -ForegroundColor Red
}

Write-Host "Done."