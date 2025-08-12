import Foundation
import CoreData

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MusicAlarm")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func fetchAlarms() -> [Alarm] {
        let request: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        
        do {
            let alarmEntities = try context.fetch(request)
            return alarmEntities.compactMap { entity in
                convertEntityToAlarm(entity)
            }
        } catch {
            print("Error fetching alarms: \(error)")
            return []
        }
    }
    
    func saveAlarm(_ alarm: Alarm) {
        let entity = AlarmEntity(context: context)
        entity.id = alarm.id
        entity.time = alarm.time
        entity.isEnabled = alarm.isEnabled
        entity.spotifySongId = alarm.spotifySongId
        entity.label = alarm.label
        entity.snoozeEnabled = alarm.snoozeEnabled
        entity.soundVolume = alarm.soundVolume
        
        do {
            entity.repeatDays = try NSKeyedArchiver.archivedData(withRootObject: Array(alarm.repeatDays.map { $0.rawValue }), requiringSecureCoding: true)
        } catch {
            print("Error archiving repeat days: \(error)")
            entity.repeatDays = Data()
        }
        
        saveContext()
    }
    
    func updateAlarm(_ alarm: Alarm) {
        let request: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", alarm.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                entity.time = alarm.time
                entity.isEnabled = alarm.isEnabled
                entity.spotifySongId = alarm.spotifySongId
                entity.label = alarm.label
                entity.snoozeEnabled = alarm.snoozeEnabled
                entity.soundVolume = alarm.soundVolume
                
                do {
                    entity.repeatDays = try NSKeyedArchiver.archivedData(withRootObject: Array(alarm.repeatDays.map { $0.rawValue }), requiringSecureCoding: true)
                } catch {
                    print("Error archiving repeat days: \(error)")
                }
                
                saveContext()
            }
        } catch {
            print("Error updating alarm: \(error)")
        }
    }
    
    func deleteAlarm(_ id: UUID) {
        let request: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                context.delete(entity)
                saveContext()
            }
        } catch {
            print("Error deleting alarm: \(error)")
        }
    }
    
    private func convertEntityToAlarm(_ entity: AlarmEntity) -> Alarm? {
        guard let id = entity.id,
              let time = entity.time,
              let label = entity.label else {
            return nil
        }
        
        var repeatDays: Set<Weekday> = []
        if let repeatDaysData = entity.repeatDays {
            do {
                if let dayStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(repeatDaysData) as? [String] {
                    repeatDays = Set(dayStrings.compactMap { Weekday(rawValue: $0) })
                }
            } catch {
                print("Error unarchiving repeat days: \(error)")
            }
        }
        
        var alarm = Alarm(
            time: time,
            isEnabled: entity.isEnabled,
            repeatDays: repeatDays,
            spotifySongId: entity.spotifySongId,
            label: label,
            snoozeEnabled: entity.snoozeEnabled,
            soundVolume: entity.soundVolume
        )
        
        return alarm
    }
}