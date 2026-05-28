#import "TDFileManagerViewController.h"
#import "TDUtils.h"
#import "LSApplicationProxy+AltList.h"
#import <objc/runtime.h>

@implementation TDFileManagerViewController

- (void)loadView {
    [super loadView];

    self.title = @"Decrypted IPAs";
    self.fileList = decryptedFileList();

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
}

- (void)refresh {
    self.fileList = decryptedFileList();
    [self.tableView reloadData];
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSelectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fileList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"FileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    NSString *path = [docPath() stringByAppendingPathComponent:self.fileList[indexPath.row]];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSDate *date = attributes[NSFileModificationDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, yyyy h:mm a"];

    NSNumber *fileSize = attributes[NSFileSize];


    cell.textLabel.text = self.fileList[indexPath.row];
    cell.detailTextLabel.text = [dateFormatter stringFromDate:date];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.imageView.image = [UIImage systemImageNamed:@"doc.fill"];

    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"%.2f MB", [fileSize doubleValue] / 1000000.0f];
    label.textColor = [UIColor grayColor];
    label.font = [UIFont systemFontOfSize:12.0f];
    [label sizeToFit];
    label.textAlignment = NSTextAlignmentCenter;
    cell.accessoryView = label;


    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65.0f;
}

- (bool)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#if !TARGET_OS_TV
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        NSString *file = self.fileList[indexPath.row];
        NSString *path = [docPath() stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        [self refresh];
    }];

    UISwipeActionsConfiguration *swipeActions = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    return swipeActions;
}
#endif

UIWindow *kw2 = NULL;
UIAlertController *doneController2 = NULL;

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *file = self.fileList[indexPath.row];
    NSString *path = [docPath() stringByAppendingPathComponent:file];

    doneController2 = [UIAlertController alertControllerWithTitle:file message:[NSString stringWithFormat:@"Location:\n%@", path] preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [kw2 removeFromSuperview];
        kw2.hidden = YES;
    }];
    [doneController2 addAction:okAction];

    UIAlertAction *openAction = [UIAlertAction actionWithTitle:@"Share IPA with Airdrop" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *filePath = path;
        NSURL *url = [NSURL fileURLWithPath:filePath];

        NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Sharing.framework"];
        [bundle load];

        NSBundle *sharingUI = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SharingUI.framework"];
        [sharingUI load];

        id sharingView = [[objc_getClass("SFAirDropSharingViewControllerTV") alloc] initWithSharingItems:@[url]];
        [self dismissViewControllerAnimated:NO completion:^{
            [self presentViewController:sharingView animated:YES completion:nil];
            [sharingView setCompletionHandler:^(NSError *error) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }];

        [self presentViewController:sharingView animated:true completion:nil];
    }];
    [doneController2 addAction:openAction];

    UIAlertAction *deleteFileAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        [self refresh];
        [kw2 removeFromSuperview];
        kw2.hidden = YES;
    }];
    [doneController2 addAction:deleteFileAction];

    [self presentViewController:doneController2 animated:YES completion:nil];
}

@end