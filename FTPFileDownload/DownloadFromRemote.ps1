# Set variables for connection details
$sftpHost = "djrcfeed.dowjones.com"
$sftpUsername = "mbsbdug"
$sftpPassword = "Amlteam@123"
$remoteFolderPath = "/tradecompliance"
$localFolderPath = "C:\Users\nayeer\Desktop\Test"
# If failed to connect because of fingerprint, need to connect using WinSCP and copy the fingerprint
$sshFingerprint = "QVADuKA4x6cUiBQuCTizQttXtoG4ZHFEPsrvFvzZ700"


function Write-ToFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    $logFolder ="$($PWD)\Logs"
    Write-Output $Text

    if (!(Test-Path $logFolder)) {
        New-Item -ItemType Directory -Path $logFolder
    }
    $FileName = "log_" + (Get-Date -Format 'yyyy-MM-dd') + ".txt"
    $FilePath = Join-Path -Path ($logFolder) -ChildPath $FileName
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $TextWithTimestamp = "$Timestamp - $Text"
    $TextWithTimestamp | Out-File -FilePath $FilePath -Append
}

# Load the WinSCP .NET assembly
Add-Type -Path "WinSCPnet.dll"

# Setup session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol              = [WinSCP.Protocol]::Sftp
    HostName              = $sftpHost
    UserName              = $sftpUsername
    Password              = $sftpPassword
    SshHostKeyFingerprint = $sshFingerprint
}

#Retrieve the fingerprint from server first - KIV

# Connect to the SFTP server
$session = New-Object WinSCP.Session
$session.Open($sessionOptions)

# Get a list of files in the remote folder
$remoteFiles = $session.ListDirectory($remoteFolderPath)

#check if local $localFolderPath exists or not, otherwise create the folder first
if (!(Test-Path $localFolderPath)) {
    New-Item -ItemType Directory -Path $localFolderPath
}

# Loop through the remote files and download only the files that don't exist in the local folder
foreach ($remoteFile in $remoteFiles.Files) {
    $remoteFilePath = $remoteFile.FullName
    $localFilePath = Join-Path $localFolderPath $remoteFile.Name

    if (-not (Test-Path $localFilePath)) {
        # Download the file
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
        $transferResult = $session.GetFiles($remoteFilePath, $localFilePath, $False, $transferOptions)

        # Check for errors
        if ($transferResult.IsSuccess) {
            Write-ToFile -Text "File downloaded successfully: $($remoteFile.Name)"
        }
        else {
            Write-Error "Error downloading file: $($transferResult.Failures[0].Message)"
        }
    }
    else {
        Write-ToFile -Text "File already exists in local folder: $($remoteFile.Name)"
    }
}

Write-ToFile -Text "Finished copying files. Exiting..."

# Disconnect from the SFTP server
$session.Dispose()



