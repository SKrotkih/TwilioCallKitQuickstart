//
//  ContentView.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 25.06.2021.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var model: ContentViewModel
    
    var body: some View {
        VStack{
            Text(model.qualityWarningsToaster.text)
                .font(Font.system(size: 12).weight(.light))
                .foregroundColor(.gray)
                .opacity(model.qualityWarningsToaster.opacity)
                .padding(.top, 0.0)
            Image("TwilioLogo")
                .resizable(resizingMode: .stretch)
                .frame(width: 240.0, height: 240.0)
                .padding()
            TextField("Phone Number",
                      text: $model.outgoingValue,
                      onEditingChanged: { _ in
                       }, onCommit: {
                           hideKeyboard()
                       }
            )
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
                action: model.placeCallButton.actionOnPressButton,
                label: {
                Text(model.placeCallButton.title)
                    .font(Font.system(size: 12).weight(.light))
                    .foregroundColor(.red)
                }
            )
                .disabled(!model.placeCallButton.isEnabled)
                .padding()
            HStack {
                Spacer(minLength: 25.0)
                VStack(alignment: .center) {
                    Toggle(isOn: $model.muteSwitchOn) {
                        Text("Mute")
                            .font(Font.system(size: 12).weight(.light))
                            .foregroundColor(.black)
                    }.hidden(model.callControlViewisHidden)
                }
                Spacer(minLength: 25.0)
                VStack(alignment: .center) {
                    Toggle(isOn: $model.speackerSwitchOn) {
                        Text("Speacker")
                            .font(Font.system(size: 12).weight(.light))
                            .foregroundColor(.black)
                    }.hidden(model.callControlViewisHidden)
                }
                Spacer(minLength: 25.0)
            }
        }.onAppear {
            model.viewDidAppear()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentViewModel())
    }
}
