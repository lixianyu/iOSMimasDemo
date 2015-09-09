/*
 ViewController.m
 TIOADExample

 Created by Ole Andreas Torvmark on 1/7/13.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */

#import "ViewController.h"
#import "BLEDevice.h"
#import "BLEUtility.h"

@interface ViewController ()
@property (strong, nonatomic) BLEDevice *bleDevice;
@end

@implementation ViewController

- (void)viewDidLoad
{
    NSLog(@"%s", __func__);
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
#ifdef PHOBOS_SHENG_CHAN
    self.dSVC = [[ShengChanViewControllerTableViewController alloc]initWithStyle:UITableViewStyleGrouped];
#else
    self.dSVC = [[deviceSelectorViewController alloc]initWithStyle:UITableViewStyleGrouped];
#endif
    self.manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.dSVC.manager = self.manager;
    self.dSVC.delegate = self;
    [self.button2 setEnabled:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"%s", __func__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button functions

- (IBAction)button1Selected:(id)sender {
    NSLog(@"Opening device selector");
    NSLog(@"%s", __func__);
    [self presentViewController:self.dSVC animated:YES completion:nil];
}

- (IBAction)button2Selected:(id)sender {
    NSLog(@"%s", __func__);
    [self.oadProfile selectImagePressed:self];
//    [self testlxy];
    [self performSelector:@selector(testLxy1) withObject:nil afterDelay:3.0];
//    [self performSelector:@selector(testLxy2) withObject:nil afterDelay:2.9];
//    [self performSelector:@selector(testLxy3) withObject:nil afterDelay:2.9];
}

- (void)testlxy {
    NSLog(@"%s", __func__);
    CBUUID *sUUID = [CBUUID UUIDWithString:@"013d8e3b-1877-4d5c-bc59-aaa7e5082346"];
    CBUUID *cUUID = [CBUUID UUIDWithString:@"20490d79-99e1-4fc1-bba0-b43f88aafeb6"];
//    uint8 connData[16] = {0xe2, 0xc5, 0x6d, 0xb5, 0xdf, 0xfb, 0x48, 0xd2, 0xb0, 0x60, 0xd0, 0xf5, 0xa7, 0x10, 0x96, 0xe0};
    uint8 connData[16] = {0xFD, 0xA5, 0x06, 0x93, 0xA4, 0xE2, 0x4F, 0xB1, 0xAF, 0xCF, 0xC6, 0xEB, 0x07, 0x64, 0x78, 0x25};
    [BLEUtility writeCharacteristic:self.bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&connData length:sizeof(connData)]];
    
    [self performSelector:@selector(testLxy1) withObject:nil afterDelay:3.0];
}

- (void)testLxy1 {
    NSLog(@"%s", __func__);
    uint8 connData[11];
    connData[0] = 0x27; connData[1] = 0x11;//Major
    connData[2] = 0xE9; connData[3] = 0xE0;//Minor
    
    connData[4] = 0xC4;
    connData[5] = 0x02;
    connData[6] = 31;
#if 1
    // This is password:
    connData[7] = 0xFF;
    connData[8] = 0x02;
    connData[9] = 0x9D;
    connData[10]= 0x8E;
#endif
    CBUUID *sUUID = [CBUUID UUIDWithString:@"013d8e3b-1877-4d5c-bc59-aaa7e5082346"];
    CBUUID *cUUID = [CBUUID UUIDWithString:@"153117a7-311b-4cc7-904a-820adc5d8461"];
    [BLEUtility writeCharacteristic:self.bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&connData length:sizeof(connData)]];
}

- (void)testLxy2 {
    NSLog(@"Enter %s", __func__);
    uint8 connData[14];
    
    // password is : 0x61,0x88,0xC6,0xA1,0xA4,0x16
    connData[0] = 0x61; connData[1] = 0x88;
    connData[2] = 0xC6; connData[3] = 0xA1;
    connData[4] = 0xA4; connData[5] = 0x16;
    
    uint32_t passkey = 2008;//Range is 0 - 999,999
    connData[6] = (passkey >> 24)&0xFF;
    connData[7] = (passkey >> 16)&0xFF;
    connData[8] = (passkey >> 8) &0xFF;
    connData[9] = (passkey & 0xFF);
    
    /*
     #define GAPBOND_PAIRING_MODE_NO_PAIRING          0x00  //!< Pairing is not allowed
     #define GAPBOND_PAIRING_MODE_WAIT_FOR_REQ        0x01  //!< Wait for a pairing request or slave security request
     #define GAPBOND_PAIRING_MODE_INITIATE            0x02  //!< Don't wait, initiate a pairing request or slave security request
     */
    connData[10] = 1; //pairMode
    connData[11] = 1; //mitm -- TRUE or FALSE
    /*
     #define GAPBOND_IO_CAP_DISPLAY_ONLY              0x00  //!< Display Only Device
     #define GAPBOND_IO_CAP_DISPLAY_YES_NO            0x01  //!< Display and Yes and No Capable
     #define GAPBOND_IO_CAP_KEYBOARD_ONLY             0x02  //!< Keyboard Only
     #define GAPBOND_IO_CAP_NO_INPUT_NO_OUTPUT        0x03  //!< No Display or Input Device
     #define GAPBOND_IO_CAP_KEYBOARD_DISPLAY          0x04  //!< Both Keyboard and Display Capable
     */
    connData[12] = 0; //ioCap
    connData[13] = 1; //bonding -- TRUE or FALSE
    
    CBUUID *sUUID = [CBUUID UUIDWithString:@"013d8e3b-1877-4d5c-bc59-aaa7e5082346"];
    CBUUID *cUUID = [CBUUID UUIDWithString:@"ab7b42fc-9dfb-438a-9ec0-7c579843e9e2"];
    [BLEUtility writeCharacteristic:self.bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&connData length:sizeof(connData)]];
    NSLog(@"Leave %s", __func__);
}

- (void)testLxy3 {
    NSLog(@"%s", __func__);
    CBUUID *sUUID = [CBUUID UUIDWithString:@"180A"];
    CBUUID *cUUID = [CBUUID UUIDWithString:@"2A25"];
    [BLEUtility readCharacteristic:self.bleDevice.p sCBUUID:sUUID cCBUUID:cUUID];
    //    [BLEUtility readCharacteristic:self.bleDevice.p sUUID:@"180a" cUUID:@"2a25"];
    //    BLEUtility *bleu = [[BLEUtility alloc] init];
    //    [bleu readValue:0x180A characteristicUUID:0x2A25 p:self.bleDevice.p];
}

/* Apple Connnection Params Limits
 1. Interval Max * (Slave Latency + 1) ≤ 2 seconds；
 2. Interval Min ≥ 20 ms；
 3. Interval Min + 20 ms ≤ Interval Max；
 4. Slave Latency ≤ 4；
 5. connSupervisionTimeout ≤ 6 seconds
 6. Interval Max * (Slave Latency + 1) * 3 < connSupervisionTimeout
 */
- (void)updateConnParams {
    NSLog(@"%s", __func__);
    CBUUID *sUUID = [CBUUID UUIDWithString:[self.oadProfile.d.setupData valueForKey:@"CC Service UUID"]];
//    CBUUID *sUUID = [CBUUID UUIDWithString:[self.oadProfile.d.setupData[@"CC Service UUID"]]];
    CBUUID *cUUID = [CBUUID UUIDWithString:[self.oadProfile.d.setupData valueForKey:@"CC Conn. Params Req UUID"]];
    
    /*
     minConnInterval = BUILD_UINT16(buf[0],buf[1]);
     maxConnInterval = BUILD_UINT16(buf[2],buf[3]);
     slaveLatency = BUILD_UINT16(buf[4],buf[5]);
     timeoutMultiplier = BUILD_UINT16(buf[6],buf[7]);
     
     // Minimum connection interval (units of 1.25ms) if automatic parameter update request is enabled
     #define DEFAULT_DESIRED_MIN_CONN_INTERVAL     80 -> 0x50
     // Maximum connection interval (units of 1.25ms) if automatic parameter update request is enabled
     #define DEFAULT_DESIRED_MAX_CONN_INTERVAL     800 -> 0x320
     // Slave latency to use if automatic parameter update request is enabled
     #define DEFAULT_DESIRED_SLAVE_LATENCY         0
     // Supervision timeout value (units of 10ms) if automatic parameter update request is enabled
     #define DEFAULT_DESIRED_CONN_TIMEOUT          600 -> 0x258
     */
    uint8 connData[8];
    // To set MIN_CONN_INTERVAL
    connData[0] = 32; connData[1] = 0x00;
    // To set MAX_CONN_INTERVAL
    connData[2] = 50; connData[3] = 0x00;
    // To Set LATENCY
    connData[4] = 0x00; connData[5] = 0x00;
    // To set Timeout
    connData[6] = 0x58; connData[7] = 0x02;
    [BLEUtility writeCharacteristic:self.bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&connData length:8]];
}

#pragma mark - deviceSelectorDelegate Callbacks

-(void)didSelectDevice:(CBCharacteristic*)imageNotiy imageBlock:(CBCharacteristic *)imageBlock {
    NSLog(@"%s, imageNotiy = %@", __func__, imageNotiy);
    [self.button1 setTitle:[NSString stringWithFormat:@"%@ selected",self.dSVC.p.name] forState:UIControlStateNormal];
    self.dSVC.p.delegate = self;
    self.manager.delegate = self;
//    if (!self.dSVC.p.isConnected) [self.manager connectPeripheral:self.dSVC.p options:nil];
    if (self.dSVC.p.state == CBPeripheralStateDisconnected) {
        [self.manager connectPeripheral:self.dSVC.p options:nil];
    }
    else {
        _bleDevice = [[BLEDevice alloc]init];
        _bleDevice.p = self.dSVC.p;
        _bleDevice.manager = self.manager;
        _bleDevice.cImageNotiy = imageNotiy;
        _bleDevice.cImageBlock = imageBlock;
        
        self.oadProfile = [[BLETIOADProfile alloc] initWithDevice:_bleDevice];
        self.oadProfile.progressView = [[BLETIOADProgressViewController alloc]init];
        [self.oadProfile makeConfigurationForProfile];
        self.oadProfile.navCtrl = self.navigationController;
        [self.oadProfile configureProfile];
        self.oadProfile.view = self.view;
        
        [self updateConnParams];
    }
    [self.button2 setEnabled:YES];
}

#pragma mark - CBCentralManagerDelegate Callbacks

-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"%s", __func__);
    if (central.state != CBCentralManagerStatePoweredOn) {
        UIAlertView *aV = [[UIAlertView alloc]initWithTitle:@"Bluetooth Smart not available on this device" message:@"Bluetooth Smart is not available on this device." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [aV show];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%s", __func__);
#if 1
    [peripheral discoverServices:nil];
#else
    [self.button2 setEnabled:YES];
    [self.button2 setTitle:@"Select file" forState:UIControlStateNormal];
#endif
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s", __func__);
    [self.oadProfile deviceDisconnected:peripheral];
}

#pragma mark - CBPeripheralDelegate Callbacks

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error  {
    NSLog(@"%s", __func__);
    for (CBService *s in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:s];
    }
//    [self performSelector:@selector(updateConnParams) withObject:nil afterDelay:1.5];
    
}
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"%s", __func__);
    NSLog(@"Service : %@", service.UUID);
    NSLog(@"Characteristic : %@", service.characteristics);
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"0xF000FFC0-0451-4000-B000-000000000000"]]) {
        [self setButton2Title];
    }
}
- (void)setButton2Title {
    NSLog(@"%s", __func__);
    [self.button2 setEnabled:YES];
    [self.button2 setTitle:@"Select file" forState:UIControlStateNormal];
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"%s, characteristic = %@", __func__, characteristic);
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A25"]]) {
        unsigned char data[characteristic.value.length];
        [characteristic.value getBytes:&data];
        for (int i = 0; i < characteristic.value.length; i++) {
            NSLog(@"0x%02X", data[i]);
        }
        NSString *serialNumber = [NSString stringWithUTF8String:data];
        NSLog(@"serialNumber = %@", serialNumber);
    }
    else {
        [self.oadProfile didUpdateValueForProfile:characteristic];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"%s, characteristic uuid = %@, error = %@", __func__, characteristic.UUID.UUIDString, error);
    
}
@end