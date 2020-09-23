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
import MarqueeLabel

class AddLocationTableViewCell: UITableViewCell {
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var secondLabel: MarqueeLabel!
  @IBOutlet var buttonOutlets: [UIButton]!
  @IBOutlet var voucherOutlets: [UILabel]!
  @IBOutlet var crownIcon: UIImageView!
  
  var vouchers:Array<GosspUser> = []
  var ID:Int = 0
  var title:String = ""
  var coordinates:Array<Double> = []
  var subscribedUsers:Array<GosspUser> = []
  var customSuperview: VouchingViewController?
  var color:UIColor = UIColor()
  var colorCGFloat:Array<CGFloat> = []
  var mapMarker = GMSCircle()
  var currentUser = GosspUser()
  var locationAsGosspLocation:GosspLocation = GosspLocation()
  let marker2 = GMSCircle()
  
  @IBAction func checkButtonAct(_ sender: Any) {
    var dictVouchers:Array<Dictionary<String, Any>> = []
    var dictUsers:Array<Dictionary<String, Any>> = []
    vouchers.forEach{dictVouchers.append($0.returnAsDictionary())}
    subscribedUsers.forEach{dictUsers.append($0.returnAsDictionary())}
    buttonOutlets[0].animateBounceTwice()
    if vouchers.first?.pNumber == accPNumber {
      //Create location. User is the owner. 5 Users vouched.
      randTaptic(4)
      let p = ["name": title,
               "ID":ID,
               "coordinates":coordinates,
               "contCount":dictUsers,
               "vouchers":dictVouchers,
               "GosspArray":[],
               "colors":colorCGFloat,
               "creator":vouchers.first!.name,
               "tmp":true] as [String : Any]
      ref.child("candidateLocations").child("value\(self.ID)").setValue(p)
      delay(5){ref.child("candidateLocations").child("value\(self.ID)").removeValue()}
      ref.child("locations").child("value\(ID)").setValue(p){
        (error:Error?, ref:DatabaseReference) in
        if let error = error {
          print("Data could not be saved: \(error).")
        } else {
          print("Data saved successfully!")
          vouchableDateAccount = Date().addingTimeInterval(timeoutsInDays().creatingLocation).timeIntervalSince1970
          locationList.append(self.ID)
          updateAccount()
          self.customSuperview?.addButtonCheck()
        }
      }
      
    } else {
      //Since user can see it, he can vouch. Warn first.
      randTaptic(1)
      let p = warningAlert()
      dictVouchers = []
      dictUsers = []
      let user = GosspUser(withLocation: self.locationAsGosspLocation)
      subscribedUsers.append(user)
      vouchers.append(user)
      vouchers.forEach{dictVouchers.append($0.returnAsDictionary())}
      subscribedUsers.forEach{dictUsers.append($0.returnAsDictionary())}
      p.addAction(UIAlertAction(title: "I understand and would like to proceed.", style: .destructive, handler: { (action) in
        randTaptic(0)
        vouchableDateAccount = Date().addingTimeInterval(timeoutsInDays().vouching).timeIntervalSince1970
        locationList.append(self.ID)
        updateAccount()
        self.customSuperview?.addButtonCheck()
        ref.child("candidateLocations").child("value\(self.ID)").setValue([
          "name": self.title,
          "ID":self.ID,
          "coordinates":self.coordinates,
          "contCount":dictUsers,
          "vouchers":dictVouchers,
          "GosspArray":[],
          "colors":self.colorCGFloat,
          "creator":self.vouchers.first!.name
          ]){
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Data could not be saved: \(error).")
          } else {
            print("Data saved successfully!")
            DispatchQueue.main.async {self.customSuperview?.tableViewContent.reloadData()}
          }
        }
      }))
      p.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
        
        randTaptic(2)
        
        
      }))
      customSuperview?.present(p, animated: true)
    }
  }
  
  @IBAction func deleteButtonAct(_ sender: Any) {
    vouchableDateAccount = 0
    randTaptic(4)
    if locationList.contains(self.ID){locationList.remove(at: locationList.firstIndex(of: self.ID)!)}
    updateAccount()
    customSuperview?.addButtonCheck()
    self.customSuperview?.vouchLocation = []
    self.customSuperview?.locationManager.requestLocation()
    if vouchers.count == 1{
      //We can delete the location.
      ref.child("candidateLocations").child("value\(ID)").removeValue()
      counters.locationCount -= 1
      counters.updateCloud()
      mapMarker.radius = 0
      
    } else {
      for k in 0...vouchers.count-1 {
        if vouchers[k].pNumber == accPNumber{
          vouchers.remove(at: k)
          subscribedUsers.remove(at: k)
          self.voucherOutlets[k].backgroundColor = .gosspLightGray
          break
        }
      }
      var dictVouchers:Array<Dictionary<String, Any>> = []
      var dictUsers:Array<Dictionary<String, Any>> = []
      vouchers.forEach{dictVouchers.append($0.returnAsDictionary())}
      subscribedUsers.forEach{dictUsers.append($0.returnAsDictionary())}
      ref.child("candidateLocations").child("value\(self.ID)").setValue([
        "name": self.title,
        "ID":self.ID,
        "coordinates":self.coordinates,
        "contCount":dictUsers,
        "vouchers":dictVouchers,
        "GosspArray":[],
        "colors":self.colorCGFloat,
        "creator":self.vouchers.first!.name
      ]){
        (error:Error?, ref:DatabaseReference) in
        if let error = error {
          print("Data could not be saved: \(error).")
        } else {
          print("Data saved successfully!")
          DispatchQueue.main.async {self.customSuperview?.tableViewContent.reloadData()}
        }
      }
    }
    
  }
  
  //MARK: Setting locations and values
  func setLocations() {
    var widthToWork = frame.size.width
    let distancesBetweenVouchers:CGFloat = 4
    widthToWork -= buttonOutlets[1].frame.width //48
    widthToWork -= 20 // Left anchor.
    widthToWork -= (distancesBetweenVouchers * 3)
    widthToWork -= 4 // Distance to delete button
    widthToWork /= 4
    
    vouchers = locationAsGosspLocation.vouchers
    subscribedUsers = locationAsGosspLocation.contCount
    coordinates = locationAsGosspLocation.coordinates
    ID = locationAsGosspLocation.ID
    color = locationAsGosspLocation.color(alpha: 1)
    colorCGFloat = locationAsGosspLocation.colors
    title = locationAsGosspLocation.name
    marker2.position = CLLocationCoordinate2D(
      latitude: CLLocationDegrees((locationAsGosspLocation.coordinates[0])),
      longitude: (CLLocationDegrees((locationAsGosspLocation.coordinates[1])))
    )
    marker2.radius = 5
    marker2.fillColor = locationAsGosspLocation.color(alpha: 0.3)
    marker2.strokeWidth = 1
    marker2.strokeColor = locationAsGosspLocation.color(alpha: 0.8)
    marker2.map = customSuperview!.mapView
    subscribedUsers.forEach{if $0.pNumber == accPNumber {currentUser = $0}}
    secondLabel.text = "\(metersToKM(meters: locationAsGosspLocation.distance)) away."
    var vouching = false
    vouchers.forEach{if $0.pNumber == currentUser.pNumber{vouching = true}}
    if vouching {
      customSuperview!.mapFocus(location: coordinates)
      //User vouches and in distance!
      if !(locationAsGosspLocation.distance < minDistanceToSee){
        //User shouldn't be in the list!
        deleteButtonAct(self)
      }
      buttonOutlets[1].isHidden = false
      if vouchers.first?.pNumber == currentUser.pNumber{
        //User is the owner as well!
        if vouchers.count == 5{
          //There are 5 users vouched!
          buttonOutlets[0].isHidden = false
        } else {
          //There are not enough people vouched!
          buttonOutlets[0].isHidden = true
        }
        customSuperview!.locationManager.distanceFilter = 33
      } else {
        //User is not the owner, but here.
        buttonOutlets[0].isHidden = true
        customSuperview!.locationManager.distanceFilter = 33
      }
    } else {
      // User is not here.
      buttonOutlets[1].isHidden = true
      buttonOutlets[0].isHidden = false
      customSuperview!.locationManager.distanceFilter = 3
    }
    if locationAsGosspLocation.distance < minDistanceToAction{buttonOutlets[0].isHidden = false}
    else{
      buttonOutlets[0].isHidden = true
      secondLabel.animationDelay = 3
      secondLabel.fadeLength = 1
      secondLabel.text = "\(metersToKM(meters: locationAsGosspLocation.distance)) away. You have to be in \(minDistanceToAction) meter radius to take any action.          "
      
      
    }
    
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
    print(locationAsGosspLocation.tmp)
    if locationAsGosspLocation.tmp == true {
      //Animate confirmed
      let radius:CGFloat = 90 / 2
      let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width/2, y: frame.size.height/2), radius: radius, startAngle: 0, endAngle: .pi*2, clockwise: true)
      
      
      let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
      animation.duration = 1
      animation.repeatCount = MAXFLOAT
      animation.path = circlePath.cgPath
      
      let centerX = frame.size.width/2
      let centerY = frame.size.height/2
      let cosXYCoord = CGFloat(cos(18 * Double.pi / 180)) * radius //cos18 * radius
      let sinXYCoord = CGFloat(sin(18 * Double.pi / 180)) * radius //sin18 * radius
      let cosXYCoord36 = CGFloat(cos(36 * Double.pi / 180)) * radius * 0.8 //cos18 * radius
      let sinXYCoord36 = CGFloat(sin(36 * Double.pi / 180)) * radius * 0.8 //sin18 * radius
      
      print("CenterX \(centerX)")
      print("CenterY \(centerY)")
      print("cosXYCoord \(cosXYCoord)")
      print("sinXYCoord \(sinXYCoord)")
      print("cosXYCoord36 \(cosXYCoord36)")
      print("sinXYCoord36 \(sinXYCoord36)")
      
      UIView.animate(withDuration: 3) {
        
        self.voucherOutlets[0].center = CGPoint(x: centerX, y: centerY - (radius * 0.6))
        self.voucherOutlets[1].center = CGPoint(x: centerX - cosXYCoord - 5, y: centerY - sinXYCoord + 10)
        self.voucherOutlets[2].center = CGPoint(x: centerX - sinXYCoord36 - 20, y: centerY + cosXYCoord36)
        self.voucherOutlets[3].center = CGPoint(x: centerX + sinXYCoord36 + 20, y: centerY + cosXYCoord36)
        self.voucherOutlets[4].center = CGPoint(x: centerX + cosXYCoord + 5, y: centerY - sinXYCoord + 10)
        self.crownIcon.center = CGPoint(x: centerX, y: centerY)
        
        
      }
      UIView.animate(withDuration: 0.5, delay: 3, options: .curveEaseIn, animations: {
        
        self.crownIcon.frame.size = CGSize(width: self.crownIcon.frame.width * 0.6, height: self.crownIcon.frame.height * 0.6)
        self.crownIcon.center = CGPoint(x: centerX, y: centerY)
      })
      
      UIView.animate(withDuration: 1, delay: 3.5, options: .curveEaseInOut, animations: {
        self.crownIcon.layer.zPosition = 20
        self.crownIcon.frame.size = CGSize(width: self.crownIcon.frame.width * 180, height: self.crownIcon.frame.height * 180)
        self.crownIcon.center = CGPoint(x: centerX, y: centerY)
      }, completion: { (smth) in
        self.customSuperview?.navigationController?.popToRootViewController(animated: true)
      })
      
      
      
    }
    DispatchQueue.main.async {
      self.titleLabel.text = self.title + "  (\(self.vouchers.count)/5)"
      self.titleLabel.textColor = self.color
      self.voucherOutlets.forEach{$0.backgroundColor = .gosspLightGray}
      if self.vouchers.count != 0{
        for k in 0...(self.vouchers.count - 1) {
          if self.vouchers[k].name == self.currentUser.name{self.voucherOutlets[k].backgroundColor = .gosspLighterGray}
          self.voucherOutlets[k].text = self.vouchers[k].name
          self.voucherOutlets[k].textColor = self.vouchers[k].color()
        }
      }
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    preservesSuperviewLayoutMargins = false
    separatorInset = UIEdgeInsets.zero
    layoutMargins = UIEdgeInsets.zero
    backgroundColor = .gosspPurple
    tintColor = .gosspGreen
    buttonOutlets[0].tintColor = .gosspGreen
    secondLabel.textColor = .white
    
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
