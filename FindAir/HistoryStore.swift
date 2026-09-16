import CoreData
import CoreLocation
import Foundation

@objc(HistoryDevice)
public final class HistoryDevice: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var deviceName: String?
    @NSManaged public var category: String?
    @NSManaged public var records: NSSet?
}

@objc(HistoryRecord)
public final class HistoryRecord: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var signalStrength: Double
    @NSManaged public var rssi: Int32
    @NSManaged public var foundAt: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var device: HistoryDevice?
}

public struct PersistenceController {
    public static let shared = PersistenceController()
    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        let persistentContainer = NSPersistentContainer(name: "FindAirHistory", managedObjectModel: Self.makeModel())
        container = persistentContainer
        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        persistentContainer.loadPersistentStores { description, error in
            guard error != nil else {
                return
            }

            if let storeURL = description.url {
                Self.removeStoreFiles(at: storeURL)
                persistentContainer.loadPersistentStores { _, retryError in
                    if let retryError {
                        assertionFailure("Unable to load history store: \(retryError.localizedDescription)")
                    }
                }
            } else {
                assertionFailure("Unable to load history store: \(error!.localizedDescription)")
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let deviceEntity = NSEntityDescription()
        deviceEntity.name = "HistoryDevice"
        deviceEntity.managedObjectClassName = NSStringFromClass(HistoryDevice.self)
        deviceEntity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("deviceName", .stringAttributeType),
            attribute("category", .stringAttributeType)
        ]

        let recordEntity = NSEntityDescription()
        recordEntity.name = "HistoryRecord"
        recordEntity.managedObjectClassName = NSStringFromClass(HistoryRecord.self)
        recordEntity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("signalStrength", .doubleAttributeType, optional: false),
            attribute("rssi", .integer32AttributeType, optional: false),
            attribute("foundAt", .dateAttributeType),
            attribute("latitude", .doubleAttributeType, optional: false),
            attribute("longitude", .doubleAttributeType, optional: false)
        ]

        let recordsRelationship = NSRelationshipDescription()
        recordsRelationship.name = "records"
        recordsRelationship.destinationEntity = recordEntity
        recordsRelationship.minCount = 0
        recordsRelationship.maxCount = 0
        recordsRelationship.deleteRule = .cascadeDeleteRule

        let deviceRelationship = NSRelationshipDescription()
        deviceRelationship.name = "device"
        deviceRelationship.destinationEntity = deviceEntity
        deviceRelationship.minCount = 1
        deviceRelationship.maxCount = 1
        deviceRelationship.deleteRule = .nullifyDeleteRule

        recordsRelationship.inverseRelationship = deviceRelationship
        deviceRelationship.inverseRelationship = recordsRelationship
        deviceEntity.properties.append(recordsRelationship)
        recordEntity.properties.append(deviceRelationship)
        model.entities = [deviceEntity, recordEntity]
        return model
    }

    private static func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = true) -> NSAttributeDescription {
        let description = NSAttributeDescription()
        description.name = name
        description.attributeType = type
        description.isOptional = optional
        return description
    }

    private static func removeStoreFiles(at storeURL: URL) {
        let fileManager = FileManager.default
        let relatedURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in relatedURLs {
            try? fileManager.removeItem(at: url)
        }
    }
}

@MainActor
public final class HistoryStore {
    public static let shared = HistoryStore()
    private let context: NSManagedObjectContext
    private let locationManager = CLLocationManager()

    private init() {
        context = PersistenceController.shared.container.viewContext
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    public func save(device: BluetoothDevice) {
        let request = NSFetchRequest<HistoryDevice>(entityName: "HistoryDevice")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", device.id as CVarArg)

        let historyDevice: HistoryDevice
        if let existing = try? context.fetch(request).first {
            historyDevice = existing
            historyDevice.deviceName = device.displayName
            historyDevice.category = device.category.title
        } else {
            historyDevice = HistoryDevice(context: context)
            historyDevice.id = device.id
            historyDevice.deviceName = device.displayName
            historyDevice.category = device.category.title
        }

        let record = HistoryRecord(context: context)
        record.id = UUID()
        record.signalStrength = device.signalStrength
        record.rssi = Int32(device.rssi)
        record.foundAt = Date()
        record.device = historyDevice

        if (locationManager.authorizationStatus == .authorizedAlways ||
            locationManager.authorizationStatus == .authorizedWhenInUse),
           let location = locationManager.location {
            record.latitude = location.coordinate.latitude
            record.longitude = location.coordinate.longitude
        } else {
            record.latitude = 0
            record.longitude = 0
        }

        let recordsToRemove = historyDevice.sortedRecords.dropFirst(5)
        for oldRecord in recordsToRemove {
            context.delete(oldRecord)
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            assertionFailure("Unable to save history record: \(error.localizedDescription)")
        }
    }
}

public extension HistoryDevice {
    var displayName: String { deviceName ?? "Unknown Device" }

    var sortedRecords: [HistoryRecord] {
        (records as? Set<HistoryRecord> ?? []).sorted {
            ($0.foundAt ?? .distantPast) > ($1.foundAt ?? .distantPast)
        }
    }
}

public extension HistoryRecord {
    var signalPercentage: Int { Int((signalStrength * 100).rounded()) }
    var hasLocation: Bool { latitude != 0 || longitude != 0 }
}
