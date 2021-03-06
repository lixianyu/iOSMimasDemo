/*
 BLEDevice.h
 TIOADExample

 Created by Ole Andreas Torvmark on 9/17/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


/// Class which describes a Bluetooth Smart Device
@interface BLEDevice : NSObject

/// Pointer to CoreBluetooth peripheral
@property (strong,nonatomic) CBPeripheral *p;
/// Pointer to CoreBluetooth manager that found this peripheral
@property (strong,nonatomic) CBCentralManager *manager;
@property (strong,nonatomic) CBCharacteristic *cImageNotiy;
@property (strong,nonatomic) CBCharacteristic *cImageBlock;
@property (strong,nonatomic) CBCharacteristic *cErrorReset;
@property (strong,nonatomic) CBCharacteristic *cTransport;
/// Pointer to dictionary with device setup data
@property NSMutableDictionary *setupData;
@end

