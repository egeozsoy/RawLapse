//
//  PickerViewController.swift
//  RawLapse
//
//  Created by Ege on 22.10.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController , UIPickerViewDelegate , UIPickerViewDataSource {
    
//    second frequency
    var pickerViewList1 =  [String]()
    
//    time limit minutes
    var pickerViewList2 =  [String]()
    
    var secondInterval:Int = 3
    var amountOfPhotos: Int = 10
    var continuous: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupArrays(){
        for x in 1...120{
            if(x <= 10 || x % 5 == 0){
            pickerViewList1.append("\(x)")
            }
            
        }
        
        for y in 5...300 {
            if(y % 5 == 0){
            pickerViewList2.append("\(y)")
            }
            
        }
        pickerViewList2.append("BULB")
        
    }
        
    
    
    
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
//        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//
//        }
    
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
