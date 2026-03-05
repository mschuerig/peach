#!/usr/bin/env python3
"""Generate a CSV file with backdated training data for testing chart expansion.

Creates comparison records at multiple time ranges so all bucket types appear:
  - 2-3 months ago  -> month buckets (tap to expand into weeks)
  - 2-3 weeks ago   -> week buckets  (tap to expand into days)
  - 2-3 days ago    -> day buckets   (tap to expand into sessions)
  - Today           -> session buckets (finest level, not expandable)

Usage:
    python3 tools/generate-test-data.py              # writes to tools/test-data.csv
    python3 tools/generate-test-data.py output.csv   # writes to custom path

Then import the CSV in the app via Settings > Import Training Data (merge mode).
"""

import csv
import random
import sys
from datetime import datetime, timedelta, timezone

HEADER = [
    "trainingType", "timestamp",
    "referenceNote", "referenceNoteName",
    "targetNote", "targetNoteName",
    "interval", "tuningSystem",
    "centOffset", "isCorrect",
    "initialCentOffset", "userCentError",
]

NOTE_NAMES = [
    "C", "C#", "D", "D#", "E", "F",
    "F#", "G", "G#", "A", "A#", "B",
]


def midi_name(note: int) -> str:
    octave = note // 12 - 1
    return f"{NOTE_NAMES[note % 12]}{octave}"


def iso_timestamp(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def comparison_row(timestamp: datetime, cent_offset: float) -> list:
    ref = 60
    return [
        "comparison",
        iso_timestamp(timestamp),
        str(ref), midi_name(ref),
        str(ref), midi_name(ref),
        "P1",  # unison
        "equalTemperament",
        f"{cent_offset:.1f}",
        "true",
        "",  # initialCentOffset (comparison doesn't use)
        "",  # userCentError (comparison doesn't use)
    ]


def generate_records():
    now = datetime.now(timezone.utc)
    rows = []

    # Month buckets: 60-90 days ago, spread across weeks
    for day in range(60, 91, 2):
        for session in range(3):
            ts = now - timedelta(days=day) + timedelta(minutes=session * 10)
            rows.append(comparison_row(ts, round(random.uniform(8, 25), 1)))

    # Week buckets: 10-20 days ago, spread across days
    for day in range(10, 21):
        for session in range(3):
            ts = now - timedelta(days=day) + timedelta(minutes=session * 10)
            rows.append(comparison_row(ts, round(random.uniform(6, 20), 1)))

    # Day buckets: 2-3 days ago, multiple sessions per day (hours apart)
    for day in [2, 3]:
        for hour in [9, 12, 18]:
            base = now - timedelta(days=day) + timedelta(hours=hour)
            for i in range(4):
                ts = base + timedelta(seconds=i * 30)
                rows.append(comparison_row(ts, round(random.uniform(5, 18), 1)))

    # Session buckets: today, within last hour
    for i in range(5):
        ts = now - timedelta(minutes=i * 5)
        rows.append(comparison_row(ts, round(random.uniform(4, 15), 1)))

    return rows


def main():
    output = sys.argv[1] if len(sys.argv) > 1 else "test-data.csv"
    rows = generate_records()

    with open(output, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        writer.writerows(rows)

    print(f"Written {len(rows)} records to {output}")
    print(f"  Month-level: ~48 records (60-90 days ago)")
    print(f"  Week-level:  ~33 records (10-20 days ago)")
    print(f"  Day-level:   ~24 records (2-3 days ago)")
    print(f"  Session:       5 records (today)")
    print()
    print("Import via: Settings > Import Training Data > Merge")


if __name__ == "__main__":
    main()
