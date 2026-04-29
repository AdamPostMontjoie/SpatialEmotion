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
        name = "neutrality"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        //penalized emotions
        let leftSmile = face.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
        let rightSmile = face.blendShapes[.mouthSmileRight]?.doubleValue ?? 0.0
        let browDown = face.blendShapes[.browDownLeft]?.doubleValue ?? 0.0
        let pucker = face.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
        let tongue = face.blendShapes[.tongueOut]?.doubleValue ?? 0.0
        
        let mostExpressive = max(leftSmile, rightSmile, browDown, pucker, tongue)
        
        let leftEye = face.blendShapes[.eyeWideLeft]?.doubleValue ?? 0.0
        let rightEye = face.blendShapes[.eyeWideRight]?.doubleValue ?? 0.0
        let openJaw = face.blendShapes[.jawOpen]?.doubleValue ?? 0.0
        
        let suprise = rightEye + leftEye + openJaw
        
        return 1.0 - (mostExpressive + suprise)
    }
}

struct SuprisedEmotion: Emotion {
    var name:String
    init(){
        name = "suprise"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let leftEye = face.blendShapes[.eyeWideLeft]?.doubleValue ?? 0.0
        let rightEye = face.blendShapes[.eyeWideRight]?.doubleValue ?? 0.0
        let openJaw = face.blendShapes[.jawOpen]?.doubleValue ?? 0.0
   
        let expression = (leftEye + rightEye + openJaw) / 3.0
        
        return expression
    }
}

struct HappyEmotion: Emotion {
    var name:String
    init(){
        name = "happiness"
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
        name = "sadness"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let shrugLower = face.blendShapes[.mouthShrugLower]?.doubleValue ?? 0.0
        
        let pressLeft = face.blendShapes[.mouthPressLeft]?.doubleValue ?? 0.0
        let pressRight = face.blendShapes[.mouthPressRight]?.doubleValue ?? 0.0
        let pressAvg = (pressLeft + pressRight) / 2.0
        
        let browLeft = face.blendShapes[.browDownLeft]?.doubleValue ?? 0.0
        let browRight = face.blendShapes[.browDownRight]?.doubleValue ?? 0.0
        let browAvg = (browLeft + browRight) / 2.0
        
        return (shrugLower + pressAvg + browAvg) / 3.0
    }
}

struct AngryEmotion: Emotion {
    var name:String
    init(){
        name = "anger"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let left = face.blendShapes[.browDownLeft]?.doubleValue ?? 0.0
        let right = face.blendShapes[.browDownRight]?.doubleValue ?? 0.0
        let pucker = face.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
        return ((left + right) / 2.0 ) - (pucker * 0.4)
    }
}

struct SpeedEmotion: Emotion {
    var name:String
    init(){
        name = "IShowSpeed"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let pucker = face.blendShapes[.mouthPucker]?.doubleValue ?? 0.0
        let blinkLeft = face.blendShapes[.eyeBlinkLeft]?.doubleValue ?? 0.0
        let blinkRight = face.blendShapes[.eyeBlinkRight]?.doubleValue ?? 0.0
        let blinkAvg = (blinkLeft + blinkRight) / 2.0

        let browLeft = face.blendShapes[.browDownLeft]?.doubleValue ?? 0.0
        let browRight = face.blendShapes[.browDownRight]?.doubleValue ?? 0.0
        let browAvg = (browLeft + browRight) / 2.0
        let baseSpeed = (pucker + blinkAvg + browAvg) / 3.0
         
        //stop pouting so we can make it different from sadness
        let pout = face.blendShapes[.mouthShrugLower]?.doubleValue ?? 0.0
        let adjustedSpeed = baseSpeed - (pout * 0.3)
                
        return max(0.0, adjustedSpeed)
        
    }
}
struct ConfidenceEmotion: Emotion {
    var name: String
    init(){
        name = "confidence"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let leftSmile = face.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
        let rightSmile = face.blendShapes[.mouthSmileRight]?.doubleValue ?? 0.0
        
        let leftFrown = face.blendShapes[.mouthFrownLeft]?.doubleValue ?? 0.0
        let rightFrown = face.blendShapes[.mouthFrownRight]?.doubleValue ?? 0.0
        
        let leftSmirk = leftSmile - rightSmile - rightFrown
        let rightSmirk = rightSmile - leftSmile - leftFrown
        
        let maxAsymmetry = max(leftSmirk, rightSmirk)
        
        let squintLeft = face.blendShapes[.eyeSquintLeft]?.doubleValue ?? 0.0
        let squintRight = face.blendShapes[.eyeSquintRight]?.doubleValue ?? 0.0
        let squintAvg = (squintLeft + squintRight) / 2.0
        
        return max(0.0, (maxAsymmetry * 0.8) + (squintAvg * 0.2))
    }
}

struct SillinessEmotion: Emotion {
    var name: String
    init(){
        name = "silliness"
    }
    func confidenceScore(for face: ARFaceAnchor) -> Double {
        let tongue = face.blendShapes[.tongueOut]?.doubleValue ?? 0.0
        
        // Adding a slight bonus if they are also winking (asymmetrical blinking)
        let blinkLeft = face.blendShapes[.eyeBlinkLeft]?.doubleValue ?? 0.0
        let blinkRight = face.blendShapes[.eyeBlinkRight]?.doubleValue ?? 0.0
        let winkAsymmetry = abs(blinkLeft - blinkRight)
        
        // Tongue drives the score, wink pushes it higher
        return min(1.0, tongue + (winkAsymmetry * 0.3))
    }
}

class EmotionClassification {
    func detectEmotion(face:ARFaceAnchor) -> String {
        let emotions:[Emotion] = [NeutralEmotion(), HappyEmotion(), SadEmotion(), AngryEmotion(), SpeedEmotion(), SuprisedEmotion(), ConfidenceEmotion(), SillinessEmotion()]
        printBlendShapes(for: face)
        let validEmotions = emotions.map{e in
            (name:e.name, score:e.confidenceScore(for: face), threshold:e.threshold)
        }.filter{
            $0.score > $0.threshold
        }
        guard let emotionName = validEmotions.max(by:{$0.score < $1.score})?.name  else {
            return "unknown"
        }
        return emotionName
    }
    func emotionToEmoji(_ emotion:String) -> String{
        switch emotion {
            case "happiness": return "😀"
            case "sadness": return "😢"
            case "anger": return "😡"
            case "suprise": return "😲"
            case "IShowSpeed": return "🤭"
            case "neutrality": return "😐"
            case "confidence": return "😏"
            case "silliness":return "😛"
            default: return "❓"
        }
    }
    private func printBlendShapes(for face: ARFaceAnchor) {
            let sortedShapes = face.blendShapes.sorted { $0.key.rawValue < $1.key.rawValue }
            print("--- ARFaceAnchor BlendShapes ---")
            for (location, value) in sortedShapes {
                let formattedValue = String(format: "%.3f", value.floatValue)
                print("\(location.rawValue): \(formattedValue)")
            }
            print("--------------------------------")
        }
}
