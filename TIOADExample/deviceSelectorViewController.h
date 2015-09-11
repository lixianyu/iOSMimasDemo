/*
 deviceSelectorViewController.h
 TIOADExample
 Created by Ole Andreas Torvmark on 1/7/13.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol deviceSelectorDelegate <NSObject>

-(void) didSelectDevice:(CBCharacteristic*)imageNotiy imageBlock:(CBCharacteristic*)imageBlock;
-(void) didSelectPeripheral:(NSString*)name;
@end

@interface deviceSelectorViewController : UITableViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong,nonatomic) NSMutableArray *devices;
@property (strong,nonatomic) NSMutableArray *devicesNames;
@property (strong,nonatomic) CBCentralManager *manager;
@property (strong,nonatomic) CBPeripheral *p;
@property (strong,nonatomic) CBCharacteristic *cImageNotiy;
@property (strong,nonatomic) CBCharacteristic *cImageBlock;
@property id<deviceSelectorDelegate> delegate;

@end
