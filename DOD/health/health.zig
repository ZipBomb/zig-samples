// page 68
const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const MAX_HEALTH = 100;
const TIME_BEFORE_REGENERATING_MS = 5_000;
const AMOUNT_TO_HEAL = 3;

const Entity = struct {
    id: i32,
    // information about the entity position
    // ...
    // other entity information
};

const EntityDamage = struct {
    time_of_last_damage: ?i64,
    health: f32,
};

fn updateHealth(
    entity_damages: *std.AutoHashMap(*Entity, *EntityDamage),
    dead_entities: *std.ArrayList(*Entity),
) !void {
    var it = entity_damages.*.iterator();
    while (it.next()) |ed_iter| {
        const entity: *Entity = ed_iter.key_ptr.*;
        const damage: *EntityDamage = ed_iter.value_ptr.*;
        if (damage.health <= 0) {
            // if dead, insert the fact that the entity is dead
            try dead_entities.append(entity);
            try expect(entity_damages.remove(entity) == true);
        } else {
            const now = std.time.milliTimestamp();
            const time_since_last_shot = now - (damage.time_of_last_damage orelse 0);
            const regen_can_start = time_since_last_shot > TIME_BEFORE_REGENERATING_MS;
            if (regen_can_start) {
                damage.health = damage.health + AMOUNT_TO_HEAL;
                if (damage.health >= MAX_HEALTH) {
                    try expect(entity_damages.remove(entity) == true);
                }
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    var entities = std.ArrayList(*Entity).init(allocator);
    defer entities.deinit();

    var entity_damages = std.AutoHashMap(*Entity, *EntityDamage).init(allocator);
    defer entity_damages.deinit();

    var dead_entities = std.ArrayList(*Entity).init(allocator);
    defer dead_entities.deinit();

    var player = Entity{ .id = 1 };
    var enemy_1 = Entity{ .id = 2 };
    var enemy_2 = Entity{ .id = 3 };
    try entities.appendSlice(&[_]*Entity{ &player, &enemy_1, &enemy_2 });

    var enemy1_damage = EntityDamage{
        .time_of_last_damage = std.time.milliTimestamp() - 10_000,
        .health = 87,
    };
    var enemy2_damage = EntityDamage{
        .time_of_last_damage = std.time.milliTimestamp() - 8_000,
        .health = 0,
    };
    try entity_damages.put(&enemy_1, &enemy1_damage);
    try entity_damages.put(&enemy_2, &enemy2_damage);

    var it = entity_damages.iterator();
    while (it.next()) |entry| {
        print(
            "entity damages entry before update = k {}, v {any}\n",
            .{ entry.key_ptr.*, entry.value_ptr.* },
        );
    }

    try updateHealth(&entity_damages, &dead_entities);

    it = entity_damages.iterator();
    while (it.next()) |entry| {
        print(
            "entity damages entry after update = k {}, v {any}\n",
            .{ entry.key_ptr.*, entry.value_ptr.* },
        );
    }

    print("dead entities = {any}\n", .{dead_entities.items});
}
