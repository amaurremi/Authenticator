//
//  TokenRowModel.swift
//  Authenticator
//
//  Copyright (c) 2015-2019 Authenticator authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import OneTimePassword

struct TokenRowModel: Equatable, Identifiable {
    typealias Action = TokenList.Action

    let name, issuer, password: String
    let showsButton: Bool
    let canReorder: Bool
    let buttonAction: Action
    let selectAction: Action
    let editAction: Action
    let deleteAction: Action

    private let identifier: Data

    init(persistentToken: PersistentToken, displayTime: DisplayTime, digitGroupSize: Int, canReorder reorderable: Bool = true) {
        let rawPassword = (try? persistentToken.token.generator.password(at: displayTime.date)) ?? ""

        name = persistentToken.token.name
        issuer = persistentToken.token.issuer
        let now = Date()
        let calendar = Calendar.current
        let startTime1 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now)!
        let endTime1 = calendar.date(bySettingHour: 14, minute: 00, second: 0, of: now)!
        let startTime2 = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: now)!
        let endTime2 = calendar.date(bySettingHour: 19, minute: 00, second: 0, of: now)!
        
        let timeAllowedToSetUpToken = calendar.date(byAdding: .minute, value: 1, to: persistentToken.creationTime)!
        let allowedTimePassed = timeAllowedToSetUpToken < now
        
        if (now < startTime1 && allowedTimePassed) {
            let startComponents = calendar.dateComponents([.hour, .minute], from: now, to: startTime1)
            password = String(startComponents.hour!) + ":" + String(startComponents.minute!) + " left"
            selectAction = .noAction
        } else if (now > endTime1 && now < startTime2 && allowedTimePassed) {
            let dayEndComponents = calendar.dateComponents([.hour, .minute], from: now, to: startTime2)
            password = String(dayEndComponents.hour!) + ":" + String(dayEndComponents.minute!) + " left"
            selectAction = .noAction
        } else if (now > endTime2 && allowedTimePassed) {
            let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startTime1)!
            let dayEndComponents = calendar.dateComponents([.hour, .minute], from: now, to: tomorrowStart)
            password = String(dayEndComponents.hour!) + ":" + String(dayEndComponents.minute!) + " left"
            selectAction = .noAction
        } else {
            password = TokenRowModel.chunkPassword(rawPassword, chunkSize: digitGroupSize)
            selectAction = .copyPassword(rawPassword)
        }
        if case .counter = persistentToken.token.generator.factor {
            showsButton = true
        } else {
            showsButton = false
        }
        buttonAction = .updatePersistentToken(persistentToken)
        editAction = .editPersistentToken(persistentToken)
        deleteAction = .deletePersistentToken(persistentToken)
        identifier = persistentToken.identifier
        canReorder = reorderable
    }

    func hasSameIdentity(as other: TokenRowModel) -> Bool {
        return (self.identifier == other.identifier)
    }

    // Group the password into chunks of two digits, separated by spaces.
    private static func chunkPassword(_ password: String, chunkSize: Int) -> String {
        var mutablePassword = password
        for i in stride(from: chunkSize, to: mutablePassword.count, by: chunkSize).reversed() {
            mutablePassword.insert(" ", at: mutablePassword.index(mutablePassword.startIndex, offsetBy: i))
        }
        return mutablePassword
    }
}
