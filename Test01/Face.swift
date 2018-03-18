import UIKit
import AVFoundation

class Face: NSObject {
    public var faceRect : CGRect = CGRect()
    public var hasSmile : Bool = false
    public var faceAngle : Float = 0.0
    public var leftEyePosition : CGPoint = CGPoint()
    public var rightEyePosition : CGPoint = CGPoint()
    public var mouthPosition : CGPoint = CGPoint()
    public var leftEyeClosed : Bool = false
    public var rightEyeClosed : Bool = false
    public var leftEyeRect : CGRect = CGRect()
    public var rightEyeRect : CGRect = CGRect()
    public var mouseRect : CGRect = CGRect()

}
