# set up variables
# remove existing variables, as we might want to redo them after init
Remove-Variable taglist -scope script -ErrorAction SilentlyContinue
Remove-Variable colours -force -scope script -ErrorAction SilentlyContinue
Remove-Variable coloursDark -force -scope script -ErrorAction SilentlyContinue

# set possible tags
Set-Variable ro_tagList -scope script -option ReadOnly -value @{
    Auto = @('normal','auto','a','regular','reg','r')
    Bright = @('bright','b')
    Error = @('error','err','e','failure','fail','f')
    Warning = @('warning','warn','w')
    Success = @('success','succ','sc','s')
    Prompt = @('prompt','pr','p')
    Highlight = @('highlight','high','hl','h','attention','attn')
    Dark = @('low','l','dark','d')
    Override = @(
        'black'
        'darkblue'
        'darkgreen'
        'darkcyan'
        'darkred'
        'darkmagenta'
        'darkyellow'
        'gray'
        'darkgray'
        'blue'
        'green'
        'cyan'
        'red'
        'magenta'
        'yellow'
        'white'
    )
}

# set colours
Set-Variable colours -scope script -option ReadOnly -value @{
    Auto = 'Gray'
    Bright = 'White'
    Error = 'Red'
    Warning = 'Yellow'
    Success = 'Green'
    Prompt = 'Cyan'
    Highlight = 'Magenta'
}

Set-Variable coloursDark -scope script -option ReadOnly -value @{
    Auto = 'DarkGray'
    Bright = 'Gray'
    Error = 'DarkRed'
    Warning = 'DarkYellow'
    Success = 'DarkGreen'
    Prompt = 'DarkCyan'
    Highlight = 'DarkMagenta'
}

Set-Variable lightnessOverride -scope script -value $false
Set-Variable highlightOverride -scope script -value $false

# Write-RichOutput / rout, ro
# streamlined Write-X wrapper with easily customisable colours and simplified newline management
# instructions:
<#  type "|@some keywords|" (without quotes) immediately before text to change the colour
    keywords should be separated by whitespace
    keywords include:
    -   auto, bright, error, warning, success, prompt, highlight - change text colour
    -   dark - darkens the output colour
    -   newline - creates a newline before outputting the following text
#>
function global:Write-RichOutput {
    [CmdletBinding()]
    [Alias('ro')]
    param (
        [parameter(Position=0, ValueFromPipeline)]
        [string] $message = "",
        [Alias("n","nnl")][switch] $NoNewline
    )

    process {
        if ($Config -and ($message -eq "")) {
            Configure-RichOutput
            return ""
        }

        try {
            # split substrings, making sure not to split an @ after a ro tag
            $substrings = $message -split '(?<!\|@[\w\ ]*)\|@' | Where-Object { $_ }

            # create output list
            $output = [System.Collections.Generic.List[psobject]]::new()

            # parse entries
            foreach ($entry in $substrings) {
                # set initial per-entry variables
                $c = "Auto"
                $dark = $false
                $newline = $false
                $colourOverride = $false

                # separate out tags from text
                $entry = $entry -split '\|',2
                if ($entry.Count -eq 2) {
                    # assign tags and text
                    $tags = $entry[0]
                    $text = $entry[1]
            
                    # parse tags, space-separated
                    $taggroup = ($tags -split " ").Trim() |? { $_ -match '\S' }
                    foreach ($t in $taggroup) {
                        $validtag = $false

                        # check tag against valid list
                        foreach ($key in $ro_tagList.keys) {
                            if ($ro_tagList[$key] -icontains $t.ToLower()) {
                                switch ($key) {
                                    "Dark" { $dark = $true ; break }
                                    "Override" { $colourOverride = $true ; $c = $t ; break }
                                    default { $c = $key }
                                }
                                $validtag = $true
                            }
                        }

                        if (!$validtag) { Write-Host "Warning: invalid tag - no formatting applied. Check `$ro_tagList for valid tags." -ForegroundColor DarkYellow }
                    }

                } else {
                    # keep default tags, assign text
                    $text = $entry[0]

                }

                # ---- config overrides
                # lightnessOverride (auto text becomes bright)
                if ($lightnessOverride -and ($c -eq "Auto")) {
                    $c = "White"
                    $colourOverride = $true
                }
                # highlightOverride (bright > highlight, highlight > prompt, prompt > blue
                if ($highlightOverride) {
                    switch ($c) {
                        "Bright" { $target = "Highlight" }
                        "Highlight" { $target = "Prompt" }
                        "Prompt" { $target = "DarkCyan"; $colourOverride = $true }
                    }
                    if ($null -ne $target) {
                        $c = $target
                        $target = $null
                    }
                }

                # ---- add to output array
                if ($colourOverride) {
                    $outpackage = [pscustomobject] @{ Colour = $c ; Text = $text ; Newline = $newline }
                
                } elseif ($dark) {
                    $outpackage = [pscustomobject] @{ Colour = $coloursDark[$c] ; Text = $text ; Newline = $newline }

                } else {
                    $outpackage = [pscustomobject] @{ Colour = $colours[$c] ; Text = $text ; Newline = $newline }
                }

                Write-Debug ($outpackage | Format-Table | Out-String)

                $output.Add($outpackage)
            }

            Write-Debug "Output:"
            Write-Debug ($output | Format-Table | Out-String)

            # add conditional newline
            if (!$NoNewline) {
                $output[-1].Text += "`n"
            }

            # output lines
            foreach ($line in $output) {
                Write-Host $line.Text -ForegroundColor $line.Colour -NoNewline
            }

        } catch {
            Write-Host ("ro error:") -ForegroundColor Red
            throw
        }
    }
}

# Configure-RichOutput
# config options for ro
function Configure-RichOutput {
    [CmdletBinding()]
    [Alias('roconfig')]
    param()

    $doConfig = $true
    while ($doConfig) {
        $toggles = @{
            1 = switch ($lightnessOverride) { $true { "s" }; $false { "e" } }
            2 = switch ($highlightOverride) { $true { "s" }; $false { "e" } }
        }
        ro "1 - Override default |@gray|grey |@|with |@white|white|@|: |@$($toggles.1)|$lightnessOverride"
        ro "2 - Override |@b|bright|@|, |@h|highlight |@|and |@p|prompt |@|tags: |@$($toggles.2)|$highlightOverride"
        Write-Host "0 - Exit"
        switch (Read-Host("Enter an option")) {
            1 { $script:lightnessOverride = !$lightnessOverride; ro "|@s|lightness override set!"; break }
            2 { $script:highlightOverride = !$highlightOverride; ro "|@s|highlight override set!"; break }
            0 { $doConfig = $false }
        }
    }
}
