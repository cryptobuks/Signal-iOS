//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSSyncManager.h"
#import "Environment.h"
#import "OWSContactsManager.h"
#import "OWSPreferences.h"
#import "OWSProfileManager.h"
#import "OWSReadReceiptManager.h"
#import <PromiseKit/AnyPromise.h>
#import <SignalCoreKit/Cryptography.h>
#import <SignalServiceKit/AppReadiness.h>
#import <SignalServiceKit/DataSource.h>
#import <SignalServiceKit/MIMETypeUtil.h>
#import <SignalServiceKit/OWSError.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/OWSSyncConfigurationMessage.h>
#import <SignalServiceKit/OWSSyncContactsMessage.h>
#import <SignalServiceKit/OWSSyncGroupsMessage.h>
#import <SignalServiceKit/SSKEnvironment.h>
#import <SignalServiceKit/SignalAccount.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>
#import <SignalServiceKit/TSAccountManager.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const kSyncManagerLastContactSyncKey = @"kTSStorageManagerOWSSyncManagerLastMessageKey";

@interface OWSSyncManager ()

@property (nonatomic) BOOL isRequestInFlight;

@end

#pragma mark -

@implementation OWSSyncManager

+ (SDSKeyValueStore *)keyValueStore
{
    return [[SDSKeyValueStore alloc] initWithCollection:@"kTSStorageManagerOWSSyncManagerCollection"];
}

#pragma mark -

+ (instancetype)shared {
    OWSAssertDebug(SSKEnvironment.shared.syncManager);

    return SSKEnvironment.shared.syncManager;
}

- (instancetype)initDefault {
    self = [super init];

    if (!self) {
        return self;
    }

    OWSSingletonAssert();

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signalAccountsDidChange:)
                                                 name:OWSContactsManagerSignalAccountsDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(profileKeyDidChange:)
                                                 name:kNSNotificationName_ProfileKeyDidChange
                                               object:nil];

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        if ([self.tsAccountManager isRegisteredAndReady]) {
            OWSAssertDebug(self.contactsManager.isSetup);

            // Flush any pending changes.
            //
            // sendSyncContactsMessageIfNecessary will skipIfRedundant,
            // so this won't yield redundant traffic.
            [self sendSyncContactsMessageIfNecessary];
        }
    }];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Dependencies

- (OWSContactsManager *)contactsManager {
    OWSAssertDebug(Environment.shared.contactsManager);

    return Environment.shared.contactsManager;
}

- (OWSIdentityManager *)identityManager {
    OWSAssertDebug(SSKEnvironment.shared.identityManager);

    return SSKEnvironment.shared.identityManager;
}

- (OWSMessageSender *)messageSender {
    OWSAssertDebug(SSKEnvironment.shared.messageSender);

    return SSKEnvironment.shared.messageSender;
}

- (MessageSenderJobQueue *)messageSenderJobQueue
{
    OWSAssertDebug(SSKEnvironment.shared.messageSenderJobQueue);

    return SSKEnvironment.shared.messageSenderJobQueue;
}

- (OWSProfileManager *)profileManager {
    OWSAssertDebug(SSKEnvironment.shared.profileManager);

    return SSKEnvironment.shared.profileManager;
}

- (TSAccountManager *)tsAccountManager
{
    return TSAccountManager.sharedInstance;
}

- (id<OWSTypingIndicators>)typingIndicators
{
    return SSKEnvironment.shared.typingIndicators;
}

- (SDSDatabaseStorage *)databaseStorage
{
    return SDSDatabaseStorage.shared;
}

#pragma mark - Notifications

- (void)signalAccountsDidChange:(id)notification {
    OWSAssertIsOnMainThread();

    [self sendSyncContactsMessageIfPossible];
}

- (void)profileKeyDidChange:(id)notification {
    OWSAssertIsOnMainThread();

    [self sendSyncContactsMessageIfPossible];
}

#pragma mark - Methods

- (void)sendSyncContactsMessageIfPossible {
    OWSAssertIsOnMainThread();

    if (!self.contactsManager.isSetup) {
        // Don't bother if the contacts manager hasn't finished setup.
        return;
    }

    if ([TSAccountManager sharedInstance].isRegisteredAndReady) {
        [self sendSyncContactsMessageIfNecessary];
    }
}

- (void)sendConfigurationSyncMessage {
    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        if (!self.tsAccountManager.isRegisteredAndReady) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendConfigurationSyncMessage_AppReady];
        });
    }];
}

- (void)sendConfigurationSyncMessage_AppReady {
    DDLogInfo(@"");

    if (![TSAccountManager sharedInstance].isRegisteredAndReady) {
        return;
    }

    BOOL areReadReceiptsEnabled = SSKEnvironment.shared.readReceiptManager.areReadReceiptsEnabled;
    BOOL showUnidentifiedDeliveryIndicators = Environment.shared.preferences.shouldShowUnidentifiedDeliveryIndicators;
    BOOL showTypingIndicators = self.typingIndicators.areTypingIndicatorsEnabled;

    [self.databaseStorage asyncWriteWithBlock:^(SDSAnyWriteTransaction *transaction) {
        TSThread *_Nullable thread = [TSAccountManager getOrCreateLocalThreadWithTransaction:transaction];
        if (thread == nil) {
            OWSFailDebug(@"Missing thread.");
            return;
        }

        BOOL sendLinkPreviews = [SSKPreferences areLinkPreviewsEnabledWithTransaction:transaction];

        OWSSyncConfigurationMessage *syncConfigurationMessage =
            [[OWSSyncConfigurationMessage alloc] initWithThread:thread
                                            readReceiptsEnabled:areReadReceiptsEnabled
                             showUnidentifiedDeliveryIndicators:showUnidentifiedDeliveryIndicators
                                           showTypingIndicators:showTypingIndicators
                                               sendLinkPreviews:sendLinkPreviews];

        [self.messageSenderJobQueue addMessage:syncConfigurationMessage.asPreparer transaction:transaction];
    }];
}

#pragma mark - Groups Sync

- (void)syncGroupsWithTransaction:(SDSAnyWriteTransaction *)transaction
{
    TSThread *_Nullable thread = [TSAccountManager getOrCreateLocalThreadWithTransaction:transaction];
    if (thread == nil) {
        OWSFailDebug(@"Missing thread.");
        return;
    }
    OWSSyncGroupsMessage *syncGroupsMessage = [[OWSSyncGroupsMessage alloc] initWithThread:thread];
    NSData *_Nullable syncData = [syncGroupsMessage buildPlainTextAttachmentDataWithTransaction:transaction];
    if (!syncData) {
        OWSFailDebug(@"Failed to serialize groups sync message.");
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        id<DataSource> dataSource = [DataSourcePath dataSourceWritingSyncMessageData:syncData error:&error];
        OWSAssertDebug(error == nil);
        [self.messageSenderJobQueue addMediaMessage:syncGroupsMessage
                                         dataSource:dataSource
                                        contentType:OWSMimeTypeApplicationOctetStream
                                     sourceFilename:nil
                                            caption:nil
                                     albumMessageId:nil
                              isTemporaryAttachment:YES];
    });
}

#pragma mark - Local Sync

- (AnyPromise *)syncLocalContact
{
    SignalAccount *signalAccount =
        [[SignalAccount alloc] initWithSignalServiceAddress:self.tsAccountManager.localAddress];
    signalAccount.contact = [Contact new];

    return [self syncContactsForSignalAccounts:@[ signalAccount ] skipIfRedundant:NO debounce:NO];
}

#pragma mark - Contacts Sync

- (AnyPromise *)syncAllContacts
{
    return [self syncContactsForSignalAccounts:self.contactsManager.signalAccounts skipIfRedundant:NO debounce:NO];
}

- (AnyPromise *)syncContactsForSignalAccounts:(NSArray<SignalAccount *> *)signalAccounts
{
    return [self syncContactsForSignalAccounts:signalAccounts skipIfRedundant:NO debounce:NO];
}

- (void)sendSyncContactsMessageIfNecessary
{
    [[self syncContactsForSignalAccounts:self.contactsManager.signalAccounts skipIfRedundant:YES debounce:YES]
        retainUntilComplete];
}

- (dispatch_queue_t)serialQueue
{
    static dispatch_queue_t _serialQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _serialQueue = dispatch_queue_create("org.whispersystems.contacts.syncing", DISPATCH_QUEUE_SERIAL);
    });

    return _serialQueue;
}

// skipIfRedundant: Don't bother sending sync messages with the same data as the
//                  last successfully sent contact sync message.
// debounce: Only have one sync message in flight at a time.
- (AnyPromise *)syncContactsForSignalAccounts:(NSArray<SignalAccount *> *)signalAccounts
                              skipIfRedundant:(BOOL)skipIfRedundant
                                     debounce:(BOOL)debounce
{
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [AppReadiness runNowOrWhenAppDidBecomeReady:^{
            dispatch_async(self.serialQueue, ^{
                if (debounce && self.isRequestInFlight) {
                    // De-bounce.  It's okay if we ignore some new changes;
                    // `sendSyncContactsMessageIfPossible` is called fairly
                    // often so we'll sync soon.
                    return resolve(@(1));
                }
                
                TSThread *_Nullable thread = [TSAccountManager getOrCreateLocalThreadWithSneakyTransaction];
                if (thread == nil) {
                    OWSFailDebug(@"Missing thread.");
                    NSError *error
                    = OWSErrorWithCodeDescription(OWSErrorCodeContactSyncFailed, @"Could not sync contacts.");
                    return resolve(error);
                }
                
                OWSSyncContactsMessage *syncContactsMessage =
                [[OWSSyncContactsMessage alloc] initWithThread:thread
                                                signalAccounts:signalAccounts
                                               identityManager:self.identityManager
                                                profileManager:self.profileManager];
                __block NSData *_Nullable messageData;
                __block NSData *_Nullable lastMessageHash;
                [self.databaseStorage readWithBlock:^(SDSAnyReadTransaction *transaction) {
                    messageData = [syncContactsMessage buildPlainTextAttachmentDataWithTransaction:transaction];
                    lastMessageHash =
                    [OWSSyncManager.keyValueStore getData:kSyncManagerLastContactSyncKey transaction:transaction];
                }];

                if (!messageData) {
                    OWSFailDebug(@"Failed to serialize contacts sync message.");
                    NSError *error
                    = OWSErrorWithCodeDescription(OWSErrorCodeContactSyncFailed, @"Could not sync contacts.");
                    return resolve(error);
                }
                
                NSData *_Nullable messageHash = [self hashForMessageData:messageData];
                if (skipIfRedundant && messageHash != nil && lastMessageHash != nil &&
                    [lastMessageHash isEqual:messageHash]) {
                    // Ignore redundant contacts sync message.
                    return resolve(@(1));
                }
                
                if (debounce) {
                    self.isRequestInFlight = YES;
                }

                // DURABLE CLEANUP - we could replace the custom durability logic in this class
                // with a durable JobQueue.
                NSError *writeError;
                id<DataSource> dataSource = [DataSourcePath dataSourceWritingSyncMessageData:messageData
                                                                                       error:&writeError];
                if (writeError != nil) {
                    resolve(writeError);
                    return;
                }

                [self.messageSender sendTemporaryAttachment:dataSource
                                                contentType:OWSMimeTypeApplicationOctetStream
                                                  inMessage:syncContactsMessage
                                                    success:^{
                                                        OWSLogInfo(@"Successfully sent contacts sync message.");
                                                        
                                                        if (messageHash != nil) {
                                                            [self.databaseStorage writeWithBlock:^(SDSAnyWriteTransaction *transaction) {
                                                                [OWSSyncManager.keyValueStore setData:messageHash
                                                                                                  key:kSyncManagerLastContactSyncKey
                                                                                          transaction:transaction];
                                                            }];
                                                        }
                                                        
                                                        dispatch_async(self.serialQueue, ^{
                                                            if (debounce) {
                                                                self.isRequestInFlight = NO;
                                                            }
                                                            
                                                            resolve(@(1));
                                                        });
                                                    }
                                                    failure:^(NSError *error) {
                                                        OWSLogError(@"Failed to send contacts sync message with error: %@", error);
                                                        
                                                        dispatch_async(self.serialQueue, ^{
                                                            if (debounce) {
                                                                self.isRequestInFlight = NO;
                                                            }
                                                            
                                                            resolve(error);
                                                        });
                                                    }];
            });
        }];
    }];
    return promise;
}

- (nullable NSData *)hashForMessageData:(NSData *)messageData
{
    NSData *_Nullable result = [Cryptography computeSHA256Digest:messageData];
    OWSAssertDebug(result != nil);
    return result;
}

@end

NS_ASSUME_NONNULL_END
