# Latvian zone database

`zones_lv.json` is the only production source of control zones. It ships inside
the app and can be overridden from `Documents/zones_lv.json` without
rebuilding.

## Non-negotiable rules

1. **Never invent coordinates.** If a zone cannot be verified, it stays out.
2. Every verified zone needs:
   - a public source URL,
   - a retrieval date,
   - a last-verification date,
   - the official length and speed limit.
3. Mark the zone `unverified` if any of the above is missing. The detection
   engine must ignore unverified zones.
4. Demo fixtures (`verification: "demo"`) belong in code/tests, not in the
   production JSON.
5. Keep the disclaimer honest. A GPS average is not an official enforcement
   measurement.

## Schema v1

```json
{
  "schemaVersion": 1,
  "countryCode": "LV",
  "updatedAt": "2026-11-09",
  "disclaimer": "…",
  "sources": [
    {
      "name": "Source name",
      "url": "https://…",
      "license": "License or terms",
      "retrievedAt": "2026-11-09"
    }
  ],
  "zones": [
    {
      "id": "lv-a1-example-001",
      "name": "Human-readable section name",
      "road": "A1",
      "direction": "startToEnd",
      "directionDescription": "Rīgas virzienā",
      "start": { "latitude": 0.0, "longitude": 0.0 },
      "end": { "latitude": 0.0, "longitude": 0.0 },
      "officialLengthMeters": 0,
      "speedLimitKmh": 90,
      "source": {
        "name": "Source name",
        "url": "https://…",
        "license": "License",
        "retrievedAt": "2026-11-09"
      },
      "verification": "verified",
      "lastVerified": "2026-11-09",
      "notes": "Optional"
    }
  ]
}
```

`direction` is relative to the stored coordinates:

- `startToEnd`: legal travel enters at `start` and exits at `end`.
- `endToStart`: legal travel enters at `end` and exits at `start`.

`directionDescription` is the human-facing direction, e.g. “Rīgas virzienā”.

## Validation performed by the app

- schema version must be `1`;
- zone IDs must be unique;
- coordinates must be finite and in range;
- length must be > 0;
- speed limit must be 20–160 km/h;
- every zone must name a source;
- verified zones must have `lastVerified`.

A Documents override that fails validation falls back to the bundled file and
displays the error on the Settings screen.

## Research starting points (not yet verified data)

- Latvijas Valsts ceļi (LVC) publications and road information.
- CSDD public information.
- OpenStreetMap enforcement/`maxspeed` data (respect ODbL attribution and
  check individual objects; OSM is not automatically authoritative).
- Official/public camera map announcements.

No coordinates will be committed until they can be cross-checked. The empty
`zones` array is deliberate.
