# Read contents from the four template code rom files
[byte[]]$DKrom_0_5et = Get-Content -Encoding Byte -Path ".\templaterom2\c_5et_g.bin"
[byte[]]$DKrom_1_5ct = Get-Content -Encoding Byte -Path ".\templaterom2\c_5ct_g.bin"
[byte[]]$DKrom_2_5bt = Get-Content -Encoding Byte -Path ".\templaterom2\c_5bt_g.bin"
[byte[]]$DKrom_3_5at = Get-Content -Encoding Byte -Path ".\templaterom2\c_5at_g.bin"


Write-Output "Calculating randomization distribution ...."
                            
$results = @( 0,0,0,0,0,0,0,0,0,0,0,0 )

# Loop through the contents of the 1st rom file
for($i=0; $i -lt 4096; $i++)
{
    $byte = $DKrom_1_5ct[$i]
    
    $byte_a = $byte -band 1
    $byte_b = ($byte -band 6) / 2
    $byte_c = ($byte -band 56) / 8
    $rnd = $byte_a + $byte_b + $byte_c
    
    $results[$rnd]++

    Write-Host "$byte - $byte_a - $byte_b - $byte_c - $rnd"
}

# Loop through the contents of the 2nd rom file
for($i=0; $i -lt 4096; $i++)
{
    $byte = $DKrom_2_5bt[$i]
    
    $byte_a = $byte -band 1
    $byte_b = ($byte -band 6) / 2
    $byte_c = ($byte -band 56) / 8
    $rnd = $byte_a + $byte_b + $byte_c
    
    $results[$rnd]++

    Write-Host "$byte - $byte_a - $byte_b - $byte_c - $rnd"
}

# Loop through the contents of the 3rd rom file
for($i=0; $i -lt 4096; $i++)
{
    $byte = $DKrom_3_5at[$i]
    
    $byte_a = $byte -band 1
    $byte_b = ($byte -band 6) / 2
    $byte_c = ($byte -band 56) / 8
    $rnd = $byte_a + $byte_b + $byte_c
    
    $results[$rnd]++

    Write-Host "$byte - $byte_a - $byte_b - $byte_c - $rnd"
}

$results

for($i=0; $i -lt 12;$i++)
{
    Write-Host "$i - $($results[$i])"
}