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

#
# Generate randomized ladders
#

Write-Output "Randomizing Barrels Stage ...."

$ladderarray = @( (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0) )

# Place bottom ladder
$segmentoffset = Get-Random -Maximum 6

$ladder_x  = 0x80 + ($segmentoffset * 0x10) + 0x0B

$ladderarray[0][0] = 0x00 # normal ladder
$ladderarray[0][1] = $ladder_x
$ladderarray[0][2] = 0xD7 + $segmentoffset
$ladderarray[0][3] = $ladder_x
$ladderarray[0][4] = 0xF7 - $segmentoffset

# Place top ladder
$segmentoffset = Get-Random -Maximum 4

$ladder_x  = 0xA0 + ($segmentoffset * 0x10) + 0x0B

$ladderarray[1][0] = 0x00 # normal ladder
$ladderarray[1][1] = $ladder_x
$ladderarray[1][2] = 0x55 + $segmentoffset
$ladderarray[1][3] = $ladder_x
$ladderarray[1][4] = 0x71 - $segmentoffset

# Place eight remaining ladders
$skipbrokenladder = Get-Random -Maximum 3

$ladder_ypos = @(0x79, 0x8F, 0xBB, 0xD1)
$ladder_index = 2

for($i=0; $i -lt 3; $i++)
{
    $rndstore = @(0xFF, 0xFF, 0xFF)

    do
    {
        $rndstore[0] = Get-Random -Maximum 12
        $rndstore[1] = Get-Random -Maximum 12
        $rndstore[2] = Get-Random -Maximum 12
    } until (($rndstore[0] -ne $rndstore[1]) -and ($rndstore[0] -ne $rndstore[2]) -and ($rndstore[1] -ne $rndstore[2]))

    for($j=0; $j -lt 3; $j++)
    {
        if( ($i -eq $skipbrokenladder) -and ($j -eq 2) ) { continue }

        if($j -eq 2) 
            { $ladder_t = 0x01 } # broken ladder
        else
            { $ladder_t = 0x00 } # normal ladder

        if($i -eq 1) 
            { 
                $ladder_x  = 0x20 + ($rndstore[$j] * 0x10) + 0x0B # right on segment
                $ladder_yt = $ladder_ypos[$i]+$rndstore[$j]
                $ladder_yb = $ladder_ypos[$i+1]-$rndstore[$j]
            }
        else
            { 
                $ladder_x  = 0x20 + ($rndstore[$j] * 0x10) + 0x03 # left on segment
                $ladder_yt = $ladder_ypos[$i]-$rndstore[$j]
                $ladder_yb = $ladder_ypos[$i+1]+$rndstore[$j]
            }

        $ladderarray[$ladder_index][0] = $ladder_t
        $ladderarray[$ladder_index][1] = $ladder_x
        $ladderarray[$ladder_index][2] = $ladder_yt
        $ladderarray[$ladder_index][3] = $ladder_x
        $ladderarray[$ladder_index][4] = $ladder_yb

        $ladder_index++
    }
}



# write ladders to rom files
$index = 0xB2A # Start position in file to insert ladders

for($i=0; $i -lt 10; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $ladderarray[$i][$j]
        $index++
    }
}



# Setup array with initial values (y-position = original -4), lowest girder to highest girder
#$girderarray = @( (0x02, 0xDF, 0xDC, 0X10, 0xD0),
#                  (0x02, 0xEF, 0xAF, 0X20, 0xBB),
#                  (0x02, 0xDF, 0x9A, 0X10, 0x8E), 
#                  (0x02, 0xEF, 0x6D, 0X20, 0x79) )


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