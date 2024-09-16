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

$ladderarray = @( 0,0,0,0,0, 0,0,0,0,0,
                  0,0,0,0,0, 0,0,0,0,0,
                  0,0,0,0,0, 0,0,0,0,0,
                  0,0,0,0,0, 0,0,0,0,0 )

# Determine ladder level that won't get broken ladder - value from 1 to 3
$mem3 = (Get-Random -Maximum 3) + 1

Write-Host "mem3: skip ladder level = $mem3"

# Reset index in the ladder array
$HL = 0

# Set start ladder y-position for top level ladders
$mem4 = 0x78

# Loop through three ladder levels - OUTER LOOP - 3 | 2 | 1
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
    # results in 3 different values in MEM5, MEM6 en MEM7
    $rndstore = @(0xFF, 0xFF, 0xFF)
    do
    {
        $rndstore[0] = Get-Random -Maximum 12
        $rndstore[1] = Get-Random -Maximum 12
        $rndstore[2] = Get-Random -Maximum 12
    } until (($rndstore[0] -ne $rndstore[1]) -and ($rndstore[0] -ne $rndstore[2]) -and ($rndstore[1] -ne $rndstore[2]))

    # Loop through three ladders - INNER LOOP - 3 | 2 | 1
    # 
    # lblb: LD       A,#03
    #       LD       (#MEM2),A
    #       ... code ...
    #       LD       A,(#MEM2)
    #       SUB      A,#01
    #       LD       (#MEM2),A
    #       JR       NZ,#lblb  
    # 
    for($mem2=3; $mem2 -gt 0; $mem2--)
    {
        Write-Host "mem1 / mem2 / mem3 / rndstore[mem2-1] = $mem1 / $mem2 / $mem3 / $($rndstore[$mem2-1])"

        # Determine ladder type: 1st and 2nd ladder are normal 3rd ladder is broken 
        if($mem2 -eq 1) 
            { 
                # Determine if broken ladder is on ladder level that won't get broken ladder
                if($mem1 -eq $mem3)
                {
                    # Do not add this broken ladder - continue loop
                    Write-Host "Continue / Skip ..."
                    continue
                }
               
                $A = 0x01 #broken ladder
            } 
        else
            { 
                $A = 0x00 #normal ladder
            }

        # Determine ladder position for this ladder
        $D = $rndstore[$mem2-1]

        $ladderarray[$HL] = $A # Set laddertype
        $HL++ # Increase pointer into data structure

        # Determine x-position for ladder
        if($mem1 -eq 2) 
            { 
                $A = 0x2B + ($D * 0x10) # right on segment
            }
        else
            { 
                $A = 0x23 + ($D * 0x10) # left on segment
            }

        $ladderarray[$HL] = $A # Set ladder x-position
        $HL++ # Increase pointer into data structure

        $B = $A # Save x-position for later

        # Determine y-position for top of ladder
        if($D -lt 7)
            {
                $A = $mem4 # ladder level pos
                $A = $A -$D - 0x01
            }
        else
            {
                $A = $mem4 #ladder level pos
                $A = $A +$D - 0x0D
            }

        $ladderarray[$HL] = $A # Set ladder y-position top
        $HL++ # Increase pointer into data structure

        # Determine y-position for bottom of ladder
        $A = $A + 0x20
        $C = $A # Save y-position bottom for later

        $A = $B # restore x-position
        $ladderarray[$HL] = $A # Set ladder x-position
        $HL++ # Increase pointer into data structure
        
        $A = $C #restore y-position bottom
        $ladderarray[$HL] = $A # Set ladder y-position bottom
        $HL++ # Increase pointer into data structure

    }

    # Adjust ladder y-position for next ladder level
    $mem4+=0x20
}

#
# write ladders to rom files
#

$index = 0xB48 # Start position in file to insert ladders
for($i=0; $i -lt 45; $i++)
{
    $DKrom_3_5at[$index] = $ladderarray[$i]
    $index++
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