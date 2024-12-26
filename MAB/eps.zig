const std = @import("std");
const math = std.math;

pub const std_options: std.Options = .{
    // Set the log level to info
    .log_level = .info,

    // Define logFn to override the std implementation
    .logFn = logFormatter,
};

pub fn logFormatter(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = scope;
    const prefix = "[" ++ comptime level.asText() ++ "] ";

    // Print the message to stderr, silently ignoring any errors
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
}

// Experiment parameters
const N_SAMPLES = 100_000;
const N_ARMS = 5;
const MEANS = [5]f32{ 0.1, 0.1, 0.1, 0.1, 0.9 };

const Randomizer = struct {
    prng: std.Random.DefaultPrng = undefined,

    fn initRandomizer(self: *Randomizer) !void {
        self.prng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
    }
};
var RANDOMIZER: Randomizer = .{};

const EpsilonGreedy = struct {
    epsilon: f32 = 0.3,
    counts: [N_ARMS]i32 = [_]i32{0} ** N_ARMS,
    values: [N_ARMS]f32 = [_]f32{0.0} ** N_ARMS,

    fn setToZero(comptime T: type, values: *[N_ARMS]T) void {
        for (values) |*pt| {
            pt.* = 0;
        }
    }

    fn reset(self: *EpsilonGreedy) void {
        setToZero(i32, &self.counts);
        setToZero(f32, &self.values);
    }

    fn selectArm(self: *EpsilonGreedy) usize {
        const flip = RANDOMIZER.prng.random().float(f32);
        std.log.debug("FLIP WHEN SELECTING ARM: {:.6}", .{flip});
        if (flip > self.epsilon) {
            return std.sort.argMax(
                f32,
                &self.values,
                {},
                std.sort.asc(f32),
            ) orelse 42; // Only when self.values.len == 0
        } else {
            return RANDOMIZER.prng.random().uintLessThan(
                usize,
                self.values.len,
            );
        }
    }

    fn update(self: *EpsilonGreedy, chosen_arm: usize, reward: f32) void {
        self.counts[chosen_arm] = self.counts[chosen_arm] + 1;
        const n = self.counts[chosen_arm];

        const value = self.values[chosen_arm];
        const new_value = (@as(f32, @floatFromInt(n - 1)) / @as(f32, @floatFromInt(n))) * value + (@as(f32, @floatFromInt(1)) / @as(f32, @floatFromInt(n))) * reward;
        self.values[chosen_arm] = new_value;
    }
};

const BernouilliArm = struct {
    p: f32,

    fn draw(self: *BernouilliArm) f32 {
        const flip = RANDOMIZER.prng.random().float(f32);
        std.log.debug("DRAWING WITH FLIP {d:.6} AND P {d:.6}", .{
            flip,
            self.p,
        });
        if (flip > self.p) {
            return 0.0;
        } else {
            return 1.0;
        }
    }
};

pub fn main() !void {
    // Init random RNG
    try RANDOMIZER.initRandomizer();

    // Copy the means array and shuffle it
    var means = MEANS;
    RANDOMIZER.prng.random().shuffle(f32, &means);
    std.log.info("MEANS: {any}", .{means});

    // Initialize arms according to the given means array
    var arms: [N_ARMS]BernouilliArm = undefined;
    for (&arms, 0..) |*arm, i| {
        arm.* = BernouilliArm{ .p = means[i] };
    }
    std.log.info("ARMS: {any}", .{arms});

    // Simulate the eps-greedy algorithm
    var eg: EpsilonGreedy = .{};
    for (0..N_SAMPLES) |_| {
        const chosen_arm = eg.selectArm();
        const reward = arms[chosen_arm].draw();
        std.log.debug("CHOSEN ARM: {d:.6}, REWARD: {d:.6}", .{ chosen_arm, reward });
        eg.update(chosen_arm, reward);
        std.log.debug("AFTER UPDATE: {any}", .{eg.values});
    }

    std.log.info("{d:.6} {any} {any}", .{
        eg.epsilon,
        eg.counts,
        eg.values,
    });

    const best_arm = std.sort.argMax(
        f32,
        &eg.values,
        {},
        std.sort.asc(f32),
    ) orelse 42;
    const confidence = eg.values[best_arm];
    std.log.info("BEST ARM: {d:.1} with confidence {d:.3}", .{
        best_arm,
        confidence,
    });
}
