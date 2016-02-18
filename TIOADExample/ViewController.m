/*
 ViewController.m
 TIOADExample
 
 Created by Ole Andreas Torvmark on 1/7/13.
 Copyright (c) 2013 Texas Instruments. All rights reserved.
 
 */

#import "ViewController.h"
#import "BLEDevice.h"
#import "BLEUtility.h"
#import "AppDelegate.h"
#include "protocol_mimas.h"

@interface ViewController ()
@property (strong, nonatomic) BLEDevice *bleDevice;
@end

@implementation ViewController {
    BOOL mAuto;
    uint8_t reConnectTimes;
    uint32_t timesOfUpgrade;
    L1_Send_Content content_l1;
    RECEIVE_STATE receive_state;
    uint8_t received_buffer[100];
    uint16_t received_content_length;
    int16_t length_to_receive;
    NSTimer *receive_time_out_timer;
    uint8_t global_reponse_buffer[GLOBAL_RESPONSE_BUFFER_SIZE];
    uint8_t global_L1_header_buffer[L1_HEADER_SIZE];
    uint16_t L1_sequence_id;
}

- (void)viewDidLoad
{
    NSLog(@"%s", __func__);
    L1_sequence_id = 0;
    receive_state = WAIT_START;
    mAuto = NO;
    reConnectTimes = 0;
    [super viewDidLoad];
    self.waitingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
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
    timesOfUpgrade = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
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
    //    [self.oadProfile selectImagePressed:self];
    //    [self testlxy];
    //    [self performSelector:@selector(testLxy1) withObject:nil afterDelay:3.0];
    //    [self performSelector:@selector(testLxy2) withObject:nil afterDelay:2.9];
    //    [self performSelector:@selector(testLxy3) withObject:nil afterDelay:2.9];
    [self testMimasEcho];
}

- (void)testMimasEcho {
    NSLog(@"%s", __func__);
    memset(&content_l1, 0, sizeof(L1_Send_Content));
    if (![self.cImageNotiy isNotifying]) {
        [self.p setNotifyValue:YES forCharacteristic:self.cImageNotiy];
    }
    [self performSelector:@selector(testMimasEcho1) withObject:nil afterDelay:2.0];
}
- (void)testMimasEcho1 {
    NSLog(@"%s", __func__);
    char data[128];
#if 0
    strcpy(data, "Mimas is the Saturn");
#elif 1
    strcpy(data, "Mimas is the Saturn first satellite!!");
#else
    strcpy(data, "Mimap");
#endif
    L2_Send_Content content;
//    generate_l2_package(&content, FACTORY_TEST_COMMAND_ID, KEY_REQUEST_ECHO, strlen(data), (uint8_t*)data);
    [self generate_l2_package:&content id:FACTORY_TEST_COMMAND_ID key:KEY_REQUEST_ECHO length:strlen(data) value:(uint8_t*)data];
//    generate_l1_package(&content, &content_l1);
    [self generate_l1_package:&content l1_content:&content_l1];
#if 0
    CBUUID *sUUID = [CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"];
    CBUUID *cUUID = [CBUUID UUIDWithString:@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"];
    [BLEUtility writeCharacteristic:self.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:content_l1.content length:content_l1.length]];
#endif
#if 0
    uint16_t sendLength = content_l1.length > BLE_NUS_MAX_DATA_LEN ? BLE_NUS_MAX_DATA_LEN : content_l1.length;
    //    [self.p writeValue:[NSData dataWithBytes:content_l1.content length:content_l1.length] forCharacteristic:_cImageBlock type:CBCharacteristicWriteWithoutResponse];
    [self.p writeValue:[NSData dataWithBytes:content_l1.content length:sendLength] forCharacteristic:_cImageBlock type:CBCharacteristicWriteWithResponse];
    content_l1.contentLeft -= sendLength;
#else
    [self continueSendMimas];
#endif
    NSLog(@"sequence_id = %d", content_l1.sequence_id);
}

- (void)continueSendMimas {
    NSLog(@"%s, length = %d, contentLeft = %d", __func__, content_l1.length, content_l1.contentLeft);
    uint16_t sendLength = 0;
    uint8_t tempBuf[64];
    if (content_l1.contentLeft > 0) {
        sendLength = content_l1.contentLeft > BLE_NUS_MAX_DATA_LEN ? BLE_NUS_MAX_DATA_LEN : content_l1.contentLeft;
        NSLog(@"sendLength = %d", sendLength);
        memcpy(tempBuf, content_l1.content+(content_l1.length-content_l1.contentLeft), sendLength);
        for (int i = 0; i < sendLength; i++) {
            printf("0x%02X ", tempBuf[i]);
        }
        NSLog(@"\r\n");
        [self.p writeValue:[NSData dataWithBytes:tempBuf length:sendLength] forCharacteristic:_cImageBlock type:CBCharacteristicWriteWithResponse];
//        [self.p writeValue:[NSData dataWithBytes:tempBuf length:sendLength] forCharacteristic:_cImageBlock type:CBCharacteristicWriteWithoutResponse];
        content_l1.contentLeft -= sendLength;
//        [self performSelector:@selector(continueSendMimas) withObject:nil afterDelay:3.0];
    }
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

-(void)initBLEDevice {
    _bleDevice = [[BLEDevice alloc]init];
    _bleDevice.p = self.dSVC.p;
    _bleDevice.manager = self.manager;
    _bleDevice.cImageNotiy = self.cImageNotiy;
    _bleDevice.cImageBlock = self.cImageBlock;
    _bleDevice.cErrorReset = self.cErrorReset;
    _bleDevice.cTransport = self.cTrans;
    
    self.oadProfile = [[BLETIOADProfile alloc] initWithDevice:_bleDevice];
    self.oadProfile.progressView = [[BLETIOADProgressViewController alloc] init];
    [self.oadProfile makeConfigurationForProfile];
    self.oadProfile.navCtrl = self.navigationController;
    [self.oadProfile configureProfile];
    self.oadProfile.view = self.view;
}

-(void)disConnectFromUS {
    NSLog(@"%s", __func__);
    timesOfUpgrade++;
    NSLog(@"timesOfUpgrade = %u", timesOfUpgrade);
    mAuto = YES;
    [self performSelector:@selector(reconnectPeripheral) withObject:nil afterDelay:38.002];
}

-(void)AutoTest {
    NSLog(@"%s", __func__);
    [self.oadProfile forAutoTest:self];
}
-(void)reconnectPeripheral {
    NSLog(@"%s", __func__);
    self.dSVC.p.delegate = self;
    self.manager.delegate = self;
    [self.manager connectPeripheral:self.dSVC.p options:NULL];
}

#pragma mark - deviceSelectorDelegate Callbacks
-(void)didSelectPeripheral:(NSString *)name {
    //-(void)didSelectDevice:(CBCharacteristic*)imageNotiy imageBlock:(CBCharacteristic *)imageBlock {
    NSLog(@"%s, name = %@", __func__, name);
    self.localName = name;
    [self.button1 setTitle:[NSString stringWithFormat:@"%@ selected",name] forState:UIControlStateNormal];
    self.dSVC.p.delegate = self;
    self.manager.delegate = self;
    //    if (!self.dSVC.p.isConnected) [self.manager connectPeripheral:self.dSVC.p options:nil];
    if (self.dSVC.p.state == CBPeripheralStateDisconnected) {
        NSDictionary *optionsdict = @{CBConnectPeripheralOptionNotifyOnConnectionKey : [NSNumber numberWithBool:YES]};
        [self.manager connectPeripheral:self.dSVC.p options:NULL];
        self.button1.enabled = NO;
        self.button2.enabled = NO;
        //        [self showWaiting:self.view];
    }
#if 0
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
#endif
    [self.button2 setEnabled:YES];
}

#pragma mark - CBCentralManagerDelegate Callbacks

-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"%s", __func__);
    if (central.state != CBCentralManagerStatePoweredOn) {
        //        UIAlertView *aV = [[UIAlertView alloc]initWithTitle:@"Bluetooth Smart not available on this device" message:@"Bluetooth Smart is not available on this device." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //
        //        [aV show];
        UIAlertController *uiac = [UIAlertController alertControllerWithTitle:@"未检测到蓝牙" message:@"请确认手机支持蓝牙4.0，并在设置里打开蓝牙" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok_action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [uiac addAction:ok_action];
        [self presentViewController:uiac animated:YES completion:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%s", __func__);
    self.p = peripheral;
#if 1
    NSArray *arrayUUID = [NSArray arrayWithObjects:[CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"], nil];
    [peripheral discoverServices:arrayUUID];
#else
    [self.button2 setEnabled:YES];
    [self.button2 setTitle:@"Select file" forState:UIControlStateNormal];
#endif
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s, error = %@", __func__, error);
    [self.oadProfile deviceDisconnected:peripheral];
    [self hideWaiting];
    if (reConnectTimes < 10) {
        [self performSelector:@selector(reconnectPeripheral) withObject:nil afterDelay:2.003];
        reConnectTimes++;
    }
}

#pragma mark - CBPeripheralDelegate Callbacks
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"%s", __func__);
    //    [self.manager cancelPeripheralConnection:peripheral];
    //    [self.tableView reloadData];
    for (CBService *s in peripheral.services) {
        //if ([s.UUID isEqual:[CBUUID UUIDWithString:@"F000F0C0-0451-4000-B000-000000000000"]]) {
        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]]) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
#if 0
        else if ([s.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
        else if ([s.UUID isEqual:[CBUUID UUIDWithString:@"CCC0"]]) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
        else if ([s.UUID isEqual:[CBUUID UUIDWithString:@"013d8e3b-1877-4d5c-bc59-aaa7e5082346"]]) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
#endif
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"%s", __func__);
    NSLog(@"Service : %@", service.UUID);
    NSLog(@"Characteristic : %@", service.characteristics);
    //if ([service.UUID isEqual:[CBUUID UUIDWithString:@"F000F0C0-0451-4000-B000-000000000000"]]) {
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            //if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F000F0C1-0451-4000-B000-000000000000"]]) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"]]) {
                _cImageNotiy = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:self.cImageNotiy];
            }
            //else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F000F0C2-0451-4000-B000-000000000000"]]) {
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"]]) {
                _cImageBlock = characteristic;
            }
#if 0
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F0C3"]]) {
                _cErrorReset = characteristic;
                
            }
            else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F0C4"]]) {
                _cTrans = characteristic;
                [self initBLEDevice];
                [self hideWaiting];
                reConnectTimes = 0;
            }
#endif
        }
        //        [self performSelector:@selector(letUsreloadData) withObject:nil afterDelay:1.0];
//        if (mAuto == YES) {
            //[self.oadProfile performSelector:@selector(forAutoTest) withObject:self afterDelay:3.038];
//            [self performSelector:@selector(AutoTest) withObject:nil afterDelay:2.039];
//        }
    }
#if 0
    else if ([service.UUID isEqual:[CBUUID UUIDWithString:@"CCC0"]]) {
        [self performSelector:@selector(letUsreloadData) withObject:nil afterDelay:1.0];
    }
#endif
}

- (void)setButton2Title {
    NSLog(@"%s", __func__);
    [self.button2 setEnabled:YES];
    [self.button2 setTitle:@"Select file" forState:UIControlStateNormal];
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //    NSLog(@"%s", __func__);
    NSLog(@"%s, characteristic = %@", __func__, characteristic);
#if 0
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A25"]]) {
        unsigned char data[characteristic.value.length];
        [characteristic.value getBytes:&data];
        for (int i = 0; i < characteristic.value.length; i++) {
            NSLog(@"0x%02X", data[i]);
        }
        NSString *serialNumber = [NSString stringWithUTF8String:data];
        NSLog(@"serialNumber = %@", serialNumber);
    }
    else
    {
        [self.oadProfile didUpdateValueForProfile:characteristic];
    }
#else
    unsigned char data[characteristic.value.length];
    //    [characteristic.value getBytes:&data];
    [characteristic.value getBytes:data length:characteristic.value.length];
    for (int i = 0; i < characteristic.value.length; i++) {
        NSLog(@"0x%02X", data[i]);
    }
    [self L1_receive_data:data dataLength:characteristic.value.length];
#endif
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"%s, characteristic uuid = %@, error = %@", __func__, characteristic.UUID.UUIDString, error);
    [self performSelector:@selector(continueSendMimas) withObject:nil afterDelay:0.001];
}


#pragma L1 receive data handle
static struct Response_Buff_Type_t g_ack_package_buffer =
{
    0, 0, 0
};

static L1Header_t *construct_response_package(uint16_t sequence_id, bool check_success)
{
    static L1Header_t response_header;
    L1_version_value_t version_ack;
    
    
    response_header.magic = L1_HEADER_MAGIC;
    
    version_ack.version_def.version = L2_HEADER_VERSION;
    version_ack.version_def.ack_flag = 1;
    version_ack.version_def.err_flag = (check_success ? 0 : 1);
    version_ack.version_def.reserve = 0;
    
    response_header.version =  version_ack.value;
    response_header.payload_len = 0;
    response_header.crc16 = 0;
    response_header.sequence_id = ((sequence_id & 0xFF) << 8) | ((sequence_id >> 8) & 0xFF); //big engian
    
    return &response_header;
}

/*************************************************************************
 * L1 receive a package and will send a response
 * para des:
 *               sequence_id : the received sequence id
 *               check_success: crc check result
 **************************************************************************/
//uint32_t L1_receive_response(uint16_t sequence_id, bool check_success)
- (uint32_t) L1_receive_response:(uint16_t)sequence_id crc:(bool)check_success
{
    NSLog(@"%s", __func__);
    //just use the new response request update the older one
    g_ack_package_buffer.check_success = (check_success == true) ? 1 : 0;
    g_ack_package_buffer.sequence_id = sequence_id;
    g_ack_package_buffer.isUsed = 1;
    
    
    //    schedule_async_send(&g_ack_package_buffer, TASK_ACK);
    uint8_t *currentSendPointer = NULL;
    currentSendPointer = (uint8_t *)construct_response_package(g_ack_package_buffer.sequence_id, (g_ack_package_buffer.check_success == 1) ? true : false );
    uint16_t sendLen = L1_HEADER_SIZE;
    
    //    error_code = ble_nus_string_send(&m_nus, currentSendPointer, sendLen);
    [self.p writeValue:[NSData dataWithBytes:currentSendPointer length:sendLen] forCharacteristic:_cImageBlock type:CBCharacteristicWriteWithoutResponse];
    return NRF_SUCCESS;
}

- (void) L1_receive_data:(uint8_t *)data dataLength:(uint16_t)length {
    if (receive_time_out_timer) {
        [receive_time_out_timer invalidate];
    }
    L1_version_value_t inner_version;
    NSLog(@"receive_state : %d",receive_state);
    switch (receive_state) {
        case WAIT_START: // we need package start
            if(data[0] != L1_HEADER_MAGIC) {
                //not a start package, so just igore
                break;
            }
            //get correct header
            received_content_length = 0;
            memcpy(&received_buffer[received_content_length],data,length);
            received_content_length = length;
            
            length_to_receive = (received_buffer[L1_PAYLOAD_LENGTH_LOW_BYTE_POS] | (received_buffer[L1_PAYLOAD_LENGTH_HIGH_BYTE_POS] << 8)) + L1_HEADER_SIZE;
            length_to_receive -= length;
            
            NSLog(@"length : %d",length);
            if(length_to_receive <= 0) { // Just one package
                
                inner_version.value = received_buffer[L1_HEADER_PROTOCOL_VERSION_POS];
                
                if(inner_version.version_def.ack_flag == RESPONSE_PACKAGE) { //response package
                    
                    NSLog(@"receive a ack package\n");
                    
                    receive_state = WAIT_START; //restart receive state machine
                    //                    response_package_handle((received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)),inner_version.version_def.err_flag);
                    
                    return;
                }
                
                //data package
                receive_state = MESSAGE_RESOLVE;
                received_content_length = 0;
                
                uint16_t crc16_value = (received_buffer[L1_HEADER_CRC16_HIGH_BYTE_POS] << 8 | received_buffer[L1_HEADER_CRC16_LOW_BYTE_POS]);
                if(L1_crc_check(crc16_value,received_buffer+L1_HEADER_SIZE,(received_buffer[L1_PAYLOAD_LENGTH_LOW_BYTE_POS] | (received_buffer[L1_PAYLOAD_LENGTH_HIGH_BYTE_POS] << 8))) == NRF_SUCCESS) { //check crc for received package
                    //LOG(LEVEL_INFO,"will send success response\n");
                    //send response
                    //                    L1_receive_response((received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)),true);
                    [self L1_receive_response:(received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)) crc:true];
                    /*throw data to uppder layer*/
//                    L2_frame_resolve(received_buffer+L1_HEADER_SIZE,(received_buffer[L1_PAYLOAD_LENGTH_LOW_BYTE_POS] | (received_buffer[L1_PAYLOAD_LENGTH_HIGH_BYTE_POS] << 8)),&receive_state);
                    [self L2_frame_resolve:received_buffer+L1_HEADER_SIZE length:(received_buffer[L1_PAYLOAD_LENGTH_LOW_BYTE_POS] | (received_buffer[L1_PAYLOAD_LENGTH_HIGH_BYTE_POS] << 8)) receiveState:&receive_state];
                } else { //receive bad package
                    //restart receive state machine
                    receive_state = WAIT_START;
                    
                    NSLog(@"will send crc fail response\n");
                    //send response
                    //                    L1_receive_response((received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)),false);
                    [self L1_receive_response:(received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)) crc:false];
                    //schedule error handler
                    //app_sched_event_put(NULL,0, schedule_crc_error_handle);
                    return;
                }
                
            } else { // more than one package
                
                receive_state = WAIT_MESSAGE;
                
                //                app_timer_start(receive_time_out_timer,RECEIVE_TIMEOUT,&receive_state);
                receive_time_out_timer = [NSTimer scheduledTimerWithTimeInterval:RECEIVE_TIMEOUT target:self selector:@selector(receive_time_out_handle) userInfo:nil repeats:NO];
            }
            break;
        case WAIT_MESSAGE:
            memcpy(&received_buffer[received_content_length],data,length);
            received_content_length += length;
            length_to_receive -= length;
            
            if(length_to_receive <= 0) {
                
                /* Stop timer */
                inner_version.value = received_buffer[L1_HEADER_PROTOCOL_VERSION_POS];
                
                if(inner_version.version_def.ack_flag == RESPONSE_PACKAGE) { //response package
                    receive_state = WAIT_START; //restart receive state machine
                    //                    response_package_handle((received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)),inner_version.version_def.err_flag);
                    return;
                }
                
                receive_state = MESSAGE_RESOLVE;
                received_content_length = 0;
                
                uint16_t crc16_value = (received_buffer[L1_HEADER_CRC16_HIGH_BYTE_POS] << 8 | received_buffer[L1_HEADER_CRC16_LOW_BYTE_POS]);
                if(L1_crc_check(crc16_value,received_buffer+L1_HEADER_SIZE,(received_buffer[L1_PAYLOAD_LENGTH_LOW_BYTE_POS] | (received_buffer[L1_PAYLOAD_LENGTH_HIGH_BYTE_POS] << 8))) == NRF_SUCCESS) { //check crc for received package
                    NSLog(@"will send success response\n");
                    //send response
                    //                    L1_receive_response((received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)),true);
                    [self L1_receive_response:(received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)) crc:true];
                    /*throw data to uppder layer*/
//                    L2_frame_resolve(received_buffer+L1_HEADER_SIZE,(received_buffer[L1_PAYLOAD_LENGTH_LOW_BYTE_POS] | (received_buffer[L1_PAYLOAD_LENGTH_HIGH_BYTE_POS] << 8)),&receive_state);
                    [self L2_frame_resolve:received_buffer+L1_HEADER_SIZE length:(received_buffer[L1_PAYLOAD_LENGTH_LOW_BYTE_POS] | (received_buffer[L1_PAYLOAD_LENGTH_HIGH_BYTE_POS] << 8)) receiveState:&receive_state];
                }
                else { //receive bad package
                    //restart receive state machine
                    receive_state = WAIT_START;
                    
                    NSLog(@"will send crc fail response\n");
                    //send response
                    //                    L1_receive_response((received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)),false);
                    [self L1_receive_response:(received_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (received_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)) crc:false];
                    //schedule error handler
                    //app_sched_event_put(NULL,0, schedule_crc_error_handle);
                    return;
                }
                
            } else {
                /* start receive time out timer */
                //app_timer_start(receive_time_out_timer,RECEIVE_TIMEOUT,&receive_state);
                receive_time_out_timer = [NSTimer scheduledTimerWithTimeInterval:RECEIVE_TIMEOUT target:self selector:@selector(receive_time_out_handle) userInfo:nil repeats:NO];
            }
            
            break;
            
        case MESSAGE_RESOLVE:
            //in this situation , can only receive a ack package
            //Note: ack package must small than 20 bytes
            
            inner_version.value = data[L1_HEADER_PROTOCOL_VERSION_POS];
            if(inner_version.version_def.ack_flag == RESPONSE_PACKAGE) { //response package
                NSLog(@"receive a ack package during MESSAGE_RESOLVE\n");
                //                response_package_handle((data[L1_HEADER_SEQ_ID_LOW_BYTE_POS] | (data[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] << 8)),inner_version.version_def.err_flag);
            }
            /* because there's no buffer to contain these data, so just ignore these package */
            
            break;
        default:
            break;
    }
}

- (void)receive_time_out_handle {
    NSLog(@"%s", __func__);
    receive_state = WAIT_START;
}

/***********************************************************************
 * para introduction
 * data                                   :      just the full of L2
 * content_length :      length of data
 * resolve_state  :  L1 receive data length
 ************************************************************************/
//uint32_t L2_frame_resolve(uint8_t *data, uint16_t length, RECEIVE_STATE *resolve_state)
- (uint32_t) L2_frame_resolve:(uint8_t*)data length:(uint16_t)length receiveState:(RECEIVE_STATE*)resolve_state
{
    uint8_t private_bond_machine = PRIVATE_NOT_BOND;
    //para check
    if((!data) || (length == 0))
    {
        return NRF_ERROR_INVALID_PARAM;
    }
    
    BLUETOOTH_COMMUNICATE_COMMAND command_id;
    uint8_t version_num;                                            /* L2 version number */
    uint8_t first_key;                                                      /* first key of L2 payload*/
    uint16_t first_value_length;            /* length of first value */
    
    command_id      = (BLUETOOTH_COMMUNICATE_COMMAND)data[0];
    version_num = data[1];
    version_num = version_num;                      /*current not use it*/
#if 1
        //  char str[64];
        if(private_bond_machine == PRIVATE_NOT_BOND)
        {
            NSLog(@"PRIVATE_NOT_BOND\n");
            //    sprintf(str,"PRIVATE_NOT_BOND\r\n");
        }
        else if(private_bond_machine == PRIVATE_BOND_SUCCESS)
        {
            NSLog(@"PRIVATE_BOND_SUCCESS\n");
            //    sprintf(str,"PRIVATE_BOND_SUCCESS\r\n");
        }
        // simple_uart_putstring((const uint8_t *)str);
        //    sprintf(str,"command_id:%d\r\n",command_id);
        //    simple_uart_putstring((const uint8_t *)str);
        uint16_t keyValueLength = (data[3] << 8) + data[4];
        NSLog(@"command_id:%d, key id:%d, keyValueLength:%d\n", command_id, data[2], keyValueLength);
#endif
    
    if (command_id == BOND_COMMAND_ID)
    {
        first_key = data[2];
        first_value_length = (((data[3] << 8) | data[4]) & 0x1FF);
        
//        resolve_private_bond_command(first_key, data + L2_FIRST_VALUE_POS, first_value_length);
        
    }
    else if (command_id == FACTORY_TEST_COMMAND_ID)
    {
#if 1
        uint16_t offset = L2_HEADER_SIZE + L2_PAYLOAD_HEADER_SIZE;
        //     uint16_t payload = 0;
        uint16_t v_length = 0;
        uint8_t *key = data + L2_HEADER_SIZE;
        while(length - offset >= 0)
        {
            v_length = ((*(key + 1)) << 8) + (*(key + 2));
//            do_test(key, v_length);
            [self do_test:key length:v_length];
            key += (v_length + L2_PAYLOAD_HEADER_SIZE);
            offset = offset + v_length + L2_PAYLOAD_HEADER_SIZE;
            NSLog(@"OH, shit it is work le!!!");
        }
#else
        
#endif
    }
    else if(command_id == FIRMWARE_UPDATE_CMD_ID)
    {
        first_key = data[2];
//        resolve_firmware_update_command((FIRMWARE_UPDATE_KEY)first_key);
    }
    else if(command_id == GET_STACK_DUMP)
    {
        first_key = data[2];
        first_value_length = (((data[3] << 8) | data[4]) & 0x1FF);
        // TODO:
        //get_stack_dump_command_resolve(first_key);
    }
    else if(command_id == BLUETOOTH_LOG_COMMAND_ID)
    {
        first_key = data[2];
        // TODO:
        //resolve_log_command_id((log_command_key_t)first_key);
    }
    
    //resolve other command
    
    else if (command_id == FIRMWARE_UPDATE_CMD_ID)
    {
        first_key = data[2];
//        resolve_firmware_update_command((FIRMWARE_UPDATE_KEY)first_key);
    }
    /****************************************************************************************************
     //should not resolve bond command
     case BOND_COMMAND_ID:
     first_key = data[2];
     first_value_length = (((data[3]<< 8) |data[4]) & 0x1FF);
     
     resolve_private_bond_command(first_key,data+ L2_FIRST_VALUE_POS,first_value_length);
     break;
     *********************************************************************************************************/
    else if (command_id == SET_CONFIG_COMMAND_ID ) {
        
        first_key = data[2];
        first_value_length = (((data[3] << 8) | data[4]) & 0x1FF);
        // here not handle the ret value
//        resolve_settings_config_command(first_key, data + L2_FIRST_VALUE_POS, first_value_length);
    }
    else if (command_id == NOTIFY_COMMAND_ID) {
        first_key = data[2];
        first_value_length = (((data[3] << 8) | data[4]) & 0x1FF);
        // here not handle the ret value
//        resolve_notify_command(first_key, data + L2_FIRST_VALUE_POS, first_value_length);
    }
#ifdef TESTFLASH
    else if (command_id == TEST_FLASH_READ_WRITE) {
        first_key = data[2];
        first_value_length = (((data[3] << 8) | data[4]) & 0x1FF);
        
        resolve_test_flash_command(first_key, data + L2_FIRST_VALUE_POS, first_value_length);
    }
#endif
    
    else if (command_id == HEALTH_DATA_COMMAND_ID) {
#ifdef DEBUG_LOG
        
        {
            LOG(LEVEL_INFO, "len:%d - %d:%d:%d \n", length, data[4], data[5], data[6]);
            //    char str[32];
            //    sprintf(str,"len:%d - %d:%d:%d \t",length,data[4],data[5],data[6]);
            //     simple_uart_putstring((const uint8_t *)str);
        }
#endif
        first_key = data[2];
        first_value_length = (((data[3] << 8) | data[4]) & 0x1FF);
//        resolve_HealthData_command(first_key, data + L2_FIRST_VALUE_POS, first_value_length);
    }
    else if (command_id == BLUETOOTH_LOG_COMMAND_ID) {
        first_key = data[2];
        // TODO:
        //resolve_log_command_id((log_command_key_t)first_key);
    }
    else if (command_id == TEST_COMMAND_ID) {
        if(length == 1)
        {
            switch (data[3])
            {
                    /* TODO:
                     case 1:
                     led_action_control(NOTIFICATION_TEST,SERIAL_FLASH,1);
                     break;
                     case 2:
                     led_action_control(NOTIFICATION_TEST,SERIAL_CLOSE,1);
                     break;
                     case 3:
                     led_action_control(NOTIFICATION_TEST,CELEBRATE,1);
                     break;
                     */
                default:
                    break;
            }
            
        }
    }
    /*********************************************************************************************
     //should not resolve factory test command
     case FACTORY_TEST_COMMAND_ID:
     {
     uint16_t offset = L2_HEADER_SIZE + L2_PAYLOAD_HEADER_SIZE;
     //     uint16_t payload = 0;
     uint16_t v_length = 0;
     uint8_t *key = data + L2_HEADER_SIZE;
     while(length - offset >= 0){
     v_length = ((*(key + 1)) << 8) + (*(key + 2));
     
     do_test(key, v_length);
     key += (v_length + L2_PAYLOAD_HEADER_SIZE);
     offset = offset + v_length + L2_PAYLOAD_HEADER_SIZE;
     }
     }
     break;
     ************************************************************************************************/
    
    /*resolve complete and restart receive*/
    *resolve_state = WAIT_START;
    return NRF_SUCCESS;
    
}

//void do_test(uint8_t *data, uint16_t length)
- (void) do_test:(uint8_t*)data length:(uint16_t)length {
    uint8_t *pData = data + L2_PAYLOAD_HEADER_SIZE;
    FACTORY_TEST_KEY theKey = *data;
    NSLog(@"key is %d.", theKey);
#if 0
    if((KEY_ENTER_TEST_MODE != *data) && !g_testMode)
        return;
#endif
//    uint32_t err_code;
    switch((FACTORY_TEST_KEY)(*data)) {
        case KEY_RETURN_ECHO:
            NSLog(@"key is KEY_RETURN_ECHO.");
//            err_code = app_sched_event_put(data + L2_PAYLOAD_HEADER_SIZE, length , (app_sched_event_handler_t)request_echo);
            NSLog(@"The echo is : %s", pData);
            break;
        case KEY_RETURN_SN:
//            err_code = app_sched_event_put(NULL, 0, (app_sched_event_handler_t)request_sensor_data);
//            APP_ERROR_CHECK(err_code);
            break;
        case KEY_RETURN_FLAG:
            break;
        case KEY_RETURN_SENSOR:
            break;
        default:
            break;
    }
}

//void generate_l2_package(
//                         L2_Send_Content *content,
//                         BLUETOOTH_COMMUNICATE_COMMAND id,
//                         uint8_t key,
//                         uint16_t length,
//                         uint8_t* value)

- (void)generate_l2_package:(L2_Send_Content*)content id:(BLUETOOTH_COMMUNICATE_COMMAND)id key:(uint8_t)key length:(uint16_t)length value:(uint8_t*)value
{
    NSLog(@"%s: length = %d", __func__, length);
#if 0
    global_reponse_buffer[0] = id;     /*command id*/
    global_reponse_buffer[1] = L2_HEADER_VERSION;           /*L2 header version */
    global_reponse_buffer[2] = key;             /*echo return*/
    global_reponse_buffer[3] = length >> 8;
    global_reponse_buffer[4] = (uint8_t)(length & 0x00FF);
#else
    global_reponse_buffer[8] = id;     /*command id*/
    global_reponse_buffer[9] = L2_HEADER_VERSION;           /*L2 header version */
    global_reponse_buffer[10] = key;             /*echo return*/
    global_reponse_buffer[11] = length >> 8;
    global_reponse_buffer[12] = (uint8_t)(length & 0x00FF);
#endif
    for(int i = 0; i < length; i++) {
        global_reponse_buffer[L1_HEADER_SIZE + 5 + i] = value[i];
    }
    
    content->callback    = 0;//send_callback;
    content->content     = global_reponse_buffer + L1_HEADER_SIZE;
    content->length      = L2_HEADER_SIZE + L2_PAYLOAD_HEADER_SIZE + length;   /*length of whole L2*/
}

//void generate_l1_package(L2_Send_Content *l2_content, L1_Send_Content *l1_content)
- (void)generate_l1_package:(L2_Send_Content *)l2_content l1_content:(L1_Send_Content*)l1_content {
    /*fill header*/
    global_L1_header_buffer[L1_HEADER_MAGIC_POS] = L1_HEADER_MAGIC;           /* Magic */
    global_L1_header_buffer[L1_HEADER_PROTOCOL_VERSION_POS] = L1_HEADER_VERSION;       /* protocol version */
    global_L1_header_buffer[L1_PAYLOAD_LENGTH_HIGH_BYTE_POS] = (l2_content->length >> 8 & 0xFF);    /* length high byte */
    global_L1_header_buffer[L1_PAYLOAD_LENGTH_LOW_BYTE_POS] = (l2_content->length & 0xFF);      /* length low byte */
    /*cal crc*/
    uint16_t crc16_ret = bd_crc16(0, l2_content->content, l2_content->length);
    NSLog(@"crc16_ret = 0x%x", crc16_ret);
    global_L1_header_buffer[L1_HEADER_CRC16_HIGH_BYTE_POS] = ( crc16_ret >> 8) & 0xff;
    global_L1_header_buffer[L1_HEADER_CRC16_LOW_BYTE_POS] = crc16_ret & 0xff;
    
    //sequence id
    global_L1_header_buffer[L1_HEADER_SEQ_ID_HIGH_BYTE_POS] = (L1_sequence_id >> 8) & 0xff;
    global_L1_header_buffer[L1_HEADER_SEQ_ID_LOW_BYTE_POS] = L1_sequence_id & 0xff;
    
    memcpy(global_reponse_buffer, global_L1_header_buffer, L1_HEADER_SIZE);
    
    l1_content->content = global_reponse_buffer;
    l1_content->length = l2_content->length + L1_HEADER_SIZE;
    NSLog(@"l2_content->length = %d", l2_content->length);
    l1_content->contentLeft = l1_content->length;
    l1_content->sequence_id = L1_sequence_id++;
}

/*************************************************************************
 * check the crc16 value for the received package
 **************************************************************************/
static uint32_t L1_crc_check(uint16_t crc_value, uint8_t *data, uint16_t length)
{
    uint16_t crc = bd_crc16(0x0000, data, length);
    if(crc == crc_value)
    {
        return NRF_SUCCESS;
    }
    
    return NRF_ERROR_INVALID_DATA;
    
}


#pragma The old history
//显示进度滚轮指示器
-(void)showWaiting:(UIView *)parent {
    int width = 32, height = 32;
    
    CGRect frame = CGRectMake(100, 200, 110, 70) ;//[parent frame]; //[[UIScreen mainScreen] applicationFrame];
    int x = frame.size.width;
    int y = frame.size.height;
    
    frame = CGRectMake((x - width) / 2, (y - height) / 2, width, height);
    
    //if (self.waitingIndicator == nil) {
    self.waitingIndicator = [[UIActivityIndicatorView alloc]initWithFrame:frame];
    //}
    [self.waitingIndicator startAnimating];
    
    self.waitingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    
    frame = CGRectMake((x - 70)/2, (y - height) / 2 + height, 80, 20);
    
    UILabel *waitingLable = [[UILabel alloc] initWithFrame:frame];
    waitingLable.text = @"Connecting...";
    waitingLable.textColor = [UIColor whiteColor];
    waitingLable.font = [UIFont systemFontOfSize:15];
    waitingLable.backgroundColor = [UIColor clearColor];
    
    frame =  CGRectMake(100, 200, 110, 70) ;//[parent frame];
    UIView *theView = [[UIView alloc] initWithFrame:frame];
    theView.backgroundColor = [UIColor blackColor];
    
    theView.alpha = 0.7;
    [theView addSubview:self.waitingIndicator];
    [theView addSubview:waitingLable];
    [theView setTag:9999];
    
    [parent addSubview:theView];
    [self.view.window bringSubviewToFront:theView];
}

//消除滚动轮指示器
-(void)hideWaiting
{
    self.button1.enabled = YES;
    self.button2.enabled = YES;
    [[self.view viewWithTag:9999] removeFromSuperview];
    self.waitingIndicator = nil;
}
@end