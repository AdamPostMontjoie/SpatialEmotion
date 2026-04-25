//
//  Emotions.swift
//  SpatialEmotion
//
//  Created by Adam Post-Montjoie on 4/25/26.
//

import ARKit

protocol Emotion {
    // The range between 0-1 where the emotion is considered active or not
    var name:String {get}
    var threshold:Double {get}
    // Calculated from the the blendshapes to see if that face has the given emotion
    func confidenceScore(for face: ARFaceAnchor) -> Double
}

extension Emotion {
    // Set default threshold to 0.3, can be overriden by class to change value.
    var threshold:Double{
        return 0.3
    }
}

struct NeutralEmotion: Emotion {
    var name:String
    init(){
        name = "Neutral"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let leftSmile = face.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
        let rightSmile = face.blendShapes[.mouthSmileRight]?.doubleValue ?? 0.0
        
        let averageSmile = (leftSmile + rightSmile) / 2.0
        
        // Invert the score: closer to 0 smile means closer to 1 neutral
        return 1.0 - averageSmile
    }
}

struct HappyEmotion: Emotion {
    var name:String
    init(){
        name = "Happy"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let left = face.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
        let right = face.blendShapes[.mouthSmileRight]?.doubleValue ?? 0.0
        return (left + right) / 2.0
    }
}

struct SadEmotion: Emotion {
    var name:String
    init(){
        name = "Sad"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let left = face.blendShapes[.mouthFrownLeft]?.doubleValue ?? 0.0
        let right = face.blendShapes[.mouthFrownRight]?.doubleValue ?? 0.0
        return (right + left) / 2.0
    }
}

struct AngryEmotion: Emotion {
    var name:String
    init(){
        name = "Angry"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let left = face.blendShapes[.browDownLeft]?.doubleValue ?? 0.0
        let right = face.blendShapes[.browDownRight]?.doubleValue ?? 0.0
        return (left + right) / 2.0
    }
}

struct SpeedEmotion: Emotion {
    var name:String
    init(){
        name = "IShowSpeed"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let pucker = face.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
        let squintLeft = face.blendShapes[.eyeSquintLeft]?.doubleValue ?? 0.0
        let squintRight = face.blendShapes[.eyeSquintRight]?.doubleValue ?? 0.0
        return (pucker + squintLeft + squintRight) / 3.0
    }
}

class EmotionClassification {
    func detectEmotion(face:ARFaceAnchor) -> String {
        let emotions:[Emotion] = [NeutralEmotion(), HappyEmotion(), SadEmotion(), AngryEmotion(), SpeedEmotion()]
        let validEmotions = emotions.map{e in
            (name:e.name, score:e.confidenceScore(for: face), threshold:e.threshold)
        }.filter{
            $0.score > $0.threshold
        }
        guard let emotionName = validEmotions.max(by:{$0.score < $1.score})?.name  else {
            return "Unknown"
        }
        return emotionName
    }
}
