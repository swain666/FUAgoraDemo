//
//  LiveRoomViewController.swift
//  OpenLive
//
//  Created by GongYuhua on 6/25/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import UIKit
import AgoraRtcEngineKit

protocol LiveRoomVCDelegate: NSObjectProtocol {
    func liveVCNeedClose(_ liveVC: LiveRoomViewController)
}

class LiveRoomViewController: UIViewController {
    
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var remoteContainerView: UIView!
    @IBOutlet weak var broadcastButton: UIButton!
    @IBOutlet var sessionButtons: [UIButton]!
    @IBOutlet weak var audioMuteButton: UIButton!
    
    @IBOutlet weak var fuDemoBar: FUAPIDemoBar!{
        
        didSet {
            fuDemoBar.itemsDataSource = ["noitem", "EatRabbi", "bg_seg", "yazui", "mask_matianyu", "lixiaolong", "Mood", "gradient", "yuguan"]
            fuDemoBar.selectedItem = fuDemoBar.itemsDataSource[1]
            
            fuDemoBar.filtersDataSource = ["nature", "delta", "electric", "slowlived", "tokyo", "warm"]
            fuDemoBar.selectedFilter = fuDemoBar.filtersDataSource[0]
            
            fuDemoBar.selectedBlur = 6
            fuDemoBar.beautyLevel = 0.2
            fuDemoBar.thinningLevel = 1.0
            fuDemoBar.enlargingLevel = 0.5
            fuDemoBar.faceShapeLevel = 0.5
            fuDemoBar.faceShape = 3
            fuDemoBar.redLevel = 0.5
            fuDemoBar.delegate = self as FUAPIDemoBarDelegate
        }
    }
    
    
    //MARK: Faceunity
    static var mcontext:EAGLContext!
    var items:[Int32] = [0,0]
    var fuInit:Bool = false
    var frameID:Int32 = 0
    var needReloadItem:Bool = true
    // --------------- Faceunity ----------------
    
    //MARK: Thrid filter
    fileprivate lazy var yuvProcessor:YuvPreProcessor? = {
        let yuvProcessor = YuvPreProcessor()
        yuvProcessor.delegate = self
        return yuvProcessor
    }()
    fileprivate var shouldYuvProcessor = false {
        didSet {
            if shouldYuvProcessor {
                yuvProcessor?.turnOn()
            } else {
                yuvProcessor?.turnOff()
            }
        }
    }
    
    var roomName: String!
    var clientRole = AgoraRtcClientRole.clientRole_Audience {
        didSet {
            updateButtonsVisiablity()
        }
    }
    var videoProfile: AgoraRtcVideoProfile!
    weak var delegate: LiveRoomVCDelegate?
    
    //MARK: - engine & session view
    var rtcEngine: AgoraRtcEngineKit!
    fileprivate lazy var agoraEnhancer: AgoraYuvEnhancerObjc? = {
        let enhancer = AgoraYuvEnhancerObjc()
        enhancer.lighteningFactor = 0.7
        enhancer.smoothness = 0.7
        return enhancer
    }()
    fileprivate var isBroadcaster: Bool {
        return clientRole == .clientRole_Broadcaster
    }
    fileprivate var isMuted = false {
        didSet {
            rtcEngine?.muteLocalAudioStream(isMuted)
            audioMuteButton?.setImage(UIImage(named: isMuted ? "btn_mute_cancel" : "btn_mute"), for: .normal)
        }
    }
    fileprivate var shouldEnhancer = true {
        didSet {
            if shouldEnhancer {
                agoraEnhancer?.turnOn()
            } else {
                agoraEnhancer?.turnOff()
            }
//            enhancerButton?.setImage(UIImage(named: shouldEnhancer ? "btn_beautiful_cancel" : "btn_beautiful"), for: .normal)
        }
    }
    
    fileprivate var videoSessions = [VideoSession]() {
        didSet {
            guard remoteContainerView != nil else {
                return
            }
            updateInterface(withAnimation: true)
        }
    }
    fileprivate var fullSession: VideoSession? {
        didSet {
            if fullSession != oldValue && remoteContainerView != nil {
                updateInterface(withAnimation: true)
            }
        }
    }
    
    fileprivate let viewLayouter = VideoViewLayouter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = roomName
        updateButtonsVisiablity()
        
        loadAgoraKit()
    }
    
    //MARK: - user action
    @IBAction func doSwitchCameraPressed(_ sender: UIButton) {
        rtcEngine?.switchCamera()
    }
    
    @IBAction func doMutePressed(_ sender: UIButton) {
        isMuted = !isMuted
    }
    
    @IBAction func doBroadcastPressed(_ sender: UIButton) {
        if isBroadcaster {
            clientRole = .clientRole_Audience
            if fullSession?.uid == 0 {
                fullSession = nil
            }
        } else {
            clientRole = .clientRole_Broadcaster
        }
        
        rtcEngine.setClientRole(clientRole, withKey: nil)
        updateInterface(withAnimation :true)
    }
    
    @IBAction func doDoubleTapped(_ sender: UITapGestureRecognizer) {
        if fullSession == nil {
            if let tappedSession = viewLayouter.responseSession(of: sender, inSessions: videoSessions, inContainerView: remoteContainerView) {
                fullSession = tappedSession
            }
        } else {
            fullSession = nil
        }
    }
    
    @IBAction func doLeavePressed(_ sender: UIButton) {
        leaveChannel()
    }
}

private extension LiveRoomViewController {
    func updateButtonsVisiablity() {
        guard let sessionButtons = sessionButtons else {
            return
        }
        
        broadcastButton?.setImage(UIImage(named: isBroadcaster ? "btn_join_cancel" : "btn_join"), for: UIControlState())
        
        for button in sessionButtons {
            button.isHidden = !isBroadcaster
        }
    }
    
    func leaveChannel() {
        setIdleTimerActive(true)
        
        rtcEngine.setupLocalVideo(nil)
        rtcEngine.leaveChannel(nil)
        if isBroadcaster {
            rtcEngine.stopPreview()
        }
        
        for session in videoSessions {
            session.hostingView.removeFromSuperview()
        }
        videoSessions.removeAll()
        
        delegate?.liveVCNeedClose(self)
        
        if shouldYuvProcessor {
            //离开时关闭YuvProcessor,并销毁美颜及道具内存
            shouldYuvProcessor = false
            
            //-------------faceunity--------------
            setupContex()
            fuDestroyAllItems()
        }
    }
    
    func setIdleTimerActive(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !active
    }
    
    func alert(string: String) {
        guard !string.isEmpty else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: string, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

private extension LiveRoomViewController {
    func updateInterface(withAnimation animation: Bool) {
        if animation {
            UIView.animate(withDuration: 0.3, animations: { [weak self] _ in
                self?.updateInterface()
                self?.view.layoutIfNeeded()
            })
        } else {
            updateInterface()
        }
    }
    
    func updateInterface() {
        var displaySessions = videoSessions
        if !isBroadcaster && !displaySessions.isEmpty {
            displaySessions.removeFirst()
        }
        viewLayouter.layout(sessions: displaySessions, fullSession: fullSession, inContainer: remoteContainerView)
        setStreamType(forSessions: displaySessions, fullSession: fullSession)
    }
    
    func setStreamType(forSessions sessions: [VideoSession], fullSession: VideoSession?) {
        if let fullSession = fullSession {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: (session == fullSession ? .videoStream_High : .videoStream_Low))
            }
        } else {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: .videoStream_High)
            }
        }
    }
    
    func addLocalSession() {
        let localSession = VideoSession.localSession()
        videoSessions.append(localSession)
        rtcEngine.setupLocalVideo(localSession.canvas)
    }
    
    func fetchSession(ofUid uid: Int64) -> VideoSession? {
        for session in videoSessions {
            if session.uid == uid {
                return session
            }
        }
        
        return nil
    }
    
    func videoSession(ofUid uid: Int64) -> VideoSession {
        if let fetchedSession = fetchSession(ofUid: uid) {
            return fetchedSession
        } else {
            let newSession = VideoSession(uid: uid)
            videoSessions.append(newSession)
            return newSession
        }
    }
}

//MARK: - Agora Media SDK
private extension LiveRoomViewController {
    func loadAgoraKit() {
        rtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
        rtcEngine.setChannelProfile(.channelProfile_LiveBroadcasting)
        rtcEngine.enableDualStreamMode(true)
        rtcEngine.enableVideo()
        rtcEngine.setVideoProfile(videoProfile, swapWidthAndHeight: true)
        rtcEngine.setClientRole(clientRole, withKey: nil)
        
        if isBroadcaster {
            rtcEngine.startPreview()
        }
        
        addLocalSession()
        
        let code = rtcEngine.joinChannel(byKey: nil, channelName: roomName, info: nil, uid: 0, joinSuccess: nil)
        if code == 0 {
            setIdleTimerActive(false)
            rtcEngine.setEnableSpeakerphone(true)
        } else {
            DispatchQueue.main.async(execute: {
                self.alert(string: "Join channel failed: \(code)")
            })
        }
        
        if isBroadcaster {
            shouldYuvProcessor = true
        }
    }
}

extension LiveRoomViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let userSession = videoSession(ofUid: Int64(uid))
        rtcEngine.setupRemoteVideo(userSession.canvas)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstLocalVideoFrameWith size: CGSize, elapsed: Int) {
        if let _ = videoSessions.first {
            updateInterface(withAnimation: false)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraRtcUserOfflineReason) {
        var indexToDelete: Int?
        for (index, session) in videoSessions.enumerated() {
            if session.uid == Int64(uid) {
                indexToDelete = index
            }
        }
        
        if let indexToDelete = indexToDelete {
            let deletedSession = videoSessions.remove(at: indexToDelete)
            deletedSession.hostingView.removeFromSuperview()
            
            if deletedSession == fullSession {
                fullSession = nil
            }
        }
    }
}

//MARK: - FUAPIDemoBarDelegate
extension LiveRoomViewController: FUAPIDemoBarDelegate
{
    func demoBarDidSelectedItem(_ item: String!) {
        needReloadItem = true
    }
    
}

//MARK: - YuvPreProcessorProtocol

//在这里处理视频数据，添加Faceunity特效
extension LiveRoomViewController: YuvPreProcessorProtocol {
    func onFrameAvailable(_ y: UnsafeMutablePointer<UInt8>, ubuf u: UnsafeMutablePointer<UInt8>, vbuf v: UnsafeMutablePointer<UInt8>, ystride: Int32, ustride: Int32, vstride: Int32, width: Int32, height: Int32) {
        
        
        setupContex()
        
        if !fuInit {
            fuInit = true
            var size:Int32 = 0;
            let v3 = mmap_bundle(bundle: "v3.bundle", psize: &size)
            
            FURenderer.share().setup(withData: v3, ardata: nil, authPackage: &g_auth_package, authSize: Int32(MemoryLayout.size(ofValue: g_auth_package)))
        }
        
        if needReloadItem {
            needReloadItem = false
            
            reloadItem()
        }
        
        if items[1] == 0 {
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
        
//        FURenderer.share().renderFrame(y, u: u, v: v, ystride: ystride, ustride: ustride, vstride: vstride, width: width, height: height, frameId: frameID, items: UnsafeMutablePointer<Int32>(mutating: items)!, itemCount: 2);
        
        FURenderer.share().renderFrame(y, u: u, v: v, ystride: ystride, ustride: ustride, vstride: vstride, width: width, height: height, frameId: frameID, items: UnsafeMutablePointer<Int32>(mutating: items)!, itemCount: 2, flipx: true)
        
        frameID += 1
    }
}

//MARK: -Faceunity Data Load
extension LiveRoomViewController
{
    
    func setupContex() {
        
        if LiveRoomViewController.mcontext == nil {
            LiveRoomViewController.mcontext = EAGLContext(api: .openGLES2)
        }
        
        if LiveRoomViewController.mcontext == nil || !EAGLContext.setCurrent(LiveRoomViewController.mcontext) {
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
        
        if fuDemoBar.selectedItem == "bg_seg" {
            fuItemSetParamd(items[0], UnsafeMutablePointer(mutating: ("rotationAngle" as NSString).utf8String!), 270.0)
        }
        
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
        }else {
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
