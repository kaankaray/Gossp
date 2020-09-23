//
//  MapViewController.swift
//  Gossp
//
//  Created by Kaan Karay on 2.08.2020.
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
import CircularProgressView

class MapViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
  
  // MARK: Variables
  var isCurrentLocation: Bool = true
  var locationManager: CLLocationManager!
  var currentLocation: CLLocation?
  var zoomLevel:Float = 17.0
  @IBOutlet var addButton: UIButton!
  var mapView: GMSMapView!
  var placesClient: GMSPlacesClient!
  var likelyPlaces: [GMSPlace] = []
  var selectedPlace: GMSPlace?
  var allLocations:Array<GosspLocation> = []
  var closeLocations:Array<GosspLocation> = []
  
  // MARK: Connections with storyboard
  @IBOutlet var tableViewContent: UITableView!
  
  // MARK: View layout
  
  @IBAction func addButtonAct(_ sender: Any) {
    //performSegue(withIdentifier: "segueShowNavigation", sender: self)
    randTaptic(3)
  }
  
  func doUIColorChanges() {
    self.view.backgroundColor = .gosspPurple
    tableViewContent.backgroundColor = .gosspPurple
    tableViewContent.separatorColor = UIColor.white
    addButton.tintColor = .gosspGreen
    
    self.navigationController?.navigationBar.barTintColor = .gosspPurple
    self.navigationController?.navigationBar.tintColor = .gosspGreen
    self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    UINavigationBar.appearance().barTintColor = .gosspPurple
    UINavigationBar.appearance().tintColor = .gosspGreen
    UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    
  }
  //MARK: ViewDid...
  override func viewDidLoad() {
    super.viewDidLoad()
    tableViewContent.delegate = self
    tableViewContent.dataSource = self
    
    // Initialize the location manager.
    locationManager = CLLocationManager()
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestAlwaysAuthorization()
    locationManager.distanceFilter = 5
    locationManager.startUpdatingLocation()
    locationManager.delegate = self
    placesClient = GMSPlacesClient.shared()
    
    // Create a map.
    let mapTableRatio:CGFloat = 0.5
    let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                          longitude: defaultLocation.coordinate.longitude,
                                          zoom: zoomLevel)
    
    mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0,
                                               width: self.view.frame.width,
                                               height: (self.view.frame.height *  mapTableRatio)), camera: camera)
    // Add the map to the view, hide it until we've got a location update.
    mapView.isMyLocationEnabled = true
    mapView.settings.scrollGestures = true
    mapView.settings.myLocationButton = false
    mapView.settings.rotateGestures = false
    mapView.settings.zoomGestures = true
    mapView.settings.tiltGestures = false
    mapView.isUserInteractionEnabled = false
    
    do {mapView.mapStyle = try GMSMapStyle(jsonString: mapStyle)} catch {NSLog("One or more of the map styles failed to load. \(error)")}
    view.addSubview(mapView)
    
    tableViewContent.frame = CGRect(x: 0, y: (self.view.frame.height * mapTableRatio), width: self.view.frame.width, height: (self.view.frame.height * (1 - mapTableRatio)))
    self.view.setNeedsDisplay()
    listLikelyPlaces()
  }
  var dist:Double = 0
  func showCloseLocations(_ location: CLLocation) {
    allLocations.forEach { (loc) in
      closeLocations = []
      loc.contCount.forEach { (user) in
        if user.pNumber == accPNumber {closeLocations.append(loc)}
      }
      loc.distance = CLLocation(latitude: CLLocationDegrees(loc.coordinates[0]),
                               longitude: CLLocationDegrees(loc.coordinates[1])).distance(from: location)
      //print("Distance for \($0.name) is \($0.distance)")
      if loc.distance < minDistanceToSee {closeLocations.append(loc)}
      let marker2 = GMSCircle()
      marker2.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(loc.coordinates[0]),
                                                longitude: CLLocationDegrees(loc.coordinates[1]))
      marker2.radius = loc.calculateRadius()
      marker2.fillColor = loc.color(alpha: 0.1)
      marker2.strokeWidth = 2
      marker2.strokeColor = loc.color(alpha: 0.8)
      marker2.map = mapView
    }
    //    closeLocations.forEach{$0.printLocation()}
    self.tableViewContent.reloadData()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    let image = UIImage(named: "GosspWide8") //Your logo url here
    let imageView = UIImageView(image: image)
    let bannerWidth = self.view.frame.width
    let bannerHeight = self.navigationController?.navigationBar.frame.size.height
    let bannerX = bannerWidth / 2 - (image?.size.width)! / 2
    let bannerY = bannerHeight! / 2 - (image?.size.height)! / 2
    imageView.frame = CGRect(x: bannerX, y: bannerY, width: bannerWidth, height: bannerHeight!)
    imageView.contentMode = .scaleAspectFit
    navigationItem.titleView = imageView
    navigationController?.navigationBar.barStyle = .black
    //self.navigationController?.isNavigationBarHidden = true
    //addButton.layer.zPosition = 10
    doUIColorChanges()
    DispatchQueue.global(qos: .background).async {
      _ = ref.child("locations").observe(DataEventType.value, with: { (snapshot) in
        let value = snapshot.value as? NSDictionary ?? [:]
        var realArray:Array<NSDictionary> = []
        self.mapView.clear()
        for k in 0...counters.locationCount{
          let p = value["value\(k)"] as? NSDictionary
          if p?["name"] as? String ?? "" != ""{realArray.append(value["value\(k)"] as! NSDictionary)}
        }
        DispatchQueue.main.async {
          //You got all the info, process and update the table view.
          self.allLocations = []
          realArray.forEach{self.allLocations.append(GosspLocation(rawValue: $0))}
          self.showCloseLocations(self.locationManager?.location ?? defaultLocation)
        }
      })
    }
  }
  
  // MARK: Map
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
    
    let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                          longitude: location.coordinate.longitude,
                                          zoom: zoomLevel)
    showCloseLocations(location)
    if mapView.isHidden {
      mapView.isHidden = false
      mapView.camera = camera
    } else {mapView.animate(to: camera)}
    
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
  
  // MARK: TableView Data
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return closeLocations.count}
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {return 123}
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as! LocationsListCellTableViewCell
    cell.useData(closeLocations[indexPath.row])
    cell.customSuperView = self
    return cell
  }
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as! LocationsListCellTableViewCell
    tableViewContent.deselectRow(at: indexPath, animated: true)
    cell.gosspLocation = closeLocations[indexPath.row]
    if !locationList.contains(closeLocations[indexPath.row].ID){cell.addOrActivateUser()}
    else {cell.useData(closeLocations[indexPath.row])}
    closeLocations[indexPath.row].printLocation()
    self.performSegue(withIdentifier: "showFeed", sender: indexPath.row)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
    if segue.identifier == "showFeed" {
      let feed = segue.destination as! LocationGosspsTableViewController
      feed.selectedLocation = closeLocations[sender as! Int]
      feed.setDisplay()
    }
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {return .lightContent}
  
}
