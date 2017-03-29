//
//  ViewController.swift
//  ble test
//
//  Created by oshitahayato on 2016/09/27.
//  Copyright © 2016年 oshitahayato. All rights reserved.
//
import UIKit
import CoreBluetooth

class ViewController:UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate,CBPeripheralDelegate
{
	
	//配列pulseサンプリング
	var samplepulse = Array(repeating: 0, count: 100)
	var samplecount = 0
	var ok = 0
	
	
	//ble 配列
	private var peripheralArray = [CBPeripheral]()
	
	
	@IBOutlet weak var myTableView: UITableView!
	
	//ble
	var centralManager:CBCentralManager!
	var BLEPeripheral:CBPeripheral!
	
	//ble検出時に保存する配列
	var myUuids: NSMutableArray = NSMutableArray()
	var myNames: Optional<NSMutableArray> = NSMutableArray()
	var myPeripheral: NSMutableArray = NSMutableArray()
	//セントラルマネージャ状態
	@IBOutlet weak var cmstate: UILabel!
	//接続状態　表示
	@IBOutlet weak var peri_state: UILabel!
	
	//pulsedata引き渡し
	var appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
	
	
	//===========================================================================
	// MARK: -- 初期化 & ビューライフサイクル --
	//===========================================================================
	
	
	
	
	override func viewDidLoad()
	{
		
		super.viewDidLoad()
		
		
		centralManager = CBCentralManager(delegate: self, queue: nil)
		
	}
	
	
	
	//===========================================================================
	// MARK: -- BLE --
	//===========================================================================
	//セントラルマネージャーの状態変化を取得
	
	@IBAction func scan(_ sender: AnyObject) {
		
		// 配列をリセット.
		myNames = NSMutableArray()
		myUuids = NSMutableArray()
		myPeripheral = NSMutableArray()
		
		self.centralManager = CBCentralManager(delegate: self, queue: nil, options:  nil)
		
		
		
		
	}
	
	
	
	
	func centralManagerDidUpdateState(_ central: CBCentralManager)
	{
		switch (central.state) {
			
		case .poweredOff:
			cmstate.text = "Bluetoothの電源がOff"
			print("Bluetoothの電源がOff")
		case .poweredOn:
			cmstate.text = "Bluetoothの電源はOn"
			print("Bluetoothの電源はOn")
			centralManager.scanForPeripherals(withServices: nil, options:nil)
		case .resetting:
			cmstate.text = "レスティング状態"
			print("レスティング状態")
		case .unauthorized:
			cmstate.text = "非認証状態"
			print("非認証状態")
		case .unknown:
			cmstate.text =  "不明"
			print("不明")
		case .unsupported:
			cmstate.text = "非対応"
			print("非対応")
		}
	}
	
	
	//スキャン結果を受け取る
	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
	{
		//print("name: \(peripheral.name)")
		//print("UUID: \(peripheral.identifier.uuidString)")
		//print("advertisementData: \(advertisementData)")
		//print("RSSI: \(RSSI)")
		
		//print("発見したデバイス: \(peripheral)")
		
		
		// 配列に追加
		if(peripheral.name == "BLENANO"){
		//print("ok")
		self.peripheralArray.append(peripheral as CBPeripheral)
		//print("\(self.peripheralArray)")
		myNames?.addObjects(from: [peripheral.name])
		
		//myPeripheral.add(peripheral)
		myUuids.addObjects(from:[peripheral.identifier.uuidString])
		//table-reload
		myTableView.reloadData()
		}
	}
	
	
	//配列からcount,table作成
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		
		//print("okkkkkkkkkkkk")
		return myUuids.count
		
	}
	
	//表示
	func tableView(_ tableView: UITableView, cellForRowAt indexpath : IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "MyCell")
		
		//cell.textLabel?.text = "\(myUuids[indexpath.row])"
		cell.textLabel!.text = "\(myNames?[indexpath.row])"
		//print("ok")
		//print("\(myUuids[indexpath.row])")
		return cell
	}
	
	
	// リストから該当Peripheralを選択し接続を開始
	func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		// 省電力のためスキャンを停止
		//print("stop")
		self.centralManager.stopScan()
		
		//接続状態変更
		peri_state.text = "接続中"
		//指定したPeripheralへ接続開始
		//print("\(peripheralArray[(indexPath as NSIndexPath).row])")
		self.centralManager.connect(peripheralArray[(indexPath as NSIndexPath).row], options: nil)
		
	}
	
	//ペリフェラルの接続に成功した時呼ばれる
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
		peri_state.text = "接続成功"
		print("接続成功")
		
		//サービス探索結果を受け取るためのデリゲートセット
		peripheral.delegate = self
		//サービス探索開始
		peripheral.discoverServices(nil)
		
		
		
		
		
	}
	//ペリフェラルの接続に失敗した時呼ばれる
	func centralManager(_ central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
		peri_state.text = "接続失敗"
		print("接続失敗")
	}
	
	//サービス発見時に呼ばれる
	func peripheral(_ peripheral: CBPeripheral!, didDiscoverServices error: NSError!){
		
		let services: NSArray = peripheral.services! as NSArray
		//print("\(services.count) 個のサービスを発見! \(services)")
		
		for obj in services{
			
			if let service = obj as? CBService{
				//キャラクタリスティック探索
				peripheral.discoverCharacteristics(nil, for: service)
				
			}
		}
		
	}
	
	//キャラクタリスティック探索結果取得,キャラクタリスティック発見時
	func peripheral(_ peripheral: CBPeripheral!, didDiscoverCharacteristicsFor service: CBService!, error: Error!){
		
		let characteristics: NSArray = service.characteristics! as NSArray
		print("\(characteristics.count)個のキャラクタリスティックを発見! \(characteristics)")
		
		for obj in characteristics{
			
			//print("oh")
			if let characteristic = obj as? CBCharacteristic {
				
				
				//Read専用のキャラクタリスティックに限定して読み出し
				if characteristic.properties == CBCharacteristicProperties.read{
					
					peripheral.readValue( for: characteristic)
					
					print("okkkkkk")
				}
				
				//データ更新通知の受取を開始
				peripheral.setNotifyValue(true, for: characteristic)
				
			}
		}
	}
	
	//探索結果表示
	func peripheral(_ peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!){
		//print("読み出し成功! setvice uuid: \(characteristic.service.uuid), characteristic uuid: \(characteristic.uuid), value: \(characteristic.value)")
		
		
		//optionalからの取り出し
		var value : CUnsignedChar = 0
		//var value : Data = characteristic.value!
		//print(value)
		//let reportdata = UnsafePointer<UInt8>(value.bytes)
		
		//valueのoptical型から取り出す
		characteristic.value?.copyBytes(to: &value, count: 1)
		
		
		
		print("読み出し成功 value: \(value) ")
		//心拍　平均化
		samplepulse[samplecount] = Int(value)
		samplecount = samplecount + 1
		if(samplecount == 100){
			ok = 1
			samplecount = 0
		}
		if(ok == 1){
		    let plus = { (a: Int, b: Int) -> Int in a + b }
			
		    let num = samplepulse.reduce(0, plus)
		    print(num/100)
		    let samrate = num/100
		    //appDelegate.pulse = samrate
		}

		appDelegate.pulse = value

		
		//型を調べるため
		//print(type(of: characteristic.value!))
		
	}
	
	//探索結果更新
	func peripheral(_ peripheral: CBPeripheral!, didUpdateNotficationStateForCharacteristic characteristic: CBCharacteristic!,error: NSError!){
		
		
		if error != nil{
			print("Notify状態更新失敗..error: \(error)")
		}
		else{
			print("okkk")
			print("Notify状態更新成功 isNotifying: \(characteristic.isNotifying)")
			
			
			
			//print("データ更新! characteristic uuid: \(characteristic.uuid), value: \(characteristic.value) ")
		}
	}
	
	/*	func peripheral(_ peripheral: CBPeripheral!,didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!){
	print("データ更新! characteristic uuid: \(characteristic.uuid), value: \(characteristic.value) ")
	
	}
	*/
	
}
