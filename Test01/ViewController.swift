//
//  ViewController.swift
//  Test01
//
//  Created by 鈴木正樹 on 2018/03/18.
//  Copyright © 2018年 鈴木正樹. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // -----
    var faceTracker:FaceTracker? = nil;
    
    @IBOutlet var cameraView :UIView!//viewController上に一つviewを敷いてそれと繋いでおく
    
    var rectView = UIView()
    
    var leftEyeView = UIView()
    var rightEyeView = UIView()
    var mouseView = UIView()

    //
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.rectView.layer.borderWidth = 3//四角い枠を用意しておく
        self.rectView.frame.size.height = 400
        
        self.leftEyeView.layer.borderWidth = 3//四角い枠を用意しておく
        self.leftEyeView.frame.size.height = 10
        
        self.rightEyeView.layer.borderWidth = 3//四角い枠を用意しておく
        self.rightEyeView.frame.size.height = 10
        
        self.mouseView.layer.borderWidth = 3//四角い枠を用意しておく
        self.mouseView.frame.size.height = 10
        
        self.view.addSubview(self.rectView)
        self.view.addSubview(self.leftEyeView)
        self.view.addSubview(self.rightEyeView)
        self.view.addSubview(self.mouseView)

        faceTracker = FaceTracker(view: self.cameraView, findface:{arr in
            let face:Face = arr[0] //一番の顔だけ使う
//            var rect:CGRect = face.faceRect
            
            self.rectView.frame = face.faceRect
            self.rectView.transform.rotated(by: CGFloat(face.faceAngle))
            
            if (!face.leftEyeClosed) {
                self.leftEyeView.frame  = face.leftEyeRect
            }
            if (!face.rightEyeClosed) {
                self.rightEyeView.frame = face.rightEyeRect
            }
            
            self.mouseView.frame = face.mouseRect
        })
    }
}

