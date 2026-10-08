//
//  TimeAttackRecordStore.swift
//  PrimePickApp
//

import SwiftData
import SwiftUI

/// タイムアタックの 1 プレイの記録の保存先（Discussion #223 Q4）
///
/// 画面やプレイの終わりの処理はこの protocol を通して記録に触り、保存方式（SwiftData）を知らない。
/// 練習・デイリーは記録しない（Q5）。記録は端末の中だけに保存する。
protocol TimeAttackRecordStore {
    /// 区分（制限時間 × 難易度）の記録。古い順
    func records(gameMode: GameMode, difficulty: Difficulty) -> [TimeAttackPlayRecord]
    /// すべての記録。古い順
    func allRecords() -> [TimeAttackPlayRecord]
    /// 記録を 1 件足す
    func save(_ record: TimeAttackPlayRecord)
    /// すべての記録を消す
    func deleteAll()
}

/// SwiftData に保存する `TimeAttackRecordStore`
///
/// 操作ごとに `ModelContext` を作って保存まで終える。呼び出し側がスレッドやコンテキストの寿命を気にしなくてよいようにするため。
/// 保存・読み込みに失敗しても、記録が残らない（空として扱う）だけにして、プレイや画面は止めない。
struct SwiftDataTimeAttackRecordStore: TimeAttackRecordStore {
    /// 保存ファイルの名前
    static let configurationName = "TimeAttackRecords"

    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// 端末に保存するコンテナを作る。`inMemory` が true なら端末に書かない（テスト・撮影モード用）
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            configurationName,
            schema: Schema([StoredTimeAttackPlay.self]),
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: StoredTimeAttackPlay.self, configurations: configuration)
    }

    /// 端末に書かないストア。テスト・撮影モード・プレビューで使う
    static func inMemory() -> SwiftDataTimeAttackRecordStore {
        // メモリ上のコンテナはファイルを開かないので、作れないのはスキーマの誤りだけ
        SwiftDataTimeAttackRecordStore(modelContainer: try! makeContainer(inMemory: true))
    }

    /// アプリで使うストア。端末のファイルを開けなければメモリ上に切り替え、起動を止めない
    static func makeDefault(inMemory: Bool) -> SwiftDataTimeAttackRecordStore {
        guard !inMemory, let container = try? makeContainer() else { return .inMemory() }
        return SwiftDataTimeAttackRecordStore(modelContainer: container)
    }

    func records(gameMode: GameMode, difficulty: Difficulty) -> [TimeAttackPlayRecord] {
        let gameModeID = gameMode.id
        let difficultyValue = difficulty.rawValue
        return fetch(FetchDescriptor<StoredTimeAttackPlay>(
            predicate: #Predicate { $0.gameModeID == gameModeID && $0.difficulty == difficultyValue },
            sortBy: [SortDescriptor(\.playedAt)]
        ))
    }

    func allRecords() -> [TimeAttackPlayRecord] {
        fetch(FetchDescriptor<StoredTimeAttackPlay>(sortBy: [SortDescriptor(\.playedAt)]))
    }

    func save(_ record: TimeAttackPlayRecord) {
        let context = ModelContext(modelContainer)
        context.insert(StoredTimeAttackPlay(record))
        try? context.save()
    }

    func deleteAll() {
        let context = ModelContext(modelContainer)
        try? context.delete(model: StoredTimeAttackPlay.self)
        try? context.save()
    }

    private func fetch(_ descriptor: FetchDescriptor<StoredTimeAttackPlay>) -> [TimeAttackPlayRecord] {
        let context = ModelContext(modelContainer)
        let stored = (try? context.fetch(descriptor)) ?? []
        return stored.compactMap(\.record)
    }
}

private struct TimeAttackRecordStoreKey: EnvironmentKey {
    /// 注入されていない画面（プレビューなど）は端末に書かない
    static let defaultValue: any TimeAttackRecordStore = SwiftDataTimeAttackRecordStore.inMemory()
}

extension EnvironmentValues {
    /// タイムアタックの記録の保存先。`PrimePickApp` で端末に保存するものを注入する
    var timeAttackRecordStore: any TimeAttackRecordStore {
        get { self[TimeAttackRecordStoreKey.self] }
        set { self[TimeAttackRecordStoreKey.self] = newValue }
    }
}
