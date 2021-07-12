//
//  ContentView.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 25.06.2021.
//

import SwiftUI

struct ContentView: View {
    
    // TODO: Use protocol ContentPresentable for the viewModel
    @EnvironmentObject var viewModel: ContentViewModel {
        didSet {
            viewModel.spinner = Spinner(isSpinning: $isSpinning)
            viewModel.placeCallButton = PlaceCallButton(title: $callButtonTitle, isEnabled: $isCallButtonEnabled)
            viewModel.toaster = QualityWarningsToaster(text: $toasterTitle, isHidden: $toasterHidden)
            viewModel.callControls = CallControls(isHidden: $callControlViewisHidden)
        }
    }
    @EnvironmentObject var appDelegate: AppDelegate
    
    @State private var isSpinning = false
    @State private var callButtonTitle = "Call"
    @State private var isCallButtonEnabled = false
    @State private var toasterTitle = ""
    @State private var toasterHidden = true
    @State private var muteSwitchOn = false
    @State private var speackerSwitchOn = true
    @State private var callControlViewisHidden = true
    
    @ObservedObject private var keyboardObserver = KeyboardObserver.shared
    
    init() {
    }
    
    var body: some View {
        ZStack {
            ProgressView()
                .frame(width: 50.0, height: 50.0)
                .progressViewStyle(CircularProgressViewStyle())
                .animation(Animation.easeInOut(duration: 3))
                .hidden(!isSpinning)
            VStack {
                Spacer()
                Group {
                    Text(toasterTitle)
                        .font(Font.system(size: 12).weight(.light))
                        .foregroundColor(.gray)
                        .hidden(toasterHidden)
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
                        Text(callButtonTitle)
                            .font(Font.system(size: 12).weight(.light))
                            .foregroundColor(.red)
                    }
                    )
                        .disabled(!isCallButtonEnabled)
                        .padding()
                    Spacer()
                    HStack {
                        Spacer(minLength: 25.0)
                        VStack(alignment: .center) {
                            Toggle(isOn: $muteSwitchOn) {
                                Text("Mute")
                                    .font(Font.system(size: 12).weight(.light))
                                    .foregroundColor(.black)
                            }.hidden(callControlViewisHidden)
                                .onChange(of: muteSwitchOn) { _muteSwitchOn in
                                    viewModel.muteSwitchOn = _muteSwitchOn
                               }
                        }
                        Spacer(minLength: 25.0)
                        VStack(alignment: .center) {
                            Toggle(isOn: $speackerSwitchOn) {
                                Text("Speacker")
                                    .font(Font.system(size: 12).weight(.light))
                                    .foregroundColor(.black)
                            }.hidden(callControlViewisHidden)
                                .onChange(of: speackerSwitchOn) { _speackerSwitchOn in
                                    viewModel.speackerSwitchOn = _speackerSwitchOn
                                }
                        }
                        Spacer(minLength: 25.0)
                    }
                }
                    .padding(.bottom, keyboardObserver.height)
            }.onAppear {
                viewModel.viewDidAppear()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentDependencies.configure())
    }
}
