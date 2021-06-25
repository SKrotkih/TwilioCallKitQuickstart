//
//  ContentView.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 25.06.2021.
//

import SwiftUI

struct ContentView: View {
    
    @State var muteIsOn: Bool
    @State var speackerIsOn: Bool
    @State var outgoingNumber: String
    var call: () -> Void
    
    var body: some View {
        VStack{
            Text("Warnings Raised")
                .font(Font.system(size: 12).weight(.light))
                .foregroundColor(Color(red:0.47, green:0.43, blue:0.40, opacity:1.00))
                .offset(CGSize(width: 0, height: 0.0))
                .padding()
            Image("TwilioLogo")
                .resizable(resizingMode: .stretch)
                .frame(width: 240.0, height: 240.0)
                .padding()
            TextField("Phone Number", text: $outgoingNumber)
                .font(Font.system(size: 12).weight(.light))
                .foregroundColor(.black)
                .frame(width: 240.0)
                .padding()
            Text("Dial a client name or phone number. Leaving the field empty results in an automated response.")
                .font(Font.system(size: 10).weight(.light))
                .foregroundColor(Color(red:0.47, green:0.43, blue:0.40, opacity:1.00))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 240.0, height: 28.0)
            Button(
                action: call,
                label: {
                Text("Call")
                    .font(Font.system(size: 12).weight(.light))
                    .foregroundColor(.red)
                }
            )
            HStack {
                Spacer(minLength: 25.0)
                VStack(alignment: .center) {
                    Toggle(isOn: $muteIsOn) {
                        Text("")
                    }
                    Text("Mute")
                        .font(Font.system(size: 12).weight(.light))
                        .foregroundColor(.black)
                }
                Spacer(minLength: 25.0)
                VStack(alignment: .center) {
                    Toggle(isOn: $speackerIsOn) {
                        Text("")
                    }
                    Text("Speacker")
                        .font(Font.system(size: 12).weight(.light))
                        .foregroundColor(.black)
                }
                Spacer(minLength: 25.0)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(muteIsOn: false, speackerIsOn: true, outgoingNumber: "", call: {})
    }
}
