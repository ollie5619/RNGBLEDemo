//
//  ViewController.swift
//  BLEDemo
//
//  Created by admin on 2023/7/28.
//

import UIKit
import RNGBLE
extension Int {
    /// In order to remove the Optional() display
    func stringDescribing() -> String {
        String(describing: self)
    }
}
extension Int64 {
    /// In order to remove the Optional() display
    func stringDescribing() -> String {
        String(describing: self)
    }
}
extension Double {
    func decimalStringValue(_ scale: Int16 = 3, roundingMode: NSDecimalNumber.RoundingMode = .plain) -> String {
        NSDecimalNumber(value: self).multiplying(by: NSDecimalNumber(value: 1), withBehavior: NSDecimalNumberHandler(roundingMode: roundingMode, scale: scale, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)).stringValue
    }
}
class ViewController: UIViewController {
    @IBOutlet weak var tableV: UITableView!
    private var bleManager = RNGBLEManager()
    /// Scanned Bluetooth list No duplicates
    /// * Empty: every time you rescan / Bluetooth off
    /// * New: when broadcasting
    private var scanPeripherals = [RNGPeripheral]()
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Bluetooth List"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(rightBarAction))
        tableV.delegate = self
        tableV.dataSource = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bleManager.delegate = self
        scanDevice()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bleManager.centralManager.stopScan()
    }
    @objc private func rightBarAction() {
        scanDevice()
    }
    private func scanDevice() {
        scanPeripherals.removeAll() // Rescan Reset
        bleManager.scanDevice()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        scanPeripherals.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cb = scanPeripherals[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        [
            (1, cb.name),
            (2, "MAC " + (cb.macAddress ?? "")),
            (3, "UUID " + cb.identifier.uuidString),
            (4, "RSSI " + (cb.RSSIIntValue?.stringDescribing() ?? "")),
        ].forEach { i, t in
            (
                cell?.contentView.subviews.filter { $0.tag == i } .first as? UILabel
            )?.text = t
        }
        return cell ?? .init()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailVC") as? DetailVC else { return }
        vc.currPeripheral = scanPeripherals[indexPath.row]
        vc.bleManager = bleManager
        show(vc, sender: self)
    }
}
extension ViewController: RNGBLEManagerDelegate {
    func centralManagerDidUpdateState(_ central: RNGBLE.RNGCentralManager, msg: String?) {
        switch central.state {
        case .poweredOn: scanDevice()
        case .poweredOff: // Turning off Bluetooth doesn't go to the Bluetooth disconnect callback, it needs to be processed again
            ToastManager.share.showErr(in: view, text: msg)
            scanPeripherals.removeAll() // Turn off Bluetooth reset
            tableV.reloadData()
        case .unauthorized: ToastManager.share.showErr(in: view, text: msg)
        case .unsupported: ToastManager.share.showErr(in: view, text: msg)
        default: break
        }
    }
    func centralManager(_ central: RNGCentralManager, didDiscover peripheral: RNGPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !scanPeripherals.contains(where: { $0.identifier.uuidString == peripheral.identifier.uuidString }) {
            scanPeripherals.append(peripheral)
        }
        tableV.reloadData()
    }
    func centralManager(_ central: RNGCentralManager, didDisconnectPeripheral peripheral: RNGPeripheral, error: Error?) {
        
    }
    func peripheral(_ peripheral: RNGPeripheral, didUpdateNotificationStateFor characteristic: RNGCharacteristic, error: Error?) {
        
    }
    func peripheral(_ peripheral: RNGPeripheral, didUpdateValueFor characteristic: RNGCharacteristic, error: Error?) {
        
    }
    func commandWillSend(_ command: RNGCommandProtocol) {
        
    }
    func commandSendResult() {
        
    }
}
