//
//  Scan.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import Foundation
import SwiftData

@Model
final class PairedScanSession {
    @Attribute(.unique) var id: UUID
    var name: String
    var timestamp: Date
    
    // The Librarian Pointers: These just tell RealityKit where to look on the SSD
    var scanOneURL: URL
    var scanTwoURL: URL
    
    var calculatedVolume: Double?
    
    init(id: UUID = UUID(), name: String, timestamp: Date = Date(), scanOneURL: URL, scanTwoURL: URL) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.scanOneURL = scanOneURL
        self.scanTwoURL = scanTwoURL
    }
}
