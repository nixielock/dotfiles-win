# ---- assert - throw a generic error on failure

function assert {
    [CmdletBinding()]
    param(
        # input statement or expression
        [parameter(Position = 0, ValueFromPipeline, ParameterSetName = 'Statement')]
        [object] $Statement,

        [parameter(Position = 0, ValueFromPipeline, ParameterSetName = 'Variable')]
        [string] $Name,

        [parameter(ParameterSetName = 'Variable')]
        [Alias('v')]
        [switch] $ByName
    )

    process {
        # make sure evaluations start from null
        $value = $null
        $eval = $null

        if ($ByIdentifier) {
            # get value of named variable
            $varName = "'$Name'"
            try {
                $value = Get-Variable $Name -ValueOnly -ErrorAction Stop
            } catch {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ([System.Activities.ValidationException]"Assertion failed: Variable $varName not found"),
                        'Assert.VariableNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    )
                )
            }
        } else {
            $varName = "input"
            $value = $Statement
        }

        # check assertion
        if ($value -is [scriptblock]) {
            # get result of expression
            $eval = (& $value)
            if (-not $eval) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ([System.Activities.ValidationException]"Assertion failed ($varName, expression): $value"),
                        'Assert.ExpressionNotTrue',
                        [System.Management.Automation.ErrorCategory]::InvalidResult
                    )
                )
            }
        } else {
            if (-not $value) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ([System.Activities.ValidationException]"Assertion failed ($varName, statement): $value"),
                        'Assert.StatementNotTrue',
                        [System.Management.Automation.ErrorCategory]::InvalidData
                    )
                )
            }
        }
    }
}
