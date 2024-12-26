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

fn addClosedDoor(g_doors: *DoorVector, door: Door) !void {
    try g_doors.append(door);
}

fn addOpenDoor(g_doors: *DoorVector, door: Door, first_closed_door: *usize) !void {
    try g_doors.insert(first_closed_door.*, door);
    first_closed_door.* += 1;
}

pub fn main() !void {
    const door_1 = Door{ .first = 1, .second = 1 };
    const door_2 = Door{ .first = 2, .second = 2 };
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    var g_doors: DoorVector = DoorVector.init(allocator);
    defer g_doors.deinit();

    var first_closed_door: usize = 0;

    try addClosedDoor(&g_doors, door_1);
    try addOpenDoor(&g_doors, door_2, &first_closed_door);
    try addClosedDoor(&g_doors, door_1);

    try addOpenDoor(&g_doors, door_2, &first_closed_door);
    try addClosedDoor(&g_doors, door_1);
    try addOpenDoor(&g_doors, door_2, &first_closed_door);

    std.debug.print("g_doors = {any}\n", .{g_doors.items});
    std.debug.print("first_closed_door = {}\n", .{first_closed_door});
}
