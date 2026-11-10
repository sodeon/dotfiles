#!/usr/bin/env bash
# Usage: ./jav_rename.sh [--dry-run] [--refresh] *.mp4

set -e

# ==============================================================================
# USER CONFIGURATION
# ==============================================================================
REMOVE_STRINGS=(
    "【FANZA限定】"
    "\[FANZA限定\]"
    "【SODstar】"
    "【VR】"
    "【4K】"
    "\[4K\]"
    "(BOD)"
    "【数量限定】"
    "【配信専用】"
    "【ベストヒッツ】"
    "パンティとチェキ付き"
)

# Where to place "Uncensored" in the expanded filename:
#   "suffix" -> 103126-001 Title Actress.2026.Uncensored[.4K].mp4
#   "prefix" -> Uncensored 103126-001 Title Actress.2026[.4K].mp4
#   "after_id" -> 103126-001 Uncensored Title Actress.2026[.4K].mp4
UNCENSORED_POS="after_id"

DRY_RUN=0
REFRESH_CACHE=0
while [[ "${1-}" == --* ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --refresh) REFRESH_CACHE=1; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [--dry-run] [--refresh] <file1.mp4> [file2.mp4 ...]"
    exit 1
fi

VENV_DIR="$HOME/.local/share/jav_renamer_venv"
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
    echo "[INIT] Setting up isolated Python environment at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --quiet --upgrade pip
    "$VENV_DIR/bin/pip" install --quiet curl_cffi beautifulsoup4
elif ! "$VENV_DIR/bin/python" -c "import curl_cffi, bs4" &>/dev/null; then
    "$VENV_DIR/bin/pip" install --quiet --upgrade curl_cffi beautifulsoup4
fi

REMOVE_LIST_ENV=$(printf "%s\n" "${REMOVE_STRINGS[@]}")

UNCENSORED_POS="$UNCENSORED_POS" REMOVE_LIST="$REMOVE_LIST_ENV" REFRESH_CACHE="$REFRESH_CACHE" "$VENV_DIR/bin/python" - "$DRY_RUN" "$@" << 'EOF'
import sys
import os
import re
import glob
import json
import time
import shutil
import sqlite3
import tempfile
import subprocess
import urllib.parse
from curl_cffi import requests as cffi_requests
from bs4 import BeautifulSoup

dry_run = sys.argv[1] == "1"
refresh_cache = os.environ.get("REFRESH_CACHE") == "1"
uncensored_pos = os.environ.get("UNCENSORED_POS", "suffix").strip().lower()
files = sys.argv[2:]
remove_patterns = [p.strip() for p in os.environ.get("REMOVE_LIST", "").splitlines() if p.strip()]

CACHE_PATH = os.path.expanduser("~/.cache/jav_rename_cache.json")
os.makedirs(os.path.dirname(CACHE_PATH), exist_ok=True)
try:
    with open(CACHE_PATH, "r", encoding="utf-8") as f:
        metadata_cache = json.load(f)
except Exception:
    metadata_cache = {}

def save_cache():
    try:
        with open(CACHE_PATH, "w", encoding="utf-8") as f:
            json.dump(metadata_cache, f, ensure_ascii=False, indent=2)
    except Exception:
        pass

def find_newest_firefox_cookies_db():
    patterns = [
        "~/.mozilla/firefox/*/cookies.sqlite",
        "~/snap/firefox/common/.mozilla/firefox/*/cookies.sqlite",
        "~/.var/app/org.mozilla.firefox/.mozilla/firefox/*/cookies.sqlite",
    ]
    candidates = []
    for p in patterns:
        candidates.extend(glob.glob(os.path.expanduser(p)))
    if not candidates:
        return None
    return max(candidates, key=os.path.getmtime)

def detect_firefox_user_agent(prof_dir):
    if os.environ.get("JAVDB_UA"):
        return [os.environ["JAVDB_UA"].strip()]

    ff_ver = "136.0"
    comp_ini = os.path.join(prof_dir, "compatibility.ini") if prof_dir else ""
    if comp_ini and os.path.exists(comp_ini):
        try:
            with open(comp_ini, "r", encoding="utf-8") as f:
                text = f.read()
            m = re.search(r'LastVersion=(\d+\.\d+)', text)
            if m:
                ff_ver = m.group(1)
        except Exception:
            pass
    else:
        try:
            res = subprocess.run(["firefox", "--version"], capture_output=True, text=True, timeout=3)
            m = re.search(r'(\d+\.\d+)', res.stdout)
            if m:
                ff_ver = m.group(1)
        except Exception:
            pass

    return [
        f"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:{ff_ver}) Gecko/20100101 Firefox/{ff_ver}",
        f"Mozilla/5.0 (X11; Linux x86_64; rv:{ff_ver}) Gecko/20100101 Firefox/{ff_ver}",
    ]

def load_firefox_cookies():
    cookie_db = find_newest_firefox_cookies_db()
    cookies = {}
    prof_dir = None
    if cookie_db:
        prof_dir = os.path.dirname(cookie_db)
        tmp_dir = tempfile.mkdtemp()
        try:
            tmp_db = os.path.join(tmp_dir, "cookies.sqlite")
            shutil.copy2(cookie_db, tmp_db)
            for ext in ("-wal", "-shm"):
                if os.path.exists(cookie_db + ext):
                    shutil.copy2(cookie_db + ext, tmp_db + ext)
            conn = sqlite3.connect(tmp_db)
            cur = conn.cursor()
            cur.execute("SELECT name, value FROM moz_cookies WHERE host LIKE '%javdb.com%'")
            for name, val in cur.fetchall():
                if val:
                    cookies[name] = val
            conn.close()
        except Exception as e:
            print(f"[WARN] Failed reading Firefox cookies.sqlite: {e}")
        finally:
            shutil.rmtree(tmp_dir, ignore_errors=True)

    cookies["over18"] = "1"
    ua_list = detect_firefox_user_agent(prof_dir)
    return cookies, ua_list, prof_dir

ff_cookies, ff_uas, ff_prof_dir = load_firefox_cookies()

def fetch_javdb_html(path_and_query):
    url = f"https://javdb.com{path_and_query}"
    imp_targets = ["firefox135", "firefox133", "firefox"]
    last_status = None

    for ua in ff_uas:
        for imp in imp_targets:
            try:
                s = cffi_requests.Session(impersonate=imp)
            except Exception:
                continue
            for k, v in ff_cookies.items():
                s.cookies.set(k, v, domain="javdb.com")
            headers = {
                "User-Agent": ua,
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "ja,en-US;q=0.9,en;q=0.8,zh-TW;q=0.7",
                "Referer": "https://javdb.com/",
                "Upgrade-Insecure-Requests": "1",
                "Sec-Fetch-Dest": "document",
                "Sec-Fetch-Mode": "navigate",
                "Sec-Fetch-Site": "same-origin",
                "Sec-Fetch-User": "?1",
            }
            resp = s.get(url, headers=headers, timeout=10)
            last_status = resp.status_code
            if resp.status_code == 200:
                if "/login" in str(resp.url) or "請先登入" in resp.text or "Sign in" in resp.text:
                    raise PermissionError("JavDB requires user sign-in for uncensored content")
                if "movie-list" in resp.text or "current-title" in resp.text or "empty-message" in resp.text:
                    return resp.text

    raise RuntimeError(f"HTTP {last_status} from JavDB")

def fetch_uncensored_direct(file_vid, studio_hint=""):
    s = cffi_requests.Session(impersonate="firefox")
    underscore_id = file_vid.replace("-", "_")
    hyphen_id = file_vid.replace("_", "-")
    hint = (studio_hint or "").upper()

    # 1. Official JSON APIs (1Pondo, 10musume, Pacopacomama)
    json_apis = [
        ("1PON", f"https://www.1pondo.tv/dyn/phpauto/movie_details/movie_id/{underscore_id}.json"),
        ("10MU", f"https://www.10musume.com/dyn/phpauto/movie_details/movie_id/{underscore_id}.json"),
        ("PACO", f"https://www.pacopacomama.com/dyn/phpauto/movie_details/movie_id/{underscore_id}.json"),
    ]
    if hint:
        json_apis.sort(key=lambda x: 0 if hint.startswith(x[0]) else 1)

    if not hint.startswith("CARIB"):
        for st_code, api_url in json_apis:
            try:
                r = s.get(api_url, timeout=8)
                if r.status_code == 200:
                    data = r.json()
                    raw_title = (data.get("Title") or "").strip()
                    if raw_title:
                        actresses = data.get("ActressesJa") or []
                        year = str(data.get("Year") or "")
                        if not year and data.get("Release"):
                            m = re.search(r'(\d{4})', str(data["Release"]))
                            if m:
                                year = m.group(1)
                        print(f"  [OK] Fetched directly from official {st_code} JSON API")
                        return {
                            "raw_title": raw_title,
                            "all_actors": list(actresses),
                            "female_actresses": list(actresses),
                            "year": year or "Unknown",
                            "is_uncensored": True
                        }
            except Exception:
                pass

    # 2. Official Caribbeancom / Caribbeancompr HTML
    carib_sites = [
        ("CARIB", f"https://www.caribbeancom.com/moviepages/{hyphen_id}/index.html"),
        ("CARIBPR", f"https://www.caribbeancompr.com/moviepages/{underscore_id}/index.html"),
    ]
    for st_code, url in carib_sites:
        try:
            r = s.get(url, timeout=8)
            if r.status_code == 200:
                html_text = r.content.decode("euc-jp", errors="ignore")
                soup = BeautifulSoup(html_text, "html.parser")
                h1 = soup.select_one("div.heading h1[itemprop='name']") or soup.select_one("div.heading h1")
                if h1 and h1.text.strip():
                    raw_title = h1.text.strip()
                    actresses = []
                    for a in soup.select("li.movie-spec span.spec-content a[itemprop='actor'] span[itemprop='name']"):
                        if a.text.strip() and a.text.strip() not in actresses:
                            actresses.append(a.text.strip())
                    if not actresses:
                        for a in soup.select("a.spec__tag, span.spec-content a"):
                            if "/search_act/" in (a.get("href") or ""):
                                actresses.append(a.text.strip())
                    year = "Unknown"
                    date_el = soup.select_one("span[itemprop='uploadDate'], span[itemprop='datePublished']")
                    if date_el:
                        m = re.search(r'(\d{4})', date_el.text)
                        if m:
                            year = m.group(1)
                    if year == "Unknown":
                        m_date = re.match(r'^\d{4}(\d{2})[-_]', hyphen_id)
                        if m_date:
                            year = f"20{m_date.group(1)}"
                    print(f"  [OK] Fetched directly from official {st_code} page")
                    return {
                        "raw_title": raw_title,
                        "all_actors": list(actresses),
                        "female_actresses": list(actresses),
                        "year": year,
                        "is_uncensored": True
                    }
        except Exception:
            pass

    # 3. JavBus Uncensored Direct Lookup
    for q_id in [hyphen_id, underscore_id]:
        try:
            jb_url = f"https://www.javbus.com/{urllib.parse.quote(q_id)}"
            s.cookies.set("existmag", "all", domain="www.javbus.com")
            r = s.get(jb_url, headers={"Accept-Language": "ja,en-US;q=0.9", "Referer": "https://www.javbus.com/"}, timeout=10)
            if r.status_code == 200:
                soup = BeautifulSoup(r.text, "html.parser")
                h3 = soup.select_one(".container h3")
                if h3 and h3.text.strip():
                    raw_title = re.sub(rf'^{re.escape(q_id)}\s*', '', h3.text.strip(), flags=re.IGNORECASE)
                    actresses = [a.text.strip() for a in soup.select(".star-name a") if a.text.strip()]
                    year = "Unknown"
                    info = soup.select_one(".info")
                    if info:
                        m = re.search(r'(\d{4})-\d{2}-\d{2}', info.text)
                        if m:
                            year = m.group(1)
                    print("  [OK] Fetched from JavBus")
                    return {
                        "raw_title": raw_title,
                        "all_actors": list(actresses),
                        "female_actresses": list(actresses),
                        "year": year,
                        "is_uncensored": True
                    }
        except Exception:
            pass

    return None

FOUR_K_REGEX = re.compile(r'(?i)(?:^|(?<=[_\-\.\s\[\(【@]))(4k(?:s|60[a-z0-9]*)?|2160p)(?=$|[_\-\.\s\]\)】])')

def strip_4k_and_uncensored_tokens(text):
    cleaned = re.sub(r'(?i)(?:^|[_\-\.\s]+)(?:4k(?:s|60[a-z0-9]*)?|2160p|uncensored)(?=$|[_\-\.\s]+)', ' ', text)
    return cleaned.strip('._- ')

def extract_vid(filename):
    """
    Returns (file_vid, search_vid, studio_hint, is_uncensored)
    """
    stem = os.path.splitext(filename)[0]
    stem = re.sub(r'^.*@', '', stem)
    stem_clean = strip_4k_and_uncensored_tokens(stem)

    # A. FC2-PPV
    m_fc2 = re.search(r'(?i)FC2[_\-\s]*(?:PPV[_\-\s]*)?(\d{5,8})', stem_clean)
    if m_fc2:
        vid = f"FC2-PPV-{m_fc2.group(1)}"
        return vid, vid, "FC2", True

    # B. Uncensored date/number + optional studio suffix (e.g., 103126-001-1PON, 103126-001-CARIB, 103126-001)
    m_uncen_suffix = re.search(
        r'(\d{4,6})[_\-](\d{2,4})(?:[_\-](1PON(?:DO)?|10MU(?:SUME)?|CARIB(?:PR)?|PACO(?:PACOMAMA)?|[a-zA-Z]{2,7}))?\b',
        stem_clean,
        re.IGNORECASE
    )
    if m_uncen_suffix:
        p1, p2, studio = m_uncen_suffix.group(1), m_uncen_suffix.group(2), (m_uncen_suffix.group(3) or "").upper()
        base_id = f"{p1}-{p2}"
        if studio.startswith(("1PON", "10MU", "PACO")):
            return base_id, f"{p1}_{p2}", studio, True
        return base_id, base_id, studio, True

    # C. Uncensored studio prefix + date/number (e.g., 1pondo_103126_001)
    m_uncen_prefix = re.search(
        r'(?i)\b(1PON(?:DO)?|10MU(?:SUME)?|CARIB(?:PR)?|PACO(?:PACOMAMA)?)[_\-](\d{4,6})[_\-](\d{2,4})\b',
        stem_clean
    )
    if m_uncen_prefix:
        studio, p1, p2 = m_uncen_prefix.group(1).upper(), m_uncen_prefix.group(2), m_uncen_prefix.group(3)
        base_id = f"{p1}-{p2}"
        if studio.startswith(("1PON", "10MU", "PACO")):
            return base_id, f"{p1}_{p2}", studio, True
        return base_id, base_id, studio, True

    # D. Known Uncensored Alphanumeric Studios (HEYZO, S2MBD, TOKYO-HOT N-series)
    m_uncen_alpha = re.search(r'\b(HEYZO|S2MBD)-?(\d{3,5})\b', stem_clean, re.IGNORECASE)
    if m_uncen_alpha:
        vid = f"{m_uncen_alpha.group(1).upper()}-{m_uncen_alpha.group(2)}"
        return vid, vid, m_uncen_alpha.group(1).upper(), True

    # E. Standard Censored
    m_std = re.search(r'\b(T28|[a-zA-Z]{2,6})-?(\d{2,5})\b', stem_clean, re.IGNORECASE)
    if m_std:
        vid = f"{m_std.group(1).upper()}-{m_std.group(2)}"
        return vid, vid, "", False

    # F. Glued leading digits (e.g. 11NACT-203)
    m_glued = re.search(r'(?:^\d+)?([a-zA-Z]{2,6})-?(\d{2,5})', stem_clean)
    if m_glued:
        vid = f"{m_glued.group(1).upper()}-{m_glued.group(2)}"
        return vid, vid, "", False

    return None, None, "", False

def normalize_id_for_compare(s):
    return re.sub(r'[_\-\s]+', '-', s.strip().upper())

def is_already_expanded(filename, file_vid):
    stem, _ = os.path.splitext(filename)
    # Matches any of the Uncensored placements:
    #   "{VID} [Uncensored ]<title>.<YYYY>[.Uncensored][.4K]" or "Uncensored {VID} <title>.<YYYY>[.4K]"
    pattern = rf'^(?:Uncensored\s+)?{re.escape(file_vid)}\s+.+\.(?:\d{{4}}|Unknown)(?:\.Uncensored)?(?:\.4K)?(?:\.Uncensored)?$'
    return bool(re.match(pattern, stem, re.IGNORECASE))

def is_4k_video(filepath, filename, raw_title=""):
    stem = os.path.splitext(filename)[0]
    if FOUR_K_REGEX.search(stem):
        return True
    if raw_title and re.search(r'(?i)(?:【4k】|\[4k\]|\b4k\b|2160p)', raw_title):
        return True
    try:
        res = subprocess.run(
            ["ffprobe", "-v", "error", "-select_streams", "v:0",
             "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0", filepath],
            capture_output=True, text=True, timeout=5
        )
        if res.returncode == 0 and res.stdout.strip():
            dims = [int(x) for x in res.stdout.strip().split('x') if x.isdigit()]
            if dims and (max(dims) >= 3800 or min(dims) >= 2100):
                return True
    except Exception:
        pass
    return False

def expand_actor_names(actors):
    expanded = []
    for a in actors:
        expanded.append(a)
        for part in re.split(r'[（\(\[【）\)\]】]', a):
            part = part.strip()
            if part and part not in expanded:
                expanded.append(part)
    return sorted(expanded, key=len, reverse=True)

def clean_title(title, all_actors, custom_removals):
    cleaned = title
    for pat in custom_removals:
        cleaned = re.sub(pat, ' ', cleaned)

    for act in expand_actor_names(all_actors):
        esc = re.escape(act)
        cleaned = re.sub(rf'(?:[・、，,／/\s]|主演[：:]?|出演[：:]?|by\s+)*{esc}(?:[・、，,／/\s])*', ' ', cleaned)

    cleaned = re.sub(r'(\(\s*\)|\[\s*\]|（\s*）|【\s*】)', '', cleaned)
    cleaned = re.sub(r'[\\/:*?"<>|／＼]', ' ', cleaned)
    return re.sub(r'\s+', ' ', cleaned).strip()

def truncate_utf8_filename(prefix, title, suffix, max_bytes=255):
    fixed_bytes = len((prefix + suffix).encode('utf-8'))
    allowed_bytes = max_bytes - fixed_bytes
    encoded_title = title.encode('utf-8')
    if len(encoded_title) <= allowed_bytes:
        return prefix + title + suffix
    truncated_title = encoded_title[:allowed_bytes].decode('utf-8', errors='ignore').strip()
    return prefix + truncated_title + suffix

def fetch_from_javdb_full(file_vid, search_vid, is_uncensored=False):
    queries = [search_vid]
    if re.match(r'^\d{4,6}-\d{2,4}$', search_vid):
        queries.append(search_vid.replace('-', '_'))
    elif re.match(r'^\d{4,6}_\d{2,4}$', search_vid):
        queries.append(search_vid.replace('_', '-'))

    norm_target = normalize_id_for_compare(file_vid)
    target_href = None
    first_items = None

    for q in queries:
        search_path = f"/search?q={urllib.parse.quote(q)}&f=all"
        search_html = fetch_javdb_html(search_path)
        soup = BeautifulSoup(search_html, 'html.parser')
        items = soup.select('.movie-list .item a')
        if not items:
            continue
        if first_items is None:
            first_items = items
        for item in items:
            uid_el = item.select_one('.video-title strong')
            if uid_el and normalize_id_for_compare(uid_el.text) == norm_target:
                target_href = item.get('href')
                break
        if target_href:
            break

    if not target_href and first_items:
        target_href = first_items[0].get('href')
    if not target_href:
        return None

    detail_html = fetch_javdb_html(target_href)
    dsoup = BeautifulSoup(detail_html, 'html.parser')
    title_el = dsoup.select_one('.current-title')
    if not title_el:
        return None
    raw_title = title_el.text.strip()

    year = "Unknown"
    female_actresses = []
    male_actors = []
    all_actors = []

    for block in dsoup.select('.panel-block'):
        strong = block.select_one('strong')
        val_el = block.select_one('.value')
        if not strong or not val_el:
            continue
        label = strong.text.strip()

        if any(k in label for k in ['日期', 'Date', 'リリース']):
            ym = re.search(r'(\d{4})', val_el.text)
            if ym:
                year = ym.group(1)
        elif any(k in label for k in ['演員', 'Actor', '出演者']):
            raw_html = str(val_el)
            for match in re.finditer(r'<a[^>]*>([^<]+)</a>\s*(?:<strong[^>]*class="([^"]*)"[^>]*>([^<]*)</strong>)?', raw_html):
                name = match.group(1).strip()
                sym_class = (match.group(2) or "").lower()
                sym_text = (match.group(3) or "").strip()
                if not name:
                    continue
                all_actors.append(name)
                if 'female' in sym_class or '♀' in sym_text:
                    if name not in female_actresses:
                        female_actresses.append(name)
                elif 'male' in sym_class or '♂' in sym_text:
                    if name not in male_actors:
                        male_actors.append(name)

            if not female_actresses and all_actors:
                in_title = [a for a in all_actors if a not in male_actors and any(alias in raw_title for alias in expand_actor_names([a]))]
                female_actresses = in_title if in_title else [a for a in all_actors if a not in male_actors]

    return {
        "raw_title": raw_title,
        "all_actors": all_actors,
        "female_actresses": female_actresses,
        "year": year,
        "is_uncensored": is_uncensored
    }

for filepath in files:
    if not os.path.exists(filepath):
        continue
    dirname, filename = os.path.split(filepath)
    ext = os.path.splitext(filename)[1]
    file_vid, search_vid, studio_hint, is_uncensored = extract_vid(filename)
    if not file_vid:
        print(f"[SKIP] Could not extract Video ID from: {filename}")
        continue

    # --- TOGGLE MODE: Revert full name -> {video_id}[.Uncensored][.4K].mp4 ---
    if is_already_expanded(filename, file_vid):
        four_k_tag = ".4K" if is_4k_video(filepath, filename) else ""
        short_filename = f"{file_vid}{four_k_tag}{ext}"
        short_filepath = os.path.join(dirname, short_filename)
        if dry_run:
            print(f"  [DRY-RUN REVERT] {filename}\n                -> {short_filename}")
        else:
            os.rename(filepath, short_filepath)
            print(f"  [REVERTED] -> {short_filename}")
        continue

    # --- EXPAND MODE ---
    if not refresh_cache and file_vid in metadata_cache:
        cached = metadata_cache[file_vid]
        raw_title = cached["raw_title"]
        all_actors = cached["all_actors"]
        female_actresses = cached["female_actresses"]
        year = cached["year"]
        is_uncensored = cached.get("is_uncensored", is_uncensored)
        print(f"[CACHE HIT] Using cached metadata for {file_vid} (from {filename})")
    else:
        info = None
        if is_uncensored:
            print(f"[INFO] Uncensored ID '{file_vid}' detected (from {filename}) -> querying official studio APIs first...")
            info = fetch_uncensored_direct(file_vid, studio_hint)

        if not info:
            print(f"[INFO] Searching JavDB for '{search_vid}' -> ID '{file_vid}' (from {filename})...")
            try:
                info = fetch_from_javdb_full(file_vid, search_vid, is_uncensored=is_uncensored)
            except PermissionError as pe:
                print(f"  [INFO] {pe} -> falling back to zero-login uncensored sources...")
                info = fetch_uncensored_direct(file_vid, studio_hint)
            except Exception as e:
                print(f"[ERROR] Failed processing {file_vid}: {e}")
                continue

        if not info:
            print(f"[WARN] No results found for {file_vid}")
            continue

        raw_title = info["raw_title"]
        all_actors = info["all_actors"]
        female_actresses = info["female_actresses"]
        year = info["year"]
        is_uncensored = info.get("is_uncensored", is_uncensored)

        if dry_run:
            print(f"  [DEBUG] Actors found -> Female: {female_actresses}")

        metadata_cache[file_vid] = info
        save_cache()
        time.sleep(1.0)

    cleaned_title = clean_title(raw_title, all_actors, remove_patterns)
    clean_actresses = [re.sub(r'[\\/:*?"<>|／＼]', ' ', a).strip() for a in female_actresses]
    actress_str = f" {' '.join(clean_actresses)}" if clean_actresses else ""
    four_k_tag = ".4K" if is_4k_video(filepath, filename, raw_title) else ""

    # Format "Uncensored" tag placement based on UNCENSORED_POS
    if is_uncensored:
        if uncensored_pos == "prefix":
            prefix = f"Uncensored {file_vid} "
            uncen_suffix = ""
        elif uncensored_pos == "after_id":
            prefix = f"{file_vid} Uncensored "
            uncen_suffix = ""
        else:
            # Default "suffix": 103126-001 Title Actress.2026.Uncensored[.4K].mp4
            prefix = f"{file_vid} "
            uncen_suffix = ".Uncensored"
    else:
        prefix = f"{file_vid} "
        uncen_suffix = ""

    suffix = f"{actress_str}.{year}{uncen_suffix}{four_k_tag}{ext}"
    new_filename = truncate_utf8_filename(prefix, cleaned_title, suffix)
    new_filepath = os.path.join(dirname, new_filename)

    if dry_run:
        print(f"  [DRY-RUN] {filename}\n         -> {new_filename}")
    else:
        os.rename(filepath, new_filepath)
        print(f"  [RENAMED] -> {new_filename}")
EOF
