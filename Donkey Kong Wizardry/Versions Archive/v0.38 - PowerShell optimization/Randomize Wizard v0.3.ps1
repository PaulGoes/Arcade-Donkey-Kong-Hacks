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
# Generate randomized ladders
#

$ladderarray = @( (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0),
                  (0,0,0,0,0),(0,0,0,0,0) )

# Determine ladder level that won't get broken ladder
$mem3 = Get-Random -Maximum 3

# Reset index in the ladder array
$ladder_index = 0

# Set start ladder y-position for top level ladders
$ladder_ypos = 0x78

# Loop through three ladder levels - OUTER LOOP
# 
# lbla: LD       A,#03
#       LD       (#MEM1),A
#       ... code ...
#       LD       A,(#MEM1)
#       SUB      A,#01
#       LD       (#MEM1),A
#       JR       NZ,#lbla  
# 
for($mem1=3; $mem1 -gt 0; $mem1--)    
{
    # Calculate 3 different random values between 0-11
    #
    #       CALL     #lblx
    #
    # results in 3 different values in MEM3, MEM4 en MEM5
    $rndstore = @(0xFF, 0xFF, 0xFF)
    do
    {
        $rndstore[0] = Get-Random -Maximum 12
        $rndstore[1] = Get-Random -Maximum 12
        $rndstore[2] = Get-Random -Maximum 12
    } until (($rndstore[0] -ne $rndstore[1]) -and ($rndstore[0] -ne $rndstore[2]) -and ($rndstore[1] -ne $rndstore[2]))


    # Loop through three ladders - INNER LOOP
    # 
    # lblb: LD       A,#03
    #       LD       (#MEM2),A
    #       ... code ...
    #       LD       A,(#MEM2)
    #       SUB      A,#01
    #       LD       (#MEM2),A
    #       JR       NZ,#lblb  
    # 
    for($mem2=0; $mem2 -lt 3; $mem2++)
    {
        # skip broken ladder if on ladder level that won't get broken ladder
        if( ($mem1 -eq $mem3) -and ($mem2 -eq 1) ) { continue }

        # Determine ladder type: 1st and 2nd ladder are normal 3rd ladder is broken 
        if($mem2 -eq 1) 
            { $ladder_t = 0x01 } # broken ladder
        else
            { $ladder_t = 0x00 } # normal ladder

        # Determine x-position for ladder
        if($mem1 -eq 2) 
            { 
                $ladder_x  = 0x20 + ($rndstore[$mem2] * 0x10) + 0x0B # right on segment
            }
        else
            { 
                $ladder_x  = 0x20 + ($rndstore[$mem2] * 0x10) + 0x03 # left on segment
            }

        # Determine y-position for top of ladder
        if($rndstore[$mem2] -lt 7)
            {
                $ladder_yt = $ladder_ypos-$rndstore[$mem2] - 1
            }
        else
            {
                $ladder_yt = $ladder_ypos+$rndstore[$mem2] - 13
            }

        # Determine y-position for bottom of ladder
        $ladder_yb = $ladder_yt + 0x20
        
        # Build ladder
        $ladderarray[$ladder_index][0] = $ladder_t
        $ladderarray[$ladder_index][1] = $ladder_x
        $ladderarray[$ladder_index][2] = $ladder_yt
        $ladderarray[$ladder_index][3] = $ladder_x
        $ladderarray[$ladder_index][4] = $ladder_yb

        # Advance index in ladder array
        $ladder_index++
    }

    # Adjust ladder y-position for next ladder level
    $ladder_ypos+=0x20
}

$ladderarray

#
# write ladders to rom files
#

$index = 0xB48 # Start position in file to insert ladders

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

# Change start level
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