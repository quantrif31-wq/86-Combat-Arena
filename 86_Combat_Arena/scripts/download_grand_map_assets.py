import os
import sys
import json
import urllib.request
import time

TARGET_BASE = r"c:\86\86_Combat_Arena\assets\environment\models"

ASSETS = [
    "modular_factory_facade",
    "modular_chainlink_fence",
    "modular_pipes",
    "modular_wooden_pier",
    "boulder_01",
    "rock_face_01",
    "ammo_box",
    "concrete_road_barrier_02"
]

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

def download_file(url, out_path):
    if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
        print(f"  [Exists] {os.path.basename(out_path)} ({os.path.getsize(out_path):,} bytes)")
        return
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    req = urllib.request.Request(url, headers=HEADERS)
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp, open(out_path, 'wb') as f:
                f.write(resp.read())
            print(f"  [Downloaded] {os.path.basename(out_path)} ({os.path.getsize(out_path):,} bytes)")
            return
        except Exception as e:
            print(f"  [Retry {attempt+1}] {url} - error: {e}")
            time.sleep(2)
    raise RuntimeError(f"Failed to download {url}")

def download_asset(asset_id):
    print(f"\n==========================================")
    print(f"Fetching manifest for: {asset_id}")
    print(f"==========================================")
    asset_dir = os.path.join(TARGET_BASE, asset_id)
    os.makedirs(asset_dir, exist_ok=True)
    
    api_url = f"https://api.polyhaven.com/files/{asset_id}"
    req = urllib.request.Request(api_url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=20) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        
    gltf_info = data.get('gltf', {}).get('1k', {}).get('gltf', {})
    if not gltf_info:
        # Fallback to any available resolution if 1k not present
        res_keys = list(data.get('gltf', {}).keys())
        if not res_keys:
            raise RuntimeError(f"No GLTF found for {asset_id}")
        chosen_res = res_keys[0]
        gltf_info = data['gltf'][chosen_res]['gltf']
        
    main_url = gltf_info['url']
    main_filename = os.path.basename(main_url)
    main_path = os.path.join(asset_dir, main_filename)
    download_file(main_url, main_path)
    
    includes = gltf_info.get('include', {})
    for rel_path, file_data in includes.items():
        file_url = file_data['url']
        local_target = os.path.join(asset_dir, rel_path.replace('/', os.sep))
        download_file(file_url, local_target)
        
    print(f"-> Successfully downloaded asset: {asset_id}")

if __name__ == "__main__":
    print(f"Starting batch download of {len(ASSETS)} grand warzone assets...")
    for aid in ASSETS:
        try:
            download_asset(aid)
        except Exception as err:
            print(f"ERROR downloading {aid}: {err}")
    print("\nAll grand warzone assets processed successfully!")
