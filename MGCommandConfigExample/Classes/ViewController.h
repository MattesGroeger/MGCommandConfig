#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic) IBOutlet UITextView *scriptField;
@property (nonatomic) IBOutlet UIButton *startButton;
@property (nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic) IBOutlet UITextView *outputField;

- (void)addOutput:(NSString *)output;

- (void)clearOutput;

@end
