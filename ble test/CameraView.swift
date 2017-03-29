//
//  CameraView.swift
//  ble test
//
//  Created by oshitahayato on 2016/11/22.
//  Copyright © 2016年 oshitahayato. All rights reserved.
//

import UIKit
import AVFoundation
//Exif情報取得、+UIImagePickerControllerDelegate,UINavigationControllerDelegate継承
import Photos
import MobileCoreServices

import AssetsLibrary

import ImageIO

var meta:NSDictionary? = nil
var selImage:UIImage? = nil


class CameraView: UIViewController,AVCapturePhotoCaptureDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
	
	//camera映像表示
	@IBOutlet weak var cameraView: UIView!
	
	var captureSesssion: AVCaptureSession!
	var stillImageOutput: AVCapturePhotoOutput?
	var previewLayer: AVCaptureVideoPreviewLayer?
	
	//心拍表示ラベル
	@IBOutlet weak var pulselabel: UILabel!
	
	
	//exif情報
	//アルバム
	let kMyAlbum = "MyAlbum"
	let kAssetIdentifier = "assetIdentifier"
	
	//var photoAssets = [PHAsset]()
	//blepulse読み出し
	var appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
	//var isMapSelect:Bool = appDelegate.isMapSelect!
	
	
	@IBAction func TakePhoto(_ sender: AnyObject) {
		// フラッシュとかカメラの細かな設定
		let settingsForMonitoring = AVCapturePhotoSettings()
		settingsForMonitoring.flashMode = .auto
		settingsForMonitoring.isAutoStillImageStabilizationEnabled = true
		settingsForMonitoring.isHighResolutionPhotoEnabled = false
		// シャッターを切る
		stillImageOutput?.capturePhoto(with: settingsForMonitoring, delegate: self as AVCapturePhotoCaptureDelegate)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		
		
		
		
		captureSesssion = AVCaptureSession()
		stillImageOutput = AVCapturePhotoOutput()
		
		captureSesssion.sessionPreset = AVCaptureSessionPresetHigh // 解像度の設定
		
		let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
		
		do {
			let input = try AVCaptureDeviceInput(device: device)
			
			// 入力
			if (captureSesssion.canAddInput(input)) {
				captureSesssion.addInput(input)
				
				// 出力
				if (captureSesssion.canAddOutput(stillImageOutput)) {
					captureSesssion.addOutput(stillImageOutput)
					captureSesssion.startRunning() // カメラ起動
					
					previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
					previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect // アスペクトフィット
					previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait // カメラの向き
					
					cameraView.layer.addSublayer(previewLayer!)
					
					// ビューのサイズの調整
					previewLayer?.position = CGPoint(x: self.cameraView.frame.width / 2, y: self.cameraView.frame.height / 2)
					previewLayer?.bounds = cameraView.frame
				}
			}
		}
		catch {
			print(error)
		}
	}
	
	
	//イメージ一時保存
	
	func addNewAssetImage(with image: CGImage,withpath tmpUrl: URL!) {
		/*
		PHPhotoLibrary.shared().performChanges({() -> Void in
			// PHAssetChangeRequest を作ります
			var createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
			
			// Request editing the album.
			let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle:"original")
			
			let placeHolder = createAlbumRequest.placeholderForCreatedAssetCollection
			
			// placeholder から取得できる identifier を
			// 保存しておくと後から画像を一意に取得することができます
			let defaults = UserDefaults.standard
			defaults.set(placeHolder.localIdentifier, forKey: self.kAssetIdentifier)
			defaults.synchronize()
			}, completionHandler: {(ok, err) in
				print(ok, err)
		})
	*/
		
		
		let dest = CGImageDestinationCreateWithURL(tmpUrl as CFURL, kUTTypeJPEG, 1, nil)
		let metaData = NSMutableDictionary()
		
		
		CGImageDestinationAddImage(dest!,image, (metaData as CFDictionary))
		print(tmpUrl)
		CGImageDestinationFinalize(dest!)
		//保存処理
		let library = PHPhotoLibrary.shared
		library().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tmpUrl as URL) },completionHandler: { (ok, err) in print(ok, err)
			//let _ = try? FileManager.default.removeItem(at: tmpfile)
		})
		

		
		
		
	}
	
	//
	func getAssets(_ fetch: PHFetchResult<AnyObject>) -> PHFetchResult<PHAsset> {
		// フェッチ結果を配列に格納します
		// アルバム写真の情報
		
		let assets = PHAsset.fetchAssets(with: .image, options: nil)
		let indexSet = IndexSet(integersIn: 0...assets.count - 1)
		let items = assets.objects(at: indexSet)
		print("写真は \(items.count) 枚")
		
		return assets
	}
	
	// デリゲート。カメラで撮影が完了した後呼ばれる。JPEG形式でフォトライブラリに保存。
	func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
		
		if let photoSampleBuffer = photoSampleBuffer {
			
			// JPEG形式で画像データを取得
			let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
			//let image = CGImageSourceCreateWithData((data as! CFDataRef), nil)
			
			let wi: UIImage = UIImage(data: photoData!)!
			
			
			
			let cg : CGImage = wi.cgImage!;
			
			// 画像の向きを指定
			let image = UIImage(cgImage: cg, scale: wi.scale, orientation: .up)
			
			/*
			//画像の読み出し
			addNewAssetImage(with: image)
			// Identifier を指定して PHAsset をフェッチします
			let identifier = UserDefaults.standard.object(forKey: kAssetIdentifier)!
			let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier as! String], options: nil)
			// assets を取り出します
			let assetArray = self.getAssets(assets as! PHFetchResult<AnyObject>)
			
			//identifierから画像urlを探す
			let manager: PHImgaeManager = PHImageManager()
			*/
			
			//EXIFデータの作成
			let exif = NSMutableDictionary()
			//Exifにコメント情報をセットする
			let value = appDelegate.pulse!
			let photovalue = value
			let comment : String = String(photovalue)
			
			//print(comment)
			//print()
			
			
			exif.setObject("photoshot",forKey: kCGImagePropertyPNGTitle as CFString as! NSCopying)
			exif.setObject(comment, forKey: kCGImagePropertyExifUserComment as NSString)
			
			//exif[(kCGImagePropertyExifUserComment as CFString)] = "hoge"
			//print(value)
			print(comment)
			print(type(of: comment))
			//print(type(of: exif))
			//
			//静止画metadata作成
			let metadata = NSMutableDictionary()
			metadata.setObject(exif,forKey:kCGImagePropertyExifDictionary as! NSCopying);
			/*
			//サンプル
			//ワイキキビーチの位置情報を作成する
			let gps = NSMutableDictionary()
			gps.setObject("N",forKey:kCGImagePropertyGPSLatitudeRef as! NSCopying)
			gps.setObject(21.275468,forKey:kCGImagePropertyGPSLatitude as! NSCopying)
			gps.setObject("W",forKey:kCGImagePropertyGPSLongitudeRef as! NSCopying)
			gps.setObject(157.825294,forKey:kCGImagePropertyGPSLongitude as! NSCopying)
			gps.setObject(0,forKey:kCGImagePropertyGPSAltitudeRef as! NSCopying)
			gps.setObject(0,forKey:kCGImagePropertyGPSAltitude as! NSCopying)
			//ExifにGPS情報をセットする
			metadata.setObject(gps,forKey:kCGImagePropertyGPSDictionary as! NSCopying);
			*/
			
			
			//フォト保存
			//メタデータ保存のためにphotoframework使用
			let tmpName = ProcessInfo.processInfo.globallyUniqueString
			let tmpUrl = NSURL.fileURL(withPath: NSTemporaryDirectory() + tmpName + ".jpg")
			//print(type(of: tmpUrl))
			//print(tmpUrl)
			//一時保存
			//addNewAssetImage(with: cg,withpath: tmpUrl as URL!)
			
			if let dest = CGImageDestinationCreateWithURL(tmpUrl as CFURL, kUTTypeJPEG, 1, nil) {
				//print("photo save ok")

				CGImageDestinationAddImage(dest,cg, (metadata as CFDictionary))
				CGImageDestinationFinalize(dest)
				//CFRelease(dest)
				//print(dest)
				//print(exif)
				print(metadata)
				//保存処理
				let library = PHPhotoLibrary.shared
				library().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tmpUrl) },completionHandler: { (ok, err) in print(ok, err)
				//let _ = try? FileManager.default.removeItem(at:tmpUrl)
				})
				
				
				pulselabel.text = String(photovalue)
				
				
			}
			//exif確認処理
			//let photourl = tmpUrl.absoluteString
			//print(photourl)
			
			
			
			// フォトライブラリに保存
			//print("photo save ok")
			//UIImageWriteToSavedPhotosAlbum(image!, nil, nil, dest)
			//
			
		}
		
	}
	
	


}
