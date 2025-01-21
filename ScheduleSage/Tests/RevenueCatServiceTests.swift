import XCTest
@testable import ScheduleSage

class RevenueCatServiceTests: XCTestCase {
    
    var revenueCatService: RevenueCatService!
    
    override func setUp() {
        super.setUp()
        revenueCatService = RevenueCatService.shared
    }
    
    override func tearDown() {
        revenueCatService = nil
        super.tearDown()
    }
    
    func testPurchaseProductSuccess() {
        let expectation = self.expectation(description: "Purchase product success")
        
        revenueCatService.purchaseProduct(productIdentifier: "test_product") { result in
            switch result {
            case .success(let purchase):
                XCTAssertNotNil(purchase)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Purchase failed with error: \(error)")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testPurchaseProductFailure() {
        let expectation = self.expectation(description: "Purchase product failure")
        
        revenueCatService.purchaseProduct(productIdentifier: "invalid_product") { result in
            switch result {
            case .success:
                XCTFail("Purchase should have failed")
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRestorePurchasesSuccess() {
        let expectation = self.expectation(description: "Restore purchases success")
        
        revenueCatService.restorePurchases { result in
            switch result {
            case .success(let customerInfo):
                XCTAssertNotNil(customerInfo)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Restore purchases failed with error: \(error)")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRestorePurchasesFailure() {
        let expectation = self.expectation(description: "Restore purchases failure")
        
        revenueCatService.restorePurchases { result in
            switch result {
            case .success:
                XCTFail("Restore purchases should have failed")
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCheckSubscriptionStatusSuccess() {
        let expectation = self.expectation(description: "Check subscription status success")
        
        revenueCatService.checkSubscriptionStatus { result in
            switch result {
            case .success(let customerInfo):
                XCTAssertNotNil(customerInfo)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Check subscription status failed with error: \(error)")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCheckSubscriptionStatusFailure() {
        let expectation = self.expectation(description: "Check subscription status failure")
        
        revenueCatService.checkSubscriptionStatus { result in
            switch result {
            case .success:
                XCTFail("Check subscription status should have failed")
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
