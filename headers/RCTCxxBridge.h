@class NSMutableArray, NSMutableDictionary, NSString, NSThread, NSObject;

@interface RCTCxxBridge: NSObject {}

- (void)executeSourceCode:(id)arg1 sync:(bool)arg2;
- (void)_runAfterLoad:(id)arg1;
- (void)executeApplicationScript:(NSData *)script url:(NSURL *)url async:(BOOL)async;


@end