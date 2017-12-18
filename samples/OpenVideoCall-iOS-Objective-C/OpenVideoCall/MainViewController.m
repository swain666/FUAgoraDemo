//
//  MainViewController.m
//  OpenVideoCall
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import "MainViewController.h"
#import "SettingsViewController.h"
#import "RoomViewController.h"

@interface MainViewController () <SettingsVCDelegate, RoomVCDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *roomNameTextField;

@property (assign, nonatomic) AgoraRtcVideoProfile videoProfile;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoProfile = AgoraRtc_VideoProfile_360P;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueId = segue.identifier;
    
    if ([segueId isEqualToString:@"mainToSettings"]) {
        SettingsViewController *settingsVC = segue.destinationViewController;
        settingsVC.videoProfile = self.videoProfile;
        settingsVC.delegate = self;
    } else if ([segueId isEqualToString:@"mainToRoom"]) {
        RoomViewController *roomVC = segue.destinationViewController;
        roomVC.roomName = sender;
        roomVC.videoProfile = self.videoProfile;
        roomVC.delegate = self;
    }
}

- (IBAction)doJoinPressed:(UIButton *)sender {
    [self enterRoom:self.roomNameTextField.text];
}

- (void)enterRoom:(NSString *)roomName {
    if (!roomName.length) {
        return;
    }
    
    [self performSegueWithIdentifier:@"mainToRoom" sender:roomName];
}

//MARK: - delegates
- (void)settingsVC:(SettingsViewController *)settingsVC didSelectProfile:(AgoraRtcVideoProfile)profile {
    self.videoProfile = profile;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)roomVCNeedClose:(RoomViewController *)roomVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self enterRoom:textField.text];
    return YES;
}
@end
