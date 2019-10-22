//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "KnownStickerPack.h"

NS_ASSUME_NONNULL_BEGIN

@implementation KnownStickerPack

- (instancetype)initWithInfo:(StickerPackInfo *)info
{
    OWSAssertDebug(info.packId.length > 0);
    OWSAssertDebug(info.packKey.length > 0);

    self = [super initWithUniqueId:[KnownStickerPack uniqueIdForStickerPackInfo:info]];

    if (!self) {
        return self;
    }

    _info = info;
    _dateCreated = [NSDate new];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }

    if (_dateCreated == nil) {
        _dateCreated = [NSDate new];
    }

    return self;
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                     dateCreated:(NSDate *)dateCreated
                            info:(StickerPackInfo *)info
                  referenceCount:(NSInteger)referenceCount
{
    self = [super initWithUniqueId:uniqueId];

    if (!self) {
        return self;
    }

    _dateCreated = dateCreated;
    _info = info;
    _referenceCount = referenceCount;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

+ (NSString *)uniqueIdForStickerPackInfo:(StickerPackInfo *)info
{
    return info.asKey;
}

@end

NS_ASSUME_NONNULL_END
