//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "ShowGroupMembersViewController.h"
#import "Signal-Swift.h"
#import "SignalApp.h"
#import "ViewControllerUtils.h"
#import <ContactsUI/ContactsUI.h>
#import <SignalMessaging/BlockListUIUtils.h>
#import <SignalMessaging/ContactTableViewCell.h>
#import <SignalMessaging/ContactsViewHelper.h>
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSContactsManager.h>
#import <SignalMessaging/UIUtil.h>
#import <SignalServiceKit/OWSBlockingManager.h>
#import <SignalServiceKit/SignalAccount.h>
#import <SignalServiceKit/TSGroupModel.h>
#import <SignalServiceKit/TSGroupThread.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShowGroupMembersViewController () <ContactsViewHelperDelegate, ContactEditingDelegate>

@property (nonatomic, readonly) TSGroupThread *thread;
@property (nonatomic, readonly) ContactsViewHelper *contactsViewHelper;

@property (nonatomic, nullable) NSSet<SignalServiceAddress *> *memberAddresses;

@end

#pragma mark -

@implementation ShowGroupMembersViewController

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    [self commonInit];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return self;
    }

    [self commonInit];

    return self;
}


- (void)commonInit
{
    _contactsViewHelper = [[ContactsViewHelper alloc] initWithDelegate:self];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;

    [self observeNotifications];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(identityStateDidChange:)
                                                 name:kNSNotificationName_IdentityStateDidChange
                                               object:nil];
}

- (void)configWithThread:(TSGroupThread *)thread
{

    _thread = thread;

    OWSAssertDebug(self.thread);
    OWSAssertDebug(self.thread.groupModel);
    OWSAssertDebug(self.thread.groupModel.groupMembers);

    self.memberAddresses = [NSSet setWithArray:self.thread.groupModel.groupMembers];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    OWSAssertDebug([self.navigationController isKindOfClass:[OWSNavigationController class]]);

    self.title = _thread.groupModel.groupName;

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 45;

    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSAssertDebug(self.thread);

    OWSTableContents *contents = [OWSTableContents new];

    __weak ShowGroupMembersViewController *weakSelf = self;
    ContactsViewHelper *helper = self.contactsViewHelper;

    OWSTableSection *membersSection = [OWSTableSection new];

    // Group Members

    // If there are "no longer verified" members of the group,
    // highlight them in a special section.
    NSArray<SignalServiceAddress *> *noLongerVerifiedRecipientAddresses = [self noLongerVerifiedRecipientAddresses];
    if (noLongerVerifiedRecipientAddresses.count > 0) {
        OWSTableSection *noLongerVerifiedSection = [OWSTableSection new];
        noLongerVerifiedSection.headerTitle = NSLocalizedString(@"GROUP_MEMBERS_SECTION_TITLE_NO_LONGER_VERIFIED",
            @"Title for the 'no longer verified' section of the 'group members' view.");
        membersSection.headerTitle = NSLocalizedString(
            @"GROUP_MEMBERS_SECTION_TITLE_MEMBERS", @"Title for the 'members' section of the 'group members' view.");
        [noLongerVerifiedSection
            addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"GROUP_MEMBERS_RESET_NO_LONGER_VERIFIED",
                                                             @"Label for the button that clears all verification "
                                                             @"errors in the 'group members' view.")
                                 accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"no_longer_verified")
                                         customRowHeight:UITableViewAutomaticDimension
                                             actionBlock:^{
                                                 [weakSelf offerResetAllNoLongerVerified];
                                             }]];
        [self addMembers:noLongerVerifiedRecipientAddresses toSection:noLongerVerifiedSection useVerifyAction:YES];
        [contents addSection:noLongerVerifiedSection];
    }

    NSMutableSet *memberAddresses = [self.memberAddresses mutableCopy];
    [memberAddresses removeObject:[helper localAddress]];
    [self addMembers:memberAddresses.allObjects toSection:membersSection useVerifyAction:NO];
    [contents addSection:membersSection];

    self.contents = contents;
}

- (void)addMembers:(NSArray<SignalServiceAddress *> *)addresses
          toSection:(OWSTableSection *)section
    useVerifyAction:(BOOL)useVerifyAction
{
    OWSAssertDebug(addresses);
    OWSAssertDebug(section);

    __weak ShowGroupMembersViewController *weakSelf = self;
    ContactsViewHelper *helper = self.contactsViewHelper;
    // Sort the group members using contacts manager.
    NSArray<SignalServiceAddress *> *sortedAddresses = [addresses
        sortedArrayUsingComparator:^NSComparisonResult(SignalServiceAddress *addressA, SignalServiceAddress *addressB) {
            SignalAccount *signalAccountA = [helper.contactsManager fetchOrBuildSignalAccountForAddress:addressA];
            SignalAccount *signalAccountB = [helper.contactsManager fetchOrBuildSignalAccountForAddress:addressB];
            return [helper.contactsManager compareSignalAccount:signalAccountA withSignalAccount:signalAccountB];
        }];
    for (SignalServiceAddress *address in sortedAddresses) {
        [section addItem:[OWSTableItem
                             itemWithCustomCellBlock:^{
                                 ContactTableViewCell *cell = [ContactTableViewCell new];
                                 OWSVerificationState verificationState =
                                     [[OWSIdentityManager sharedManager] verificationStateForAddress:address];
                                 BOOL isVerified = verificationState == OWSVerificationStateVerified;
                                 BOOL isNoLongerVerified = verificationState == OWSVerificationStateNoLongerVerified;
                                 BOOL isBlocked = [helper isSignalServiceAddressBlocked:address];
                                 if (isNoLongerVerified) {
                                     cell.accessoryMessage = NSLocalizedString(@"CONTACT_CELL_IS_NO_LONGER_VERIFIED",
                                         @"An indicator that a contact is no longer verified.");
                                 } else if (isBlocked) {
                                     cell.accessoryMessage = MessageStrings.conversationIsBlocked;
                                 }

                                 [cell configureWithRecipientAddress:address];

                                 if (isVerified) {
                                     [cell setAttributedSubtitle:cell.verifiedSubtitle];
                                 } else {
                                     [cell setAttributedSubtitle:nil];
                                 }

                                 NSString *cellName = [NSString stringWithFormat:@"user.%@", address.stringForDisplay];
                                 cell.accessibilityIdentifier
                                     = ACCESSIBILITY_IDENTIFIER_WITH_NAME(ShowGroupMembersViewController, cellName);

                                 return cell;
                             }
                             customRowHeight:UITableViewAutomaticDimension
                             actionBlock:^{
                                 if (useVerifyAction) {
                                     [weakSelf showSafetyNumberView:address];
                                 } else {
                                     [weakSelf didSelectAddress:address];
                                 }
                             }]];
    }
}

- (void)offerResetAllNoLongerVerified
{
    OWSAssertIsOnMainThread();

    UIAlertController *actionSheet = [UIAlertController
        alertControllerWithTitle:nil
                         message:NSLocalizedString(@"GROUP_MEMBERS_RESET_NO_LONGER_VERIFIED_ALERT_MESSAGE",
                                     @"Label for the 'reset all no-longer-verified group members' confirmation alert.")
                  preferredStyle:UIAlertControllerStyleAlert];

    __weak ShowGroupMembersViewController *weakSelf = self;
    UIAlertAction *verifyAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                         accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"ok")
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *_Nonnull action) {
                                                             [weakSelf resetAllNoLongerVerified];
                                                         }];
    [actionSheet addAction:verifyAction];
    [actionSheet addAction:[OWSAlerts cancelAction]];

    [self presentAlert:actionSheet];
}

- (void)resetAllNoLongerVerified
{
    OWSAssertIsOnMainThread();

    OWSIdentityManager *identityManger = [OWSIdentityManager sharedManager];
    NSArray<SignalServiceAddress *> *addresses = [self noLongerVerifiedRecipientAddresses];
    for (SignalServiceAddress *address in addresses) {
        OWSVerificationState verificationState = [identityManger verificationStateForAddress:address];
        if (verificationState == OWSVerificationStateNoLongerVerified) {
            NSData *identityKey = [identityManger identityKeyForAddress:address];
            if (identityKey.length < 1) {
                OWSFailDebug(@"Missing identity key for: %@", address);
                continue;
            }
            [identityManger setVerificationState:OWSVerificationStateDefault
                                     identityKey:identityKey
                                         address:address
                           isUserInitiatedChange:YES];
        }
    }

    [self updateTableContents];
}

// Returns a collection of the group members who are "no longer verified".
- (NSArray<SignalServiceAddress *> *)noLongerVerifiedRecipientAddresses
{
    NSMutableArray<SignalServiceAddress *> *result = [NSMutableArray new];
    for (SignalServiceAddress *address in self.thread.recipientAddresses) {
        if ([[OWSIdentityManager sharedManager] verificationStateForAddress:address]
            == OWSVerificationStateNoLongerVerified) {
            [result addObject:address];
        }
    }
    return [result copy];
}

- (void)didSelectAddress:(SignalServiceAddress *)address
{
    OWSAssertDebug(address.isValid);

    ContactsViewHelper *helper = self.contactsViewHelper;
    SignalAccount *_Nullable signalAccount = [helper fetchSignalAccountForAddress:address];

    UIAlertController *actionSheet =
        [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    if (self.contactsViewHelper.contactsManager.supportsContactEditing) {
        NSString *contactInfoTitle = signalAccount
            ? NSLocalizedString(@"GROUP_MEMBERS_VIEW_CONTACT_INFO", @"Button label for the 'show contact info' button")
            : NSLocalizedString(
                  @"GROUP_MEMBERS_ADD_CONTACT_INFO", @"Button label to add information to an unknown contact");
        [actionSheet
            addAction:[UIAlertAction actionWithTitle:contactInfoTitle
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"show_contact_info")
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *_Nonnull action) {
                                                 [self showContactInfoViewForAddress:address];
                                             }]];
    }

    BOOL isBlocked;
    if (signalAccount) {
        isBlocked = [helper isSignalServiceAddressBlocked:signalAccount.recipientAddress];
        if (isBlocked) {
            [actionSheet
                addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BLOCK_LIST_UNBLOCK_BUTTON",
                                                             @"Button label for the 'unblock' button")
                                 accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"unblock")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                     [BlockListUIUtils
                                                         showUnblockSignalAccountActionSheet:signalAccount
                                                                          fromViewController:self
                                                                             blockingManager:helper.blockingManager
                                                                             contactsManager:helper.contactsManager
                                                                             completionBlock:^(BOOL ignore) {
                                                                                 [self updateTableContents];
                                                                             }];
                                                 }]];
        } else {
            [actionSheet
                addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BLOCK_LIST_BLOCK_BUTTON",
                                                             @"Button label for the 'block' button")
                                 accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"block")
                                                   style:UIAlertActionStyleDestructive
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                     [BlockListUIUtils
                                                         showBlockSignalAccountActionSheet:signalAccount
                                                                        fromViewController:self
                                                                           blockingManager:helper.blockingManager
                                                                           contactsManager:helper.contactsManager
                                                                           completionBlock:^(BOOL ignore) {
                                                                               [self updateTableContents];
                                                                           }];
                                                 }]];
        }
    } else {
        isBlocked = [helper isSignalServiceAddressBlocked:address];
        if (isBlocked) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BLOCK_LIST_UNBLOCK_BUTTON",
                                                                      @"Button label for the 'unblock' button")
                                          accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"unblock")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                              [BlockListUIUtils
                                                                  showUnblockAddressActionSheet:address
                                                                             fromViewController:self
                                                                                blockingManager:helper.blockingManager
                                                                                contactsManager:helper.contactsManager
                                                                                completionBlock:^(BOOL ignore) {
                                                                                    [self updateTableContents];
                                                                                }];
                                                          }]];
        } else {
            [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BLOCK_LIST_BLOCK_BUTTON",
                                                                      @"Button label for the 'block' button")
                                          accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"block")
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                              [BlockListUIUtils
                                                                  showBlockAddressActionSheet:address
                                                                           fromViewController:self
                                                                              blockingManager:helper.blockingManager
                                                                              contactsManager:helper.contactsManager
                                                                              completionBlock:^(BOOL ignore) {
                                                                                  [self updateTableContents];
                                                                              }];
                                                          }]];
        }
    }

    if (!isBlocked) {
        [actionSheet
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"GROUP_MEMBERS_SEND_MESSAGE",
                                                         @"Button label for the 'send message to group member' button")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"send_message")
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *_Nonnull action) {
                                                 [self showConversationViewForAddress:address];
                                             }]];
        [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"GROUP_MEMBERS_CALL",
                                                                  @"Button label for the 'call group member' button")
                                      accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"call")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *_Nonnull action) {
                                                          [self callMember:address];
                                                      }]];
        [actionSheet
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"VERIFY_PRIVACY",
                                                         @"Label for button or row which allows users to verify the "
                                                         @"safety number of another user.")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"safety_numbers")
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *_Nonnull action) {
                                                 [self showSafetyNumberView:address];
                                             }]];
    }

    [actionSheet addAction:[OWSAlerts cancelAction]];

    [self presentAlert:actionSheet];
}

- (void)showContactInfoViewForAddress:(SignalServiceAddress *)address
{
    OWSAssertDebug(address.isValid);

    [self.contactsViewHelper presentContactViewControllerForAddress:address fromViewController:self editImmediately:NO];
}

- (void)showConversationViewForAddress:(SignalServiceAddress *)address
{
    OWSAssertDebug(address.isValid);

    [SignalApp.sharedApp presentConversationForAddress:address action:ConversationViewActionCompose animated:YES];
}

- (void)callMember:(SignalServiceAddress *)address
{
    [SignalApp.sharedApp presentConversationForAddress:address action:ConversationViewActionAudioCall animated:YES];
}

- (void)showSafetyNumberView:(SignalServiceAddress *)address
{
    OWSAssertDebug(address.isValid);

    [FingerprintViewController presentFromViewController:self address:address];
}

#pragma mark - ContactsViewHelperDelegate

- (void)contactsViewHelperDidUpdateContacts
{
    [self updateTableContents];
}

- (BOOL)shouldHideLocalNumber
{
    return YES;
}

#pragma mark - ContactEditingDelegate

- (void)didFinishEditingContact
{
    OWSLogDebug(@"");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CNContactViewControllerDelegate

- (void)contactViewController:(CNContactViewController *)viewController
       didCompleteWithContact:(nullable CNContact *)contact
{
    OWSLogDebug(@"done editing contact.");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notifications

- (void)identityStateDidChange:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    [self updateTableContents];
}

@end

NS_ASSUME_NONNULL_END
