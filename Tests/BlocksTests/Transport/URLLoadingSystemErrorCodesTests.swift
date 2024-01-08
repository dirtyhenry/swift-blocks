import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest

final class URLLoadingSystemErrorCodesTests: XCTestCase {
    func testErrorCodes() {
        XCTAssertEqual(NSURLErrorUnknown, -1)

        XCTAssertEqual(NSURLErrorCancelled, -999)
        XCTAssertEqual(NSURLErrorBadURL, -1000)
        XCTAssertEqual(NSURLErrorTimedOut, -1001)
        XCTAssertEqual(NSURLErrorUnsupportedURL, -1002)
        XCTAssertEqual(NSURLErrorCannotFindHost, -1003)
        XCTAssertEqual(NSURLErrorCannotConnectToHost, -1004)
        XCTAssertEqual(NSURLErrorNetworkConnectionLost, -1005)
        XCTAssertEqual(NSURLErrorDNSLookupFailed, -1006)
        XCTAssertEqual(NSURLErrorHTTPTooManyRedirects, -1007)
        XCTAssertEqual(NSURLErrorResourceUnavailable, -1008)
        XCTAssertEqual(NSURLErrorNotConnectedToInternet, -1009)
        XCTAssertEqual(NSURLErrorRedirectToNonExistentLocation, -1010)
        XCTAssertEqual(NSURLErrorBadServerResponse, -1011)
        XCTAssertEqual(NSURLErrorUserCancelledAuthentication, -1012)
        XCTAssertEqual(NSURLErrorUserAuthenticationRequired, -1013)
        XCTAssertEqual(NSURLErrorZeroByteResource, -1014)
        XCTAssertEqual(NSURLErrorCannotDecodeRawData, -1015)
        XCTAssertEqual(NSURLErrorCannotDecodeContentData, -1016)
        XCTAssertEqual(NSURLErrorCannotParseResponse, -1017)
        XCTAssertEqual(NSURLErrorAppTransportSecurityRequiresSecureConnection, -1022)
        XCTAssertEqual(NSURLErrorFileDoesNotExist, -1100)
        XCTAssertEqual(NSURLErrorFileIsDirectory, -1101)
        XCTAssertEqual(NSURLErrorNoPermissionsToReadFile, -1102)
        XCTAssertEqual(NSURLErrorDataLengthExceedsMaximum, -1103)

        // SSL Errors
        #if os(Linux)
        // cannot find 'NSURLErrorFileOutsideSafeArea' in scope 🤷‍♂️
        #else
        XCTAssertEqual(NSURLErrorFileOutsideSafeArea, -1104)
        #endif
        XCTAssertEqual(NSURLErrorSecureConnectionFailed, -1200)
        XCTAssertEqual(NSURLErrorServerCertificateHasBadDate, -1201)
        XCTAssertEqual(NSURLErrorServerCertificateUntrusted, -1202)
        XCTAssertEqual(NSURLErrorServerCertificateHasUnknownRoot, -1203)
        XCTAssertEqual(NSURLErrorServerCertificateNotYetValid, -1204)
        XCTAssertEqual(NSURLErrorClientCertificateRejected, -1205)
        XCTAssertEqual(NSURLErrorClientCertificateRequired, -1206)
        XCTAssertEqual(NSURLErrorCannotLoadFromNetwork, -2000)

        // Download and file I/O errors
        XCTAssertEqual(NSURLErrorCannotCreateFile, -3000)
        XCTAssertEqual(NSURLErrorCannotOpenFile, -3001)
        XCTAssertEqual(NSURLErrorCannotCloseFile, -3002)
        XCTAssertEqual(NSURLErrorCannotWriteToFile, -3003)
        XCTAssertEqual(NSURLErrorCannotRemoveFile, -3004)
        XCTAssertEqual(NSURLErrorCannotMoveFile, -3005)
        XCTAssertEqual(NSURLErrorDownloadDecodingFailedMidStream, -3006)
        XCTAssertEqual(NSURLErrorDownloadDecodingFailedToComplete, -3007)

        XCTAssertEqual(NSURLErrorInternationalRoamingOff, -1018)
        XCTAssertEqual(NSURLErrorCallIsActive, -1019)
        XCTAssertEqual(NSURLErrorDataNotAllowed, -1020)
        XCTAssertEqual(NSURLErrorRequestBodyStreamExhausted, -1021)

        XCTAssertEqual(NSURLErrorBackgroundSessionRequiresSharedContainer, -995)
        XCTAssertEqual(NSURLErrorBackgroundSessionInUseByAnotherProcess, -996)
        XCTAssertEqual(NSURLErrorBackgroundSessionWasDisconnected, -997)
    }
}
