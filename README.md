# ``RNGBLE``

Xcode 14.0+
Programming Language Swift
Minimum Deployment Support iOS Deployment Target iOS 12.0

![Gif](https://github.com/ollie5619/RNGBLEDemo/blob/main/2.gif)

## Introducing RNGBLE.framework

- Drag and drop the RNGBLE.framework file into your project.
- Ensure that RNGBLE.framework is present in TARGETS -> General -> Frameworks, Libriaies and Embedded Content, if not click on the + button and select Add RNGBLE.framework from the file.

## Using RNGBLE

### Basic configuration

#### Initialization

- Create a ``UIViewController.swift`` file and import the header ``RNGBLE`` file
```
import RNGBLE
```

- Create an instance of ``RNGBLEManager`` in ``ViewController`` `bleManager``
```
class ViewController: UIViewController {
    private let bleManager = RNGBLEManager()
}
```
or
```
class ViewController: UIViewController {
    private let bleManager = RNGBLEManager(serviceCharacteristic: .init(notiService: “FFF0”, notiCharacteristic: “FFF1”, readWriteService: “FFD0 ”, readWriteCharacteristic: “FFD1”))
}
```
Where ``RNGBLEServiceCharacteristic`` supports custom notification/read/write service and characterization value attributes, ``FFF0````FFF1`` is the notification service characterization value attribute ``FFD0````FFD1`` read/write service characterization value attribute

- Setting the proxy
```
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        bleManager.delegate = self
    }
}
```

#### Scanning for Bluetooth

- Create an array of receiving Bluetooth ``scanPeripherals`` and implement the ``scanDevice()`` method in ``viewDidAppear``
```
class ViewController: UIViewController {
    private let bleManager = RNGBLEManager()
    /// List of scanned bluetooths without duplicates
    /// * Empty: every time scanning is resumed / Bluetooth is turned off.
    /// * New: when broadcasting
    private var scanPeripherals = [RNGPeripheral]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scanDevice()
    }
    private func scanDevice() {
        scanPeripherals.removeAll() // rescan and reset the device.
        bleManager.scanDevice()
    }
}
```

- Implementing the ``RNGBLEManagerDelegate`` method
```
extension ViewController: RNGBLEManagerDelegate {
    func centralManagerDidUpdateState(_ central: RNGCentralManager) {
        switch central.state {
        case .poweredOn: scanDevice()
        case .poweredOff: // Turning off Bluetooth doesn't go to the Bluetooth disconnect callback, it needs to be handled again
            scanPeripherals.removeAll() // turn off bluetooth reset
            // Handle your code here. Update scanPeripherals and update the page at the same time, e.g. call UITableView.reload() to refresh the page
        default: break
        }
    }    
    func centralManager(_ central: RNGCentralManager, didDiscover peripheral: RNGPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber ) {
        if !scanPeripherals.contains(where: { $0.identifier.uuidString == peripheral.identifier.uuidString }) {
            scanPeripherals.append(peripheral)
        }
        // Process your code here. Render the scanPeripherals to display on the UITableView
    }
```

#### stop Bluetooth scanning ``bleManager.centralManager.stopScan()``
```
class ViewController: UIViewController {
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bleManager.centralManager.stopScan()
    }
}
```

#### Monitor the state of the Bluetooth center ``RNGCentralManager.state`` ``.poweredOn`` indicates successful turn-on
```
extension ViewController: RNGBLEManagerDelegate {
    func centralManagerDidUpdateState(_ central: RNGCentralManager) {
        switch central.state {
        case .poweredOn: break
        case .poweredOff: // Bluetooth is off.
            print(“Bluetooth is not powered on”)
        case .unauthorized: // Bluetooth is not authorized.
            if #available(iOS 13.0, *) {
                switch central.authorization {
                case .denied: // Bluetooth authorization is not enabled
                    print(“You are not authorized to use bluetooth”)
                case .restricted: // Bluetooth is restricted, usually turned on/off in iPhone/iPad settings.
                    print(“Bluetooth is restricted”)
                case .restricted: // Bluetooth authorization is not available. print(“Bluetooth is restricted”)
                    print(“Unexpected bluetooth authorization”)
                }
            }
        case .unsupported: // Bluetooth is not supported on this device.
            print(“Bluetooth is not supported on this device”)
        default: break
        }
    }
}
```

#### Connecting to Bluetooth ``RNGPeripheral``

- Get the target Bluetooth from the ``scanPeripherals`` array and store it as ``currPeripheral``
```
    var currPeripheral: RNGPeripheral!
```

- Implementing a Bluetooth connection method
```
    bleManager.connect(currPeripheral)
```

- Confirm successful Bluetooth connection in ``RNGBLEManagerDelegate`` method ``didUpdateNotificationStateFor`` for successful notification turn-on
```
    func peripheral(_ peripheral: RNGPeripheral, didUpdateNotificationStateFor characteristic: RNGCharacteristic, error: Error?) {
        guard currPeripheral.identifier.uuidString == peripheral.identifier.uuidString else {
            bleManager.cleanup(peripheral)
            return
        }
        // Process your code here. Bluetooth successfully connected
    }
```

#### Connecting Bluetooth ``RNGPeripheral``

- Implementing the Disconnect Bluetooth method
```
    bleManager.cleanup(currPeripheral)
```

- Confirm successful Bluetooth disconnection in ``RNGBLEManagerDelegate`` Bluetooth disconnect method ``didDisconnectPeripheral``
```
    func centralManager(_ central: RNGCentralManager, didDisconnectPeripheral peripheral: RNGPeripheral, error: Error?) {
        guard currPeripheral.identifier.uuidString == peripheral.identifier.uuidString else { return }
        // Handle your code here. Bluetooth disconnected
    }
```

- Disconnecting Bluetooth is also handled in the ``RNGBLEManagerDelegate`` method ``centralManagerDidUpdateState`` for Bluetooth center state changes
```
    func centralManagerDidUpdateState(_ central: RNGCentralManager) {
        switch central.state {
        case .poweredOff.
            // Handle your code here. Bluetooth is disconnected
            break
        default: break
        }
    }
```

#### Basic Bluetooth communication, you need to parse it yourself, for direct calls, see ``### Controller identification and communication``.

#### Basic concepts of instructions

- Instruction function codes
```
public enum RNGCommandFuncCode {
    case `get`(_ length: UInt16)
    case `set`(_ newValue: UInt16)
    public var value: UInt8 {
        switch self { case `get`(_ length: UInt16)
        case .get: return 0x03
        case .set: return 0x06
        }
    }
}
```

- Command Protocol
```
public protocol RNGCommandProtocol {
    /// Function codes
    var funcCode: UInt8 { get }
    /// PDU command address
    var pdu: UInt16 { get }
    /// Data sent by the command Parameters sent by RNGPeripheral.write
    /// Address + function code + PDU + read/write length + ModbusCRC16 converted to Data to send
    var writeData: Data { get }
    /// Hexadecimal string
    var writeData16HStr: String { get }
    /// Maximum command response time (timeout)
    var maxReceivedTime: TimeInterval { get }
    /// Minimum command response time
    var minReceivedTime: TimeInterval { get }
    /// Whether a timeout is required
    /// - No timeout is needed to indicate that the command was sent “successfully”.
    var needSendTimeOut: Bool { get }
    /// Data length is exceeded, proxy returns in two passes.
    var hasTwiceResponse: Bool { get }
    var is2000Inverter: Bool { get }
    var isOTAInfo: Bool { get }
    var characteristicWriteType: RNGCharacteristicWriteType { get }
}
```

- Controller directives, the ``address`` parameter defaults to ``0xFF``, and directives with the ``funcCode`` parameter indicate support for reads and writes, otherwise read operations are supported
```
public enum RNGCommandController: RNGCommandProtocol {
    case SKU(_ address: UInt8 = 0xFF)
    case address(_ address: UInt8 = 0xFF, funcCode: RNGCommandFuncCode = .get(0x01))
}
```
For an example of the write address ``address`` command operation, see ``#### send command to device - set system voltage of controller`` for implementation details.
```
    RNGCommandController.address(0xFF, funcCode: .set(0x01))
```

#### sends a command to the device

- Call the ``send`` method of the ``RNGBLEManager`` instance, passing the ``RNGPeripheral`` instance and the ``RNGCommandProtocol`` array as parameters, e.g., to send the command ``RNGCommandController.SKU(address)`` to read the controller SKU:
```
    let address: UInt8 = 0xFF
    bleManager.send(currPeripheral, commandList: [RNGCommandController.SKU(address)]) { singleSuccess, commandIdx, command, receivedList in
        guard singleSuccess, let receivedList = receivedList, receivedList.count > 3 else { return }
        let sku = RNGBLETools.getASCII(with: Array(receivedList[3...]))
    }
```

- Read the controller and address:
```
    Let address: UInt8 = 0xFF
    bleManager.send(currPeripheral, commandList: [
        RNGCommandController.SKU(address),
        RNGCommandController.address(address),
    ) { singleSuccess, commandIdx, command, receivedList in
        guard singleSuccess, let receivedList = receivedList else { return } return
        // The first way to write commandIdx is to determine if commandIdx == 0.
        If commandIdx == 0, receivedList.count > 3 {
            let sku = RNGBLETools.getASCII(with: Array(receivedList[3...]))
        } else if commandIdx == 1, receivedList.count > 4 {
            let address = receivedList[4])
        }
        // second write command judgment: // second write command judgment: // second write command judgment: // second write command judgment: // second write command judgment: // second write command judgment
        switch command {
        case RNGCommandController.SKU:
            SKU: guard receivedList.count > 3 else { return }
            let sku = RNGBLETools.getASCII(with: Array(receivedList[3...]))
        case RNGCommandController.address:
            guard receivedList.count > 4 else { return }
            let address = receivedList[4]
        Default: disconnect
        }
    }
```

- Set the controller's system voltage ``RNGCommandController.voltSystem`` to ``ControllerSystemVolt._24``:
```
    let address: UInt8 = 0xFF, newSystemVolt = ControllerSystemVolt._24 // set the new system voltage to 24V
    bleManager.send(currPeripheral, commandList: [
        RNGCommandController.voltSystem(address, funcCode: .set(newSystemVolt.setData))
    ]) { singleSuccess, commandIdx, command, receivedList in
        // singleSuccess sets up success/failure handling
    }
```

#### command read/write return, correct/error return listener

- Implement the ``RNGBLEManagerDelegate`` feature value return method ``didUpdateValueFor``.
```
    func peripheral(_ peripheral: RNGPeripheral, didUpdateValueFor characteristic: RNGCharacteristic, error: Error?) {
        print(characteristic.value as Any, error as Any)
        // Process your code here. Grab the return content and error message directly and troubleshoot and analyze it as appropriate
    }
```

### Controller identification and communication, encapsulated, so you don't need to parse it yourself.

#### Identifying the controller

- Call the ``RNGPeripheral.isController`` method, passing in ``RNGBLEManager`` as a parameter
```
    currPeripheral.isController(bleManager) { isController, SKU in
        guard isController, let x = SKU else {
            print(“Not a controller”)
            return
        }
        // Handle your code here. 
    }
```

#### Basic controller communication

- Getting the device address ``RNGCommandController.getAddress``
```
    RNGCommandController.getAddress(bleManager, peripheral: currPeripheral) { address in
        // Handle your code here. Subsequent communication can take this address for read/write, or it's fine to use 0xFF as the default address, which is valid in HUB mode
    }
```

- Get device SKU ``RNGCommandController.getSKU``
```
    RNGCommandController.getSKU(manager, peripheral: currPeripheral, address: 0xFF) { success, SKU in
        guard success, let x = SKU else { return }
        // Process your code here. You need to call the currPeripheral.isController method first to validate it, otherwise the SKU may be returned as a phoenix or DCC, which you need to deal with yourself
    }
```

- Set the battery type ``RNGCommandController.setBatteryType``
```
    RNGCommandController.setBatteryType(bleManager, peripheral: currPeripheral, address: address, newValue: .Li) { success in
        // success sets up success/failure handling
    }
```

#### For more information about the controller, please refer to the SDK interface directly, for example, to get the battery SOC/battery voltage/battery current, etc. read as follows

- Get Battery SOC ``RNGCommandController.getBatterySOC``
```
    RNGCommandController.getBatterySOC(bleManager, peripheral: currPeripheral, address: 0xFF) { SOC in
        // do something
    }
```

- Get battery voltages ``RNGCommandController.getBatteryChargingVolts``
```
    RNGCommandController.getBatteryChargingVolts(bleManager, peripheral: currPeripheral, address: 0xFF) { batteryChargingVolts in
        // do something
    }
```

- Get battery currents ``RNGCommandController.getBatteryChargingAmps``
```
    RNGCommandController.getBatteryChargingAmps(bleManager, peripheral: currPeripheral, address: 0xFF) { batteryChargingAmps in
        // do something
    }
```

#### Bulk data reading and receiving using the model provided by the SDK

- Parsing data using the controller model ``BLEControllerModel`` and the ``RNGCommandController.getData`` method
```
    let currControlelrModel = BLEControllerModel() // create the data receiving container
    bleManager.send(currPeripheral, commandList: [
        RNGCommandController.batterySOC(),
        RNGCommandController.batteryChargingVolts(), [ RNGCommandController.batterySOC(), [
        RNGCommandController.batteryChargingAmps(),
        RNGCommandController.temperatures(), RNGCommandController.batteryChargingAmps(), RNGCommandController.
        RNGCommandController.dcVolts(), ]) { singleSuccess, command
    ]) { singleSuccess, commandIdx, command, receivedList in
        guard singleSuccess, let command = command as? RNGCommandController, let receivedList = receivedList else { return }
        let model = command.getData(currControlelrModel, deviceSku: sku, receivedList: receivedList)
        let batterySOC = model.batterySOC
        let batteryChargingVolts = model.batteryChargingVolts
        let batteryChargingAmps = model.batteryChargingAmps
        // Handle your code here. The model can be used directly for page rendering, see the list of BLEControllerModel properties for more information.
    }
```

- Use the controller history model ``BLEControllerHistoryModel`` to read the history of a particular day, e.g. read the day's record information ``targetDay: 0``, read the previous day's record information ``targetDay: 1``, read the previous two days' record information ``targetDay: 2``, and so on targetDay: 2``. And so on targetDay increments: (if you want to read data within as many consecutive days or within a specified interval of days, use a for loop to achieve this on your own for the time being)
```
    let address: UInt8 = 0xFF
    RNGCommandController.getHistory(bleManager, peripheral: currPeripheral, address: address, targetDay: 0) { model in
        /// Power consumption for the day
        let powerGenerate = model.powerGenerate
        /// The amount of power generated for the day
        let powerUse = model.powerUse
    }
```

### Identifying and communicating with inverters

#### Identifying the inverter

- Call the ``RNGPeripheral.isInverter`` method, passing ``RNGBLEManager`` as a parameter
```
    currPeripheral.isInverter(bleManager) { isInverter, address_deviceSku in
        guard isController, let (address, deviceSku) = address_deviceSku else {
            print(“Not an inverter”)
            return
        }
        print(“Inverter address and SKU:”, address, deviceSku)
        // Process your code here. Due to the special nature of the 1000w inverter, the address is also checked when the inverter is recognized, and here the method returns data in the form of address+SKU
    }
```

#### Inverter communication, please refer to SDK interface for information reading, sample data reading is as follows:

- Get device address ``RNGCommandInverter.getAddress``
```
    RNGCommandInverter.getAddress(bleManager, peripheral: currPeripheral) { address in
        // Handle your code here. Subsequent communication can take this address for read/write, or it's fine to use 0xFF as the default address, valid in HUB mode
    }
```

- Get the device SKU ``RNGCommandInverter.getSKU ``
```
    RNGCommandInverter.getSKU(manager, peripheral: currPeripheral, address: 0xFF) { success, SKU in
        guard success, let SKU else { return }
        // Handle your code here. 
    }
```

- Parsing data using the inverter model ``BLEInverterModel`` and the ``RNGCommandInverter.getData`` method

- Get the inverter output voltage ``RNGCommandInverter.outputVoltage``
```
    let address: UInt8 = 0xFF
    var model = BLEInverterModel()
    bleManager?.send(currPeripheral, commandList: [
        RNGCommandInverter.outputVoltage(address), [ ], commandsAllSend
    ], commandsAllSend: true) { singleSuccess, commandIdx, command, receivedList in
        guard singleSuccess, let command = command as? RNGCommandInverter, let receivedList else { return }
        model = command.getData(model, receivedList: receivedList)
        print(“Inverter output voltage”, model.outputVoltage)
    }
```

```
    let address: UInt8 = 0xFF
    var model = BLEInverterModel()
    bleManager?.send(currPeripheral, commandList: [
        RNGCommandInverter.address(address), [
        RNGCommandInverter.outputVoltage(address), [
        RNGCommandInverter.outputAmps(address), [ RNGCommandInverter.outputVoltage(address)
        RNGCommandInverter.outputFrequency(address), RNGCommandInverter.outputAmps(address), RNGCommandInverter.
        RNGCommandInverter.batteryVoltage(address), RNGCommandInverter.outputAmps(address), RNGCommandInverter.outputFrequency(address), RNGCommandInverter.
        RNGCommandInverter.temperature(address), RNGCommandInverter.
        RNGCommandInverter.errList_x0FA7(address), RNGCommandInverter.
        RNGCommandInverter.mode(address), RNGCommandInverter.
        RNGCommandInverter.errList_x112E_4(address), ], commandsAllSend
    ], commandsAllSend: true) { singleSuccess, commandIdx, command, receivedList in
        guard singleSuccess, let command = command as? RNGCommandInverter, let receivedList else { return }
        model = command.getData(model, receivedList: receivedList)
    }
    // Process your code here. 
```
