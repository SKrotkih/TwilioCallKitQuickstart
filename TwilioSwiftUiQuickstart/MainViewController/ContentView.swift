//
//  ContentView.swift
//  TwilioVoiceQuickstart
//
//  Created by Serhii Krotkykh on 25.06.2021.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ContentViewModel {
        didSet {
            viewModel.spinner = Spinner(isSpinning: $isSpinning)
            viewModel.placeCallButton = PlaceCallButton(title: $callButtonTitle, isEnabled: $isCallButtonEnabled)
            viewModel.toaster = QualityWarningsToaster(text: $toasterTitle, isHidden: $toasterHidden)
            viewModel.callControls = CallControls(isHidden: $callControlViewisHidden)
        }
    }
    @EnvironmentObject var appDelegate: AppDelegate
    @ObservedObject private var keyboardObserver = KeyboardObserver.shared

    @State private var isSpinning = false
    @State private var callButtonTitle = "Call"
    @State private var isCallButtonEnabled = false
    @State private var toasterTitle = "Warnings Raised"
    @State private var toasterHidden = false
    @State private var muteSwitchOn = false
    @State private var speackerSwitchOn = true
    @State private var callControlViewisHidden = false

    var body: some View {
        ZStack {
            ProgressView()
                .frame(width: 50.0, height: 50.0)
                .progressViewStyle(CircularProgressViewStyle())
                .animation(Animation.easeInOut(duration: 3))
                .hidden(!isSpinning)
            VStack {
                Group {
                    Spacer(minLength: 15.0)
                    Text(toasterTitle)
                        .font(Font.system(size: 14).weight(.light))
                        .foregroundColor(.black)
                        .hidden(toasterHidden)
                        .padding(.top, 0.0)
                    Spacer(minLength: 150.0)
                    Image("TwilioLogo")
                        .resizable(resizingMode: .stretch)
                        .frame(width: 240.0, height: 240.0)
                    Spacer(minLength: 30.0)
                }
                Group {
                    TextField(viewModel.textFieldPlaceholder,
                              text: $viewModel.outgoingValue,
                              onEditingChanged: { _ in
                    }, onCommit: {
                        hideKeyboard()
                    })
                    .frame(height: 30.0)
                    .overlay(RoundedRectangle(cornerRadius: 4) .stroke(.gray))
                    .font(Font.system(size: 16))
                    .padding(.leading, 75.0)
                    .padding(.trailing, 75.0)
                    Spacer(minLength: 15.0)
                    Text(viewModel.hintText)
                        .font(Font.system(size: 10).weight(.light))
                        .foregroundColor(Color(red: 0.47, green: 0.43, blue: 0.40, opacity: 1.00))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.leading, 60.0)
                        .padding(.trailing, 60.0)
                }
                Spacer(minLength: 20.0)
                Group {
                    Button(
                        action: {
                            viewModel.mainButtonPressed()
                        },
                        label: {
                            Text(callButtonTitle)
                                .font(Font.system(size: 14).weight(.light))
                                .foregroundColor(.red)
                        }
                    )
                    .disabled(!isCallButtonEnabled)
                    .padding()
                    if callControlViewisHidden {
                        Spacer()
                    } else {
                        VStack {
                            Spacer(minLength: 15.0)
                            HStack {
                                VStack {
                                    Toggle("Mute", isOn: $muteSwitchOn)
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: .green))
                                        .padding(.bottom, 5.0)
                                        .onChange(of: muteSwitchOn, perform: { isMute in
                                            viewModel.muteSwitchOn = isMute
                                        })
                                    Text(viewModel.muteButtonTitle)
                                        .frame(alignment: .center)
                                        .font(.system(size: 12))
                                }
                                Spacer()
                                    .frame(width: 45.0)
                                VStack {
                                    Toggle("Speaker", isOn: $speackerSwitchOn)
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: .green))
                                        .padding(.bottom, 5.0)
                                        .onChange(of: speackerSwitchOn, perform: { isSpeakerOn in
                                            viewModel.speackerSwitchOn = isSpeakerOn
                                        })
                                    Text(viewModel.spakerButtonTitle)
                                        .frame(alignment: .center)
                                        .font(.system(size: 12))
                                }
                            }
                            .frame(width: 250)
                            Spacer()
                        }
                    }
                    Spacer()
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
