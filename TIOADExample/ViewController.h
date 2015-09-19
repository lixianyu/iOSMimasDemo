/*
  ViewController.h
  TIOADExample

  Created by Ole Andreas Torvmark on 1/7/13.
  Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "deviceSelectorViewController.h"
#ifdef PHOBOS_SHENG_CHAN
#import "ShengChanViewControllerTableViewController.h"
#endif
#import "BLETIOADProfile.h"
#import "BLETIOADProgressViewController.h"

#ifdef PHOBOS_SHENG_CHAN
@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, ShengChanDelegate>
#else
@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, deviceSelectorDelegate>
#endif
@property (strong, nonatomic) NSString *localName;
@property (strong, nonatomic) CBCentralManager *manager;
@property (strong,nonatomic) CBPeripheral *p;
@property (strong,nonatomic) CBCharacteristic *cImageNotiy;
@property (strong,nonatomic) CBCharacteristic *cImageBlock;
@property (strong,nonatomic) CBCharacteristic *cErrorReset;
#ifdef PHOBOS_SHENG_CHAN
@property (strong, nonatomic) ShengChanViewControllerTableViewController *dSVC;
#else
@property (strong, nonatomic) deviceSelectorViewController *dSVC;
#endif
@property (strong,nonatomic) BLETIOADProfile *oadProfile;


//In case of iOS 7.0
@property (strong,nonatomic) BLETIOADProgressViewController *progressView;

- (IBAction)button1Selected:(id)sender;
- (IBAction)button2Selected:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;

//@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *waitingIndicator;
@property (strong, nonatomic) UIActivityIndicatorView *waitingIndicator;
@end
