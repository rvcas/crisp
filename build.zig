const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("crisp", "src/main.zig");

    exe.setBuildMode(mode);

    exe.addPackage(.{
        .name = "zig-terminal",
        .path = "deps/zig-terminal/src/main.zig",
    });

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
