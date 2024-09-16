# Determine date-time stamp based folder name
$timestamp = Get-Date -Format yyMMddHHmm

# Create unique rom folder
New-Item -Path ".\roms\" -Name "$($timestamp)" -ItemType "directory" | Out-Null

# Copy template rom to rom folder
Copy-Item ".\templaterom\dkong.zip" -Destination ".\roms\$($timestamp)"

# Read contents from the four template code rom files
[byte[]]$DKrom_0_5et = Get-Content -Encoding Byte -Path ".\templaterom\c_5et_g.bin"
[byte[]]$DKrom_1_5ct = Get-Content -Encoding Byte -Path ".\templaterom\c_5ct_g.bin"
[byte[]]$DKrom_2_5bt = Get-Content -Encoding Byte -Path ".\templaterom\c_5bt_g.bin"
[byte[]]$DKrom_3_5at = Get-Content -Encoding Byte -Path ".\templaterom\c_5at_g.bin"

#
# Change HIGH SCORE text to time stamp
#

# Write timestamp to rom file 
for($i=0; $i -lt 10; $i++)
{
    $DKrom_3_5at[0x6B4+$i] = [int]$timestamp[$i]-48 #HIGH SCORE starts at 0x36B2 with first two bytes containing the video location
}


Write-Output "Randomizing Barrels Stage ...."

#
# Generate randomized girders
#

$girderarray = @( (0,0,0,0,0),(0,0,0,0,0) )

# Shift upper randomized girder
#$girderoffset1 = (Get-Random -Maximum 4)*2
$girderoffset1 = (Get-Random -Maximum 5)*2
#$girderoffset1 = 8
Write-Output "- 1st girderoffset = $($girderoffset1)"

$girder_y_right = 0x96 + $girderoffset1 # 0x9A original y-value - 4
$girder_y_left = $girder_y_right - 0x0C

$girderarray[0][0] = 0x02 # slanted girder
$girderarray[0][1] = 0xDF
$girderarray[0][2] = $girder_y_right
$girderarray[0][3] = 0x10 - 0x08 # extend girder for correct roll-over
$girderarray[0][4] = $girder_y_left

# Shift lower randomized girder
#$girderoffset2 = (Get-Random -Maximum 4)*2
$girderoffset2 = (Get-Random -Maximum 5)*2
#$girderoffset2 = 0
Write-Output "- 2nd girderoffset = $($girderoffset2)"

#$girder_y_right = 0xAB + $girderoffset2 # 0xAF original y-value - 4
$girder_y_right = 0xA9 + $girderoffset2 # 0xAF original y-value - 6
$girder_y_left = $girder_y_right + 0x0C 

$girderarray[1][0] = 0x02 # slanted girder
$girderarray[1][1] = 0xEF
$girderarray[1][2] = $girder_y_right
$girderarray[1][3] = 0x20
$girderarray[1][4] = $girder_y_left


#
# Generate randomized ladders
#

$ladderarray = @( (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0) )


# Place eight remaining ladders
$skipnormalladder = Get-Random -Maximum 3
$girder_delta = $girderoffset1 - $girderoffset2

Write-Output "- skip normal ladder on $($skipnormalladder)"

#$ladder_ypos = @(0x6E, 0x96, 0xAC, 0xDC)
$ladder_ypos = @(0x6E, 0x96, 0xAA, 0xDC)
$ladder_index = 0

# offset ladder ypos start values
$ladder_ypos[1] = $ladder_ypos[1] + $girderoffset1
$ladder_ypos[2] = $ladder_ypos[2] + $girderoffset2

for($i=0; $i -lt 3; $i++)
{
    $rndstore = @(0xFF, 0xFF, 0xFF)

    do
    {
        $rndstore[0] = Get-Random -Maximum 6
        $rndstore[1] = Get-Random -Maximum 6
        $rndstore[2] = Get-Random -Maximum 6
        #$rndstore[0] = 1
        #$rndstore[1] = 2
        #$rndstore[2] = 5
    } until (($rndstore[0] -ne $rndstore[1]) -and ($rndstore[0] -ne $rndstore[2]) -and ($rndstore[1] -ne $rndstore[2]))

    Write-Output "- ladder offsets: $($rndstore[0]) - $($rndstore[1]) - $($rndstore[2])"

    for($j=0; $j -lt 3; $j++)
    {
        if( ($i -eq $skipnormalladder) -and ($j -eq 1) ) { continue }

        if( ($girder_delta -ge 4) -and ($i -eq 1) -and ($j -eq 2) ) { continue }

        # determine ladder type: last ladder is broken ladder
        if($j -eq 2) 
            { $ladder_t = 0x01 } # broken ladder
        else
            { $ladder_t = 0x00 } # normal ladder

        # determine start value for x
        $ladder_x  = 0xD3 - ($rndstore[$j] * 0x20)
        
        #determine start values for y
        $ladder_yt = $ladder_ypos[$i]
        $ladder_yb = $ladder_ypos[$i+1]
        $ladder_delta = $rndstore[$j] * 0x02

        # determine offsets for multiple of 4
        $ladder_y_diff = $ladder_ypos[$i+1]-$ladder_ypos[$i]
        if( ($ladder_y_diff -band 0x03) -ne 0)
        {
            $ladder_x  = $ladder_x - 0x10 # offset one segment left if not multiple of 4
            $ladder_delta = $ladder_delta + 0x01
        }
        if($i -eq 1)
        {
            $ladder_x = $ladder_x + 0x08 # offset to right on segment if middle area
            $ladder_yt = $ladder_yt - $ladder_delta
            $ladder_yb = $ladder_yb + $ladder_delta
        }
        else
        {
            $ladder_yt = $ladder_yt + $ladder_delta
            $ladder_yb = $ladder_yb - $ladder_delta
        }
       
        Write-Output "-- $($ladder_t) $($ladder_x) $($ladder_yt) $($ladder_x) $($ladder_yb)"

        $ladderarray[$ladder_index][0] = $ladder_t
        $ladderarray[$ladder_index][1] = $ladder_x
        $ladderarray[$ladder_index][2] = $ladder_yt
        $ladderarray[$ladder_index][3] = $ladder_x
        $ladderarray[$ladder_index][4] = $ladder_yb

        $ladder_index++
    }
}


# write girders to rom files
$index = 0xB2A # Start position in file to insert ladders

for($i=0; $i -lt 2; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $girderarray[$i][$j]
        $index++
    }
}


# write ladders to rom files
$index = 0xB34 # Start position in file to insert ladders

for($i=0; $i -lt 8; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $ladderarray[$i][$j]
        $index++
    }
}


# Write AA to indicate end of board definition
$DKrom_3_5at[$index] = 0xAA

# Write changed contents to four code rom files
Set-Content -Encoding Byte -Path ".\roms\$($timestamp)\c_5et_g.bin" -Value $DKrom_0_5et
Set-Content -Encoding Byte -Path ".\roms\$($timestamp)\c_5ct_g.bin" -Value $DKrom_1_5ct
Set-Content -Encoding Byte -Path ".\roms\$($timestamp)\c_5bt_g.bin" -Value $DKrom_2_5bt
Set-Content -Encoding Byte -Path ".\roms\$($timestamp)\c_5at_g.bin" -Value $DKrom_3_5at

# Add the four code rom files to dkong.zip
Compress-Archive -Path ".\roms\$($timestamp)\c_5et_g.bin" -DestinationPath ".\roms\$($timestamp)\dkong.zip" -Update
Compress-Archive -Path ".\roms\$($timestamp)\c_5ct_g.bin" -DestinationPath ".\roms\$($timestamp)\dkong.zip" -Update
Compress-Archive -Path ".\roms\$($timestamp)\c_5bt_g.bin" -DestinationPath ".\roms\$($timestamp)\dkong.zip" -Update
Compress-Archive -Path ".\roms\$($timestamp)\c_5at_g.bin" -DestinationPath ".\roms\$($timestamp)\dkong.zip" -Update

# Create command file to run created rom
$mameexe = "C:\Data\WolfMame\mame64.exe"
$rompath = "$($PSScriptroot)\roms\$($timestamp)"
$command = """$($mameexe)"" -rompath ""$($rompath)"" dkong.zip"
Set-Content -Encoding String -Path ".\roms\$($timestamp)\startrom.cmd" -Value $command

# Run created rom
Invoke-Item -Path ".\roms\$($timestamp)\startrom.cmd"