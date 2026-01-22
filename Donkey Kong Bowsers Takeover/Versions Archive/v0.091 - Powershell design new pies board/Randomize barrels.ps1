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

$girderarray = @( (0x02,0x8F,0xF0,0x80,0xF0),(0x02,0xA7,0xE8,0x98,0xE8),(0x02,0xBF,0xE0,0xB0,0xE0),
                  (0x02,0xDF,0xD8,0xD0,0xD8), # staircase girders bottom 
                  (0x00,0xDB,0xB8,0xDB,0xD8), # ladder bottom right
                  (0x02,0xDF,0xB8,0xD0,0xB8), (0x02,0xBF,0xC0,0xB0,0xC0),(0x02,0xA7,0xC8,0x98,0xC8),
                  (0x02,0x8F,0xD0,0x80,0xD0),(0x02,0x77,0xC8,0x68,0xC8),(0x02,0x5F,0xC0,0x50,0xC0), 
                  (0x02,0x47,0xC8,0x38,0xC8),(0x02,0x27,0xD0,0x18,0xD0), # staircase girders 2nd level
                  (0x00,0x1B,0xB0,0x1B,0xD0), # ladder 2nd level left
                  (0x02,0x27,0xB0,0x18,0xB0),(0x02,0x47,0xA8,0x38,0xA8),(0x02,0x5F,0xA0,0x50,0xA0), # staricase girders 3rd level
                  (0x02,0xA7,0xA8,0x68,0xA8),(0x02,0xA7,0x78,0x68,0x78), # girders middle part
                  (0x00,0x6B,0x78,0x6B,0xA8),(0x00,0xA3,0x78,0xA3,0xA8), # ladders middle part
                  (0x02,0x5F,0x80,0x50,0x80),(0x02,0x47,0x88,0x38,0x88),
                  (0x02,0x27,0x90,0x18,0x90),(0x02,0x27,0x70,0x18,0x70), # staircase girders left top
                  (0x00,0x1B,0x70,0x1B,0x90), # ladder left top
                  (0x02,0xBF,0xA0,0xB0,0xA0),(0x02,0xDF,0x98,0xD0,0x98),
                  (0x02,0xDF,0x78,0xD0,0x78), # starcase girders right top
                  (0x00,0xDB,0x78,0xDB,0x98), # ladder right top
                  (0x00,0x83,0x54,0x83,0x78), # ladder to bowser level
                  (0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0) )

$girderarrayindex = 31

#$girderdefarray = @( (0x70,0x70,2),
#                     (0x30,0x90,2), (0xB0,0x90,2),
#                     (0x70,0xB0,2),
#                     (0x30,0xD0,2), (0xB0,0xD0,2) )

#for($count = 0; $count -lt 6; $count++)
#{
    #[int]$x_pos = $girderdefarray[$count][0]
    #[int]$y_pos = $girderdefarray[$count][1]
    #[int]$slope = $girderdefarray[$count][2]

    #Write-Output "    Creating construct $($count) : startposition ($($x_pos),$($y_pos)) with slope $slope ..."

    #Create left slope segment including top

    #$girder_x_right = $x_pos+0x0F
    #$girder_y_right = $y_pos
    #$girder_x_left = $x_pos-$slope*0x10
    #$girder_y_left = $y_pos+$slope

    #$girderarray[$girderarrayindex][0] = 0x02 # slanted girder
    #$girderarray[$girderarrayindex][1] = $girder_x_right
    #$girderarray[$girderarrayindex][2] = $girder_y_right
    #$girderarray[$girderarrayindex][3] = $girder_x_left
    #$girderarray[$girderarrayindex][4] = $girder_y_left

    #$girderarrayindex++

    #Create right slope segment

    #Create left slope segment including top

    #$girder_x_right = $x_pos+0x1F+$slope*0x10
    #$girder_y_right = $y_pos+$slope
    #$girder_x_left = $x_pos+0x10
    #$girder_y_left = $y_pos

    #$girderarray[$girderarrayindex][0] = 0x02 # slanted girder
    #$girderarray[$girderarrayindex][1] = $girder_x_right
    #$girderarray[$girderarrayindex][2] = $girder_y_right
    #$girderarray[$girderarrayindex][3] = $girder_x_left
    #$girderarray[$girderarrayindex][4] = $girder_y_left

    #girderarrayindex++

#}


#
# Generate randomized ladders
#

#$ladderarray = @( (0,0,0,0,0),(0,0,0,0,0),
#                  (0,0,0,0,0),(0,0,0,0,0),
#                  (0,0,0,0,0),(0,0,0,0,0),
#                  (0,0,0,0,0),(0,0,0,0,0) )


# Place eight remaining ladders
#$skipbrokenladder = Get-Random -Maximum 3

#Write-Output "- skip broken ladder on $($skipbrokenladder)"

#$ladder_ypos = @(0x6E, 0x96, 0xAC, 0xDC)
#$ladder_index = 0

# offset ladder ypos start values
#$ladder_ypos[1] = $ladder_ypos[1] + $girderoffset1
#$ladder_ypos[2] = $ladder_ypos[2] + $girderoffset2

#for($i=0; $i -lt 3; $i++)
#{
#    $rndstore = @(0xFF, 0xFF, 0xFF)
#
#    do
#    {
#        $rndstore[0] = Get-Random -Maximum 6
#        $rndstore[1] = Get-Random -Maximum 6
#        $rndstore[2] = Get-Random -Maximum 6
#    } until (($rndstore[0] -ne $rndstore[1]) -and ($rndstore[0] -ne $rndstore[2]) -and ($rndstore[1] -ne $rndstore[2]))
#
#    Write-Output "- ladder offsets: $($rndstore[0]) - $($rndstore[1]) - $($rndstore[2])"
#
#    for($j=0; $j -lt 3; $j++)
#    {
#        if( ($i -eq $skipbrokenladder) -and ($j -eq 2) ) { continue }

#        # determine ladder type: last ladder is broken ladder
#        if($j -eq 2) 
#            { $ladder_t = 0x01 } # broken ladder
#        else
#            { $ladder_t = 0x00 } # normal ladder

#        # determine start value for x
#        $ladder_x  = 0xD3 - ($rndstore[$j] * 0x20)
        
        
#        #determine start values for y
#        $ladder_yt = $ladder_ypos[$i]
#        $ladder_yb = $ladder_ypos[$i+1]
#        $ladder_delta = $rndstore[$j] * 0x02

#        # determine offsets for multiple of 4
#        $ladder_y_diff = $ladder_ypos[$i+1]-$ladder_ypos[$i]
#        if( ($ladder_y_diff -band 0x03) -ne 0)
#        {
#            $ladder_x  = $ladder_x - 0x10 # offset one segment left if not multiple of 4
#            $ladder_delta = $ladder_delta + 0x01
#        }
#        if($i -eq 1)
#        {
#            $ladder_x = $ladder_x + 0x08 # offset to right on segment if middle area
#            $ladder_yt = $ladder_yt - $ladder_delta
#            $ladder_yb = $ladder_yb + $ladder_delta
#        }
#        else
#        {
#            $ladder_yt = $ladder_yt + $ladder_delta
#            $ladder_yb = $ladder_yb - $ladder_delta
#        }
#       
#        Write-Output "-- $($ladder_t) $($ladder_x) $($ladder_yt) $($ladder_x) $($ladder_yb)"
#
#        $ladderarray[$ladder_index][0] = $ladder_t
#        $ladderarray[$ladder_index][1] = $ladder_x
#        $ladderarray[$ladder_index][2] = $ladder_yt
#        $ladderarray[$ladder_index][3] = $ladder_x
#        $ladderarray[$ladder_index][4] = $ladder_yb

#        $ladder_index++
#    }
#}


# write girders to rom files
$index = 0xB0C # Start position in file to insert ladders

for($i=0; $i -lt $girderarrayindex; $i++)
{
    for($j=0; $j -lt 5; $j++)
    {
        $DKrom_3_5at[$index] = $girderarray[$i][$j]
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