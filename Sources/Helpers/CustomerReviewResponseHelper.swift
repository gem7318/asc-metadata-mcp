import AppStoreAPI

// Both `CustomerReviewResponse` (single review) and `CustomerReviewsResponse` (list) expose
// their side-loaded resources as an `IncludedItem` enum with cases `.customerReviewResponseV1`
// and `.territory`. When we request `include: [.response]` we only care about the developer
// response, so these helpers unwrap that case (ignoring territories) into the concrete
// `CustomerReviewResponseV1` value.
extension CustomerReviewResponse.IncludedItem {
    /// The developer response payload, or `nil` if this included item is a territory.
    var customerReviewResponse: CustomerReviewResponseV1? {
        if case .customerReviewResponseV1(let response) = self { return response }
        return nil
    }
}

extension CustomerReviewsResponse.IncludedItem {
    /// The developer response payload, or `nil` if this included item is a territory.
    var customerReviewResponse: CustomerReviewResponseV1? {
        if case .customerReviewResponseV1(let response) = self { return response }
        return nil
    }
}
