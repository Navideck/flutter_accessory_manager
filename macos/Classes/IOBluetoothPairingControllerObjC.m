//
//  IOBluetoothPairingControllerObjC.m
//  BT Classic
//
//  Created by Fotios Dimanidis on 13.10.24.
//

#import "IOBluetoothPairingControllerObjC.h"

@implementation IOBluetoothPairingControllerObjC

IOBluetoothPairingController *pairingController;

- (instancetype)init {
    self = [super init];
    if (self) {
        pairingController = [[IOBluetoothPairingController pairingController] init];
    }
    return self;
}

- (void)runModal {
    // [pairingController runModal] does not show any device results so we use performSelectorOnMainThread as a workaround.
    // In a native app [pairingController runModal] works as expected. In Flutter it only works before the Flutter window is rendered (e.g. on init).
    [pairingController performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
}

@end
