//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "DataSource.h"
#import "TSAttachment.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

#endif

NS_ASSUME_NONNULL_BEGIN

@class AudioWaveform;
@class SSKProtoAttachmentPointer;
@class TSAttachmentPointer;

typedef void (^OWSThumbnailSuccess)(UIImage *image);
typedef void (^OWSThumbnailFailure)(void);

@interface TSAttachmentStream : TSAttachment

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithServerId:(UInt64)serverId
                   encryptionKey:(NSData *)encryptionKey
                       byteCount:(UInt32)byteCount
                     contentType:(NSString *)contentType
                  sourceFilename:(nullable NSString *)sourceFilename
                         caption:(nullable NSString *)caption
                  albumMessageId:(nullable NSString *)albumMessageId NS_UNAVAILABLE;

- (instancetype)initForRestoreWithUniqueId:(NSString *)uniqueId
                               contentType:(NSString *)contentType
                            sourceFilename:(nullable NSString *)sourceFilename
                                   caption:(nullable NSString *)caption
                            albumMessageId:(nullable NSString *)albumMessageId NS_UNAVAILABLE;

- (instancetype)initAttachmentWithContentType:(NSString *)contentType
                                    byteCount:(UInt32)byteCount
                               sourceFilename:(nullable NSString *)sourceFilename
                                      caption:(nullable NSString *)caption
                               albumMessageId:(nullable NSString *)albumMessageId NS_UNAVAILABLE;

- (instancetype)initWithContentType:(NSString *)contentType
                          byteCount:(UInt32)byteCount
                     sourceFilename:(nullable NSString *)sourceFilename
                            caption:(nullable NSString *)caption
                     albumMessageId:(nullable NSString *)albumMessageId
                    shouldAlwaysPad:(BOOL)shouldAlwaysPad NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPointer:(TSAttachmentPointer *)pointer
                    transaction:(SDSAnyReadTransaction *)transaction NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                  albumMessageId:(nullable NSString *)albumMessageId
         attachmentSchemaVersion:(NSUInteger)attachmentSchemaVersion
                  attachmentType:(TSAttachmentType)attachmentType
                       byteCount:(unsigned int)byteCount
                         caption:(nullable NSString *)caption
                     contentType:(NSString *)contentType
                   encryptionKey:(nullable NSData *)encryptionKey
                    isDownloaded:(BOOL)isDownloaded
                        serverId:(unsigned long long)serverId
                  sourceFilename:(nullable NSString *)sourceFilename
      cachedAudioDurationSeconds:(nullable NSNumber *)cachedAudioDurationSeconds
               cachedImageHeight:(nullable NSNumber *)cachedImageHeight
                cachedImageWidth:(nullable NSNumber *)cachedImageWidth
               creationTimestamp:(NSDate *)creationTimestamp
                          digest:(nullable NSData *)digest
                      isUploaded:(BOOL)isUploaded
              isValidImageCached:(nullable NSNumber *)isValidImageCached
              isValidVideoCached:(nullable NSNumber *)isValidVideoCached
           localRelativeFilePath:(nullable NSString *)localRelativeFilePath
                 shouldAlwaysPad:(BOOL)shouldAlwaysPad
NS_SWIFT_NAME(init(uniqueId:albumMessageId:attachmentSchemaVersion:attachmentType:byteCount:caption:contentType:encryptionKey:isDownloaded:serverId:sourceFilename:cachedAudioDurationSeconds:cachedImageHeight:cachedImageWidth:creationTimestamp:digest:isUploaded:isValidImageCached:isValidVideoCached:localRelativeFilePath:shouldAlwaysPad:));

// clang-format on

// --- CODE GENERATION MARKER

// Though now required, `digest` may be null for pre-existing records or from
// messages received from other clients
@property (nullable, nonatomic) NSData *digest;

// This only applies for attachments being uploaded.
@property (atomic) BOOL isUploaded;

@property (nonatomic, readonly) NSDate *creationTimestamp;

#if TARGET_OS_IPHONE
- (nullable NSData *)validStillImageData;
#endif

@property (nonatomic, readonly, nullable) UIImage *originalImage;
@property (nonatomic, readonly, nullable) NSString *originalFilePath;
@property (nonatomic, readonly, nullable) NSURL *originalMediaURL;

- (NSArray<NSString *> *)allSecondaryFilePaths;

+ (BOOL)hasThumbnailForMimeType:(NSString *)contentType;

- (nullable NSData *)readDataFromFileWithError:(NSError **)error;
- (BOOL)writeData:(NSData *)data error:(NSError **)error;

/// Copies the contents of the DataSource into the attachment stream's backing file.
- (BOOL)writeCopyingDataSource:(id<DataSource>)dataSource
                         error:(NSError **)error NS_SWIFT_NAME(writeCopyingDataSource(_:));

/// This method *moves* the file backing `dataSource`, rather than copying it's content. As such it's faster than
/// `writeCopyingDataSource`, but it must not be used if the DataSource is backed by a file which must exist *after*
/// this write.
- (BOOL)writeConsumingDataSource:(id<DataSource>)dataSource
                           error:(NSError **)error NS_SWIFT_NAME(writeConsumingDataSource(_:));

+ (void)deleteAttachments;

+ (NSString *)attachmentsFolder;
+ (NSString *)legacyAttachmentsDirPath;
+ (NSString *)sharedDataAttachmentsDirPath;

- (BOOL)shouldHaveImageSize;
- (CGSize)imageSize;

- (CGFloat)audioDurationSeconds;
- (nullable AudioWaveform *)audioWaveform;

+ (nullable NSError *)migrateToSharedData;

#pragma mark - Thumbnails

// On cache hit, the thumbnail will be returned synchronously and completion will never be invoked.
// On cache miss, nil will be returned and success will be invoked if thumbnail can be generated;
// otherwise failure will be invoked.
//
// success and failure are invoked async on main.
- (nullable UIImage *)thumbnailImageWithSizeHint:(CGSize)sizeHint
                                         success:(OWSThumbnailSuccess)success
                                         failure:(OWSThumbnailFailure)failure;
- (nullable UIImage *)thumbnailImageSmallWithSuccess:(OWSThumbnailSuccess)success failure:(OWSThumbnailFailure)failure;
- (nullable UIImage *)thumbnailImageMediumWithSuccess:(OWSThumbnailSuccess)success failure:(OWSThumbnailFailure)failure;
- (nullable UIImage *)thumbnailImageLargeWithSuccess:(OWSThumbnailSuccess)success failure:(OWSThumbnailFailure)failure;
- (nullable UIImage *)thumbnailImageSmallSync;

// This method should only be invoked by OWSThumbnailService.
- (NSString *)pathForThumbnailDimensionPoints:(NSUInteger)thumbnailDimensionPoints;

// When uploading, always apply adding to this attachment,
// regardless of feature flags.
@property (nonatomic, readonly) BOOL shouldAlwaysPad;

#pragma mark - Validation

@property (nonatomic, readonly) BOOL isValidImage;
@property (nonatomic, readonly) BOOL isValidVideo;
@property (nonatomic, readonly) BOOL isValidVisualMedia;

#pragma mark - Update With... Methods

- (void)updateAsUploadedWithEncryptionKey:(NSData *)encryptionKey
                                   digest:(NSData *)digest
                                 serverId:(UInt64)serverId
                              transaction:(SDSAnyWriteTransaction *)transaction;

- (nullable TSAttachmentStream *)cloneAsThumbnail;

#pragma mark - Protobuf

+ (nullable SSKProtoAttachmentPointer *)buildProtoForAttachmentId:(nullable NSString *)attachmentId
                                                      transaction:(SDSAnyReadTransaction *)transaction;

- (nullable SSKProtoAttachmentPointer *)buildProto;

@end

NS_ASSUME_NONNULL_END
