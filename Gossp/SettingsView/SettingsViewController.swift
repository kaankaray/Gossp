//
//  SettingsViewController.swift
//  Gossp
//
//  Created by Kaan Karay on 2.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseCore

class SettingsViewController: UITableViewController {
  var currentUser:GosspUser = GosspUser()
  var currentLocation:GosspLocation = GosspLocation()
  var masterVC = LocationGosspsTableViewController()
  
  @IBOutlet var labels: [UILabel]!
//  MARK: Cell 0 Outlets
  @IBOutlet var idLabel: UILabel!
  @IBOutlet var idChange: UIButton!
  @IBOutlet var idColorChange: UIButton!
  @IBOutlet var cellContentViews: [UIView]!
  
  @IBAction func idChangeAct(_ sender: Any) {
    if currentUser.vouchable() {
      let alert = UIAlertController(title: "Sorry!", message: "You are not allowed to change your name for: \(timeIntervalToBeautifulString(time: (currentUser.vouchableDate - Date().timeIntervalSince1970)))", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Understood.", style: .default, handler: nil))
      alert.addAction(UIAlertAction(title: "Understood and show me time penalties.", style: .default, handler: { (action) in
        self.present(timeoutAlert, animated: true)
      }))
      self.present(alert, animated: true)
    } else {
      let p = warningAlert()
      p.addAction(UIAlertAction(title: "I understand and would like to proceed.", style: .destructive, handler: { (action) in
        let tempOldUser = self.currentUser
        tempOldUser.isDeleted = true
        //tempOldUser.updateCloud(loc: self.currentLocation)
        
        let newUser = GosspUser()
        
        newUser.vouchableDate = Double(Date().addingTimeInterval(timeoutsInDays().IDChange).timeIntervalSince1970)
        self.currentLocation.contCount.append(newUser)
        self.currentLocation.updateCloud()
        self.viewWillAppear(false)
        //self.masterVC.viewWillAppear(false)
        
      }))
      p.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
      
      self.present(p, animated: true)
    }
  }
  
  @IBAction func idColorChange(_ sender: Any) {
    if currentUser.vouchable() {
      let alert = UIAlertController(title: "Sorry!", message: "You are not allowed to change your color for: \(timeIntervalToBeautifulString(time: (currentUser.vouchableDate - Date().timeIntervalSince1970)))", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Understood.", style: .default, handler: nil))
      alert.addAction(UIAlertAction(title: "Understood and show me time penalties.", style: .default, handler: { (action) in
        self.present(timeoutAlert, animated: true)
      }))
      self.present(alert, animated: true)
    } else {
      let p = warningAlert()
      p.addAction(UIAlertAction(title: "I understand and would like to proceed.", style: .destructive, handler: { (action) in
        //Asking for the name of the Location.
        self.currentUser.colors = randomColorFloat()
        
        self.currentUser.vouchableDate = Double(Date().addingTimeInterval(timeoutsInDays().colorChange).timeIntervalSince1970)
        self.currentUser.updateCloud(loc: self.currentLocation)
        self.viewWillAppear(false)
        
      }))
      p.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
      
      self.present(p, animated: true)
    }
  }
  
  // MARK: Cell 1
  
  @IBOutlet var isHiddenSelected: UISwitch!
  @IBAction func isHiddenSelectedAct(_ sender: Any) {
    UserDefaults.standard.setValue(!UserDefaults.standard.bool(forKey: "nameHiddenIntGosspList"), forKey: "nameHiddenIntGosspList")
    masterVC.updateTopViewName()
  }
  
//  MARK: Cell 2
  
  @IBOutlet var colorPickers: [UISlider]!
  @IBAction func colorPickersAct(_ sender: Any) {
  }
  @IBAction func butPressed(_ sender: Any) {
    currentUser.vouchableDate = 0
    currentUser.updateCloud(loc: currentLocation)
    idChange.tintColor = .gosspGreen
    idColorChange.tintColor = .gosspGreen
  }
  
  //MARK: ViewDid...
  override func viewWillAppear(_ animated: Bool) {
    labels.forEach{$0.textColor = .gosspGreen}
    self.tableView.tintColor = .gosspGreen
    self.tableView.backgroundColor = .gosspLighterPurple
    self.tableView.separatorColor = UIColor.white
    
    cellContentViews.forEach{$0.backgroundColor = .gosspLighterPurple}
    
    let strokeTextAttributes = [
      NSAttributedString.Key.strokeColor : UIColor.gosspLightGray,
      NSAttributedString.Key.foregroundColor : currentUser.color(),
      NSAttributedString.Key.strokeWidth : -1.5
      ]
      as [NSAttributedString.Key : Any]
    //Cell 0
    idLabel.attributedText = NSMutableAttributedString(string: currentUser.name, attributes: strokeTextAttributes)
    if currentUser.vouchable() {
      idChange.tintColor = .gosspLightGray
      idColorChange.tintColor = .gosspLightGray
    } else {
      idChange.tintColor = .gosspGreen
      idColorChange.tintColor = .gosspGreen
    }
    idLabel.textColor = currentUser.color()
    idLabel.text = currentUser.name
    
    //Cell 1
    isHiddenSelected.onTintColor = .gosspGreen
    isHiddenSelected.isOn = UserDefaults.standard.bool(forKey: "nameHiddenIntGosspList")
    
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return 6
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {return .lightContent}
  
  /*
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
   let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as UITableViewCell
   cell.backgroundColor = .gosspPurple
   // Configure the cell...
   
   return cell
   }
   */
  
  /*
   // Override to support conditional editing of the table view.
   override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the specified item to be editable.
   return true
   }
   */
  
  /*
   // Override to support editing the table view.
   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
   if editingStyle == .delete {
   // Delete the row from the data source
   tableView.deleteRows(at: [indexPath], with: .fade)
   } else if editingStyle == .insert {
   // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }
   }
   */
  
  /*
   // Override to support rearranging the table view.
   override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
   
   }
   */
  
  /*
   // Override to support conditional rearranging of the table view.
   override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the item to be re-orderable.
   return true
   }
   */
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
  
}
