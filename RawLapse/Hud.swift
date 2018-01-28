//
//  Hud.swift
//  RawLapse
//
//  Created by Ege on 20.10.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import UIKit

class Hud: UIView {
    //    reference to delagate and data source must be at the top / file level
    var pickerController: PickerViewController?
    
    var secondInterval: Int?
    var amountOfPhotos: Int?
    var continuous: Bool?
    
    let testButton:UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        var image = UIImage(named: "pictures_icon")
        button.setBackgroundImage(image, for: .normal)
        button.contentMode = .scaleAspectFit
        return button
    }()
    
    let picturesIconImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        var image = UIImage(named: "timer")
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    
    func setupInsideHud(pickerViewController  pickerVC : PickerViewController){
        self.addSubview(testButton)
        self.addSubview(picturesIconImageView)
        self.pickerController = pickerVC
        let pickerView1 = UIPickerView()
        pickerView1.tag = 1
        pickerView1.dataSource = pickerController
        pickerView1.delegate = pickerController
        pickerView1.translatesAutoresizingMaskIntoConstraints = false
        pickerView1.layer.cornerRadius = 10
        pickerView1.layer.masksToBounds = true
        pickerView1.backgroundColor = UIColor.lightGray
        let currentInterval =  UserDefaults.standard.integer(forKey: "secondInterval")
        if let currentIndex = self.pickerController?.indexOfItem(currentTimerMod: String (currentInterval) ) {
            pickerView1.selectRow(currentIndex, inComponent: 0, animated: true)
        }
        
        
        let pickerView2 = UIPickerView()
        pickerView2.tag = 2
        pickerView2.dataSource = pickerController
        pickerView2.delegate = pickerController
        pickerView2.translatesAutoresizingMaskIntoConstraints = false
        pickerView2.layer.cornerRadius = 10
        pickerView2.layer.masksToBounds = true
        pickerView2.backgroundColor = UIColor.lightGray
        pickerView2.tintColor = UIColor.black
        let conti = UserDefaults.standard.bool(forKey: "continuous")
        if conti {
            if let currentIndex = self.pickerController?.indexOfItem(currentCounterMod: "BULB" ) {
                pickerView2.selectRow(currentIndex, inComponent: 0, animated: true)
            }
        }
        else {
            let currentCounter =  UserDefaults.standard.integer(forKey: "amountOfPhotos")
            if let currentIndex = self.pickerController?.indexOfItem(currentCounterMod: String (currentCounter) ) {
                pickerView2.selectRow(currentIndex, inComponent: 0, animated: true)
            }
        }
        
        self.addSubview(pickerView1)
        self.addSubview(pickerView2)
        
        picturesIconImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16).isActive = true
        picturesIconImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        picturesIconImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        picturesIconImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        pickerView1.leftAnchor.constraint(equalTo: picturesIconImageView.rightAnchor , constant:8).isActive = true
        pickerView1.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        pickerView1.widthAnchor.constraint(equalToConstant: 80).isActive = true
        pickerView1.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        testButton.leftAnchor.constraint(equalTo: pickerView1.rightAnchor, constant: 16).isActive = true
        testButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
        testButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        testButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        pickerView2.leftAnchor.constraint(equalTo: testButton.rightAnchor , constant: 16).isActive = true
        pickerView2.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        pickerView2.widthAnchor.constraint(equalToConstant: 80).isActive = true
        pickerView2.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
    }
    class func hud(inView view: UIView) -> Hud{
        let width:Double = Double(view.frame.width * CGFloat( 0.95))
        let height:Double = 80
        let x:Double = Double(view.frame.midX) - width/2
        let y:Double = Double(view.safeAreaLayoutGuide.layoutFrame.minY + CGFloat(40))
        let frame = CGRect(x: x, y: y, width: width, height: height)
        let hudView = Hud(frame: frame)
        //        hudView.setupInsideHud()
        hudView.isOpaque = false
        hudView.backgroundColor = UIColor.black
        hudView.alpha = 0.6
        hudView.layer.cornerRadius = 20
        hudView.layer.masksToBounds = true
        hudView.animateIn()
        view.addSubview(hudView)
        
        return hudView
    }
    
    func animateOut(){
        alpha = 0.9
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.alpha = 0
        }, completion: nil)
    }
    
    func animateIn(){
        alpha = 0
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.alpha = 0.9
        }, completion: nil)
    }
    
}
