[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($PSScriptRoot) {
    $exeDir = $PSScriptRoot
} else {
    $exeDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

$ProjectRoot = Split-Path -Parent $exeDir
$LogsDir     = Join-Path $ProjectRoot "logs"

if (-not (Test-Path $LogsDir)) {
    New-Item -Path $LogsDir -ItemType Directory | Out-Null
}

$global:LogFile   = Join-Path $LogsDir ("ssh-scan-report-{0}-{1}-{2}-UTC.log" -f $env:USERNAME, $env:COMPUTERNAME, (Get-Date -Format 'yyyy_MM_dd-HH_mm_ss'))
$global:LogWriter = [System.IO.StreamWriter]::new($global:LogFile, $true, [System.Text.Encoding]::UTF8)
$global:LogWriter.AutoFlush = $true

Register-EngineEvent -SourceIdentifier ConsoleCancelEventHandler -Action {
    if ($global:LogWriter) {
        $global:LogWriter.Flush()
        $global:LogWriter.Close()
        $global:LogWriter.Dispose()
        $global:LogWriter = $null
    }
    Log "Program interrupted. Logs closed."
    [System.Environment]::Exit(1)
}
Register-EngineEvent PowerShell.Exiting -Action {
    if ($global:LogWriter) {
        $global:LogWriter.Flush()
        $global:LogWriter.Close()
        $global:LogWriter.Dispose()
    }
}
function Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss UTC")
    $Entry = "$Timestamp [$Level] $Message"
    $global:LogWriter.WriteLine($Entry)
    Write-Host $Entry
}
function Load_List {
    param($path)
    if (Test-Path $path) {
        Get-Content $path | Where-Object { $_ -and ($_ -notmatch '^#') } | ForEach-Object { $_.Trim() }
    } else {
        Log "Missing config file: $path" "WARNING"
        return @()
    }
}
$Match_SSHFileBlock = {
    param($filePath, $sshTokens, $cryptoExtensions, $batchExtensions, $libraryExtensions)
    try {
        $fileInfo = [System.IO.FileInfo]::new($filePath)
        if ($null -eq $fileInfo -or -not $fileInfo.Exists) {
            Log "DEBUG: Invalid FileInfo object - $filePath"
            return $false
        }
        $fullPath = $fileInfo.FullName.ToLowerInvariant()
        $fileName = $fileInfo.Name.ToLowerInvariant()
        $fileExt  = $fileInfo.Extension.ToLowerInvariant()
        $isLikelyHash = $fileName -match '^[a-f0-9]{32,}$'

        if ($fileInfo.Length -eq 0 -or $isLikelyHash) {
            Log "DEBUG: $filePath skipped - Length=$($fileInfo.Length), IsHash=$isLikelyHash"
            return $false
        }
        $hasTokenMatch = $sshTokens.Where({ $fullPath -like "*$_*" })
        $allExtensions = $cryptoExtensions + $batchExtensions + $libraryExtensions
        $hasKnownExt = $allExtensions -contains $fileExt
        $hasNoExt = [string]::IsNullOrWhiteSpace($fileExt)
        $hasContentMatch = $false
        try {
            $content = [System.IO.File]::ReadAllText($filePath)
            $lines = $content -split "`r?`n"
            if ($lines.Count -gt 20) { $lines = $lines[0..19] }

            foreach ($token in $sshTokens) {
                foreach ($line in $lines) {
                    if ($line -like "*$token*") {
                        $hasContentMatch = $true
                        break
                    }
                }
                if ($hasContentMatch) { break }
            }
        } catch {
            Log "DEBUG: $filePath content unreadable - $($_.Exception.Message)"
        }
        $matchResult = ($hasTokenMatch.Count -gt 0 -or $hasKnownExt -or $hasNoExt -or $hasContentMatch)
        Log "DEBUG: $filePath - Ext=$fileExt, KnownExt=$hasKnownExt, TokenMatch=$($hasTokenMatch.Count), ContentMatch=$hasContentMatch"
        return $matchResult
    } catch {
        Log "DEBUG: $filePath error - $($_.Exception.Message)"
        return $false
    }
}
function Show-ProgressRectangle {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity = "Scanning"
    )

    if ($Total -le 0) {
        $percent = 0
    } else {
        $percent = [math]::Round(($Current / $Total) * 100, 0)
    }
    $width  = 88
    $filled = [math]::Round(($percent / 100) * $width)
    $empty  = $width - $filled
    $bar = ("#" * $filled) + ("-" * $empty)
    $msg = ("`r{0,-20} [{1}] {2}% ({3}/{4})" -f $Activity, $bar, $percent, $Current, $Total)
    Log $msg -NoNewline
    $global:LogWriter.WriteLine($msg)
}
function GetHtmlFromLog {
    if ($PSScriptRoot) {
        $exeDir = $PSScriptRoot
    } else {
        $exeDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    }
    $ProjectRoot = Split-Path -Parent $exeDir
    $LogsDir     = Join-Path $ProjectRoot "logs"
    $ReportsDir  = Join-Path $ProjectRoot "reports"
    $ConfigDir   = Join-Path $ReportsDir "config"
    $logFile = Get-ChildItem -Path $LogsDir -Filter "ssh-scan-report-*.log" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
    if (-not $logFile) {
        Log "No log file found in $LogsDir"
        exit
    }
    $templatePath = Join-Path $ConfigDir "tmp-report-template.html"
    $cssPath      = Join-Path $ConfigDir "report-style.css"
    if (-not (Test-Path $templatePath)) {
        Log "Missing HTML template: $templatePath"
        exit
    }
    $template = Get-Content $templatePath -Raw
    $rows = "" 
    Get-Content $logFile.FullName | 
    ForEach-Object { $line = $_.Trim() 
        if ($line) { 
            $escapedPath = $line -replace '\\','/' -replace ' ', '%20' 
            $fileUrl = "file:///$escapedPath" 
            $rows += "<tr><td><a href='$fileUrl'>$line</a></td></tr>`n" } 
    }
    $html = $template -replace "{{timestamp}}", (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
    $html = $html -replace "{{rows}}", $rows
    $html = $html -replace "{{css}}", $cssPath
    $reportPath = Join-Path $ReportsDir "ssh-log-report.html"
    Set-Content -Path $reportPath -Value $html -Encoding UTF8
    Log "HTML report created: $reportPath"
}
function SSH_Scan {
    param(
        [string]$Root = "$env:USERPROFILE\.ssh"
    )

    if ($PSVersionTable.Platform) {
        $platform = $PSVersionTable.Platform
    } elseif ($IsWindows) {
        $platform = "Win32NT"
    } else {
        $platform = [System.Environment]::OSVersion.Platform.ToString()
    }
    Log "################################################################################"
    Log "1. Scanning SSH keys"
    Log "################################################################################"  
    $username  = $env:USERNAME
    $hostname  = $env:COMPUTERNAME
    $timestamp = [DateTime]::UtcNow.ToString("yyyy_MM_dd-HH_mm_ss")
    if ($PSScriptRoot) {
        $exeDir = $PSScriptRoot
    } else {
        $exeDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    }
    $ProjectRoot = Split-Path -Parent $exeDir
    $ConfigLibDir= Join-Path $ProjectRoot "config"
    $LogsDir     = Join-Path $ProjectRoot "logs"
    $ReportsDir  = Join-Path $ProjectRoot "reports"
    $ConfigDir   = Join-Path $ReportsDir "config"
    foreach ($folder in @($LogsDir, $ReportsDir)) {
        if (-not (Test-Path $folder)) {
            New-Item -Path $folder -ItemType Directory | Out-Null
        }
    }
    $templatePath = Join-Path $ConfigDir "report-template.html"
    Log "Looking for template at: $templatePath"
    $HtmlPath = "$ReportsDir/ssh-scan-report-$username-$hostname-$timestamp-UTC.html"
    $LogFile  = "$LogsDir/ssh-scan-report-$username-$hostname-$timestamp-UTC.log"
    $startTime = [DateTime]::UtcNow
    if (Test-Path $Root) {
        Log "Starting SSH file scan in: $Root"
        for ($i = 1; $i -le 10; $i++) {
            Show-ProgressRectangle -Current $i -Total 10 -Activity "Scanning directories"
            Start-Sleep -Milliseconds 300
        }
        Log ""
    } else {
        Log "Path to the default .ssh dir was not found: $Root" "ERROR"
    }    

    $sshTokens         = Load_List("$ConfigLibDir/ssh-tokens.txt")
    $cryptoExtensions  = Load_List("$ConfigLibDir/crypto-extensions.txt")
    $batchExtensions   = Load_List("$ConfigLibDir/win-batch-extensions.txt")
    $libraryExtensions = Load_List("$ConfigLibDir/library-extensions.txt")
    Log "Loaded extensions: $($cryptoExtensions + $batchExtensions + $libraryExtensions -join ', ')"

    $results      = [System.Collections.Concurrent.ConcurrentBag[System.IO.FileInfo]]::new()
    $accessDenied = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $totalFiles   = 0
    $allStats     = @()
    $directories  = @()

    if ((Test-Path $Root) -and (([System.IO.DirectoryInfo]::new($Root)).Exists)) {
        Log "Enumerating directories under: $Root"
        $directories += $Root
        $directories += Get-ChildItem -Path $Root -Directory -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
        Log "DEBUG: Directories to scan: $($directories -join ', ')"

        $dirCount = $directories.Count
        $MaxThreads = [Math]::Min([Environment]::ProcessorCount * 2, [Math]::Max(1, [Math]::Min($dirCount, 32)))
        Log "Using $MaxThreads threads for $dirCount directories"

        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 2)
        $runspacePool.Open()
        $runspaces = @()
        $completedCount = [System.Collections.Concurrent.ConcurrentBag[int]]::new()
        $visitedDirs    = [System.Collections.Concurrent.ConcurrentDictionary[string,bool]]::new()
        $seenFiles      = [System.Collections.Concurrent.ConcurrentDictionary[string,bool]]::new()

        foreach ($dir in $directories) {
            if (-not [string]::IsNullOrWhiteSpace($dir) -and $visitedDirs.TryAdd($dir, $true)) {
                $ps = [powershell]::Create()
                $ps.RunspacePool = $runspacePool
                $ps.AddScript({
                    param($dir, $sshTokens, $cryptoExtensions, $batchExtensions, $libraryExtensions, $visitedDirs, $seenFiles, $Match_SSHFileBlock)
                    $localResults   = @()
                    $localDenied    = @()
                    $localFileCount = 0
                    $threadStats = [PSCustomObject]@{
                        ThreadID       = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime      = [DateTime]::UtcNow
                        FilesScanned   = 0
                        MatchesFound   = 0
                        AccessDenied   = 0
                    }
                    $stack = [System.Collections.Generic.Stack[string]]::new()
                    if (-not [string]::IsNullOrWhiteSpace($dir)) { $stack.Push($dir) }
                    while ($true) {
                        $current = $null
                        try {
                            try {
                                if ($stack.Count -eq 0) { break }
                                $current = $stack.Pop()
                            } catch {
                                Log "DEBUG: Stack empty - breaking loop"
                                break
                            }
                            if ([string]::IsNullOrWhiteSpace($current)) {
                                continue
                            }
                            $files = @()
                            foreach ($path in [System.IO.Directory]::EnumerateFiles($current)) {
                                $files += [System.IO.FileInfo]::new($path)
                            }
                            $threadStats.FilesScanned += $files.Count
                            $localFileCount += $files.Count
                            $sshDir = Join-Path $env:USERPROFILE ".ssh"

                            foreach ($filePath in $files) {
                                if ($null -ne $filePath -and -not [string]::IsNullOrWhiteSpace($filePath.FullName)) {
                                    $fullPath = $filePath.FullName

                                    if ($seenFiles.TryAdd($fullPath, $true)) {
                                        try {
                                            if ($fullPath.StartsWith($sshDir, [System.StringComparison]::OrdinalIgnoreCase)) {
                                                $localResults += $filePath
                                                $threadStats.MatchesFound++
                                                Log "SSH MATCHED: $($filePath.FullName)"
                                            }
                                            else {
                                                if (& $Match_SSHFileBlock $filePath.FullName $sshTokens $cryptoExtensions $batchExtensions $libraryExtensions) {
                                                    $localResults += $filePath
                                                    $threadStats.MatchesFound++
                                                    Log "MATCHED: $($filePath.FullName)"
                                                } else {
                                                    Log "NOT MATCHED: $($filePath.FullName)"
                                                }
                                            }
                                        } catch {
                                            $msg = $_.Exception.Message
                                            if ($msg -match "access.*denied" -or $msg -match "unauthorized") {
                                                $localDenied += "$($filePath.FullName) (denied)"
                                                $threadStats.AccessDenied++
                                            }
                                        }
                                    }
                                }
                            }
                            $subDirs = [System.IO.Directory]::EnumerateDirectories($current).ToArray()
                            foreach ($subDir in $subDirs) {
                                if (-not [string]::IsNullOrWhiteSpace($subDir) -and $visitedDirs.TryAdd($subDir, $true)) {
                                    $stack.Push($subDir)
                                }
                            }
                        } catch {
                            $msg = $_.Exception.Message
                            if ($msg -match "access.*denied" -or $msg -match "unauthorized") {
                                $localDenied += "$current (denied)"
                                $threadStats.AccessDenied++
                            }
                        }
                    }
                    $threadStats.EndTime = [DateTime]::UtcNow
                    return @{ Results = $localResults; Denied = $localDenied; FileCount = $localFileCount; Stats = $threadStats }
                }).AddArgument($dir).AddArgument($sshTokens).AddArgument($cryptoExtensions).AddArgument($batchExtensions).AddArgument($libraryExtensions).AddArgument($visitedDirs).AddArgument($seenFiles).AddArgument($Match_SSHFileBlock)
                $handle = $ps.BeginInvoke()
                $runspaces += @{ Handle = $handle; PS = $ps }
            }
        }
        foreach ($runspace in $runspaces) {
            $output = $runspace.PS.EndInvoke($runspace.Handle)
            if ($output.ContainsKey("Results")) {
                foreach ($file in $output.Results) {
                    $results.Add($file)
                }
            }
            if ($output.ContainsKey("Denied")) {
                foreach ($deniedPath in $output.Denied) {
                    $accessDenied.Add($deniedPath)
                }
            }
            if ($output.ContainsKey("FileCount")) {
                $totalFiles += $output.FileCount
            }
            if ($output.ContainsKey("Stats")) {
                $allStats += $output.Stats
            }
            $runspace.PS.Dispose()
            $completedCount.Add(1)
            Show-ProgressRectangle -Current $completedCount.Count -Total $dirCount -Activity "Scanning SSH files"
        }

        $duration = [DateTime]::UtcNow - $startTime
        Log "Enumerating directories completed. Found $($results.Count) SSH-related files. Access denied on $($accessDenied.Count) paths."

        $templatePath = "$ReportsDir/config/report-template.html"
        if (-not [System.IO.File]::Exists($templatePath)) {
            Log "[ERROR] Missing HTML template: $templatePath"
            return
        }

        $template = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
        $rowHtml = ""
        $finalResults = foreach ($file in $results.ToArray()) {
            try {
                $acl = [System.IO.File]::GetAccessControl($file.FullName)
                $owner = $acl.GetOwner([System.Security.Principal.NTAccount]).Value
            } catch {
                $owner = "Unknown"
            }
            $sha256 = try {
                if ($null -eq $file -or -not ([System.IO.File]::Exists($file.FullName))) {
                    Log "DEBUG: File does not exist or is null - $($file.FullName)"
                    $null
                } else {
                    $fileInfo = [System.IO.FileInfo]::new($file.FullName)
                    if ($fileInfo.Length -gt 0) {
                        $stream = [System.IO.File]::Open($file.FullName, 'Open', 'Read', 'ReadWrite')
                        $hasher = [System.Security.Cryptography.SHA256]::Create()
                        $hashBytes = $hasher.ComputeHash($stream)
                        $stream.Close()
                        [BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
                    } else {
                        $null
                    }
                }
            } catch {
                Log "DEBUG: SHA256 error - $($_.Exception.Message)"
                $null
            }
            $escapedPath = $file.FullName -replace '\\', '/' -replace ' ', '%20'
            $fileUrl = "file:///$escapedPath"
            $escapedParent = $file.DirectoryName -replace '\\', '/' -replace ' ', '%20'
            $parentUrl = "file:///$escapedParent"
            $rowHtml += "<tr><td><a href='$parentUrl'>$($file.DirectoryName)</a></td><td><a href='$fileUrl'>$($file.FullName)</a></td><td>$($file.Name)</td><td>$($file.Length)</td><td>$($file.CreationTime.ToUniversalTime())</td><td>$($file.LastWriteTime.ToUniversalTime())</td><td>$sha256</td><td>$owner</td></tr>"
            [PSCustomObject]@{
                Parent   = $file.DirectoryName
                Path     = $file.FullName
                Name     = $file.Name
                Length   = $file.Length
                Created  = $file.CreationTime.ToUniversalTime()
                Modified = $file.LastWriteTime.ToUniversalTime()
                SHA256   = $sha256
                Owner    = $owner
            }
        }

        $html = $template -replace "{{timestamp}}", [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss UTC")
        $html = $html -replace "{{rows}}", $rowHtml
        [System.IO.File]::WriteAllText($HtmlPath, $html, [System.Text.Encoding]::UTF8)
        foreach ($path in $accessDenied.ToArray()) {
            Diagnose_AccessIssue $path
        }
        if ($accessDenied.Count -gt 0) {
            Log "Access Denied:"
            foreach ($item in $accessDenied.ToArray() | Sort-Object) {
                $timestamp = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss UTC")
                Log "$timestamp [WARNING] > $item"
            }
        }

        Log "Thread Summary:"
        foreach ($stat in $allStats) {
            Log " > ThreadId $($stat.ThreadID): Files=$($stat.FilesScanned), Matches=$($stat.MatchesFound), Denied=$($stat.AccessDenied), Duration=$($duration.ToString())"
        }

        Log " Scan Summary:"
        Log " > Directories scanned  : $dirCount"
        Log " > Files scanned        : $totalFiles"
        Log " > Matches found        : $($results.Count)"
        Log " > Access denied paths  : $($accessDenied.Count)"
        Log " > Duration             : $($duration.ToString())"
        Log " > Log saved to         : $LogFile"
        Log " > HTML report saved to : $HtmlPath"
        Log " SSH File Scan Completed"        
    } else {
        Log "Path to the default .ssh dir was not found: $Root" "ERROR"
    }

    # ---------------------------------------------------------------------------------------------------------------------------------------------
    # 2. Active SSH-related processes
    # ---------------------------------------------------------------------------------------------------------------------------------------------
    Log "################################################################################"
    Log "2. Active SSH-related processes"
    Log "################################################################################"
    
    if ($platform -eq "Win32NT") {
        Get-Process | Where-Object { $_.ProcessName -match "ssh" } | Format-Table Name, Id, StartTime
    } else {
        Get-Process -eo pid,comm,args | grep -E "ssh|sshd" | grep -v grep
    }

    # ---------------------------------------------------------------------------------------------------------------------------------------------
    # 3. TCP connections on tunneling ports
    # ---------------------------------------------------------------------------------------------------------------------------------------------
    Log "################################################################################"
    Log "3. TCP connections on tunneling ports"
    Log "################################################################################"

    $tunnelingPorts = @(22, 2222, 8022, 1080, 443, 80, 53, 3306, 3389) + (5900..5999)

    if ($platform -eq "Win32NT") {
        $table = Get-NetTCPConnection |
            Where-Object { $_.State -eq "Established" -and $tunnelingPorts -contains $_.RemotePort } |
            Format-Table LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess -AutoSize |
            Out-String

        Log $table
    }
    else {
        foreach ($port in $tunnelingPorts) {
            $lines = netstat -an | Select-String ":$port " | Select-String "ESTABLISHED"
            if ($lines) { Log $lines }
        }
    }

    # ---------------------------------------------------------------------------------------------------------------------------------------------
    # 4. Scheduled tasks / cron jobs
    # ---------------------------------------------------------------------------------------------------------------------------------------------
    Log "################################################################################"
    Log "4. Scheduled tasks / cron jobs"
    Log "################################################################################"      
    Log "`nScheduled SSH-related tasks:"
    if ($platform -eq "Win32NT") {
        Get-ScheduledTask | Where-Object { $_.Actions.ToString() -match "ssh" } | Format-Table TaskName, State
    } else {
        crontab -l | grep -i ssh
    }

    # ---------------------------------------------------------------------------------------------------------------------------------------------
    # 5. Startup entries referencing SSH
    # ---------------------------------------------------------------------------------------------------------------------------------------------
    Log "################################################################################"
    Log "5. Startup entries referencing SSH"
    Log "################################################################################"        
    Log "`nStartup entries referencing SSH:"
    if ($platform -eq "Win32NT") {
        $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        Get-ChildItem $startupFolder -Recurse | Where-Object { $_.Name -match "ssh" } | Format-Table Name, FullName
    } else {
        Get-ChildItem ~/.config/autostart ~/.config/systemd/user 2>$null | grep -i ssh
    }

    # ---------------------------------------------------------------------------------------------------------------------------------------------
    # 6. authorized_keys inspection
    # ---------------------------------------------------------------------------------------------------------------------------------------------
    Log "################################################################################"
    Log "6. authorized_keys inspection"
    Log "################################################################################"   
    Log "`nauthorized_keys:"
    if ($platform -eq "Win32NT") {
        $hm = $env:USERPROFILE
    } else {
        $hm = $env:HOME
        if (-not $hm) { $hm = [Environment]::GetFolderPath("UserProfile") }
    }
    $locations = @(
        (Join-Path (Join-Path $hm ".ssh") "authorized_keys"),
        (Join-Path $env:ProgramData "ssh\authorized_keys"),
        (Join-Path $env:SystemRoot "System32\OpenSSH\authorized_keys")
    )
    foreach ($authKeysPath in $locations) {
        Log "Checking: $authKeysPath"
        if (Test-Path -LiteralPath $authKeysPath) {
            $fileInfo = Get-Item -LiteralPath $authKeysPath -ErrorAction SilentlyContinue
            if ($fileInfo -and $fileInfo.Name -eq "authorized_keys") {
                $lines = Get-Content -LiteralPath $fileInfo.FullName -ErrorAction SilentlyContinue |
                    Where-Object { $_ -and ($_ -notmatch '^\s*$') }
                if ($lines.Count -gt 0) {
                    Log "Found $($lines.Count) entries in $authKeysPath"
                    foreach ($line in $lines) {
                        Log "-> $line"
                    }
                } else {
                    Log "authorized_keys file is empty at $authKeysPath"
                }
            }
        } else {
            Log "No authorized_keys file found at $authKeysPath"
        }
    }

    # ---------------------------------------------------------------------------------------------------------------------------------------------
    # 7. Windows Event Logs (User Context) 
    # ---------------------------------------------------------------------------------------------------------------------------------------------
    Log "################################################################################"
    Log "7. Windows Event Logs (User Context)"
    Log "################################################################################"      
    $sshEvents = Get-WinEvent -LogName Application -ErrorAction SilentlyContinue | Where-Object {$_.Message -match "ssh" }
    Log "Application EventLog: $($sshEvents.Count) entries matched 'ssh'" "ERROR"
    $sshEvents | Select-Object -First 5 |
        ForEach-Object {
            Log "Sample EventLog: Time=$($_.TimeCreated) Id=$($_.Id) Provider=$($_.ProviderName)" "ERROR"
        }
    Log "Application EventLog: $($sshEvents.Count) entries matched 'ssh'" "WARNING"
    $sshEvents | Select-Object -First 5 |
        ForEach-Object {
            Log "Sample EventLog: Time=$($_.TimeCreated) Id=$($_.Id) Provider=$($_.ProviderName)" "ERROR"
        }    

    # ---------------------------------------------------------------------------------------------------------------------------------------------
    # 8. PowerShell / CMD History
    # ---------------------------------------------------------------------------------------------------------------------------------------------
    Log "################################################################################"
    Log "8. PowerShell / CMD History"
    Log "################################################################################"      
    $psHistory = Join-Path $env:APPDATA "Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    if (Test-Path $psHistory) {
        Log "Checking PowerShell history: $psHistory"
        $psMatches = Select-String -Path $psHistory -Pattern "ssh" 
        Log "PSHistory: $($psMatches.Count) entries matched 'ssh'" "INFO"
        $psMatches | ForEach-Object { Log "PSHistory sample: $($_.Line)" "INFO" }
    } else {
        Log "No PowerShell history file found."
    }

    $cmdHistory = Join-Path $env:USERPROFILE "AppData\Roaming\Microsoft\Windows\cmd_history.txt"
    if (Test-Path $cmdHistory) {
        Log "Checking CMD history: $cmdHistory"
        $cmdMatches = Select-String -Path $cmdHistory -Pattern "ssh" 
        Log "CMDHistory: $($cmdMatches.Count) entries matched 'ssh'" "INFO"
        $cmdMatches | ForEach-Object { Log "CMDHistory sample: $($_.Line)" "INFO" }
    } else {
        Log "No CMD history file found."
    }

    $bashHistory = Join-Path $env:USERPROFILE ".bash_history"
    if (Test-Path $bashHistory) {
        Log "Checking WSL bash history: $bashHistory"
        $bashMatches = Select-String -Path $bashHistory -Pattern "ssh"
        Log "BashHistory: $($bashMatches.Count) entries matched 'ssh'" "INFO"
        $bashMatches | ForEach-Object { Log "BashHistory sample: $($_.Line)" "INFO" }
    } else {
        Log "No bash history file found."
    }         

    # ---------------------------------------------------------------------------------------------------------------------------------------------
    # 9. Application Logs
    # ---------------------------------------------------------------------------------------------------------------------------------------------
    function Scan_ApplicationLogsForSSH {
        param(
            [string[]]$Paths = @(
                "$env:APPDATA\PuTTY",
                "$env:APPDATA\WinSCP",
                "$env:LOCALAPPDATA"
            ),
            [string]$Pattern    = "ssh",
            [int]$MaxSamples    = 5,
            [int]$MaxFileSizeMB = 5
        )

        Log "################################################################################"
        Log "9. Application Logs"
        Log "################################################################################"
        Log "Scanning application logs for pattern '$Pattern'"

        foreach ($path in $Paths) {
            if (-not (Test-Path $path)) { continue }

            Log "Checking: $path"
            Log "Please wait..."

            $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Length -lt ($MaxFileSizeMB * 1MB) }

            if (-not $files) {
                Log "No eligible files found in $path" "INFO"
                continue
            }

            $existingFiles = $files | Where-Object { Test-Path $_.FullName }

            if ($existingFiles) {
                try {
                    $matches = Select-String -Path $existingFiles.FullName -Pattern $Pattern -SimpleMatch -ErrorAction SilentlyContinue
                } catch {
                    $matches = @()
                }

                $count = $matches.Count
                Log "Found $count '$Pattern' entries in $path" "INFO"

                $matches | Select-Object -First $MaxSamples | ForEach-Object {
                    Log "Sample: $($_.Path) -> $($_.Line)" "INFO"
                }
            }
        }
    }
    Scan_ApplicationLogsForSSH
    GetHtmlFromLog
}
# ---------------------------------------------------------------------------------------------------------------------------------------------
try {
    SSH_Scan
    Log "Scan completed."
}
finally {
    if ($global:LogWriter) {
        $global:LogWriter.Flush()
        $global:LogWriter.Close()
        $global:LogWriter.Dispose()
        $global:LogWriter = $null
    }
}
 # ---------------------------------------------------------------------------------------------------------------------------------------------
