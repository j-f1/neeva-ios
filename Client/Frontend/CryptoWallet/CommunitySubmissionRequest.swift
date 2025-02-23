// Copyright Neeva. All rights reserved.

import Apollo
import Combine
import Foundation
import Shared

public class TrustSignalRequest: MutationRequest<ReportDomainTrustSignalMutation> {
    public init(url: URL, trusted: Bool) {
        super.init(
            mutation: ReportDomainTrustSignalMutation(
                input: ReportDomainTrustSignalInput(
                    domain: url.baseDomain, signal: trusted ? .trusted : .malicious
                )))
    }
}

let web3Extensions = [".io", ".xyz", ".com", ".art"]

typealias DomainTrustSignal = GetDomainTrustSignalsQuery.Data.DomainTrustSignal

class TrustSignalController: QueryController<GetDomainTrustSignalsQuery, [DomainTrustSignal]> {

    override class func processData(_ data: GetDomainTrustSignalsQuery.Data) -> [DomainTrustSignal]
    {
        data.domainTrustSignals ?? []
    }

    @discardableResult static func getTrustSignals(
        domains: [String],
        completion: @escaping (Result<[DomainTrustSignal], Error>) -> Void
    ) -> Combine.Cancellable {
        Self.perform(
            query: GetDomainTrustSignalsQuery(
                input: DomainTrustSignalsInput(domains: domains)),
            completion: completion
        )
    }

    @discardableResult static func getTrustSignals(
        domain: String,
        completion: @escaping (Result<[DomainTrustSignal], Error>) -> Void
    ) -> Combine.Cancellable {
        var domains = [domain]
        if let index = domain.lastIndex(of: ".") {
            domains.append(
                contentsOf: web3Extensions.map({ String(domain.prefix(upTo: index)) + $0 }))
        }

        return getTrustSignals(domains: domains, completion: completion)
    }
}
