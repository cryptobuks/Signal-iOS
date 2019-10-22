//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (normalizeImage)

- (UIImage *)normalizedImage;
- (UIImage *)resizedWithQuality:(CGInterpolationQuality)quality rate:(CGFloat)rate;

- (nullable UIImage *)resizedWithMaxDimensionPoints:(CGFloat)maxDimensionPoints;
- (nullable UIImage *)resizedImageToSize:(CGSize)dstSize;
- (UIImage *)resizedImageToFillPixelSize:(CGSize)boundingSize;

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

- (size_t)pixelWidth;
- (size_t)pixelHeight;
- (CGSize)pixelSize;

@end

NS_ASSUME_NONNULL_END
