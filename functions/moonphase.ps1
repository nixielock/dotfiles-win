# ---- moonphase - calculate the phase of the moon

function moonphase {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipeline)]
        [datetime] $Date = [datetime]::Now,

        # do not convert input time to universal time
        [switch] $AsUniversalTime
    )

    begin {
        $orbitalData = Import-Csv "$pwsh_dataPath\orbital-params.csv" -ErrorAction SilentlyContinue
        $JulianKnownEpoch = 2444238.5 # 00:00 1 January 1980
        $JulianUnixEpoch = 2440587.5 # 00:00 1 January 1970 (Unix epoch)

        # constants for sun's apparent orbit
        $S_ELong0 = 278.833540; # ecliptic longitude of the Sun at epoch
        # updated from NASA GISS ModelE AR5 Simulations - https://data.giss.nasa.gov/modelE/ar5plots/srorbpar.html
        $S_ELongP = 282.596403; # ecliptic longitude of the perihelion at epoch
        $E_Eccen = 0.016718;   # eccentricity of Earth's orbit at epoch
        $S_KmSmAxis = 1.495985e8; # semi-major axis of Earth's orbit (km)
        $S_DegSmAxis = 0.533128;   # sun's angular size (deg) at semi-major axis distance

        # constants for moon's orbit
        $L_MLong0 = 64.975464;   # moon's mean longitude at epoch
        $L_MLongP0 = 349.383063;  # mean longitude of the perigee at epoch
        # ! only used for l_mlongNAsc
        #$L_MLongN0 = 151.950429;  # mean longitude of the node at epoch
        # ! only used for l_beta and l_lambda
        #$L_Inclin = 5.145396;    # inclination of the Moon's orbit
        $L_Eccen = 0.054900;    # eccentricity of the Moon's orbit
        $L_AngDeg = 0.5181;      # moon's angular size at distance a from Earth
        $L_KmSmAxis = 384401.0;    # semi-major axis of Moon's orbit (km)
        # ! only used for l_parallaxAt
        #$L_Parallax = 0.9507;      # parallax at distance a from Earth
        $SynodicMonth = 29.53058868; # synodic month (new moon to new moon)

        # long pi
        $Pi = [math]::Pi # assuming not near a black hole nor in Tennessee

        # base functions
        function toRadians {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                 $Degrees
            )
            return ($Degrees * $Pi / 180)
        }

        function toDegrees {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                 $Radians
            )
            return ($Radians * 180 / $Pi)
        }

        function fixAngle {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                 $Degrees
            )
            return (($Degrees % 360) + 360) % 360
        }

        function toJulian {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                [datetime] $GregorianDate
            )
            $seconds = ($GregorianDate - ([datetime]::UnixEpoch)).TotalSeconds
            $days = $seconds / 86400
            return ($days + $JulianUnixEpoch)
        }

        function nrKepler { 
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                 $Degrees,
                [parameter(Position = 1, Mandatory, ValueFromPipeline)]
                 $Eccentricity
            )
            # use Newton's method to sufficient precision
            $epsilon = 1E-6
            $meanAnomaly = (toRadians $Degrees)
            $e = (toRadians $Degrees) # set eccentric anomaly to initial value
            do {
                $delta = $e - ($Eccentricity * [math]::Sin($e)) - $meanAnomaly
                $e = $e - ($delta / (1 - ($Eccentricity * [math]::Cos($e))))
            } while ([math]::Abs($delta) -gt $epsilon)
            return $e
        }
        
        # quick help functions
        function radSin {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                 $Degrees
            )
            return ([math]::Sin((toRadians $Degrees)))
        }

        function radCos {
            [CmdletBinding()]
            [OutputType([decimal])]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                 $Degrees
            )
            return ([math]::Cos((toRadians $Degrees)))
        }
        
        function phase {
            [CmdletBinding()]
            param (
                [parameter(Position = 0, Mandatory, ValueFromPipeline)]
                [datetime] $TargetDate
            )
            
            $julianDate = (toJulian $TargetDate)
            $day = $julianDate - $JulianKnownEpoch # days since epoch
            
            #if ($null -ne $orbitalData) {
            #    $record = $orbitalData | Where-Object Year -eq $TargetDate.Year
            #    $S_ELongP = $record.LongOfPeri; # ecliptic longitude of the perihelion at epoch
            #    $E_Eccen = $record.Eccentricity;   # eccentricity of Earth's orbit at epoch
            #}

            # > solar calculations

            # mean anomaly
            $s_n = fixAngle ((360 / 365.2422) * $day) # 360 degrees per year since epoch
            $s_mAnomaly = fixAngle ($s_n + $S_ELong0 - $S_ELongP) # mean anomaly
            # eccentric anomaly via newton-raphson method
            $s_eAnomaly = (nrKepler $s_mAnomaly $E_Eccen)
            # true anomaly
            $s_tAnomaly = [math]::Sqrt(((1 + $E_Eccen) / (1 - $E_Eccen))) * [math]::Tan(($s_eAnomaly / 2))
            $s_tAnomaly = 2 * (toDegrees ([math]::Atan($s_tAnomaly)))
            # geocentric ecliptic longitude
            $s_lambda = fixAngle ($trueAnomaly + $S_ELongP)
            # orbital factor
            $orbitFactor = (1 + ($E_Eccen * (radCos $trueAnomaly))) / (1 - ([math]::Pow($E_Eccen, 2)))
            # distance and angular size
            $s_distance = $S_KmSmAxis / $orbitFactor # distance to sun (km)
            $s_angSize = $S_DegSmAxis * $orbitFactor # sun's angular size (deg)

            # > lunar calculations

            # mean longitude
            $l_mLong = fixAngle ((13.1763966 * $day) + $L_MLong0)
            # mean anomaly
            $l_mAnomaly = fixAngle ($l_mLong - (0.1114041 * $day) - $L_MLongP0)
            # ascending node mean longitude
            # ! only used for l_nLongC
            #$l_mLongNAsc = fixAngle ($L_MLongN0 - (0.0529539 * $day))
            # evection (lunar inequality)
            $l_evec = 1.2739 * (radSin ((2 * ($l_mLong - $s_lambda)) - $l_mAnomaly))
            # annual equation (lunar inequality)
            $l_annualEq = 0.1858 * (radSin $s_mAnomaly)
            # correction term
            $l_c3 = 0.37 * (radSin $s_mAnomaly)
            # corrected anomaly
            $l_cAnomaly = $l_mAnomaly + $l_evec - $l_annualEq - $l_c3
            # equation of the centre (lunar inequality)
            $l_centreEq = 6.2886 * (radSin $l_cAnomaly)
            # "another correction term"
            $l_c4 = 0.214 * (radSin (2 * $l_cAnomaly))
            # corrected longitude
            $l_cLong = $l_mLong + $l_evec + $l_centreEq - $l_annualEq + $l_c4
            # variation
            $l_var = 0.6583 * (radSin (2 * ($l_cLong - $s_lambda)))
            # true longitude
            $l_trueLong = $l_cLong + $l_var
            # corrected longitude of the node
            # ! only used for l_lambda
            #$l_nLongC = $l_mLongNAsc - (0.16 * (radSin $s_mAnomaly))
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
            # phase
            $phase = (1 - (radCos $l_ageDeg)) / 2
            # distance from centre of earth
            $denom = $L_KmSmAxis * (1 - ([math]::Pow($L_Eccen, 2)))
            $recip = 1 + ($L_Eccen * (radCos ($l_cAnomaly + $l_centreEq)))
            $l_distance = $denom / $recip
            # angular diameter
            $l_dFrac = $l_distance / $L_KmSmAxis
            $l_diameter = $L_AngDeg / $l_dFrac
            # parallax
            # ! originally MoonPar - isn't used for anything or set anywhere
            #$l_parallaxAt = $L_Parallax / $l_dFrac

            return [PSCustomObject]@{
                Phase              = $phase
                Age                = $SynodicMonth * (fixAngle $l_ageDeg) / 360
                Illuminated        = (fixAngle $l_ageDeg) / 360
                Distance           = $l_distance
                AngularDiameter    = $l_diameter
                SunDistance        = $s_distance
                SunAngularDiameter = $s_angSize
            }
        }
    }

    process {
        if (-not $AsUniversalTime) {
            $Date = $Date.ToUniversalTime()
        }
        
        $current = (phase $Date)
        $next = (phase $Date.AddHours(1))
        
        $outputObject = [PSCustomObject]@{
            Phase              = $current.Phase
            Status             = ($next.Phase -gt $current.Phase) ? "Waxing" : "Waning"
            Age                = $current.Age
            Illuminated        = $current.Illuminated
            Distance           = $current.Distance
            AngularDiameter    = $current.AngularDiameter
            SunDistance        = $current.SunDistance
            SunAngularDiameter = $current.SunAngularDiameter
        }
        
        return $outputObject
    }
}
