/*
 BLETIOADProfile.h
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "BLETIOADProgressDialog.h"
#import "BLETIOADProgressViewController.h"
#import "oad.h"
#import "BLEDevice.h"

#define UPLOAD_INTERVERL  0.09

#define HI_UINT16(a) (((a) >> 8) & 0xff)
#define LO_UINT16(a) ((a) & 0xff)

@interface BLETIOADProfile : NSObject <UIActionSheetDelegate,UIAlertViewDelegate,CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong,nonatomic) NSData *imageFile;
@property uint8 *imageFileData;
@property (strong,nonatomic) BLETIOADProgressDialog *progressDialog;
@property (strong,nonatomic) BLEDevice *d;
@property (strong,nonatomic) UIView *view;

@property int nBlocks;
@property int nBytes;
@property int iBlocks;
@property int iBytes;
@property BOOL canceled;
@property BOOL inProgramming;
@property BOOL start;
@property (nonatomic,retain) NSTimer *imageDetectTimer;
@property uint16_t imgVersion;
@property UINavigationController *navCtrl;

//In case of iOS 7.0
@property (strong,nonatomic) BLETIOADProgressViewController *progressView;

@property (strong, nonatomic) id idViewController;

-(id) initWithDevice:(BLEDevice *) dev;
-(void) makeConfigurationForProfile;
-(void) configureProfile;
-(void) deconfigureProfile;
-(void) didUpdateValueForProfile:(CBCharacteristic *)characteristic;
-(void)deviceDisconnected:(CBPeripheral *)peripheral;

-(void) uploadImage:(NSString *)filename;

-(IBAction)selectImagePressed:(id)sender;

-(void) programmingTimerTick:(NSTimer *)timer;
-(void) imageDetectTimerTick:(NSTimer *)timer;

-(NSMutableArray *) findFWFiles;

-(BOOL) validateImage:(NSString *)filename;
-(BOOL) isCorrectImage;
-(void) completionDialog;
-(void)forAutoTest: (id)sender ;
@end
