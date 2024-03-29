//
//  DefaultLayoutViewController.m
//  UILibraryDemo
//
//  Created by DJI on 16/4/2017.
//  Copyright © 2017 DJI. All rights reserved.
//

#import "DefaultLayoutViewController.h"
@import SocketIO;

@interface DefaultLayoutViewController ()<DJISDKManagerDelegate, DJIGimbalDelegate,DJIFlightControllerDelegate, DJIFlightAssistantDelegate>
@property DJIFlightController* flightController;

@property DJIGimbal* djiGimbal;
@property DJIGimbalAttitudeAction* gimbalAction;
@property DJIMissionControl* missionControl;

@property (atomic) DJIGimbalAttitude gimbalAtti;
@property (atomic) DJIVirtualStickFlightControlData controlData;
@property DJIGimbalRotation *rotationData;
@property DJIFlightAssistant *flightAssistant;

@property NSURL* url;
@property SocketManager* manager;
@property SocketIOClient* socket;
@property (atomic) NSMutableDictionary* sdInfoBuff;
@property (atomic) NSMutableDictionary* socketSig;
@property int socketNum;

@property BOOL SDFlying;
@property BOOL autoSwitchStateBoo;
@property (atomic) float sliderValue;
@property BOOL goHomeF;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UILabel *label4;
@property (weak, nonatomic) IBOutlet UILabel *label5;
@property (weak, nonatomic) IBOutlet UILabel *label6;
@property (weak, nonatomic) IBOutlet UILabel *label7;
@property (weak, nonatomic) IBOutlet UILabel *label8;
@property (weak, nonatomic) IBOutlet UILabel *label9;
@property (weak, nonatomic) IBOutlet UISlider *sliderBarForTes;
@property (weak, nonatomic) IBOutlet UIButton *setControllerModeButton;
@property (weak, nonatomic) IBOutlet UIButton *stubSDSoc;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImage;


@property (atomic) double latSpeed;
@property (atomic) double lonSpeed;
@property (atomic) double targetAlt;
@property (atomic) double targetYaw;
@property (atomic) double gyroZ;

@property CATransform3D pitchTrans;
@property CATransform3D yawTrans;

@property (atomic) CLLocation* sdLocation;
@property (atomic) double SDAlt;
@property (atomic) double flightTime;
@property (atomic) double gimbalAngle;

- (IBAction)sliderBarForGimbal:(UISlider *)sender;
- (IBAction)autoOperateSwitch:(UISwitch *)sender;
- (IBAction)showInfoLabel:(UISwitch *)sender;
- (IBAction)setControllerMode:(UIButton *)sender;
- (IBAction)stubPD:(id)sender;
- (IBAction)sliderBar2:(UISlider *)sender;

@property (atomic) float sliderValue2;
@end

@implementation DefaultLayoutViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    //Please enter your App Key in the info.plist file.
    [DJISDKManager registerAppWithDelegate:self];
    [NSTimer scheduledTimerWithTimeInterval:0.03f target:self selector:@selector(Vmethod:) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(Tmethod:) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.3f target:self selector:@selector(Tmethod2:) userInfo:nil repeats:YES];
    self.url = [[NSURL alloc] initWithString:@"http://192.168.100.154:5000"];
    self.manager = [[SocketManager alloc] initWithSocketURL:self.url config:@{@"log": @YES, @"compress": @YES}];
    self.socket = self.manager.defaultSocket;

    UIImage *image = [UIImage imageNamed:@"arrowMark_line.png"];
   //  self.arrowImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrowMark.png"]];
    self.arrowImage.image = image;
    [self.view addSubview:self.arrowImage];
    [self.view bringSubviewToFront:self.arrowImage];
    
    [self.socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket connected");
    }];
    [self.socket on:@"v2Cont" callback:^(NSArray * data, SocketAckEmitter * ack) {
        self.latSpeed = [[data[0] objectForKey:@"latSpeed"] doubleValue];
        self.lonSpeed = [[data[0] objectForKey:@"lonSpeed"] doubleValue];
        self.targetAlt = [[data[0] objectForKey:@"alt"] doubleValue];
        self.targetYaw = [[data[0] objectForKey:@"yaw"] doubleValue];
        self.gimbalAngle = [[data[0] objectForKey:@"gimbalAngle"] doubleValue];
        self.gyroZ = [[data[0] objectForKey:@"gyroZ"] doubleValue];
        NSLog(@"latSpeed, lonSpeed, alt, yaw: %f, %f, %f, %f %f", self.latSpeed, self.lonSpeed, self.targetAlt, self.targetYaw, self.gimbalAngle);
    }];
    self.SDAlt = 6;
    /*
    [self.socket on:@"v2Posture" callback:^(NSArray * data, SocketAckEmitter * ack) {
        float v1Lat;
        float v1Lon;
        v1Lat = [[data[0] objectForKey:@"v1Lat"] doubleValue];
        v1Lon = [[data[0] objectForKey:@"v1Lon"] doubleValue];
        if((v1Lon - self.SDPosiCurrent.longitude) == 0){
            self.targetYaw = atan((v1Lat - self.SDPosiCurrent.latitude)/(0.00000001));
        }else{
            self.targetYaw = atan((v1Lat - self.SDPosiCurrent.latitude)/(v1Lon - self.SDPosiCurrent.longitude));
        }
        self.distanceBtDrone = [[data[0] objectForKey:@"dist"] doubleValue];
    }];
     */

    self.targetAlt = 0;
    self.targetYaw = 0;
    self.gimbalAngle = 0;
    self.socketNum = 0;
    
    [self.socket connect];
    self.sdInfoBuff = [NSMutableDictionary dictionary];
    self.socketSig = [NSMutableDictionary dictionary];
    [self.socketSig setObject:[NSNumber numberWithInt:self.socketNum] forKey:@"SDSocketNum"];
}

- (void)showAlertViewWithMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* alertViewController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertViewController addAction:okAction];
        UIViewController *rootViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
        [rootViewController presentViewController:alertViewController animated:YES completion:nil];
    });
}

#pragma mark DJISDKManager Delegate Methods
- (void)appRegisteredWithError:(NSError *)error
{
    if (!error) {
        [self showAlertViewWithMessage:@"Registration Success"];
        [DJISDKManager startConnectionToProduct];
    }else
    {
        [self showAlertViewWithMessage:[NSString stringWithFormat:@"Registration Error:%@", error]];
    }
}

- (void)productConnected:(DJIBaseProduct *)product
{
    //If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
    [[DJISDKManager userAccountManager] logIntoDJIUserAccountWithAuthorizationRequired:NO withCompletion:^(DJIUserAccountState state, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Login failed: %@", error.description);
        }
    }];
    self.djiGimbal = ((DJIAircraft*)[DJISDKManager product]).gimbal;
    self.djiGimbal.delegate = self;
    self.flightController = [self fetchFlightController];
    self.flightController.delegate = self;
    self.flightAssistant = self.flightController.flightAssistant;
    self.flightAssistant.delegate = self;
    [self.flightAssistant setCollisionAvoidanceEnabled:YES withCompletion:^(NSError * _Nullable error) {
    }];
    // Max speed of each direction is 15 m/s. and min speed is -15 m/s
    [self initControllerMode];
}

- (DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    return nil;
}

- (void) flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state{
    self.sdLocation = state.aircraftLocation;
    self.SDAlt = state.altitude;
    self.SDFlying = state.isFlying;
    self.flightTime = state.flightTimeInSeconds;
}


- (void)Vmethod:(NSTimer *)timer
{
    // [self.socket emit:@"v1params" with:[NSArray arrayWithObject:self.fPosiBuffStub]];
    [self.sdInfoBuff setObject:[NSNumber numberWithDouble:self.sdLocation.coordinate.latitude] forKey:@"lat"];
    [self.sdInfoBuff setObject:[NSNumber numberWithDouble:self.sdLocation.coordinate.longitude] forKey:@"lon"];
    [self.sdInfoBuff setObject:[NSNumber numberWithDouble:self.SDAlt] forKey:@"alt"];
    [self.sdInfoBuff setObject:[NSNumber numberWithDouble:self.flightTime] forKey:@"flightTime"];
    [self.socket emit:@"v2params" with:[NSArray arrayWithObject:self.sdInfoBuff]];
    self.label2.text = [NSString stringWithFormat:@"latSpeed, %f", self.latSpeed];
    self.label3.text = [NSString stringWithFormat:@"lonSpeed, %f", self.lonSpeed];
    self.label4.text = [NSString stringWithFormat:@"lat, %f", self.sdLocation.coordinate.latitude];
    self.label5.text = [NSString stringWithFormat:@"lon, %f", self.sdLocation.coordinate.longitude];
    if(self.autoSwitchStateBoo){
        self.label1.text = @"on";
        [self culcuControlData];
        [self.flightController sendVirtualStickFlightControlData:self.controlData withCompletion:^(NSError * _Nullable error) {
        }];
     //    [self culcuGimbalRotation];
        // self.rotationData = [DJIGimbalRotation gimbalRotationWithPitchValue:[NSNumber numberWithDouble:-self.gimbalAngle] rollValue:0 yawValue:0 time:0.2 mode:DJIGimbalRotationModeAbsoluteAngle];
        self.rotationData = [DJIGimbalRotation gimbalRotationWithPitchValue:[NSNumber numberWithFloat:-self.sliderValue] rollValue:0 yawValue:0 time:0.2 mode:DJIGimbalRotationModeAbsoluteAngle];
        [self.djiGimbal rotateWithRotation:self.rotationData completion:^(NSError * _Nullable error) {
        }];
        self.label9.text = [NSString stringWithFormat:@"targetAlt: %lf", self.targetAlt];
        self.label6.text = [NSString stringWithFormat:@"gimbal Angle: %lf", self.gimbalAngle];
    }else{
        self.label1.text = @"off";
    }
}
     

-(void) gimbal:(DJIGimbal *)gimbal didUpdateState:(DJIGimbalState *)state{
//    self.label6.text = [NSString stringWithFormat:@"%f", state.attitudeInDegrees.pitch];
}

-(void) culcuGimbalRotation{
     // self.gimbalAngle = -(atan((self.SDAltCurrent - self.PDAltCurrent )/ self.distanceBtDrone)* 0.5 * M_1_PI * 360);
     self.rotationData = [DJIGimbalRotation gimbalRotationWithPitchValue:[NSNumber numberWithDouble:self.gimbalAngle] rollValue:0 yawValue:0 time:0.2 mode:DJIGimbalRotationModeAbsoluteAngle];
    // self.rotationData = [DJIGimbalRotation gimbalRotationWithPitchValue:[NSNumber numberWithFloat:self.sliderValue] rollValue:0 yawValue:0 time:0.2 mode:DJIGimbalRotationModeAbsoluteAngle];
    
}

- (IBAction)sliderBarForGimbal:(UISlider *)sender {
    self.sliderValue = (sender.value);
}

- (void)culcuControlData{
    DJIVirtualStickFlightControlData data;
    data.verticalThrottle = self.targetAlt;
    data.yaw = self.targetYaw;
    data.pitch = self.lonSpeed;
    data.roll = self.latSpeed;
    self.controlData = data;
}

- (IBAction)autoOperateSwitch:(UISwitch *)sender {
    self.autoSwitchStateBoo = sender.isOn;
    if(self.autoSwitchStateBoo == TRUE && self.flightController){
        [self.flightController setFlightOrientationMode:DJIFlightOrientationModeAircraftHeading withCompletion:^(NSError * _Nullable error) {
        }];
        [self.flightController setVirtualStickModeEnabled:YES withCompletion:^(NSError * _Nullable error) {
        }];
        [self.flightController getVirtualStickModeEnabledWithCompletion:^(BOOL enabled, NSError * _Nullable error) {
        }];
    }
    if(self.autoSwitchStateBoo == FALSE && self.flightController){
        [self.flightController setFlightOrientationMode:DJIFlightOrientationModeAircraftHeading withCompletion:^(NSError * _Nullable error) {
        }];
        [self.flightController setVirtualStickModeEnabled:NO withCompletion:^(NSError * _Nullable error) {
        }];
        [self.flightController getVirtualStickModeEnabledWithCompletion:^(BOOL enabled, NSError * _Nullable error) {
        }];
    }
}

- (IBAction)showInfoLabel:(UISwitch *)sender {
    if(sender.isOn){
        self.label1.hidden = false;
        self.label2.hidden = false;
        self.label3.hidden = false;
        self.label4.hidden = false;
        self.label5.hidden = false;
        self.label6.hidden = false;
        self.label7.hidden = false;
        self.label8.hidden = false;
        self.label9.hidden = false;
        self.sliderBarForTes.hidden = false;
        self.setControllerModeButton.hidden = false;
    }else{
        self.label1.hidden = true;
        self.label2.hidden = true;
        self.label3.hidden = true;
        self.label4.hidden = true;
        self.label5.hidden = true;
        self.label6.hidden = true;
        self.label7.hidden = true;
        self.label8.hidden = true;
        self.label9.hidden = true;
        self.sliderBarForTes.hidden = true;
        self.setControllerModeButton.hidden = true;
    }
}

- (void) initControllerMode{
    self.flightController.rollPitchControlMode = DJIVirtualStickRollPitchControlModeVelocity;
    self.flightController.yawControlMode = DJIVirtualStickYawControlModeAngle;
    self.flightController.verticalControlMode = DJIVirtualStickVerticalControlModePosition;
    self.flightController.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystemGround;
    ((DUXFPVViewController*)self.contentViewController).fpvView.showCameraDisplayName = false;
}

- (IBAction)setControllerMode:(UIButton *)sender {
    self.flightController.rollPitchControlMode = DJIVirtualStickRollPitchControlModeVelocity;
    self.flightController.yawControlMode = DJIVirtualStickYawControlModeAngle;
    self.flightController.verticalControlMode = DJIVirtualStickVerticalControlModePosition;
    self.flightController.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystemGround;
    ((DUXFPVViewController*)self.contentViewController).fpvView.showCameraDisplayName = false;
}

- (IBAction)stubPD:(id)sender {
}

- (IBAction)sliderBar2:(UISlider *)sender {
    self.sliderValue2 = sender.value;
}

- (void)flightAssistant:(DJIFlightAssistant *)assistant
didUpdateVisionDetectionState:(DJIVisionDetectionState *)state{
    //state.detectionSectors[0].obstacleDistanceInMeters;
}

- (void)Tmethod:(NSTimer *)timer{
    self.socketNum += 1;
    [self.socketSig setObject:[NSNumber numberWithFloat:self.socketNum] forKey:@"SDSocketNum"];
    [self.socket emit:@"sdSocket" with:[NSArray arrayWithObject:self.socketSig]];
}

- (void)Tmethod2:(NSTimer *)timer{
    /*
    self.pitchTrans = CATransform3DMakeRotation((90 - self.gimbalAngle) * (M_PI/180),  1, 0, 0);
    self.yawTrans = CATransform3DMakeRotation(self.gyroZ*(M_PI/180), 0, 0, 1);
     */
    self.pitchTrans = CATransform3DMakeRotation(self.sliderValue2 * (M_PI/180),  1, 0, 0);
    self.yawTrans = CATransform3DMakeRotation(self.sliderValue * (M_PI/180), 0, 0, 1);
    // self.arrowImage.layer.sublayerTransform
    self.arrowImage.layer.transform = CATransform3DConcat(self.yawTrans, self.pitchTrans);
    // self.arrowImage.layer.transform = self.yawTrans;
   /*
    
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.5;
    animation.repeatCount = 1;
    animation.autoreverses = YES; //逆方向再生の設定
    // CATransform3D transform = CATransform3DMakeRotation(M_PI, 0.0, 1.0, 0.0);
    CATransform3D transform = CATransform3DConcat(self.yawTrans, self.pitchTrans);
    // transform.m34 = 1.0f / -420.0f;//回転に立体感を出す
    animation.toValue = [NSNumber valueWithCATransform3D:transform];
    */
    // [self.arrowImage.layer addAnimation:animation forKey:@"transform"];
   // self.arrowImage.layer.transform = CATransform3DConcat(self.yawTrans, self.pitchTrans);
    NSLog(@"image ok_____________-");
}
@end
