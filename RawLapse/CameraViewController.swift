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
        tv.textAlignment = .center
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool{
        return false
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
        label.textAlignment = .center
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
            guard let currentCamera = currentCamera else {
                return
            }
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            let rawFormatType = kCVPixelFormatType_14Bayer_RGGB
            photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormatType)
            try? currentCamera.lockForConfiguration()
            
            //            forces maximum shutter speed for best lowlight
            currentCamera.setExposureModeCustom(duration: currentCamera.activeFormat.maxExposureDuration, iso: currentCamera.activeFormat.minISO, completionHandler: nil)
            
            currentCamera.exposureMode = .continuousAutoExposure
            updateLabels()
            currentCamera.unlockForConfiguration()
            guard let photoSettings = photoSettings else{
                print("no photo settings")
                return
            }
            let preferedThumbnailFormat = photoSettings.availableEmbeddedThumbnailPhotoCodecTypes.first
            photoSettings.embeddedThumbnailPhotoFormat = [AVVideoCodecKey : preferedThumbnailFormat as Any , AVVideoWidthKey : 512 , AVVideoHeightKey: 512]
            photoOutput?.setPreparedPhotoSettingsArray([photoSettings], completionHandler: nil)
            guard let output = photoOutput else{return}
            captureSession.addOutput(output)
            
        }catch{
            
        }
    }
    
    func setupPreviewLayer(){
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let cameraPreviewLayer = cameraPreviewLayer else{
            print("no preview layer")
            return
        }
        cameraPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft{
            cameraPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            cameraPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        }
        else{
            cameraPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        
        cameraPreviewLayer.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer, at: 0)
        let  x = cameraPreviewLayer.frame.minX
        let width = cameraPreviewLayer.frame.width
        let height = cameraPreviewLayer.frame.height
        let wantedHeight = cameraPreviewLayer.frame.width * 4/3
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
        guard let cameraPreviewLayerFrame = cameraPreviewLayerFrame else{
            print("no preview layer")
            return
        }
        if(tap.location(in: self.view).y < (self.view.frame.height - cameraPreviewLayerFrame.height) / 2 || tap.location(in: self.view).y > (self.view.frame.height - cameraPreviewLayerFrame.height) / 2 + cameraPreviewLayerFrame.height ){
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
        guard let currentCamera = currentCamera else {
            print("no camera")
            return
        }
        try? currentCamera.lockForConfiguration()
        let newExposureBias = swipe.direction == .left ? currentCamera.exposureTargetBias - 1 : currentCamera.exposureTargetBias + 1
        if newExposureBias > -6 && newExposureBias < 6{
            currentCamera.setExposureTargetBias(newExposureBias, completionHandler: { (time) in
                self.updateLabels()
            })
        }
        currentCamera.unlockForConfiguration()
    }
    
    
    //    get preview by putting your hand
    func toggleProximitySensor(){
        let device = UIDevice.current
        if activeTimelapse{
            device.isProximityMonitoringEnabled = true
            NotificationCenter.default.addObserver(self, selector: #selector(adjustBrightness), name: NSNotification.Name.UIDeviceProximityStateDidChange, object: device)
        }
        else{
            device.isProximityMonitoringEnabled = false
            NotificationCenter.default.removeObserver(self)
        }
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
    
    func keepLabelsUpToDate(){
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.updateLabels()
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
        NotificationCenter.default.addObserver(self, selector: #selector(newOrientation), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
        
        addViews()
        setupUI()
        startBrightness = UIScreen.main.brightness
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
        keepLabelsUpToDate()
        
    }
//    changes button orientation
    @objc func newOrientation(notification: Notification){
        var angle: Double
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.landscapeLeft:
            angle = Double.pi / 2
            break;
        case UIDeviceOrientation.landscapeRight:
            angle = -(Double.pi / 2)
            break;
        default:
            angle = 0
            break;
        }
        
        self.lockAEButton?.transform = CGAffineTransform.init(rotationAngle: CGFloat(angle))
        self.lockFocusButton?.transform = CGAffineTransform.init(rotationAngle: CGFloat(angle))
        self.hudButton.transform = CGAffineTransform.init(rotationAngle: CGFloat(angle))
        self.photoCounterLabel.transform = CGAffineTransform.init(rotationAngle: CGFloat(angle))
        self.settingsTextView.transform = CGAffineTransform.init(rotationAngle: CGFloat(angle))
    }
    
    @objc func startTimelapse(){
        
        self.amountOfPhotos = pickerViewController.amountOfPhotos
        self.secondInterval = pickerViewController.secondInterval
        self.continuous = pickerViewController.continuous
        if startBrightness == nil{
            startBrightness = UIScreen.main.brightness
        }
        
        UIScreen.main.brightness = 0.0
        if(activeTimelapse == false){
            activeTimelapse = true
            toggleProximitySensor()
            shutterButton.tintColor = UIColor.red
            //            how to use the timer
            timelapseTimer =  Timer.scheduledTimer(withTimeInterval: TimeInterval(secondInterval!), repeats: true) { (timer) in
                
                if(self.photoCounter <= self.amountOfPhotos! || self.continuous!){
                    self.takePhoto()
                    self.photoCounter += 1;
                    self.updateLabels()
                    if(self.amountOfPhotos! % 10 == 0){
                        UIScreen.main.brightness = 0.0
                    }
                }
                else{
                    self.timelapseTimer?.invalidate();
                    print("finishing1")
                    UIScreen.main.brightness = self.startBrightness!
                    self.activeTimelapse = false;
                    self.shutterButton.tintColor = UIColor.white
                    self.toggleProximitySensor()
                    return;
                }
            }
        }else{
            activeTimelapse = false;
            toggleProximitySensor()
            print("finishing2")
            shutterButton.tintColor = UIColor.white
            UIScreen.main.brightness = startBrightness!
            timelapseTimer?.invalidate();
            return ;
        }
        
    }
    
    @objc  func takePhoto(){
        
        let uniqueSettings = AVCapturePhotoSettings.init(from: self.photoSettings!)
        self.photoOutput?.capturePhoto(with: uniqueSettings, delegate: self)
        
        
    }
    
    func cachesDirectory() -> URL{

        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
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
        catch{
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
    var settingsLabelRightAnchorConstraint: NSLayoutConstraint?
    var settingsLabelHeightAnchorConstraint: NSLayoutConstraint?
    
    var photoCounterLabelBottomAnchorConstraint: NSLayoutConstraint?
    var photoCounterLabelWidthAnchorConstraint: NSLayoutConstraint?
    var photoCounterLabelLeftAnchorConstraint: NSLayoutConstraint?
    var photoCounterLabelHeightAnchorConstraint: NSLayoutConstraint?
    
    func addViews(){
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
    
    func setupUI(){
        slimTopBarBottomAnchor?.isActive = false
        slimTopBarWidthAnchor?.isActive = false
       
        
        slimTopBarTopAnchor = slimTopBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor , constant:0)
        slimTopBarTopAnchor!.isActive = true
        slimTopBarLeftAnchor = slimTopBar.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        slimTopBarLeftAnchor!.isActive = true
        slimTopBarRightAnchor = slimTopBar.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        slimTopBarRightAnchor!.isActive = true
        slimTopBarHeightAnchor = slimTopBar.heightAnchor.constraint(equalToConstant: 50)
        slimTopBarHeightAnchor!.isActive = true
        
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
        bottomBar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor , constant:0).isActive = true
        bottomBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        bottomBarLeftAnchor = bottomBar.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        bottomBarLeftAnchor?.isActive = true
        
        bottomBarHeightAnchor = bottomBar.heightAnchor.constraint(equalToConstant: 100)
        bottomBarHeightAnchor?.isActive = true
        
        shutterButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor).isActive = true
        shutterButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor).isActive = true
        shutterButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shutterButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        settingsLabelRightAnchorConstraint?.isActive = false
        settingsLabelHeightAnchorConstraint?.isActive = false
        
        settingsTextView.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor).isActive = true
        settingsTextView.leftAnchor.constraint(equalTo: bottomBar.leftAnchor).isActive = true
        settingsTextView.heightAnchor.constraint(equalToConstant: 88).isActive = true
        
        settingsLabelWidthAnchorConstraint = settingsTextView.widthAnchor.constraint(equalToConstant: 100)
        settingsLabelWidthAnchorConstraint?.isActive = true
        
        photoCounterLabelLeftAnchorConstraint?.isActive = false
        photoCounterLabelHeightAnchorConstraint?.isActive = false
        
        photoCounterLabel.rightAnchor.constraint(equalTo: bottomBar.rightAnchor).isActive = true
        photoCounterLabel.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor).isActive = true
        photoCounterLabelWidthAnchorConstraint = photoCounterLabel.widthAnchor.constraint(equalToConstant: 100)
        photoCounterLabelWidthAnchorConstraint?.isActive = true
        photoCounterLabel.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
    }
    
}

