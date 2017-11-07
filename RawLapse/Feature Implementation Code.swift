//
//  Feature Implementation Code.swift
//  RawLapse
//
//  Created by Ege on 27.10.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import Foundation

/*
 
 
func handleIsoTooHigh(){
    
    let currentShutter = currentCamera?.exposureDuration
    var newIso = currentCamera!.iso
    var newShutter = currentShutter
    if currentCamera!.iso > 160{
        print("iso was 160")
        newIso = currentCamera!.iso / 4
        newShutter = CMTimeMultiplyByRatio(currentShutter!, 4, 1)
        if newShutter! > currentCamera!.activeFormat.maxExposureDuration {
            newShutter = currentCamera!.activeFormat.maxExposureDuration
        }
        try? currentCamera?.lockForConfiguration()
        currentCamera?.setExposureModeCustom(duration: newShutter!, iso: newIso, completionHandler: { (time) in
            self.updateLabels()
        })
        currentCamera?.unlockForConfiguration()
    }else if currentCamera!.iso > 80{
        print("iso was 80")
        newIso = currentCamera!.iso / 2
        newShutter = CMTimeMultiplyByRatio(currentShutter!, 2, 1)
        if newShutter! > currentCamera!.activeFormat.maxExposureDuration {
            newShutter = currentCamera!.activeFormat.maxExposureDuration
        }
        try? currentCamera?.lockForConfiguration()
        currentCamera?.setExposureModeCustom(duration: newShutter!, iso: newIso, completionHandler: { (time) in
            self.updateLabels()
        })
        currentCamera?.unlockForConfiguration()

    }




}
 
*/
