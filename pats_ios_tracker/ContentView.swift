//
//  ContentView.swift
//  pats_ios_tracker
//
//  Created by Brandon Yap on 2020-01-29.
//  Copyright © 2020 Brandon Yap. All rights reserved.
//

import Combine
import CoreLocation
import SwiftUI

class BeaconDetector: NSObject, ObservableObject, CLLocationManagerDelegate {
    var objectWillChange = PassthroughSubject<Void, Never>()
    var locationManager: CLLocationManager?
    var lastDistance = 0
    var uuid: String
    var beaconName: String
    
    init(uuid: String, beaconName: String) {
        self.uuid = uuid
        self.beaconName = beaconName
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
        
        print(uuid)
        
        locationManager?.startMonitoring(for: beaconRegion)
        locationManager?.startRangingBeacons(satisfying: constraint)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if let beacon = beacons.first {
            update(distance: beacon.rssi)
            print(lastDistance)
        } else {
            update(distance: 0)
            print("Couldn't find beacon")
        }
    }
    
    func update(distance: Int) {
        lastDistance = distance
        objectWillChange.send(())
    }
    
    func stringToUuidFormat(string: String) -> String {
        let characters = Array(string)
        let uuidString = String(characters[..<8]) + "-" + String(characters[8...11]) + "-" + String(characters[12...15]) + "-" + String(characters[16...19]) + "-" + String(characters[20...])
        print(uuidString)
        return uuidString
    }
}

struct BigText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 72, design: .rounded))
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }
}

struct ContentView: View {
    @ObservedObject var detectorOne = BeaconDetector(uuid: "a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1", beaconName: "iBeacon 1")
    @ObservedObject var detectorTwo = BeaconDetector(uuid: "b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2", beaconName: "iBeacon 2")
    @ObservedObject var detectorThree = BeaconDetector(uuid: "c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3", beaconName: "iBeacon 3")
    @ObservedObject var detectorFour = BeaconDetector(uuid: "d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4", beaconName: "iBeacon 4")
    
    var body: some View {
        Form {
            HStack {
                Text("Beacon 1 Signal Strength")
                Spacer()
                Text(String(detectorOne.lastDistance))
            }
            HStack {
                Text("Beacon 2 Signal Strength")
                Spacer()
                Text(String(detectorTwo.lastDistance))
            }
            HStack {
                Text("Beacon 3 Signal Strength")
                Spacer()
                Text(String(detectorThree.lastDistance))
            }
            HStack {
                Text("Beacon 4 Signal Strength")
                Spacer()
                Text(String(detectorFour.lastDistance))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
