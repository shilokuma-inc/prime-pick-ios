//
//  SoundFeedback.swift
//  PrimePickApp
//

import AudioToolbox
import AVFoundation

/// アプリ内で鳴らす効果音の種類
///
/// 呼び出し側は「どの場面の音か」だけを指定し、どの音源を鳴らすかはここで決める。
/// 音源は `scripts/generate-sounds.py` で生成したもの（`Sounds/*.caf`）を使う。
/// 正解音は音階 8 音（`correct_0〜7`）をコンボに応じて鳴らし分ける。
/// 誤答音は独自の音源が無いため、iOS のシステムサウンドで代替している。
enum SoundEffect: Equatable {
    /// 正解。`combo` はこの解答を反映した後の連続正解数
    case correct(combo: Int)
    case incorrect
    /// コンボ段階が上がった。MAX はジングル。通常段階では鳴らさない
    case comboStageUp(ComboStage)
    /// コンボが切れた（下降音）
    case comboBreak
    /// 残り 5 秒の 1 秒ごとのチック
    case countdownTick
    /// タイムアップのホイッスル
    case timeUp

    /// 正解音の音階の数
    static let correctNoteCount = 8

    /// 正解音で鳴らす音階の番号（0 が最も低い）
    ///
    /// 通常段階（1〜2 コンボ）は最低音、Good から 1 コンボごとに 1 段ずつ上げ、Great の途中で最高音の手前に張り付く。
    /// 最高音は MAX に到達したときのために取っておく。
    static func correctNoteIndex(combo: Int) -> Int {
        if combo >= ComboStage.maxMinimumCombo {
            return correctNoteCount - 1
        }
        let raised = combo - (ComboStage.goodMinimumCombo - 1)
        return min(max(raised, 0), correctNoteCount - 2)
    }

    /// バンドルに含めた音源の名前（拡張子なし）。システムサウンドで鳴らす場合は nil
    var resourceName: String? {
        switch self {
        case .correct(let combo):
            return "correct_\(Self.correctNoteIndex(combo: combo))"
        case .incorrect:
            return nil
        case .comboStageUp(let stage):
            switch stage {
            case .normal:
                return nil
            case .good:
                return "stage_good"
            case .great:
                return "stage_great"
            case .max:
                return "stage_max"
            }
        case .comboBreak:
            return "combo_break"
        case .countdownTick:
            return "countdown_tick"
        case .timeUp:
            return "time_up"
        }
    }

    /// 参照している ID は iOS 標準の UISounds に含まれる短い否定音
    fileprivate var systemSoundID: SystemSoundID? {
        switch self {
        case .incorrect:
            return 1053
        case .correct, .comboStageUp, .comboBreak, .countdownTick, .timeUp:
            return nil
        }
    }
}

/// 効果音再生の薄いラッパー
enum SoundFeedback {
    /// 音源の拡張子
    static let resourceExtension = "caf"

    /// 効果音を再生する
    ///
    /// どちらの再生方法も呼び出し後すぐに制御を返し、再生は非同期に行われるため、クイズの進行をブロックしない。
    /// `AVAudioSession` を `.ambient` にしているので、マナーモードでは鳴らず、他のアプリの音楽も止めない。
    @MainActor
    static func play(_ effect: SoundEffect) {
        if let resourceName = effect.resourceName {
            BundledSoundPlayer.shared.play(resourceName)
        } else if let systemSoundID = effect.systemSoundID {
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }
}

/// バンドル内の音源を鳴らす
///
/// 解答のたびにファイルを読み込むと鳴り始めが遅れるため、一度読み込んだプレイヤーを使い回す。
/// 解答はメインスレッドからしか来ないので、メインアクターに閉じ込めている。
@MainActor
private final class BundledSoundPlayer {
    static let shared = BundledSoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]
    private var isSessionConfigured = false

    func play(_ resourceName: String) {
        configureSessionIfNeeded()
        guard let player = player(for: resourceName) else { return }
        // 連続で正解したときも頭から鳴らし直す
        player.currentTime = 0
        player.play()
    }

    private func player(for resourceName: String) -> AVAudioPlayer? {
        if let cached = players[resourceName] { return cached }
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: SoundFeedback.resourceExtension),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return nil }
        player.prepareToPlay()
        players[resourceName] = player
        return player
    }

    /// マナーモードでは鳴らさず、他のアプリの音楽を止めない `.ambient` にする。
    /// 失敗しても音が鳴らないだけでクイズは続けられるため、エラーは無視する。
    private func configureSessionIfNeeded() {
        guard !isSessionConfigured else { return }
        isSessionConfigured = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
    }
}
