import json
import math

with open('C:/Users/vikto/Documents/Noklusējuma projekts/SpeedZoneLV/SpeedZoneLV/Resources/zones_lv.json') as f:
    data = json.load(f)

def haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1)*math.cos(lat2)*math.sin(dlon/2)**2
    return 2*R*math.asin(math.sqrt(a))

print("Zone coordinate vs official length comparison:")
print("=" * 70)
for zone in data['zones'][:20]:
    start = zone['start']
    end = zone['end']
    actual_dist = haversine(start['latitude'], start['longitude'], end['latitude'], end['longitude'])
    official = zone['officialLengthMeters']
    diff = actual_dist - official
    pct = diff/official*100
    print(f"{zone['id']}: actual={actual_dist:.0f}m, official={official}m, diff={diff:.0f}m ({pct:+.1f}%)")

print("\n--- Summary ---")
diffs = []
for zone in data['zones']:
    start = zone['start']
    end = zone['end']
    actual_dist = haversine(start['latitude'], start['longitude'], end['latitude'], end['longitude'])
    official = zone['officialLengthMeters']
    diff = actual_dist - official
    diffs.append(diff)

print(f"Min diff: {min(diffs):.0f}m")
print(f"Max diff: {max(diffs):.0f}m")
print(f"Avg diff: {sum(diffs)/len(diffs):.0f}m")
print(f"Zones with >50m diff: {sum(1 for d in diffs if abs(d) > 50)}")
print(f"Zones with >100m diff: {sum(1 for d in diffs if abs(d) > 100)}")