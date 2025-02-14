//
//  DetailVC.swift
//  BLEDemo
//
//  Created by admin on 2023/7/28.
//

import Foundation
import UIKit
import RNGBLE
class DetailVC: UIViewController {
    @IBOutlet weak var bleStateL: UILabel!
    @IBOutlet weak var disconnectBtn: UIButton!
    @IBOutlet weak var reconnectBtn: UIButton!
    @IBOutlet weak var infoReadBtn: UIButton!
    private let textV = UITextView()
    weak var bleManager: RNGBLEManager?
    var currPeripheral: RNGPeripheral!
    private var controllerSKU: String?, model_ctrl = BLEControllerModel(), model_riv = BLEInverterModel(), model_batt = BLEBatteryModel()
    deinit {
        disconnectBtn_action(disconnectBtn)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currPeripheral.name
        textV.font = .systemFont(ofSize: 18)
        view.addSubview(textV)
        bleManager?.delegate = self
        reconnectBtn_action(reconnectBtn)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let y = infoReadBtn.frame.maxY + 20
        textV.frame = .init(x: 20, y: y, width: view.bounds.width - 40, height: view.bounds.height - (view.window?.safeAreaInsets.bottom ?? 0) - y)
    }
    @IBAction func disconnectBtn_action(_ sender: UIButton) {
        guard currPeripheral.state != .disconnected else {
            bleStateL.text = "BLE Disconnected"
            return
        }
        bleStateL.text = "BLE Disconnecting"
        bleManager?.cleanup(currPeripheral)
    }
    @IBAction func reconnectBtn_action(_ sender: UIButton) {
        guard currPeripheral.state != .connected else {
            bleStateL.text = "BLE Connected"
            return
        }
        bleStateL.text = "BLE Connecting"
        bleManager?.connect(currPeripheral)
    }
    @IBAction func infoReadBtn_action(_ sender: UIButton) {
        guard currPeripheral.state == .connected else {
            ToastManager.share.showErr(in: view, text: "BLE Disconnected")
            return
        }
        ToastManager.share.loading(in: view)
        currPeripheral.isController(bleManager) { isController, SKU in
            guard isController, let SKU else {
                self.getInverter()
                return
            }
            ToastManager.share.stopLoading()
            let address: UInt8 = 0xFF
            self.model_ctrl.deviceSku = SKU
            self.bleManager?.send(self.currPeripheral, commandList: [
                RNGCommandController.address(address),
                RNGCommandController.batterySOC(address),
                RNGCommandController.batteryChargingVolts(address),
                RNGCommandController.batteryChargingAmps(address),
                RNGCommandController.temperatures(address),
                RNGCommandController.dcVolts(address),
                RNGCommandController.dcAmps(address),
                RNGCommandController.dcWatts(address),
                RNGCommandController.pvVolts(address),
                RNGCommandController.pvAmps(address),
                RNGCommandController.pvChargingWatts(address),
                RNGCommandController.powerGenerationToday(address),
                RNGCommandController.totalRunningDays(address),
                RNGCommandController.batteryTotalDiscTimes(address),
                RNGCommandController.batteryTotalCharTimes(address),
                RNGCommandController.batteryAhChar(address),
                RNGCommandController.batteryAhDisc(address),
                RNGCommandController.powerGeneration(address),
                RNGCommandController.powerUse(address),
                RNGCommandController.isOnLoad_chargeStatus(address),
                RNGCommandController.errList(address),
                RNGCommandController.voltSystem(address),
                RNGCommandController.batteryType(address),
                RNGCommandController.voltEqualization(address),
                RNGCommandController.voltBoost(address),
                RNGCommandController.voltFloat(address),
                RNGCommandController.voltLowReconnect(address),
                RNGCommandController.voltUnderRecoverWarning(address),
                RNGCommandController.voltLowDisconnect(address),
                RNGCommandController.timeBoost(address),
                RNGCommandController.loadMode(address),
                RNGCommandController.getSoftwareVersion(address),
                RNGCommandController.getHardwareVersion(address),
            ], commandsAllSend: true) { singleSuccess, commandIdx, command, receivedList in
                guard singleSuccess, let command = command as? RNGCommandController, let receivedList else { return }
                self.model_ctrl = command.getData(self.model_ctrl, deviceSku: SKU, receivedList: receivedList)
                self.textV.text = """
                BLE Mac: \(self.currPeripheral.macAddress ?? "")
                BLE UUID: \(self.currPeripheral.identifier.uuidString)
                Device Type: Controller
                
                Device Address: \(self.model_ctrl.deviceAddress?.stringDescribing() ?? "")
                Device SKU: \(SKU)
                batterySOC: \(self.model_ctrl.batterySOC?.stringDescribing() ?? "")
                batteryChargingVolts: \(self.model_ctrl.batteryChargingVolts?.decimalStringValue() ?? "") V
                batteryChargingAmps: \(self.model_ctrl.batteryChargingAmps?.decimalStringValue() ?? "") A
                batteryChargingPower: \(self.model_ctrl.batteryChargingPower?.decimalStringValue() ?? "") W
                controllerTemperature: \(self.model_ctrl.controllerTemperature?.stringDescribing() ?? "") ℃
                batteryTemperature: \(self.model_ctrl.batteryTemperature?.stringDescribing() ?? "") ℃
                
                dcVolts: \(self.model_ctrl.dcVolts?.decimalStringValue() ?? "") V
                dcAmps: \(self.model_ctrl.dcAmps?.decimalStringValue() ?? "") A
                dcWatts: \(self.model_ctrl.dcWatts?.stringDescribing() ?? "") W
                pvChargingWatts: \(self.model_ctrl.pvChargingWatts?.stringDescribing() ?? "") W
                loadMode: \(self.model_ctrl.loadMode?.localized ?? "")
                pvVolts: \(self.model_ctrl.pvVolts?.decimalStringValue() ?? "") V
                pvAmps: \(self.model_ctrl.pvAmps?.decimalStringValue() ?? "") A
                
                powerGenerationToday: \(self.model_ctrl.powerGenerationToday?.decimalStringValue() ?? "") W
                totalRunningDays: \(self.model_ctrl.totalRunningDays?.stringDescribing() ?? "")
                batteryTotalDiscTimes: \(self.model_ctrl.batteryTotalDiscTimes?.stringDescribing() ?? "")
                batteryTotalCharTimes: \(self.model_ctrl.batteryTotalCharTimes?.stringDescribing() ?? "")
                batteryAhChar: \(self.model_ctrl.batteryAhChar?.stringDescribing() ?? "") Ah
                batteryAhDisc: \(self.model_ctrl.batteryAhDisc?.stringDescribing() ?? "") Ah
                powerGeneration: \(self.model_ctrl.powerGeneration?.decimalStringValue() ?? "") W
                powerUse: \(self.model_ctrl.powerUse?.decimalStringValue() ?? "") W
                
                isOnLoad: \(self.model_ctrl.isOnLoad ?? false)
                chargeStatus: \(self.model_ctrl.chargeStatus?.localized ?? "")
                voltSystem: \(self.model_ctrl.voltSystem?.localized ?? "") V
                batteryType: \(self.model_ctrl.batteryType?.localized ?? "")
                
                voltEqualization: \(self.model_ctrl.voltEqualization?.decimalStringValue() ?? "") V
                voltBoost: \(self.model_ctrl.voltBoost?.decimalStringValue() ?? "") V
                voltFloat: \(self.model_ctrl.voltFloat?.decimalStringValue() ?? "") V
                voltLowReconnect: \(self.model_ctrl.voltLowReconnect?.decimalStringValue() ?? "") V
                voltUnderRecoverWarning: \(self.model_ctrl.voltUnderRecoverWarning?.decimalStringValue() ?? "") V
                voltLowDisconnect: \(self.model_ctrl.voltLowDisconnect?.decimalStringValue() ?? "") V
                timeBoost: \(self.model_ctrl.timeBoost?.stringDescribing() ?? "")
                
                errList: \(self.model_ctrl.errList.map { $0.message } )
                """
                self.textV.sizeToFit()
            }
        }
    }
    private func getInverter() {
        currPeripheral.isInverter(bleManager) { isInverter, address_deviceSku in
            ToastManager.share.stopLoading()
            guard isInverter, let address_deviceSku else {
                self.getBattery()
                return
            }
            let address: UInt8 = 0xFF
            self.bleManager?.send(self.currPeripheral, commandList: [
                RNGCommandInverter.address(address),
                RNGCommandInverter.outputVoltage(address),
                RNGCommandInverter.outputAmps(address),
                RNGCommandInverter.outputFrequency(address),
                RNGCommandInverter.batteryVoltage(address),
                RNGCommandInverter.temperature(address),
                RNGCommandInverter.errList_x0FA7(address),
                RNGCommandInverter.mode(address),
                RNGCommandInverter.errList_x112E_4(address),
            ], commandsAllSend: true) { singleSuccess, commandIdx, command, receivedList in
                guard singleSuccess, let command = command as? RNGCommandInverter, let receivedList else { return }
                self.model_riv = command.getData(self.model_riv, receivedList: receivedList)
                self.textV.text = """
                BLE Mac: \(self.currPeripheral.macAddress ?? "")
                BLE UUID: \(self.currPeripheral.identifier.uuidString)
                Device Type: Battery
                
                Device Address: \(address_deviceSku.address)
                Device SKU: \(address_deviceSku.deviceSku)
                outputVoltage: \(self.model_riv.outputVoltage?.decimalStringValue() ?? "") V
                outputAmps: \(self.model_riv.outputAmps?.decimalStringValue() ?? "") A
                outputPower: \(self.model_riv.outputPower?.decimalStringValue() ?? "") W
                outputFrequency: \(self.model_riv.outputFrequency?.decimalStringValue() ?? "") Hz
                batteryVoltage: \(self.model_riv.batteryVoltage?.decimalStringValue() ?? "") V
                temperature: \(self.model_riv.temperature?.decimalStringValue() ?? "") ℃
                mode: \(self.model_riv.mode?.localized ?? "")
                
                errList: \(self.model_riv.errList.map { $0.message } )
                """
                self.textV.sizeToFit()
            }
        }
    }
    private func getBattery() {
        currPeripheral.isBattery(bleManager) { isBattery, address_deviceSku in
            ToastManager.share.stopLoading()
            guard isBattery, let address_deviceSku else {
                self.textV.text = """
                BLE Mac: \(self.currPeripheral.macAddress ?? "")
                BLE UUID: \(self.currPeripheral.identifier.uuidString)
                Device Type: Temporarily unsupported device type
                """
                self.textV.sizeToFit()
                return
            }
            let address: UInt8 = 0xFF
            self.bleManager?.send(self.currPeripheral, commandList: [
                RNGCommandBattery.Address(address),
                RNGCommandBattery.ChargingDischarging(address),
                RNGCommandBattery.cellVolts(address),
                RNGCommandBattery.maxMinTemperatures(address),
                RNGCommandBattery.currAmps(address),
                RNGCommandBattery.volts(address),
                RNGCommandBattery.remainingAh(address),
                RNGCommandBattery.totalAhPercentageAh(address),
                RNGCommandBattery.errListHeatingModuleStatus(address),
                RNGCommandBattery.selfDevelopedBatteryInfo(address),
                RNGCommandBattery.softwareVersion(address),
            ], commandsAllSend: true) { singleSuccess, commandIdx, command, receivedList in
                guard singleSuccess, let command = command as? RNGCommandBattery, let receivedList else { return }
                self.model_batt = command.getData(self.model_batt, receivedList: receivedList, deviceSku: address_deviceSku.deviceSku)
                self.textV.text = """
                BLE Mac: \(self.currPeripheral.macAddress ?? "")
                BLE UUID: \(self.currPeripheral.identifier.uuidString)
                Device Type: Inverter
                
                Device Address: \(address_deviceSku.address)
                Device SKU: \(address_deviceSku.deviceSku)
                cellVolts: \(self.model_batt.cellVolts)
                maxCellTemperature: \(self.model_batt.maxCellTemperature?.decimalStringValue() ?? "") ℃
                minCellTemperature: \(self.model_batt.minCellTemperature?.decimalStringValue() ?? "") ℃
                currAmps: \(self.model_batt.currAmps?.decimalStringValue() ?? "") A
                volts: \(self.model_batt.volts?.decimalStringValue() ?? "") V
                remainingAh: \(self.model_batt.remainingAh?.decimalStringValue() ?? "") Ah
                totalAh: \(self.model_batt.totalAh?.decimalStringValue() ?? "") Ah
                percentageAh: \(self.model_batt.percentageAh?.decimalStringValue() ?? "") Ah
                heatingModuleStatus: \(self.model_batt.heatingModuleStatus ?? false)
                ManufactureVersion: \(self.model_batt.ManufactureVersion ?? "")
                MainLineVersion: \(self.model_batt.MainLineVersion ?? "")
                CommunicationProtocolVersion: \(self.model_batt.CommunicationProtocolVersion ?? "")
                Model: \(self.model_batt.Model ?? "")
                softwareVersion: \(self.model_batt.softwareVersion ?? "")
                ManufacturerName: \(self.model_batt.ManufacturerName ?? "")
                
                errList: \(self.model_batt.errList.map { $0.message } )
                """
                self.textV.sizeToFit()
            }
        }
    }
    private func readHistory() {
        let address: UInt8 = 0xFF
        RNGCommandController.getHistory(bleManager, peripheral: currPeripheral, address: address, targetDay: 0) { model in
            /// Power consumption for the day
            let powerGenerate = model.powerGenerate
            /// The amount of electricity generated during the day
            let powerUse = model.powerUse
        }
        var data30 = [BLEControllerHistoryModel]()
        (0...29).forEach {
            RNGCommandController.getHistory(bleManager, peripheral: currPeripheral, address: address, targetDay: $0) { model in
                /// Power consumption in the first $0 days
                let powerGenerate = model.powerGenerate
                /// Previous $0 days power generation
                let powerUse = model.powerUse
                
                data30.append(model)
            }
        }
    }
    func setParamTest() {
        let address: UInt8 = 0xFF, newSystemVolt = ControllerSystemVolt._24 // Set the new system voltage to 24V
        bleManager?.send(currPeripheral, commandList: [
            RNGCommandController.voltSystem(address, funcCode: .set(newSystemVolt.settingData))
        ]) { singleSuccess, commandIdx, command, receivedList in
            // singleSuccess Setting Success/Failure Handling
        }
        RNGCommandController.setBatteryType(bleManager, peripheral: currPeripheral, address: address, newValue: .Li) { success in
            // success Setting Success/Failure Handling
        }
    }
}
extension DetailVC: RNGBLEManagerDelegate {
    func centralManagerDidUpdateState(_ central: RNGBLE.RNGCentralManager, msg: String?) {
        switch central.state {
        case .poweredOff:
            bleStateL.text = "BLE Closed"
            controllerSKU = nil
        default: break
        }
    }
    func peripheral(_ peripheral: RNGPeripheral, didUpdateNotificationStateFor characteristic: RNGCharacteristic, error: Error?) {
        guard currPeripheral.identifier.uuidString == peripheral.identifier.uuidString else {
            bleManager?.cleanup(peripheral)
            return
        }
        currPeripheral = peripheral
        bleStateL.text = "BLE Connected"
        infoReadBtn_action(infoReadBtn)
    }
    func peripheral(_ peripheral: RNGPeripheral, didUpdateValueFor characteristic: RNGCharacteristic, error: Error?) {
        print(characteristic.value as Any, error as Any)
    }
    func centralManager(_ central: RNGCentralManager, didDisconnectPeripheral peripheral: RNGPeripheral, error: Error?) {
        guard currPeripheral.identifier.uuidString == peripheral.identifier.uuidString else { return }
        currPeripheral = peripheral
        bleStateL.text = "BLE Disconnected"
        controllerSKU = nil
    }
    func didFailToConnectPeripheral(_ peripheral: RNGPeripheral, errMsg: String) {
        currPeripheral = peripheral
    }
    func centralManager(_ central: RNGBLE.RNGCentralManager, didDiscover peripheral: RNGBLE.RNGPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
    }
    func commandWillSend(_ command: RNGBLE.RNGCommandProtocol) {
        
    }
    func commandSendResult() {
        
    }
}
