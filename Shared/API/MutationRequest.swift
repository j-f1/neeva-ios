// Copyright Neeva. All rights reserved.

import Apollo
import Combine

open class MutationRequest<Mutation: GraphQLMutation>: ObservableObject {
    private var subcription: Combine.Cancellable? = nil

    public enum State {
        case initial
        case success
        case failure
    }

    @Published public var state: State = .initial
    @Published public var error: Error?

    public init(mutation: Mutation) {
        assert(subcription == nil)

        self.subcription = mutation.perform { result in
            self.subcription = nil
            switch result {
            case .failure(let error):
                self.error = error
                self.state = .failure
                break
            case .success(_):
                self.state = .success
            }
        }
    }
}
