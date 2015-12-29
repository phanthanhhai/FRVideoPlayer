//
//  ViewController.swift
//  FRVideoPlayer
//
//  Created by haipt on 12/28/15.
//  Copyright © 2015 haipt. All rights reserved.
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

    @IBAction func playVideoTouched() {
        var listVideoUrl: [String] = []
        listVideoUrl.append("http://clips.vorwaerts-gmbh.de/VfE_html5.mp4")
        listVideoUrl.append("http://clips.vorwaerts-gmbh.de/VfE_html5.mp4")
        let videoController = FRVideoController(withListVideo: listVideoUrl)
        self.presentViewController(videoController, animated: true) { () -> Void in
            
        }
    }
}

