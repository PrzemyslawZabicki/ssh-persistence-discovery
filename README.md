📄 README.md

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-lime?logo=powershell)](https://learn.microsoft.com/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-lime?logo=windows)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/github/license/PrzemyslawZabicki/persistence-discovery)](LICENSE)
[![Stars](https://img.shields.io/github/stars/PrzemyslawZabicki/persistence-discovery?style=social)](https://github.com/PrzemyslawZabicki/persistence-discovery/stargazers)
[![Issues](https://img.shields.io/github/issues/PrzemyslawZabicki/persistence-discovery)](https://github.com/PrzemyslawZabicki/persistence-discovery/issues)


### Windows-based PowerShell-CLI application that scans for SSH-related artifacts, persistence mechanisms, and forensic traces.  

##  Persistence-Discovery

### DESCRIPTION

It is a script designed to search and output numerous forms of persistence on the host.  
It includes the following persistence locations:  
   > Registry Run Values  
   > Registry Winlogon Values  
   > Registry Installed Components Keys  
   > Services  
   > Schedule Tasks  
   > Startup Folders  

**Version:**        1.0  
**Author:**         Collin Montenegro  
**Creation Date:**  02/15/2020  
**Purpose/Change:** Initial script development  

---

## SSH_Scan

### DESCRIPTION

It is a script designed to search and output SSH-related artifacts and forensic traces on the host.  
It includes the following discovery locations:  
   > `.ssh` directories and key files  
   > SSH configuration files  
   > Authorized keys  
   > Active SSH processes  
   > TCP connections on tunneling ports  
   > Scheduled tasks referencing SSH  
   > Startup entries referencing SSH  
   > Application logs (PuTTY, WinSCP, etc.)  
   > PowerShell / CMD / WSL history  

**Version:**        1.0  
**Author:**         Przemyslaw Zabicki  
**Creation Date:**  11/19/2025  
**Purpose/Change:** Initial script development of SSH artifact scanner  



### 📂 Combined Workflow Diagram

```text
+-------------------------------------------------------------+
| 🔒 Persistence-Discovery (Collin Montenegro, 2020)          |
|  - Registry Run values                                      |
|  - Registry Winlogon values                                 |
|  - Registry Installed Components                            |
|  - Services                                                 |
|  - Scheduled Tasks                                          |
|  - Startup Folders                                          |
+-------------------------------------------------------------+

                          |
                          v

+-------------------------------------------------------------+
| 🔍 SSH_Scan (Przemyslaw Zabicki, 2025)                      |
|  - Scan .ssh directories, keys, configs                     |
|  - Inspect authorized_keys                                  |
|  - Detect active SSH processes                              |
|  - Check tunneling TCP ports                                |
|  - Scheduled tasks referencing SSH                          |
|  - Startup entries referencing SSH                          |
|  - Application logs (PuTTY, WinSCP, etc.)                   |
|  - PowerShell / CMD / WSL history                           |
+-------------------------------------------------------------+

                          |
                          v

+-------------------------------------------------------------+
| 📊 Output                                                   |
|  - Logs saved to /logs                                      |
|  - HTML reports saved to /reports                           |
|  - Reports styled with /reports/config template + CSS       |
|  - Clickable file:/// links for forensic navigation         |
+-------------------------------------------------------------+
⚡ Quick Start
Run the PowerShell script:

powershell
.\Persistence-Discovery.ps1


Start the SSH scan:
powershell
```bash
.\src\SSH_Scan.ps1 
```

Run the compiled executable directly:
powershell
```bash
.\bin\SSH_Scan.exe
```

Generate HTML report from logs:
powershell
```bash
GetHtmlFromLog
```

powershell
If you want to build exe file from the PowerShell script go to the project main folder
```bash
Install-Module -Name PS2EXE -Scope CurrentUser
Import-Module PS2EXE
Invoke-PS2EXE -InputFile ".\src\SSH_Scan.ps1" -OutputFile ".\bin\SSH_Scan.exe"
```

💡 Features:

🔍 SSH Artifact Discovery — scans .ssh folders, keys, configs, and related files.

📊 Multi-threaded File Scanning — parallel runspaces with live progress bar.

📝 Logging — timestamped logs under logs/.

🌐 HTML Reporting — styled reports with clickable file links and metadata.

🛡️ Security Checks — active processes, tunneling ports, scheduled tasks, startup entries, authorized_keys.

📂 Historic Traces — PowerShell history, CMD history, WSL .bash_history, PuTTY/WinSCP logs. scanning LOCALAPPDATA

📂 Project Structure
```text
├── config/                                   # Token lists and extension definitions
│   ├── ssh-tokens.txt
│   ├── crypto-extensions.txt
│   ├── file-extensions.txt
│   ├── library-extensions.txt
│   ├── win-batch-extensions.txt
├── logs/                                     # Generated log files
│   └── ssh-scan-report-username-hostname-yyyy_MM_dd-HH_mm_ss-UTC.log
├── reports/                                  # Generated HTML reports
│   ├── ssh-log-report.html
│   ├── ssh-scan-report-username-hostname-yyyy_MM_dd-HH_mm_ss-UTC.html
│   └── config/                               # HTML template and CSS
├── src/                                      # Source scripts
│   ├── SSH_Scan.ps1						  # SSH persistence script
│   ├── Persistence-Discovery.ps1			  # General persistence script
│   └── create-config-files.cmd               # Create config files
├── bin/                                      # Compiled executables
│   └── SSH_Scan.exe
├── Persistence-Discovery.ps1                 # Main PowerShell script (entry point)
└── README.md                                 # Documentation


📡 Live Logging  
Logs are written to `logs/SSH_Scan-report-<user>-<host>-<timestamp>-UTC.log`


Console output streams live with color-coded matches.

HTML reports saved to reports/SSH_Scan-report-<user>-<host>-<timestamp>-UTC.html.

🛠️ Requirements
Windows 10/11

PowerShell 5.1+ or PowerShell Core

📜 License
This project is licensed under the MIT License. See the LICENSE file for details.

🤝 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

📧 Contact
Persistence-Discovery.ps1 created by Collin Montenegro

SSH_Scan created and maintained by Przemyslaw Zabicki

Reach out via GitHub Issues.