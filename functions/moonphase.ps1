# ---- moonphase - calculate the phase of the moon
# written by nixie!

# inspired by pom, from BSDGames - https://github.com/vattam/BSDGames/blob/master/pom/pom.c
# code adapted from:
# - Moontool - https://www.fourmilab.ch/moontoolw/
# - the Astro::MoonPhase PERL module - https://metacpan.org/pod/Astro::MoonPhase

# i've removed (read: commented out) some non-functional parts of the code, namely to do with parallax and inclination
# moontool.c seems to have either used them elsewhere (that i missed) or simply never implemented the related features

# icons are meant for use with Nerd Fonts:
# https://www.nerdfonts.com/

# in the spirit of its predecessors <3
# LICENSE: This program is in the public domain: "Do what thou wilt shall be the whole of the law".

function moonphase {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [datetime] $Date = [datetime]::Now,

        [Alias('p')]
        [switch] $Print
    )

    begin {
        $KnownNewMoon = (Get-Date "20:35 29 Jan 2025 +8:00")
        $KnownEpoch = (Get-Date "00:00 31 Dec 1979 +0:00") # 00:00 1 January 1980

        # constants for sun's apparent orbit
        [decimal] $S_ELong0 = 278.833540; # ecliptic longitude of the Sun at epoch
        [decimal] $S_ELongP = 282.553; # ecliptic longitude of the perihelion at epoch
        [decimal] $E_Eccen = 0.016712;   # eccentricity of Earth's orbit at epoch
        [decimal] $S_KmSmAxis = 1.495985e8; # semi-major axis of Earth's orbit (km)
        [decimal] $S_DegSmAxis = 0.533128;   # sun's angular size (deg) at semi-major axis distance

        # constants for moon's orbit
        [decimal] $L_MLong0 = 64.975464;   # moon's mean longitude at epoch
        [decimal] $L_MLongP0 = 349.383063;  # mean longitude of the perigee at epoch
        [decimal] $L_MLongN0 = 151.950429;  # mean longitude of the node at epoch
        [decimal] $L_Inclin = 5.145396;    # inclination of the Moon's orbit
        [decimal] $L_Eccen = 0.054900;    # eccentricity of the Moon's orbit
        [decimal] $L_AngDeg = 0.5181;      # moon's angular size at distance a from Earth
        [decimal] $L_KmSmAxis = 384401.0;    # semi-major axis of Moon's orbit (km)
        # ! nothing to do with parallax is ultimately used anywhere in the original source code
        #[decimal] $L_Parallax = 0.9507;      # parallax at distance a from Earth
        [decimal] $SynodicMonth = 29.53058868; # synodic month (new moon to new moon)

        # long pi
        [decimal] $Pi = [math]::Pi # assuming not near a black hole nor in Tennessee

        # base functions
        function toRadians {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                [decimal] $Degrees
            )
            return ($Degrees * $Pi / 180)
        }

        function toDegrees {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                [decimal] $Radians
            )
            return ($Radians * 180 / $Pi)
        }

        function fixAngle {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                [decimal] $Degrees
            )
            return ([math]::DivRem($Degrees, 360).Item2 + 360) % 360
        }

        function inverseKepler { 
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                [decimal] $Degrees,
                [parameter(Position = 1, Mandatory, ValueFromPipeline)]
                [decimal] $Eccentricity
            )
            # use Newton's method to sufficient precision
            $epsilon = [math]::Pow(10, -6)
            $meanAnomaly = (toRadians $Degrees)
            [decimal] $e = $meanAnomaly # set eccentric anomaly to initial value
            do {
                $delta = $e - ($Eccentricity * [math]::Sin($e)) - $meanAnomaly
                $e -= ($delta / (1 - ($Eccentricity * [math]::Cos($e))))
            } while ([math]::Abs($delta) -gt $epsilon)
            return $e
        }
        
        # quick help functions
        function radSin {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                [decimal] $Degrees
            )
            return ([math]::Sin((toRadians $Degrees)))
        }

        function radCos {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                [decimal] $Degrees
            )
            return ([math]::Cos((toRadians $Degrees)))
        }

        function pom {
            [CmdletBinding()]
            param (
                [parameter(Position = 0, ValueFromPipeline, Mandatory)]
                [datetime] $TargetDate
            )

            $day = ($TargetDate - $KnownEpoch).TotalDays # days since epoch

            # > solar calculations

            # mean anomaly
            [decimal] $s_n = (fixAngle ((360 / ([decimal] 365.2422)) * $day)) # 360 degrees per year since epoch
            [decimal] $s_mAnomaly = fixAngle ($s_n + $S_ELong0 - $S_ELongP) # mean anomaly
            # eccentric anomaly
            [decimal] $eccenAnomaly = (inverseKepler $s_mAnomaly $E_Eccen)
            # true anomaly
            [decimal] $ec = [math]::Sqrt(((1 + $E_Eccen) / (1 - $E_Eccen))) * [math]::Tan(($eccenAnomaly / 2))
            [decimal] $trueAnomaly = 2 * (toDegrees ([math]::Atan($ec)))
            Remove-Variable ec
            # geocentric ecliptic longitude
            [decimal] $s_lambda = (fixAngle ($trueAnomaly + $S_ELongP))
            # orbital factor
            [decimal] $orbitFactor = (1 + ($E_Eccen * (radCos $trueAnomaly))) / (1 - [math]::Pow($E_Eccen, 2))
            # distance and angular size
            [decimal] $s_distance = $S_KmSmAxis / $orbitFactor # distance to sun (km)
            [decimal] $s_angSize = $S_DegSmAxis * $orbitFactor # sun's angular size (deg)

            # > lunar calculations

            # mean longitude
            $l_mLong = fixAngle ((([decimal] 13.1763966) * $day) + $L_MLong0)
            # mean anomaly
            $l_mAnomaly = fixAngle ($l_mLong - (([decimal] 0.1114041) * $day) - $L_MLongP0)
            # ascending node mean longitude
            $l_mLongNAsc = fixAngle ($L_MLongN0 - (([decimal] 0.0529539) * $day))
            # evection (lunar inequality)
            $l_evec = ([decimal] 1.2739) * (radSin ((2 * ($l_mLong - $s_lambda)) - $l_mAnomaly))
            # annual equation (lunar inequality)
            $l_annualEq = ([decimal] 0.1858) * (radSin $s_mAnomaly)
            # correction term
            $l_c3 = ([decimal] 0.37) * (radSin $s_mAnomaly)
            # corrected anomaly
            $l_cAnomaly = $l_mAnomaly + $l_evec - $l_annualEq - $l_c3
            # equation of the centre (lunar inequality)
            $l_centreEq = ([decimal] 6.2886) * (radSin $l_cAnomaly)
            # "another correction term"
            $l_c4 = ([decimal] 0.214) * (radSin (2 * $l_cAnomaly))
            # corrected longitude
            $l_cLong = $l_mLong + $l_evec + $l_centreEq - $l_annualEq + $l_c4
            # variation
            $l_var = ([decimal] 0.6583) * (radSin (2 * ($l_cLong - $s_lambda)))
            # true longitude
            $l_trueLong = $l_cLong + $l_var
            # corrected longitude of the node
            $l_nLongC = $l_mLongNAsc - (([decimal] 0.16) * (radSin $s_mAnomaly))
            # ! originally LambdaMoon - is calculated but never actually used
            # y inclination coordinate
            #$incY = (radSin ($l_trueLong - $l_nLongC)) * (radCos $L_Inclin)
            # x inclination coordinate
            #$incX = radCos ($l_trueLong - $l_nLongC)
            # ecliptic longitude
            #$l_lambda = (toDegrees ([math]::Atan2($incY, $incX))) + $l_nLongC
            # ! also never used
            # ecliptic latitude
            #$l_beta = toDegrees ([math]::Asin((radSin ($l_trueLong - $l_nLongC))))
            #$l_beta *= radSin $L_Inclin

            # > moon phase calculations

            # age (deg)
            $l_ageDeg = $l_trueLong - $s_lambda
            # illuminated fraction
            $illum = (1 - (radCos $l_ageDeg)) / 2
            # distance from centre of earth
            $denom = $L_KmSmAxis * (1 - [math]::Pow($L_Eccen, 2))
            $recip = 1 + ($L_Eccen * (radCos ($l_cAnomaly + $l_centreEq)))
            $l_distance = $denom / $recip
            Remove-Variable denom, recip
            # angular diameter
            $l_dFrac = $l_distance / $L_KmSmAxis
            $l_diameter = $L_AngDeg / $l_dFrac
            # parallax
            # ! originally MoonPar - isn't used for anything or set anywhere
            #$l_parallaxAt = $L_Parallax / $l_dFrac

            return [PSCustomObject]@{
                Illuminated        = $illum
                PhaseFraction      = (fixAngle $l_ageDeg) / 360
                Age                = $SynodicMonth * (fixAngle $l_ageDeg) / 360
                AgeDays            = ($TargetDate - $KnownNewMoon).TotalDays % $SynodicMonth
                Distance           = $l_distance
                AngularDiameter    = $l_diameter
                SunDistance        = $s_distance
                SunAngularDiameter = $s_angSize
            }
        }
    }

    process {
        $prev = $Date.AddHours(-6)

        $dayOutput = (pom $Date)
        $prevOutput = (pom $prev)

        $phaseStatus = (($dayOutput.Illuminated -gt $prevOutput.Illuminated) ? "Waxing" : "Waning")

        $phase = switch ($dayOutput.Illuminated) {
            { $_ -ge 0.999 } { "Full Moon"; break }
            { $_ -ge 0.53 } { "$phaseStatus Gibbous"; break }
            { $_ -gt 0.47 } { "$($phaseStatus -eq 'Waxing' ? 'First' : 'Last') Quarter"; break }
            { $_ -gt 0.001 } { "$phaseStatus Crescent"; break }
            default { "New Moon" }
        }

        $icon = switch ($phase) {
            'New Moon' { "`u{e38d}" }
            'Waxing Crescent' { "`u{e3a5}" }
            'First Quarter' { "`u{e3a2}" }
            'Waxing Gibbous' { "`u{e39e}" }
            'Full Moon' { "`u{e39b}" }
            'Waning Gibbous' { "`u{e398}" }
            'Last Quarter' { "`u{e394}" }
            'Waning Crescent' { "`u{e391}" }
        }
        
        $output = [PSCustomObject]@{
            Phase              = $phase
            Illuminated        = $dayOutput.Illuminated
            Age                = $dayOutput.Age
            AgeDays            = $dayOutput.AgeDays
            PhaseFraction      = $dayOutput.PhaseFraction
            Icon               = $icon
            Distance           = $dayOutput.Distance
            AngularDiameter    = $dayOutput.AngularDiameter
            SunDistance        = $dayOutput.SunDistance
            SunAngularDiameter = $dayOutput.SunAngularDiameter
        }

        if ($Print) {
            return "$icon  $phase ($([math]::Round(($output.Illuminated * 100), 1))%)"
        } else {
            $output
        }
    }
}

function pom {
    moonphase -p
}
