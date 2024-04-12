$Host.UI.RawUI.WindowTitle = "Signal Portable Updater " + $Host.Version;
cls
##elevate to admin
Write-Host "*************************************************************************************"
Write-Host "                     Checking for Administrator Elevation..."
Write-Host "*************************************************************************************"

Write-Host "Prompting user to elevate if needed."
Write-Host " "

Start-Sleep -Milliseconds 1500

# Get the ID and security principal of the current user account
 $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
 $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

 # Get the security principal for the Administrator role
 $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

 # Check to see if we are currently running "as Administrator"
 if ($myWindowsPrincipal.IsInRole($adminRole))
    {
    # We are running "as Administrator" - so change the title and background color to indicate this
    $Host.UI.RawUI.WindowTitle = "Signal Portable Updater (Elevated)"
    $Host.UI.RawUI.BackgroundColor = "Black"
	$Host.UI.RawUI.ForegroundColor = "Green"
    clear-host
    }
 else
    {
    # We are not running "as Administrator" - so relaunch as administrator

    # Create a new process object that starts PowerShell
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";

    # Specify the current script path and name as a parameter
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;

    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";

    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess);

    # Exit from the current, unelevated, process
    exit
    }

#-------------------- Run your code that needs to be elevated here ----------------------#
 
##functions

function Write-Color {
<#
.EXAMPLE
    Write-Color -Text "Red ", "Green ", "Yellow " -Color Red,Green,Yellow
#>

    [alias('Write-Colour')]
    [CmdletBinding()]
    param (
        [alias ('T')] [String[]]$Text,
        [alias ('C', 'ForegroundColor', 'FGC')] [ConsoleColor[]]$Color = [ConsoleColor]::White,
        [alias ('B', 'BGC')] [ConsoleColor[]]$BackGroundColor = $null,
        [alias ('Indent')][int] $StartTab = 0,
        [int] $LinesBefore = 0,
        [int] $LinesAfter = 0,
        [int] $StartSpaces = 0,
        [alias ('L')] [string] $LogFile = '',
        [Alias('DateFormat', 'TimeFormat')][string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
        [alias ('LogTimeStamp')][bool] $LogTime = $true,
        [int] $LogRetry = 2,
        [ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')][string]$Encoding = 'Unicode',
        [switch] $ShowTime,
        [switch] $NoNewLine,
        [alias('HideConsole')][switch] $NoConsoleOutput
    )
    if (-not $NoConsoleOutput) {
        $DefaultColor = $Color[0]
        if ($null -ne $BackGroundColor -and $BackGroundColor.Count -ne $Color.Count) {
            Write-Error "Colors, BackGroundColors parameters count doesn't match. Terminated."
            return
        }
        if ($LinesBefore -ne 0) {
            for ($i = 0; $i -lt $LinesBefore; $i++) {
                Write-Host -Object "`n" -NoNewline 
            } 
        } # Add empty line before
        if ($StartTab -ne 0) {
            for ($i = 0; $i -lt $StartTab; $i++) {
                Write-Host -Object "`t" -NoNewline 
            } 
        }  # Add TABS before text
        if ($StartSpaces -ne 0) {
            for ($i = 0; $i -lt $StartSpaces; $i++) {
                Write-Host -Object ' ' -NoNewline 
            } 
        }  # Add SPACES before text
        if ($ShowTime) {
            Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline 
        } # Add Time before output
        if ($Text.Count -ne 0) {
            if ($Color.Count -ge $Text.Count) {
                # the real deal coloring
                if ($null -eq $BackGroundColor) {
                    for ($i = 0; $i -lt $Text.Length; $i++) {
                        Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline 
                    }
                }
                else {
                    for ($i = 0; $i -lt $Text.Length; $i++) {
                        Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline 
                    }
                }
            }
            else {
                if ($null -eq $BackGroundColor) {
                    for ($i = 0; $i -lt $Color.Length ; $i++) {
                        Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline 
                    }
                    for ($i = $Color.Length; $i -lt $Text.Length; $i++) {
                        Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -NoNewline 
                    }
                }
                else {
                    for ($i = 0; $i -lt $Color.Length ; $i++) {
                        Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline 
                    }
                    for ($i = $Color.Length; $i -lt $Text.Length; $i++) {
                        Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -BackgroundColor $BackGroundColor[0] -NoNewline 
                    }
                }
            }
        }
        if ($NoNewLine -eq $true) {
            Write-Host -NoNewline 
        }
        else {
            Write-Host 
        } # Support for no new line
        if ($LinesAfter -ne 0) {
            for ($i = 0; $i -lt $LinesAfter; $i++) {
                Write-Host -Object "`n" -NoNewline 
            } 
        }  # Add empty line after
    }
    if ($Text.Count -and $LogFile) {
        # Save to file
        $TextToFile = ""
        for ($i = 0; $i -lt $Text.Length; $i++) {
            $TextToFile += $Text[$i]
        }
        $Saved = $false
        $Retry = 0
        Do {
            $Retry++
            try {
                if ($LogTime) {
                    "[$([datetime]::Now.ToString($DateTimeFormat))] $TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
                }
                else {
                    "$TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
                }
                $Saved = $true
            }
            catch {
                if ($Saved -eq $false -and $Retry -eq $LogRetry) {
                    Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Tried ($Retry/$LogRetry))"
                }
                else {
                    Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Retrying... ($Retry/$LogRetry)"
                }
            }
        } Until ($Saved -eq $true -or $Retry -ge $LogRetry)
    }
}


function Write-FlagColor {
<#
.EXAMPLE
    Write-FlagColor -mMsg "[*] this is a test"
	Write-FlagColor -mMsg "[!] this is a test"
	Write-FlagColor -mMsg "[#] this is a test"
	Write-FlagColor -mMsg "[+] this is a test"
#>

    param (
        [string]$mMsg
    )

    $mFlag = $mMsg[1]
    $strippedMsg = $mMsg.Substring(3)

    Write-Host "[" -NoNewline

    switch ($mFlag) {
        "*" {
            Write-Color -text "*" -c Yellow -noNewLine
        }
        "-" {
            Write-Color -text "-" -c White -noNewLine
        }
        "+" {
            Write-Color -text "+" -c Blue -noNewLine
        }
        "!" {
            Write-Color -text "!" -c Red -noNewLine
        }
        default {
            Write-Color -text $mFlag -noNewLine
        }
    }

    Write-Host "] $strippedMsg"
}


##end functions

cls
Write-Host "######################################    Signal Portable Updater     ###############################################"
Write-Host ""


# Store the original script location
$originalScriptLocation = $PWD.Path


$text = @"
  ____  _                   _
 / ___|(_) __ _ _ __   __ _| |
 \___ \| |/ _` | '_ \ / _` | |
  ___) | | (_| | | | | (_| | |
 |____/|_|\__, |_| |_|\__,_|_|   _
          |___/
  ____            _        _     _
 |  _ \ ___  _ __| |_ __ _| |__ | | ___
 | |_) / _ \| '__| __/ _` | '_ \| |/ _ \
 |  __/ (_) | |  | || (_| | |_) | |  __/
 |_|   \___/|_|   \__\__,_|_.__/|_|\___|
  _   _ ____  ____    _  _____ _____ ____
 | | | |  _ \|  _ \  / \|_   _| ____|  _ \
 | | | | |_) | | | |/ _ \ | | |  _| | |_) |
 |_| |_|  __/|_| |_/_/   \_\_| |_|____/___/
              |_|_  \/\   / ____| | | | | |  
             |_ _|  \  /  | |    | | | | | | 
              | |    \/   | |    | |_| | |_| 
             |___|         |_|     \___/ \___/ 
"@

$lines = $text -split [Environment]::NewLine

foreach ($line in $lines) {
    Write-Host $line
    Start-Sleep -Milliseconds 145
}

function AnimateText {
    param(
        [string]$text,
        [int]$delayMilliseconds = 40
    )

    foreach ($letter in $text.ToCharArray()) {
        Write-Host -NoNewline $letter
        Start-Sleep -Milliseconds $delayMilliseconds
    }

    Write-Host  # Write a new line after the animation is complete
}


Write-Host ""
AnimateText "^^^ thanks for the gucci animation chatgpt..."
Start-Sleep -Milliseconds 400
AnimateText "                          --whalelinguini"
Start-Sleep -Seconds 3
Write-Host ""
cls

$continue = Read-Host "Update Signal Portable? [Y/N]"
	if($reboot -eq 'Y' -or $continue -eq 'y'){
        Write-Host ""
            }else{
            Write-Output "Kthxbye!"
			Start-Sleep -Seconds 1
			Exit
            }

cls

# Get the width of the console window
$consoleWidth = [System.Console]::WindowWidth

# Create a string of characters to fill the line
$global:fillLine = '#' * $consoleWidth

# Output the line to fill the console window width
Write-Host $fillLine


Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host $fillLine
Write-Host ""

$startTime = Get-Date
Write-Host "Start Time: $startTime"
Start-Sleep -milliseconds 600

$currentDirectory = $PWD.Path
Write-FlagColor -mMsg "[-] Working Dir: $originalScriptLocation"

Write-FlagColor -mMsg "[*] Checking current signal release..."
Invoke-RestMethod https://updates.signal.org/desktop/latest.yml -OutFile "$PWD\latest.yml"


$fileName = "latest.yml"
$filePath = Join-Path -Path $currentDirectory -ChildPath $fileName
Write-FlagColor -mMsg "[-] Latest Version Info: $filePath"

Start-Sleep -milliseconds 600


##error out if latest.yml isn't dowbloaded
$timeoutSeconds = 10

while (-not (Test-Path -Path $filePath)) {
    # Check if the timeout has been reached
    $currentTime = Get-Date
    $elapsedTime = ($currentTime - $startTime).TotalSeconds
    if ($elapsedTime -ge $timeoutSeconds) {
        Write-Error "[*] Timeout reached. latest.yml does not exist."
		Pause
        exit 1
    }

    # Wait for a short interval before checking again
    Start-Sleep -Seconds 1
}

# Read the contents of the file as plain text
$fileContent = Get-Content -Path $filePath -Raw

# Parse the yml from the line containing 'url:'
$urlLine = ($fileContent -split "`n" | Where-Object { $_ -match 'url:' })
$url = ($urlLine -split ':', 2)[1].Trim()
$fileName = $url -replace '.+/', ''



# Parse the yml from the line containing 'Version:'
function Get-YamlVersion {
    param (
        [string]$FilePath
    )

    # Read the content of the YAML file as a single string
    $content = Get-Content -Path $FilePath -Raw

    # Split the content into lines
    $lines = $content -split "`n"

    # Iterate through each line in the content
    foreach ($line in $lines) {
        # Check if the line contains "version"
        if ($line -match 'version:') {
            # Output the line containing "version"
			$line = $line -replace 'version: '
            $global:verCur=$line
            break  # Exit the loop after finding the first occurrence
        }
    }
}

Get-YamlVersion -FilePath $filePath

# Output the file name
Write-FlagColor -mMsg "[+] Signal Release Version: $verCur"
Write-FlagColor -mMsg "[+] Signal Release Binary: $fileName"
Write-Output ""

Start-Sleep -milliseconds 600


#********************************************************#
####****** test signal portable dir path  ************####
#********************************************************#
#********************************************************#

Write-FlagColor -mMsg "[*] Checking Signal Portable path."
Write-FlagColor -mMsg "[-] $PWD\App\SignalPortable\Signal.exe"
Start-Sleep -Milliseconds 600


# Path to Signal executable
$exePath = "$PWD\App\SignalPortable\Signal.exe"

# Check if the file exists
if (Test-Path -Path $exePath) {
    # Output that the path exists
    Write-FlagColor -mMsg "[+] Path exists: $exePath"
    
    # Retrieve version information
    $versionInfo = (Get-Item $exePath).VersionInfo
    
    # Output version information if available
    if ($versionInfo) {
		Write-Host ""
        Write-Host "Current Signal Version: $($versionInfo.FileVersion)"
		Write-Host ""
    } else {
        Write-FlagColor -mMsg "[!] Unknown Error: Version information not available."
		Pause
		Exit
    }
} else {
    Write-FlagColor -mMsg "[*] Error: Cannot find Signal executable at path: $exePath"
    Write-Host "    Please make sure the update binary is located in the Signal Portable root directory."
    Write-Host "    -> Root\App\Signal..\.."
    pause
    Exit
}

# Check versions

If ($versionInfo = $verCur) {
	
	$Host.UI.RawUI.ForegroundColor = "White"
	Write-Host "####--  No Update Available.  --####"
	$Host.UI.RawUI.ForegroundColor = "Green"
	Write-Host "Current Version: $versionInfo"
	Write-Host "Installed Version: $verCur"
	
	$Host.UI.RawUI.ForegroundColor = "White"
	$continue = Read-Host "No update found. Would you like to re-install the current version? [Y/N]"
	if($reboot -eq 'Y' -or $continue -eq 'y'){
        Write-Host ""
            }else{
            Write-Output "Kthxbye!"
			Start-Sleep -Seconds 1
			Exit
            }
$Host.UI.RawUI.ForegroundColor = "Green"
} else {
	$Host.UI.RawUI.ForegroundColor = "White"
	Write-Host "####--  Update Available.  --####"
	$Host.UI.RawUI.ForegroundColor = "Green"
	Write-Host "Current Version: $versionInfo"
	Write-Host "Installed Version: $verCur"
	
}
	

#***********************************************************#
####****** save where we are ******####
#***********************************************************#
#***********************************************************#

# Define $selectedFolder globally
$global:selectedFolder = "$PWD\App"



#***********************************************************#
####****** download and extract new signal desktop ******####
#***********************************************************#
#***********************************************************#


# Store the original script location
$originalScriptLocation = $PWD.Path


# Construct the URL to download the file
$fileUrl = "https://updates.signal.org/desktop/$fileName"

# Define the path to the 7zip executable (adjust this path if 7zip is installed in a different location)
$zipPath = "$PWD\7z\7z.exe"

# Define the extraction directory for the first archive
$firstExtractDir = "tmp"

# Define the extraction directory for the second archive
$secondExtractDir = "tmpSignalExtract"

Write-Host ""
Write-FlagColor -mMsg "[*] Starting Signal update!"
Start-Sleep -Milliseconds 200

# Download the file
# Check if the file exists
if (Test-Path "$PWD\$fileName") {
    Write-FlagColor -mMsg "[+] File '$fileName' already exists. Skipping download."
} else {
    # Download the file
    Write-FlagColor -mMsg "[*] Downloading installer binary..."
    Start-Sleep -Milliseconds 600
    Invoke-WebRequest -Uri $fileUrl -OutFile "$PWD\$fileName"
    Write-FlagColor -mMsg "[+] Installer binary downloaded."
}


#***********************************************************#
####******          start extractions              ******####
#***********************************************************#
#***********************************************************#

# Create the extraction directory if it doesn't exist
if (-not (Test-Path -Path $firstExtractDir -PathType Container)) {
    New-Item -Path $firstExtractDir -ItemType Directory | Out-Null
}

Write-FlagColor -mMsg "[*] Extracting installer..."
Start-Sleep -Milliseconds 600
# Extract the first archive using 7zip, always overwriting existing files

##colors
$Host.UI.RawUI.ForegroundColor = "White"

& $zipPath x "$PWD\$fileName" -o"$PWD\$firstExtractDir" -aoa

##colors
$Host.UI.RawUI.ForegroundColor = "Green"

Write-FlagColor -mMsg "[+] Extract complete"
Start-Sleep -Seconds 3
#cls

Write-Host ""
Write-Host $fillLine
Write-Host ""

Write-FlagColor -mMsg "[-] Parsing nested archive..."
Start-Sleep -Seconds 2

# Iterate through subdirectories of $firstExtractDir to find the one containing app-64.7z
$subdirs = Get-ChildItem -Path "$PWD\$firstExtractDir" -Directory
foreach ($subdir in $subdirs) {
    $app64File = Join-Path -Path $subdir.FullName -ChildPath "app-64.7z"
    if (Test-Path -Path $app64File -PathType Leaf) {
        # Move the .7z file to the original script location
        Move-Item -Path $app64File -Destination $originalScriptLocation -Force
        break  # Exit the loop after finding the file
    }
}


Write-FlagColor -mMsg "[-] Pulling binary archive..."
Start-Sleep -Milliseconds 600

# Change the working directory back to the original script location
Set-Location -Path $originalScriptLocation

# Create the extraction directory for the second archive if it doesn't exist
if (-not (Test-Path -Path $secondExtractDir -PathType Container)) {
    New-Item -Path $secondExtractDir -ItemType Directory | Out-Null
}



Write-FlagColor -mMsg "[*] Extracting archive..."
Start-Sleep -milliseconds 600
# Extract the second archive from the $PLUGINSDIR subdirectory, always overwriting existing files
## colors
$Host.UI.RawUI.ForegroundColor = "White"
& $zipPath x "$PWD\app-64.7z" -o"$PWD\$secondExtractDir" -aoa
Start-Sleep -Seconds 3
## colors
$Host.UI.RawUI.ForegroundColor = "Green"

Write-Host ""
Write-FlagColor -mMsg "[+] Extraction complete: '$PWD\$secondExtractDir'."
Write-Host ""
Start-Sleep -milliseconds 200

Write-Host ""
Write-Host $fillLine
Write-Host ""



#********************************************************#
####****** start file copy & update             ******####
#********************************************************#
#********************************************************#

#Write-Host "[D] Debug: $selectedFolder"
#pause

Write-FlagColor -mMsg "[*] Checking for running processes..."
Start-Sleep -milliseconds 600

# Check if signal.exe is running
$signalProcess = Get-Process -Name "signal" -ErrorAction SilentlyContinue

if ($signalProcess -ne $null) {
    Write-FlagColor -mMsg "[*] signal.exe is running. Attempting to close..."
    Stop-Process -Name "signal" -Force
} else {
    Write-FlagColor -mMsg "[-] signal.exe is not running."
	Start-Sleep -Milliseconds 200
}

# Check if signalportable.exe is running
$signalPortableProcess = Get-Process -Name "signalportable" -ErrorAction SilentlyContinue

if ($signalPortableProcess -ne $null) {
    Write-FlagColor -mMsg "[*] signalportable.exe is running. Attempting to close..."
    Stop-Process -Name "signalportable" -Force
} else {
    Write-FlagColor -mMsg "[-] signalportable.exe is not running."
	Start-Sleep -Milliseconds 200
}


# Define the paths
$signalPortableDirectory = Join-Path -Path $selectedFolder -ChildPath "SignalPortable"
#Write-Host "[D] Debug: $signalPortableDirectory"


# Check if $selectedFolder is not null
if ($selectedFolder) {
	Write-FlagColor -mMsg "[*] Testing paths..."
	Start-Sleep -Milliseconds 600
    # Check if the SignalPortable directory exists
    if (Test-Path -Path $signalPortableDirectory -PathType Container) {
        # Check if the SignalPortable directory is not empty
		Write-FlagColor -mMsg "[+] Path found."
        $signalPortableFiles = Get-ChildItem -Path $signalPortableDirectory
        if ($signalPortableFiles.Count -gt 0) {
            # Define backup zip file only if the directory is not empty
            $backupZipFile = Join-Path -Path $selectedFolder -ChildPath "signalUpdateBak.zip"
            # Create a backup zip file
			Write-FlagColor -mMsg "[*] Backing up app directory..."
            Compress-Archive -Path $signalPortableDirectory -DestinationPath $backupZipFile -Force
			Write-FlagColor -mMsg "[+] Backup complete."
			
            # Remove the contents of the SignalPortable directory
            Remove-Item -Path $signalPortableDirectory\* -Exclude 'signalUpdateBak.zip' -Recurse -Force
        } else {
            Write-Host "[#] SignalPortable directory is empty. Skipping backup."
			Start-Sleep -Milliseconds 600
        }
    } else {
        Write-Error "[*] SignalPortable directory does not exist."
		pause
		Exit
    }

    # Copy the contents of 'tmpSignalExtract' to the SignalPortable directory
	Write-FlagColor -mMsg "[*] Applying updates..."
	Start-Sleep -Milliseconds 1400
    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "tmpSignalExtract"
    Copy-Item -Path $sourceDirectory\* -Destination $signalPortableDirectory -Recurse -Force
} else {
    Write-FlagColor -mMsg "[!] Error: \$selectedFolder is null. Please specify a valid folder."
}

Write-FlagColor -mMsg "[+] Updates applied."

# cleanup
Write-FlagColor -mMsg "[*] Cleaning up..."
Start-Sleep -Milliseconds 600

# Remove app-64.7z
Remove-Item -Path "$originalScriptLocation\app-64.7z" -Force -ErrorAction SilentlyContinue
if (-not (Test-Path "$originalScriptLocation\app-64.7z")) {
    Write-FlagColor -mMsg "[+] Removed: app-64.7z"
}
Start-Sleep -Milliseconds 200
# Remove latest.yml
Remove-Item -Path "$originalScriptLocation\latest.yml" -Force -ErrorAction SilentlyContinue
if (-not (Test-Path "$originalScriptLocation\latest.yml")) {
    Write-FlagColor -mMsg "[+] Removed: latest.yml"
}
Start-Sleep -Milliseconds 200
# Remove $fileName
Remove-Item -Path "$originalScriptLocation\$fileName" -Force -ErrorAction SilentlyContinue
if (-not (Test-Path "$originalScriptLocation\$fileName")) {
    Write-FlagColor -mMsg "[+] Removed: $fileName"
}
Start-Sleep -Milliseconds 200
# Remove SignalPortableAppPath.txt
Remove-Item -Path "$originalScriptLocation\SignalPortableAppPath.txt" -Force -ErrorAction SilentlyContinue
if (-not (Test-Path "$originalScriptLocation\SignalPortableAppPath.txt")) {
    Write-FlagColor -mMsg "[+] Removed: SignalPortableAppPath.txt"
}
Start-Sleep -Milliseconds 200
# Remove $firstExtractDir
Remove-Item -Path "$originalScriptLocation\$firstExtractDir" -Recurse -Force -ErrorAction SilentlyContinue
if (-not (Test-Path "$originalScriptLocation\$firstExtractDir")) {
    Write-FlagColor -mMsg "[+] Removed: $firstExtractDir"
}
Start-Sleep -Milliseconds 200
# Remove $secondExtractDir
Remove-Item -Path "$originalScriptLocation\$secondExtractDir" -Recurse -Force -ErrorAction SilentlyContinue
if (-not (Test-Path "$originalScriptLocation\$secondExtractDir")) {
    Write-FlagColor -mMsg "[+] Removed: $secondExtractDir"
}
Start-Sleep -Milliseconds 200
Write-FlagColor -mMsg "[+] Cleanup finished."
Start-Sleep -Seconds 0.5



Write-Host ""
Write-Host $fillLine
Write-Host ""

Write-Host ""
Write-Host " _____ ___ _   _ ___ ____  _   _ _____ ____  "
Write-Host "|  ___|_ _| \ | |_ _/ ___|| | | | ____|  _ \ "
Write-Host "| |_   | ||  \| || |\___ \| |_| |  _| | | | |"
Write-Host "|  _|  | || |\  || | ___) |  _  | |___| |_| |"
Write-Host "|_|   |___|_| \_|___|____/|_| |_|_____|____/ "
Write-Host ""
Write-Host ""


Write-Host "You did it!"
Write-Host ""
Write-Host ""
pause



