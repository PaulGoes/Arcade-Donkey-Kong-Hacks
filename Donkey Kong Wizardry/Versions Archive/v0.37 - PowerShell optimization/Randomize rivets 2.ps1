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
# Generate randomized ladders barrels
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

# Write AA to indicate end of board definition
$DKrom_3_5at[$index] = 0xAA

#
# Generate randomized ladders rivets
#

Write-Output "Randomizing Rivets Stage ...."

$ladderarray = @( (0,0x1B,0xD0,0x1B,0xF8),(0,0xE3,0xD0,0xE3,0xF8),   # outer ladders bottom layer
                  (1,0x23,0xA8,0x23,0xD0),(1,0xDB,0xA8,0xDB,0xD0),   # outer ladders second layer
                  (1,0x53,0xA8,0x53,0xD0),(1,0xA3,0xA8,0xA3,0xD0),   # inner ladders second layer
                  (2,0x2B,0x80,0x2B,0xA8),(2,0xD3,0x80,0xD3,0xA8),   # outer ladders third layer 
                  (3,0x33,0x58,0x33,0x80),(3,0xCB,0x58,0xCB,0x80),   # outer ladders top layer
                  (3,0x53,0x58,0x53,0x80),(3,0xAB,0x58,0xAB,0x80),   # inner ladders top layer 
                  (0,0x5B,0xD0,0x5B,0xF8),(2,0x6B,0x80,0x6B,0xA8) )  # single ladder bottom layer and ingle ladder third layer

# Place the outer ladders and double ladders

$ladder_index = 0

for($i=0; $i -lt 6; $i++)
{
    if($i -lt 2) 
        { $segmentoffset = Get-Random -Maximum 3 }
    else
        { $segmentoffset = Get-Random -Maximum 2 }

    $ladderarray[$ladder_index][1] += ( $segmentoffset * 0x10 )
    $ladderarray[$ladder_index][3] += ( $segmentoffset * 0x10 )

    $ladder_index++

    $ladderarray[$ladder_index][1] -= ( $segmentoffset * 0x10 )
    $ladderarray[$ladder_index][3] -= ( $segmentoffset * 0x10 )

    $ladder_index++
}

# Place the bottom single middle ladder

$segmentoffset = Get-Random -Maximum 6
   
$ladderarray[$ladder_index][1] += ( $segmentoffset * 0x10 )
$ladderarray[$ladder_index][3] += ( $segmentoffset * 0x10 )

$ladder_index++

# Place the 3rd layer single middle ladder

$segmentoffset = Get-Random -Maximum 3
   
$ladderarray[$ladder_index][1] += ( $segmentoffset * 0x10 )
$ladderarray[$ladder_index][3] += ( $segmentoffset * 0x10 )

# Determine girder offsets

for($i=0; $i -lt 3; $i++)
{
    $rnd = Get-Random -Maximum 3
    
    switch ($rnd) {
        0 { $rndstore[$i] = -8 }
        1 { $rndstore[$i] = 0 }
        2 { $rndstore[$i] = +8 }
    }
}

# Adjust ladders to girder offsets

for($i=0; $i -lt 14; $i++)
{
    switch ($ladderarray[$i][0]) {
        0 { $ladderarray[$i][2] += $rndstore[0] ; break }
        1 { $ladderarray[$i][2] += $rndstore[1] ;  $ladderarray[$i][4] += $rndstore[0] ; break }
        2 { $ladderarray[$i][2] += $rndstore[2] ;  $ladderarray[$i][4] += $rndstore[1] ; break }
        3 { $ladderarray[$i][2] += $rndstore[3] ;  $ladderarray[$i][4] += $rndstore[2] ; break } 
    }

    $ladderarray[$i][0] = 0
}

# Adjust girders and fireball placement

$girderarray = @( (5,0xEF,0xF8,0x10,0xF8),   # bottom girder
                  (5,0xE7,0xD0,0x18,0xD0),   # second girder
                  (5,0xDF,0xA8,0x20,0xA8),   # third girder
                  (5,0xD7,0x80,0x28,0x80),   # fourth girder
                  (5,0xCF,0x58,0x30,0x58) )  # top girder

$fireballarray_left = @( (0xEE, 0xF0),   # left bottom girder
                         (0xE6, 0xC8),   # left second girder
                         (0xDB, 0xA0),   # left third girder
                         (0xD6, 0x78) )  # left fourth girder

$fireballarray_right = @( (0x12, 0xF0),  # right bottom girder
                          (0x1B, 0xC8),  # right second girder
                          (0x23, 0xA0),  # right third girder
                          (0x2B, 0x78))  # right fourth girder

for($i=1; $i -lt 4; $i++)
{
    $girderarray[$i][2] += $rndstore[$i-1]
    $girderarray[$i][4] += $rndstore[$i-1]

    $fireballarray_left[$i][1] += $rndstore[$i-1]
    $fireballarray_right[$i][1] += $rndstore[$i-1]
}

# Adjust rivets

$rivetsarray = @( (0xD9, 0x76, 0x39, 0x75),   # second girder rivets
                  (0xD4, 0x76, 0x34, 0x75),   # third girder rivets
                  (0xCF, 0x76, 0x2F, 0x75),   # fourth girder rivets
                  (0xCA, 0x76, 0x2A, 0x75) )  # top girder rivets

for($i=0; $i -lt 3; $i++)
{
    $rivetsarray[$i][0] += ($rndstore[$i]/8)
    $rivetsarray[$i][2] += ($rndstore[$i]/8)
}

# write ladders to rom files
$index = 0xC8B # Start position in file to insert ladders

for($i=0; $i -lt 14; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $ladderarray[$i][$j]
        $index++
    }
}

# write girders to rom files
$index = 0xCD6 # Start position in file to insert girders

for($i=0; $i -lt 5; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $girderarray[$i][$j]
        $index++
    }
}

# write fireball placement to rom files
$indexleft = 0xAC4  # Start position in file to insert left fireballs placement
$indexright = 0xAD4 # Start position in file to insert right fireballs placement

for($i=0; $i -lt 4; $i++)
{
    for($j=0; $j -lt 2; $j++)
    {
        $DKrom_3_5at[$indexleft] = $fireballarray_left[$i][$j]
        $DKrom_3_5at[$indexright] = $fireballarray_right[$i][$j]
        $indexleft++
        $indexright++
    }
}

# write rivets placement to rom files
$index = 0xD17 # Start position in file to insert rivets

for($i=0; $i -lt 4; $i++)
{
    for($j=0; $j -lt 4; $j++)
    {
        $DKrom_0_5et[$index] = $rivetsarray[$i][$j]
        $index++
    }
}

# Set first board first level to rivets
$DKrom_3_5at[0xA65] = 0x04


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