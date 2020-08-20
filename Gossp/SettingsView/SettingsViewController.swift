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
  
//  MARK: Cell 0 Outlets
  @IBOutlet var idLabel: UILabel!
  @IBOutlet var labels: [UILabel]!
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
        let tempOldUser = currentUser
        tempOldUser.isDeleted = true
        tempOldUser.updateCloud()
        
        currentUser.name = randomString(length: 8)
        currentUser.colors = randomColorFloat()
        currentUser.vouchableDate = Double(Date().addingTimeInterval(timeoutsInDays().IDChange).timeIntervalSince1970)
        currentUser.updateCloud()
        self.viewWillAppear(false)
        
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
        currentUser.colors = randomColorFloat()
        
        currentUser.vouchableDate = Double(Date().addingTimeInterval(timeoutsInDays().colorChange).timeIntervalSince1970)
        currentUser.updateCloud()
        self.viewWillAppear(false)
        
      }))
      p.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
      
      self.present(p, animated: true)
    }
  }
  
//  MARK: Cell 1
  
  @IBOutlet var colorPickers: [UISlider]!
  @IBAction func colorPickersAct(_ sender: Any) {
  }
  @IBAction func butPressed(_ sender: Any) {
    currentUser.vouchableDate = 0
    currentUser.updateCloud()
    idChange.tintColor = .gosspGreen
    idColorChange.tintColor = .gosspGreen
  }
  
  //MARK: ViewDid...
  override func viewWillAppear(_ animated: Bool) {
    self.navigationController?.navigationBar.topItem?.title = "Gossp"
    navigationController?.navigationBar.barStyle = .black
    
    idLabel.text = currentUser.name
    
    let strokeTextAttributes = [
      NSAttributedString.Key.strokeColor : UIColor.gosspLightGray,
      NSAttributedString.Key.foregroundColor : currentUser.color(),
      NSAttributedString.Key.strokeWidth : -1.5
      ]
      as [NSAttributedString.Key : Any]
    
    idLabel.attributedText = NSMutableAttributedString(string: currentUser.name, attributes: strokeTextAttributes)
    labels.forEach{$0.textColor = .gosspGreen}
    
    if currentUser.vouchable() {
      idChange.tintColor = .gosspLightGray
      idColorChange.tintColor = .gosspLightGray
    } else {
      idChange.tintColor = .gosspGreen
      idColorChange.tintColor = .gosspGreen
    }
    self.tableView.tintColor = .gosspGreen
    self.tableView.backgroundColor = .gosspLighterPurple
    self.tableView.separatorColor = UIColor.white
    
    cellContentViews.forEach{$0.backgroundColor = .gosspLighterPurple}
    let image = UIImage(named: "GosspWide8") //Your logo url here
    let imageView = UIImageView(image: image)
    let bannerWidth = self.navigationController?.navigationBar.frame.size.width
    let bannerHeight = self.navigationController?.navigationBar.frame.size.height
    let bannerX = bannerWidth! / 2 - (image?.size.width)! / 2
    let bannerY = bannerHeight! / 2 - (image?.size.height)! / 2
    imageView.frame = CGRect(x: bannerX, y: bannerY, width: bannerWidth!, height: bannerHeight!)
    imageView.contentMode = .scaleAspectFit
    navigationItem.titleView = imageView
    
    //self.navigationController?.navigationBar.topItem?.title = "Gossp"
    // Listen to the color.
    DispatchQueue.global(qos: .background).async {
      _ = ref.child("users").child(currentUser.name).observe(DataEventType.value, with: { (snapshot) in
        DispatchQueue.main.async {
          let value = snapshot.value as? NSDictionary
          currentUser.colors = value?["colors"] as? Array<CGFloat> ?? [0,0,0]
          currentUser.name = value?["username"] as? String ?? ""
          self.idLabel.textColor = currentUser.color()
          self.idLabel.text = currentUser.name
          
        }
      })
    }
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
    return 5
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
