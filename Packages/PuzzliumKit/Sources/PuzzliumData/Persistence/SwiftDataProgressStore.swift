import Foundation
import PuzzliumDomain
import SwiftData

/// Background SwiftData store. Only Sendable domain values cross its boundary.
public actor SwiftDataProgressStore: ModelActor, ProgressRepository {
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    public func progress(for puzzleID: String) throws -> PuzzleProgress? {
        try record(for: puzzleID)?.domain
    }

    public func allProgress() throws -> [PuzzleProgress] {
        let descriptor = FetchDescriptor<ProgressRecord>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map(\.domain)
    }

    public func save(_ progress: PuzzleProgress) throws {
        if let existing = try record(for: progress.puzzleID) {
            existing.update(from: progress)
        } else {
            modelContext.insert(ProgressRecord(progress))
        }
        try modelContext.save()
    }

    public func recordCompletion(_ completion: PuzzleCompletion) throws {
        modelContext.insert(CompletionRecord(completion))
        try modelContext.save()
    }

    public func completionDates() throws -> [Date] {
        try modelContext.fetch(FetchDescriptor<CompletionRecord>()).map(\.date)
    }

    private func record(for puzzleID: String) throws -> ProgressRecord? {
        var descriptor = FetchDescriptor<ProgressRecord>(predicate: #Predicate { $0.puzzleID == puzzleID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
