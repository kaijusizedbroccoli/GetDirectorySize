function Get-DirectorySize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage="Enter the full path of what you want to check the size of. E.g. C:\Windows, DO NOT INCLUDE AN ENDING '\'")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ (Test-Path $_) -eq $true })]
        [ValidatePattern("^(\w:|\\\\).*[^\\]$")]
        [alias("p")]
        [string]$Path,

        [Parameter(Mandatory=$true,HelpMessage="Original = How windows displays a file size, Gb = In Gb, 512Mb would be 0.5Gb, Mb = In Mb, 1Gb would be 1024Mb")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Original","Gb","Mb")]
        [alias("dt")]
        [string]$DataType,

        [Parameter(Mandatory=$false,HelpMessage="Input how many threads to use for the robocopy process.")]
        [ValidatePattern("^\d{1,2}$")]
        [alias("mt")]
        [int]$MultiThread = 8
    )
    
    # ------- REGION START: Robocopy Cmd ------- #

    $RobocopyProcess = robocopy $Path "NO" /e /l /r:0 /w:0 /mt:$MultiThread /nfl /ndl /nc /fp /np /njh /xj /bytes

    [int64]$SizeInBytes = $RobocopyProcess.Where({$_ -match "Bytes :"}).Split("",[System.StringSplitOptions]::RemoveEmptyEntries)[2]
    [int64]$FileCount   = $RobocopyProcess.Where({$_ -match "Files :"}).Split("",[System.StringSplitOptions]::RemoveEmptyEntries)[2]
    [int64]$DirCount    = $RobocopyProcess.Where({$_ -match "Dirs :"}).Split("",[System.StringSplitOptions]::RemoveEmptyEntries)[2]

    # ------- REGION END  : Robocopy Cmd ------- #

    # ------- REGION START: Filter Output ------- #

    $SizeOutput = switch ($DataType) {
        "Original" {  
            if($SizeInBytes -lt 1Gb -and $SizeInBytes -gt 1Mb){
                "{0:N2} {1}" -f ($SizeInBytes / 1Mb), "Mb"
            } elseif ($SizeInBytes -lt 1Mb) {
                "{0:N2} {1}" -f ($SizeInBytes / 1Kb), "Kb"
            } else {
                "{0:N2} {1}" -f ($SizeInBytes / 1GB), "Gb"
            }
        }
        "Gb"       {  
            "{0:N2} {1}" -f ($SizeInBytes / 1Gb), "Gb"
        }
        "Mb"       {  
            "{0:N2} {1}" -f ($SizeInBytes / 1MB), "Mb"
        }
        Default { Write-Error "Error in size output switch statement." }
    }

    $OutputObject = [PSCustomObject]@{
        Path = $Path
        Size = $SizeOutput
        "FileCount" = $FileCount
        "DirectoryCount" = $DirCount
    }

    # ------- REGION END  : Filter Output ------- #

    # ------- REGION START: Output ------- #

    return $OutputObject

    # ------- REGION END  : Output ------- #
}