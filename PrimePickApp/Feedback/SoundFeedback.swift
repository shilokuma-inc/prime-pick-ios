//
//  SoundFeedback.swift
//  PrimePickApp
//

import AudioToolbox

/// アプリ内で鳴らす効果音の種類
///
/// 現状は独自の音源ファイルを持たず iOS のシステムサウンドで代替しているが、
/// 呼び出し側は「どの場面の音か」だけを指定する形にしてあるため、
/// 将来カスタム音源を追加する際は `systemSoundID` の実装を差し替えるだけで済む。
enum SoundEffect {
    case correct
    case incorrect

    /// 参照している ID は iOS 標準の UISounds に含まれる短い肯定音 / 否定音
    fileprivate var systemSoundID: SystemSoundID {
        switch self {
        case .correct:
            return 1054
        case .incorrect:
            return 1053
        }
    }
}

/// 効果音再生の薄いラッパー
enum SoundFeedback {
    /// 効果音を再生する
    ///
    /// `AudioServicesPlaySystemSound` は呼び出し後すぐに制御を返し、再生はシステム側で非同期に行われる。
    /// マナーモードや消音時は再生されないだけで、待たされたりクラッシュしたりはしないため、
    /// クイズの進行をブロックすることはない。
    static func play(_ effect: SoundEffect) {
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
