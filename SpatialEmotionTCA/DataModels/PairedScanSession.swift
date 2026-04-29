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
    
    // pointers: These just tell RealityKit where to look on the SSD
    var objURL: URL
    var faceURL: URL
    
    var emotion:String
    var emoji:String?
    
    
    init(id: UUID = UUID(), name: String, timestamp: Date = Date(), objURL: URL, faceURL: URL, emotion:String, emoji:String) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.objURL = objURL
        self.faceURL = faceURL
        self.emotion = emotion
        self.emoji = emoji
    }
}
