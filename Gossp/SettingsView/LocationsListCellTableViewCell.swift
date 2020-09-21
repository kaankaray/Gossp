//
//  LocationsListCellTableViewCell.swift
//  
//
//  Created by Kaan Karay on 10.08.2020.
//

import UIKit

class LocationsListCellTableViewCell: UITableViewCell {
  
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var contributersLabel: UILabel!
  @IBOutlet var cellImageView: UIImageView!
  @IBOutlet var userIcon: UIImageView!
  @IBOutlet var subscriptionButton: UIButton!
  @IBOutlet var secondLabel: UILabel!
  
  @IBAction func subscriptionButtonAct(_ sender: Any) {
    
    if locationList.contains(gosspLocation.ID){
      randTaptic(1)
      let k = NSMutableAttributedString()
        .normal("Please note that once you ")
        .bold("unsubscribe")
        .normal(" from a Gossp location, you can only subscribe again ")
        .bold("only if")
        .normal(" you are 100 meters near to that Gossp location. And, once you unsubscribe, your ID in your Gossps and in your comments on any Gossps, your name will get strikethough ")
        .crossed("like this")
        .normal(".")
      
      
      let alert = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .actionSheet)
      alert.setValue(k, forKey: "attributedMessage")
      
      alert.addAction(UIAlertAction(title: "Unsubscribe", style: .destructive, handler: { (action) in
        randTaptic(0)
        
        self.subscriptionButton.animateBounceTwice()
        
        
        locationList.remove(at: locationList.firstIndex(of: self.gosspLocation.ID)!)
        for k in 0...self.gosspLocation.contCount.count-1{
          if self.gosspLocation.contCount[k].pNumber == accPNumber{self.gosspLocation.contCount[k].isDeleted = true}
        }
        for k in 0...self.gosspLocation.GosspArray.count-1{
          // Update creators of this user. As deleted.
          if self.gosspLocation.GosspArray[k].creator.pNumber == accPNumber {
            self.gosspLocation.GosspArray[k].creator.isDeleted = true
            ref.child("locations").child("value\(self.gosspLocation.ID)").child("GosspArray").child("creator").setValue(self.gosspLocation.GosspArray[k].creator.returnAsDictionary())
          }
        }
        
        updateAccount()
        self.gosspLocation.updateCloud()
        self.useData(self.gosspLocation)
      }))
      alert.addAction(UIAlertAction(title: "Nevermind", style: .cancel, handler: {(action) in randTaptic(7)}))
      //if customSuperView.allLocations.count != 0{} Will this check work?
      //customSuperViewSocial.present(alert, animated: true)
      customSuperView.present(alert, animated: true)
      
      
    }
    else {
      addOrActivateUser()
      subscriptionButton.animateBounceTwice()
      randTaptic(4)
    }
  }
  
  var gosspLocation:GosspLocation = GosspLocation()
  var customSuperView:MapViewController = MapViewController()
  
  
  
  ///Checks if the user already exists. If exists, reactivates the acc by changing isDeleted to false. If doesn't exist, creates the user.
  func addOrActivateUser() {
    locationList.append(gosspLocation.ID)
    for k in (self.gosspLocation.contCount.count-1) * -1...0{
      if self.gosspLocation.contCount[-k].pNumber == accPNumber{
        self.gosspLocation.contCount[-k].isDeleted = false
        break
      }
      if k == 0 && self.gosspLocation.contCount[-k].pNumber != accPNumber {
        self.gosspLocation.contCount.append(GosspUser.init(withLocation: self.gosspLocation))
      }
    }
    updateAccount()
    gosspLocation.updateCloud()
    useData(gosspLocation)
  }
  
  ///Removes deleted accounts from contributer count and returns it.
  func getRealContributerCount(_ arr:Array<GosspUser>) -> Int{
    var t = arr.count
    arr.forEach{if $0.isDeleted{t -= 1}}
    
    return t
  }
  
  ///Updates the view completely. Adds all the new data.
  func useData(_ loc:GosspLocation) {
    gosspLocation = loc
    
    titleLabel.text = gosspLocation.name
    titleLabel.textColor = gosspLocation.color(alpha: 1)
    contributersLabel.text = String(getRealContributerCount(gosspLocation.contCount))
    secondLabel.text = metersToKM(meters: gosspLocation.distance) + " away."
    if !(gosspLocation.distance < minDistanceToAction) {subscriptionButton.isHidden = true}
    else {subscriptionButton.isHidden = false}
    if locationList.contains(gosspLocation.ID){
      //      subscriptionButton.setTitle("Unsubscribe from this Gossp location.", for: .normal)
      subscriptionButton.setImage(UIImage(named: "starFilled.png"), for: .normal)
      subscriptionButton.tintColor = .systemRed
      subscriptionButton.isHidden = false
    } else {
      //      subscriptionButton.setTitle("Subscribe to this Gossp location.", for: .normal)
      subscriptionButton.setImage(UIImage(named: "star.png"), for: .normal)
      subscriptionButton.tintColor = .gosspGreen
    }
    backgroundColor = .gosspPurple
    contributersLabel.textColor = .gosspGreen
    secondLabel.textColor = .white
    userIcon.tintColor = .gosspGreen
    
    
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    backgroundColor = .gosspPurple
    tintColor = .gosspGreen
    
    
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
