import XCTest
@testable import H3

final class READMEExamplesTests: XCTestCase {

    // MARK: - Convert a coordinate to an H3 index

    func testConvertCoordinateToIndex() {
        let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
        let index = H3Index(coordinate: coord, resolution: 9)

        XCTAssertFalse(index.description.isEmpty)
        XCTAssertTrue(index.isValid)
        XCTAssertEqual(index.resolution, 9)
    }

    // MARK: - Create an index from a hex string

    func testCreateIndexFromHexString() {
        if let index = H3Index(string: "8928308280fffff") {
            _ = index.coordinate
        } else {
            XCTFail("Failed to parse valid H3 string")
        }

        XCTAssertNil(H3Index(string: "invalid_string"))
    }

    // MARK: - Traverse neighbors (k-ring)

    func testKRingExamples() {
        let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
        let index = H3Index(coordinate: coord, resolution: 9)

        let neighbors = index.kRing(k: 1)
        XCTAssertEqual(neighbors.count, 7)

        let twoRings = index.kRing(k: 2)
        XCTAssertEqual(twoRings.count, 19)
    }

    // MARK: - Navigate the hierarchy

    func testNavigateHierarchy() {
        let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
        let index = H3Index(coordinate: coord, resolution: 9)

        let parent = index.parent(at: 5)
        XCTAssertNotNil(parent)
        XCTAssertEqual(parent?.resolution, 5)

        let directParent = index.directParent
        XCTAssertNotNil(directParent)

        let children = index.children(at: 10)
        XCTAssertFalse(children.isEmpty)
        XCTAssertTrue(children.allSatisfy { $0.resolution == 10 })

        let centerChild = index.directCenterChild
        XCTAssertNotNil(centerChild)
    }

    // MARK: - Get the cell boundary

    func testCellBoundary() {
        let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
        let index = H3Index(coordinate: coord, resolution: 9)

        let vertices = index.boundary()
        XCTAssertEqual(vertices.count, 6)
        XCTAssertTrue(vertices.allSatisfy { $0.lat >= -90 && $0.lat <= 90 })
    }

    // MARK: - Grid distance between two cells

    func testGridDistance() {
        let sf = H3Index(coordinate: H3Coordinate(lat: 37.7793, lng: -122.4193), resolution: 9)
        let oakland = H3Index(coordinate: H3Coordinate(lat: 37.8044, lng: -122.2712), resolution: 9)

        let steps = sf.distance(to: oakland)
        XCTAssertNotNil(steps)
        XCTAssertGreaterThan(steps!, 0)
    }

    // MARK: - Check if a cell is a pentagon

    func testIsPentagon() {
        let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
        let index = H3Index(coordinate: coord, resolution: 5)

        if index.isPentagon {
            XCTFail("SF coordinate should not be a pentagon")
        } else {
            XCTAssertFalse(index.isPentagon)
        }

        let pentagonIndexes = H3Index.pentagons(resolution: 3)
        XCTAssertEqual(pentagonIndexes.count, 12)
        XCTAssertTrue(pentagonIndexes.allSatisfy { $0.isPentagon })
    }

    // MARK: - Average cell area and edge length at a resolution

    func testResolutionStatistics() {
        for res in 0...5 {
            let areaKm2 = H3Index.hexArea(resolution: res, unit: .km2)
            let edgeKm = H3Index.edgeLength(resolution: res, unit: .km)
            let count = H3Index.cellCount(resolution: res)

            XCTAssertGreaterThan(areaKm2, 0)
            XCTAssertGreaterThan(edgeKm, 0)
            XCTAssertGreaterThan(count, 0)

            print("res \(res): \(areaKm2) km²  edge \(edgeKm) km  total cells \(count)")
        }

        XCTAssertEqual(H3Index.cellCount(resolution: 0), 122)
    }

    // MARK: - H3Edge examples

    func testEdgeExamples() {
        let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
        let index = H3Index(coordinate: coord, resolution: 5)

        let edges = index.edges()
        XCTAssertTrue(edges.count == 5 || edges.count == 6)

        if let firstEdge = edges.first {
            XCTAssertTrue(firstEdge.isValid)
            XCTAssertEqual(firstEdge.origin, index)
            XCTAssertNotEqual(firstEdge.destination, index)

            let boundary = firstEdge.boundary()
            XCTAssertFalse(boundary.isEmpty)
        }
    }

    // MARK: - kRingDistances example

    func testKRingDistancesExample() {
        let coord = H3Coordinate(lat: 37.7793, lng: -122.4193)
        let index = H3Index(coordinate: coord, resolution: 5)

        let results = index.kRingDistances(k: 2)
        XCTAssertEqual(results.count, 19)
        XCTAssertTrue(results.contains { $0.index == index && $0.distance == 0 })
    }

    // MARK: - gridLine example

    func testGridLineExample() {
        let sf = H3Index(coordinate: H3Coordinate(lat: 37.7793, lng: -122.4193), resolution: 5)
        let oakland = H3Index(coordinate: H3Coordinate(lat: 37.8044, lng: -122.2712), resolution: 5)

        let line = sf.gridLine(to: oakland)
        XCTAssertNotNil(line)
        XCTAssertTrue(line!.count > 0)
        XCTAssertTrue(line!.first == sf)
        XCTAssertTrue(line!.last == oakland)
    }

    // MARK: - isNeighbor example

    func testIsNeighborExample() {
        let index = H3Index(coordinate: H3Coordinate(lat: 37.7793, lng: -122.4193), resolution: 9)
        let neighbors = index.kRing(k: 1)

        if let neighbor = neighbors.first(where: { $0 != index }) {
            XCTAssertTrue(index.isNeighbor(of: neighbor))
        }
    }

    // MARK: - compact/uncompact examples

    func testCompactUncompactExamples() {
        let parent = H3Index(coordinate: H3Coordinate(lat: 37.7793, lng: -122.4193), resolution: 4)
        let children = parent.children(at: 5)

        let compacted = H3Index.compact(children)
        XCTAssertNotNil(compacted)
        XCTAssertLessThanOrEqual(compacted!.count, children.count)

        let uncompacted = H3Index.uncompact(compacted!, resolution: 5)
        XCTAssertNotNil(uncompacted)
    }

}
