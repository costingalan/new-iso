function New-WindowsISO()
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true)]
        [string]$baseImagePath,
        [parameter(Mandatory=$true)]
        [string]$outputImageName,
        [parameter(Mandatory=$true)]
        [string]$workDir,
        [parameter(Mandatory=$true)]
        [string]$updatesDir,
        [parameter(Mandatory=$false)]
        [string]$indexList=@(1,2)
    )

    PROCESS
    {
        try {
            $driveLetter = (Mount-DiskImage $baseImagePath -PassThru | Get-Volume).DriveLetter
            if (! Test-Path $workDir) {
                Remove-Item -Force -Recurse "${workDir}"
            }
            New-Item -Type Directory $workDir
            pushd $workDir
            New-Item -Type Directory ISO
            Copy-Item -Recurse "${driveLetter}\*" "ISO"
            foreach $index in $indexList {
                $workIndex = Join-Path -Path $workDir -ChildPath "index-${index}"
                New-Item -Type Directory $workIndex
                Dism.exe /mount-wim /wimfile:${workDir}\ISO\sources\install.wim /mountdir:$workIndex /index:$index
                foreach $update in $updatesDir {
                    Add-WindowsPackage -Path ${workIndex}\sources\install.wim -PackagePath $update
                }
                Dism.exe /unmount-wim /mountdir:$workIndex /commit
            }
            & C:\Users\Administrator\mkisofs.exe -o iso_name.iso -ldots -allow-lowercase -allow-multidot -l -publisher "Cloudbase Solutions" -J -r -V "DVD Label" "${workDir}\ISO"
    } finally {
      Write-Host "New-ISO failed"
      Write-Host $_
      Dismount-DiskImage $baseImagePath
      }
}
