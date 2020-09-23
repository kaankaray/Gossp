//
//  LocationGosspsTableViewController.swift
//  Gossp
//
//  Created by Kaan Karay on 10.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseCore

class LocationGosspsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
  var selectedLocation:GosspLocation = GosspLocation()
  var currentUser:GosspUser = GosspUser()
  @IBOutlet var GosspButton: UIButton!
  @IBOutlet var titleBut: UIButton!
  
  
  @IBAction func GosspButtonAct(_ sender: Any) {
    print("Gossp Button!")
    self.performSegue(withIdentifier: "createGossp", sender: self)
  }
  
  var backupView:UIView = UIView()
  func updateTopViewName() {
    if !UserDefaults.standard.bool(forKey: "nameHiddenIntGosspList"){
      navigationItem.titleView = backupView
      titleBut.setTitle(selectedLocation.badgeCheck(name: currentUser.name), for: .normal)
      titleBut.tintColor = currentUser.color()
      titleBut.sizeToFit()
    } else {
      //When it becomes an image, you can't press it...
      let image = UIImage(named: "GosspWide8") //Your logo url here
      let imageView = UIImageView(image: image)
      let bannerWidth = self.view.frame.width
      let bannerHeight = self.navigationController?.navigationBar.frame.size.height
      let bannerX = bannerWidth / 2 - (image?.size.width)! / 2
      let bannerY = bannerHeight! / 2 - (image?.size.height)! / 2
      imageView.frame = CGRect(x: bannerX, y: bannerY, width: bannerWidth, height: bannerHeight!)
      imageView.contentMode = .scaleAspectFit
      navigationController?.navigationBar.barStyle = .black
      navigationItem.titleView = imageView
      
    }
  }
  
  @IBAction func titleButAct(_ sender: Any) {
    //let vc = SettingsViewController()
    let vc = self.storyboard?.instantiateViewController(withIdentifier: "settings") as! SettingsViewController
    vc.currentUser = currentUser
    vc.currentLocation = selectedLocation
    vc.masterVC = self
    vc.modalPresentationStyle = .popover
    vc.preferredContentSize = CGSize(width: 300, height: 250)
    
    let ppc = vc.popoverPresentationController
    ppc?.permittedArrowDirections = .up
    ppc?.delegate = self
    ppc?.sourceView = (sender as! UIView)
    
    present(vc, animated: true, completion: nil)
  }
  
  func setDisplay() {
    currentUser = selectedLocation.findUser()
    self.view.backgroundColor = .gosspPurple
    tableView.backgroundColor = .gosspPurple
    tableView.separatorColor = UIColor.white
    
    backupView = navigationItem.titleView!
    delay(1){self.updateTopViewName()}
    //self.title = currentUser.name
    //self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: currentUser.color()]
    
  }
  
  //MARK: ViewDid...
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    DispatchQueue.global(qos: .background).async {
      _ = ref.child("locations").child("value\(self.selectedLocation.ID)").observe(DataEventType.value, with: { (snapshot) in
        DispatchQueue.main.async {
          let value = snapshot.value as? NSDictionary
          self.selectedLocation = GosspLocation(rawValue: value ?? [:])
          self.setDisplay()
          self.tableView.reloadData()
          
        }
      })
    }
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {return 1}
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return selectedLocation.GosspArray.count}
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    //Go to Gossp.
    
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 168
  }
  
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as! GosspTableViewCell
    cell.GosspReal = selectedLocation.GosspArray[indexPath.row]
    selectedLocation.GosspArray[indexPath.row].printGossp()
    cell.GosspReal.GosspLoc = selectedLocation
    cell.selectedLocation = self.selectedLocation
    cell.currentUser = self.currentUser
    cell.indexPathRowCell = indexPath.row
    
    
    
    
    cell.setDisplay()
    
    
    return cell
  }
  override var preferredStatusBarStyle: UIStatusBarStyle {return .lightContent}
  
  override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
    if segue.identifier == "createGossp" {
      let feed = segue.destination as! CreateGosspViewController
      feed.currentUser = currentUser
      feed.loc = selectedLocation
    }
    if segue.identifier == "showGosspDetails" {
//      let feed = segue.destination as! ShowGosspDetailsViewController
      
    }
  }
  
  func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    return .none
  }
  
  func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    return .none
  }
  
}
