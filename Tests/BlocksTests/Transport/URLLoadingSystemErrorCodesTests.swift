import Foundation
import XCTest

final class URLLoadingSystemErrorCodesTests: XCTestCase {
    func testErrorCodes() {
        dump(NSURLErrorUnknown) // -1

        dump(NSURLErrorCancelled) // -999
        dump(NSURLErrorBadURL) // -1000
        dump(NSURLErrorTimedOut) // -1001
        dump(NSURLErrorUnsupportedURL) // -1002
        dump(NSURLErrorCannotFindHost) // -1003
        dump(NSURLErrorCannotConnectToHost) // -1004
        dump(NSURLErrorNetworkConnectionLost) // -1005
        dump(NSURLErrorDNSLookupFailed) // -1006
        dump(NSURLErrorHTTPTooManyRedirects) // -1007
        dump(NSURLErrorResourceUnavailable) // -1008
        dump(NSURLErrorNotConnectedToInternet) // -1009
        dump(NSURLErrorRedirectToNonExistentLocation) // -1010
        dump(NSURLErrorBadServerResponse) // -1011
        dump(NSURLErrorUserCancelledAuthentication) // -1012
        dump(NSURLErrorUserAuthenticationRequired) // -1013
        dump(NSURLErrorZeroByteResource) // -1014
        dump(NSURLErrorCannotDecodeRawData) // -1015
        dump(NSURLErrorCannotDecodeContentData) // -1016
        dump(NSURLErrorCannotParseResponse) // -1017
        dump(NSURLErrorAppTransportSecurityRequiresSecureConnection) // -1022
        dump(NSURLErrorFileDoesNotExist) // -1100
        dump(NSURLErrorFileIsDirectory) // -1101
        dump(NSURLErrorNoPermissionsToReadFile) // -1102
        dump(NSURLErrorDataLengthExceedsMaximum) // -1103

        // SSL Errors
        dump(NSURLErrorFileOutsideSafeArea) // -1104
        dump(NSURLErrorSecureConnectionFailed) // -1200
        dump(NSURLErrorServerCertificateHasBadDate) // -1201
        dump(NSURLErrorServerCertificateUntrusted) // -1202
        dump(NSURLErrorServerCertificateHasUnknownRoot) // -1203
        dump(NSURLErrorServerCertificateNotYetValid) // -1204
        dump(NSURLErrorClientCertificateRejected) // -1205
        dump(NSURLErrorClientCertificateRequired) // -1206
        dump(NSURLErrorCannotLoadFromNetwork) // -2000

        // Download and file I/O errors
        dump(NSURLErrorCannotCreateFile) // -3000
        dump(NSURLErrorCannotOpenFile) // -3001
        dump(NSURLErrorCannotCloseFile) // -3002
        dump(NSURLErrorCannotWriteToFile) // -3003
        dump(NSURLErrorCannotRemoveFile) // -3004
        dump(NSURLErrorCannotMoveFile) // -3005
        dump(NSURLErrorDownloadDecodingFailedMidStream) // -3006
        dump(NSURLErrorDownloadDecodingFailedToComplete) // -3007

        dump(NSURLErrorInternationalRoamingOff) // -1018
        dump(NSURLErrorCallIsActive) // -1019
        dump(NSURLErrorDataNotAllowed) // -1020
        dump(NSURLErrorRequestBodyStreamExhausted) // -1021

        dump(NSURLErrorBackgroundSessionRequiresSharedContainer) // -995
        dump(NSURLErrorBackgroundSessionInUseByAnotherProcess) // -996
        dump(NSURLErrorBackgroundSessionWasDisconnected) // -997
    }
}
