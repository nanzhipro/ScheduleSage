import XCTest
@testable import ScheduleSage

class SubscriptionViewModelTests: XCTestCase {

    var viewModel: SubscriptionViewModel!

    override func setUp() {
        super.setUp()
        viewModel = SubscriptionViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testPurchaseSubscriptionSuccess() {
        let expectation = self.expectation(description: "Purchase subscription success")

        viewModel.purchaseSubscription()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(self.viewModel.isSubscribed)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRestorePurchasesSuccess() {
        let expectation = self.expectation(description: "Restore purchases success")

        viewModel.restorePurchases()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(self.viewModel.isSubscribed)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCheckSubscriptionStatusSuccess() {
        let expectation = self.expectation(description: "Check subscription status success")

        viewModel.checkSubscriptionStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(self.viewModel.isSubscribed)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
