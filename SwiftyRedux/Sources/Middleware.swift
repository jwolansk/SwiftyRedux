//
//  Middleware.swift
//  ReMVVM
//
//  Created by Dariusz Grzeszczak on 22/09/2018.
//  Copyright © 2018 Dariusz Grzeszczak. All rights reserved.
//

public protocol AnyMiddleware {
    func applyMiddleware<State: StoreState>(for state: State, action: StoreAction, dispatcher: AnyDispatcher<State>)
}

public protocol Middleware: AnyMiddleware {
    associatedtype Action: StoreAction
    associatedtype State: StoreState
    func applyMiddleware(for state: State, action: Action, dispatcher: Dispatcher<Action, State>)
}

extension AnyMiddleware where Self: Middleware {
    public func applyMiddleware<State: StoreState>(for state: State, action: StoreAction, dispatcher: AnyDispatcher<State>) {
        guard   let action = action as? Self.Action,
                let state = state as? Self.State,
                let middlewareDispatcher = dispatcher.dispatcher as? MiddlewareDispatcher<Self.State>
        else {
            dispatcher.next()
            return
        }

        let dispatcher = Dispatcher<Self.Action, Self.State>(dispatcher: middlewareDispatcher, action: action)
        applyMiddleware(for: state, action: action, dispatcher: dispatcher)
    }
}

struct MiddlewareDispatcher<State: StoreState>: StoreActionDispatcher {
    weak var store: Store<State>?
    let completion: ((State) -> Void)?
    let middleware: [AnyMiddleware]
    let reduce: () -> Void

    func dispatch(action: StoreAction) {
        store?.dispatch(action: action)
    }

    func next(action: StoreAction, completion: ((State) -> Void)? = nil) {

        guard let store = store else { return } // store dealocated no need to do

        let compl = compose(completion1: self.completion, completion2: completion)

        guard !middleware.isEmpty else { // reduce if no more middlewares
            reduce()
            compl?(store.state)
            return
        }

        var newWiddleware = middleware
        let first = newWiddleware.removeFirst()
        let middlewareDispatcher = MiddlewareDispatcher(store: store, completion: compl, middleware: newWiddleware, reduce: reduce)
        let dispatcher = AnyDispatcher(dispatcher: middlewareDispatcher, action: action)

        first.applyMiddleware(for: store.state, action: action, dispatcher: dispatcher)
    }

    private func compose(completion1: ((State) -> Void)?, completion2: ((State) -> Void)?) -> ((State) -> Void)? {
        guard let completion1 = completion1 else { return completion2 }
        guard let completion2 = completion2 else { return completion1 }
        return { state in
            completion2(state)
            completion1(state)
        }
    }
}

public struct AnyDispatcher<State: StoreState>: StoreActionDispatcher {

    let dispatcher: MiddlewareDispatcher<State>
    let action: StoreAction

    public func dispatch(action: StoreAction) {
        dispatcher.dispatch(action: action)
    }

    public func next(completion: ((State) -> Void)? = nil) {
        next(action: action, completion: completion)
    }

    public func next(action: StoreAction, completion: ((State) -> Void)? = nil) {
        dispatcher.next(action: action, completion: completion)
    }
}

public struct Dispatcher<Action: StoreAction, State: StoreState>: StoreActionDispatcher {

    let dispatcher: MiddlewareDispatcher<State>
    let action: Action

    public func dispatch(action: StoreAction) {
        dispatcher.dispatch(action: action)
    }

    public func next(completion: ((State) -> Void)? = nil) {
        next(action: action, completion: completion)
    }

    public func next(action: Action, completion: ((State) -> Void)? = nil) {
        dispatcher.next(action: action, completion: completion)
    }
}
