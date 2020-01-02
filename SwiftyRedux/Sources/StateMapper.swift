//
//  StateMapper.swift
//  SwiftyRedux
//
//  Created by Dariusz Grzeszczak on 10/12/2019.
//  Copyright © 2019 Dariusz Grzeszczak. All rights reserved.
//

import Foundation

/**
 Maps application state to any other 'substate' that may be observed in the store.

 #Example
     struct ApplicationState: StoreState {

        let userState: UserState
        let favouritesState: FavouritesState

        let factory: ViewModelFactory
     }

     let userStateMapper = StateMapper<ApplicationState> { $0.userState }
 */
public struct StateMapper<State> {

    let newStateType: Any.Type
    private let _map: (State) -> Any
    /// Initialize mapper with map finction
    /// - Parameter map: pure function that maps the state to 'sub'state
    public init<NewState>(map: @escaping (State) -> NewState) {
        newStateType = NewState.self
        _map = { map($0) }
    }

    /// Initialize mapper with keyPath to substate
    /// - Parameter keyPath: property key path to substate
    public init<NewState>(keyPath: KeyPath<State, NewState>) {
        self.init { $0[keyPath: keyPath] }
    }

    func matches<State>(state: State.Type) -> Bool {
        return newStateType == state
    }

    func map<NewState>(state: State) -> NewState? {
        guard newStateType == NewState.self else { return nil }
        return _map(state) as? NewState
    }
}