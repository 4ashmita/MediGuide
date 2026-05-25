import Foundation

enum DecisionTreeLoaderError: Error, LocalizedError {
    case fileNotFound
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "DecisionTree.json not found in app bundle."
        case .decodingFailed(let underlying):
            return "Failed to decode DecisionTree.json: \(underlying.localizedDescription)"
        }
    }
}

enum DecisionTreeLoader {
    static func load() throws -> DecisionTreeData {
        guard let url = Bundle.main.url(forResource: "DecisionTree", withExtension: "json") else {
            throw DecisionTreeLoaderError.fileNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(DecisionTreeData.self, from: data)
        } catch let error as DecodingError {
            throw DecisionTreeLoaderError.decodingFailed(error)
        }
    }

    static func getStartNode(from treeData: DecisionTreeData) -> TreeNode? {
        return treeData.nodes[treeData.startNode]
    }

    static func getNodeById(_ id: String, from treeData: DecisionTreeData) -> TreeNode? {
        return treeData.nodes[id]
    }
}
