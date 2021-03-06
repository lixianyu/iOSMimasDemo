/*
 BLETIOADProfile.m
 TIOADExample

 Created by Ole Andreas Torvmark on 11/22/12.
 Copyright (c) 2013 Texas Instruments. All rights reserved.

 */
#import <mach/mach_time.h>
#import "BLETIOADProfile.h"
#import "BLETIOADProgressDialog.h"
#import "BLEUtility.h"
#if 0
typedef enum {
    m328 = 0,
    m328p,
    m644,
    m644p,
    m1284,
    m1284p,
}t_part_id;
#endif
typedef enum
{
    m328p_16M_5V = 0,//Upload speed is 115200
    m328p_8M_3_3V,   //Upload speed is 57600
    
    m644p_16M_5V,    //Upload speed is 115200
    m644p_8M_3_3V,   //Upload speed is 57600
    
    m1284p_16M_5V,   //Upload speed is 115200
    m1284p_8M_3_3V,  //Upload speed is 57600
    
    m32u4_16M,       //Upload speed is 57600
    m128rfa116m,     //Upload speed is 57600
    
    m328_16M_5V,     //Upload speed is 115200
    m328_8M_3_3V,    //Upload speed is 57600
    m644_16M_5V,     //Upload speed is 115200
    m644_8M_3_3V,    //Upload speed is 57600
    m1284_16M_5V,    //Upload speed is 115200
    m1284_8M_3_3V,   //Upload speed is 57600
} t_part_id;

@interface BLETIOADProfile ()
@property (strong, nonatomic) BLEDevice *bleDevice;
@end

@implementation BLETIOADProfile {
    t_part_id g_PartID;
    double secondsPerBlock;
    float secondsLeft;
    NSTimer *gTimer;
    int8_t iCheckTimes;
    BOOL bUpgradeSuccess;
    NSUInteger avSizeLeft;
    UIAlertView *completeOK;
    double writeInterval;
    uint64_t time1;
    uint64_t time2;
    uint64_t elapsed;
    uint8_t times;
    uint64_t msAll;
}

-(id) initWithDevice:(BLEDevice *) dev {
    NSLog(@"%s", __func__);
    self = [[BLETIOADProfile alloc]init];
    if (self) {
        self.d = dev;
        self.d.p.delegate = self;
        self.d.manager.delegate = self;
        self.canceled = FALSE;
        self.inProgramming = FALSE;
        self.start = YES;
        g_PartID = m328p_8M_3_3V;
    }
    return self;
}

-(void) makeConfigurationForProfile {
    NSLog(@"%s", __func__);
    if (!self.d.setupData) self.d.setupData = [[NSMutableDictionary alloc] init];
    // Append the UUID to make it easy for app
#if 0
    [self.d.setupData setValue:@"0xF000F0C0-0451-4000-B000-000000000000" forKey:@"OAD Service UUID"];
    [self.d.setupData setValue:@"0xF000F0C1-0451-4000-B000-000000000000" forKey:@"OAD Image Notify UUID"];
    [self.d.setupData setValue:@"0xF000F0C2-0451-4000-B000-000000000000" forKey:@"OAD Image Block Request UUID"];

    [self.d.setupData setValue:@"0xF000CCC0-0451-4000-B000-000000000000" forKey:@"CC Service UUID"];
    [self.d.setupData setValue:@"0xF000CCC1-0451-4000-B000-000000000000" forKey:@"CC Conn. Params UUID"];
    [self.d.setupData setValue:@"0xF000CCC2-0451-4000-B000-000000000000" forKey:@"CC Conn. Params Req UUID"];
    [self.d.setupData setValue:@"0xF000CCC3-0451-4000-B000-000000000000" forKey:@"CC Disconnect Req UUID"];
#else
    [self.d.setupData setValue:@"0xF0C0" forKey:@"OAD Service UUID"];
    [self.d.setupData setValue:@"0xF0C1" forKey:@"OAD Image Notify UUID"];
    [self.d.setupData setValue:@"0xF0C2" forKey:@"OAD Image Block Request UUID"];

    [self.d.setupData setValue:@"0xCCC0" forKey:@"CC Service UUID"];
    [self.d.setupData setValue:@"0xCCC1" forKey:@"CC Conn. Params UUID"];
    [self.d.setupData setValue:@"0xCCC2" forKey:@"CC Conn. Params Req UUID"];
    [self.d.setupData setValue:@"0xCCC3" forKey:@"CC Disconnect Req UUID"];
#endif
    NSLog(@"%@",self.d.setupData);
}

#if 0
-(void) configureProfile {
    NSLog(@"Configurating OAD Profile");
//    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
//    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]];
//    [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];
    [self.d.p setNotifyValue:YES forCharacteristic:self.d.cImageNotiy];
    unsigned char data = 0x00;
//    [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
    [self.d.p writeValue:[NSData dataWithBytes:&data length:1] forCharacteristic:self.d.cImageNotiy type:CBCharacteristicWriteWithResponse];
    self.imageDetectTimer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(imageDetectTimerTick:) userInfo:nil repeats:NO];
    self.imgVersion = 0xFFFF;
    self.start = YES;
    
    [self performSelector:@selector(checkTest) withObject:nil afterDelay:2.0];
}
#else
-(void) configureProfile {
    NSLog(@"%s", __func__);
    [self.d.p setNotifyValue:YES forCharacteristic:self.d.cImageNotiy];
    //[self.d.p setNotifyValue:YES forCharacteristic:self.d.cTransport];
    self.start = YES;

    //[self performSelector:@selector(testTransport) withObject:nil afterDelay:2.01];
}
#endif

-(void)testTransport {
    NSLog(@"%s", __func__);
    //NSString *nihao = [NSString stringWithUTF8String:"nishi shuiya?"];
    char requestData[128];
    strcpy(requestData, "Bitbucket:9=IMngF09kBitbucket:9=IMngF0\r\n");
    [self.d.p writeValue:[NSData dataWithBytes:requestData length:strlen(requestData)] forCharacteristic:self.d.cTransport type:CBCharacteristicWriteWithoutResponse];
}
- (void) checkTest {
    NSLog(@"%s, cImageBlock = %@", __func__, self.d.cImageBlock);
}

-(void) deconfigureProfile {
    NSLog(@"Deconfiguring OAD Profile");
    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]];
    [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];
}

-(IBAction)selectImagePressed:(id)sender {
    NSLog(@"%s", __func__);
//    if (![self.d.p isConnected]) {
    if (self.d.p.state == CBPeripheralStateDisconnected) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Device disconnected !" message:@"Unable to start programming when device is not connected ..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Reconnect",nil];
        [alertView show];
        alertView.tag = 1;
        //return;
    }
    _idViewController = sender;
    UIActionSheet *selectImageActionSheet = [[UIActionSheet alloc]initWithTitle:@"Select image from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Internal Image ...",@"Shared files ...",nil];
    selectImageActionSheet.tag = 0;
    [selectImageActionSheet showInView:self.view];

    
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"Button clicked : %d",buttonIndex);
    switch (actionSheet.tag) {
        case 0: {
            switch(buttonIndex) {
                case 0: {
                    UIActionSheet *selectInternalFirmwareSheet = [[UIActionSheet alloc]initWithTitle:@"Select Firmware image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"blink328pShort.bin",@"blink328pLong.bin",
                                                                  @"Blink644pShort.bin",@"Blink644pLong.bin",
                                                                  @"MPU6050_328p.bin",@"MPU6050_328p.FLASH.bin",@"644p_64K_Long.bin",@"644p_64K_Short",@"1284p_64K_Long",@"1284p_64K_Short",@"1284p_90K_Long",@"1284p_90K_Short",@"1284p_13K_Long", @"1284p_13K_Short", @"1284p_127K_Long", @"1284p_127K_Short",@"1284p_5K_Long",@"1284p_5K_Short",@"644pa16m_ChenHao", nil];
                    selectInternalFirmwareSheet.tag = 1;
                    [selectInternalFirmwareSheet showInView:self.view];
                    break;
                }
                case 1: {
                    NSMutableArray *files = [self findFWFiles];
                    UIActionSheet *selectSharedFileFirmware = [[UIActionSheet alloc]init];
                    selectSharedFileFirmware.title = @"Select Firmware image";
                    selectSharedFileFirmware.tag = 2;
                    selectSharedFileFirmware.delegate = self;
                    
                    for (NSString *fileName in files) {
                        [selectSharedFileFirmware addButtonWithTitle:[fileName lastPathComponent]];
                    }
                    [selectSharedFileFirmware addButtonWithTitle:@"Cancel"];
                    selectSharedFileFirmware.cancelButtonIndex = selectSharedFileFirmware.numberOfButtons - 1;
                    [selectSharedFileFirmware showInView:self.view];
                    break;
                }
            }
            break;
        }
        case 1: {
            switch (buttonIndex) {
                case 0: {
                    g_PartID = m328p_8M_3_3V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"blink.bin"];
                    [self validateImage:path];
                    break;
                }
                case 1: {
                    g_PartID = m328p_8M_3_3V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"blink1.bin"];
                    [self validateImage:path];
                    break;
                }
                case 2: {
                    g_PartID = m644p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"Blink.short.bin"];
                    [self validateImage:path];
                    break;
                }
                case 3: {
                    g_PartID = m644p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"Blink.cpp.bin"];
                    [self validateImage:path];
                    break;
                }
                case 4: {
                    g_PartID = m328p_8M_3_3V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"MPU6050_DMP6.cpp.bin"];
                    [self validateImage:path];
                    break;
                }
                case 5: {
                    g_PartID = m328p_8M_3_3V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"MPU6050_FLASH.bin"];
                    [self validateImage:path];
                    break;
                }
                case 6: {
                    g_PartID = m644p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"644p_64K_Long.bin"];
                    [self validateImage:path];
                    break;
                }
                case 7: {
                    g_PartID = m644p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"644p_64K_Short.bin"];
                    [self validateImage:path];
                    break;
                }
                case 8: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_64K_Long.bin"];
                    [self validateImage:path];
                    break;
                }
                case 9: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_64K_Short.bin"];
                    [self validateImage:path];
                    break;
                }
                case 10: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_90K_Long.bin"];
                    [self validateImage:path];
                    break;
                }
                case 11: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_90K_Short.bin"];
                    [self validateImage:path];
                    break;
                }
                case 12: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_13K_Long.bin"];
                    [self validateImage:path];
                    break;
                }
                case 13: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_13K_Short.bin"];
                    [self validateImage:path];
                    break;
                }
                case 14: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_127K_long.bin"];
                    [self validateImage:path];
                    break;
                }
                case 15: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_127K_short.bin"];
                    [self validateImage:path];
                    break;
                }
                case 16: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_5K_Long.bin"];
                    [self validateImage:path];
                    break;
                }
                case 17: {
                    g_PartID = m1284p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"1284p_5K_Short.bin"];
                    [self validateImage:path];
                    break;
                }
                case 18: {
                    g_PartID = m644p_16M_5V;
                    NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
                    [path appendString:@"/"] ;
                    [path appendString:@"644pa16m_ChenHao.bin"];
                    [self validateImage:path];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 2: {
            if (buttonIndex == actionSheet.numberOfButtons - 1) break;
            NSMutableArray *files = [self findFWFiles];
            NSString *fileName = [files objectAtIndex:buttonIndex];
            NSLog(@"fileName = %@", fileName);
            NSString * lastPC =[fileName lastPathComponent];
            NSLog(@"lastPC = %@", lastPC);
            if ([lastPC hasPrefix:@"1284p"]) {
                g_PartID = m1284p_16M_5V;
            }
            else if ([lastPC hasPrefix:@"644p"])
            {
                g_PartID = m644p_16M_5V;
            }
            else if ([lastPC hasPrefix:@"328p"]) {
                g_PartID = m328p_8M_3_3V;
            }
            else if ([lastPC hasPrefix:@"32u4"]) {
                g_PartID = m32u4_16M;
            }
            else if ([lastPC hasPrefix:@"128rfa"]) {
                g_PartID = m128rfa116m;
            }
            [self validateImage:fileName];
            break;
        }
        default:
        break;
    }
}

-(void)forAutoTest: (id)sender {
    static uint8_t u8whichOne = 0;
    _idViewController = sender;
    g_PartID = m1284p_16M_5V;
#if 0
    char fileNameCharsLong[] = "/var/mobile/Containers/Bundle/Application/2A5B3E5E-A401-4E66-BD83-B9FE5D811737/TIOADExample.app/1284p_13K_Long.bin";
    char fileNameCharsShort[] = "/var/mobile/Containers/Bundle/Application/C5A2BCB3-5874-4A9D-ACCF-3628695C5046/TIOADExample.app/1284p_13K_Short.bin";
    NSString *fileNameLong =  [NSString stringWithCString:fileNameCharsLong encoding:NSASCIIStringEncoding];
    NSString *fileNameShort =  [NSString stringWithCString:fileNameCharsShort encoding:NSASCIIStringEncoding];
    NSLog(@"fileNameCharsLong = %@", fileNameLong);
    NSLog(@"fileNameCharsShort = %@", fileNameShort);
#endif
#if 0
    if (u8whichOne == 0) {
        NSMutableString *pathLong = [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
        [pathLong appendString:@"/"] ;
        [pathLong appendString:@"1284p_5K_Long.bin"];
        [self validateImage:pathLong];
        u8whichOne = 1;
    }
    else {
        NSMutableString *pathShort = [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
        [pathShort appendString:@"/"] ;
        [pathShort appendString:@"1284p_5K_Short.bin"];
        [self validateImage:pathShort];
        u8whichOne = 0;
    }
#elif 0
    if (u8whichOne == 0) {
        NSMutableString *pathLong = [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
        [pathLong appendString:@"/"] ;
        [pathLong appendString:@"1284p_13K_Long.bin"];
        [self validateImage:pathLong];
        u8whichOne = 1;
    }
    else {
        NSMutableString *pathShort = [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
        [pathShort appendString:@"/"] ;
        [pathShort appendString:@"1284p_13K_Short.bin"];
        [self validateImage:pathShort];
        u8whichOne = 0;
    }
#else
    if (u8whichOne == 0) {
        NSMutableString *pathLong = [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
        [pathLong appendString:@"/"] ;
        [pathLong appendString:@"MPU6050_DMP6.cpp.bin"];
        [self validateImage:pathLong];
        u8whichOne = 1;
    }
    else {
        NSMutableString *pathShort = [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
        [pathShort appendString:@"/"] ;
        [pathShort appendString:@"MPU6050_FLASH.bin"];
        [self validateImage:pathShort];
        u8whichOne = 0;
    }
#endif
}

-(void) uploadImage:(NSString *)filename {
    NSLog(@"%s", __func__);
    self.inProgramming = YES;
    self.canceled = NO;
    
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    
    uint8_t requestData[OAD_IMG_HDR_SIZE + 2 + 2]; // 12Bytes
    for(int ii = 0; ii < 20; ii++) {
        NSLog(@"%02hhx",imageFileData[ii]);
    }
    
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    
    requestData[0] = LO_UINT16(imgHeader.ver);
    requestData[1] = HI_UINT16(imgHeader.ver);
    
    requestData[2] = LO_UINT16(imgHeader.len);
    requestData[3] = HI_UINT16(imgHeader.len);
    
    NSLog(@"Image version = %04hx, len = %04hx",imgHeader.ver,imgHeader.len);
    
    memcpy(requestData + 4, &imgHeader.uid, sizeof(imgHeader.uid));
    
    requestData[OAD_IMG_HDR_SIZE + 0] = LO_UINT16(12);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(12);
    
    requestData[OAD_IMG_HDR_SIZE + 2] = LO_UINT16(15);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(15);

//    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
//    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]];
//    [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:requestData length:OAD_IMG_HDR_SIZE + 2 + 2]];
    
    [self.d.p writeValue:[NSData dataWithBytes:requestData length:OAD_IMG_HDR_SIZE + 2 + 2] forCharacteristic:self.d.cImageNotiy type:CBCharacteristicWriteWithResponse];
    
    self.nBlocks = imgHeader.len / (OAD_BLOCK_SIZE / HAL_FLASH_WORD_SIZE);
    self.nBytes = imgHeader.len * HAL_FLASH_WORD_SIZE;
    self.iBlocks = 0;
    self.iBytes = 0;

    _imageFileData = malloc(self.imageFile.length);
    [self.imageFile getBytes:_imageFileData];
    
    [NSTimer scheduledTimerWithTimeInterval:2.1 target:self selector:@selector(programmingTimerTick) userInfo:nil repeats:NO];
}

-(void) programmingTimerTick {
//    NSLog(@"%s", __func__);
    if (self.canceled) {
        self.canceled = FALSE;
        return;
    }
    
    //Prepare Block
    uint8_t requestData[2 + OAD_BLOCK_SIZE];
    
    // This block is run 4 times, this is needed to get CoreBluetooth to send consequetive packets in the same connection interval.
    for (int ii = 0; ii < 4; ii++) {
        
        requestData[0] = LO_UINT16(self.iBlocks);
        requestData[1] = HI_UINT16(self.iBlocks);
        
        memcpy(&requestData[2] , _imageFileData + self.iBytes, OAD_BLOCK_SIZE);
        
//        CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
//        CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Block Request UUID"]];
//        [BLEUtility writeNoResponseCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:requestData length:2 + OAD_BLOCK_SIZE]];
        [self.d.p writeValue:[NSData dataWithBytes:requestData length:2 + OAD_BLOCK_SIZE] forCharacteristic:self.d.cImageBlock type:CBCharacteristicWriteWithoutResponse];
        
        self.iBlocks++;
        self.iBytes += OAD_BLOCK_SIZE;
        
        if(self.iBlocks == self.nBlocks) {
            if ([BLEUtility runningiOSSeven]) {
                [self.navCtrl popToRootViewControllerAnimated:YES];
            }
            else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
            self.inProgramming = NO;
            [self completionDialog];
            free(_imageFileData);
            return;
        }
        else {
            if (ii == 3) {
                [NSTimer scheduledTimerWithTimeInterval:UPLOAD_INTERVERL target:self selector:@selector(programmingTimerTick) userInfo:nil repeats:NO];
            }
        }
    }
    
    if (self.iBlocks % 16) {
//        NSLog(@"Oh, iBlocks mo 16 != 0");
        return;
    }
    else {
//        NSLog(@"Oh, iBlocks mo 16 == 0");
    }
    
    self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
    self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
    float secondsPerBlock = UPLOAD_INTERVERL / 4;
    float secondsLeft = (float)(self.nBlocks - self.iBlocks) * secondsPerBlock;
    
    if ([BLEUtility runningiOSSeven]) {
        self.progressView.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        self.progressView.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressView.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }
    else {
        //self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        //self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressDialog.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }
    
    if (self.start) {
        self.start = NO;
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl pushViewController:self.progressView animated:YES];
        }
        else {
            self.progressDialog = [[BLETIOADProgressDialog alloc]initWithFrame:CGRectMake((self.view.bounds.size.width / 2) - 150, (self.view.bounds.size.height /2) - 80, self.view.bounds.size.width, 160)];
            self.progressDialog.delegate = self;
            [self.progressDialog show];
        }
    }
}

#pragma mark - To use Notiy logic to download the image.
//这种方式，可以保证PHOBOS重启后，绝对能升级成功，但是会慢
-(void) uploadImageNotify:(NSString *)filename {
    NSLog(@"%s", __func__);
    [self.d.p setNotifyValue:YES forCharacteristic:self.d.cImageBlock];
    self.inProgramming = YES;
    self.canceled = NO;
    
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    uint8_t requestData[OAD_IMG_HDR_SIZE + 2 + 2]; // 12Bytes
    
    for(int ii = 0; ii < 20; ii++) {
        NSLog(@"%02hhx",imageFileData[ii]);
    }
    
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    
    requestData[0] = LO_UINT16(imgHeader.ver);
    requestData[1] = HI_UINT16(imgHeader.ver);
    
    requestData[2] = LO_UINT16(imgHeader.len);
    requestData[3] = HI_UINT16(imgHeader.len);
    
    NSLog(@"Image version = %04hx, len = %04hx",imgHeader.ver,imgHeader.len);
    
    memcpy(requestData + 4, &imgHeader.uid, sizeof(imgHeader.uid));
    
    requestData[OAD_IMG_HDR_SIZE + 0] = LO_UINT16(12);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(12);
    
    requestData[OAD_IMG_HDR_SIZE + 2] = LO_UINT16(15);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(15);
    
//    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
//    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]];
    
//    [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:requestData length:OAD_IMG_HDR_SIZE + 2 + 2]];
    [self.d.p writeValue:[NSData dataWithBytes:requestData length:OAD_IMG_HDR_SIZE + 2 + 2] forCharacteristic:self.d.cImageNotiy type:CBCharacteristicWriteWithResponse];
    
    self.nBlocks = imgHeader.len / (OAD_BLOCK_SIZE / HAL_FLASH_WORD_SIZE);
//    self.nBlocks = imgHeader.len / OAD_BLOCK_SIZE;
    self.nBytes = imgHeader.len * HAL_FLASH_WORD_SIZE;
    self.iBlocks = 0;
    self.iBytes = 0;
    NSLog(@"nBlocks = %d, nBytes = %d", self.nBlocks, self.nBytes);
    
//    _imageFileData = new uint8[10];
    _imageFileData = malloc(self.imageFile.length);
    [self.imageFile getBytes:_imageFileData];
}

-(void) programmingTimerTickNotify:(NSNumber*)blockNumber {
    NSLog(@"%s, blockNum = %@", __func__, blockNumber);
    if (self.canceled) {
        self.canceled = FALSE;
        return;
    }
    uint16_t blockNum = [blockNumber unsignedShortValue];
//    unsigned char imageFileData[self.imageFile.length];
//    [self.imageFile getBytes:imageFileData];
    
    //Prepare Block
    uint8_t requestData[2 + OAD_BLOCK_SIZE];
    requestData[0] = LO_UINT16(blockNum);
    requestData[1] = HI_UINT16(blockNum);
    memcpy(&requestData[2] , _imageFileData + self.iBytes, OAD_BLOCK_SIZE);
    
//    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
//    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Block Request UUID"]];
//    [BLEUtility writeNoResponseCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:requestData length:2 + OAD_BLOCK_SIZE]];
    [self.d.p writeValue:[NSData dataWithBytes:requestData length:2 + OAD_BLOCK_SIZE] forCharacteristic:self.d.cImageBlock type:CBCharacteristicWriteWithoutResponse];
    
    self.iBlocks = blockNum;
    self.iBytes += OAD_BLOCK_SIZE;
#if 0
    if(self.iBlocks == self.nBlocks) {
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl popToRootViewControllerAnimated:YES];
        }
        else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
        self.inProgramming = NO;
        [self completionDialog];
        return;
    }
#else
    if (self.iBytes >= self.nBytes) {
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl popToRootViewControllerAnimated:YES];
        }
        else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
        self.inProgramming = NO;
        [self completionDialog];
        return;
    }
#endif
    if (self.iBlocks % 8) {
        return;
    }
    self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
    self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
//    float secondsPerBlock = 0.12 / 4;
    float secondsPerBlock = 0.12;
    float secondsLeft = (float)(self.nBlocks - self.iBlocks) * secondsPerBlock;
    
    if ([BLEUtility runningiOSSeven]) {
        self.progressView.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        self.progressView.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressView.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }
    else {
        self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
        self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressDialog.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }
    
//    NSLog(@".");
    if (self.start) {
        self.start = NO;
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl pushViewController:self.progressView animated:YES];
        
        }
        else {
            self.progressDialog = [[BLETIOADProgressDialog alloc]initWithFrame:CGRectMake((self.view.bounds.size.width / 2) - 150, (self.view.bounds.size.height /2) - 80, self.view.bounds.size.width, 160)];
            self.progressDialog.delegate = self;
            [self.progressDialog show];
        }
    }
}

-(void) uploadBinBegin:(NSString *)filename {
    NSLog(@"%s", __func__);
    [self.d.p setNotifyValue:YES forCharacteristic:self.d.cImageBlock];
    self.canceled = NO;
    self.inProgramming = YES;
    
    self.nBytes = self.imageFile.length;
    self.iBytes = 0;
    NSLog(@"iBytes = %d, nBytes = %d", self.iBytes, self.nBytes);
    
    _imageFileData = malloc(self.imageFile.length + OAD_BLOCK_SIZE);
    [self.imageFile getBytes:_imageFileData length:self.imageFile.length];
    memset(_imageFileData+self.imageFile.length, 0xFF, OAD_BLOCK_SIZE);
#ifdef WRITE_WITH_RESPONSE
    msAll = 0;
    times = 0;
    time1 = mach_absolute_time();
    writeInterval = 0.050;
#else
    writeInterval = 0.013;
#endif
    //secondsPerBlock = 0.04375;
    //secondsPerBlock = 0.00625;
    //secondsPerBlock = 0.0125;
    //secondsPerBlock = 0.009375;
    secondsPerBlock = writeInterval / OAD_BLOCK_SIZE;
    //[self performSelector:@selector(uploadBinTickNotify:) withObject:[NSNumber numberWithInt:self.iBytes] afterDelay:0.051];
#ifdef WRITE_WITH_RESPONSE
    [self performSelector:@selector(uploadBinTickNotify) withObject:nil afterDelay:0.051];
#else
    gTimer = [NSTimer scheduledTimerWithTimeInterval:writeInterval target:self selector:@selector(uploadBinTickNotify) userInfo:nil repeats:YES];
#endif
    iCheckTimes = 5;
    bUpgradeSuccess = NO;
}

//-(void) uploadBinTickNotify:(NSNumber*)blockNumber {
-(void) uploadBinTickNotify {
    //NSLog(@"%s, blockNum = %@", __func__, blockNumber);
    if (self.canceled) {
        self.canceled = FALSE;
        return;
    }
#ifdef WRITE_WITH_RESPONSE
    if (times < 5) {
        time2 = mach_absolute_time();
        elapsed = time2 - time1;
        time1 = time2;
        mach_timebase_info_data_t info;
        if (mach_timebase_info(&info) != KERN_SUCCESS) {
            NSLog(@"mach_timebase_info failed");
        }
        uint64_t nanosecs = elapsed * info.numer / info.denom;
        msAll += (nanosecs / 1000000);
        times++;
    }
    else if (times == 5) {
        secondsPerBlock = (msAll / (double)times / 1000) / (double)OAD_BLOCK_SIZE;
        NSLog(@"secondsPerBlock = %f, msAll = %llu, times = %d", secondsPerBlock, msAll, times);
        times++;
    }
#endif
    //Prepare Block
    uint8_t requestData[OAD_BLOCK_SIZE];
    memcpy(requestData, _imageFileData + self.iBytes, OAD_BLOCK_SIZE);
//    NSLog(@"self.iBytes = %d", self.iBytes);
    if (self.iBytes < self.nBytes) {
#if 0
        int len = self.nBytes - self.iBytes;
        if (len > OAD_BLOCK_SIZE) {
            len = OAD_BLOCK_SIZE;
        }
#else
        int len = OAD_BLOCK_SIZE;
#endif
#ifdef WRITE_WITH_RESPONSE
        [self.d.p writeValue:[NSData dataWithBytes:requestData length:len] forCharacteristic:self.d.cImageBlock type:CBCharacteristicWriteWithResponse];
#else
        [self.d.p writeValue:[NSData dataWithBytes:requestData length:len] forCharacteristic:self.d.cImageBlock type:CBCharacteristicWriteWithoutResponse];
#endif
    }
    self.iBytes += OAD_BLOCK_SIZE;
#if 0
    if(self.iBlocks == self.nBlocks) {
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl popToRootViewControllerAnimated:YES];
        }
        else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
        self.inProgramming = NO;
        [self completionDialog];
        return;
    }
#else
    if (self.iBytes >= self.nBytes) {
#ifndef WRITE_WITH_RESPONSE
        [gTimer invalidate];
#endif
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTimeOut) object:nil];
        [self performSelector:@selector(updateTimeOut) withObject:nil afterDelay:3.0];
        return;
    }
#endif
    if (self.iBytes % 76) {
        return;
    }
    //self.progressDialog.progressBar.progress = (float)((float)self.iBytes / (float)self.nBytes);
    //self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBytes / (float)self.nBytes) * 100.0f];
    //    float secondsPerBlock = 0.12 / 4;
    
    secondsLeft = (float)(self.nBytes - self.iBytes) * secondsPerBlock;
    
    if ([BLEUtility runningiOSSeven]) {
        self.progressView.progressBar.progress = (float)((float)self.iBytes / (float)self.nBytes);
        self.progressView.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBytes / (float)self.nBytes) * 100.0f];
        self.progressView.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }
    else {
//        self.progressDialog.progressBar.progress = (float)((float)self.iBlocks / (float)self.nBlocks);
//        self.progressDialog.label1.text = [NSString stringWithFormat:@"%0.1f%%",(float)((float)self.iBlocks / (float)self.nBlocks) * 100.0f];
        self.progressDialog.label2.text = [NSString stringWithFormat:@"Time remaining : %d:%02d",(int)(secondsLeft / 60),(int)secondsLeft - (int)(secondsLeft / 60) * (int)60];
    }
    
    //    NSLog(@".");
#if 0
    if (self.start) {
        self.start = NO;
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl pushViewController:self.progressView animated:YES];
        }
        else {
            self.progressDialog = [[BLETIOADProgressDialog alloc]initWithFrame:CGRectMake((self.view.bounds.size.width / 2) - 150, (self.view.bounds.size.height /2) - 80, self.view.bounds.size.width, 160)];
            self.progressDialog.delegate = self;
            [self.progressDialog show];
        }
    }
#endif
}

-(void) resetCC2541 {
    NSLog(@"%s", __func__);
    uint8_t requestData[4] = {0x61, 0x79, 0xB3, 0xAF};
    [self.d.p writeValue:[NSData dataWithBytes:requestData length:sizeof(requestData)] forCharacteristic:self.d.cErrorReset type:CBCharacteristicWriteWithoutResponse];
}
-(void) updateTimeOut {
    NSLog(@"%s", __func__);
    
    if (bUpgradeSuccess == YES) {
        if ([BLEUtility runningiOSSeven]) {
            [self.navCtrl popToRootViewControllerAnimated:YES];
        }
        else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
        self.inProgramming = NO;
        [self completionDialog];
    }
    else {
        iCheckTimes--;
        if (iCheckTimes <= 0) {
            if ([BLEUtility runningiOSSeven]) {
                [self.navCtrl popToRootViewControllerAnimated:YES];
            }
            else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
            self.inProgramming = NO;
            [self completionDialogFail];
            [self resetCC2541];
        }
        else {
            [self performSelector:@selector(updateTimeOut) withObject:nil afterDelay:3.0];
        }
    }
}
-(void) didUpdateValueForProfile:(CBCharacteristic *)characteristic {
    NSLog(@"%s", __func__);
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]]]) {
        if (self.imgVersion == 0xFFFF) {
            unsigned char data[characteristic.value.length];
            [characteristic.value getBytes:&data];
            self.imgVersion = ((uint16_t)data[1] << 8 & 0xff00) | ((uint16_t)data[0] & 0xff);
            NSLog(@"self.imgVersion from BLE : %04hx", self.imgVersion);
         }
        NSLog(@"OAD Image notify : %@", characteristic.value);
        
    }
}
-(void) didWriteValueForProfile:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForProfile : %@",characteristic);
}

-(NSMutableArray *) findFWFiles {
    NSLog(@"%s", __func__);
    NSMutableArray *FWFiles = [[NSMutableArray alloc]init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *publicDocumentsDir = [paths objectAtIndex:0];
    
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:publicDocumentsDir error:&error];
    
    
    if (files == nil) {
        NSLog(@"Could not find any firmware files ...");
        return FWFiles;
    }
    for (NSString *file in files) {
        if ([file.pathExtension compare:@"bin" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            NSString *fullPath = [publicDocumentsDir stringByAppendingPathComponent:file];
            [FWFiles addObject:fullPath];
        }
    }

    return FWFiles;
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSLog(@"%s", __func__);
    if (alertView.tag == 0) {
        self.canceled = TRUE;
        self.inProgramming = NO;
    }
    else if ((alertView.tag == 1) && buttonIndex == 1) {
        [self.d.manager connectPeripheral:self.d.p options:nil];
    }
}

-(void)deviceDisconnected:(CBPeripheral *)peripheral {
    NSLog(@"%s", __func__);
    if ([peripheral isEqual:self.d.p] && self.inProgramming) {
        [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"FW Upgrade Failed !" message:@"Device disconnected during programming, firmware upgrade was not finished !" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = 0;
        [alertView show];
        self.inProgramming = NO;
    }
}

#if 0
-(BOOL)validateImage:(NSString *)filename {
    NSLog(@"%s", __func__);
    self.imageFile = [NSData dataWithContentsOfFile:filename];
    NSLog(@"Loaded firmware \"%@\"of size : %d",filename,self.imageFile.length);
    if ([self isCorrectImage]) {
        [self uploadImageNotify:filename];
        //[self uploadImage:filename];
    }
    else {
        UIAlertView *wrongImage = [[UIAlertView alloc]initWithTitle:@"Wrong image type !" message:[NSString stringWithFormat:@"Image that was selected was of type : %c, which is the same as on the peripheral, please select another image",(self.imgVersion & 0x01) ? 'B' : 'A'] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        [wrongImage show];
        NSLog(@"hehe");
    }
    return NO;
}
#else
-(BOOL)validateImage:(NSString *)filename {
    NSLog(@"%s", __func__);
    [self.navCtrl pushViewController:self.progressView animated:YES];
    self.imageFile = [NSData dataWithContentsOfFile:filename];
    NSLog(@"Loaded firmware \"%@\"of size : %d",filename,self.imageFile.length);
    
    NSInteger size = self.imageFile.length;
    //size = 96999;
    uint8_t requestData[5];
    requestData[0] = size & 0xff;
    requestData[1] = (size >> 8) & 0xff;
    requestData[2] = (size >> 16) & 0xff;
    requestData[3] = (size >> 24) & 0xff;
    requestData[4] = g_PartID;
    [self.d.p writeValue:[NSData dataWithBytes:requestData length:sizeof(requestData)] forCharacteristic:self.d.cImageNotiy type:CBCharacteristicWriteWithoutResponse];
    
    return YES;
}
#endif

-(BOOL) isCorrectImage {
    NSLog(@"%s", __func__);
    return NO;
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    NSLog(@"imgHeader.ver : %04hx", imgHeader.ver);
    NSLog(@"ver = %d", imgHeader.ver);
    if ((imgHeader.ver & 0x01) != (self.imgVersion & 0x01)) {
        return YES;
    }
    
    return NO;
}

-(void) imageDetectTimerTick:(NSTimer *)timer {
    //IF we have come here, the image userID is B.
    NSLog(@"%s", __func__);
//    CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Service UUID"]];
//    CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]];
    unsigned char data = 0x01;
//    [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
    [self.d.p writeValue:[NSData dataWithBytes:&data length:1] forCharacteristic:self.d.cImageNotiy type:CBCharacteristicWriteWithResponse];
}

-(void) completionDialogOK {
    [completeOK dismissWithClickedButtonIndex:0 animated:YES];
    
}
-(void) completionDialog {
    NSLog(@"%s", __func__);
//    UIAlertView *complete;
    NSString * avs = [NSString stringWithFormat:@"Firmware upgrade was successfully completed, device needs to be reconnected.The left flash size is %ld(0x%08X)", (unsigned long)avSizeLeft, avSizeLeft];
    completeOK = [[UIAlertView alloc]initWithTitle:@"Firmware upgrade complete" message:avs delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [completeOK show];
    [self performSelector:@selector(completionDialogOK) withObject:nil afterDelay:3.5];
    [UIScreen mainScreen].brightness = 0.8;
}

-(void) completionDialogFail {
    NSLog(@"%s", __func__);
    UIAlertView *complete;
    complete = [[UIAlertView alloc]initWithTitle:@"Firmware upgrade fail" message:@"请把手机和CC2541靠近，再重试。CC2541将重启" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [complete show];
    [UIScreen mainScreen].brightness = 0.8;
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
    NSLog(@"%s, error = %@", __func__, error);
    [self deviceDisconnected:peripheral];
//    [_idViewController performSelector:@selector(disConnectFromUS) withObject:nil afterDelay:3.698];
}

#pragma mark - CBPeripheralDelegate Callbacks

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error  {
    NSLog(@"%s", __func__);
    for (CBService *s in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:s];
    }
}
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"%s", __func__);
    NSLog(@"Service : %@", service.UUID);
    NSLog(@"Characteristic : %@", service.characteristics);
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"0xF0C0"]]) {
        [_idViewController performSelector:@selector(setButton2Title) withObject:nil afterDelay:0.1];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"%s,characteristic = %@, error = %@", __func__, characteristic, error);
//    [self didUpdateValueForProfile:characteristic];
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Block Request UUID"]]]) {
        uint8 datas[characteristic.value.length];
        [characteristic.value getBytes:datas length:characteristic.value.length];
        NSUInteger wSize = ((NSUInteger)(datas[0]&0xff))|((NSUInteger)(datas[1]<<8 & 0xff00))|((NSUInteger)(datas[2]<<16 & 0xff0000))|((NSUInteger)(datas[3]<<24 & 0xff000000));

        NSUInteger avSize = ((NSUInteger)(datas[4]&0xff))|((NSUInteger)(datas[5]<<8 & 0xff00))|((NSUInteger)(datas[6]<<16 & 0xff0000))|((NSUInteger)(datas[7]<<24 & 0xff000000));
        //NSLog(@"size = %d", size);

        //if (size != 0)
        {
//            [self performSelector:@selector(uploadBinTickNotify:) withObject:[NSNumber numberWithUnsignedShort:size]];
            NSLog(@"Had write %d(0x%08X) bytes to CC2541. The left flash is %d(0x%08X) bytes", wSize, wSize, avSize, avSize);
        }
        avSizeLeft = avSize;
        bUpgradeSuccess = YES;
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.d.setupData valueForKey:@"OAD Image Notify UUID"]]]) {
        //        NSLog(@"OAD Image notify : %@", characteristic.value);
        uint8 datas[characteristic.value.length];
        [characteristic.value getBytes:datas length:characteristic.value.length];
        NSUInteger avSize = ((NSUInteger)(datas[0]&0xff))|((NSUInteger)(datas[1]<<8 & 0xff00))|((NSUInteger)(datas[2]<<16 & 0xff0000))|((NSUInteger)(datas[3]<<24 & 0xff000000));
        NSLog(@"avSize = %d(0x%08X)", avSize, avSize);
        if (avSize == 0) {
            if ([BLEUtility runningiOSSeven]) {
                [self.navCtrl popToRootViewControllerAnimated:YES];
            }
            else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
            self.inProgramming = NO;
            UIAlertView *wrongImage = [[UIAlertView alloc]initWithTitle:@"Wrong Size!" message:@"The bin size is too big!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
            [wrongImage show];
        }
        else if (avSize == 0xFFFFFFFF) {
            if ([BLEUtility runningiOSSeven]) {
                [self.navCtrl popToRootViewControllerAnimated:YES];
            }
            else [self.progressDialog dismissWithClickedButtonIndex:0 animated:YES];
            self.inProgramming = NO;
            UIAlertView *wrongImage = [[UIAlertView alloc]initWithTitle:@"Wrong Size!" message:@"CC2541 will reset to release some flash" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
            [wrongImage show];
        }
        else {
            [self performSelector:@selector(uploadBinBegin:) withObject:@"hehe" afterDelay:1.1];
        }
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F0C4"]]) {
        char datas[characteristic.value.length + 1];
        [characteristic.value getBytes:datas length:characteristic.value.length+1];
        datas[characteristic.value.length] = 0;
        NSString *transString = [NSString stringWithCString:datas encoding:NSASCIIStringEncoding];
        NSLog(@"transString = %@", transString);
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A25"]]) {
        unsigned char data[characteristic.value.length+1];
        [characteristic.value getBytes:&data length:characteristic.value.length + 1];
        data[characteristic.value.length] = 0;
        for (int i = 0; i < characteristic.value.length; i++) {
            NSLog(@"0x%02X", data[i]);
        }
        NSString *serialNumber = [NSString stringWithUTF8String:(const char*)data];
        NSLog(@"serialNumber = %@", serialNumber);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //NSLog(@"%s, characteristic = %@, error = %@", __func__, characteristic, error);
    //[self performSelector:@selector(uploadBinTickNotify:) withObject:[NSNumber numberWithUnsignedShort:5]];
//    [self performSelector:@selector(uploadBinTickNotify:) withObject:[NSNumber numberWithInt:self.iBytes] afterDelay:0.051];
#ifdef WRITE_WITH_RESPONSE
    [self performSelector:@selector(uploadBinTickNotify)];
#endif
//    [self performSelector:@selector(uploadBinTickNotify) withObject:nil afterDelay:0.051];
}
@end