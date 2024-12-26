// page 68
const std = @import("std");
const print = std.debug.print;

const MAX_HEALTH = 100;
const TIME_BEFORE_REGENERATING_MS = 5_000;
const AMOUNT_TO_HEAL = 3;

const Entity = struct {
    id: i32,
    // information about the entity position
    // ...
    // now health data in the middle of the entity
    time_of_last_damage: ?i64,
    health: f32,
    // ..
    // other entity information
};

fn updateHealth(entity: *Entity) void {
    const now = std.time.milliTimestamp();
    const time_since_last_shot = now - (entity.time_of_last_damage orelse 0);
    const is_hurt = entity.health < MAX_HEALTH;
    const is_dead = entity.health <= 0;
    const regen_can_start = time_since_last_shot > TIME_BEFORE_REGENERATING_MS;
    // if alive, and hurt, and it's been long enough
    if (!is_dead and is_hurt and regen_can_start) {
        entity.health = @min(MAX_HEALTH, entity.health + AMOUNT_TO_HEAL);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    var entities = std.ArrayList(*Entity).init(allocator);
    defer entities.deinit();

    var player = Entity{
        .id = 1,
        .time_of_last_damage = null,
        .health = 100,
    };
    var enemy_1 = Entity{
        .id = 2,
        .time_of_last_damage = std.time.milliTimestamp() - 10_000,
        .health = 87,
    };
    var enemy_2 = Entity{
        .id = 3,
        .time_of_last_damage = std.time.milliTimestamp() - 8_000,
        .health = 0,
    };

    try entities.appendSlice(&[_]*Entity{ &player, &enemy_1, &enemy_2 });
    print("entities = {any}\n", .{entities.items});
    for (entities.items) |entity| {
        updateHealth(entity);
    }
    print("entities = {any}\n", .{entities.items});
}
