// Copyright © 2023 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct AccountHeaderViewRepresentable: UIViewRepresentable {
    typealias UIViewType = AccountHeaderView
    let viewModelClosure: () ->  ProfileViewModel
    
    func makeUIView(context: Context) -> AccountHeaderView {
        return AccountHeaderView(viewModel: viewModelClosure())
    }
    
    func updateUIView(_ uiView: AccountHeaderView, context: Context) {
        
    }
}

#if DEBUG
import PreviewViewModels

struct AccountHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountHeaderViewRepresentable(
                viewModelClosure: {ProfileViewModel.preview})
        }
    }
}
#endif
