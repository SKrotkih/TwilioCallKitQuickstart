//
//  ContentView.swift
//  TwilioSwiftUiQuickstart
//
//  Created by Serhii Krotkykh on 01.10.2023
//
import SwiftUI
import TwilioVoicePackage

struct ContentView: View {
    @EnvironmentObject var viewModel: ViewModel
    @ObservedObject private var keyboardObserver = KeyboardObserver.shared
    @State private var outgoingValue = ""

    var body: some View {
        ZStack {
            ProgressView()
                .frame(width: 50.0, height: 50.0)
                .progressViewStyle(CircularProgressViewStyle())
                .animation(Animation.easeInOut(duration: 3))
                .hidden(!viewModel.startLongTermProcess)
            VStack {
                Group {
                    Spacer(minLength: 15.0)
                    Text(viewModel.warningText)
                        .hidden(viewModel.warningText.isEmpty)
                        .font(Font.system(size: 14).weight(.light))
                        .foregroundColor(.black)
                        .padding(.top, 0.0)
                    Spacer(minLength: 150.0)
                    Image("TwilioLogo")
                        .resizable(resizingMode: .stretch)
                        .frame(width: 240.0, height: 240.0)
                    Spacer(minLength: 30.0)
                }
                Group {
                    TextField("Client name or phone number",
                              text: $outgoingValue,
                              onEditingChanged: { _ in
                    }, onCommit: {
                        hideKeyboard()
                    })
                    .onChange(of: outgoingValue, perform: { text in
                        viewModel.saveOutgoingValue(text)
                    })
                    .frame(height: 30.0)
                    .overlay(RoundedRectangle(cornerRadius: 4) .stroke(.gray))
                    .font(Font.system(size: 16))
                    .padding(.leading, 75.0)
                    .padding(.trailing, 75.0)
                    Spacer(minLength: 15.0)
                    Text("Dial a client name or phone number. Leaving the field empty results in an automated response.")
                        .font(Font.system(size: 10).weight(.light))
                        .foregroundColor(Color(red: 0.47, green: 0.43, blue: 0.40, opacity: 1.00))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.leading, 60.0)
                        .padding(.trailing, 60.0)
                }
                Spacer(minLength: 20.0)
                VStack {
                    Button(
                        action: {
                            viewModel.makeCallButtonPressed()
                        },
                        label: {
                            Text(viewModel.mainButtonTitle)
                                .font(Font.system(size: 14).weight(.light))
                                .foregroundColor(.red)
                        }
                    )
                    .disabled(!viewModel.enableMainButton)
                    .padding()
                    Group {
                        Spacer(minLength: 15.0)
                        HStack {
                            VStack {
                                Toggle("Mute", isOn: $viewModel.onMute)
                                    .toggleStyle()
                                    .onChange(of: viewModel.onMute, perform: { isMute in
                                        viewModel.toggleMuteSwitch(to: isMute)
                                    })
                                Text("Mute")
                                    .toggleTextStyle()
                            }
                            Spacer()
                                .frame(width: 45.0)
                            VStack {
                                Toggle("Speaker", isOn: $viewModel.onSpeaker)
                                    .toggleStyle()
                                    .onChange(of: viewModel.onSpeaker, perform: { isSpeakerOn in
                                        viewModel.toggleSpeakerSwitch(to: isSpeakerOn)
                                    })
                                Text("Speaker")
                                    .toggleTextStyle()
                            }
                        }
                        .frame(width: 250)
                    }.hidden(!viewModel.showCallControl)
                    Spacer()
                }
                .padding(.bottom, keyboardObserver.height)
            }.onAppear {
                viewModel.viewDidLoad(viewController: UIViewController())
            }
        }
    }
}

struct ToggleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: .green))
            .padding(.bottom, 5.0)
    }
}

struct ToggleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(alignment: .center)
            .font(.system(size: 12))
    }
}

extension View {
    func toggleStyle() -> some View {
        modifier(ToggleStyle())
    }
    func toggleTextStyle() -> some View {
        modifier(ToggleTextStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ViewModel())
    }
}
