//
//  PickerViewController.swift
//  RawLapse
//
//  Created by Ege on 22.10.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController , UIPickerViewDelegate , UIPickerViewDataSource {
    
    var pickerViewList1 =  [String]()
    var pickerViewList2 =  [String]()
    
//    var secondInterval:Int = 3
//    var amountOfPhotos: Int = 10
//    var continuous: Bool = false
    
    var secondInterval:Int {
        get{
            if UserDefaults.standard.integer(forKey: "secondInterval") == 0{
                return 3
            }
            return UserDefaults.standard.integer(forKey: "secondInterval")
        }
        set{ UserDefaults.standard.set(newValue, forKey: "secondInterval")}
    }
    var amountOfPhotos: Int {
        get{
            if UserDefaults.standard.integer(forKey: "amountOfPhotos") == 0{
                return 50
            }
            return UserDefaults.standard.integer(forKey: "amountOfPhotos")}
        set{UserDefaults.standard.set(newValue, forKey: "amountOfPhotos")}
    }
    var continuous: Bool {
        get{return UserDefaults.standard.bool(forKey: "continuous")}
        set{UserDefaults.standard.set(newValue, forKey: "continuous")}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setupArrays(){
        for x in 1...120{
            if(x <= 10 || x % 5 == 0){
                pickerViewList1.append("\(x)")
            }
        }
        
        for y in 10...300 {
            if(y % 10 == 0){
                pickerViewList2.append("\(y)")
            }
            
        }
        pickerViewList2.append("BULB")
        
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //    colored text
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if pickerView.tag == 1{
            return NSAttributedString(string: pickerViewList1[row], attributes: [NSAttributedStringKey.foregroundColor : UIColor.white])
        }
        else{
            return NSAttributedString(string: pickerViewList2[row], attributes: [NSAttributedStringKey.foregroundColor : UIColor.white])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1{
            print(pickerViewList1[row])
            secondInterval = Int(pickerViewList1[row])!
        }
        else{
            print(pickerViewList2[row])
            if(pickerViewList2[row] == "BULB"){
                continuous = true
            }else{
                continuous = false
                amountOfPhotos = Int(pickerViewList2[row])!
            }
        }
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        setupArrays()
        if pickerView.tag == 1{
            return pickerViewList1.count
        }else{
            return pickerViewList2.count
        }
    }
}
