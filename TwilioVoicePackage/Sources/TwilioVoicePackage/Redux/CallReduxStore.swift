//
//  CallReduxStore.swift
//  Twilio Voice Quickstart - Swift
//
import Combine

let store = ReduxStore.shared.store

typealias CallReduxStore = Store<CallState, CallAction, NetworkService>
typealias Reducer<State, Action, Environment> = (State, Action, Environment) async throws -> State

public class ReduxStore {
    public static let shared = ReduxStore()

    public let environment = Environment()

    lazy var networkService: NetworkService = {
        NetworkService(with: environment.callKitActions)
    }()

    lazy var store: CallReduxStore = {
        return Store(initialState: .init(), reducer: callReducer, environment: networkService)
    }()
}
///
///  Store: Store holds the state. Store receives the action and passes on to the reducer
///  and gets the updated state and passes on to the subscribers.
///  It is important to note that you will only have a single store in an application.
///  If you want to split your data handling logic,
///  you will use reducer composition i.e using many reducers instead of many stores.
///
///  Example:
///  private let store: CallReduxStore = Store(initialState: .init(userSession: nil), reducer: callReducer)
///
///  Thanks https://github.com/mecid/redux-like-state-container-in-swiftui for the idea
///
final class Store<State, Action, Environment>: ObservableObject {
    @Published var state: State

    private let reducer: Reducer<State, Action, Environment>
    private let environment: Environment

    init(initialState: State,
         reducer: @escaping Reducer<State, Action, Environment>,
         environment: Environment) {
        self.state = initialState
        self.reducer = reducer
        self.environment = environment
    }

    func stateDispatch(action: Action) {
        Task { @MainActor in
            do {
                self.state = try await reducer(self.state, action, environment)
            } catch {
                fatalError("Failed to change state")
            }
        }
    }
}
