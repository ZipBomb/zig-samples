const std = @import("std");
const math = std.math;
const print = std.debug.print;
const zigg = std.Random.ziggurat;

// Experiment parameters
const N_SAMPLES = 1_000_000;

// Based off Extrema type from zig-plotille
// https://github.com/tammoippen/zig-plotille/blob/master/src/hist.zig
const Statistics = struct {
    min: f64,
    max: f64,
    mean: f64,
    stdev: f64,

    fn of(values: []const f64) Statistics {
        var xmin: f64 = undefined;
        var xmax: f64 = undefined;
        var xsum: f64 = 0;
        var xsum2: f64 = 0;

        if (values.len == 0) {
            xmin = 0;
            xmax = 1;
        } else {
            xmin = values[0];
            xmax = values[0];
            for (values) |value| {
                if (value < xmin) {
                    xmin = value;
                }
                if (value > xmax) {
                    xmax = value;
                }
                xsum += value;
                xsum2 += math.pow(f64, value, 2);
            }
        }
        if (math.approxEqRel(f64, xmin, xmax, math.floatEps(f64))) {
            xmin -= 0.5;
            xmax += 0.5;
        }

        const flength = @as(f64, @floatFromInt(values.len));
        const mean = xsum / flength;
        const mean2 = xsum2 / flength;
        const stdev = math.pow(f64, mean2 - math.pow(f64, mean, 2), 0.5);
        return Statistics{
            .min = xmin,
            .max = xmax,
            .mean = mean,
            .stdev = stdev,
        };
    }
};

fn normalized(values: []f64, xmin: f64, xmax: f64) [N_SAMPLES]f64 {
    var result: [N_SAMPLES]f64 = undefined;
    const range = xmax - xmin;
    for (values, 0..) |point, i| {
        result[i] = (point - xmin) / range;
    }
    return result;
}

pub fn main() !void {
    const dist_table = zigg.NormDist;
    const seed: u64 = undefined;
    var rand_gen = std.Random.DefaultPrng.init(seed);
    const random_instance = rand_gen.random();

    var data: [N_SAMPLES]f64 = undefined;

    var timer = try std.time.Timer.start();
    for (&data) |*point| {
        const x = zigg.next_f64(random_instance, dist_table);
        point.* = x;
    }
    print("{d} ms spent on initialization\n", .{timer.lap() / @as(u64, 1e6)});

    const hist = Statistics.of(&data);
    print("{d} ms spent on hist\n", .{timer.lap() / @as(u64, 1e6)});
   
    const norm_data = normalized(&data, hist.min, hist.max); 
    print("{d} ms spent normalizing\n", .{timer.lap() / @as(u64, 1e6)});
    
    const norm_hist = Statistics.of(&norm_data);
    print("{d} ms spent on normalized hist\n", .{timer.lap() / @as(u64, 1e6)});
    
    print("{d:.3} {d:.3} {d:.3} {d:.3}\n", .{
        hist.max,
        hist.min,
        hist.mean,
        hist.stdev,    
    });
    
    print("{d:.3} {d:.3} {d:.3} {d:.3}\n", .{
        norm_hist.max,
        norm_hist.min,
        norm_hist.mean,
        norm_hist.stdev,    
    });
}
