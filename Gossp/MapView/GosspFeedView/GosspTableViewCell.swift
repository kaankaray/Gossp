//
//  GosspTableViewCell.swift
//  Gossp
//
//  Created by Kaan Karay on 10.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit

class GosspTableViewCell: UITableViewCell {
  
  @IBOutlet var voteButtonsOutlet: [UIButton]!
  var GosspReal:Gossp = Gossp()
  var selectedLocation:GosspLocation = GosspLocation()
  var currentUser:GosspUser = GosspUser()
  var indexPathRowCell:Int = 0
  @IBOutlet var voteCountLabel: UILabel!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var contextTextView: UITextView!
  @IBOutlet var cellImageView: UIImageView!
  @IBOutlet var commentImage: UIImageView!
  @IBOutlet var commentsCountLabel: UILabel!
  @IBOutlet var creatorCell: UILabel!
  
  @IBAction func upVoteArrow(_ sender: Any) {
    voteButtonsOutlet[0].animateBounceTwice()
    randTaptic(5)
    if voteButtonsOutlet[0].imageView?.image == UIImage(named: "arrowUp.png"){
      //Not upvoted.
      if voteButtonsOutlet[1].imageView?.image == UIImage(named: "arrowDownFilled.png"){
        //Downvoted and will upvote.
        GosspReal.downVotes.removeAll(where: {$0.pNumber == currentUser.pNumber})
        voteButtonsOutlet[1].setImage(UIImage(named: "arrowDown.png"), for: .normal)
      }
      voteButtonsOutlet[0].setImage(UIImage(named: "arrowUpFilled.png"), for: .normal)
      GosspReal.upVotes.append(currentUser)
      
    } else {
      //Upvoted, will remove user from upvoters.
      GosspReal.upVotes.removeAll(where: {$0.pNumber == currentUser.pNumber})
      voteButtonsOutlet[0].setImage(UIImage(named: "arrowUp.png"), for: .normal)
    }
    //Update cloud.
    voteCountLabel.text = "\(GosspReal.upVotes.count - GosspReal.downVotes.count)"
    var upUsers:Array<Dictionary<String, Any>> = []
    var downUsers:Array<Dictionary<String, Any>> = []
    GosspReal.upVotes.forEach{upUsers.append($0.returnAsDictionary())}
    GosspReal.downVotes.forEach{downUsers.append($0.returnAsDictionary())}
    
    ref.child("locations").child("value\(selectedLocation.ID)").child("GosspArray").child("\(GosspReal.ID)").child("upVotes").setValue(upUsers)
    ref.child("locations").child("value\(selectedLocation.ID)").child("GosspArray").child("\(GosspReal.ID)").child("downVotes").setValue(downUsers)
  }
  
  @IBAction func downVoteArrow(_ sender: Any) {
    voteButtonsOutlet[1].animateBounceTwice()
    randTaptic(4)
    if voteButtonsOutlet[1].imageView?.image == UIImage(named: "arrowDown.png"){
      //Not downvoted.
      if voteButtonsOutlet[0].imageView?.image == UIImage(named: "arrowUpFilled.png"){
        //Upvoted and will downvote.
        GosspReal.upVotes.removeAll(where: {$0.pNumber == currentUser.pNumber})
        voteButtonsOutlet[0].setImage(UIImage(named: "arrowUp.png"), for: .normal)
      }
      voteButtonsOutlet[1].setImage(UIImage(named: "arrowDownFilled.png"), for: .normal)
      GosspReal.downVotes.append(currentUser)
      
    } else {
      //Downvoted, will remove user from downvoters.
      GosspReal.downVotes.removeAll(where: {$0.pNumber == currentUser.pNumber})
      voteButtonsOutlet[1].setImage(UIImage(named: "arrowDown.png"), for: .normal)
    }
    voteCountLabel.text = "\(GosspReal.upVotes.count - GosspReal.downVotes.count)"
    var upUsers:Array<Dictionary<String, Any>> = []
    var downUsers:Array<Dictionary<String, Any>> = []
    GosspReal.upVotes.forEach{upUsers.append($0.returnAsDictionary())}
    GosspReal.downVotes.forEach{downUsers.append($0.returnAsDictionary())}
    
    ref.child("locations").child("value\(selectedLocation.ID)").child("GosspArray").child("\(GosspReal.ID)").child("upVotes").setValue(upUsers)
    ref.child("locations").child("value\(selectedLocation.ID)").child("GosspArray").child("\(GosspReal.ID)").child("downVotes").setValue(downUsers)
  }
  
  func setDisplay() {
    titleLabel.text = GosspReal.subject
    contextTextView.text = GosspReal.context
    creatorCell.textColor = GosspReal.creator.color()
    creatorCell.text = GosspReal.creator.name
    GosspReal.creator = selectedLocation.findUser(withName: GosspReal.creator.name)
    selectedLocation.contCount.forEach{$0.printUser()}
    GosspReal.creator.printUser()
    let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: GosspReal.creator.name)
    if GosspReal.creator.isDeleted {
      attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle,
                                   value: 1, range: NSMakeRange(0, attributeString.length))
      creatorCell.attributedText = attributeString
    } else {creatorCell.attributedText = nil;creatorCell.text = GosspReal.creator.name}
    
    
    voteCountLabel.text = "\(GosspReal.upVotes.count - GosspReal.downVotes.count)"
    voteButtonsOutlet[0].setImage(UIImage(named: "arrowUp.png"), for: .normal)
    voteButtonsOutlet[1].setImage(UIImage(named: "arrowDown.png"), for: .normal)
    GosspReal.upVotes.forEach{if $0.pNumber == accPNumber {voteButtonsOutlet[0].setImage(UIImage(named: "arrowUpFilled.png"), for: .normal)}}
    GosspReal.downVotes.forEach{if $0.pNumber == accPNumber {voteButtonsOutlet[1].setImage(UIImage(named: "arrowDownFilled.png"), for: .normal)}}
    storageRef.child("locations").child("value\(selectedLocation.ID)").child("GosspArray").child(String(GosspReal.ID) + ".png").getData(maxSize: 4 * 1024 * 1024) { data, error in
      DispatchQueue.main.async {
        if error != nil {
          //There is no photo. Hiding UIImageView.
          print(error?.localizedDescription ?? "Smth went wrong when downloading image of a Gossp cell.")
        } else {
          //Use photo
          self.cellImageView.image = UIImage(data: data!)
          self.contextTextView.translatesAutoresizingMaskIntoConstraints = true
          UIView.animate(withDuration: 0.3) {
            self.contextTextView.frame = CGRect(x: 66, y: self.contextTextView.frame.origin.y, width: self.frame.size.width - 174, height: self.contextTextView.bounds.height)
          }
        }
      }
      
    }
    
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    backgroundColor = .gosspPurple
    titleLabel.textColor = .gosspGreen
    creatorCell.backgroundColor = .gosspLightGray
    voteCountLabel.textColor = .gosspGreen
    commentsCountLabel.textColor = .white
    contextTextView.backgroundColor = .gosspPurple
    contextTextView.textColor = .white
    //setDisplay()
    
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
}
