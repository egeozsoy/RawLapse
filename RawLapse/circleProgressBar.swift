//
//  circleProgressBar.swift
//  RawLapse
//
//  Created by Ege on 03.02.18.
//  Copyright © 2018 Ege. All rights reserved.
//
import UIKit

class CircleProgressBar: UIView {
    let shapeLayer = CAShapeLayer()
    var circleProgressBar:CircleProgressBar?
    
    func circleProgressBar(inView view: UIView, photoPercantage percantage: Float) -> CircleProgressBar{
        print("init")
       
        let width:Double = Double(view.frame.width)
        let height:Double = Double(view.frame.width)
        let x:Double = Double(view.frame.minX)
        let y:Double = Double(view.frame.midY) - height/2
        let frame = CGRect(x: x, y: y, width: width, height: height)
        circleProgressBar = CircleProgressBar(frame: frame)
        circleProgressBar?.backgroundColor = UIColor.black
//        drawing circle
        let center = CGPoint(x:(circleProgressBar?.frame.midX)!, y: (view.frame.minY) + CGFloat(height/2))
        let circlePath = UIBezierPath(arcCenter: center, radius: CGFloat(50), startAngle: -CGFloat.pi/2 , endAngle: 2 * CGFloat.pi - CGFloat.pi/2, clockwise: true)
        
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 5
        shapeLayer.strokeEnd = CGFloat(percantage)
        shapeLayer.strokeColor = UIColor.orange.cgColor
        circleProgressBar?.layer.addSublayer(shapeLayer)
        circleProgressBar?.isOpaque = false
        circleProgressBar?.alpha = 0.9
        circleProgressBar?.layer.cornerRadius = 30
        circleProgressBar?.layer.masksToBounds = true
        
        let str = "Please wait while your timelapse is getting processed"
        let textView:UITextView = {
            let tv = UITextView()
            tv.isEditable = false
            tv.backgroundColor = UIColor.clear
            tv.textColor = UIColor.white
            tv.textAlignment = .center
            tv.isSelectable = false
            tv.translatesAutoresizingMaskIntoConstraints = false
            return tv
        }()
        textView.text = str
        textView.font = UIFont.systemFont(ofSize: 20)
        circleProgressBar?.addSubview(textView)
        textView.bottomAnchor.constraint(equalTo: circleProgressBar!.bottomAnchor, constant: -16).isActive = true
        textView.centerXAnchor.constraint(equalTo: circleProgressBar!.centerXAnchor, constant: 0).isActive = true
        textView.widthAnchor.constraint(equalTo: circleProgressBar!.widthAnchor, constant: 0).isActive = true
        textView.heightAnchor.constraint(equalToConstant: 80) .isActive = true
        
        return circleProgressBar!
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

