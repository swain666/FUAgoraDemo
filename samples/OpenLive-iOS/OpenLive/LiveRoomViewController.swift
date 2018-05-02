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
    
    
    @IBOutlet weak var demobar: FUAPIDemoBar! {
        
        didSet {
            demobar.itemsDataSource = FUManager.share().itemsDataSource;
            demobar.selectedItem = FUManager.share().selectedItem ;
            
            demobar.filtersDataSource = FUManager.share().filtersDataSource ;
            demobar.beautyFiltersDataSource = FUManager.share().beautyFiltersDataSource ;
            demobar.filtersCHName = FUManager.share().filtersCHName ;
            demobar.selectedFilter = FUManager.share().selectedFilter ;
            demobar.setFilterLevel(FUManager.share().selectedFilterLevel, forFilter: FUManager.share().selectedFilter)
            
            demobar.skinDetectEnable = FUManager.share().skinDetectEnable;
            demobar.blurShape = FUManager.share().blurShape ;
            demobar.blurLevel = FUManager.share().blurLevel ;
            demobar.whiteLevel = FUManager.share().whiteLevel ;
            demobar.redLevel = FUManager.share().redLevel;
            demobar.eyelightingLevel = FUManager.share().eyelightingLevel ;
            demobar.beautyToothLevel = FUManager.share().beautyToothLevel ;
            demobar.faceShape = FUManager.share().faceShape ;
            
            demobar.enlargingLevel = FUManager.share().enlargingLevel ;
            demobar.thinningLevel = FUManager.share().thinningLevel ;
            demobar.enlargingLevel_new = FUManager.share().enlargingLevel_new ;
            demobar.thinningLevel_new = FUManager.share().thinningLevel_new ;
            demobar.jewLevel = FUManager.share().jewLevel ;
            demobar.foreheadLevel = FUManager.share().foreheadLevel ;
            demobar.noseLevel = FUManager.share().noseLevel ;
            demobar.mouthLevel = FUManager.share().mouthLevel ;
            
            demobar.delegate = self as FUAPIDemoBarDelegate;
        }
    }
    
    
    var roomName: String!
    var clientRole = AgoraClientRole.audience {
        didSet {
            updateButtonsVisiablity()
        }
    }
    var videoProfile: AgoraVideoProfile!
    weak var delegate: LiveRoomVCDelegate?
    
    //MARK: - engine & session view
    var rtcEngine: AgoraRtcEngineKit!
    fileprivate var isBroadcaster: Bool {
        return clientRole == .broadcaster
    }
    fileprivate var isMuted = false {
        didSet {
            rtcEngine?.muteLocalAudioStream(isMuted)
            audioMuteButton?.setImage(UIImage(named: isMuted ? "btn_mute_cancel" : "btn_mute"), for: .normal)
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
    
    // --------------- Faceunity ----------------
    
    //MARK: Thrid filter
    fileprivate lazy var yuvProcessor:YuvPreProcessor? = {
        let yuvProcessor = YuvPreProcessor()
        yuvProcessor.delegate = self as YuvPreProcessorProtocol
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = roomName
        updateButtonsVisiablity()
        
        loadAgoraKit()
        
        if isBroadcaster {
            shouldYuvProcessor = true
            
            FUManager.share().loadItems()
            
            self.demobar.isHidden = false
        }
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
            clientRole = .audience
            if fullSession?.uid == 0 {
                fullSession = nil
            }
        } else {
            clientRole = .broadcaster
        }
        
        rtcEngine.setClientRole(clientRole)
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
            
            FUManager.share().destoryItems()
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
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: (session == fullSession ? .high : .low))
            }
        } else {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: .high)
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
        rtcEngine.setChannelProfile(.liveBroadcasting)
        rtcEngine.enableDualStreamMode(true)
        rtcEngine.enableVideo()
        rtcEngine.setVideoProfile(videoProfile, swapWidthAndHeight: true)
        rtcEngine.setClientRole(clientRole)
        
        if isBroadcaster {
            rtcEngine.startPreview()
        }
        
        addLocalSession()
        
        let code = rtcEngine.joinChannel(byToken: nil, channelId: roomName, info: nil, uid: 0, joinSuccess: nil)
        if code == 0 {
            setIdleTimerActive(false)
            rtcEngine.setEnableSpeakerphone(true)
        } else {
            DispatchQueue.main.async(execute: {
                self.alert(string: "Join channel failed: \(code)")
            })
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
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
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



//在这里处理视频数据，添加Faceunity特效
extension LiveRoomViewController: YuvPreProcessorProtocol {
    
    func onFrameAvailable(_ y: UnsafeMutablePointer<UInt8>, ubuf u: UnsafeMutablePointer<UInt8>, vbuf v: UnsafeMutablePointer<UInt8>, ystride: Int32, ustride: Int32, vstride: Int32, width: Int32, height: Int32) {
        
        FUManager.share().renderItemsWith(y: y, u: u, v: v, ystride: ystride, ustride: ustride, vstride: vstride, width: width, height: height)
    }
}

extension LiveRoomViewController : FUAPIDemoBarDelegate {
    func demoBarBeautyParamChanged() {
        
        FUManager.share().skinDetectEnable = demobar.skinDetectEnable;
        FUManager.share().blurShape = demobar.blurShape;
        FUManager.share().blurLevel = demobar.blurLevel ;
        FUManager.share().whiteLevel = demobar.whiteLevel;
        FUManager.share().redLevel = demobar.redLevel;
        FUManager.share().eyelightingLevel = demobar.eyelightingLevel;
        FUManager.share().beautyToothLevel = demobar.beautyToothLevel;
        FUManager.share().faceShape = demobar.faceShape;
        FUManager.share().enlargingLevel = demobar.enlargingLevel;
        FUManager.share().thinningLevel = demobar.thinningLevel;
        FUManager.share().enlargingLevel_new = demobar.enlargingLevel_new;
        FUManager.share().thinningLevel_new = demobar.thinningLevel_new;
        FUManager.share().jewLevel = demobar.jewLevel;
        FUManager.share().foreheadLevel = demobar.foreheadLevel;
        FUManager.share().noseLevel = demobar.noseLevel;
        FUManager.share().mouthLevel = demobar.mouthLevel;
        
        FUManager.share().selectedFilter = demobar.selectedFilter ;
        FUManager.share().selectedFilterLevel = demobar.selectedFilterLevel;
    }
    
    func demoBarDidSelectedItem(_ itemName: String!) {
        
        FUManager.share().loadItem(itemName)
    }
}
