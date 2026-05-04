import Foundation

enum FuzzyStringMatcher {
    static func matches(query: String, in candidate: String) -> Bool {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else {
            return true
        }

        return matches(normalizedQuery: normalizedQuery, inNormalizedCandidate: normalized(candidate))
    }

    static func matches(normalizedQuery: String, inNormalizedCandidate candidate: String) -> Bool {
        guard !normalizedQuery.isEmpty else {
            return true
        }

        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)
        guard queryTokens.count > 1 else {
            return isSubsequence(normalizedQuery, of: candidate)
        }

        let candidateTokens = candidate.split(separator: " ").map(String.init)
        return queryTokens.allSatisfy { queryToken in
            candidateTokens.contains { candidateToken in
                candidateToken.contains(queryToken) || isSubsequence(queryToken, of: candidateToken)
            }
        }
    }

    private static func isSubsequence(_ query: String, of candidate: String) -> Bool {
        var queryIndex = query.startIndex

        for character in candidate where character == query[queryIndex] {
            query.formIndex(after: &queryIndex)
            if queryIndex == query.endIndex {
                return true
            }
        }

        return false
    }

    static func normalized(_ value: String) -> String {
        let folded = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()

        var result = ""
        result.reserveCapacity(folded.count)
        var previousWasSpace = true

        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                result.unicodeScalars.append(scalar)
                previousWasSpace = false
            } else if !previousWasSpace {
                result.append(" ")
                previousWasSpace = true
            }
        }

        if result.last == " " {
            result.removeLast()
        }

        return result
    }
}
