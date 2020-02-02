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
    var txpower: Float = -62.0
    var uuid: String
    var beaconName: String
    var location_x: Float
    var location_y: Float
    
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
        
        print(uuid)
        
        locationManager?.startMonitoring(for: beaconRegion)
        locationManager?.startRangingBeacons(satisfying: constraint)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if let beacon = beacons.first {
            update(rssi: beacon.rssi)
            print(lastDistance)
        } else {
            update(rssi: 0)
            print("Couldn't find beacon")
        }
    }
    
    func update(rssi: Int) {
        lastDistance = rssi
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
    @ObservedObject var detectorOne = BeaconDetector(uuid: "a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1", beaconName: "iBeacon 1", location_x: 0.0, location_y: 3.0)
    @ObservedObject var detectorTwo = BeaconDetector(uuid: "b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2", beaconName: "iBeacon 2", location_x: 5.5, location_y: 3.0)
    @ObservedObject var detectorThree = BeaconDetector(uuid: "c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3c3", beaconName: "iBeacon 3", location_x: 0.0, location_y: 0.0)
    @ObservedObject var detectorFour = BeaconDetector(uuid: "d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4", beaconName: "iBeacon 4", location_x: 5.5, location_y: 0.0)
    
    @State private var active = false
    
    var body: some View {
        Form {
            HStack {
                Text("Host URL")
            }
            HStack {
                Toggle("Active", isOn: $active)
            }
            Spacer()
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
            Spacer()
            HStack {
                Text("Location")
                Spacer()
                Text(createLocationString(location: trilateration(d1: pathloss(rssi: detectorOne.lastDistance, tx_power: detectorOne.txpower), d2: pathloss(rssi: detectorTwo.lastDistance, tx_power: detectorTwo.txpower), d3: pathloss(rssi: detectorThree.lastDistance, tx_power: detectorThree.txpower), p: Float(5.5), q: Float(0.0), r: Float(3.0))))
            }
        }
    }
}

func pathloss(rssi: Int, tx_power: Float) -> Float {
    let n = 2.0
    let distance = powf(10.0, (tx_power - Float(rssi)) / Float(10.0 * n))
    print(distance)
    return distance
}

func trilateration(d1: Float, d2: Float, d3: Float, p: Float, q: Float, r: Float) -> Array<Float> {
    let x = (powf(d1, 2.0) - powf(d2, 2.0) + powf(p, 2.0)) / (2.0 * p)
    let y = ((powf(d1, 2.0) - powf(d2, 2.0) + powf(q, 2.0) + powf(r, 2.0)) / (2.0 * r)) - ((q / r) * x)
    return [x, y]
}

func createLocationString(location: Array<Float>) -> String {
    return "X: " + String(location[0]) + " Y: " + String(location[1])
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
