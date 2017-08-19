//
//  VideoChatViewController.swift
//  Agora Video Source
//
//  Created by GongYuhua on 2017/4/11.
//  Copyright © 2017 Agora.io All rights reserved.
//

import UIKit
import AVFoundation

class VideoChatViewController: UIViewController {
    @IBOutlet weak var localVideo: MyVideoView!
    @IBOutlet weak var remoteVideo: UIView!
    @IBOutlet weak var controlButtons: UIView!
    @IBOutlet weak var remoteVideoMutedIndicator: UIImageView!
    @IBOutlet weak var localVideoMutedBg: UIImageView!
    @IBOutlet weak var localVideoMutedIndicator: UIImageView!

    var agoraKit: AgoraRtcEngineKit!
    var videoCapture: MyVideoCapture!
    
    
    //MARK: ------Faceunity-------
    static var mcontext:EAGLContext!
    var items:[Int32] = [0,0]
    var fuInit:Bool = false
    var frameID:Int32 = 0
    var needReloadItem:Bool = true
    
    lazy var fuDemoBar: FUAPIDemoBar = {
        let bar = FUAPIDemoBar.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height, width: self.view.frame.size.width, height: 208))
        bar.itemsDataSource = ["noitem", "yuguan", "yazui", "mask_matianyu", "lixiaolong", "EatRabbi", "Mood"]
        
        bar.selectedItem = bar.itemsDataSource[1]

        bar.filtersDataSource = ["nature", "delta", "electric", "slowlived", "tokyo", "warm"]
        bar.selectedFilter = bar.filtersDataSource[0]

        bar.selectedBlur = 6
        bar.beautyLevel = 0.2
        bar.thinningLevel = 1.0
        bar.enlargingLevel = 0.5
        bar.faceShapeLevel = 0.5
        bar.faceShape = 3
        bar.redLevel = 0.5
        bar.delegate = self
        return bar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideVideoMuted()
        initializeAgoraEngine()
        setupVideo()
        startVideoCapture()
        joinChannel()
        
        view.addSubview(fuDemoBar)
    }
    
    @IBAction func showFUDemoBar(_ sender: UIButton) {
        if sender.isSelected {
            
            UIView.animate(withDuration: 0.4, animations: {
                self.fuDemoBar.frame = CGRect.init(x: 0, y: self.view.frame.size.height, width: self.view.frame.size.width, height: 208)
            })
        }else {
            UIView.animate(withDuration: 0.4, animations: {
                self.fuDemoBar.frame = CGRect.init(x: 0, y: self.view.frame.size.height - 208 , width: self.view.frame.size.width, height: 208)
            })
        }
        sender.isSelected = !sender.isSelected
    }
    
    func initializeAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
    }

    func setupVideo() {
        agoraKit.setExternalVideoSource(true, useTexture: true, pushMode: true)
        agoraKit.enableVideo()
        agoraKit.setVideoProfile(._VideoProfile_360P, swapWidthAndHeight: true)
        
    }
    
    func startVideoCapture() {
        videoCapture = MyVideoCapture(delegate: self, videoView: localVideo)
        videoCapture.startCapture(ofCamera: Camera.defaultCamera())
    }
    
    func joinChannel() {
        agoraKit.joinChannel(byKey: nil, channelName: "demoChannel", info: nil, uid: 0) { [unowned self] _ in
            self.agoraKit.setEnableSpeakerphone(true)
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    @IBAction func didClickHangUpButton(_ sender: UIButton) {
        leaveChannel()
    }
    
    func leaveChannel() {
        
        videoCapture.stopCapture()
        agoraKit.leaveChannel(nil)
        
        hideControlButtons()
        UIApplication.shared.isIdleTimerDisabled = false
        remoteVideo.removeFromSuperview()
        localVideo.removeFromSuperview()
        
        agoraKit = nil
        
    //MARK:------FaceUnity---
        setupContex()
        fuDestroyAllItems()
        items[0] = 0
        items[1] = 0
    }

    func hideControlButtons() {
        controlButtons.isHidden = true
    }
    
    @IBAction func didClickMuteButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        agoraKit.muteLocalAudioStream(sender.isSelected)
    }
    
    @IBAction func didClickVideoMuteButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        agoraKit.muteLocalVideoStream(sender.isSelected)
        localVideo.isHidden = sender.isSelected
        localVideoMutedBg.isHidden = !sender.isSelected
        localVideoMutedIndicator.isHidden = !sender.isSelected
    }
    
    func hideVideoMuted() {
        remoteVideoMutedIndicator.isHidden = true
        localVideoMutedBg.isHidden = true
        localVideoMutedIndicator.isHidden = true
    }
    
    @IBAction func didClickSwitchCameraButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        videoCapture.switchCamera()
    }
}

extension VideoChatViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit!, firstRemoteVideoDecodedOfUid uid:UInt, size:CGSize, elapsed:Int) {
        if (remoteVideo.isHidden) {
            remoteVideo.isHidden = false
        }
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = remoteVideo
        videoCanvas.renderMode = .render_Fit
        agoraKit.setupRemoteVideo(videoCanvas)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didOfflineOfUid uid:UInt, reason:AgoraRtcUserOfflineReason) {
        self.remoteVideo.isHidden = true
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didVideoMuted muted:Bool, byUid:UInt) {
        remoteVideo.isHidden = muted
        remoteVideoMutedIndicator.isHidden = !muted
    }
}

extension VideoChatViewController: MyVideoCaptureDelegate {
    
    // 添加Faceunity特效
    func myVideoCapture(didOutput sampleBuffer: CMSampleBuffer, pixelBuffer: CVPixelBuffer) {


        setupContex()
        
        if !fuInit {
            fuInit = true
            var size:Int32 = 0;
            let v3 = mmap_bundle(bundle: "v3.bundle", psize: &size)
            // 初始化~
            FURenderer.share().setup(withData: v3, ardata: nil, authPackage: &g_auth_package, authSize: Int32(MemoryLayout.size(ofValue: g_auth_package)))
        }
        
        if needReloadItem {
            needReloadItem = false
            reloadItem()
        }
        
        if items[1] == 0 {
            // 美颜
            loadFilter()
        }
        
        //  Set item parameters
        fuItemSetParamd(items[1], UnsafeMutablePointer(mutating: ("cheek_thinning" as NSString).utf8String!), Double(self.fuDemoBar.thinningLevel));//瘦脸
        fuItemSetParamd(items[1], UnsafeMutablePointer(mutating: ("eye_enlarging" as NSString).utf8String!), Double(self.fuDemoBar.enlargingLevel));//大眼
        fuItemSetParamd(items[1], UnsafeMutablePointer(mutating: ("color_level" as NSString).utf8String!), Double(self.fuDemoBar.beautyLevel));//美白
        fuItemSetParams(items[1], UnsafeMutablePointer(mutating: ("filter_name" as NSString).utf8String!), UnsafeMutablePointer(mutating: (fuDemoBar.selectedFilter as NSString).utf8String!));// 滤镜
        fuItemSetParamd(items[1], UnsafeMutablePointer(mutating: ("blur_level" as NSString).utf8String!), Double(self.fuDemoBar.selectedBlur));// 磨皮
        fuItemSetParamd(items[1], UnsafeMutablePointer(mutating: ("face_shape" as NSString).utf8String!), Double(self.fuDemoBar.faceShape));//瘦脸类型
        fuItemSetParamd(items[1], UnsafeMutablePointer(mutating: ("face_shape_level" as NSString).utf8String!), Double(self.fuDemoBar.faceShapeLevel));//瘦脸等级
        fuItemSetParamd(items[1], UnsafeMutablePointer(mutating: ("red_level" as NSString).utf8String!), Double(self.fuDemoBar.redLevel));//红润
        
        FURenderer.share().renderPixelBuffer(pixelBuffer, withFrameId: frameID, items: UnsafeMutablePointer<Int32>(mutating: items)!, itemCount: 2, flipx: true)
        frameID += 1
        
        // 展示
        localVideo.displayBuffer(sampleBuffer: sampleBuffer)
        
        // --------AgoraVideoFrame
        let videoFrame = AgoraVideoFrame()
        videoFrame.format = 12
        videoFrame.textureBuf = pixelBuffer
        videoFrame.timeStamp = Int64(CACurrentMediaTime()*1000)
        videoFrame.rotation = Int32(0)

        agoraKit?.pushExternalVideoFrame(videoFrame)
    }
}

//MARK: - FUAPIDemoBarDelegate
extension VideoChatViewController: FUAPIDemoBarDelegate
{
    func demoBarDidSelectedItem(_ item: String!) {
        needReloadItem = true
    }
    
}

//MARK: -Faceunity Data Load
extension VideoChatViewController
{
    
    func setupContex() {
        
        if VideoChatViewController.mcontext == nil {
            VideoChatViewController.mcontext = EAGLContext(api: .openGLES2)
        }
        
        if VideoChatViewController.mcontext == nil || !EAGLContext.setCurrent(VideoChatViewController.mcontext) {
            print("context error")
        }
    }
    
    
    func reloadItem()
    {
        setupContex()
        if fuDemoBar.selectedItem == "noitem" || fuDemoBar.selectedItem == nil
        {
            if items[0] != 0 {
                fuDestroyItem(items[0])
            }
            items[0] = 0
            return
        }
        
        var size:Int32 = 0
        // load selected
        let data = mmap_bundle(bundle: fuDemoBar.selectedItem + ".bundle", psize: &size)
        
        let itemHandle = fuCreateItemFromPackage(data, size)
        
        if items[0] != 0 {
            fuDestroyItem(items[0])
        }
        
        items[0] = itemHandle
        
        print("faceunity: load item")
    }
    
    func loadFilter()
    {
        setupContex()
        
        var size:Int32 = 0
        
        let data = mmap_bundle(bundle: "face_beautification.bundle", psize: &size)
        
        items[1] = fuCreateItemFromPackage(data, size);
    }
    
    func mmap_bundle(bundle: String, psize:inout Int32) -> UnsafeMutableRawPointer? {
        
        // Load item from predefined item bundle
        let str = Bundle.main.resourcePath! + "/" + bundle
        let fn = str.cString(using: String.Encoding.utf8)!
        let fd = open(fn, O_RDONLY)
        
        var size:Int32
        var zip:UnsafeMutableRawPointer!
        
        if fd == -1 {
            print("faceunity: failed to open bundle")
            size = 0
        }else
        {
            size = getFileSize(fd: fd);
            zip = mmap(nil, Int(size), PROT_READ, MAP_SHARED, fd, 0)
        }
        
        psize = size
        return zip
    }
    
    func getFileSize(fd: Int32) -> Int32
    {
        var sb:stat = stat()
        sb.st_size = 0
        fstat(fd, &sb)
        return Int32(sb.st_size)
    }
}
