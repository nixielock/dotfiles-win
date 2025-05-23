# ---- whentoleave - <description>

function whentoleave {
    [CmdletBinding()]
    param(
        # <description 0>
        [parameter(Position = 0, Mandatory)]
        [float] $RawTotal,

        # <description 1>
        [parameter(Position = 1, Mandatory)]
        [string] $LastClockIn,

        # <description 2>
        [parameter(Position = 2)]
        [float] $UnloggedHours = 0
    )

    process {
        $remainingTime = [timespan]::FromHours((38 - $RawTotal - $UnloggedHours))
        $lastClockTime = (date "$(date ([datetime]::Today) -f 'yyyy-MM-dd') $LastClockIn")
        $targetTime = $lastClockTime + $remainingTime

        if ($targetTime.Day -ne ([datetime]::Now.Day)) {
            wr "your input is probably bogus - this says you'll want to clock off on $($targetTime.DayOfWeek)!" -f yellow
            return
        }

        if ($targetTime -le ([datetime]::Now)) {
            ro "you needed to leave at |@red|$((date $targetTime -f "h:mmtt").ToLower())|@|! |@cyan|go now!!"
        } else {
            ro "you'll want to clock off at |@white|$((date $targetTime -f "h:mmtt").ToLower())|@|!"
        }
    }
}
