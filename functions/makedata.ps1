# makedata
# load the function globally when script is called

function makedata {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $Name
    )

    begin {
        function readData {
            
        }
    }
    
    process {
        # create construction hashtable
        $struct = @{}
        
        # begin interactive loop
        
    }
}
