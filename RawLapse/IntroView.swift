//
//  IntroView.swift
//  RawLapse
//
//  Created by Ege on 28.01.18.
//  Copyright © 2018 Ege. All rights reserved.
//

import UIKit

class IntroView: UIView {
    
    let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        var image = UIImage(named: "intro_screen")
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    
    func setupInsideView(){
        addSubview(imageView)
        imageView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    class func introview(inView view: UIView) -> IntroView{
        let width:Double = Double(view.frame.width)
        let height:Double = Double(view.frame.width)
        let x:Double = Double(view.frame.minX)
        let y:Double = Double(view.frame.midY) - height/2
        let frame = CGRect(x: x, y: y, width: width, height: height)
        let introview = IntroView(frame: frame)
        //        hudView.setupInsideHud()
        introview.isOpaque = false
        introview.backgroundColor = UIColor.black
        introview.alpha = 0.6
        introview.layer.cornerRadius = 30
        introview.layer.masksToBounds = true
        introview.animateIn()
        view.addSubview(introview)
        return introview
    }
    
    @objc func animateOut(){
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
