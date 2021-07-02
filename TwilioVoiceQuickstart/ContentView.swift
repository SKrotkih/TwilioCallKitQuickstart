//
//  ContentView.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 25.06.2021.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var appDelegate: AppDelegate
    
    @State private var isSpinning = false
    
    var body: some View {
        ZStack {
            
            if isSpinning {
                ProgressView()
                    .frame(width: 50.0, height: 50.0)
                    .progressViewStyle(CircularProgressViewStyle())
                    .animation(Animation.easeInOut(duration: 3))
                    .hidden(!isSpinning)
            } else {
                
            }
        VStack {
            Spacer()
            Group {
                Text(viewModel.qualityWarningsToaster.text)
                    .font(Font.system(size: 12).weight(.light))
                    .foregroundColor(.gray)
                    .opacity(viewModel.qualityWarningsToaster.opacity)
                    .padding(.top, 0.0)
                Spacer()
                Image("TwilioLogo")
                    .resizable(resizingMode: .stretch)
                    .frame(width: 240.0, height: 240.0)
                    .padding()
                Spacer()
                TextField("Phone Number",
                          text: $viewModel.outgoingValue,
                          onEditingChanged: { _ in
                           }, onCommit: {
                               hideKeyboard()
                           }
                )
                    .font(Font.system(size: 12).weight(.light))
                    .foregroundColor(.black)
                    .frame(width: 240.0)
                    .padding()
                Spacer()
                Text("Dial a client name or phone number. Leaving the field empty results in an automated response.")
                    .font(Font.system(size: 10).weight(.light))
                    .foregroundColor(Color(red:0.47, green:0.43, blue:0.40, opacity:1.00))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 240.0, height: 28.0)
                    .padding()
            }
            Spacer(minLength: 20.0)
            Group {
                Button(
                    action: {
                    viewModel.mainButtonPressed()
                },
                    label: {
                    Text(viewModel.placeCallButton.title)
                        .font(Font.system(size: 12).weight(.light))
                        .foregroundColor(.red)
                    }
                )
                    .disabled(!viewModel.placeCallButton.isEnabled)
                    .padding()
                Spacer()
                HStack {
                    Spacer(minLength: 25.0)
                    VStack(alignment: .center) {
                        Toggle(isOn: $viewModel.muteSwitchOn) {
                            Text("Mute")
                                .font(Font.system(size: 12).weight(.light))
                                .foregroundColor(.black)
                        }.hidden(viewModel.callControlViewisHidden)
                    }
                    Spacer(minLength: 25.0)
                    VStack(alignment: .center) {
                        Toggle(isOn: $viewModel.speackerSwitchOn) {
                            Text("Speacker")
                                .font(Font.system(size: 12).weight(.light))
                                .foregroundColor(.black)
                        }.hidden(viewModel.callControlViewisHidden)
                    }
                    Spacer(minLength: 25.0)
                }
            }
            Spacer()
        }.onAppear {
            appDelegate.pushKitEventDelegate = viewModel
            viewModel.spinner = Spinner(isSpinning: $isSpinning)
            viewModel.viewDidAppear()
        }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentViewModel())
    }
}
