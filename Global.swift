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
import OneSignal


let screenSize: CGRect = UIScreen.main.bounds
// A default location to use when location permission is not granted.
let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
var mapStyle = ""
var ref: DatabaseReference! = Database.database().reference()
let storage = Storage.storage()
let storageRef = storage.reference()
let minDistanceToAction:Double = 100
let minDistanceToSee:Double = 100000 // 3000?

struct emojis {
  //Emojis? ⚡️😔☠️✍️🔥👑💎🔑📣⚛️⚖️🔧⭐️👀
  let key = "🔑";let megaphone = "📣";let atom = "⚛️";let judge = "⚖️";let wrench = "🔧";let star = "⭐️"; let eyes = "👀"
  let crown = "👑";let fire = "🔥";let writing = "✍️";let skull = "☠️";let sad = "😔";let lightning = "⚡️";let diamond = "💎";
}

//MARK: Acc vars & funcs
var accPNumber = UserDefaults.standard.string(forKey: "pNumber") ?? ""
var accUID:String = ""
var locationList:Array<Int> = []
var vouchableDateAccount:Double = 0
func updateAccount() {
  ref.child("accounts").child(accPNumber).setValue([
    "pNumber": accPNumber,
    "locationList":locationList,
    "vouchableDateAccount": vouchableDateAccount,
    "UID":accUID
  ])
}
func accountVouchable() -> Bool {return !(Date().timeIntervalSince1970 < vouchableDateAccount)}


//MARK: Extensions
extension UIColor {
  static var gosspGreen:UIColor {return UIColor(red: 28/256, green: 184/256, blue: 35/256, alpha: 1)} // #00c329
  static var gosspPurple:UIColor {return UIColor(red: 74/256, green: 29/256, blue: 141/256, alpha: 1)}
  static var gosspLighterPurple:UIColor {return UIColor(red: 74/256, green: 29/256, blue: 141/256, alpha: 0.85)}
  static var gosspLightGray:UIColor {return UIColor(white: 1, alpha: 0.3)}
  static var gosspLighterGray:UIColor {return UIColor(white: 1, alpha: 0.5)}
}

extension NSMutableAttributedString {
  var fontSize:CGFloat { return 14 }
  var boldFont:UIFont { return UIFont(name: "AvenirNext-Bold", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize) }
  var crossedFont:UIFont { return UIFont(name: "AvenirNext-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize) }
  var normalFont:UIFont { return UIFont(name: "AvenirNext-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)}
  
  func bold(_ value:String) -> NSMutableAttributedString {
    
    let attributes:[NSAttributedString.Key : Any] = [
      .font : boldFont
    ]
    
    self.append(NSAttributedString(string: value, attributes:attributes))
    return self
  }
  
  func crossed(_ value:String) -> NSMutableAttributedString {
    
    let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: value)
    attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
    self.append(attributeString)
    return self
  }
  
  func normal(_ value:String) -> NSMutableAttributedString {
    
    let attributes:[NSAttributedString.Key : Any] = [
      .font : normalFont,
    ]
    
    self.append(NSAttributedString(string: value, attributes:attributes))
    return self
  }
  /* Other styling methods */
  func orangeHighlight(_ value:String) -> NSMutableAttributedString {
    
    let attributes:[NSAttributedString.Key : Any] = [
      .font :  normalFont,
      .foregroundColor : UIColor.white,
      .backgroundColor : UIColor.orange
    ]
    
    self.append(NSAttributedString(string: value, attributes:attributes))
    return self
  }
  
  func blackHighlight(_ value:String) -> NSMutableAttributedString {
    
    let attributes:[NSAttributedString.Key : Any] = [
      .font :  normalFont,
      .foregroundColor : UIColor.white,
      .backgroundColor : UIColor.black
      
    ]
    
    self.append(NSAttributedString(string: value, attributes:attributes))
    return self
  }
  
  func underlined(_ value:String) -> NSMutableAttributedString {
    
    let attributes:[NSAttributedString.Key : Any] = [
      .font :  normalFont,
      .underlineStyle : NSUnderlineStyle.single.rawValue
      
    ]
    
    self.append(NSAttributedString(string: value, attributes:attributes))
    return self
  }
}

extension UIView{
  func animateBounceTwice() {
    
      self.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
      UIView.animate(withDuration: 1.0,
                     delay: 0,
                     usingSpringWithDamping: CGFloat(0.20),
                     initialSpringVelocity: CGFloat(5.0),
                     options: UIView.AnimationOptions.allowUserInteraction,
                     animations: {self.transform = CGAffineTransform.identity},
                     completion: { Void in()  })
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



//MARK: Global Functions

/**
 Send taptic feedback:
 
 - (0...2) notification feedback (.success, .warning, .error)
 - (3...5) impact feedback (.light, .medium, .heavy)
 - (6,7) impact feedback iOS 13 and later. (.rigid, .soft)
 */
func randTaptic(_ customTaptic:Int = Int.random(in: 0...7)) {
  let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
  notificationFeedbackGenerator.prepare()
//  print("Taptic played: \(customTaptic)")
  switch customTaptic {
  case 0:
    notificationFeedbackGenerator.notificationOccurred(.success)
  case 1:
    notificationFeedbackGenerator.notificationOccurred(.warning)
  case 2:
    notificationFeedbackGenerator.notificationOccurred(.error)
  case 3:
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
    impactFeedbackgenerator.prepare()
    impactFeedbackgenerator.impactOccurred()
  case 4:
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
    impactFeedbackgenerator.prepare()
    impactFeedbackgenerator.impactOccurred()
  case 5:
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
    impactFeedbackgenerator.prepare()
    impactFeedbackgenerator.impactOccurred()
  case 6:
    if #available(iOS 13.0, *) {
      let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .rigid)
      impactFeedbackgenerator.prepare()
      impactFeedbackgenerator.impactOccurred()
    } else {
      // Fallback on earlier versions
    }
  case 7:
    if #available(iOS 13.0, *) {
      let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .soft)
      impactFeedbackgenerator.prepare()
      impactFeedbackgenerator.impactOccurred()
    } else {
      // Fallback on earlier versions
      let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
      impactFeedbackgenerator.prepare()
      impactFeedbackgenerator.impactOccurred()
    }
  default:
    print("ffs u suck")
  }
}

/**
 Sends UNMutableNotification.
 - title: String
 - context: String
 - inSeconds: Double = 1
 */
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

func metersToKM(meters:Double) -> String {
  if meters < 1000 {return String(format: "%.2f", meters) + " meters"}
  else {return String(format: "%.2f", meters/1000) + " kilometers"}
}

///Returns amount of seconds in a beautiful string.
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

/**
 Delays the event (DispatchQueue.main.asyncAfter) for input seconds. Doesn't halt.
 - time: Double
 
 Example:
 delay(4){
  print("4 second delayed print command!")
 }
 */
func delay(_ time: Double, completion: @escaping () -> ()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + time) {
    // Code with delay
    completion()
  }
}

//MARK: Objects



//MARK: GosspUser
class GosspUser{
  
  var name:String = ""
  var pNumber:String = ""
  var UID:String = ""
  var colors:Array<CGFloat> = []
  var vouchableDate:Double = 0
  var isDeleted:Bool = false
  var score:Int = 0
  var playerID:String = ""
  var empty = false
  
  init() {
    name = randomString(length: 8)
    pNumber = accPNumber
    UID = accUID
    colors = randomColorFloat()
    vouchableDate = 0
    isDeleted = false
    score = 0
    playerID = (OneSignal.getUserDevice()?.getUserId())!
    empty = true
  }
  
  init(withLocation:GosspLocation) {
    name = randomString(length: 8)
    for var k in 0...withLocation.contCount.count-1 {if withLocation.contCount[k].name == name {name = randomString(length: 8); k = 0}}
    pNumber = accPNumber
    UID = accUID
    colors = randomColorFloat()
    vouchableDate = 0
    isDeleted = false
    score = 0
    playerID = (OneSignal.getUserDevice()?.getUserId())!
  }
  
  /*init(withLocationID:Int) {
    ref.child("locations").child("\(withLocationID)").child("contCount").observeSingleEvent(of: .value, with: { (snapshot) in
      let value = snapshot.value as? NSDictionary
      let p = (value?.allKeys ?? []) as Array<String>
      
      var randomUsername = randomString(length: 8)
      while p.contains(randomUsername) {randomUsername = randomString(length: 8)}
      
      self.name = randomUsername
      self.pNumber = UserDefaults.standard.string(forKey: "pNumber")!
      self.UID = accUID
      self.colors = randomColorFloat()
      self.vouchableDate = 0
      self.isDeleted = false
      self.score = 0
      self.playerID = (OneSignal.getUserDevice()?.getUserId())!
      
    }) { (error) in
      print(error.localizedDescription)
    }
    
  } //Too slow.
  
  init(withCandidateLocationID:Int) {
    ref.child("candidateLocations").child("\(withCandidateLocationID)").child("contCount").observeSingleEvent(of: .value, with: { (snapshot) in
      let value = snapshot.value as? NSDictionary
      let p = (value?.allKeys ?? []) as Array<String>
      
      var randomUsername = randomString(length: 8)
      while p.contains(randomUsername) {randomUsername = randomString(length: 8)}
      
      self.name = randomUsername
      self.pNumber = UserDefaults.standard.string(forKey: "pNumber")!
      self.UID = accUID
      self.colors = randomColorFloat()
      self.vouchableDate = 0
      self.isDeleted = false
      self.score = 0
      self.playerID = (OneSignal.getUserDevice()?.getUserId())!
      
    }) { (error) in
      print(error.localizedDescription)
    }
    
  }*/
  
  init(value: NSDictionary) {
    name = value["username"] as? String ?? ""
    pNumber = value["pnumber"] as? String ?? ""
    colors = value["colors"] as? Array<CGFloat> ?? [0,0,0]
    UID = value["UID"] as? String ?? ""
    vouchableDate = value["vouchableDate"] as? Double ?? 0
    isDeleted = value["isDeleted"] as? Bool ?? false
    score = value["score"] as? Int ?? 0
    playerID = value["playerID"] as? String ?? ""
  }
  
  func contains(_ sec: GosspUser) -> Bool {return self.pNumber == sec.pNumber}
  
  func color() -> UIColor {return UIColor(red: colors[0], green: colors[1], blue: colors[2], alpha: 1)}
  func vouchable() -> Bool {return Date().timeIntervalSince1970 < self.vouchableDate}
  func emptyUser() -> Bool {return empty}
  
  func printUser() {
    print("===GosspUser===========================================")
    print("Name: \(name)")
    print("Phone number: \(pNumber)")
    print("UID: \(UID)")
    print("User colors: \(colors)")
    print("Score: \(score)")
    print("Can vouch, change color, change name after: \(Date.init(timeIntervalSince1970: vouchableDate))")
    print("PlayerID for notifications: \(playerID)")
    print("Deleted?: \(isDeleted)")
    print("=======================================================")
  }
  
  func updateCloud(loc:GosspLocation) {
    let userID = loc.findUserID()
    if userID != -1 {
      ref.child("locations").child("value\(loc.ID)").child("contCount").child("\(userID)").setValue([
        "username": name,
        "pnumber": pNumber,
        "uid":UID,
        "colors": colors,
        "vouchableDate":vouchableDate,
        "isDeleted": isDeleted,
        "score": score,
        "playerID": playerID
      ])
      if loc.userExists(withName: loc.findUser().name, isVouchers: true) {
        ref.child("locations").child("value\(loc.ID)").child("vouchers").child("\(userID)").setValue([
          "username": name,
          "pnumber": pNumber,
          "uid":UID,
          "colors": colors,
          "vouchableDate":vouchableDate,
          "isDeleted": isDeleted,
          "score": score,
          "playerID": playerID
        ])
      }
    }
  }
  
    
  func returnAsDictionary() -> Dictionary<String, Any> {
    return [
      "username": name,
      "pnumber": pNumber,
      "uid":UID,
      "colors": colors,
      "vouchableDate":vouchableDate,
      "isDeleted": isDeleted,
      "score": score,
      "playerID": playerID
    ]
  }
  
  
}

//MARK: GosspLocation
class GosspLocation{
  var ID: Int = 0
  var name: String = ""
  var coordinates: Array<Double> = [0,0]
  var contCount: Array<GosspUser> = []
  var vouchers:Array<GosspUser> = []
  var GosspArray: Array<Gossp> = []
  var colors: Array<CGFloat> = [0,0,0]
  var creator: String = ""
  var distance: Double = 0
  var tmp:Bool = false
  
  private var maxCircleRadius:Double = 40
  private var minCircleRadius:Double = 8
  private var maxPeopleToReachMaxRadius:Double = 1000
  
  init() {}
  
  init(rawValue:NSDictionary) {
    //Use this to fill the data
    ID = rawValue["ID"] as? Int ?? 0
    name = rawValue["name"] as? String ?? ""
    coordinates = rawValue["coordinates"] as? Array<Double> ?? []
    colors = rawValue["colors"] as? Array<CGFloat> ?? [0,0,0]
    creator = rawValue["creator"] as? String ?? ""
    tmp = rawValue["tmp"] as? Bool ?? false
    (rawValue["GosspArray"] as? Array<NSDictionary> ?? []).forEach{GosspArray.append(Gossp(rawValue: $0))}
    (rawValue["contCount"] as? Array<NSDictionary> ?? []).forEach{contCount.append(GosspUser(value: $0))}
    (rawValue["vouchers"] as? Array<NSDictionary> ?? []).forEach{vouchers.append(GosspUser(value: $0))}
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
  
  func findUser() -> GosspUser{
    var userToReturn = GosspUser()
    contCount.forEach{if $0.pNumber == accPNumber && $0.isDeleted == false{userToReturn = $0}}
//    print("Find user function found:")
//    userToReturn.printUser()
    return userToReturn
  }
  func findUserID() -> Int{
      for k in 0...contCount.count-1 {
        if contCount[k].pNumber == accPNumber && contCount[k].isDeleted == false{return k}
      }
    return -1
  }
  func findUser(withName:String) -> GosspUser{
    var userToReturn = GosspUser()
    contCount.forEach{if $0.name == withName{userToReturn = $0}}
    //    print("Find user function found:")
    //    userToReturn.printUser()
    return userToReturn
  }
  func userExists(withName:String, isVouchers:Bool = false) -> Bool {
    var t = false
    if isVouchers {vouchers.forEach{if $0.name == withName{t = true}}}
    else {contCount.forEach{if $0.name == withName{t = true}}}
    return t
  }
  func badgeCheck(name:String) -> String {
    //return name with badges.
    var badgedName = name
    for _ in 0...2 {
      switch badgedName {
      case _ where !name.contains(emojis().crown) && name == creator:
        badgedName = emojis().crown + name
      case _ where !name.contains(emojis().atom) && findUser(withName: name).pNumber == "+380985959881":
        badgedName = emojis().atom + name
      default: break
      }
    }
    return badgedName
  }
  
  func calculateRadius() -> Double {
    return (((maxCircleRadius - minCircleRadius) / maxPeopleToReachMaxRadius) * Double(contCount.count)) + minCircleRadius
  }
  func printLocation() {
    print("===GosspLocation=======================================")
    print("name: \(name)")
    print("ID: \(ID)")
    print("coordinates: \(coordinates)")
    print("Creator: \(creator)")
    print("contCount: \(contCount.count)")
//    print("vouchers: \(vouchers)")
    print("GosspArray: \(GosspArray)")
    print("Colors: \(colors)")
    print("Circle radius: \(calculateRadius()) Distance:\(distance)")
    print("=======================================================")
  }
  func updateCloud(candidate:Bool = false) {
    var loc = "locations"
    var dictVouchers:Array<Dictionary<String, Any>> = []
    var dictUsers:Array<Dictionary<String, Any>> = []
    var dictGossp:Array<Dictionary<String, Any>> = []
    vouchers.forEach{dictVouchers.append($0.returnAsDictionary())}
    contCount.forEach{dictUsers.append($0.returnAsDictionary())}
    GosspArray.forEach{dictGossp.append($0.returnAsDictionary())}
    if candidate {loc = "candidateLocations"}
    ref.child(loc).child("value\(ID)").setValue([
      "name": name,
      "ID":ID,
      "coordinates":coordinates,
      "contCount":dictUsers,
      "vouchers":dictVouchers,
      "GosspArray":dictGossp,
      "colors": colors,
      "creator": creator
      
    ])
  }
  
}

//MARK: Gossp
class Gossp{
  var GosspLoc:GosspLocation = GosspLocation()
  var ID:Int = 0
  var creationDate: Double = 0
  var parentID:Int = -2
  var subject:String = ""
  var context:String = ""
  var creator: GosspUser = GosspUser()
  var upVotes: Array<GosspUser> = []
  var downVotes: Array<GosspUser> = []
  var comments:Array<Gossp> = []
  
  init() {}
  
  init(rawValue:NSDictionary) {
    //Use this to fill the data
    ID = rawValue["ID"] as? Int ?? 0
    creationDate = rawValue["creationDate"] as? Double ?? 0
    parentID = rawValue["parentUD"] as? Int ?? -2
    subject = rawValue["subject"] as? String ?? ""
    context = rawValue["context"] as? String ?? ""
    creator = GosspUser(value: (rawValue["creator"] as? NSDictionary ?? [:]))
    (rawValue["upVotes"] as? Array<NSDictionary> ?? []).forEach{upVotes.append(GosspUser(value: $0))}
    (rawValue["downVotes"] as? Array<NSDictionary> ?? []).forEach{downVotes.append(GosspUser(value: $0))}
    (rawValue["comments"] as? Array<NSDictionary> ?? []).forEach{comments.append(Gossp(rawValue: $0))}
  }
  func findUser(_ arr:Array<GosspUser>) -> GosspUser{
    var userToReturn = GosspUser()
    arr.forEach{if $0.pNumber == accPNumber && $0.isDeleted == false{userToReturn = $0}}
    //    print("Find user function found:")
    //    userToReturn.printUser()
    return userToReturn
  }
  func printGossp() {
    print("===Gossp===============================================")
    print("ID: \(ID)")
    print("creationDate: \(creationDate)")
    print("Creator:"); creator.printUser()
    print("parentID: \(parentID)")
    print("context: \(context)")
    print("upVotes: \(upVotes.count)")
    print("downVotes: \(downVotes.count)")
    print("comments: \(comments.count)")
    print("=======================================================")
  }
  func returnAsDictionary() -> Dictionary<String, Any> {
    
    var upVotesDict:Array<Dictionary<String, Any>> = []
    var downVotesDict:Array<Dictionary<String, Any>> = []
    var commentsDict:Array<Dictionary<String, Any>> = []
    upVotes.forEach{upVotesDict.append($0.returnAsDictionary())}
    downVotes.forEach{downVotesDict.append($0.returnAsDictionary())}
    comments.forEach{commentsDict.append($0.returnAsDictionary())}
    
    return [
      "ID": ID,
      "creationDate":creationDate,
      "parentID":parentID,
      "subject":subject,
      "context":context,
      "creator":creator.returnAsDictionary(),
      "upVotes":upVotesDict,
      "downVotes":downVotesDict,
      "comments":commentsDict
    ]
  }
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


