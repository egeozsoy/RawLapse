//
//  ViewController.swift
//  RawLapse
//
//  Created by Ege on 20.10.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import UIKit
import Dispatch
import Photos
import AVFoundation

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate{
    /*
    Select a camera input.
    Create and configure a photo capture output.
    Configure the capture session by adding the camera input and the capture output.
    Optionally create and attach a preview view.
    Start the capture session.
    
     */
//    data source Reference
    let pickerViewController = PickerViewController()
//    camera Settings
    var captureSession = AVCaptureSession()
    var currentCamera: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput?
    var photoSettings: AVCapturePhotoSettings?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var cameraPreviewLayerFrame: CGRect?
    var rawPhotoData: Data?
    
//    hud
    var hudActive = false
    var hudView: Hud?
    var blackOutView: UIView?

//    timelapse settings
    var timelapseTimer: Timer?
    var photoCounter = 0
    var activeTimelapse = false
    var lockAEButton: UIButton?
    var lockFocusButton:UIButton?
    
    var secondInterval: Int?
    var amountOfPhotos: Int?
    var continuous: Bool?

    var buttonsSet = false
    
    
    let shutterButton: UIButton = {
        let button = UIButton()
        var image = UIImage(named: "shutter_icon")
        image = image?.withRenderingMode(.alwaysTemplate)
        button.tintColor = UIColor.white
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startTimelapseWith), for: .touchUpInside)
        return button
    }()
    
    let settingsTextView:UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.backgroundColor = UIColor.clear
        tv.textColor = UIColor.white
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()


    let photoCounterLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()


    func setupCaptureSession(){
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
    }
    func setupDevice(){
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera] , mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
        let device = deviceDiscoverySession.devices.first
        currentCamera = device
        
    }
    
    func setupInputOutput(){
        do{
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            let rawFormatType = kCVPixelFormatType_14Bayer_RGGB
            photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormatType)
            let preferedThumbnailFormat = photoSettings?.availableEmbeddedThumbnailPhotoCodecTypes.first
            photoSettings?.embeddedThumbnailPhotoFormat = [AVVideoCodecKey : preferedThumbnailFormat as Any , AVVideoWidthKey : 512 , AVVideoHeightKey: 512]
            photoOutput?.setPreparedPhotoSettingsArray([photoSettings!], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
            
        }catch{
            print(error)
        }
    }
    func setupPreviewLayer(){
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        print(self.view.frame)
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
        let  x = cameraPreviewLayer!.frame.minX
        let width = cameraPreviewLayer!.frame.width
        let height = cameraPreviewLayer!.frame.height
        let wantedHeight = cameraPreviewLayer!.frame.width * 4/3
        let y = (height - wantedHeight)/2
        cameraPreviewLayerFrame = CGRect(x: x, y: y, width: width , height: wantedHeight)
        
    }
    
    func lockUnlockExposure(){
        if let lockedExposure = lockAEButton?.isSelected {
            if(lockedExposure){
                try? currentCamera?.lockForConfiguration()
                currentCamera?.exposureMode = .locked
                try? currentCamera?.unlockForConfiguration()
                }else{
                try? currentCamera?.lockForConfiguration()
                currentCamera?.exposureMode = .continuousAutoExposure
                try? currentCamera?.unlockForConfiguration()
            }
        }
        
        
    }
    func lockUnlockFocus(){
        if let lockedFocus = lockFocusButton?.isSelected{
            if(lockedFocus){
                try? currentCamera?.lockForConfiguration()
                currentCamera?.focusMode = .locked
                try? currentCamera?.unlockForConfiguration()
                
            }
            else{
                try? currentCamera?.lockForConfiguration()
                currentCamera?.focusMode = .continuousAutoFocus
                try? currentCamera?.unlockForConfiguration()
            }
        }
        
    }
    
    
    func updateSettingLabel(){
        settingsTextView.text = "ISO: \(Int(currentCamera!.iso))\nShutter: 1/\(Int(1 / (currentCamera!.exposureDuration).seconds))"
        photoCounterLabel.text = "\(photoCounter)/\(pickerViewController.amountOfPhotos)"
        
    }
    
    
    
    @objc func handleSettingTap(_ tap : UITapGestureRecognizer ){
        updateSettingLabel()
        print("tap")
        if let lockedExposure = lockAEButton?.isSelected , let lockedFocus = lockFocusButton?.isSelected{
            if(!(lockedExposure)){
                handleExposureTap(tap)
            }
            if(!(lockedFocus)){
                handleFocusTap(tap)
            }
        }
        
    }
    
    @objc func handleExposureTap(_ tap : UITapGestureRecognizer){
        print(tap.location(in: self.view))
        if(tap.location(in: self.view).y < (self.view.frame.height - cameraPreviewLayerFrame!.height) / 2 || tap.location(in: self.view).y > (self.view.frame.height - cameraPreviewLayerFrame!.height) / 2 + cameraPreviewLayerFrame!.height ){
        }else{
            
            try? currentCamera?.lockForConfiguration()
        
        let x = tap.location(in: self.view).y / self.view.bounds.size.height
        let y = 1 - tap.location(in: self.view).x / self.view.bounds.size.width
        let point = CGPoint(x: x, y: y)
            
            
        print(x)
        print(y)
        currentCamera?.exposurePointOfInterest = point
        currentCamera?.exposureMode = .autoExpose
        currentCamera?.unlockForConfiguration()
        }
    }
    
    
    @objc func handleFocusTap(_ tap : UITapGestureRecognizer){
        print(tap.location(in: self.view))
        if(tap.location(in: self.view).y < (self.view.frame.height - cameraPreviewLayerFrame!.height) / 2 || tap.location(in: self.view).y > (self.view.frame.height - cameraPreviewLayerFrame!.height) / 2 + cameraPreviewLayerFrame!.height ){
        }else{
            
            try? currentCamera?.lockForConfiguration()
            
            let x = tap.location(in: self.view).y / self.view.bounds.size.height
            let y = 1 - tap.location(in: self.view).x / self.view.bounds.size.width
            print(x)
            print(y)
            currentCamera?.focusPointOfInterest = CGPoint(x: x, y: y)
            currentCamera?.focusMode = .autoFocus
            currentCamera?.unlockForConfiguration()
        }
    }
    
//    double rotate bug
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            setupLandscapeUi()
            self.view.reloadInputViews()
            self.view.layoutIfNeeded()
            self.view.setNeedsLayout()
            cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            let oldX = self.view.frame.maxX
            let oldY = self.view.frame.maxY
            let newFrame = CGRect(x: 0, y: 0, width: oldY, height: oldX)
            
            cameraPreviewLayer?.frame = newFrame
            cameraPreviewLayerFrame = newFrame
            
            print("landscape left")
        } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            setupLandscapeUi()
            self.view.reloadInputViews()
            self.view.layoutIfNeeded()
            self.view.setNeedsLayout()
            cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            let oldX = self.view.frame.maxX
            let oldY = self.view.frame.maxY
            let newFrame = CGRect(x: 0, y: 0, width: oldY, height: oldX)
            
            cameraPreviewLayer?.frame = newFrame
            cameraPreviewLayerFrame = newFrame
            print(self.view.frame)
            print("landscape right")
            
        } else if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            setupPortraitUi()
            self.view.reloadInputViews()
            self.view.layoutIfNeeded()
            self.view.setNeedsLayout()
            cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            let oldX = self.view.frame.maxX
            let oldY = self.view.frame.maxY
            let newFrame = CGRect(x: 0, y: 0, width: oldY, height: oldX)
            cameraPreviewLayerFrame = newFrame
            
            cameraPreviewLayer?.frame = newFrame
            print("portrait")
            
        }
    }
    
    func startRunningCaptureSession(){
        captureSession.startRunning()
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
         self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSettingTap(_:))))
        checkCameraAuthorization { (error) in
            
        }
        checkPhotoLibraryAuthorization { (error) in
            
        }
        
        setupPortraitUi()
        
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
        
    }
    
    @objc func startTimelapseWith(){
        
        self.amountOfPhotos = pickerViewController.amountOfPhotos
        
        self.secondInterval = pickerViewController.secondInterval
        self.continuous = pickerViewController.continuous
        
        
        print("starting timelapse")

        if(activeTimelapse == false){
            activeTimelapse = true;
            shutterButton.tintColor = UIColor.red
//            how to use the timer
            timelapseTimer =  Timer.scheduledTimer(withTimeInterval: TimeInterval(secondInterval!), repeats: true) { (timer) in
                print("in timer")
                
                if(self.photoCounter <= self.amountOfPhotos! || self.continuous!){
                    print("take photo")
                self.takePhoto()
                self.photoCounter += 1;
                self.updateSettingLabel()
            }
            else{
                    self.timelapseTimer?.invalidate();
                 return;
            }
        }
        }else{
            activeTimelapse = false;
            shutterButton.tintColor = UIColor.white
            timelapseTimer?.invalidate();
            return ;
        }
    }


    @objc  func takePhoto(){
//        blackoutview not needed with red shutter button and photo counter
//        use different setting each time
//        if(blackOutView == nil){
//            print("blackout view created")
//            blackOutView = UIView()
//            blackOutView!.backgroundColor = UIColor.black
//            blackOutView!.frame  = cameraPreviewLayerFrame!
//            self.view.addSubview(blackOutView!)
//        }
//            blackout view landscape bug
//        else{
//            blackOutView?.frame = cameraPreviewLayerFrame!
//            blackOutView?.isHidden = false
//            print("blackout view changed")
//        }
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
//            self.blackOutView?.isHidden = true
        }
        
        let uniqueSettings = AVCapturePhotoSettings.init(from: self.photoSettings!)


        photoOutput?.capturePhoto(with: uniqueSettings, delegate: self)
        
        
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if photo.isRawPhoto{
            self.rawPhotoData = photo.fileDataRepresentation()
            
        }else {
//            if jpeg is needed create a jpegData Data? object
//            self.jpegPhotoData = photo.fileDataRepresentation()
        }
        
    }

    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        guard error == nil else{
            print("error")
            return
        }
        
        saveRawWithEmbeddedThumbnail()
        }
    
    func saveRawWithEmbeddedThumbnail(){
        self.checkPhotoLibraryAuthorization { (error) in
        
        }
        
        let dngFileURL = uniqueURL()
        do{
            try rawPhotoData!.write(to: dngFileURL, options: [])
            
        }
        catch let error as NSError{
            print(error)
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let creationRequet = PHAssetCreationRequest.forAsset()
            let creationOptions = PHAssetResourceCreationOptions()
            creationOptions.shouldMoveFile = true
            creationRequet.addResource(with: .photo, fileURL: dngFileURL, options: creationOptions)
            
        }, completionHandler: nil)
        
    }
    func cachesDirectory() -> URL{
        
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        print(paths[0])
        return paths[0]
    }
    
    func uniqueURL() -> URL{
        let uuid = UUID().uuidString
        let saveString = uuid + ".dng"
        print(saveString)
        return cachesDirectory().appendingPathComponent(saveString)
        
    }
    
    
    
    func checkCameraAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            //The user has previously granted access to the camera.
            completionHandler(true)
            
        case .notDetermined:
            // The user has not yet been presented with the option to grant video access so request access.
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { success in
                completionHandler(success)
            })
            
        case .denied:
            // The user has previously denied access.
            completionHandler(false)
            
        case .restricted:
            // The user doesn't have the authority to request access e.g. parental restriction.
            completionHandler(false)
        }
    }
    
    func checkPhotoLibraryAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            // The user has previously granted access to the photo library.
            completionHandler(true)
            
        case .notDetermined:
            // The user has not yet been presented with the option to grant photo library access so request access.
            PHPhotoLibrary.requestAuthorization({ status in
                completionHandler((status == .authorized))
            })
            
        case .denied:
            // The user has previously denied access.
            completionHandler(false)
            
        case .restricted:
            // The user doesn't have the authority to request access e.g. parental restriction.
            completionHandler(false)
        }
    }
    
    
    
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    let switchButton:UIButton = {
        let button = UIButton()
        button.setTitle("HUD", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleHud), for: .touchUpInside)
        
        return button
    }()
    
    let slimTopBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = UIColor.black
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
        
        
    }()
    
    let bottomBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = UIColor.black
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
        
    }()
    
    
   
    
    
    
    @objc func handleHud(){
        print("HUD")
        if hudActive {
            hudView?.animateOut()
            hudActive = false
            
        }
        else{
            if(hudView == nil){
            hudView = Hud.hud(inView: self.view)
            hudView?.setupInsideHud(pickerViewController: pickerViewController)
            hudActive = true
            }
            else{
                hudView?.animateIn()
                hudActive = true
            }
        }
        
    }
    func afterDelay(_ seconds:Double , closure: @escaping () -> ()){
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: closure)
        
    }
    
    @objc func toggleLockAEButton(){
        lockAEButton?.isSelected = !(lockAEButton!.isSelected)
        lockUnlockExposure()
    }
    @objc func toggleLockFocusButton(){
        lockFocusButton?.isSelected = !(lockFocusButton!.isSelected)
        lockUnlockFocus()
    }
    
    var slimTopBarRightAnchor : NSLayoutConstraint?
    var slimTopBarHeightAnchor: NSLayoutConstraint?
    
    var slimTopBarBottomAnchor: NSLayoutConstraint?
    var slimTopBarWidthAnchor: NSLayoutConstraint?
    
    var bottomBarLeftAnchor: NSLayoutConstraint?
    var bottomBarHeightAnchor:NSLayoutConstraint?
    
    var bottomBarTopAnchor: NSLayoutConstraint?
    var bottomBarWidthAnchor: NSLayoutConstraint?
    
    var lockAEButtonLeftAnchor : NSLayoutConstraint?
    var lockAEButtonCenterYAnchor : NSLayoutConstraint?
    var lockAEButtonBottomAnchor: NSLayoutConstraint?
    var lockAEButtonCenterXAnchor : NSLayoutConstraint?
    
    var lockFocusButtonLeftAnchor:NSLayoutConstraint?
    var lockFocusButtonCenterYAnchor : NSLayoutConstraint?
    var lockFocusButtonBottomAnchor: NSLayoutConstraint?
    var lockFocusButtonCenterXAnchor : NSLayoutConstraint?
    
    
    var settingsLabelTopAnchorConstraint: NSLayoutConstraint?
    var settingsLabelWidthAnchorConstraint:NSLayoutConstraint?
    var settiongsLabelRightAnchorConstraint: NSLayoutConstraint?
    var settingsLabelHeightAnchorConstraint: NSLayoutConstraint?
    
    var photoCounterLabelBottomAnchorConstraint: NSLayoutConstraint?
    var photoCounterLabelWidthAnchorConstraint: NSLayoutConstraint?
    var photoCounterLabelLeftAnchorConstraint: NSLayoutConstraint?
    var photoCounterLabelHeightAnchorConstraint: NSLayoutConstraint?
    
    
    
    func setButtons(){
        lockAEButton = UIButton()
        lockAEButton?.setTitle("AE", for: .normal)
        lockAEButton?.setTitleColor(UIColor.white, for: .normal)
        lockAEButton?.setTitleColor(UIColor.orange, for: UIControlState.selected)
        lockAEButton?.addTarget(self, action: #selector(toggleLockAEButton), for: .touchUpInside)
        lockAEButton?.translatesAutoresizingMaskIntoConstraints = false
        
        lockFocusButton = UIButton()
        lockFocusButton?.setTitle("AF", for: .normal)
        lockFocusButton?.setTitleColor(UIColor.white, for: .normal)
        lockFocusButton?.setTitleColor(UIColor.orange, for: .selected)
        lockFocusButton?.addTarget(self, action: #selector(toggleLockFocusButton), for: .touchUpInside)
        lockFocusButton?.translatesAutoresizingMaskIntoConstraints = false
        
        
    }
    
    
    func setupPortraitUi(){
        bottomBar.addSubview(shutterButton)
        
        shutterButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor).isActive = true
        shutterButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor).isActive = true
        shutterButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shutterButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
//        setup two lock buttons
        if(buttonsSet == false){
            setButtons()
            buttonsSet = true
        }
        
        
        
       
        self.view.addSubview(slimTopBar)
        self.view.addSubview(bottomBar)
        slimTopBar.addSubview(switchButton)
        slimTopBar.addSubview(lockAEButton!)
        slimTopBar.addSubview(lockFocusButton!)
        
        bottomBar.addSubview(settingsTextView)
        
        bottomBar.addSubview(photoCounterLabel)
        
       
        
        slimTopBarBottomAnchor?.isActive = false
        slimTopBarWidthAnchor?.isActive = false
        
        slimTopBar.topAnchor.constraint(equalTo: self.view.topAnchor , constant:0).isActive = true
        slimTopBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        slimTopBarRightAnchor = slimTopBar.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        slimTopBarRightAnchor?.isActive = true
        slimTopBarHeightAnchor = slimTopBar.heightAnchor.constraint(equalToConstant: 50)
        slimTopBarHeightAnchor?.isActive = true
        
        switchButton.centerXAnchor.constraint(equalTo: slimTopBar.centerXAnchor).isActive = true
        switchButton.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor).isActive = true
        switchButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        switchButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        lockAEButtonBottomAnchor?.isActive = false
        lockAEButtonCenterXAnchor?.isActive = false
        
        
        lockAEButtonLeftAnchor = lockAEButton?.leftAnchor.constraint(equalTo: slimTopBar.leftAnchor, constant: 16)
        lockAEButtonLeftAnchor?.isActive = true
        lockAEButtonCenterYAnchor = lockAEButton?.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor)
        lockAEButtonCenterYAnchor?.isActive = true
        lockAEButton?.widthAnchor.constraint(equalToConstant: 44).isActive = true
        lockAEButton?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        lockFocusButtonCenterXAnchor?.isActive = false
        lockFocusButtonBottomAnchor?.isActive = false
        
        lockFocusButtonLeftAnchor = lockFocusButton?.leftAnchor.constraint(equalTo: lockAEButton!.rightAnchor)
        lockFocusButtonLeftAnchor?.isActive = true
        lockFocusButtonCenterYAnchor = lockFocusButton?.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor)
        lockFocusButtonCenterYAnchor?.isActive = true
        lockFocusButton?.widthAnchor.constraint(equalToConstant: 44).isActive = true
        lockFocusButton?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
       
        

        bottomBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor , constant:0).isActive = true
        bottomBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        bottomBarLeftAnchor = bottomBar.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        bottomBarLeftAnchor?.isActive = true
        
        bottomBarHeightAnchor = bottomBar.heightAnchor.constraint(equalToConstant: 100)
        bottomBarHeightAnchor?.isActive = true
        bottomBarWidthAnchor?.isActive = false
        bottomBarTopAnchor?.isActive = false
        
        
        settiongsLabelRightAnchorConstraint?.isActive = false
        settingsLabelHeightAnchorConstraint?.isActive = false
        
        settingsTextView.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor).isActive = true
        settingsTextView.leftAnchor.constraint(equalTo: bottomBar.leftAnchor).isActive = true
        
        settingsLabelTopAnchorConstraint =  settingsTextView.topAnchor.constraint(equalTo: bottomBar.topAnchor)
        settingsLabelTopAnchorConstraint?.isActive = true
        
        settingsLabelWidthAnchorConstraint = settingsTextView.widthAnchor.constraint(equalToConstant: 100)
        settingsLabelWidthAnchorConstraint?.isActive = true
        
        photoCounterLabelLeftAnchorConstraint?.isActive = false
        photoCounterLabelHeightAnchorConstraint?.isActive = false
        
        photoCounterLabel.rightAnchor.constraint(equalTo: bottomBar.rightAnchor).isActive = true
        photoCounterLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor).isActive = true
        photoCounterLabelBottomAnchorConstraint =  photoCounterLabel.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor)
        photoCounterLabelBottomAnchorConstraint?.isActive = true
        photoCounterLabelWidthAnchorConstraint = photoCounterLabel.widthAnchor.constraint(equalToConstant: 100)
        photoCounterLabelWidthAnchorConstraint?.isActive = true
        
        
        
        
        
    }
    
    func setupLandscapeUi(){
        if(buttonsSet == false){
            setButtons()
            buttonsSet = true
        }
        
       
        
        
        slimTopBar.leftAnchor.constraint(equalTo: self.view.leftAnchor , constant:0).isActive = true
        slimTopBar.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        slimTopBarHeightAnchor?.isActive = false
        slimTopBarRightAnchor?.isActive = false
        
        slimTopBarBottomAnchor = slimTopBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        slimTopBarBottomAnchor?.isActive = true
        
        slimTopBarWidthAnchor = slimTopBar.widthAnchor.constraint(equalToConstant: 50)
        slimTopBarWidthAnchor?.isActive = true
        
        
        switchButton.centerXAnchor.constraint(equalTo: slimTopBar.centerXAnchor).isActive  = true
        switchButton.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor).isActive = true
        switchButton.heightAnchor.constraint(equalTo: slimTopBar.heightAnchor).isActive = true
        switchButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        
        lockAEButtonLeftAnchor?.isActive = false
        lockAEButtonCenterYAnchor?.isActive = false
        
        lockAEButtonBottomAnchor = lockAEButton?.bottomAnchor.constraint(equalTo: slimTopBar.bottomAnchor , constant: -16)
        lockAEButtonBottomAnchor?.isActive = true
        lockAEButtonCenterXAnchor = lockAEButton?.centerXAnchor.constraint(equalTo: slimTopBar.centerXAnchor)
        lockAEButtonCenterXAnchor?.isActive = true
        lockAEButton?.widthAnchor.constraint(equalToConstant: 44).isActive = true
        lockAEButton?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        lockFocusButtonLeftAnchor?.isActive = false
        lockFocusButtonCenterYAnchor?.isActive = false
        
        lockFocusButtonBottomAnchor = lockFocusButton?.bottomAnchor.constraint(equalTo: lockAEButton!.topAnchor)
        lockFocusButtonBottomAnchor?.isActive = true
        lockFocusButtonCenterXAnchor = lockFocusButton?.centerXAnchor.constraint(equalTo: slimTopBar.centerXAnchor)
        lockFocusButtonCenterXAnchor?.isActive = true
        lockFocusButton?.widthAnchor.constraint(equalToConstant: 44).isActive = true
        lockFocusButton?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
        
        bottomBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor , constant:0).isActive = true
        bottomBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        bottomBarLeftAnchor?.isActive = false
        bottomBarHeightAnchor?.isActive = false

        bottomBarTopAnchor = bottomBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0)
        bottomBarTopAnchor?.isActive = true
        bottomBarWidthAnchor = bottomBar.widthAnchor.constraint(equalToConstant: 100)
        bottomBarWidthAnchor?.isActive = true
        
        settingsLabelWidthAnchorConstraint?.isActive = false
        settingsLabelTopAnchorConstraint?.isActive = false
        
        settingsTextView.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor).isActive = true
        settingsTextView.leftAnchor.constraint(equalTo: bottomBar.leftAnchor).isActive = true
        
        settiongsLabelRightAnchorConstraint = settingsTextView.rightAnchor.constraint(equalTo: bottomBar.rightAnchor)
        settiongsLabelRightAnchorConstraint?.isActive = true
        settingsLabelHeightAnchorConstraint = settingsTextView.heightAnchor.constraint(equalToConstant: 100)
        settingsLabelHeightAnchorConstraint?.isActive = true
        
        
        photoCounterLabelBottomAnchorConstraint?.isActive = false
        photoCounterLabelWidthAnchorConstraint?.isActive = false
        
        photoCounterLabelLeftAnchorConstraint = photoCounterLabel.leftAnchor.constraint(equalTo: bottomBar.leftAnchor)
        photoCounterLabelLeftAnchorConstraint?.isActive = true
        photoCounterLabel.rightAnchor.constraint(equalTo: bottomBar.rightAnchor).isActive = true
        
        photoCounterLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor).isActive = true
        photoCounterLabelHeightAnchorConstraint = photoCounterLabel.heightAnchor.constraint(equalToConstant: 100)
        photoCounterLabelHeightAnchorConstraint?.isActive = true
        
    }
    
    
    

}

