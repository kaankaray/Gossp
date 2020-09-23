//
//  TagableListScrollView.swift
//  Gossp
//
//  Created by Kaan Karay on 28.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit
import Foundation

protocol TagableListScrollViewDelegate: UIScrollViewDelegate {
  // Classes that adopt this protocol MUST define
  // this method -- and hopefully do something in
  // that definition.
  func predictionSelected(_ sender: TagableListScrollView, withNumber:Int)
}

class TagableListScrollView: UIScrollView {
  
  var list:Array<String> = []
  var listColors:Array<UIColor> = []
  var listDeleted:Array<Bool> = []
  var butList:Array<UIButton> = []
  
  
  weak var myDelegate: TagableListScrollViewDelegate?
  override weak var delegate: UIScrollViewDelegate? {didSet {myDelegate = delegate as? TagableListScrollViewDelegate}}
  
  @objc func predictionSelected(_ sender : UIButton){myDelegate?.predictionSelected(self, withNumber: sender.tag)}
  
  func drawButtons() {
    butList.forEach{$0.removeFromSuperview()}
    contentSize = CGSize(width: ((list.count) * 108) + 8, height: Int(self.frame.height))
    if list.count != 0 {
      for k in 0...list.count-1{
        let but = UIButton(type: .system) as UIButton
        but.frame = CGRect(x: ((104 * k) + 4), y: 0, width: 100, height: Int(self.frame.height))
        but.backgroundColor = .gosspLighterPurple
        but.layer.borderColor = UIColor.gosspGreen.cgColor
        but.layer.borderWidth = 1.0
        but.layer.cornerRadius = 8
        
        
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: list[k])
        attributeString.addAttribute(NSAttributedString.Key.foregroundColor, value: listColors[k] , range: NSMakeRange(0, attributeString.length))
        if listDeleted[k] {attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle,
                                                        value: 1, range: NSMakeRange(0, attributeString.length))}
        but.setAttributedTitle(attributeString, for: .normal)
        but.tag = k
        but.addTarget(self, action: #selector(predictionSelected), for: .touchUpInside)
        butList.append(but)
      }
    } else {butList = []}
    
    butList.forEach{self.addSubview($0)}
    
  }
  
  override func draw(_ rect: CGRect) {
    // Drawing code
    showsHorizontalScrollIndicator = false
    backgroundColor = .gosspPurple
    drawButtons()
    
    
    
  }
  
}
