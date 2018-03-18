import UIKit
import AVFoundation

class FaceTracker: NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
    
    var videoOutput = AVCaptureVideoDataOutput()
    var view:UIView
//    private var findface : (_ arr:Array<CGRect>) -> Void
    private var findface : (_ arr:Array<Face>) -> Void
//    required init(view:UIView, findface: @escaping (_ arr:Array<CGRect>) -> Void)
    required init(view:UIView, findface: @escaping (_ arr:Array<Face>) -> Void)
    {
        self.view=view
        self.findface = findface
        super.init()
        self.initialize()
    }
    
    
    func initialize()
    {
        //各デバイスの登録(audioは実際いらない)
        do {
            let videoInput = try AVCaptureDeviceInput(device: self.videoDevice!) as AVCaptureDeviceInput
            self.captureSession.addInput(videoInput)
        } catch let error as NSError {
            print(error)
        }
        do {
            let audioInput = try AVCaptureDeviceInput(device: self.audioDevice!) as AVCaptureInput
            self.captureSession.addInput(audioInput)
        } catch let error as NSError {
            print(error)
        }
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCVPixelFormatType_32BGRA)]
        
        //フレーム毎に呼び出すデリゲート登録
        //let queue:DispatchQueue = DispatchQueue(label:"myqueue",attribite: DISPATCH_QUEUE_SERIAL)
        let queue:DispatchQueue = DispatchQueue(label: "myqueue", attributes: .concurrent)
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.view.layer.addSublayer(videoLayer)
        
        //カメラ向き
        for connection in self.videoOutput.connections {
            let conn = connection
            if conn.isVideoOrientationSupported {
                conn.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        
        self.captureSession.startRunning()
    }
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        //バッファーをUIImageに変換
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context!.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage: UIImage = UIImage(cgImage: imageRef!)
        return resultImage
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        //同期処理（非同期処理ではキューが溜まりすぎて画面がついていかない）
        DispatchQueue.main.sync(execute: {
            
            //バッファーをUIImageに変換
            let image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            let ciimage:CIImage! = CIImage(image: image)
            
            //CIDetectorAccuracyHighだと高精度（使った感じは遠距離による判定の精度）だが処理が遅くなる
            let detector : CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyLow] )!
//            let faces : NSArray = detector.features(in: ciimage) as NSArray
            let options = [CIDetectorSmile : true, CIDetectorEyeBlink : true]
            let faces : NSArray = detector.features(in: ciimage, options: options) as NSArray

            if faces.count != 0
            {
//                var rects = Array<CGRect>();
                var rects = Array<Face>();
                var _ : CIFaceFeature = CIFaceFeature()
                for feature in faces {
                    
                    // 座標変換
                    var faceRect : CGRect = (feature as AnyObject).bounds
                    let widthPer = (self.view.bounds.width/image.size.width)
                    let heightPer = (self.view.bounds.height/image.size.height)
                    
                    // その他プロパティ
                    //                    hasSmile    Bool    笑顔かどうか
                    //                    faceAngle    Float    顔の傾き （回転角度）
                    //                    leftEyePosition    CGPoint    左目の位置
                    //                    rightEyePosition    CGPoint    右目の位置
                    //                    mouthPosition    CGPoint    口の位置
                    //                    他にも、leftEyeClosedやrightEyeClosed
                    var hasSmile : Bool = (feature as AnyObject).hasSmile
                    var faceAngle : Float = (feature as AnyObject).faceAngle
                    var leftEyePosition : CGPoint = (feature as AnyObject).leftEyePosition
                    var rightEyePosition : CGPoint = (feature as AnyObject).rightEyePosition
                    var mouthPosition : CGPoint = (feature as AnyObject).mouthPosition
                    var leftEyeClosed : Bool = (feature as AnyObject).leftEyeClosed
                    var rightEyeClosed : Bool = (feature as AnyObject).rightEyeClosed

                    
                    
                    print("hasSmile=",hasSmile)
                    print("faceAngle=",faceAngle)
                    print("leftEyePosition=" , leftEyePosition)
                    print("rightEyePosition=" , rightEyePosition)
                    print("mouthPosition=" , mouthPosition)
                    print("leftEyeClosed=" , leftEyeClosed)
                    print("rightEyeClosed=" , rightEyeClosed)

                    // other
                    var leftEyeRect:CGRect  = CGRect(x: leftEyePosition.x  * 1, y: leftEyePosition.y  * 1, width: 10, height: 10)
                    var rightEyeRect:CGRect = CGRect(x: rightEyePosition.x * 1, y: rightEyePosition.y * 1, width: 10, height: 10)
                    var mouthRect:CGRect    = CGRect(x: mouthPosition.x    * 1, y: mouthPosition.y    * 1, width: 10, height: 10)

                    // UIKitは左上に原点があるが、CoreImageは左下に原点があるので揃える
                    faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                    // other
                    leftEyeRect.origin.y = image.size.height - leftEyeRect.origin.y - leftEyeRect.size.height
                    rightEyeRect.origin.y = image.size.height - rightEyeRect.origin.y - rightEyeRect.size.height
                    mouthRect.origin.y = image.size.height - mouthRect.origin.y - mouthRect.size.height

                    
                    //倍率変換
                    faceRect.origin.x = faceRect.origin.x * widthPer
                    faceRect.origin.y = faceRect.origin.y * heightPer
                    faceRect.size.width = faceRect.size.width * widthPer
                    faceRect.size.height = faceRect.size.height * heightPer
                    
                    //other
                    leftEyeRect.origin.x = leftEyeRect.origin.x * widthPer
                    leftEyeRect.origin.y = leftEyeRect.origin.y * heightPer
                    
                    rightEyeRect.origin.x = rightEyeRect.origin.x * widthPer
                    rightEyeRect.origin.y = rightEyeRect.origin.y * heightPer
                    
                    mouthRect.origin.x = mouthRect.origin.x * widthPer
                    mouthRect.origin.y = mouthRect.origin.y * heightPer
                    
                    
                    // other
//                    var leftEyeRect:CGRect  = CGRect(x: leftEyePosition.x  * widthPer, y: leftEyePosition.y  * heightPer, width: 10, height: 10)
//                    var rightEyeRect:CGRect = CGRect(x: rightEyePosition.x * widthPer, y: rightEyePosition.y * heightPer, width: 10, height: 10)
//                    var mouthRect:CGRect    = CGRect(x: mouthPosition.x    * widthPer, y: mouthPosition.y    * heightPer, width: 10, height: 10)

                    
//                    leftEyeRect.origin.y = image.size.height - leftEyeRect.origin.y - leftEyeRect.size.height
//                    rightEyeRect.origin.y = image.size.height - rightEyeRect.origin.y - rightEyeRect.size.height
//                    mouthRect.origin.y = image.size.height - mouthRect.origin.y - mouthRect.size.height

                    
//                    rects.append(faceRect)
                    
                    let face:Face = Face()
                    face.faceRect = faceRect
                    face.hasSmile = hasSmile
                    face.faceAngle = faceAngle
                    face.leftEyePosition = leftEyePosition
                    face.rightEyePosition = rightEyePosition
                    face.mouthPosition = mouthPosition
                    face.leftEyeClosed = leftEyeClosed
                    face.rightEyeClosed = rightEyeClosed
                    face.leftEyeRect = leftEyeRect
                    face.rightEyeRect = rightEyeRect
                    face.mouseRect = mouthRect

                    rects.append(face)
                    
                }
                self.findface(rects)
            }
        })
    }
}


