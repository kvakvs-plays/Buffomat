"""Download DB2 tables as CSV from wago.tools, which allows AI agents and scripts to use
/db2/{table}/csv and /api/ (see https://wago.tools/llms.txt). Wowhead's robots.txt disallows
Anthropic crawlers, so do not scrape Wowhead.

Politeness: one request at a time, 3 s apart, every table cached on disk and fetched once.

Usage: python -I fetch.py <outdir> <Table1,Table2,...>
Env:   WOWF_VERSION (default 1.60.1.70862), ERA_VERSION (default 1.15.9.70576),
       TAGS=wowf,era to pick which builds to fetch.
Find current versions with: curl -s https://wago.tools/api/builds/latest  (products wowf, wow_classic_era)
"""
import sys, os, time, urllib.request
out = sys.argv[1]
allBuilds = {"wowf": os.environ.get("WOWF_VERSION", "1.60.1.70862"),
             "era": os.environ.get("ERA_VERSION", "1.15.9.70576")}
builds = {k: v for k, v in allBuilds.items() if k in os.environ.get("TAGS", "wowf,era").split(",")}
tables = sys.argv[2].split(",")
for tag, ver in builds.items():
    for t in tables:
        p = os.path.join(out, f"{t}.{tag}.csv")
        if os.path.exists(p) and os.path.getsize(p) > 0:
            continue
        url = f"https://wago.tools/db2/{t}/csv?version={ver}"
        req = urllib.request.Request(url, headers={"User-Agent": "BuffomatClassic-addon-research/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                data = r.read()
            open(p, "wb").write(data)
            print(tag, t, len(data))
        except Exception as e:
            print(tag, t, "ERR", e)
        time.sleep(3)
