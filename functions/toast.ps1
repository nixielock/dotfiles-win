if ($PSVersionTable.PSVersion.Major -lt 6) {
    function toast {
        [CmdletBinding()]
        param (
            [parameter(Position = 0, Mandatory)]
            [string] $Message,
            [parameter(Position = 1, Mandatory)]
            [string] $Title
        )

        begin {
            Add-Type -AssemblyName System.Windows.Forms
        }

        process {
            [void] [System.Windows.Forms.MessageBox]::Show($_, $Message, $Title, "Ok")
        }
    }
} else {
    function toast {
        [CmdletBinding()]
        param (
            [parameter(Position = 0, Mandatory)]
            [string] $Message,
            [parameter(Position = 1, Mandatory)]
            [string] $Title
        )

        process {
            [void] (powershell.exe -NoProfile -File ~\awldrive\Scripts\scripts\toast.ps1 -Message $Message -Title $Title)
        }
    }
}
