$jsonPath = ".\SpeedZoneLV\SpeedZoneLV\Resources\zones_lv.json"
$jsonString = Get-Content $jsonPath -Raw -Encoding UTF8

# Use actual newlines in replacement
$newline = "`n"
$replacement = '"notes": "$1",' + $newline + '                       "entryAdjustmentMeters": -100,' + $newline + '                       "exitAdjustmentMeters": -100' + $newline + '                   }'

$updated = $jsonString -replace '"notes":\s*"([^"]*)"\s*}', $replacement

$updated | Set-Content $jsonPath -Encoding UTF8
Write-Host "Updated zones_lv.json"