//
//  FRVideoController.swift
//  AVLayerCustom
//
//  Created by haipt on 12/4/15.
//  Copyright © 2015 Framgia. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
let kPlayerStatus = "status"
let kControllerNibName = "FRVideoController"

@objc class FRVideoController: UIViewController {
    //define constant
    let kWidthScreen: CGFloat = UIScreen.mainScreen().bounds.size.width
    let kHeightScreen: CGFloat = UIScreen.mainScreen().bounds.size.height
    
    //public variable
    var listVideoUrl: [String] = []
    
    //player
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var currentVideoIndex: Int = 0
    private var playerSeeking: Bool = false
    private var currentEndTime: CMTime?
    
    //for controls
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var previousBtn: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var durationTimeLbl: UILabel!
    @IBOutlet weak var endTimeLbl: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    private var isPlaying: Bool = false
    private var timeObserver:AnyObject?
    private var navigationFlag: Bool!
    
    init()
    {
        super.init(nibName: kControllerNibName, bundle: nil)
    }
    
    init(withListVideo list: [String], playAtIndex index: Int = 0)
    {
        super.init(nibName: kControllerNibName, bundle: nil)
        listVideoUrl = list
        currentVideoIndex = index
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit{
        print("FRVideoController -> deinit")
        if self.player != nil {
            self.player = nil
        }
        if self.playerLayer != nil {
            self.playerLayer = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initVideoPlayer()
        self.customSlider()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationFlag = self.navigationController?.navigationBarHidden
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.navigationBarHidden = navigationFlag
        self.stopObservers()
    }
    
    func initVideoPlayer() {
        if self.player == nil {
            if listVideoUrl.count > currentVideoIndex {
                let currentPlayerItem = AVPlayerItem(URL: NSURL(string: listVideoUrl[currentVideoIndex])!)
                self.player = AVPlayer(playerItem: currentPlayerItem)
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer!.videoGravity = AVLayerVideoGravityResizeAspect //AVLayerVideoGravityResizeAspectFill
                self.view.layer.addSublayer(self.playerLayer!)
                self.playerLayer!.frame = CGRectMake(0, 0, kWidthScreen, kHeightScreen)
                
                //create control
                controlView.frame = CGRectMake(0, 0, kWidthScreen, kHeightScreen)
                self.view.addSubview(controlView)
                
                self.playBtn.hidden = false
                self.pauseBtn.hidden = true
                self.loadingView.hidden = false
                self.loadingView.startAnimating()
                
                self.nextBtn.hidden = listVideoUrl.count > currentVideoIndex + 1 ? false : true
                self.previousBtn.hidden = currentVideoIndex >  0 ? false : true
                
                self.startObservers()
            }
        }
    }
    
    func startObservers() {
        if (timeObserver == nil) {
            weak var wSelf = self
            timeObserver = player?.addPeriodicTimeObserverForInterval(CMTimeMake(1, 100), queue: dispatch_get_main_queue(),
                usingBlock: { (time: CMTime) -> Void in
                    let currentItem = wSelf!.player?.currentItem!
                    let endTime = CMTimeConvertScale(currentItem!.asset.duration, time.timescale, CMTimeRoundingMethod.RoundHalfAwayFromZero)
                    let currentTimeF: Float = (Float)(CMTimeGetSeconds(time))
                    let endTimeF: Float = (Float)(CMTimeGetSeconds(endTime))
                    if (!isnan(currentTimeF) && !isinf(currentTimeF) && !isnan(endTimeF) && !isinf(endTimeF)) {
                        wSelf?.currentEndTime = endTime
                        wSelf!.updateTime(currentTimeF, endTime: endTimeF)
                    }
            })
        }
        player?.currentItem!.addObserver(self, forKeyPath: kPlayerStatus, options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    
    
    func stopObservers() {
        if (timeObserver != nil) {
            player?.currentItem!.removeObserver(self, forKeyPath: kPlayerStatus)
            player?.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>){
        if keyPath! == kPlayerStatus {
            let status: AVPlayerStatus = self.player!.status
            switch (status) {
            case AVPlayerStatus.ReadyToPlay:
                self.loadingView.hidden = true
                self.loadingView.stopAnimating()
                self.playVideo()
                break
            case AVPlayerStatus.Unknown, AVPlayerStatus.Failed:
                
                break
            }
        }
    }
    
    func playVideoWithItemIndex(index: Int) {
        if listVideoUrl.count > index {
            self.loadingView.hidden = false
            self.loadingView.startAnimating()
            player?.pause()
            player?.currentItem!.removeObserver(self, forKeyPath: kPlayerStatus)
            self.currentVideoIndex = index
            let currentPlayerItem = AVPlayerItem(URL: NSURL(string: listVideoUrl[index])!)
            player?.replaceCurrentItemWithPlayerItem(currentPlayerItem)
            player?.currentItem!.addObserver(self, forKeyPath: kPlayerStatus, options: NSKeyValueObservingOptions.New, context: nil)
        }
    }
    
    @IBAction func playVideo(){
        self.playBtn.hidden = true
        self.pauseBtn.hidden = false
        player?.play()
    }
    
    @IBAction func pauseVideo(){
        self.playBtn.hidden = false
        self.pauseBtn.hidden = true
        player?.pause()
    }
    
    
    @IBAction func nextVideo() {
        if currentVideoIndex < listVideoUrl.count {
            currentVideoIndex = currentVideoIndex + 1
            self.playVideoWithItemIndex(currentVideoIndex)
            self.nextBtn.hidden = false
            self.previousBtn.hidden = false
        }
        if currentVideoIndex >= listVideoUrl.count - 1 {
            self.nextBtn.hidden = true
        }
    }
    
    @IBAction func previousVideo() {
        if currentVideoIndex > 0 {
            currentVideoIndex = currentVideoIndex - 1
            self.playVideoWithItemIndex(currentVideoIndex)
            self.nextBtn.hidden = false
            self.previousBtn.hidden = false
        }
        if currentVideoIndex == 0 {
            self.previousBtn.hidden = true
        }
    }
    
    @IBAction func doneTouched() {
        if !self.isModal() {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                
            })
        }
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        if(playerSeeking || self.player == nil || currentEndTime == nil) {
            return
        }
        self.pauseVideo()
        let currentValue = Double(sender.value)
        let time = CMTimeMultiplyByFloat64(currentEndTime!, currentValue)
        playerSeeking = true
        sender.userInteractionEnabled = false
        weak var wSelf = self
        player?.seekToTime(time, completionHandler: { (finished) -> Void in
            if finished {
                if wSelf != nil {
                    let currentTimeF: Float = (Float)(CMTimeGetSeconds(time))
                    let endTimeF: Float = (Float)(CMTimeGetSeconds(wSelf!.currentEndTime!))
                    if (!isnan(currentTimeF) && !isinf(currentTimeF) && !isnan(endTimeF) && !isinf(endTimeF)) {
                        wSelf!.updateTime(currentTimeF, endTime: endTimeF)
                    }
                }
                wSelf?.playerSeeking = false
                sender.userInteractionEnabled = true
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    wSelf?.playVideo()
                }
            }
        })
    }
    
    func customSlider(){
//        let thumbImg = UIImage(named: "video_handle")
//        thumbImg?.scaleToSize(CGSizeMake(16,16))
//        self.timeSlider.setThumbImage(thumbImg, forState: UIControlState.Normal)
//        self.timeSlider.setMinimumTrackImage(UIImage(named: "volume_white"), forState: UIControlState.Normal)
//        self.timeSlider.setMaximumTrackImage(UIImage(named: "volume_gray"), forState: UIControlState.Normal)
    }
    
    func isModal() -> Bool {
        if (self.presentingViewController != nil) {
            return true
        }
        
        if self.presentingViewController?.presentingViewController == self {
            return true
        }
        
        if self.navigationController?.presentingViewController?.presentingViewController == self.navigationController {
            return true
        }
        return false
    }
    
    func updateTime(durationTime: Float, endTime: Float) {
        self.timeSlider.value = (Float)(durationTime/endTime)
        self.durationTimeLbl.text = self.convertTime(durationTime)
        self.endTimeLbl.text = self.convertTime(endTime)
    }
    
    func convertTime(time: Float) -> String {
        var timeStr = "00:00"
        var minute: Int = 0
        var second: Int = (Int)(floorf(time))
        if time > 60 {
            minute = (Int)(floorf(time/60))
            second = second - minute * 60
        }
        
        timeStr = minute < 10 ? "0\(minute)" : "\(minute)"
        timeStr = timeStr + ":" + (second < 10 ? "0\(second)" : "\(second)")
        return timeStr
    }
}