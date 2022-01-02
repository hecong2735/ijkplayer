//
//  MainView.swift
//  IJKMediaDemo
//
//  Created by 何聪 on 2021/12/13.
//  Copyright © 2021 bilibili. All rights reserved.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Hello, World!")
                    .font(.title)
                Button("test") {
                    
                }
                Text("test")
                
                Spacer()
            }
        
            
            Spacer()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
