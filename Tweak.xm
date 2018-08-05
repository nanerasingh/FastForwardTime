@interface SBUILegibilityLabel : UIView
@property (nonatomic,copy) NSString *string;
@property (nonatomic,retain) UIFont *font;
-(void)setNumberOfLines:(long long)arg1;
-(void)setString:(NSString *)arg1;
-(void)setFrame:(CGRect)arg1;
@end

@interface SBFLockScreenDateView : UIView
-(float)expectedLabelWidth:(SBUILegibilityLabel *)label;
-(void)updateSeconds;
@end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
-(BOOL)isUILocked;
@end

static NSTimer *secondsTimer = nil;

%hook SBFLockScreenDateView

/* iOS 10 - 11.3.1 for now */
-(void)layoutSubviews {
    [self updateSeconds];
    if (secondsTimer == nil && ![secondsTimer isValid]) {
        // Run once and then start the timer
        secondsTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSeconds) userInfo:nil repeats:YES];
    }
    %orig;
}

%new
-(void)updateSeconds {
	// Check if phone unlocked and secondsTimer isnt nil/isValid, if so, invalidate and set to nil
	if (![[%c(SBLockScreenManager) sharedInstance] isUILocked] && secondsTimer != nil && [secondsTimer isValid]) {
		[secondsTimer invalidate];
		secondsTimer = nil;
	}

	// Hook the time label
	SBUILegibilityLabel *timeLabel = MSHookIvar<SBUILegibilityLabel *>(self, "_timeLabel");

	// Extra check just to be sure
	if (timeLabel != nil) {
		// Set the date formatter to hour:minute:second (like stock just extra second)
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"HH:mm:ss"];

		// Get NSString from date and format it using dateFormater then set the time label
		NSString *currentTimeString = [dateFormatter stringFromDate:[NSDate date]];
		[timeLabel setString:currentTimeString];

		// To make space for the seconds
		[timeLabel setFrame:CGRectMake(timeLabel.frame.origin.x, timeLabel.frame.origin.y, [self expectedLabelWidth:timeLabel], timeLabel.frame.size.height)];
	}
}

%new
// calculate needed width
-(float)expectedLabelWidth:(SBUILegibilityLabel *)label {
    [label setNumberOfLines:1];
    CGSize expectedLabelSize = [[label string] sizeWithAttributes:@{NSFontAttributeName:label.font}];
    return expectedLabelSize.width + 2; // just added a tiny bit extra just in case otherwise sometimes it would just be ".."
}


%end
