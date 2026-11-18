$jsonPath = ".\SpeedZoneLV\SpeedZoneLV\Resources\zones_lv.json"
$jsonString = Get-Content $jsonPath -Raw -Encoding UTF8

# Fix indentation for the new fields (should be 23 spaces like other fields)
$fixed = $jsonString -replace '^(\s{7})"entryAdjustmentMeters"', '                       "entryAdjustmentMeters"' -replace '^(\s{7})"exitAdjustmentMeters"', '                       "exitAdjustmentMeters"'

$fixed | Set-Content $jsonPath -Encoding UTF8
Write-Host "Fixed indentation"