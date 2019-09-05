//
//  ItemDetailAbstractView.swift
//  Zotero
//
//  Created by Michal Rentka on 28/08/2019.
//  Copyright © 2019 Corporation for Digital Scholarship. All rights reserved.
//

import SwiftUI

struct ItemDetailAbstractView: View {
    @Binding var abstract: String
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading) {
            ItemDetailFieldTitleView(title: "Abstract")
            if self.isEditing {
                TextField("Abstract", text: self.$abstract)
            } else {
                Text(self.abstract)
            }
        }
    }
}

#if DEBUG

struct ItemDetailAbstractView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailAbstractView(abstract: .constant("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Dolor sed viverra ipsum nunc aliquet bibendum enim. In massa tempor nec feugiat. Nunc aliquet bibendum enim facilisis gravida. Nisl nunc mi ipsum faucibus vitae aliquet nec ullamcorper. Amet luctus venenatis lectus magna fringilla. Volutpat maecenas volutpat blandit aliquam etiam erat velit scelerisque in. Egestas egestas fringilla phasellus faucibus scelerisque eleifend. Sagittis orci a scelerisque purus semper eget duis. Nulla pharetra diam sit amet nisl suscipit. Sed adipiscing diam donec adipiscing tristique risus nec feugiat in. Fusce ut placerat orci nulla. Pharetra vel turpis nunc eget lorem dolor. Tristique senectus et netus et malesuada."), isEditing: false)
    }
}

#endif
