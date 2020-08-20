//
//  AddLocationTableViewCell.swift
//  
//
//  Created by Kaan Karay on 10.08.2020.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseCore

class AddLocationTableViewCell: UITableViewCell {
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var secondLabel: UILabel!
  @IBOutlet var buttonOutlets: [UIButton]!
  @IBOutlet var voucherOutlets: [UILabel]!
  @IBOutlet var crownIcon: UIImageView!
  @IBOutlet var blockadeView: UIView!
  
  var vouchers:Array<String> = []
  var ID:Int = 0
  var title:String = ""
  var coordinates:Array<Double> = []
  var vouchersGosspUsers:Array<GosspUser> = []
  var customSuperview: VouchingViewController?
  var color:UIColor = UIColor()
  var colorCGFloat:Array<CGFloat> = []
  var mapMarker = GMSCircle()
  
  @IBAction func checkButtonAct(_ sender: Any) {
    
    if vouchers.first == currentUser.name {
      //Create location. User is the owner. 5 Users vouched.
      ref.child("locations").child("value\(ID)").setValue([
        "name": title,
        "ID":ID,
        "coordinates":coordinates,
        "contCount":vouchers,
        "vouchers":vouchers,
        "GosspArray":[],
        "colors":colorCGFloat,
        "creator":currentUser.name
        
      ]){
        (error:Error?, ref:DatabaseReference) in
        if let error = error {
          print("Data could not be saved: \(error).")
        } else {
          print("Data saved successfully!")
          currentUser.enlistedLocations.append(self.ID)
          currentUser.vouchableDate = Date().addingTimeInterval(timeoutsInDays().creatingLocation).timeIntervalSince1970
          currentUser.updateCloud()
          self.customSuperview?.addButtonCheck()
        }
      }
      
    } else {
      //Since user can see it, he can vouch. Warn first.
      let p = warningAlert()
      p.addAction(UIAlertAction(title: "I understand and would like to proceed.", style: .destructive, handler: { (action) in
        self.vouchers.append(currentUser.name)
        currentUser.vouchableDate = Date().addingTimeInterval(timeoutsInDays().vouching).timeIntervalSince1970
        currentUser.enlistedLocations.append(self.ID)
        currentUser.updateCloud()
        self.customSuperview?.addButtonCheck()
        ref.child("candidateLocation").child("value\(self.ID)").child("vouchers").setValue(self.vouchers){
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Data could not be saved: \(error).")
          } else {
            print("Data saved successfully!")
            DispatchQueue.main.async {self.customSuperview?.tableViewContent.reloadData()}
          }
        }
      }))
      p.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
      customSuperview?.present(p, animated: true)
    }
  }
  
  @IBAction func deleteButtonAct(_ sender: Any) {
    currentUser.vouchableDate = 0
    currentUser.enlistedLocations.remove(at: currentUser.enlistedLocations.firstIndex(of: self.ID)!)
    currentUser.updateCloud()
    customSuperview?.addButtonCheck()
    self.customSuperview?.vouchLocation = []
    self.customSuperview?.locationManager.requestLocation()
    if vouchers.count == 1{
      //We can delete the location.
      ref.child("candidateLocation").child("value\(ID)").removeValue()
      counters.locationCount -= 1
      counters.updateCloud()
      mapMarker.radius = 0
      
    } else {
      vouchers.remove(at: vouchers.firstIndex(of: currentUser.name)!)
      ref.child("candidateLocation").child("value\(ID)").child("vouchers").setValue(vouchers)
    }
    
  }
  
  func setLocations() {
    //MARK: Setting locations
    var widthToWork = frame.size.width
    let distancesBetweenVouchers:CGFloat = 4
    widthToWork -= buttonOutlets[1].frame.width //48
    widthToWork -= 20 // Left anchor.
    widthToWork -= (distancesBetweenVouchers * 3)
    widthToWork -= 4 // Distance to delete button
    widthToWork /= 4
    
    for k in 0...4 {voucherOutlets[k].text = "";voucherOutlets[k].textColor = UIColor.white}
    
    voucherOutlets[1].frame = CGRect(x: (20), y: 52, width: (widthToWork), height: 16)
    voucherOutlets[2].frame = CGRect(x: (20 + (widthToWork + distancesBetweenVouchers)),
                                     y: 52, width: (widthToWork), height: 16)
    
    voucherOutlets[3].frame = CGRect(x: (20 + ((widthToWork + distancesBetweenVouchers) * 2)),
                                     y: 52, width: (widthToWork), height: 16)
    
    voucherOutlets[4].frame = CGRect(x: (20 + ((widthToWork + distancesBetweenVouchers) * 3)),
                                     y: 52, width: (widthToWork), height: 16)
    
    titleLabel.frame = CGRect(x: 20, y: 11, width: (((widthToWork) + (distancesBetweenVouchers))*3), height: 32)
    //secondLabel.frame = CGRect(x: 20, y: 40, width: (((widthToWork) + (distancesBetweenVouchers))*3), height: 9)
    
    voucherOutlets[0].frame = CGRect(x: (20 + ((widthToWork + distancesBetweenVouchers) * 3)),
                                     y: 19, width: (widthToWork), height: 16)
    
    crownIcon.frame = CGRect(x: (20 + ((widthToWork + distancesBetweenVouchers) * 3) + (widthToWork/2) - 5),
                             y: 5, width: 10, height: 10)
    
    DispatchQueue.main.async {
      self.titleLabel.text = self.title
      self.titleLabel.textColor = self.color
      if self.vouchers.count != 0{
        for k in 0...(self.vouchers.count - 1) {
          ref.child("users").child(self.vouchers[k]).observeSingleEvent(of: .value) { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let user = GosspUser(value: value ?? [:])
            self.voucherOutlets[k].text = user.name
            self.voucherOutlets[k].textColor = user.color()
            self.vouchersGosspUsers.append(user)
          }
        }
      }
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    preservesSuperviewLayoutMargins = false
    separatorInset = UIEdgeInsets.zero
    layoutMargins = UIEdgeInsets.zero
    //setLocations()
    buttonOutlets[0].tintColor = .gosspGreen
    blockadeView.backgroundColor = .gosspPurple
    secondLabel.textColor = .white
    voucherOutlets.forEach{
      //$0.text = randomString(length: 8)
      //$0.textColor = randomColor()
      $0.backgroundColor = .gosspLightGray
      
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
