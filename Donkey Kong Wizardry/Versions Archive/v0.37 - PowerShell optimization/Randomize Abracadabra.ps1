# Determine date-time stamp based folder name
$timestamp = Get-Date -Format yyMMddHHmm

# Create unique rom folder
New-Item -Path ".\roms\" -Name "$($timestamp)" -ItemType "directory" | Out-Null

# Copy template rom to rom folder
Copy-Item ".\templaterom2\dkong.zip" -Destination ".\roms\$($timestamp)"

# Read contents from the four template code rom files
[byte[]]$DKrom_0_5et = Get-Content -Encoding Byte -Path ".\templaterom2\c_5et_g.bin"
[byte[]]$DKrom_1_5ct = Get-Content -Encoding Byte -Path ".\templaterom2\c_5ct_g.bin"
[byte[]]$DKrom_2_5bt = Get-Content -Encoding Byte -Path ".\templaterom2\c_5bt_g.bin"
[byte[]]$DKrom_3_5at = Get-Content -Encoding Byte -Path ".\templaterom2\c_5at_g.bin"

#
# Change HIGH SCORE text to time stamp
#

# Write title to rom file 
for($i=0; $i -lt 10; $i++)
{
    $DKrom_3_5at[0x6B4+$i] = [int]$timestamp[$i]-48 #HIGH SCORE starts at 0x36B2 with first two bytes containing the video location
}

Write-Output "Randomizing Barrels Stage ...."

#
# Define girders
#

#$girderarray = @( (2,0x8F,0x71,0x20,0x78),   # top girder - left half
#                  (2,0xEF,0x77,0x90,0x72),   # top girder - right half
#                  (2,0x8F,0x91,0x10,0x99),   # top girder - left half
#                  (2,0xDF,0x96,0x90,0x92),   # top girder - right half
#                  (2,0x8F,0xB1,0x20,0xB8),   # top girder - left half
#                  (2,0xEF,0xB7,0x90,0xB2),   # top girder - right half
#                  (2,0x8F,0xD1,0x10,0xD9),   # top girder - left half
#                  (2,0xDF,0xD6,0x90,0xD2) )  # top girder - right half
                    
$girderarray = @( (2,0x8F,0x71,0x20,0x78),   # top girder    - left half
                  (2,0xEF,0x77,0x90,0x72),   # top girder    - right half
                  (2,0x8F,0x91,0x00,0x9A),   # third girder  - left half
                  (2,0xDF,0x96,0x90,0x92),   # third girder  - right half
                  (2,0x8F,0xB1,0x20,0xB8),   # second girder - left half
                  (2,0xFF,0xB8,0x90,0xB2),   # second girder - right half
                  (2,0x8F,0xD1,0x00,0xDA),   # bottom girder - left half
                  (2,0xDF,0xD6,0x90,0xD2) )  # bottom girder - right half
                               
#
# Generate randomized ladders
#

$ladderarray = @( (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0x01,0x63,0xD3,0x63,0xF8),    # bottom broken ladder
                  (0x00,0xDB,0xD6,0xDB,0xF2),    # bottom right ladder
                  (0x01,0x6B,0x54,0x6B,0x73),    # top broken ladder
                  (0x00,0xCB,0x59,0xCB,0x75) )   # top right ladder


# Place eight remaining ladders
$skipbrokenladder = Get-Random -Maximum 3

$ladder_ypos = @(0x78, 0x98, 0xB8, 0xD8)
$ladder_index = 0

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
            }
        else
            { 
                $ladder_x  = 0x20 + ($rndstore[$j] * 0x10) + 0x03 # left on segment
            }

        if($rndstore[$j] -lt 7)
            {
                $ladder_yt = $ladder_ypos[$i]-$rndstore[$j] - 1
                $ladder_yb = $ladder_ypos[$i+1]-$rndstore[$j] - 1
            }
        else
            {
                $ladder_yt = $ladder_ypos[$i]+$rndstore[$j] - 13
                $ladder_yb = $ladder_ypos[$i+1]+$rndstore[$j] - 13
            }
        
        $ladderarray[$ladder_index][0] = $ladder_t
        $ladderarray[$ladder_index][1] = $ladder_x
        $ladderarray[$ladder_index][2] = $ladder_yt
        $ladderarray[$ladder_index][3] = $ladder_x
        $ladderarray[$ladder_index][4] = $ladder_yb

        $ladder_index++
    }
}

#
# Write girders to rom files
#

$index = 0xB0C # Start position in file to insert girders

for($i=0; $i -lt 8; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $girderarray[$i][$j]
        $index++
    }
}

#
# write ladders to rom files
#

for($i=0; $i -lt 12; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $ladderarray[$i][$j]
        $index++
    }
}

# Write AA to indicate end of board definition
$DKrom_3_5at[$index] = 0xAA


# Change level
$DKrom_0_5et[0x95E] = 0x03


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