//
//  SettingsTableViewController.swift
//  RawLapse
//
//  Created by Ege on 12.11.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    let cellId = "cellId"
    let screenDiming = "Screen Dimming"
    let ruleOfThirds = "ruleOfThirds"
    lazy var settingsArray = [screenDiming, ruleOfThirds]
    lazy var settingsDic = UserDefaults.standard.dictionary(forKey: "settinsgDic") as? [String: Bool]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(settingCell.self, forCellReuseIdentifier: cellId)
        self.view.backgroundColor = UIColor.black
        
        self.navigationItem.title = "Settings"
        let buttonItem = UIBarButtonItem(title: "OK", style: .plain, target: self, action: #selector(dismissing))
        buttonItem.tintColor = UIColor.white
        navigationItem.rightBarButtonItem = buttonItem
        
        if settingsDic == nil {
            settingsDic = [String:Bool]()
        }
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func dismissing(){
        UserDefaults.standard.set(settingsDic, forKey: "settinsgDic")
        navigationController?.dismiss(animated: true) {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.cameraViewController.setRuleOfThirdsViewer()
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsArray.count
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    @objc func changesOccured(sender: AnyObject){
        let mySwitch = sender as! UISwitch
        settingsDic![settingsArray[mySwitch.tag]] = mySwitch.isOn
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! settingCell
        let settingActive =  UISwitch()
        settingActive.tag = indexPath.row
        settingActive.onTintColor = UIColor.white
        settingActive.thumbTintColor = UIColor.orange
        settingActive.addTarget(self, action: #selector(changesOccured), for: .valueChanged)
        
        cell.accessoryView = settingActive
        cell.settingName.text = settingsArray[indexPath.row]
        if let settingsDic = settingsDic {
            if let isActive = settingsDic[settingsArray[indexPath.row]]{
                settingActive.isOn = isActive
            }
            else{
                settingActive.isOn = false
            }
        }else{
            settingActive.isOn = false
        }
        cell.selectionStyle = .none
        return cell
    }
    
    class settingCell: UITableViewCell {
        let settingName =  UILabel()
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: .default, reuseIdentifier: "cellId")
            self.backgroundColor = UIColor.black
            settingName.translatesAutoresizingMaskIntoConstraints = false
            settingName.textColor = UIColor.white
            settingName.font = UIFont.boldSystemFont(ofSize: 20)
            self.addSubview(settingName)
            settingName.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16).isActive = true
            settingName.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
            settingName.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
            settingName.widthAnchor.constraint(equalToConstant: 200).isActive = true
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

