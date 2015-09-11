/*
 deviceSelectorViewController.m
 TIOADExample
 Created by Ole Andreas Torvmark on 1/7/13.
 Copyright (c) 2013 Texas Instruments. All rights reserved.
 
 */
 
#import "deviceSelectorViewController.h"

@interface deviceSelectorViewController ()
@property (strong,nonatomic) UIWindow *bWindow;

@end

@implementation deviceSelectorViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    NSLog(@"%s", __func__);
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        //self.devices = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"%s", __func__);
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"%s", __func__);
    for (CBPeripheral *peripheral in _devices) {
        if (!(peripheral.state == CBPeripheralStateDisconnected)) {
            [_manager cancelPeripheralConnection:peripheral];
        }
    }
    _devices = [NSMutableArray arrayWithCapacity:10];
    _devicesNames = [NSMutableArray arrayWithCapacity:10];
    
    [self performSelector:@selector(installBrightnessWindow) withObject:nil afterDelay:3.0];
}

-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"%s", __func__);
    self.manager.delegate = self;
    NSDictionary *optionsdict = @{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]};
//    [_bleManager scanForPeripheralsWithServices:nil options:optionsdict];
    [self.manager scanForPeripheralsWithServices:nil options:optionsdict];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"%s", __func__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)installBrightnessWindow {
    NSLog(@"%s", __func__);
    
    [UIScreen mainScreen].brightness = 0.8;
}

- (void)reConnect:(CBPeripheral*)peripheral {
    NSLog(@"%s", __func__);
    if (peripheral.state == CBPeripheralStateDisconnected) {
        [self.manager connectPeripheral:peripheral options:nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"%s", __func__);
    // Return the number of sections.
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSLog(@"%s", __func__);
    if (section == 0) return @"Actions";
    else if (section == 1) return @"Devices Found";
    else return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"%s", __func__);
    // Return the number of rows in the section.
    if (section == 0) return 1;
    else if (section == 1) return self.devices.count;
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%s", __func__);
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    // Configure the cell...
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Cancel";
    }
    if (indexPath.section == 1) {
        //CBPeripheral *p = [self.devices objectAtIndex:indexPath.row];
        //cell.textLabel.text = p.name;
        cell.textLabel.text = [self.devicesNames objectAtIndex:indexPath.row];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%s", __func__);
    [self.manager stopScan];
    if (indexPath.section == 1)
    {
        self.p = [self.devices objectAtIndex:indexPath.row];
        
        //[self.delegate didSelectDevice:_cImageNotiy imageBlock:_cImageBlock];
        [self.delegate didSelectPeripheral:[self.devicesNames objectAtIndex:indexPath.row]];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CBCentralManagerDelegate Callbacks

-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"%s", __func__);
}

-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"%s, RSSI = %@, name = %@, uuid = %@", __func__, RSSI, peripheral.name, peripheral.identifier.UUIDString);
    int iRssi = [RSSI intValue];
    NSLog(@"iRssi = %d", iRssi);
    // 只有当手机离Phobos很近的时候，才会识别。
    // 这样做是为了避免周围有很多Phobos，对配对产生混乱。
#if 0
    if (iRssi < -59 || iRssi > 0) {
        return;
    }
#endif
    NSString *localName = advertisementData[@"kCBAdvDataLocalName"];
    NSLog(@"localName = %@", localName);
    
    if (![localName hasPrefix:@"Elara"]) {
        NSLog(@"This is not a Elara, so just return !");
        return;
    }
    if ([self.devices containsObject:peripheral]) {
        NSLog(@"OH, Let's reconnect it!");
//        [self.manager connectPeripheral:peripheral options:nil];
        //[self performSelector:@selector(reConnect:) withObject:peripheral afterDelay:4.8];
        return;
    }
    else {
        if (self.devices.count <= 10) { // 因为我周围有20多个iBeacon，我不想影响她们
            [self.devices addObject:peripheral];
            [self.devicesNames addObject:localName];
#if 0
            [self.manager connectPeripheral:peripheral options:nil];
#else
            [self.tableView reloadData];
#endif
        }
    }
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%s", __func__);
    peripheral.delegate = self;
#if 1
    [peripheral discoverServices:nil];
#else
    [self.manager cancelPeripheralConnection:peripheral];
    [self.tableView reloadData];
#endif
}

- (void)letUsreloadData {
    NSLog(@"%s", __func__);
//    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:1.0];
    [self.tableView reloadData];
}

#pragma mark - CBPeripheralDelegate Callbacks

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"%s", __func__);
//    [self.manager cancelPeripheralConnection:peripheral];
//    [self.tableView reloadData];
    for (CBService *s in peripheral.services) {
        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"F000FFC0-0451-4000-B000-000000000000"]]) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
        else if ([s.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
        else if ([s.UUID isEqual:[CBUUID UUIDWithString:@"CCC0"]]) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
        else if ([s.UUID isEqual:[CBUUID UUIDWithString:@"013d8e3b-1877-4d5c-bc59-aaa7e5082346"]]) {
            [peripheral discoverCharacteristics:nil forService:s];
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"%s", __func__);
    NSLog(@"Service : %@", service.UUID);
    NSLog(@"Characteristic : %@", service.characteristics);
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"F000FFC0-0451-4000-B000-000000000000"]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F000FFC1-0451-4000-B000-000000000000"]]) {
                _cImageNotiy = characteristic;
            }
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F000FFC2-0451-4000-B000-000000000000"]]) {
                _cImageBlock = characteristic;
            }
        }
//        [self performSelector:@selector(letUsreloadData) withObject:nil afterDelay:1.0];
    }
    else if ([service.UUID isEqual:[CBUUID UUIDWithString:@"CCC0"]]) {
        [self performSelector:@selector(letUsreloadData) withObject:nil afterDelay:1.0];
    }
}
@end
