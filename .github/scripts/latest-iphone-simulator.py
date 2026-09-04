#!/usr/bin/env python3
"""Print the UDID of an available iPhone simulator on the newest installed iOS runtime."""
import json
import re
import subprocess
import sys

devices = json.loads(subprocess.run(
    ["xcrun", "simctl", "list", "devices", "available", "--json"],
    capture_output=True, text=True, check=True,
).stdout)["devices"]

best = None
for runtime, runtime_devices in devices.items():
    match = re.search(r"iOS-(\d+)-(\d+)$", runtime)
    if match is None:
        continue
    version = (int(match.group(1)), int(match.group(2)))
    for device in runtime_devices:
        if device["name"].startswith("iPhone") and (best is None or version > best[0]):
            best = (version, device["udid"])
            break

if best is None:
    sys.exit("No available iPhone simulator")

print(best[1])
