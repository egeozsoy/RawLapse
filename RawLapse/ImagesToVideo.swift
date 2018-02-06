//
//  ImagesToVideo.swift
//  RawLapse
//
//  Created by Ege on 02.12.17.
//  Copyright © 2017 Ege. All rights reserved.
//


import AVFoundation
import UIKit
import Photos

class ImagesToVideo: NSObject {
}

struct RenderSettings {
    
    var width: CGFloat = 3840
    var height: CGFloat = 2160
    var fps: Int32 = 24
    var avCodecKey = AVVideoCodecType.hevc
//    give option for h264
    var videoFilename = "Timelapse1"
    var videoFilenameExt = "mp4"
    
    init(orientation imageOrientation : UIImageOrientation , quality res : String , width imageWidth: Int , height imageHeight: Int) {
        switch res {
        
        case "4K":
                if imageWidth > imageHeight {
                    self.width = 3840
                    self.height = 2160
                }
                else {
                    self.width = 2160
                    self.height = 3840
                }
            
        case "1080p":
            if imageOrientation.rawValue == 0 || imageOrientation.rawValue == 1 {
                width = 1920
                height = 1080
            }
            else {
                width = 1080
                height = 1920
            }
            
        default:
            if imageOrientation.rawValue == 0 || imageOrientation.rawValue == 1 {
                width = 1920
                height = 1080
            }
            else {
                width = 1080
                height = 1920
            }
        }
    }
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    var outputURL: NSURL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt) as NSURL
        }
        fatalError("URLForDirectory() failed")
    }
}

class ImageAnimator {
    
    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    static let kTimescale: Int32 = 600
    
    let settings: RenderSettings
    let videoWriter: VideoWriter
    var images: [URL]!
    var frameNum = 0
    
    class func saveToLibrary(videoURL: NSURL) {
        PHPhotoLibrary.requestAuthorization { status in
            
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                print("here")
                print("Video URl \(videoURL)")
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL as URL)
                
            }) { success, error in
                if !success {
//                    print("Could not save video to photo library:", error)
                }
            }
        }
    }
    
    class func removeFileAtURL(fileURL: NSURL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path!)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
        }
    }
    
    init(renderSettings: RenderSettings , imagesArray: [URL]) {
        settings = renderSettings
        videoWriter = VideoWriter(renderSettings: settings)
        images = imagesArray
    }
    
    func render(completion: @escaping ()->Void) {
        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        ImageAnimator.removeFileAtURL(fileURL: settings.outputURL)
        
        videoWriter.start()
        videoWriter.render(appendPixelBuffers: appendPixelBuffers) {
            
            ImageAnimator.saveToLibrary(videoURL: self.settings.outputURL)
            completion()
        }
    }
    
    // This is the callback function for VideoWriter.render()
    func appendPixelBuffers(writer: VideoWriter) -> Bool {
        let frameDuration = CMTimeMake(Int64(ImageAnimator.kTimescale / settings.fps), ImageAnimator.kTimescale)
        
        while !images.isEmpty {
            if writer.isReadyForData == false {
                // Inform writer we have more buffers to write.
                return false
            }
            do {
                let imageDataUrl = images.removeFirst()
                let imageData = try Data(contentsOf: imageDataUrl)
                let image = UIImage(data: imageData)!
//                print(image.imageOrientation.rawValue)
                let presentationTime = CMTimeMultiply(frameDuration, Int32(frameNum))
                print("FrameNum: \(frameNum)")
                let success = videoWriter.addImage(image: image, withPresentationTime: presentationTime)
                if success == false {
                    fatalError("addImage() failed")
                }
                frameNum += 1
            }
            catch{
            }
        }
        // Inform writer all buffers have been written.
        return true
    }
}

func createMatchingBackingDataWithImage(imageRef: CGImage?, orienation: UIImageOrientation) -> CGImage? {
    var orientedImage: CGImage?
    
    if let imageRef = imageRef {
        let originalWidth = imageRef.width
        let originalHeight = imageRef.height
        let bitsPerComponent = imageRef.bitsPerComponent
        let bytesPerRow = imageRef.bytesPerRow
        
        let colorSpace = imageRef.colorSpace
        let bitmapInfo = imageRef.bitmapInfo
        
        var degreesToRotate: Double
        var swapWidthHeight: Bool
        var mirrored: Bool
        switch orienation {
        case .up:
            degreesToRotate = 0.0
            swapWidthHeight = false
            mirrored = false
            break
        case .upMirrored:
            degreesToRotate = 0.0
            swapWidthHeight = false
            mirrored = true
            break
        case .right:
            degreesToRotate = 90.0
//            swapWidthHeight = true
            swapWidthHeight = false
            mirrored = false
            break
        case .rightMirrored:
            degreesToRotate = 90.0
//            swapWidthHeight = true
            swapWidthHeight = false
            mirrored = true
            break
        case .down:
            degreesToRotate = 180.0
            swapWidthHeight = false
            mirrored = false
            break
        case .downMirrored:
            degreesToRotate = 180.0
            swapWidthHeight = false
            mirrored = true
            break
        case .left:
            degreesToRotate = -90.0
            swapWidthHeight = true
//            swapWidthHeight = false
            mirrored = false
            break
        case .leftMirrored:
            degreesToRotate = -90.0
//            swapWidthHeight = true
            swapWidthHeight = false
            mirrored = true
            break
        }
        let radians = degreesToRotate * Double.pi / 180
        
        var width: Int
        var height: Int
        if swapWidthHeight {
            width = originalHeight
            height = originalWidth
        } else {
            width = originalWidth
            height = originalHeight
        }
        
        if let contextRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue) {
            
            contextRef.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
            if mirrored {
                contextRef.scaleBy(x: -1.0, y: 1.0)
            }
            contextRef.rotate(by: CGFloat(radians))
            if swapWidthHeight {
                contextRef.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
            } else {
                contextRef.translateBy(x: -CGFloat(width) / 2.0, y: -CGFloat(height) / 2.0)
            }
            contextRef.draw(imageRef, in: CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight))
            
            orientedImage = contextRef.makeImage()
        }
    }
    return orientedImage
}

class VideoWriter {
    
    let renderSettings: RenderSettings
    
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }
    
    class func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
//        jpeg portrait mode size differences with CGContext
        
        //flip image if false
        var newImage: CGImage?
        
        if  image.imageOrientation.rawValue == 1 {
            print("Upside Down Fix")
            newImage = createMatchingBackingDataWithImage(imageRef: image.cgImage, orienation: .down)
        }
        else if  image.imageOrientation.rawValue == 3 {
//            print("Portrait Fix")
            newImage = createMatchingBackingDataWithImage(imageRef: image.cgImage, orienation: .left)
        }
        else {
            print("No Fix")
            newImage = image.cgImage
        }
        
        
        var pixelBufferOut: CVPixelBuffer?
        
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }
        let pixelBuffer = pixelBufferOut!
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        //        context.
        context!.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        //        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        
        let x = CGFloat(-(newSize.width - size.width)/4)
        let y = CGFloat(-(newSize.height - size.height)/4)
        let newWidth = newSize.width - (newSize.width - size.width)/2
        let newHeight = newSize.height - (newSize.height - size.height)/2
        context?.draw(newImage!, in: CGRect(x: x, y: y, width: newWidth, height: newHeight))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }
    
    func start() {
        
      
        
        let avOutputSettings: [String: AnyObject] = [
            AVVideoCodecKey: renderSettings.avCodecKey as AnyObject,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.height))
            ]
            
            
       
        
        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.height))
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }
        
        func createAssetWriter(outputURL: NSURL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL as URL, fileType: AVFileType.mp4) else {
                fatalError("AVAssetWriter() failed")
            }
            
            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
                fatalError("canApplyOutputSettings() failed")
            }
            return assetWriter
        }
        
        videoWriter = createAssetWriter(outputURL: renderSettings.outputURL)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        else {
            fatalError("canAddInput() returned false")
        }
        
        // The pixel buffer adaptor must be created before we start writing.
        createPixelBufferAdaptor()
        
        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }
        
        videoWriter.startSession(atSourceTime: kCMTimeZero)
        
        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }
    
    func render(appendPixelBuffers: @escaping (VideoWriter)->Bool, completion: @escaping ()->Void) {
        
        precondition(videoWriter != nil, "Call start() to initialze the writer")
        
        let queue = DispatchQueue(label: "mediaInputQueue")
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            let isFinished = appendPixelBuffers(self)
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting() {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
            else {
                // Fall through. The closure will be called again when the writer is ready.
            }
        }
    }
    
    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        
        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")
        
        let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
}


