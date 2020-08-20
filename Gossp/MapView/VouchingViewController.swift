//
//  VouchingViewController.swift
//  Gossp
//
//  Created by Kaan Karay on 10.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FirebaseCore

class VouchingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UINavigationBarDelegate {
  //MARK: - Variables.
  var isCurrentLocation: Bool = true
  var locationManager: CLLocationManager!
  var currentLocation: CLLocation?
  var zoomLevel:Float = 20.0
  var mapView: GMSMapView!
  var placesClient: GMSPlacesClient!
  var likelyPlaces: [GMSPlace] = []
  var selectedPlace: GMSPlace?
  var candidateLocations: Array<GosspLocation> = []
  var vouchLocation:Array<Double> = []
  
  func addButtonCheck() {
    //Adding button is not possible, time limit.
    if currentUser.vouchable() {addButton.tintColor = UIColor.lightGray}
    else {addButton.tintColor = .gosspGreen}
  }
  func mapFocus(location:Array<Double>) {
    DispatchQueue.main.async {
      let camera = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(location[0]),
                                        longitude: CLLocationDegrees(location[1]),
                                        zoom: self.zoomLevel)
      self.mapView.animate(to: camera)
    }
    vouchLocation = location
  }
  
  @objc func appWillTerminate() {
    //Removes user from vouching if he is vouching anything.
    if candidateLocations.count != 0{
      for k in 0...candidateLocations.count-1 {
        let w = tableViewContent.cellForRow(at: IndexPath(row: k, section: 0)) as! AddLocationTableViewCell
        if w.vouchers.contains(currentUser.name){
          w.deleteButtonAct(self)
        }
      }
    }
  }
  
  //MARK: - Storyboard connections
  @IBOutlet var tableViewContent: UITableView!
  @IBOutlet var cancelButton: UIBarButtonItem!
  @IBOutlet var addButton: UIBarButtonItem!
  
  //Not in use!
  @IBAction func cancelButtonAct(_ sender: Any) {
    
  }
  
  @IBAction func addButtonAct(_ sender: Any) {
    if currentUser.vouchable() {
      //Adding button is not possible, time limit.
      let alert = UIAlertController(title: "Sorry!", message: "You are not allowed to create a new location for: \(timeIntervalToBeautifulString(time: (currentUser.vouchableDate - Date().timeIntervalSince1970)))", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Understood.", style: .default, handler: nil))
      alert.addAction(UIAlertAction(title: "Understood and show me time penalties.", style: .default, handler: { (action) in
        self.present(timeoutAlert, animated: true)
      }))
      self.present(alert, animated: true)
    }
      //Any other reasons that won't allow to creation of a Gossp location?
      //TODO: Really close to another Gossp location!
    else {// Everything looks good I guess...
      
      let p = warningAlert()
      
      p.addAction(UIAlertAction(title: "I understand and would like to proceed.", style: .destructive, handler: { (action) in
        //Asking for the name of the Location.
        self.locationManager.requestLocation()
        let alert = UIAlertController(title: "Input the name of the Gossp location", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
          textField.placeholder = "Min 3, max 24 characters."
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
          if let name = alert.textFields?.first?.text {
            if name.count >= 3 && name.count <= 24{
              print("Your name: \(name)")
              // MARK: Saving candidate location.
              let locationColor = randomColorFloat()
              ref.child("candidateLocation").child("value\(counters.locationCount)").setValue([
                "name": name,
                "ID":counters.locationCount,
                "coordinates":[self.locationManager.location?.coordinate.latitude, self.locationManager.location?.coordinate.longitude],
                "contCount":[],
                "vouchers":[currentUser.name],
                "GosspArray":[],
                "colors":locationColor
                
                
              ]){
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                  print("Data could not be saved: \(error).")
                } else {
                  print("Data saved successfully!")
                  self.tableViewContent.reloadData()
                  counters.locationCount += 1
                  counters.updateCloud()
                  currentUser.vouchableDate = Date().addingTimeInterval(timeoutsInDays().creatingLocation).timeIntervalSince1970
                  currentUser.updateCloud()
                  self.addButtonCheck()
                }
              }
              
            } else {
              let alert = UIAlertController(title: "Sorry!", message: "Gossp location name must be minimum 3 characters and maximum 24 long.", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
              self.present(alert, animated: true)
            }
          }
        }))
        self.present(alert, animated: true)
      }))
      p.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
      
      self.present(p, animated: true)
    }
    
    
  }
  //MARK: - ViewDid...
  override func viewDidLoad() {
    super.viewDidLoad()
    tableViewContent.delegate = self
    tableViewContent.dataSource = self
    
    locationManager = CLLocationManager()
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestAlwaysAuthorization()
    locationManager.distanceFilter = 50
    locationManager.startUpdatingLocation()
    locationManager.delegate = self
    placesClient = GMSPlacesClient.shared()
    
    DispatchQueue.global(qos: .background).async {
      _ = ref.child("candidateLocation").observe(DataEventType.value, with: { (snapshot) in
        let value = snapshot.value as? NSDictionary ?? [:]
        var realArray:Array<NSDictionary> = []
        self.mapView.clear()
        for k in 0...counters.locationCount {
          let p = value["value\(k)"] as? NSDictionary
          if p?["name"] as? String ?? "" != ""{
            realArray.append(value["value\(k)"] as! NSDictionary)
          }
        }
        DispatchQueue.main.async {
          self.candidateLocations = []
          realArray.forEach{
            let tmp = GosspLocation(rawValue: $0)
            tmp.distance = CLLocation(latitude: CLLocationDegrees(tmp.coordinates[0]),
                                      longitude: CLLocationDegrees(tmp.coordinates[1])).distance(from: self.locationManager?.location ?? defaultLocation)
            if tmp.distance < minDistanceToSee{self.candidateLocations.append(tmp)}
            
            
          }
          print("Vouching locations:")
          self.candidateLocations.forEach{$0.printValues()}
          self.tableViewContent.reloadData()
        }
        
        
      })
    }
    NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.didEnterBackgroundNotification, object: nil)
    
    // Create a map.
    let mapTableRatio:CGFloat = 0.66
    let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                          longitude: defaultLocation.coordinate.longitude,
                                          zoom: zoomLevel)
    
    mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0,
                                               width: self.view.frame.width,
                                               height: (self.view.frame.height *  mapTableRatio)), camera: camera)
    // Add the map to the view, hide it until we've got a location update.
    mapView.isMyLocationEnabled = true
    mapView.settings.myLocationButton = false
    mapView.settings.scrollGestures = false
    mapView.settings.rotateGestures = false
    mapView.settings.zoomGestures = true
    mapView.settings.tiltGestures = false
    mapView.isUserInteractionEnabled = true
    do {
      // Set the map style by passing a valid JSON string.
      mapView.mapStyle = try GMSMapStyle(jsonString: mapStyle)
    } catch {
      NSLog("One or more of the map styles failed to load. \(error)")
    }
    
    view.addSubview(mapView)
    
    tableViewContent.frame = CGRect(x: 0, y: (self.view.frame.height * mapTableRatio), width: self.view.frame.width, height: (self.view.frame.height * (1 - mapTableRatio)))
    
    
    listLikelyPlaces()
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    self.navigationController?.setNavigationBarHidden(false, animated: true)
    addButtonCheck()
    self.view.backgroundColor = .gosspPurple
    tableViewContent.backgroundColor = .gosspPurple
    tableViewContent.separatorColor = UIColor.white
    
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    appWillTerminate()
  }
  
  // MARK: - Map
  // Delegates to handle events for the location manager.
  
  func listLikelyPlaces() {
    // Clean up from previous sessions.
    likelyPlaces.removeAll()
    
    placesClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: .name) { (placeLikelihoods, error) in
      guard error == nil else {
        // TODO: Handle the error.
        print("Current Place error: \(error!.localizedDescription)")
        return
      }
      
      guard let placeLikelihoods = placeLikelihoods else {
        print("No places found.")
        return
      }
      
      // Get likely places and add to the list.
      for likelihood in placeLikelihoods {
        let place = likelihood.place
        self.likelyPlaces.append(place)
      }
    }
  }
  // Handle incoming location events.
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let location: CLLocation = locations.last!
    print("Location: \(location)")
    var camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                          longitude: location.coordinate.longitude,
                                          zoom: zoomLevel)
    if vouchLocation.isEmpty == false {
      camera = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(vouchLocation[0]),
                                        longitude: CLLocationDegrees(vouchLocation[1]),
                                        zoom: zoomLevel)
    }
    
    if mapView.isHidden {
      mapView.isHidden = false
      mapView.camera = camera
    } else {
      DispatchQueue.main.async {
        self.mapView.animate(to: camera)
      }
      
    }
    listLikelyPlaces()
    
  }
  
  // Handle authorization for the location manager.
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .restricted:
      print("Location access was restricted.")
    case .denied:
      print("User denied access to location.")
      // Display the map using the default location.
      mapView.isHidden = false
    case .notDetermined:
      print("Location status not determined.")
    case .authorizedAlways: fallthrough
    case .authorizedWhenInUse:
      print("Location status is OK.")
    @unknown default:
      fatalError()
    }
  }
  
  // Handle location manager errors.
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationManager.stopUpdatingLocation()
    print("Error: \(error)")
  }
  
  // MARK: - TableView Data
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return candidateLocations.count}
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as! AddLocationTableViewCell
    cell.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: cell.frame.size.height)
    cell.backgroundColor = .gosspPurple
    cell.tintColor = .gosspGreen
    cell.vouchers = self.candidateLocations[indexPath.row].vouchers
    cell.coordinates = self.candidateLocations[indexPath.row].coordinates
    cell.ID = self.candidateLocations[indexPath.row].ID
    cell.color = self.candidateLocations[indexPath.row].color(alpha: 1)
    cell.colorCGFloat = self.candidateLocations[indexPath.row].colors
    cell.title = "\(self.candidateLocations[indexPath.row].name)  (\(cell.vouchers.count)/5)"
    cell.setLocations()
    cell.customSuperview = self
    let marker2 = GMSCircle()
    marker2.position = CLLocationCoordinate2D(
      latitude: CLLocationDegrees((self.candidateLocations[indexPath.row].coordinates[0])),
      longitude: (CLLocationDegrees((self.candidateLocations[indexPath.row].coordinates[1])))
    )
    marker2.radius = 5
    marker2.fillColor = UIColor(red: self.candidateLocations[indexPath.row].colors[0], green: self.candidateLocations[indexPath.row].colors[1], blue: self.candidateLocations[indexPath.row].colors[2], alpha: 0.3)
    marker2.strokeWidth = 1
    marker2.strokeColor = UIColor(red: self.candidateLocations[indexPath.row].colors[0], green: self.candidateLocations[indexPath.row].colors[1], blue: self.candidateLocations[indexPath.row].colors[2], alpha: 0.8)
    marker2.map = self.mapView
    if cell.vouchers.contains(currentUser.name){
      self.mapFocus(location: cell.coordinates)
      //User vouches and in distance!
      if !(self.candidateLocations[indexPath.row].distance < minDistanceToAction){
        //User shouldn't be in the list!
        cell.deleteButtonAct(self)
      }
      
      
      cell.buttonOutlets[1].isHidden = false
      if cell.vouchers.first == currentUser.name{
        //User is the owner as well!
        if cell.vouchers.count == 5{
          //There are 5 users vouched!
          cell.buttonOutlets[0].isHidden = false
        } else {
          //There are not enough people vouched!
          cell.buttonOutlets[0].isHidden = true
        }
      } else {
        //User is not the owner, but here.
        cell.buttonOutlets[0].isHidden = true
      }
    } else {
      // User is not here.
      cell.buttonOutlets[1].isHidden = true
      if self.candidateLocations[indexPath.row].distance < minDistanceToAction{cell.buttonOutlets[0].isHidden = false}
      else{
        cell.buttonOutlets[0].isHidden = true
        cell.secondLabel.text = "\(self.candidateLocations[indexPath.row].distance) meters. You have to be in \(minDistanceToAction) meter radius to take any action."
        cell.secondLabel.animateLongText(frames:cell.secondLabel.frame.width - cell.titleLabel.frame.width, duration: 1)
        
      }
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableViewContent.cellForRow(at: indexPath)?.isSelected = false
  }
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {return 78}
  
  override var preferredStatusBarStyle: UIStatusBarStyle {return .lightContent}
}
