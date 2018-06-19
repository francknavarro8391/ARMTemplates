Param(
[Parameter(Mandatory=$True)]
[String]$Key
)
$Buildversion = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion" -Name ReleaseID).releaseID
$MountDrive = "Z"
$ShareToMount = "\\smagmastersource.file.core.windows.net\master"
$acctKey = ConvertTo-SecureString -String $key -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\smagmastersource", $acctKey
New-PSDrive -Name $MountDrive -PSProvider FileSystem -Root $ShareToMount -Credential $credential -Persist
$testdrive = (Get-PSDrive -Name $MountDrive -ErrorAction SilentlyContinue)
if ($testdrive -ne $null)
{ 
    #
    # Check if a folder exists for the build version into the LanguagesPacks folder
    #
    $BaseFolder = ""
    if ((Test-Path ($MountDrive + ":\LanguagePacks\$Buildversion")) -eq $true)
    {
        Write-Host "Language Pack folder for build $Buildversion exists."
        #
        # Filter folder content to get only the required language pack
        #
        $file = Get-ChildItem -Path ($MountDrive + ":\LanguagePacks\$Buildversion\*fr-fr_lp.cab")
        $File
        $DISMCommand = "DISM.EXE /ONLINE /ADD-PACKAGE /PACKAGEPATH:$file"
        $DISMCommand 
        Invoke-expression $DISMCommand  
        #
        # Configure UI Culture
        #
        $command = "dism /online /get-packages"
        Invoke-Expression $command | out-file "C:\LOGS\LanguagePack.LOG"

    }
    Else
    {
        Write-Warning "Unable to locate Language Pack folder for build $Buildversion."
    }
}
Else
{
    Write-Warning "Unable to mount SMB share."
}
