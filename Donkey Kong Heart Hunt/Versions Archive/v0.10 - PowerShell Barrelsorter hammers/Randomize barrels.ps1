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


Write-Output "Building Barrels Stage ...."

$girderarray = @( (0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0), 
                  (0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0) )

$girderarrayindex = 0

$girderdefarray = @( (0x70,0x73,0),
                     (0x30,0x90,1), (0xB0,0x90,2),
                     (0x70,0xAF,0),
                     (0x30,0xD0,1), (0xB0,0xD0,2) )

for($count = 0; $count -lt 6; $count++)
{
    [int]$x_pos = $girderdefarray[$count][0]
    [int]$y_pos = $girderdefarray[$count][1]
    [int]$short = $girderdefarray[$count][2]
    [int]$slope = 2

    Write-Output "    Creating construct $($count) : startposition ($($x_pos),$($y_pos)) with short $short ..."

    #Create left slope segment including top
    if( ($short -eq 0) -or ($short -eq 2) )
    {
        #Create long left segment
        $girder_x_right = $x_pos+0x0F
        $girder_y_right = $y_pos
        $girder_x_left = $x_pos-$slope*0x10
        $girder_y_left = $y_pos+$slope
    }
    else
    {
        #Create short left segment
        $girder_x_right = $x_pos+0x0F
        $girder_y_right = $y_pos
        $girder_x_left = $x_pos-($slope-1)*0x10
        $girder_y_left = $y_pos+($slope-1)
    }

    $girderarray[$girderarrayindex][0] = 0x02 # slanted girder
    $girderarray[$girderarrayindex][1] = $girder_x_right
    $girderarray[$girderarrayindex][2] = $girder_y_right
    $girderarray[$girderarrayindex][3] = $girder_x_left
    $girderarray[$girderarrayindex][4] = $girder_y_left

    $girderarrayindex++

    #Create left slope segment including top

    if( ($short -eq 0) -or ($short -eq 1) )
    {
        #Create long right segment
        $girder_x_right = $x_pos+0x1F+$slope*0x10
        $girder_y_right = $y_pos+$slope
        $girder_x_left = $x_pos+0x10
        $girder_y_left = $y_pos
    }
    else
    {
        #Create short right segment
        $girder_x_right = $x_pos+0x1F+($slope-1)*0x10
        $girder_y_right = $y_pos+($slope-1)
        $girder_x_left = $x_pos+0x10
        $girder_y_left = $y_pos
    }

    $girderarray[$girderarrayindex][0] = 0x02 # slanted girder
    $girderarray[$girderarrayindex][1] = $girder_x_right
    $girderarray[$girderarrayindex][2] = $girder_y_right
    $girderarray[$girderarrayindex][3] = $girder_x_left
    $girderarray[$girderarrayindex][4] = $girder_y_left

    $girderarrayindex++
}

#Create single ramp left

$girderarray[$girderarrayindex][0] = 0x02 # slanted girder
$girderarray[$girderarrayindex][1] = 0x2F
$girderarray[$girderarrayindex][2] = 0xB1
$girderarray[$girderarrayindex][3] = 0x00
$girderarray[$girderarrayindex][4] = 0xAF

$girderarrayindex++

#Create single ramp right

$girderarray[$girderarrayindex][0] = 0x02 # slanted girder
$girderarray[$girderarrayindex][1] = 0xFF
$girderarray[$girderarrayindex][2] = 0xAF
$girderarray[$girderarrayindex][3] = 0xD0
$girderarray[$girderarrayindex][4] = 0xB1

$girderarrayindex++


#
# Generate ladders
#

$ladderarray = @( (0x00,0xBB,0xD0,0xBB,0xF4),
                  (0x00,0xA3,0xB1,0xA3,0xD1),
                  (0x00,0x5B,0xB1,0x5B,0xD1),
                  (0x00,0x2B,0xB1,0x2B,0xD1),
                  (0x00,0x23,0x91,0x23,0xB1),
                  (0x00,0x5B,0x75,0x5B,0x91),
                  (0x00,0xA3,0x75,0xA3,0x91),
                  (0x01,0x43,0xD0,0x43,0xF8),
                  (0x00,0xD3,0x91,0xD3,0xB1) )
                  #(0x01,0xDB,0xB1,0xDB,0xD1) )

$ladderarrayindex = 9

# write girders to rom files
$index = 0xB11 # Start position in file to insert girders

for($i=0; $i -lt $girderarrayindex; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $girderarray[$i][$j]
        $index++
    }
}

for($i=0; $i -lt $ladderarrayindex; $i++)
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