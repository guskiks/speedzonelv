$json = Get-Content 'C:\Users\vikto\Documents\Noklusējuma projekts\SpeedZoneLV\SpeedZoneLV\Resources\zones_lv.json' -Raw | ConvertFrom-Json

function Get-HaversineDistance {
    param($lat1, $lon1, $lat2, $lon2)
    $R = 6371000
    $lat1 = $lat1 * [Math]::PI / 180
    $lon1 = $lon1 * [Math]::PI / 180
    $lat2 = $lat2 * [Math]::PI / 180
    $lon2 = $lon2 * [Math]::PI / 180
    $dlat = $lat2 - $lat1
    $dlon = $lon2 - $lon1
    $a = [Math]::Pow([Math]::Sin($dlat/2), 2) + [Math]::Cos($lat1)*[Math]::Cos($lat2)*[Math]::Pow([Math]::Sin($dlon/2), 2)
    return 2 * $R * [Math]::Asin([Math]::Sqrt($a))
}

Write-Host "Zone coordinate vs official length comparison:"
Write-Host "=" * 70

$diffs = @()
$count = 0
foreach ($zone in $json.zones) {
    if ($count -ge 20) { break }
    $actual = Get-HaversineDistance $zone.start.latitude $zone.start.longitude $zone.end.latitude $zone.end.longitude
    $official = $zone.officialLengthMeters
    $diff = $actual - $official
    $pct = $diff / $official * 100
    Write-Host ("{0}: actual={1:N0}m, official={2:N0}m, diff={3:+N0}m ({4:+.1f}%)" -f $zone.id, $actual, $official, $diff, $pct)
    $diffs += $diff
    $count++
}

Write-Host "`n--- Summary ---"
Write-Host ("Min diff: {0:N0}m" -f ($diffs | Measure-Object -Minimum).Minimum)
Write-Host ("Max diff: {0:N0}m" -f ($diffs | Measure-Object -Maximum).Maximum)
Write-Host ("Avg diff: {0:N0}m" -f ($diffs | Measure-Object -Average).Average)
$gt50 = ($diffs | Where-Object { [Math]::Abs($_) -gt 50 }).Count
$gt100 = ($diffs | Where-Object { [Math]::Abs($_) -gt 100 }).Count
Write-Host "Zones with >50m diff: $gt50"
Write-Host "Zones with >100m diff: $gt100"