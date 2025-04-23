# rdc
# load the function globally when script is called

function rdc {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [string] $Target
    )
    
    process {
        if (-not ($Target -match '\S')) {
            ro "|@p|select a connection:"
            ro "|@b|1 |@|- |@b|SOEv4 Terminal |@|(e7359svin1444.schools.internal)"
            ro "|@b|2 |@|- |@b|Central Script Server |@|(e7359svin1122.resources.internal)"
            ro "|@b|3 |@|- |@b|Test Script Server |@|(e7359svin2505.resourcestest.internal)"
            ro "|@b|0 |@|- |@b|exit"
            wr ""
            ro "|@p|> " -n
            
            $setTarget = switch (Read-Host) {
                1 {
                    ro "selected: |@b|soe-terminal"
                    "soe-terminal"
                }
                2 {
                    ro "selected: |@b|script"
                    "script"
                }
                3 {
                    ro "selected: |@b|script-test"
                    "script-test"
                }
                default { return "" }
            }
            
        } else {
            $setTarget = $Target
        }
        
        $computerName = switch -regex ($setTarget) {
            '^soe(v4)?(-terminal)?$|^terminal$' { 'e7359svin1444'; break }
            '^sc(r(ipt)?)?$' { 'e7359svin1122'; break }
            '^test-?sc(r(ipt)?)?$|^sc(r(ipt)?)?-?test$' { 'e7359svin2505.resourcestest.internal'; break }
            default { $Target }
        }

        ro "connecting to |@b|$computerName|@|!"
        start mstsc.exe -ArgumentList "/v:$computerName"
    }
}
