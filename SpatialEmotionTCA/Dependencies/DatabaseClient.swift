//
//  DatabaseClient.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 4/4/26.
//

import ComposableArchitecture
import Foundation
import SwiftData


struct DatabaseClient:Sendable {
    //added asynchrony, may cause issues 
    var saveSession: @Sendable (_ scanID:UUID, _ objURL: URL, _ faceURL: URL,_ emotion:String) async throws -> Void
    var deleteSession: @Sendable(_ scanId:UUID, _ objURL: URL, _ faceURL: URL) async throws -> Void
    var fetchAllSessions: @Sendable() throws -> [PairedScan]
}

//potentially need modelactor?
extension DatabaseClient: DependencyKey {
    static let liveValue = Self(
        saveSession: {scanId, objURL, faceURL, emotion in //save from camera feature
            //Connect to the existing SQLite database file
            let container = try ModelContainer(for: PairedScanSession.self)
            // Create a fresh context for this specific background task
            let context = ModelContext(container)
            let emoji = EmotionClassification().emotionToEmoji(emotion)
            
            // Initialize data model
            let now = Date.now
            let session = PairedScanSession(
                id:scanId,
                name: "Scan \(Date().formatted(date: .abbreviated, time: .shortened))",
                objFilename: objURL.lastPathComponent,
                faceFilename: faceURL.lastPathComponent,
                emotion:emotion,
                emoji:emoji
            )
            context.insert(session)
            try context.save()
        },
        deleteSession: {scanId, objUrl, faceUrl in //delete from scan review
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: objUrl)
            } catch{
                print("Failed to remove object scan file from system \(error)")
            }
            do {
                try fileManager.removeItem(at: faceUrl)
            } catch{
                print("Failed to remove face scan file from system \(error)")
            }
            //Connect to SwiftData
            let container = try ModelContainer(for: PairedScanSession.self)

            let context = ModelContext(container)
           // Find the specific record and delete it
            do {
                let descriptor = FetchDescriptor<PairedScanSession>(predicate: #Predicate { $0.id == scanId })
                if let sessionToDelete = try context.fetch(descriptor).first {
                    context.delete(sessionToDelete)
                    try context.save()
                }
            } catch {
                print("Failed to remove from SwiftData \(error)")
            }
        },
        fetchAllSessions: { //get all for scan history
            let container = try ModelContainer(for: PairedScanSession.self)
            let context = ModelContext(container)
            // Fetch all sessions, sorted by date (newest first)
            var descriptor = FetchDescriptor<PairedScanSession>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            let scans = try context.fetch(descriptor)
            //make value type so i can give to main thread
            let valueScans = scans.map {
                PairedScan(id: $0.id, name: $0.name, timestamp: $0.timestamp, objURL: $0.objURL, faceURL: $0.faceURL, emotion: $0.emotion, emoji: $0.emoji ?? "❓")
            }
            return valueScans
        }
    )
}
extension DependencyValues {
    var databaseClient: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}
