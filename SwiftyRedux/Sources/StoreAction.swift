//
//  Action.swift
//  ReMVVM
//
//  Created by Dariusz Grzeszczak on 29/01/2018.
//  Copyright © 2018 Dariusz Grzeszczak. All rights reserved.
//

import Actions

public protocol StoreAction: Actions.Action where ReturnType == Void { }
