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
    ref.child("accounts").observeSingleEvent(of: .value, with: { (snapshot) in
      let value = snapshot.value as? NSDictionary
      self.listOfKeys = value?.allKeys as? Array<String> ?? []
      self.loadingView.setProgress(to: 0.1, animated: false)
      _ = Auth.auth().addStateDidChangeListener { (auth, user) in
        if accPNumber == ""{
          // You need to adopt a FUIAuthDelegate protocol to receive callback
          authUI.delegate = self
          authUI.providers = [FUIPhoneAuth(authUI:FUIAuth.defaultAuthUI()!)]
          let phoneProvider = authUI.providers.first as! FUIPhoneAuth
          self.loadingView.setProgress(to: 0.5, animated: true)
          
          phoneProvider.signIn(withPresenting: self, phoneNumber: nil)
          
        } else {
          //Already registered.
          self.loadingView.setProgress(to: 0.3, animated: false)
          ref.child("accounts").child(UserDefaults.standard.string(forKey: "pNumber")!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            vouchableDateAccount = value?["vouchableDate"] as? Double ?? 0
            locationList = value?["locationList"] as? Array<Int> ?? []
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
    print("didSignIn\n\(String(describing: error?.localizedDescription))") // If entered correctly, error?.localizedDescription returns nil
    if error?.localizedDescription == nil{
    self.loadingView.setProgress(to: 1, animated: true)
    UserDefaults.standard.setValue(authDataResult!.user.phoneNumber!, forKey: "pNumber")
    ref.child("accounts").child(UserDefaults.standard.string(forKey: "pNumber")!).observeSingleEvent(of: .value, with: { (snapshot) in
      let value = snapshot.value as? NSDictionary
      vouchableDateAccount = value?["vouchableDate"] as? Double ?? 0
      locationList = value?["locationList"] as? Array<Int> ?? []
      accUID = authDataResult!.user.uid
      accPNumber = authDataResult!.user.phoneNumber!
      updateAccount()
      counters.activeUser += 1
      counters.nameCount += 1
      counters.updateCloud()
      self.performSegue(withIdentifier: "segueShowNavigation", sender: self)
    }) { (error) in
      print(error.localizedDescription)
    }
    }
  }
  func authUI(_ authUI: FUIAuth, didFinish operation: FUIAccountSettingsOperationType, error: Error?) {
    print(operation)
    print(error! as Error)
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
