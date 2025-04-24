# ---- nf
# create a new function, add template, open in helix or ISE
function nf {
    [CmdletBinding()]
    param (
        # function name
        [parameter(Position=0, Mandatory, ValueFromPipeline)]
        [string] $Name,

        # number of parameters
        [parameter(Position = 1, ValueFromPipeline)]
        [Alias('p','params')]
        [int] $ParameterCount = -1,

        # create advanced function (include CmdletBinding and process block)
        [Alias('a','c')]
        [switch] $Advanced
    )

    # -- INIT

    if ($ParameterCount -lt 0) {
        $paramCount = switch ($Advanced) {
            $true  { 1 }
            $false { 0 }
        }
    } else {
        $paramCount = $ParameterCount
    }
    
    # set filepath for new function
    $newFilePath = "$pwsh_scriptpath\functions\$Name.ps1"

    # create .ps1 file for function
    ni -path $newFilePath -ItemType File
    
    # -- BUILD TEMPLATE

# --------------------------------
# HEREIN LIES HERE-STRING BULLSHIT
# --------------------------------

# a bunch of formatting here is broken in helix
# cause it doesn't handle expanding here-strings well
# adding a # inside the two double-linebreak here-strings makes it kinda work

# > opening lines of template
    $template = @"
# ---- $Name - <description>

function $Name {
"@ # " # end here-string
    
    # // <advanced>
    if ($Advanced) {
# > cmdletbinding for advanced functions
        $template += @'

    [CmdletBinding()]
'@
    }
    # // </advanced>

    # // <parameters>
    if ($paramCount -ge 1) {
# > open param block
        $template += @'

    param(
'@
        
        for ($i = 0; $i -lt $paramCount; $i++) {
            if ($i -gt 0) {
                # after each parameter
                # comma at end of line, then linebreak
                $template += @'
,

'@
            }
# > add parameters
            $template += @"

        # <description $i>
        [parameter(Position = $i)]
        [string] `$Parameter$i
"@ # " # end here-string
        }

# > close param block
        $template += @'

    )
'@
    }
    # // </parameters>

# > add whitespace after first section
    $template += @'


'@

    # // <advanced>
    if ($Advanced) {
# > process block for advanced functions
        $template += @'

    process {
        
    }
'@
    } else {
# > remaining whitespace for body
    $template += @'


'@
    }
    # // </advanced>

# > close out function
    $template += @'

}
'@

# ------------------------------
# THUS ENDS HERE-STRING BULLSHIT
# ------------------------------
    
    # -- CREATE FUNCTION

    # > add template to .ps1 file
    ac -path $newFilePath -val $template
    
    # -- open .ps1 file for editing
    switch ($host.Name) {
        'Windows PowerShell ISE Host' { ise $newFilePath }
        default { hx $newFilePath }
    }
}
