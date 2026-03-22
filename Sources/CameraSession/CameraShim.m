#import "CameraShim.h"
#import <YourPackageName/YourPackageName-Swift.h>

static CameraSession *sharedSession;

void camera_start(void) {
    if (!sharedSession) {
        sharedSession = [[CameraSession alloc] initWithDelegateQueue:nil];
    }
    [sharedSession start];
}

void camera_stop(void) {
    [sharedSession stop];
}
