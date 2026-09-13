"""Select an available iPhone 17 on iOS 26.1+, failing rather than testing an older OS."""
import json
import subprocess

state = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "--json"]))
runtimes = {r["identifier"] for r in state["runtimes"]
            if r.get("isAvailable") and r.get("platform") == "iOS"
            and tuple(int(p) for p in r["version"].split(".")[:2]) >= (26, 1)}
# Older simctl releases omit platform; runtime identifiers remain explicit.
if not runtimes:
    runtimes = {r["identifier"] for r in state["runtimes"]
                if r.get("isAvailable") and ".iOS-" in r["identifier"]
                and tuple(int(p) for p in r["version"].split(".")[:2]) >= (26, 1)}
for runtime in sorted(runtimes, reverse=True):
    for device in state["devices"].get(runtime, []):
        if device.get("isAvailable") and device["name"] == "iPhone 17":
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit("An available iPhone 17 simulator running iOS 26.1+ is required.")
