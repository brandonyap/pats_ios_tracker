//
//  ContentView.swift
//  pats_ios_tracker
//
//  Created by Brandon Yap on 2020-01-29.
//  Copyright © 2020 Brandon Yap. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var active = false
    @State private var url_address = ""
    @ObservedObject var settingStore = SettingStore()
    @ObservedObject var store = BeaconLocationStore()
    @ObservedObject var beaconStore = BeaconDetectorStore()
    let timer = Timer.publish(every: 0.5, on: .current, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        TextField("Example: 0.0.0.0:7000", text: $url_address)
                    }
                }
                if (active) {
                    Section {
                        ForEach(beaconStore.beacons) { beacon in
                            HStack {
                                Text(String(beacon.beaconName + " Signal Strength"))
                                Spacer()
                                Text(String(beacon.lastDistance))
                            }
                        }
                    }
                    Section {
                        HStack {
                            Text("Location")
                            Spacer()
                            Text(createLocationString(location: trilaterationNew(beacons: beaconStore.beacons)))
                        }
                    }
                }
            }.navigationBarTitle(Text("iPats Tracker"))
                .navigationBarItems(leading: Button(action: startStop) {
                    if (active) {
                        Text("Stop")
                    } else {
                        Text("Start")
                    }
                }, trailing: Button(action: save) {
                    Text("Save Address")
                })
        }.onAppear(perform: onStart).onReceive(timer) {_ in
            self.beaconStore.objectWillChange.send()
        }
    }
    
    func save() {
        self.settingStore.url_address = url_address
        UserDefaults.standard.set(self.settingStore.url_address, forKey: "address")
        print("Saved URL Address: " + self.settingStore.url_address)
    }
    
    func startStop() {
        if (self.active) {
            self.active = false;
            self.beaconStore.beacons.removeAll()
        } else {
            self.active = true;
            self.loadBeacons()
        }
    }
    
    func onStart() {
        self.url_address = self.settingStore.url_address
    }
    
    func loadBeacons() {
        guard let url = URL(string: "http://" + settingStore.url_address + "/api/beacons/group/1/location/all") else {
            print("Invalid URL")
            return
        }
        print(url)
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                // OH NO! An error occurred...
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return
            }
            if let data = data {
                if let decodedResponse = try?
                    JSONDecoder().decode(BeaconLocationListResponse.self, from: data) {
                    
                    // we have good data – go back to the main thread
                    DispatchQueue.main.async {
                        // update our UI
                        decodedResponse.data.forEach() { beacon in
                            self.beaconStore.beacons.append(BeaconDetector(uuid: beacon.uuid, beaconName: "Beacon " + String(beacon.beacons_id), location_x: beacon.location_x, location_y: beacon.location_y))
                        }
                    }
                    // everything is good, so we can exit
                    return
                }
            }
        }.resume()
    }
    
//    func update() {
//        self.store.beacons.forEach() { beacon in
//            self.beaconStore.beacons.append(BeaconDetector(uuid: beacon.uuid, beaconName: String(beacon.beacons_id), location_x: beacon.location_x, location_y: beacon.location_y))
//        }
//    }
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

func trilaterationNew(beacons: [BeaconDetector]) -> Array<Float> {
    if (beacons.count < 3) {
        return [0, 0]
    }
    let sorted = beacons.sorted(by: { $0.lastDistance > $1.lastDistance })
    let beacon_1 = sorted[0]
    let beacon_2 = sorted[1]
    let beacon_3 = sorted[2]
    
    let r1 = pathloss(rssi: beacon_1.lastDistance, tx_power: beacon_1.txpower)
    let r2 = pathloss(rssi: beacon_2.lastDistance, tx_power: beacon_2.txpower)
    let r3 = pathloss(rssi: beacon_3.lastDistance, tx_power: beacon_3.txpower)
    
    let A = 2*beacon_2.location_x - 2*beacon_1.location_x
    let B = 2*beacon_2.location_y - 2*beacon_2.location_y
    let C = powf(r1, 2.0) - powf(r2, 2.0) - powf(beacon_1.location_x, 2.0) + powf(beacon_2.location_x, 2.0) - powf(beacon_1.location_y, 2.0) + powf(beacon_2.location_y, 2.0)
    let D = 2*beacon_3.location_x - 2*beacon_2.location_x
    let E = 2*beacon_3.location_y - 2*beacon_2.location_y
    let F = powf(r2, 2.0) - powf(r3, 2.0) - powf(beacon_2.location_x, 2.0) + powf(beacon_3.location_x, 2.0) - powf(beacon_2.location_y, 2.0) + powf(beacon_3.location_y, 2.0)
    let x = (C*E - F*B) / (E*A - B*D)
    let y = (C*D - A*F) / (B*D - A*E)
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
