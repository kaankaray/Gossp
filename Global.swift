//
//  Global.swift
//  Gossp
//
//  Created by Kaan Karay on 2.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import GoogleMaps
import GooglePlaces


let screenSize: CGRect = UIScreen.main.bounds
// A default location to use when location permission is not granted.
let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
var mapStyle = ""
var ref: DatabaseReference! = Database.database().reference()
let storage = Storage.storage()
let storageRef = storage.reference()
let minDistanceToAction:Double = 100
let minDistanceToSee:Double = 100000

extension UIColor {
  static var gosspGreen:UIColor {return UIColor(red: 28/256, green: 184/256, blue: 35/256, alpha: 1)}
  static var gosspPurple:UIColor {return UIColor(red: 74/256, green: 29/256, blue: 141/256, alpha: 1)}
  static var gosspLighterPurple:UIColor {return UIColor(red: 74/256, green: 29/256, blue: 141/256, alpha: 0.85)}
  static var gosspLightGray:UIColor {return UIColor(white: 1, alpha: 0.3)}
}

extension UILabel{
  
  func animateLongText(frames:CGFloat, duration:Double, delay:Double = 2) {
    UIView.animate(withDuration: duration, delay: delay, options: ([.curveLinear, .repeat, .autoreverse]), animations: {() -> Void in
      self.center = CGPoint(x: self.center.x - (frames/2) + 5, y: self.center.y)
    }, completion:  nil)
  }
}

//MARK: Penalties and their alerts
struct timeoutsInDays {
  var vouching = TimeInterval(86400 * 2)
  var colorChange = TimeInterval(86400 * 3)
  var creatingLocation = TimeInterval(86400 * 5)
  var IDChange = TimeInterval(86400 * 7)
}
let timeoutAlert = UIAlertController(title: "Timeouts", message: "Timeouts to keep the order in Gossp areas and to prevail chaos:\n\nVouching for an approval of a Gossp location has \(timeoutsInDays().vouching/86400) days.\nRe-randomizing your ID color has \(timeoutsInDays().colorChange/86400) days.\nCreating a new Gossp location has \(timeoutsInDays().creatingLocation/86400) days.\nResetting your ID has \(timeoutsInDays().IDChange/86400) days.", preferredStyle: .alert)

func warningAlert() -> UIAlertController {
  return UIAlertController(title: "Are you sure?", message: "Please be advised that you are NOT going to be able to;\n\nVouch for an approval of a Gossp location for \(timeoutsInDays().vouching/86400) days.\nChange your ID color for \(timeoutsInDays().colorChange/86400) days.\nCreate a Gossp location for \(timeoutsInDays().creatingLocation/86400) days.\nChange your Gossp ID for \(timeoutsInDays().IDChange/86400) days.\n", preferredStyle: .actionSheet)
}

//MARK: Random
func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}
func randomColor(alpha:CGFloat = 1) -> UIColor {
  let randomColors = randomColorFloat()
  return UIColor(red: randomColors[0], green: randomColors[1], blue: randomColors[2], alpha: alpha)
}
func randomColorFloat() -> Array<CGFloat>{
  var randomColors = [CGFloat.random(in: 0...0.5),CGFloat.random(in: 0...0.5),CGFloat.random(in: 0...0.5)]
  for k in 0...2 {if randomColors[k] >= 0.25 {randomColors[k] += 0.5}}
  while randomColors[0] + randomColors[1] + randomColors[2] > 2.5 || randomColors[0] + randomColors[1] + randomColors[2] < 1 {
    randomColors = [CGFloat.random(in: 0...0.5),CGFloat.random(in: 0...0.5),CGFloat.random(in: 0...0.5)]
    for k in 0...2 {if randomColors[k] >= 0.25 {randomColors[k] += 0.5}}
  }
  return randomColors
}

//Delay func delay(time)
func delay(_ time: Double, completion: @escaping () -> ()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + time) {
    // Code with delay
    completion()
  }
}

//MARK: Objects
var currentUser = GosspUser()
class GosspUser{
  
  var name:String = ""
  var pNumber:String = ""
  var UID:String = ""
  var colors:Array<CGFloat> = []
  var enlistedLocations:Array<Int> = []
  var vouchableDate:Double = 0
  var isDeleted:Bool = false
  var score:Int = 0
  var playerID:String = ""
  
  init() {}
  
  init(withName: String) {
    ref.child("users").child(withName).observeSingleEvent(of: .value) { (snapshot) in
      let value = snapshot.value as? NSDictionary
      self.name = value?["username"] as? String ?? ""
      self.pNumber = value?["pnumber"] as? String ?? ""
      self.colors = value?["colors"] as? Array<CGFloat> ?? [0,0,0]
      self.UID = value?["UID"] as? String ?? ""
      self.enlistedLocations = value?["locationIDs"] as? Array<Int> ?? []
      self.vouchableDate = value?["vouchableDate"] as? Double ?? 0
      self.isDeleted = value?["isDeleted"] as? Bool ?? false
      self.score = value?["score"] as? Int ?? 0
      self.playerID = value?["playerID"] as? String ?? ""
    }
  }
  
  init(value: NSDictionary) {
    name = value["username"] as? String ?? ""
    pNumber = value["pnumber"] as? String ?? ""
    colors = value["colors"] as? Array<CGFloat> ?? [0,0,0]
    UID = value["UID"] as? String ?? ""
    enlistedLocations = value["locationIDs"] as? Array<Int> ?? []
    vouchableDate = value["vouchableDate"] as? Double ?? 0
    isDeleted = value["isDeleted"] as? Bool ?? false
    score = value["score"] as? Int ?? 0
    playerID = value["playerID"] as? String ?? ""
  }
  
  func color() -> UIColor {return UIColor(red: colors[0], green: colors[1], blue: colors[2], alpha: 1)}
  
  func vouchable() -> Bool {return Date().timeIntervalSince1970 < self.vouchableDate}
  
  func printUser() {
    print("==================================================")
    print("Name: \(name)")
    print("Phone number: \(pNumber)")
    print("UID: \(UID)")
    print("User colors: \(colors)")
    print("Enlisted location IDs: \(enlistedLocations)")
    print("Score: \(score)")
    print("Can vouch, change color, change name after: \(Date.init(timeIntervalSince1970: vouchableDate))")
    print("PlayerID for notifications: \(playerID)")
    print("Deleted?: \(isDeleted)")
    print("==================================================")
  }
  
  func updateCloud() {
    ref.child("users").child(name).setValue([
      "username": name,
      "pnumber": pNumber,
      "uid":UID,
      "locationIDs":enlistedLocations,
      "colors": colors,
      "vouchableDate":vouchableDate,
      "isDeleted": isDeleted,
      "score": score,
      "playerID": playerID
    ])
  }
  
  
}

class GosspLocation{
  var ID: Int = 0
  var name: String = ""
  var coordinates: Array<Double> = [0,0]
  var contCount: Array<String> = []
  var vouchers:Array<String> = []
  var GosspArray: Array<Int> = []
  var colors: Array<CGFloat> = [0,0,0]
  var creator: String = ""
  var distance: Double = 0
  
  private var maxCircleRadius:Double = 40
  private var minCircleRadius:Double = 8
  private var maxPeopleToReachMaxRadius:Double = 1000
  
  init() {}
  
  init(rawValue:NSDictionary) {
    //Use this to fill the data
    ID = rawValue["ID"] as? Int ?? 0
    name = rawValue["name"] as? String ?? ""
    coordinates = rawValue["coordinates"] as? Array<Double> ?? []
    contCount = rawValue["contCount"] as? Array<String> ?? []
    vouchers = rawValue["vouchers"] as? Array<String> ?? []
    GosspArray = rawValue["GosspArray"] as? Array<Int> ?? []
    colors = rawValue["colors"] as? Array<CGFloat> ?? [0,0,0]
    creator = rawValue["creator"] as? String ?? ""
  }
  
  func color(alpha:Double) -> UIColor {return UIColor(red: colors[0], green: colors[1], blue: colors[2], alpha: CGFloat(alpha))}
  func returnAsDictionary() -> Dictionary<String, Any> {
    return [
      "name": name,
      "ID":ID,
      "coordinates":coordinates,
      "contCount":contCount,
      "vouchers":vouchers,
      "GosspArray":GosspArray,
      "colors": colors,
      "creator": creator
    ]
  }
  func calculateRadius() -> Double {
    return (((maxCircleRadius - minCircleRadius) / maxPeopleToReachMaxRadius) * Double(contCount.count)) + minCircleRadius
    //return maxCircleRadius
  }
  func printValues() {
    print("==================================================")
    print("name: \(name)")
    print("ID: \(ID)")
    print("coordinates: \(coordinates)")
    print("Creator: \(creator)")
    print("contCount: \(contCount)")
    print("vouchers: \(vouchers)")
    print("GosspArray: \(GosspArray)")
    print("Colors: \(colors)")
    print("Circle radius: \(calculateRadius())")
    print("==================================================")
  }
  func updateCloud(candidate:Bool = false) {
    var loc = "locations"
    if candidate {loc = "candidateLocation"}
    ref.child(loc).child("value\(ID)").setValue([
      "name": name,
      "ID":ID,
      "coordinates":coordinates,
      "contCount":contCount,
      "vouchers":vouchers,
      "GosspArray":GosspArray,
      "colors": colors,
      "creator": creator
    ])
  }
  
}

class Gossp{
  var ID:Int = 0
  var creator: String = ""
  var creationDate: Double = 0
  var votes: Array<Int> = []
  var parentID:Int = 0
  var subject:String = ""
  var context:String = ""
  var comments:Array<Int> = []
  
}

let counters = Counters()
class Counters{
  
  var locationCount: Int = 0
  var GosspCount: Int = 0
  var activeUser: Int = 0
  var nameCount: Int = 0
  
  func callListener() {
    DispatchQueue.global(qos: .background).async {
      _ = ref.child("counters").observe(DataEventType.value, with: { (snapshot) in
        DispatchQueue.main.async {
          let value = snapshot.value as? NSDictionary
          self.locationCount = value?["locationCount"] as? Int ?? 0
          self.GosspCount = value?["GosspCount"] as? Int ?? 0
          self.activeUser = value?["activeUser"] as? Int ?? 0
          self.nameCount = value?["nameCount"] as? Int ?? 0
          //self.printValues()
        }
      })
    }
  }
  
  func updateCloud() {
    ref.child("counters").setValue([
      "locationCount":locationCount,
      "GosspCount":GosspCount,
      "activeUser":activeUser,
      "nameCount":nameCount
    ])
  }
  
  func printValues() {
    print("==================================================\nValue change detected.")
    print("locationCount: \(locationCount)")
    print("GosspCount: \(GosspCount)")
    print("activeUser: \(activeUser)")
    print("nameCount: \(nameCount)")
    print("==================================================")
  }
}

func sendNotification(title:String, context:String, _ inSeconds:Double = 1) {
  let content = UNMutableNotificationContent()
  content.title = title
  content.subtitle = context
  content.sound = UNNotificationSound.default
  
  let trigger = UNTimeIntervalNotificationTrigger(timeInterval: inSeconds, repeats: false)
  
  UNUserNotificationCenter.current().add(
    UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
  )
  
}
func timeIntervalToBeautifulString(time:Double) -> String {
  var returningText = ""
  var tmp = Int(time)
  while tmp != 0 {
    if Int(tmp / 86400) > 0 {
      if Int(tmp / 86400) == 1{
        tmp -= 86400
        returningText.append("A day, ")
      } else {
        returningText.append("\(Int(tmp / 86400)) days, ")
        tmp -= (86400 * Int(tmp / 86400))
      }
    } else if Int(tmp / 3600) > 0 {
      if Int(tmp / 3600) == 1{
        tmp -= 3600
        returningText.append("an hour, ")
      } else {
        returningText.append("\(Int(tmp / 3600)) hours, ")
        tmp -= (3600 * Int(tmp / 3600))
      }
    } else if Int(tmp / 60) > 0 {
      if Int(tmp / 60) == 1{
        tmp -= 60
        returningText.append("a minute, ")
      } else {
        returningText.append("\(Int(tmp / 60)) minutes, ")
        tmp -= (60 * Int(tmp / 60))
      }
    } else if tmp == 1 {
      tmp -= 1
      returningText.append("a second. ")
    } else {
      returningText.append("\(tmp) seconds. ")
      tmp = 0
    }
  }
  return returningText
}
