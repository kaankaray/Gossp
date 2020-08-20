//
//  PhoneLoginViewController.swift
//  Gossp
//
//  Created by Kaan Karay on 9.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import OneSignal
import CircularProgressView

class PhoneLoginViewController: UIViewController, FUIAuthDelegate {
  var listOfKeys: Array<String> = []
  
  @IBOutlet var logoOutlet: UIImageView!
  @IBOutlet var loadingView: CircularProgressView!
  
  func animateEntrence() {
    let options: UIView.AnimationOptions = []
    UIView.animate(withDuration: 1,
                   delay: 0,
                   options: options,
                   animations: { [weak self] in
                    self?.logoOutlet.frame = CGRect(x: self!.logoOutlet.frame.minX, y: self!.logoOutlet.frame.minY - 50, width: 220, height: 110)
      }, completion: nil)
  }
  func loadMapStyle() {
    if let path = Bundle.main.path(forResource: "mapStyle", ofType: "json") {
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let convertedString = String(data: data, encoding: String.Encoding.utf8)
        mapStyle = convertedString!
      } catch {
        // handle error
      }
    }
  }
  
  // MARK: View...
  override func viewDidAppear(_ animated: Bool) {
    animateEntrence()
    loadMapStyle()
    loadingView.animationDuration = 0.3
    loadingView.textColor = .gosspGreen
    loadingView.maximumBarColor = .gosspGreen
    loadingView.foregroundBarColor = .gosspGreen
    loadingView.backgroundBarColor = .gosspLightGray
    
    let authUI = FUIAuth.defaultAuthUI()!
    ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
      let value = snapshot.value as? NSDictionary
      self.listOfKeys = value?.allKeys as? Array<String> ?? []
      self.loadingView.setProgress(to: 0.1, animated: false)
      _ = Auth.auth().addStateDidChangeListener { (auth, user) in
        if !self.listOfKeys.contains(UserDefaults.standard.string(forKey: "username") ?? "Something."){
          // You need to adopt a FUIAuthDelegate protocol to receive callback
          authUI.delegate = self
          authUI.providers = [FUIPhoneAuth(authUI:FUIAuth.defaultAuthUI()!)]
          let phoneProvider = authUI.providers.first as! FUIPhoneAuth
          self.loadingView.setProgress(to: 0.5, animated: true)
          
          phoneProvider.signIn(withPresenting: self, phoneNumber: nil)
          
        } else {
          //Already registered.
          self.loadingView.setProgress(to: 0.3, animated: false)
          ref.child("users").child(UserDefaults.standard.string(forKey: "username")!).observeSingleEvent(of: .value, with: { (snapshot) in
            print("Already registered user.")
            self.loadingView.setProgress(to: 1, animated: true)
            let value = snapshot.value as? NSDictionary
            currentUser.name = value?["username"] as? String ?? ""
            currentUser.pNumber = value?["pnumber"] as? String ?? ""
            currentUser.colors = value?["colors"] as? Array<CGFloat> ?? [0,0,0]
            currentUser.UID = value?["UID"] as? String ?? ""
            currentUser.enlistedLocations = value?["locationIDs"] as? Array<Int> ?? []
            currentUser.vouchableDate = value?["vouchableDate"] as? Double ?? 0
            currentUser.isDeleted = value?["isDeleted"] as? Bool ?? false
            currentUser.score = value?["score"] as? Int ?? 0
            currentUser.playerID = value?["playerID"] as? String ?? ""
            
            currentUser.printUser()
            self.loadingView.setProgress(to: 1, animated: true)
            print("Segue called!")
            self.performSegue(withIdentifier: "segueShowNavigation", sender: self)
          }) { (error) in
            print(error.localizedDescription)
          }
        }
      }
    }) { (error) in
      print(error.localizedDescription)
    }
    // Listen for the *counters*
    counters.callListener()
    timeoutAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
  }
  
  // MARK: Auth
  
  func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
    print("didSignIn")
    var randomUsername = randomString(length: 8)
    self.loadingView.setProgress(to: 1, animated: true)
    while listOfKeys.contains(randomUsername){randomUsername = randomString(length: 8)}
    let newUser = [
      "username": randomUsername,
      "pnumber": authDataResult!.user.phoneNumber!,
      "uid":authDataResult!.user.uid,
      "locationIDs":[],
      "colors": randomColorFloat(),
      "vouchableDate":Double(0),
      "isDeleted": false,
      "score": Int(0),
      "playerID": String((OneSignal.getUserDevice()?.getUserId())!)
      ] as [String : Any]
    UserDefaults.standard.setValue(randomUsername, forKey: "username")
    ref.child("users").child(randomUsername).setValue(newUser)
    currentUser = GosspUser(value: newUser as NSDictionary)
    counters.activeUser += 1
    counters.nameCount += 1
    counters.updateCloud()
    print("Segue called!")
    performSegue(withIdentifier: "segueShowNavigation", sender: self)
  }
  func authUI(_ authUI: FUIAuth, didFinish operation: FUIAccountSettingsOperationType, error: Error?) {
    print(operation)
    print(error! as Error)
  }
  
  func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
    // handle user and error as necessary
    print("Error - ")
    print(error as Any)
  }
  
  
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "segueShowNavigation" {
      if let destVC = segue.destination as? UINavigationController,
        let targetController = destVC.topViewController as? MapViewController {
        targetController.title = "hello from ReceiveVC !"
      }
    }
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {return .lightContent}
}
