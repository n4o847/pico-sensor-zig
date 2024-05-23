const std = @import("std");

pub fn build(b: *std.Build) !void {
    const cmake_generate_run = b.addSystemCommand(&.{ "cmake", "-S", ".", "-B", "build", "-DPICO_BOARD=pico_w" });

    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .thumb,
            .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
            .os_tag = .freestanding,
            .abi = .eabi,
        },
    });

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const obj = b.addObject(.{
        .name = "pico_sensor",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    obj.addSystemIncludePath(.{ .cwd_relative = "/usr/lib/arm-none-eabi/include" });
    {
        const dir = try std.fs.cwd().openDir("pico-sdk/src", .{ .iterate = true });
        var walker = try dir.walk(b.allocator);
        defer walker.deinit();
        while (try walker.next()) |entry| {
            if (std.mem.startsWith(u8, entry.path, "host/")) {
                continue;
            }
            if (std.mem.eql(u8, entry.basename, "include")) {
                const include_path = try std.fmt.allocPrint(b.allocator, "pico-sdk/src/{s}", .{entry.path});
                obj.addIncludePath(b.path(include_path));
            }
        }
    }
    obj.addIncludePath(b.path("pico-sdk/lib/cyw43-driver/src"));
    obj.addIncludePath(b.path("pico-sdk/lib/lwip/src/include"));
    obj.addIncludePath(b.path("build/generated/pico_base"));
    obj.addIncludePath(b.path("include"));

    obj.root_module.addCMacro("PICO_CYW43_ARCH_THREADSAFE_BACKGROUND", "1");

    obj.linkLibC();

    obj.step.dependOn(&cmake_generate_run.step);

    const install_file = b.addInstallFile(obj.getEmittedBin(), "pico_sensor.o");

    const cmake_build_run = b.addSystemCommand(&.{ "cmake", "--build", "build" });

    cmake_build_run.step.dependOn(&install_file.step);

    b.default_step.dependOn(&cmake_build_run.step);
}
