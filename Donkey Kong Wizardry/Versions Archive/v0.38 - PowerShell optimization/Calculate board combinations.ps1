$valueswith3bitsset = 0
$valueswith2bitsset = 0

for($value=0x00; $value -lt 0x1000; $value++)
{

    [int]$bit00 = [int][bool]($value -band    1)
    [int]$bit01 = [int][bool]($value -band    2)
    [int]$bit02 = [int][bool]($value -band    4)
    [int]$bit03 = [int][bool]($value -band    8)
    [int]$bit04 = [int][bool]($value -band   16)
    [int]$bit05 = [int][bool]($value -band   32)
    [int]$bit06 = [int][bool]($value -band   64)
    [int]$bit07 = [int][bool]($value -band  128)
    [int]$bit08 = [int][bool]($value -band  256)
    [int]$bit09 = [int][bool]($value -band  512)
    [int]$bit10 = [int][bool]($value -band 1024)
    [int]$bit11 = [int][bool]($value -band 2048)
    
    $mark2 = "    "
    $mark3 = "    "
    $bitsset = $bit11 + $bit10 + $bit09 + $bit08 + $bit07 + $bit06 + $bit05 + $bit04 + $bit03 + $bit02 + $bit01 + $bit00
    if($bitsset -eq 3)
    {
        $valueswith3bitsset++
        $mark3 = "<--3"
    }
    if($bitsset -eq 2)
    {
        $valueswith2bitsset++
        $mark2 = "<--2"

    }

    Write-Host "$($value) $($bit11) $($bit10) $($bit09) $($bit08) $($bit07) $($bit06) $($bit05) $($bit04) $($bit03) $($bit02) $($bit01) $($bit00) $($mark2) $($mark3)"
}


$boardcombinations = $valueswith3bitsset*$valueswith3bitsset*$valueswith2bitsset

Write-Host
Write-Host "Total values with exactly 2 bits set: $($valueswith2bitsset)"
Write-Host "Total values with exactly 3 bits set: $($valueswith3bitsset)"
Write-Host "Total number of possible board combinations:  $($boardcombinations)"