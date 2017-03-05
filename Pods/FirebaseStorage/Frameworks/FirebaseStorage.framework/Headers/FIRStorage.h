// clang-format off
/** @file FIRStorage.h
    @brief Firebase SDK
    @copyright Copyright 2016 Google Inc.
    @remarks Use of this SDK is subject to the Google APIs Terms of Service:
    https://developers.google.com/terms/
 */
// clang-format on

#import <Foundation/Foundation.h>

#import "FIRStorageConstants.h"

@class FIRApp;
@class FIRStorageReference;

NS_ASSUME_NONNULL_BEGIN

/** Project version string for FirebaseStorage. */
FOUNDATION_EXPORT const unsigned char *const FirebaseStorageVersionString;

/**
 * FirebaseStorage is a service that supports uploading and downloading binary objects,
 * such as images, videos, and other files to Google Cloud Storage.
 *
 * If you call [FIRStorage storage], the instance will initialize with the default FIRApp,
 * [FIRApp defaultApp], and the storage location will come from the provided
 * GoogleService-Info.plist.
 *
 * If you call [FIRStorage storageForApp:] and provide a custom instance of FIRApp,
 * the storage location will be specified via the FIROptions#storageBucket property.
 */
@interface FIRStorage : NSObject

/**
 * Creates an instance of FIRStorage, configured with the default FIRApp.
 * @return the FIRStorage instance, initialized with the default FIRApp.
 */
+ (instancetype)storage NS_SWIFT_NAME(storage());

/**
 * Creates an instance of FIRStorage, configured with the custom FIRApp @a app.
 * @param app The custom FIRApp used for initialization.
 * @return the FIRStorage instance, initialized with the custom FIRApp.
 */
+ (instancetype)storageForApp:(FIRApp *)app NS_SWIFT_NAME(storage(app:));

/**
 * Creates an instance of FIRStorage, configured with a custom storage bucket @a url.
 * @param url The gs:// url to your Firebase Storage Bucket.
 * @return the FIRStorage instance, initialized with the custom FIRApp.
 */
+ (instancetype)storageWithURL:(NSString *)url NS_SWIFT_NAME(storage(url:));

/**
 * Creates an instance of FIRStorage, configured with a custom FIRApp @a app and a custom storage
 * bucket @a url.
 * @param app The custom FIRApp used for initialization.
 * @param url The gs:// url to your Firebase Storage Bucket.
 * @return the FIRStorage instance, initialized with the custom FIRApp.
 */
+ (instancetype)storageForApp:(FIRApp *)app
                          URL:(NSString *)url NS_SWIFT_NAME(storage(app:url:));

/**
 * The Firebase App associated with this Firebase Storage instance.
 */
@property(strong, nonatomic, readonly) FIRApp *app;

/**
 * Maximum time in seconds to retry an upload if a failure occurs.
 * Defaults to 10 minutes (600 seconds).
 */
@property NSTimeInterval maxUploadRetryTime;

/**
 * Maximum time in seconds to retry a download if a failure occurs.
 * Defaults to 10 minutes (600 seconds).
 */
@property NSTimeInterval maxDownloadRetryTime;

/**
 * Maximum time in seconds to retry operations other than upload and download if a failure occurs.
 * Defaults to 2 minutes (120 seconds).
 */
@property NSTimeInterval maxOperationRetryTime;

/**
 * Queue that all developer callbacks are fired on. Defaults to the main queue.
 */
@property(strong, nonatomic) dispatch_queue_t callbackQueue;

/**
 * Creates a FIRStorageReference initialized at the root Firebase Storage location.
 * @return An instance of FIRStorageReference initialized at the root.
 */
- (FIRStorageReference *)reference;

/**
 * Creates a FIRStorageReference given a gs:// or https:// URL pointing to a Firebase Storage
 * location. For example, you can pass in an https:// download URL retrieved from
 * [FIRStorageReference downloadURLWithCompletion] or the gs:// URI from
 * [FIRStorageReference description].
 * @param string A gs:// or https:// URL to initialize the reference with.
 * @return An instance of FIRStorageReference at the given child path.
 * @throws Throws an exception if passed in URL is not associated with the FIRApp used to initialize
 * this FIRStorage.
 */
- (FIRStorageReference *)referenceForURL:(NSString *)string;

/**
 * Creates a FIRStorageReference initialized at a child Firebase Storage location.
 * @param string A relative path from the root to initialize the reference with,
 * for instance @"path/to/object".
 * @return An instance of FIRStorageReference at the given child path.
 */
- (FIRStorageReference *)referenceWithPath:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
