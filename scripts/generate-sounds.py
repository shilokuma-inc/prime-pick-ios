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


def glide(start_hz, end_hz, duration, decay):
    """start_hz から end_hz へ音程を滑らかに下げ（上げ）ながら減衰する音"""
    samples = []
    phase = 0.0
    count = int(SAMPLE_RATE * duration)
    for index in range(count):
        t = index / SAMPLE_RATE
        # 周波数を指数的に動かすと、耳には一定の速さで音程が変わって聞こえる
        frequency = start_hz * (end_hz / start_hz) ** (index / count)
        phase += 2 * math.pi * frequency / SAMPLE_RATE
        envelope = min(1.0, t / 0.005) * math.exp(-t / decay)
        samples.append((math.sin(phase) + 0.3 * math.sin(2 * phase)) / 1.3 * envelope)
    return samples


def whistle(frequency, duration, vibrato_hz=28, vibrato_depth=0.03):
    """細かく揺れる高音。ホイッスルの代わりに使う。立ち上がりと終わりは短くフェードする"""
    samples = []
    phase = 0.0
    count = int(SAMPLE_RATE * duration)
    fade = 0.02
    for index in range(count):
        t = index / SAMPLE_RATE
        current = frequency * (1 + vibrato_depth * math.sin(2 * math.pi * vibrato_hz * t))
        phase += 2 * math.pi * current / SAMPLE_RATE
        envelope = min(1.0, t / fade, (duration - t) / fade)
        samples.append(math.sin(phase) * envelope)
    return samples


def sequence(*parts, gap=0.0):
    """複数の音を順に並べる。gap 秒の無音をはさむ"""
    samples = []
    for part in parts:
        samples.extend(part)
        samples.extend([0.0] * int(SAMPLE_RATE * gap))
    return samples


def overlap(parts_with_offsets):
    """(開始秒, サンプル列) の組を重ねて 1 つにする。和音やアルペジオの余韻に使う"""
    length = max(int(offset * SAMPLE_RATE) + len(part) for offset, part in parts_with_offsets)
    samples = [0.0] * length
    for offset, part in parts_with_offsets:
        start = int(offset * SAMPLE_RATE)
        for index, value in enumerate(part):
            samples[start + index] += value
    peak = max(abs(value) for value in samples) or 1.0
    return [value / peak for value in samples]


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

    # コンボ段階到達。段階が上がるほど音を増やし、MAX は和音で締めるジングルにする
    g5, c6, e6, g6, c7 = 783.99, 1046.50, 1318.51, 1567.98, 2093.00
    write_caf("stage_good", overlap([(0.0, tone(g5, 0.3, 0.1)), (0.08, tone(c6, 0.35, 0.12))]), volume=0.5)
    write_caf(
        "stage_great",
        overlap([(0.0, tone(c6, 0.3, 0.1)), (0.07, tone(e6, 0.3, 0.1)), (0.14, tone(g6, 0.4, 0.14))]),
        volume=0.5,
    )
    write_caf(
        "stage_max",
        overlap([
            (0.0, tone(c6, 0.3, 0.1)),
            (0.08, tone(e6, 0.3, 0.1)),
            (0.16, tone(g6, 0.3, 0.1)),
            (0.26, tone(c7, 0.8, 0.3)),
            (0.26, tone(g6, 0.8, 0.3)),
            (0.26, tone(e6, 0.8, 0.3)),
        ]),
        volume=0.5,
    )

    # 残り 5 秒のチック。解答の音を邪魔しないよう短く小さくする
    write_caf("countdown_tick", tone(1760.0, duration=0.06, decay=0.015, partials=((1, 1.0),)), volume=0.4)

    # タイムアップのホイッスル（短く 2 回）
    write_caf("time_up", sequence(whistle(2350.0, 0.18), whistle(2350.0, 0.45), gap=0.06), volume=0.45)

    # コンボ切れの下降音
    write_caf("combo_break", glide(620.0, 180.0, duration=0.4, decay=0.18), volume=0.55)


if __name__ == "__main__":
    main()
