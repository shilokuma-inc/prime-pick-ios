#!/usr/bin/env python3
"""効果音の音源を合成して PrimePickApp/Sounds に書き出す。

外部の素材は使わず、正弦波の和と減衰エンベロープだけで作る（Discussion #156 で「生成した音源でよい」と決定）。
WAV を一時ファイルに書き、macOS 標準の afconvert で .caf（16bit リニア PCM）に変換する。

    python3 scripts/generate-sounds.py
"""

import math
import os
import struct
import subprocess
import tempfile
import wave

SAMPLE_RATE = 44_100
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "PrimePickApp", "Sounds")

# 正解音の音階（ハ長調 C5〜C6 の 8 音）。コンボが上がるほど高い音を鳴らす
CORRECT_SCALE_HZ = [523.25, 587.33, 659.25, 698.46, 783.99, 880.00, 987.77, 1046.50]


def tone(frequency, duration, decay, partials=((1, 1.0), (2, 0.3), (3, 0.1)), attack=0.005):
    """倍音を重ねた音を、立ち上がり attack 秒・時定数 decay 秒の指数減衰で鳴らしたサンプル列"""
    samples = []
    total = sum(weight for _, weight in partials)
    for index in range(int(SAMPLE_RATE * duration)):
        t = index / SAMPLE_RATE
        envelope = min(1.0, t / attack) * math.exp(-t / decay)
        value = sum(weight * math.sin(2 * math.pi * frequency * multiple * t) for multiple, weight in partials)
        samples.append(value / total * envelope)
    return samples


def write_caf(name, samples, volume=0.6):
    """サンプル列を <name>.caf として書き出す"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with tempfile.TemporaryDirectory() as directory:
        wav_path = os.path.join(directory, f"{name}.wav")
        with wave.open(wav_path, "wb") as file:
            file.setnchannels(1)
            file.setsampwidth(2)
            file.setframerate(SAMPLE_RATE)
            frames = b"".join(
                struct.pack("<h", int(max(-1.0, min(1.0, sample * volume)) * 32_767)) for sample in samples
            )
            file.writeframes(frames)
        caf_path = os.path.join(OUTPUT_DIR, f"{name}.caf")
        subprocess.run(["afconvert", "-f", "caff", "-d", "LEI16", wav_path, caf_path], check=True)
        print(f"wrote {os.path.relpath(caf_path)}")


def main():
    for index, frequency in enumerate(CORRECT_SCALE_HZ):
        write_caf(f"correct_{index}", tone(frequency, duration=0.25, decay=0.08))


if __name__ == "__main__":
    main()
