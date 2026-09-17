import wave
import math
import struct
import os
import random

SAMPLE_RATE = 44100

def clamp(v, min_v=-1.0, max_v=1.0):
    return max(min_v, min(max_v, v))

def write_wav_stereo(filepath, left_samples, right_samples):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    n_frames = min(len(left_samples), len(right_samples))
    with wave.open(filepath, 'w') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for i in range(n_frames):
            l = int(clamp(left_samples[i]) * 32767)
            r = int(clamp(right_samples[i]) * 32767)
            frames.extend(struct.pack('<hh', l, r))
        w.writeframes(frames)
    print(f"Generated {filepath} ({n_frames/SAMPLE_RATE:.2f}s)")

# 1. Tree Snap / Timber Splinter (0.75s)
def generate_tree_snap(filepath):
    duration = 0.85
    n_samples = int(SAMPLE_RATE * duration)
    left = [0.0] * n_samples
    right = [0.0] * n_samples
    random.seed(42)
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Multiple splinter cracks
        crack = 0.0
        # Main explosive snap at t=0
        if t < 0.25:
            env1 = math.exp(-t * 22.0)
            noise1 = (random.random() * 2.0 - 1.0)
            snap1 = math.sin(2 * math.pi * (180.0 + random.random() * 120.0) * t)
            crack += (noise1 * 0.7 + snap1 * 0.5) * env1
            
        # Secondary splinter groans between 0.08 and 0.55
        if t > 0.06:
            t2 = t - 0.06
            env2 = math.exp(-t2 * 12.0) * math.sin(t2 * 18.0)
            groan = math.sin(2 * math.pi * 95.0 * t2) + math.sin(2 * math.pi * 145.0 * t2) * 0.5
            splinters = (random.random() * 2.0 - 1.0) * math.exp(-t2 * 8.0) * 0.6
            crack += (groan * 0.4 + splinters * 0.5) * max(0.0, env2)
            
        # Low frequency fiber tear
        fiber = math.sin(2 * math.pi * 60.0 * t) * math.exp(-t * 6.0) * 0.45
        val = (crack + fiber) * 0.85
        left[i] = val
        # Slight stereo spread
        right[i] = val * 0.9 + (random.random() * 0.1 - 0.05)
        
    write_wav_stereo(filepath, left, right)

# 2. Tree Fall Ground Impact Crash (1.6s)
def generate_tree_fall_impact(filepath):
    duration = 1.6
    n_samples = int(SAMPLE_RATE * duration)
    left = [0.0] * n_samples
    right = [0.0] * n_samples
    random.seed(86)
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Heavy ground thud
        env_thud = math.exp(-t * 9.0)
        thud = (
            math.sin(2 * math.pi * 48.0 * t) * 0.6 +
            math.sin(2 * math.pi * 75.0 * t) * 0.35 +
            math.sin(2 * math.pi * 110.0 * t) * 0.2
        ) * env_thud
        
        # Crashing branches & rustling pine needles (broadband filtered noise)
        env_brush = (t / 0.05 if t < 0.05 else math.exp(-(t - 0.05) * 4.5))
        brush = (random.random() * 2.0 - 1.0) * env_brush * 0.55
        
        # Secondary bounce thud at 0.28s
        thud2 = 0.0
        if t > 0.28:
            t_b = t - 0.28
            thud2 = math.sin(2 * math.pi * 55.0 * t_b) * math.exp(-t_b * 14.0) * 0.38
            
        val = (thud + brush + thud2) * 0.9
        left[i] = val
        right[i] = val * 0.95 + (random.random() * 0.08 - 0.04)
        
    write_wav_stereo(filepath, left, right)

# 3. Concrete Road Barrier Shatter (0.9s)
def generate_concrete_shatter(filepath):
    duration = 0.9
    n_samples = int(SAMPLE_RATE * duration)
    left = [0.0] * n_samples
    right = [0.0] * n_samples
    random.seed(123)
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 16.0)
        # Low frequency rubble thump + high frequency stone crack
        thump = math.sin(2 * math.pi * 85.0 * t) * 0.6 * env
        crack = math.sin(2 * math.pi * 1450.0 * t) * math.exp(-t * 35.0) * 0.5
        gravel = (random.random() * 2.0 - 1.0) * math.exp(-t * 9.0) * 0.6
        val = (thump + crack + gravel) * 0.75
        left[i] = val
        right[i] = val
        
    write_wav_stereo(filepath, left, right)

# 4. Ammo Box Secondary Detonation (1.4s)
def generate_ammo_detonation(filepath):
    duration = 1.4
    n_samples = int(SAMPLE_RATE * duration)
    left = [0.0] * n_samples
    right = [0.0] * n_samples
    random.seed(999)
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Explosive blast
        env_blast = math.exp(-t * 8.0)
        blast = (
            math.sin(2 * math.pi * 55.0 * t) * 0.55 +
            math.sin(2 * math.pi * 125.0 * t) * 0.4 +
            (random.random() * 2.0 - 1.0) * 0.5
        ) * env_blast
        
        # Multiple secondary round crackles (bullets cooking off)
        cookoff = 0.0
        for crackle_t in [0.08, 0.16, 0.24, 0.38, 0.52]:
            if t > crackle_t:
                dt = t - crackle_t
                c_env = math.exp(-dt * 45.0)
                cookoff += (math.sin(2 * math.pi * 2800.0 * dt) + (random.random() * 2.0 - 1.0)) * c_env * 0.3
                
        val = (blast + cookoff) * 0.82
        left[i] = val
        right[i] = val
        
    write_wav_stereo(filepath, left, right)

if __name__ == "__main__":
    out_dir = r"c:\86\86_Combat_Arena\assets\audio"
    generate_tree_snap(os.path.join(out_dir, "tree_snap.wav"))
    generate_tree_fall_impact(os.path.join(out_dir, "tree_fall_impact.wav"))
    generate_concrete_shatter(os.path.join(out_dir, "concrete_shatter.wav"))
    generate_ammo_detonation(os.path.join(out_dir, "ammo_detonation.wav"))
    print("ALL DESTRUCTION AUDIO ASSETS SYNTHESIZED SUCCESSFULLY!")
