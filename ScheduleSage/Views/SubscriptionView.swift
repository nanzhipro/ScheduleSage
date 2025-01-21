import SwiftUI

struct SubscriptionView: View {
    @ObservedObject var viewModel: SubscriptionViewModel

    var body: some View {
        VStack {
            if viewModel.isSubscribed {
                Text("You are subscribed!")
                    .font(.title)
                    .padding()
                Button(action: viewModel.restorePurchases) {
                    Text("Restore Purchases")
                }
                .padding()
            } else {
                Text("Subscribe to access premium features")
                    .font(.title)
                    .padding()
                Button(action: viewModel.purchaseSubscription) {
                    Text("Subscribe Now")
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.checkSubscriptionStatus()
        }
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView(viewModel: SubscriptionViewModel())
    }
}
