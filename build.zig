const std = @import("std");
const config = @import("src/config.zig");

/// Adds a NASM file to the build and returns the path to the compiled object file
fn addNasmFile(b: *std.Build, kernel: *std.Build.Step.Compile, source_path: []const u8, name: []const u8) void {
    const output_path = b.fmt("zig-out/bin/{s}.o", .{name});

    const nasm_command = b.addSystemCommand(&[_][]const u8{
        "nasm",
        "-f",
        "elf32",
        "-D",
        b.fmt("STACK_SIZE={d}", .{config.stack_size}),
        "-o",
        output_path,
        source_path,
    });

    kernel.addObjectFile(b.path(output_path));
    kernel.step.dependOn(&nasm_command.step);
}

pub fn build(b: *std.Build) void {
    const wf = b.addWriteFiles();
    var disabled_features = std.Target.Cpu.Feature.Set.empty;
    var enabled_features = std.Target.Cpu.Feature.Set.empty;

    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
    enabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));

    const target_query = std.Target.Query{
        .cpu_arch = std.Target.Cpu.Arch.x86,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
        .cpu_features_sub = disabled_features,
        .cpu_features_add = enabled_features,
    };

    const optimize = b.standardOptimizeOption(.{});
    const default_step = b.getInstallStep();

    const root_file = "src/main.zig";
    const linker_script = "src/linker.ld";
    const out_iso = "zig-out/kernel.iso";

    // Create kernel executable
    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = b.path(root_file),
        .target = b.resolveTargetQuery(target_query),
        .optimize = optimize,
        .code_model = .kernel,
    });

    const assembly_files = [_]struct { []const u8, []const u8 }{
        .{ "src/entry.asm", "entry" },
        .{ "src/kernel/console.asm", "console" },
        .{ "src/kernel/idt.asm", "idt" },
    };

    for (assembly_files) |pair|
        addNasmFile(b, kernel, pair[0], pair[1]);

    kernel.setLinkerScript(b.path(linker_script));
    b.installArtifact(kernel);

    // creating a temp system folder, placing all neccesities there
    _ = wf.addCopyFile(kernel.getEmittedBin(), "tmpsys/kernel/boot/kernel.elf");

    // Copy Limine configuration to bootloader location
    _ = wf.addCopyFile(b.path("src/bootloader/limine.cfg"), "tmpsys/kernel/boot/limine.cfg");

    // taking the temp system directory and copying into the global system dir its contents
    const copy_built_system = b.addInstallDirectory(.{
        .source_dir = wf.getDirectory().path(b, "tmpsys/kernel"),
        .install_dir = .{ .custom = "sysroot/kernel" },
        .install_subdir = "",
    });
    copy_built_system.step.dependOn(&kernel.step);

    // Copy Limine boot files to sysroot
    // limine.sys must be in root, /boot, /limine, or /boot/limine directories
    const copy_limine_boot = b.addSystemCommand(&[_][]const u8{ "bash", "-c", "mkdir -p zig-out/sysroot/kernel/boot/limine && cp /usr/share/limine/limine-cd.bin /usr/share/limine/limine-cd-efi.bin /usr/share/limine/BOOTX64.EFI zig-out/sysroot/kernel/boot/ && cp /usr/share/limine/limine.sys zig-out/sysroot/kernel/boot/limine/" });
    copy_limine_boot.step.dependOn(&copy_built_system.step);

    // Create ISO using xorriso with Limine boot options
    const makeiso = b.addSystemCommand(&[_][]const u8{
        "xorriso",
        "-as",
        "mkisofs",
        "-b",
        "boot/limine-cd.bin",
        "-no-emul-boot",
        "-boot-load-size",
        "4",
        "-boot-info-table",
        "--efi-boot",
        "boot/BOOTX64.EFI",
        "-efi-boot-part",
        "--efi-boot-image",
        "--protective-msdos-label",
        "zig-out/sysroot/kernel",
        "-o",
        out_iso,
    });
    makeiso.step.dependOn(&copy_limine_boot.step);

    // Install Limine bootloader files into the ISO (must run after ISO is created)
    // This will add the bootloader and make the ISO bootable
    const install_limine = b.addSystemCommand(&[_][]const u8{
        "limine-deploy",
        out_iso,
    });
    install_limine.step.dependOn(&makeiso.step);

    const compile_steps = [_]*std.Build.Step{ &kernel.step, &copy_built_system.step, &makeiso.step, &install_limine.step };
    for (compile_steps) |step| {
        default_step.dependOn(step);
    }

    {
        const run_qemu = b.addSystemCommand(&[_][]const u8{ "qemu-system-i386", "-cdrom", out_iso, "-serial", "stdio" });
        const qemu_step = b.step("run", "compile & launch qemu");

        qemu_step.dependOn(default_step);
        for (compile_steps) |step| {
            run_qemu.step.dependOn(step);
        }
        qemu_step.dependOn(&run_qemu.step);
    }

    {
        const run_qemu = b.addSystemCommand(&[_][]const u8{ "qemu-system-i386", "-cdrom", out_iso, "-s", "-S", "-serial", "stdio" });
        const qemu_step = b.step("debug", "compile & launch qemu with a debugger");

        qemu_step.dependOn(default_step);
        for (compile_steps) |step| {
            run_qemu.step.dependOn(step);
        }
        qemu_step.dependOn(&run_qemu.step);
    }
}
