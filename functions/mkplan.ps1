# plan
# load the function globally when script is called

function Add-DeepdwnPlan {
    [CmdletBinding()]
    [Alias('mkplan')]
    param (
        [parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string] $Name,

        [parameter(Position = 1)]
        [Alias('t')]
        [string[]] $Tags = @(),

        [parameter(Position = 2)]
        [Alias('o')]
        [string] $Outline = ''
    )

    begin {
        $templatePath = "~\code\templates\deepdwn"
        $plansPath = "~\notes\plans"
        $date = Get-Date -format 'yyyy-MM-dd'
    }
    
    process {
        if (-not ($Name -match '\S')) {
            throw [System.ArgumentException]::new('Name cannot be blank','Name')
        }

        try {
            # validate filename is free
            $fileName = "$($date -replace '-','')-$($Name.ToLower() -replace ' ','-').md"
            if (Test-Path "$plansPath\$fileName") {
                throw [System.ArgumentException]::new("File with this name already exists from today: $fileName",'Name')
            }

            # set content of new plan file
            $inputTags = $Tags |% { "- $_" }
            $planContents = cat "$templatePath\plans-template.md" -ea stop
            $planContents = $planContents -replace 'title: plans',"title: $Name"
            $planContents = $planContents -replace '- template',"$tagList"
            $planContents = $planContents -replace 'date:',"date: $date"
            $planContents = $planContents -replace 'subject:',"subject: $Name"
            $planContents = $planContents -replace 'outline:',"outline: $Outline"

            # create file
            wr "creating " -f darkgray -n
            wr "$fileName... " -n
            ac -path "$plansPath\$fileName" -val $planContents -ea stop
            wr "done!" -f green
            
        } catch {
            wr "failed" -f red
            wr ''
            throw
        }
    }
}
