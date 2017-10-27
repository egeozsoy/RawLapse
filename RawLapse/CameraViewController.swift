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
    var startBrightness : CGFloat?
    
    
    var uuid: String?
    
    
    let shutterButton: UIButton = {
        let button = UIButton()
        var image = UIImage(named: "shutter_icon")
        image = image?.withRenderingMode(.alwaysTemplate)
        button.tintColor = UIColor.white
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startTimelapse), for: .touchUpInside)
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


    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    let hudButton:UIButton = {
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
//            let newShutter = CMTimeMultiply(AVCaptureDevice.currentExposureDuration, 0.5)
//            print("Scale \(AVCaptureDevice.currentExposureDuration.timescale)")
            let newShutter = CMTime(seconds: 1/2, preferredTimescale: 0)
            try? currentCamera?.lockForConfiguration()
            currentCamera?.setExposureModeCustom(duration:   newShutter , iso: AVCaptureDevice.currentISO, completionHandler: { (cmtime) in
//
            })
            currentCamera?.unlockForConfiguration()
            let preferedThumbnailFormat = photoSettings?.availableEmbeddedThumbnailPhotoCodecTypes.first
            photoSettings?.embeddedThumbnailPhotoFormat = [AVVideoCodecKey : preferedThumbnailFormat as Any , AVVideoWidthKey : 512 , AVVideoHeightKey: 512]
            photoOutput?.setPreparedPhotoSettingsArray([photoSettings!], completionHandler: nil)
            guard let output = photoOutput else{return}
            captureSession.addOutput(output)
            
        }catch{
            print(error)
        }
    }
    func setupPreviewLayer(){
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft{
            cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        }
        else{
            cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        
        print(self.view.frame)
        
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
        guard let cameraLayer = cameraPreviewLayer else{return}
        let  x = cameraLayer.frame.minX
        let width = cameraLayer.frame.width
        let height = cameraLayer.frame.height
        let wantedHeight = cameraLayer.frame.width * 4/3
        let y = (height - wantedHeight)/2
        cameraPreviewLayerFrame = CGRect(x: x, y: y, width: width , height: wantedHeight)
        
    }
    
    func startRunningCaptureSession(){
        captureSession.startRunning()
        
    }
    
    
    func updateLabels(){
        if let camera = currentCamera {
            settingsTextView.text = "ISO: \(Int(camera.iso))\nShutter: 1/\(Int(1 / (camera.exposureDuration).seconds))\nEV:\(camera.exposureTargetBias)"
            if pickerViewController.continuous  {
            photoCounterLabel.text = "\(photoCounter)/∞"
            }
        else {
        photoCounterLabel.text = "\(photoCounter)/\(pickerViewController.amountOfPhotos)"
        }
        
    }
    }
    
    func lockUnlockExposureFocus(toggleExposure exposureToggle:Bool , toggleFocus focusToggle:Bool){
        if let lockedExposure = lockAEButton?.isSelected  , let lockedFocus = lockFocusButton?.isSelected{
            try? currentCamera?.lockForConfiguration()
            if(exposureToggle){
                if(lockedExposure){
                    currentCamera?.exposureMode = .locked
                }else{
                    currentCamera?.exposureMode = .continuousAutoExposure
                }
            }
            if(focusToggle){
                if(lockedFocus){
                currentCamera?.focusMode = .locked
            }else{
                currentCamera?.focusMode = .continuousAutoFocus
            }
            
        }
            currentCamera?.unlockForConfiguration()
        }
    }
    
    
    func handleExposureFocusTap(_ tap : UITapGestureRecognizer , changeExposure exposureNotLocked: Bool , changeFocus focusNotLocked:Bool){
        
        if(tap.location(in: self.view).y < (self.view.frame.height - cameraPreviewLayerFrame!.height) / 2 || tap.location(in: self.view).y > (self.view.frame.height - cameraPreviewLayerFrame!.height) / 2 + cameraPreviewLayerFrame!.height ){
        }else{
            
            try? currentCamera?.lockForConfiguration()
            let x = tap.location(in: self.view).y / self.view.bounds.size.height
            let y = 1 - tap.location(in: self.view).x / self.view.bounds.size.width
            let point = CGPoint(x: x, y: y)
            if(exposureNotLocked){
                currentCamera?.exposurePointOfInterest = point
                currentCamera?.exposureMode = .continuousAutoExposure
                
            }
            if(focusNotLocked){
                currentCamera?.focusPointOfInterest = CGPoint(x: x, y: y)
                currentCamera?.focusMode = .autoFocus
            }
            currentCamera?.unlockForConfiguration()
        }
        updateLabels()
        
        
    }
    @objc func handleSettingTap(_ tap : UITapGestureRecognizer ){
        if let lockedExposure = lockAEButton?.isSelected , let lockedFocus = lockFocusButton?.isSelected{
            handleExposureFocusTap(tap, changeExposure: !lockedExposure, changeFocus: !lockedFocus)
        }
    }
    
    @objc func handleSwiping(_ swipe: UISwipeGestureRecognizer){
        try? currentCamera?.lockForConfiguration()
        let newExposureBias = swipe.direction == .left ? currentCamera!.exposureTargetBias - 1 : currentCamera!.exposureTargetBias + 1
        if newExposureBias > -6 && newExposureBias < 6{
            currentCamera?.setExposureTargetBias(newExposureBias, completionHandler: { (time) in
                self.updateLabels()
            })
        }
        currentCamera?.unlockForConfiguration()
    }
    
    
//    get preview by putting your hand
    func activateProximitySensor(){
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(adjustBrightness), name: NSNotification.Name.UIDeviceProximityStateDidChange, object: device)
        
    }
    @objc func adjustBrightness(notification: NSNotification){
        let device = notification.object as? UIDevice
        if device?.proximityState == true && activeTimelapse == true{
            UIScreen.main.brightness = 1.0
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) in
                UIScreen.main.brightness = 0.0
                
            })
            
        }
    }
    
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSettingTap(_:))))
        let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwiping(_:)))
        leftSwipeRecognizer.direction = .left
        let rightSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwiping(_:)))
        rightSwipeRecognizer.direction = .right
        
        self.view.addGestureRecognizer(leftSwipeRecognizer)
        self.view.addGestureRecognizer(rightSwipeRecognizer)
        
        
        
        checkCameraAuthorization { (error) in
            
        }
        
        checkPhotoLibraryAuthorization { (error) in
            
        }
        addingView()
        setupPortraitUi()
        startBrightness = UIScreen.main.brightness
        activateProximitySensor()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
        
    }
    
    
    
    @objc func startTimelapse(){
        
        self.amountOfPhotos = pickerViewController.amountOfPhotos
        self.secondInterval = pickerViewController.secondInterval
        self.continuous = pickerViewController.continuous
        let currentScreenBrightness = UIScreen.main.brightness
        print("timelapse called")
        startBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 0.0
        if(activeTimelapse == false){
            activeTimelapse = true;
            shutterButton.tintColor = UIColor.red
//            how to use the timer
            timelapseTimer =  Timer.scheduledTimer(withTimeInterval: TimeInterval(secondInterval!), repeats: true) { (timer) in
                
                if(self.photoCounter <= self.amountOfPhotos! || self.continuous!){
                self.takePhoto()
                self.photoCounter += 1;
                self.updateLabels()
            }
            else{
                    self.timelapseTimer?.invalidate();
                    UIScreen.main.brightness = currentScreenBrightness
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
       
        let uniqueSettings = AVCapturePhotoSettings.init(from: self.photoSettings!)
        photoOutput?.capturePhoto(with: uniqueSettings, delegate: self)
    }
    
    func cachesDirectory() -> URL{
        
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        print(paths[0])
        return paths[0]
    }
    
    func uniqueURL() -> URL{
        if uuid == nil{
        uuid = UUID().uuidString
        }
        var appendString = ""
        if(photoCounter < 10){
            appendString = "0000\(photoCounter)"
        }
        else if(photoCounter < 100){
            appendString = "000\(photoCounter)"
        }
        else if(photoCounter < 1000){
           appendString = "00\(photoCounter)"
        }else if(photoCounter < 10000){
            appendString = "0\(photoCounter)"
        }else{
            appendString = "\(photoCounter)"
        }
        
        let saveString = "IMG-" + uuid! + appendString + ".dng"
        print(saveString)
        return cachesDirectory().appendingPathComponent(saveString)
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if photo.isRawPhoto{
            self.rawPhotoData = photo.fileDataRepresentation()
        }
    }

    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        guard error == nil else{
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
    
    
    
    
    @objc func handleHud(){
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
        lockUnlockExposureFocus(toggleExposure: true, toggleFocus: false)
    }
    @objc func toggleLockFocusButton(){
        lockFocusButton?.isSelected = !(lockFocusButton!.isSelected)
        lockUnlockExposureFocus(toggleExposure: false, toggleFocus: true)
    }
    
    var slimTopBarRightAnchor : NSLayoutConstraint?
    var slimTopBarHeightAnchor: NSLayoutConstraint?
    
    var slimTopBarBottomAnchor: NSLayoutConstraint?
    var slimTopBarWidthAnchor: NSLayoutConstraint?
    var slimTopBarTopAnchor : NSLayoutConstraint?
    var slimTopBarLeftAnchor : NSLayoutConstraint?
    
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
    
    func addingView(){
        if(buttonsSet == false){
            setButtons()
            buttonsSet = true
        }
        
        bottomBar.addSubview(shutterButton)
        self.view.addSubview(slimTopBar)
        self.view.addSubview(bottomBar)
        slimTopBar.addSubview(hudButton)
        slimTopBar.addSubview(lockAEButton!)
        slimTopBar.addSubview(lockFocusButton!)
        bottomBar.addSubview(settingsTextView)
        bottomBar.addSubview(photoCounterLabel)
    }
    
    
    
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
    
    override var shouldAutorotate: Bool{
        return false
    }
    
    
    func setupPortraitUi(){
    
       
        slimTopBarBottomAnchor?.isActive = false
        slimTopBarWidthAnchor?.isActive = false
        
        
        slimTopBarTopAnchor = slimTopBar.topAnchor.constraint(equalTo: self.view.topAnchor , constant:0)
        slimTopBarTopAnchor!.isActive = true
        slimTopBarLeftAnchor = slimTopBar.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        slimTopBarLeftAnchor!.isActive = true
        slimTopBarRightAnchor = slimTopBar.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        slimTopBarRightAnchor!.isActive = true
        slimTopBarHeightAnchor = slimTopBar.heightAnchor.constraint(equalToConstant: 50)
        slimTopBarHeightAnchor!.isActive = true
        print(" My constraints \(slimTopBar.constraints)")

        hudButton.centerXAnchor.constraint(equalTo: slimTopBar.centerXAnchor).isActive = true
        hudButton.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor).isActive = true
        hudButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        hudButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

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




        bottomBarWidthAnchor?.isActive = false
        bottomBarTopAnchor?.isActive = false
        bottomBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor , constant:0).isActive = true
        bottomBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        bottomBarLeftAnchor = bottomBar.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        bottomBarLeftAnchor?.isActive = true

        bottomBarHeightAnchor = bottomBar.heightAnchor.constraint(equalToConstant: 100)
        bottomBarHeightAnchor?.isActive = true

        shutterButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor).isActive = true
        shutterButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor).isActive = true
        shutterButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shutterButton.heightAnchor.constraint(equalToConstant: 44).isActive = true


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

}

