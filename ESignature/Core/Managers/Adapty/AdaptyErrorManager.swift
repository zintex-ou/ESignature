import Foundation
import Adapty

struct AdaptyErrorManager {
    
    var error: PurchaisesError?
    var adaptyErrorCode: AdaptyError.ErrorCode = .unknown
    
    init(error: Error) {
        self.error = getErrorText(error: error)
        adaptyErrorCode = errorCode(error: error)
    }
    
    private func errorCode(error: Error) -> AdaptyError.ErrorCode {
        guard let adaptyError = error as? AdaptyError else {
            return .unknown
        }
        return adaptyError.adaptyErrorCode
    }
    
    private func getErrorText(error: Error) -> PurchaisesError {
        guard let adaptyError = error as? AdaptyError else {
            return .raw(title: R.string.localizable.error(), subTitle: "An unexpected error occurred.")
        }
        
        switch adaptyError.adaptyErrorCode {
        case .unknown:
            return .raw(
                title: R.string.localizable.error(),
                subTitle: R.string.localizable.anUnexpectedErrorOccurred()
            )
        case .clientInvalid:
            return .raw(
                title: R.string.localizable.error(),
                subTitle: R.string.localizable.youAreNotAllowedToPerformThisAction()
            )
            
        case .paymentCancelled:
            return .raw(
                title: R.string.localizable.paymentCancelled(),
                subTitle: R.string.localizable.yourPaymentRequestWasCanceled()
            )
            
        case .paymentInvalid:
            return .raw(
                title: R.string.localizable.paymentInvalid(),
                subTitle: R.string.localizable.oneOfThePaymentDetailsWasNotRecognized()
            )
            
        case .paymentNotAllowed:
            return .raw(
                title: R.string.localizable.paymentNotAllowed(),
                subTitle: R.string.localizable.youAreNotAuthorizedToMakePayments()
            )
            
        case .storeProductNotAvailable:
            return .raw(
                title: R.string.localizable.productNotAvailable(),
                subTitle: R.string.localizable.theItemYouRequestedIsNotAvailableInTheStore()
            )
            
        case .cloudServicePermissionDenied:
            return .raw(
                title: R.string.localizable.permissionDenied(),
                subTitle: R.string.localizable.youHaventAllowedAccessToCloudServiceInformation()
            )
            
        case .cloudServiceNetworkConnectionFailed:
            return .raw(
                title: R.string.localizable.badConnection(),
                subTitle: R.string.localizable.pleaseTurnOnTheInternet()
            )
            
        case .cloudServiceRevoked:
            return .raw(
                title: R.string.localizable.cloudServiceRevoked(),
                subTitle: R.string.localizable.permissionToUseThisCloudServiceHasBeenRevoked()
            )
            
        case .privacyAcknowledgementRequired:
            return .raw(
                title: R.string.localizable.privacyAcknowledgementRequired(),
                subTitle: R.string.localizable.youNeedToAcknowledgeApplesPrivacyPolicyForAppleMusic()
            )
            
        case .unauthorizedRequestData:
            return .raw(
                title: R.string.localizable.unauthorizedRequestData(),
                subTitle: R.string.localizable.theAppIsAttemptingToUseUnauthorizedData()
            )
            
        case .invalidOfferIdentifier:
            return .raw(
                title: R.string.localizable.invalidOfferIdentifier(),
                subTitle: R.string.localizable.theOfferIdentifierIsInvalid()
            )
            
        case .invalidSignature:
            return .raw(
                title: R.string.localizable.invalidSignature(),
                subTitle: R.string.localizable.theSignatureInAPaymentDiscountIsNotValid()
            )
            
        case .missingOfferParams:
            return .raw(
                title: R.string.localizable.missingOfferParams(),
                subTitle: R.string.localizable.someParametersAreMissingInAPaymentDiscount()
            )
            
        case .invalidOfferPrice:
            return .raw(
                title: R.string.localizable.invalidOfferPrice(),
                subTitle: R.string.localizable.thePriceSpecifiedInAppStoreConnectIsNoLongerValid()
            )
            
        case .noProductIDsFound:
            return .raw(
                title: R.string.localizable.noProductIdsFound(),
                subTitle: R.string.localizable.noInappPurchaseProductIdentifiersWereFound()
            )
            
        case .productRequestFailed:
            return .raw(
                title: R.string.localizable.productRequestFailed(),
                subTitle: R.string.localizable.unableToFetchAvailableInappPurchaseProductsAtTheMoment()
            )
            
        case .cantMakePayments:
            return .raw(
                title: R.string.localizable.cantMakePayments(),
                subTitle: R.string.localizable.inappPurchasesAreNotAllowedOnThisDevice()
            )
            
        case .cantReadReceipt:
            return .raw(
                title: R.string.localizable.cantReadReceipt(),
                subTitle: R.string.localizable.cantFindAValidReceipt()
            )
            
        case .productPurchaseFailed:
            return .raw(
                title: R.string.localizable.productPurchaseFailed(),
                subTitle: R.string.localizable.productPurchaseFailed()
            )
            
        case .refreshReceiptFailed:
            return .raw(
                title: R.string.localizable.refreshReceiptFailed(),
                subTitle: R.string.localizable.refreshReceiptFailed()
            )
            
        case .notActivated:
            return .raw(title: R.string.localizable.notActivated(), subTitle: R.string.localizable.youNeedToBeAuthenticatedToPerformRequests())
        case .badRequest:
            return .raw(title: R.string.localizable.badRequest(), subTitle: R.string.localizable.theRequestMadeIsNotValid())
        case .serverError:
            return .raw(title: R.string.localizable.badConnection(), subTitle: R.string.localizable.pleaseTurnOnTheInternet())
        case .networkFailed:
            return .raw(title: R.string.localizable.badConnection(), subTitle: R.string.localizable.pleaseTurnOnTheInternet())
        case .decodingFailed:
            return .raw(title: R.string.localizable.decodingFailed(), subTitle: R.string.localizable.unableToUnderstandTheResponseReceived())
        case .encodingFailed:
            return .raw(title: R.string.localizable.encodingFailed(), subTitle: R.string.localizable.failedToEncodeParametersForTheRequest())
        case .analyticsDisabled:
            return .raw(title: R.string.localizable.analyticsDisabled(), subTitle: R.string.localizable.weCanTHandleAnalyticsEventsSinceYouVeOptedOut())
        case .wrongParam:
            return .raw(title: R.string.localizable.wrongParam(), subTitle: R.string.localizable.anIncorrectParameterWasPassed())
        case .activateOnceError:
            return .raw(title: R.string.localizable.activateOnceError(), subTitle: R.string.localizable.itIsNotPossibleToCallTheActivateMethodMoreThanOnce())
        case .profileWasChanged:
            return .raw(title: R.string.localizable.profileWasChanged(), subTitle: R.string.localizable.theUserProfileWasChangedDuringTheOperation())
        case .unsupportedData:
            return .raw(title: R.string.localizable.unsupportedData(), subTitle: R.string.localizable.unsupportedData())
        case .fetchTimeoutError:
            return .raw(title: R.string.localizable.fetchTimeoutError(), subTitle: R.string.localizable.fetchTimeoutError())
        case .operationInterrupted:
            return .raw(title: R.string.localizable.operationInterrupted(), subTitle: R.string.localizable.thisOperationWasInterruptedByTheSystem())
        case .fetchSubscriptionStatusFailed:
            return .raw(title: R.string.localizable.fetchSubscriptionStatus(), subTitle: R.string.localizable.statusError())
        }
    }
}
