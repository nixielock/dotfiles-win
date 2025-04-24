# ---- update-file - update a file only if the source is newer
# chuck in an optional hashtable to keep count

function update-file {
    param (
        [parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('f','i')]
        [PSObject] $File,
        
        [parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('t','o')]
        [PSObject] $Target,
        
        [parameter(ValueFromPipelineByPropertyName)]
        [Alias('r','s','status')]
        [switch] $ReturnStatus
    )

    if ($null -eq $File) {
        throw [System.ArgumentException]::new(
            "Source file and destination must be specified.",
            "File"
        )
    }
    
    if ($null -eq $Target) {
        throw [System.ArgumentException]::new(
            "Destination must be specified for source file.",
            "Target"
        )
    }

    try {
        $fileObject = (gi $File -ea Stop)
        $targetObject = (gi $Target -ea SilentlyContinue) ?? $Target
        
        wr "$($fileObject.BaseName)" -n
        wr " -> " -f darkgray -n        
        
        # no existing target, add
        if ($targetObject.GetType().Name -eq 'String') {
            cp $fileObject $Target
            wr "created $((gi $Target -ea Stop).FullName)" -f green
            return ($ReturnStatus ? 'added' : $null)
        }

        # target is newer, skip
        if ($targetObject.LastWriteTime -gt $fileObject.LastWriteTime) {
            wr "target is newer" -f yellow
            return ($ReturnStatus ? 'skipped' : $null)
        }
        
        # files are identical, skip
        if ((Get-FileHash $fileObject).Hash -eq (Get-FileHash $targetObject).Hash) {
            wr "no change"
            return ($ReturnStatus ? 'skipped' : $null)
        }
        
        # target is older, overwrite
        cp $fileObject $targetObject.FullName
        wr "updated" -f green
        return ($ReturnStatus ? 'updated' : $null)
        
    } catch {
        wr "failed: $($_.Exception.ErrorRecord)" -f red
        return ($ReturnStatus ? 'failed' : $null)
    }
}
