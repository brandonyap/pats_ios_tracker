//
//  BeaconDetector.swift
//  pats_ios_tracker
//
//  Created by Brandon Yap on 2020-02-05.
//  Copyright © 2020 Brandon Yap. All rights reserved.
//

import Combine
import CoreLocation
import SwiftUI

class BeaconDetector: NSObject, ObservableObject, CLLocationManagerDelegate, Identifiable {
    var objectWillChange = PassthroughSubject<Void, Never>()
    var locationManager: CLLocationManager?
    var lastDistance: CLLocationAccuracy = Double.infinity
    var currentDistance: CLLocationAccuracy = 0
    var txpower: Float = -62.0
    var uuid: String
    var beaconName: String
    var location_x: Float
    var location_y: Float
    
    var filter = KalmanFilter(stateEstimatePrior: 0.0, errorCovariancePrior: 1)

    init(uuid: String, beaconName: String, location_x: Float, location_y: Float) {
        self.uuid = uuid
        self.beaconName = beaconName
        self.location_x = location_x
        self.location_y = location_y
        super.init()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    print("Starting Scan")
                    startScanning()
                }
            }
        }
    }
    
    func startScanning() {
        let uuid = UUID(uuidString: self.stringToUuidFormat(string: self.uuid))!
        let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 0, minor: 0)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: self.beaconName)
                
        locationManager?.startMonitoring(for: beaconRegion)
        locationManager?.startRangingBeacons(satisfying: constraint)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if let beacon = beacons.first {
            update(rssi: beacon.accuracy)
//            print(lastDistance)
        } else {
            updateNotFound(rssi: Double.infinity)
            print("Couldn't find beacon")
        }
    }
    
    func update(rssi: CLLocationAccuracy) {
        let prediction = filter.predict(stateTransitionModel: 1, controlInputModel: 0, controlVector: 0, covarianceOfProcessNoise: 0)
        let update = prediction.update(measurement: rssi, observationModel: 1, covarienceOfObservationNoise: 0.1)
        
        filter = update
        
        currentDistance = filter.stateEstimatePrior
        lastDistance = currentDistance
        objectWillChange.send(())
    }
    
    func updateNotFound(rssi: CLLocationAccuracy) {
        lastDistance = rssi
        objectWillChange.send(())
    }
    
    func stringToUuidFormat(string: String) -> String {
        let characters = Array(string)
        let uuidString = String(characters[..<8]) + "-" + String(characters[8...11]) + "-" + String(characters[12...15]) + "-" + String(characters[16...19]) + "-" + String(characters[20...])
        return uuidString
    }
}
