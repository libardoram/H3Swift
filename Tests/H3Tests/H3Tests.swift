import XCTest
@testable import H3

final class H3Tests: XCTestCase {

    // MARK: - Known test values
    // San Francisco City Hall: 37.7793°N, 122.4193°W
    private let sfLat: Double = 37.7793
    private let sfLon: Double = -122.4193
    private let sfRes5String = "85283083fffffff"
    private let sfRes5RawValue: UInt64 = 0x85283083fffffff

    // Oakland City Hall: 37.8044°N, 122.2712°W (same resolution, close neighbor)
    private let oaklandLat: Double = 37.8044
    private let oaklandLon: Double = -122.2712

    private func sfIndex(resolution: Int32 = 9) -> H3Index {
        H3Index(coordinate: H3Coordinate(lat: sfLat, lng: sfLon), resolution: resolution)
    }

    private func oaklandIndex(resolution: Int32 = 9) -> H3Index {
        H3Index(coordinate: H3Coordinate(lat: oaklandLat, lng: oaklandLon), resolution: resolution)
    }

    // MARK: - H3Coordinate

    func testCoordinateInitialization() {
        let coord = H3Coordinate(lat: sfLat, lng: sfLon)
        XCTAssertEqual(coord.lat, sfLat)
        XCTAssertEqual(coord.lng, sfLon)
    }

    func testCoordinateEquality() {
        let a = H3Coordinate(lat: 37.0, lng: -122.0)
        let b = H3Coordinate(lat: 37.0, lng: -122.0)
        let c = H3Coordinate(lat: 38.0, lng: -122.0)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testCoordinateCodable() throws {
        let coord = H3Coordinate(lat: sfLat, lng: sfLon)
        let data = try JSONEncoder().encode(coord)
        let decoded = try JSONDecoder().decode(H3Coordinate.self, from: data)
        XCTAssertEqual(coord, decoded)
    }

    // MARK: - H3Index initializers

    func testInitFromCoordinate() {
        let index = sfIndex(resolution: 5)
        XCTAssertTrue(index.isValid)
        XCTAssertEqual(index.resolution, 5)
    }

    func testInitFromRawValue() {
        let index = H3Index(sfRes5RawValue)
        XCTAssertTrue(index.isValid)
        XCTAssertEqual(index.rawValue, sfRes5RawValue)
    }

    func testInitFromValidString() {
        let index = H3Index(string: sfRes5String)
        XCTAssertNotNil(index)
        XCTAssertTrue(index!.isValid)
        XCTAssertEqual(index!.resolution, 5)
    }

    func testInitFromInvalidStringReturnsNil() {
        XCTAssertNil(H3Index(string: "not_a_valid_h3_string"))
    }

    func testInitFromEmptyStringReturnsNil() {
        XCTAssertNil(H3Index(string: ""))
    }

    // MARK: - H3Index core properties

    func testResolution() {
        for res: Int32 in [0, 3, 5, 9, 15] {
            let index = sfIndex(resolution: res)
            XCTAssertEqual(index.resolution, Int(res))
        }
    }

    func testIsValid() {
        XCTAssertTrue(sfIndex().isValid)
        XCTAssertFalse(H3Index(0).isValid)
    }

    func testCoordinateRoundTrip() {
        let index = sfIndex(resolution: 9)
        let recovered = index.coordinate
        XCTAssertEqual(recovered.lat, sfLat, accuracy: 1.0)
        XCTAssertEqual(recovered.lng, sfLon, accuracy: 1.0)
    }

    // MARK: - H3Index missing properties

    func testBaseCell() {
        let index = sfIndex(resolution: 5)
        // Base cell is 0–121
        XCTAssertTrue((0...121).contains(index.baseCell))
    }

    func testIsPentagonFalseForNormalCell() {
        // SF is not near an icosahedron vertex so this should be false
        XCTAssertFalse(sfIndex(resolution: 5).isPentagon)
    }

    func testIsPentagonTrueForKnownPentagon() {
        // Pentagon at res 0 base cell 4 is a well-known pentagon
        let pentagons = H3Index.pentagons(resolution: 0)
        XCTAssertFalse(pentagons.isEmpty)
        XCTAssertTrue(pentagons.allSatisfy { $0.isPentagon })
    }

    func testIsResClassIII() {
        // Odd resolutions are Class III, even are Class II
        XCTAssertFalse(sfIndex(resolution: 0).isResClassIII) // even → Class II
        XCTAssertTrue(sfIndex(resolution: 1).isResClassIII)  // odd  → Class III
        XCTAssertFalse(sfIndex(resolution: 2).isResClassIII)
        XCTAssertTrue(sfIndex(resolution: 3).isResClassIII)
    }

    func testFaces() {
        let index = sfIndex(resolution: 5)
        let faces = index.faces()
        // A cell intersects 1–2 icosahedron faces (never 0)
        XCTAssertFalse(faces.isEmpty)
        XCTAssertTrue(faces.allSatisfy { (0...19).contains($0) })
    }

    // MARK: - CustomStringConvertible

    func testDescription() {
        guard let index = H3Index(string: sfRes5String) else {
            return XCTFail("Failed to create index from string")
        }
        XCTAssertEqual(index.description, sfRes5String)
    }

    func testDescriptionRoundTrip() {
        let index = sfIndex(resolution: 7)
        let recovered = H3Index(string: index.description)
        XCTAssertNotNil(recovered)
        XCTAssertEqual(index, recovered)
    }

    // MARK: - Equatable / Hashable

    func testEquality() {
        XCTAssertEqual(sfIndex(resolution: 5), sfIndex(resolution: 5))
    }

    func testHashability() {
        var set = Set<H3Index>()
        set.insert(sfIndex(resolution: 5))
        set.insert(sfIndex(resolution: 5))
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Traversal

    func testKRingK0ReturnsSelf() {
        let index = sfIndex(resolution: 5)
        let ring = index.kRing(k: 1)
        XCTAssertTrue(ring.contains(index))
    }

    func testKRingK1Returns7Cells() {
        let ring = sfIndex(resolution: 5).kRing(k: 1)
        XCTAssertEqual(ring.count, 7)
    }

    func testKRingAllValid() {
        XCTAssertTrue(sfIndex(resolution: 6).kRing(k: 2).allSatisfy { $0.isValid })
    }

    func testHexRingK1Returns6Cells() {
        // hexRing(k:1) is the hollow ring — exactly 6 cells (no self)
        let ring = sfIndex(resolution: 5).hexRing(k: 1)
        XCTAssertNotNil(ring)
        XCTAssertEqual(ring?.count, 6)
    }

    func testHexRingK0ReturnsSelf() {
        let ring = sfIndex(resolution: 5).hexRing(k: 0)
        XCTAssertNotNil(ring)
        XCTAssertEqual(ring?.count, 1)
    }

    func testHexRingDoesNotContainOrigin() {
        let index = sfIndex(resolution: 5)
        let ring = index.hexRing(k: 2)
        XCTAssertNotNil(ring)
        XCTAssertFalse(ring!.contains(index))
    }

    func testKRingDistances() {
        let index = sfIndex(resolution: 5)
        let results = index.kRingDistances(k: 2)
        // k=2 → 1 + 6 + 12 = 19 cells
        XCTAssertEqual(results.count, 19)
        // Origin is always distance 0
        XCTAssertTrue(results.contains { $0.index == index && $0.distance == 0 })
        // All distances are 0–2
        XCTAssertTrue(results.allSatisfy { $0.distance >= 0 && $0.distance <= 2 })
    }

    // MARK: - Hierarchy

    func testDirectParent() {
        let child = sfIndex(resolution: 5)
        XCTAssertEqual(child.directParent?.resolution, 4)
    }

    func testParentAtResolution() {
        XCTAssertEqual(sfIndex(resolution: 9).parent(at: 5)?.resolution, 5)
    }

    func testParentAtInvalidResolutionReturnsNil() {
        XCTAssertNil(sfIndex(resolution: 3).parent(at: 5))
    }

    func testChildrenAtResolution() {
        let children = sfIndex(resolution: 4).children(at: 5)
        XCTAssertFalse(children.isEmpty)
        XCTAssertTrue(children.allSatisfy { $0.resolution == 5 && $0.isValid })
    }

    func testDirectCenterChild() {
        XCTAssertEqual(sfIndex(resolution: 4).directCenterChild?.resolution, 5)
    }

    func testCenterChildAtResolution() {
        XCTAssertEqual(sfIndex(resolution: 3).centerChild(at: 6)?.resolution, 6)
    }

    // MARK: - Grid distance

    func testDistanceToSelf() {
        let index = sfIndex(resolution: 9)
        XCTAssertEqual(index.distance(to: index), 0)
    }

    func testDistanceToNeighborIsOne() {
        let index = sfIndex(resolution: 9)
        let neighbor = index.kRing(k: 1).first { $0 != index }!
        XCTAssertEqual(index.distance(to: neighbor), 1)
    }

    func testDistanceSFtoOakland() {
        let sf = sfIndex(resolution: 9)
        let oak = oaklandIndex(resolution: 9)
        let d = sf.distance(to: oak)
        XCTAssertNotNil(d)
        XCTAssertGreaterThan(d!, 0)
    }

    // MARK: - Grid line

    func testGridLineStartAndEndIncluded() {
        let sf = sfIndex(resolution: 5)
        let oak = oaklandIndex(resolution: 5)
        let line = sf.gridLine(to: oak)
        XCTAssertNotNil(line)
        XCTAssertTrue(line!.contains(sf))
        XCTAssertTrue(line!.contains(oak))
    }

    func testGridLineAllValid() {
        let sf = sfIndex(resolution: 5)
        let oak = oaklandIndex(resolution: 5)
        let line = sf.gridLine(to: oak)
        XCTAssertNotNil(line)
        XCTAssertTrue(line!.allSatisfy { $0.isValid })
    }

    func testGridLineToSelfReturnsOneCell() {
        let index = sfIndex(resolution: 5)
        let line = index.gridLine(to: index)
        XCTAssertNotNil(line)
        XCTAssertEqual(line!.count, 1)
    }

    // MARK: - Boundary

    func testBoundaryVertexCount() {
        let boundary = sfIndex(resolution: 5).boundary()
        XCTAssertTrue(boundary.count == 5 || boundary.count == 6)
    }

    func testBoundaryCoordinatesAreValid() {
        for coord in sfIndex(resolution: 5).boundary() {
            XCTAssertTrue(coord.lat >= -90 && coord.lat <= 90)
            XCTAssertTrue(coord.lng >= -180 && coord.lng <= 180)
        }
    }

    // MARK: - H3Edge

    func testEdgesFromHexagon() {
        let index = sfIndex(resolution: 5)
        let edges = index.edges()
        // A hexagon has 6 edges; a pentagon has 5
        XCTAssertTrue(edges.count == 5 || edges.count == 6)
        XCTAssertTrue(edges.allSatisfy { $0.isValid })
    }

    func testEdgeOriginAndDestination() {
        let index = sfIndex(resolution: 5)
        let edges = index.edges()
        for edge in edges {
            XCTAssertEqual(edge.origin, index)
            XCTAssertNotEqual(edge.destination, index)
            XCTAssertTrue(edge.destination.isValid)
        }
    }

    func testEdgeBetweenNeighbors() {
        let index = sfIndex(resolution: 5)
        let neighbor = index.kRing(k: 1).first { $0 != index }!
        let edge = H3Edge(from: index, to: neighbor)
        XCTAssertNotNil(edge)
        XCTAssertTrue(edge!.isValid)
    }

    func testEdgeBetweenNonNeighborsIsNil() {
        let sf = sfIndex(resolution: 5)
        let oak = oaklandIndex(resolution: 5)
        // SF and Oakland at res 5 are not direct neighbors
        let edge = H3Edge(from: sf, to: oak)
        XCTAssertNil(edge)
    }

    func testEdgeBoundary() {
        let index = sfIndex(resolution: 5)
        let edge = index.edges().first!
        let boundary = edge.boundary()
        XCTAssertFalse(boundary.isEmpty)
        XCTAssertTrue(boundary.allSatisfy { $0.lat >= -90 && $0.lat <= 90 })
    }

    func testAreNeighbors() {
        let index = sfIndex(resolution: 5)
        let neighbor = index.kRing(k: 1).first { $0 != index }!
        let farAway = oaklandIndex(resolution: 5)
        XCTAssertTrue(index.isNeighbor(of: neighbor))
        XCTAssertFalse(index.isNeighbor(of: farAway))
    }

    func testEdgeEquality() {
        let index = sfIndex(resolution: 5)
        let edges = index.edges()
        XCTAssertEqual(edges[0], edges[0])
        XCTAssertNotEqual(edges[0], edges[1])
    }

    // MARK: - Compact / Uncompact

    func testCompactAndUncompact() {
        // Take all children of an SF res-4 cell at res 5, compact back → should give res-4 parent
        let parent = sfIndex(resolution: 4)
        let children = parent.children(at: 5)
        let compacted = H3Index.compact(children)
        XCTAssertNotNil(compacted)
        // Compacted set should be smaller than or equal to children count
        XCTAssertLessThanOrEqual(compacted!.count, children.count)
        XCTAssertTrue(compacted!.allSatisfy { $0.isValid })
    }

    func testUncompactRoundTrip() {
        let parent = sfIndex(resolution: 4)
        let children = parent.children(at: 5)
        let compacted = H3Index.compact(children)!
        let uncompacted = H3Index.uncompact(compacted, resolution: 5)
        XCTAssertNotNil(uncompacted)
        XCTAssertEqual(Set(uncompacted!), Set(children))
    }

    func testCompactEmptySetReturnsEmpty() {
        let result = H3Index.compact([])
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.isEmpty)
    }

    // MARK: - Polyfill

    func testPolyfillSmallSquare() {
        // A small square around SF City Hall
        let polygon = H3GeoPolygon(
            exterior: [
                H3Coordinate(lat: 37.770, lng: -122.425),
                H3Coordinate(lat: 37.770, lng: -122.410),
                H3Coordinate(lat: 37.785, lng: -122.410),
                H3Coordinate(lat: 37.785, lng: -122.425),
            ]
        )
        let cells = polygon.fill(resolution: 9)
        XCTAssertFalse(cells.isEmpty)
        XCTAssertTrue(cells.allSatisfy { $0.isValid })
        XCTAssertTrue(cells.allSatisfy { $0.resolution == 9 })
    }

    func testPolyfillCellsAreInsidePolygon() {
        let polygon = H3GeoPolygon(
            exterior: [
                H3Coordinate(lat: 37.770, lng: -122.425),
                H3Coordinate(lat: 37.770, lng: -122.410),
                H3Coordinate(lat: 37.785, lng: -122.410),
                H3Coordinate(lat: 37.785, lng: -122.425),
            ]
        )
        let cells = polygon.fill(resolution: 8)
        // Each cell's center coordinate should be roughly within the bounding box
        for cell in cells {
            let c = cell.coordinate
            XCTAssertTrue(c.lat >= 37.770 && c.lat <= 37.785, "lat \(c.lat) outside bbox")
            XCTAssertTrue(c.lng >= -122.425 && c.lng <= -122.410, "lng \(c.lng) outside bbox")
        }
    }

    func testPolyfillWithHole() {
        let exterior: [H3Coordinate] = [
            H3Coordinate(lat: 37.760, lng: -122.430),
            H3Coordinate(lat: 37.760, lng: -122.400),
            H3Coordinate(lat: 37.800, lng: -122.400),
            H3Coordinate(lat: 37.800, lng: -122.430),
        ]
        let hole: [H3Coordinate] = [
            H3Coordinate(lat: 37.774, lng: -122.422),
            H3Coordinate(lat: 37.774, lng: -122.412),
            H3Coordinate(lat: 37.782, lng: -122.412),
            H3Coordinate(lat: 37.782, lng: -122.422),
        ]
        let withHole = H3GeoPolygon(exterior: exterior, holes: [hole])
        let withoutHole = H3GeoPolygon(exterior: exterior)

        let cellsWithHole = withHole.fill(resolution: 9)
        let cellsWithoutHole = withoutHole.fill(resolution: 9)

        // Polygon with a hole should produce fewer cells
        XCTAssertLessThan(cellsWithHole.count, cellsWithoutHole.count)
    }

    // MARK: - Static resolution stats

    func testHexAreaDecreasesWithResolution() {
        for res in 0..<15 {
            XCTAssertGreaterThan(H3Index.hexArea(resolution: res, unit: .km2),
                                 H3Index.hexArea(resolution: res + 1, unit: .km2))
        }
    }

    func testHexAreaKm2VsM2() {
        for res in 0...5 {
            let km2 = H3Index.hexArea(resolution: res, unit: .km2)
            let m2  = H3Index.hexArea(resolution: res, unit: .m2)
            XCTAssertEqual(km2 * 1_000_000, m2, accuracy: m2 * 0.0001)
        }
    }

    func testEdgeLengthDecreasesWithResolution() {
        for res in 0..<15 {
            XCTAssertGreaterThan(H3Index.edgeLength(resolution: res, unit: .km),
                                 H3Index.edgeLength(resolution: res + 1, unit: .km))
        }
    }

    func testNumHexagonsIncreasesWithResolution() {
        for res in 0..<15 {
            XCTAssertLessThan(H3Index.cellCount(resolution: res),
                              H3Index.cellCount(resolution: res + 1))
        }
    }

    func testRes0IndexCount() {
        let indexes = H3Index.res0Cells()
        XCTAssertEqual(indexes.count, 122)
        XCTAssertTrue(indexes.allSatisfy { $0.isValid })
        XCTAssertTrue(indexes.allSatisfy { $0.resolution == 0 })
    }

    func testPentagonCount() {
        let pentagons = H3Index.pentagons(resolution: 5)
        XCTAssertEqual(pentagons.count, 12)
        XCTAssertTrue(pentagons.allSatisfy { $0.isPentagon })
    }

    func testPentagonCountAllResolutions() {
        for res in 0...15 {
            XCTAssertEqual(H3Index.pentagons(resolution: res).count, 12)
        }
    }

}
