#!/usr/bin/env python3
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path
p = Path(__file__).resolve().parents[1] / "waivers" / "waivers.json"
required = {"finding_id", "rationale", "compensating_control", "owner", "approver", "issue_url", "created_utc", "expires_utc"}
try:
    doc = json.loads(p.read_text(encoding="utf-8"))
    assert doc.get("schema_version") == 1 and isinstance(doc.get("waivers"), list)
    now = datetime.now(timezone.utc)
    for w in doc["waivers"]:
        assert required <= w.keys(), f"missing fields: {required - w.keys()}"
        created = datetime.fromisoformat(w["created_utc"].replace("Z", "+00:00"))
        expires = datetime.fromisoformat(w["expires_utc"].replace("Z", "+00:00"))
        assert created.tzinfo and expires.tzinfo, "timestamps must include timezone"
        limit = timedelta(hours=4 if w.get("break_glass") else 24 * 30)
        assert created < expires <= created + limit, "waiver duration exceeds maximum"
        assert expires > now, f"expired waiver: {w['finding_id']}"
    print(f"OK: {len(doc['waivers'])} waiver(s) valid")
except Exception as e:
    raise SystemExit(f"WAIVER CHECK FAILED: {e}")
