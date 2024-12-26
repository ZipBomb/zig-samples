// page 50
const std = @import("std");

fn Pair(comptime T: type, comptime U: type) type {
    return struct {
        first: T,
        second: U,
    };
}

const Door = Pair(u32, u32);

const DoorVector = std.ArrayList(Door);

fn addDoor(g_doors: *DoorVector, door: Door) !void {
    try g_doors.append(door);
}

pub fn main() !void {
    const door_1 = Door{ .first = 1, .second = 1 };
    const door_2 = Door{ .first = 2, .second = 2 };
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    var g_open_doors: DoorVector = DoorVector.init(allocator);
    defer g_open_doors.deinit();

    var g_closed_doors: DoorVector = DoorVector.init(allocator);
    defer g_closed_doors.deinit();

    try addDoor(&g_open_doors, door_1);
    try addDoor(&g_closed_doors, door_2);
    try addDoor(&g_open_doors, door_1);

    try addDoor(&g_closed_doors, door_2);
    try addDoor(&g_open_doors, door_1);
    try addDoor(&g_closed_doors, door_2);

    std.debug.print("open = {any}\n", .{g_open_doors.items});
    std.debug.print("closed = {any}\n", .{g_closed_doors.items});
}
