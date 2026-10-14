import CoreLocation
import Flutter
import MapKit
import UIKit

final class DrivingMapViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    DrivingMapView(frame: frame, viewId: viewId, messenger: messenger)
  }
}

final class DrivingMapView: NSObject, FlutterPlatformView, MKMapViewDelegate, CLLocationManagerDelegate {
  private let containerView: UIView
  private let mapView: MKMapView
  private let locationButton: UIButton
  private var locationButtonTopConstraint: NSLayoutConstraint!
  private let channel: FlutterMethodChannel
  private let locationManager = CLLocationManager()
  private var locationResult: FlutterResult?
  private var locationTimeout: DispatchWorkItem?
  private var waitingForLocation = false
  private var initialLocationRequested = false
  private var hasPositionedMap = false
  private var search: MKLocalSearch?
  private var selectedPlace: MKMapItem?
  private var placeAnnotation: MKPointAnnotation?
  private var placeRequest: AnyObject?

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
    containerView = UIView(frame: frame)
    mapView = MKMapView(frame: containerView.bounds)
    locationButton = UIButton(type: .system)
    channel = FlutterMethodChannel(
      name: "carwidget/driving_map_v1/\(viewId)",
      binaryMessenger: messenger
    )
    super.init()
    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    containerView.addSubview(mapView)
    mapView.delegate = self
    mapView.overrideUserInterfaceStyle = .light
    mapView.isPitchEnabled = false
    mapView.isScrollEnabled = true
    mapView.isZoomEnabled = true
    mapView.userTrackingMode = .none
    mapView.showsCompass = false
    if #available(iOS 16.0, *) {
      mapView.selectableMapFeatures = [.pointsOfInterest]
    }
    mapView.layoutMargins = UIEdgeInsets(top: 72, left: 12, bottom: 12, right: 12)
    locationButton.translatesAutoresizingMaskIntoConstraints = false
    locationButton.backgroundColor = .white
    locationButton.tintColor = UIColor(red: 22 / 255, green: 133 / 255, blue: 1, alpha: 1)
    locationButton.setImage(
      UIImage(systemName: "location", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23)),
      for: .normal
    )
    locationButton.layer.cornerRadius = 22
    locationButton.layer.shadowColor = UIColor.black.cgColor
    locationButton.layer.shadowOpacity = 0.16
    locationButton.layer.shadowRadius = 5
    locationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
    locationButton.accessibilityLabel = "Current location"
    locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
    containerView.addSubview(locationButton)
    locationButtonTopConstraint = locationButton.topAnchor.constraint(
      equalTo: containerView.topAnchor,
      constant: 14
    )
    NSLayoutConstraint.activate([
      locationButtonTopConstraint,
      locationButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
      locationButton.widthAnchor.constraint(equalToConstant: 44),
      locationButton.heightAnchor.constraint(equalToConstant: 44)
    ])
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "map_closed", message: "The map has closed.", details: nil))
        return
      }
      switch call.method {
      case "setExpanded":
        guard let expanded = call.arguments as? Bool else {
          result(FlutterError(code: "invalid_layout", message: "Invalid map layout.", details: nil))
          return
        }
        self.locationButtonTopConstraint.constant = expanded ? 70 : 14
        result(nil)
      case "centerOnUser":
        self.centerOnUser(result: result)
      case "search":
        guard let arguments = call.arguments as? [String: Any],
              let query = arguments["query"] as? String,
              !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
          result(FlutterError(code: "invalid_query", message: "Enter a place to search for.", details: nil))
          return
        }
        self.searchForPlace(query, result: result)
      case "clearSelection":
        self.clearSelection()
        result(nil)
      case "getDirections":
        guard let place = self.selectedPlace else {
          result(FlutterError(code: "place_missing", message: "Select a place first.", details: nil))
          return
        }
        if place.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]) {
          result(nil)
        } else {
          result(FlutterError(code: "directions_unavailable", message: "Could not open directions in Apple Maps.", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    centerInitiallyIfAuthorized()
  }

  deinit {
    channel.setMethodCallHandler(nil)
    search?.cancel()
    if #available(iOS 16.0, *) {
      (placeRequest as? MKMapItemRequest)?.cancel()
    }
    locationTimeout?.cancel()
    locationResult?(FlutterError(code: "map_closed", message: "The map has closed.", details: nil))
    mapView.showsUserLocation = false
    mapView.delegate = nil
    locationManager.delegate = nil
  }

  func view() -> UIView { containerView }

  @objc private func locationButtonTapped() {
    locationButton.isEnabled = false
    centerOnUser(result: { [weak self] response in
      guard let self = self else { return }
      self.locationButton.isEnabled = true
      if let error = response as? FlutterError {
        self.channel.invokeMethod("locationError", arguments: error.message)
      }
    })
  }

  private var authorizationStatus: CLAuthorizationStatus {
    if #available(iOS 14.0, *) { return locationManager.authorizationStatus }
    return CLLocationManager.authorizationStatus()
  }

  private func centerInitiallyIfAuthorized() {
    guard !initialLocationRequested,
          authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
    initialLocationRequested = true
    // Only the location button prompts for permission; existing permission is reused.
    centerOnUser(result: nil)
  }

  private func centerOnUser(result: FlutterResult?) {
    if result != nil {
      initialLocationRequested = true
    }
    guard !waitingForLocation else {
      if locationResult == nil {
        locationResult = result
      } else {
        result?(FlutterError(code: "location_pending", message: "Your location is still being found.", details: nil))
      }
      return
    }
    guard CLLocationManager.locationServicesEnabled() else {
      result?(FlutterError(code: "location_disabled", message: "Enable Location Services to center the map.", details: nil))
      return
    }
    switch authorizationStatus {
    case .denied, .restricted:
      result?(FlutterError(code: "location_denied", message: "Allow location access in Settings to center the map.", details: nil))
      return
    case .notDetermined:
      guard result != nil else { return }
      locationResult = result
      waitingForLocation = true
      locationManager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse:
      locationResult = result
      waitingForLocation = true
      requestLocation()
    @unknown default:
      result?(FlutterError(code: "location_unavailable", message: "Your current location is unavailable.", details: nil))
    }
  }

  private func requestLocation() {
    mapView.showsUserLocation = true
    if let location = locationManager.location,
       location.horizontalAccuracy >= 0,
       abs(location.timestamp.timeIntervalSinceNow) < 60 {
      showLocation(location)
      return
    }
    locationManager.requestLocation()
    locationTimeout?.cancel()
    let timeout = DispatchWorkItem { [weak self] in
      self?.finishLocation(FlutterError(code: "location_timeout", message: "Could not find your location. Try again.", details: nil))
    }
    locationTimeout = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeout)
  }

  private func showLocation(_ location: CLLocation) {
    guard waitingForLocation else { return }
    mapView.setUserTrackingMode(.none, animated: false)
    if !hasPositionedMap {
      mapView.setRegion(
        MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1600, longitudinalMeters: 1600),
        animated: true
      )
    } else {
      // Recenter once without changing the zoom or enabling location tracking.
      mapView.setCenter(location.coordinate, animated: true)
    }
    hasPositionedMap = true
    finishLocation(nil)
  }

  private func finishLocation(_ error: FlutterError?) {
    waitingForLocation = false
    locationTimeout?.cancel()
    locationTimeout = nil
    let result = locationResult
    locationResult = nil
    result?(error)
  }

  private func authorizationChanged() {
    if waitingForLocation {
      switch authorizationStatus {
      case .authorizedAlways, .authorizedWhenInUse:
        requestLocation()
      case .denied, .restricted:
        mapView.showsUserLocation = false
        finishLocation(FlutterError(code: "location_denied", message: "Allow location access in Settings to center the map.", details: nil))
      default:
        break
      }
    } else {
      mapView.showsUserLocation = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
      centerInitiallyIfAuthorized()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationChanged()
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if #available(iOS 14.0, *) { return }
    authorizationChanged()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
    showLocation(location)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishLocation(FlutterError(code: "location_unavailable", message: "Your current location is unavailable. Try again.", details: nil))
  }

  private func searchForPlace(_ query: String, result: @escaping FlutterResult) {
    initialLocationRequested = true
    finishLocation(nil)
    search?.cancel()
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    request.region = mapView.region
    let activeSearch = MKLocalSearch(request: request)
    search = activeSearch
    activeSearch.start { [weak self] response, error in
      DispatchQueue.main.async {
        guard let self = self else {
          result(FlutterError(code: "map_closed", message: "The map has closed.", details: nil))
          return
        }
        guard self.search === activeSearch else {
          result(nil)
          return
        }
        self.search = nil
        if error != nil {
          result(FlutterError(code: "search_failed", message: "Search is unavailable. Check your internet connection.", details: nil))
          return
        }
        guard let item = response?.mapItems.first else {
          result(FlutterError(code: "place_not_found", message: "No matching places found.", details: nil))
          return
        }
        // A completed location request must not override the selected search result.
        self.finishLocation(nil)
        self.clearSelection()
        let annotation = MKPointAnnotation()
        annotation.coordinate = item.placemark.coordinate
        annotation.title = item.name
        self.placeAnnotation = annotation
        self.mapView.addAnnotation(annotation)
        self.hasPositionedMap = true
        self.mapView.setUserTrackingMode(.none, animated: false)
        self.mapView.setRegion(
          MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1600, longitudinalMeters: 1600),
          animated: true
        )
        self.mapView.selectAnnotation(annotation, animated: true)
        self.showPlace(item)
        result(nil)
      }
    }
  }

  private func showPlace(_ item: MKMapItem) {
    selectedPlace = item
    channel.invokeMethod("placeSelected", arguments: [
      "name": item.name ?? "Selected place",
      "address": item.placemark.title ?? ""
    ])
  }

  private func clearSelection() {
    if #available(iOS 16.0, *) {
      let request = placeRequest as? MKMapItemRequest
      placeRequest = nil
      request?.cancel()
    }
    selectedPlace = nil
    for annotation in mapView.selectedAnnotations {
      mapView.deselectAnnotation(annotation, animated: false)
    }
    if let annotation = placeAnnotation {
      mapView.removeAnnotation(annotation)
      placeAnnotation = nil
    }
    channel.invokeMethod("placeCleared", arguments: nil)
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard !(annotation is MKUserLocation) else { return nil }
    let identifier = "DrivingPlace"
    let marker = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
      ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
    marker.annotation = annotation
    marker.canShowCallout = false
    marker.markerTintColor = .systemOrange
    marker.glyphImage = UIImage(systemName: "mappin")
    return marker
  }

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    guard !(view.annotation is MKUserLocation) else { return }
    if #available(iOS 16.0, *), let feature = view.annotation as? MKMapFeatureAnnotation {
      initialLocationRequested = true
      finishLocation(nil)
      search?.cancel()
      search = nil
      selectedPlace = nil
      channel.invokeMethod("placeCleared", arguments: nil)
      (placeRequest as? MKMapItemRequest)?.cancel()
      let request = MKMapItemRequest(mapFeatureAnnotation: feature)
      placeRequest = request
      request.getMapItem { [weak self] item, _ in
        DispatchQueue.main.async {
          guard let self = self, self.placeRequest === request else { return }
          self.placeRequest = nil
          guard let item = item else {
            self.channel.invokeMethod("placeError", arguments: "Could not load this place. Try again.")
            return
          }
          self.finishLocation(nil)
          self.showPlace(item)
        }
      }
    } else if let annotation = placeAnnotation, view.annotation === annotation,
              let item = selectedPlace {
      showPlace(item)
    }
  }

  func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    guard hasActiveGesture(in: mapView) else { return }
    hasPositionedMap = true
    initialLocationRequested = true
    // A manual pan takes priority over a pending initial location request.
    finishLocation(nil)
  }

  private func hasActiveGesture(in view: UIView) -> Bool {
    if (view.gestureRecognizers ?? []).contains(where: { $0.state == .began || $0.state == .changed }) {
      return true
    }
    return view.subviews.contains { hasActiveGesture(in: $0) }
  }

  func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
    channel.invokeMethod("mapError", arguments: nil)
  }
}
