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
  
  
  var gosspLocation:GosspLocation = GosspLocation()
  var customSuperView:MapViewController = MapViewController()
  var customSuperViewSocial:SocialViewController = SocialViewController()
  
  func useData(_ loc:GosspLocation) {
    gosspLocation = loc
    
      titleLabel.text = gosspLocation.name
      titleLabel.textColor = gosspLocation.color(alpha: 1)
      contributersLabel.text = String(gosspLocation.contCount.count)
      secondLabel.text = String(format: "%.2f", gosspLocation.distance) + " meters away."
      if currentUser.enlistedLocations.contains(gosspLocation.ID){
        subscriptionButton.setTitle("Unsubscribe from this Gossp location.", for: .normal)
        subscriptionButton.tintColor = .systemRed
      } else {
        subscriptionButton.setTitle("Subscribe to this Gossp location.", for: .normal)
        subscriptionButton.tintColor = .gosspGreen
      }
      backgroundColor = .gosspPurple
      contributersLabel.textColor = .gosspGreen
      secondLabel.textColor = .gosspGreen
      userIcon.tintColor = .gosspGreen
    
    
  }
  
  @IBAction func subscriptionButtonAct(_ sender: Any) {
    if currentUser.enlistedLocations.contains(gosspLocation.ID){
      
      let alert = UIAlertController(title: "Are you sure?", message: "Please be advised that once you unsubscribe from a location, you can only subscribe again if you are near to that Gossp location. Users in the location won't know that you left.", preferredStyle: .actionSheet)
      
      alert.addAction(UIAlertAction(title: "Unsubscribe", style: .destructive, handler: { (action) in
        currentUser.enlistedLocations.remove(at: currentUser.enlistedLocations.firstIndex(of: self.gosspLocation.ID)!)
        self.gosspLocation.contCount.remove(at: self.gosspLocation.contCount.firstIndex(of: currentUser.name)!)
        currentUser.updateCloud()
        self.gosspLocation.updateCloud()
        self.useData(self.gosspLocation)
      }))
      alert.addAction(UIAlertAction(title: "Nevermind", style: .cancel, handler: nil))
      //if customSuperView.allLocations.count != 0{} Will this check work?
      //customSuperViewSocial.present(alert, animated: true)
      customSuperView.present(alert, animated: true)
      
      
    }
    else {
      currentUser.enlistedLocations.append(gosspLocation.ID)
      gosspLocation.contCount.append(currentUser.name)
      currentUser.updateCloud()
      gosspLocation.updateCloud()
      useData(gosspLocation)
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
