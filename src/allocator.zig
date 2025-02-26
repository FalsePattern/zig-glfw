const std = @import("std");
const c = @import("c.zig").c;

const alignment = @alignOf(std.c.max_align_t);
const prefix_size = blk: {
    var n = alignment;
    while (n < @sizeOf(usize)) {
        n += alignment;
    }
    break :blk n;
};


fn rawFromZig(buf: []align(alignment)u8, size: usize) [*]u8 {
    const pfx = @as(*usize, @ptrCast(@alignCast(buf)));
    pfx.* = size;
    return @ptrCast(buf[prefix_size..]);
}

fn zigFromRaw(memory: [*]u8) []align(alignment)u8 {
    const ptr: [*]align(alignment)u8 = @alignCast(memory - prefix_size);
    const pfx = @as(*usize, @ptrCast(ptr));
    const content_size: usize = pfx.*;
    const full_size: usize = content_size + prefix_size;
    return ptr[0..full_size];
}

fn alloc(
    size: usize,
    user: ?*anyopaque,
) callconv(.C) ?*anyopaque {
    if (user == null)
        unreachable;
    const allocator = @as(*const std.mem.Allocator, @ptrCast(@alignCast(user.?))).*;
    return @ptrCast(doAlloc(allocator, size));
}

fn doAlloc(
    allocator: std.mem.Allocator,
    size: usize,
) ?[*]u8 {
    const buf = allocator.allocAdvancedWithRetAddr(u8, alignment, size + prefix_size, @returnAddress()) catch return null;
    return rawFromZig(buf, size);
}

fn realloc(
    p_block: ?*anyopaque,
    size: usize,
    user: ?*anyopaque,
) callconv(.C) ?*anyopaque {
    if (user == null)
        unreachable;
    const allocator = @as(*const std.mem.Allocator, @ptrCast(@alignCast(user.?))).*;
    if (p_block) |block| {
        return @ptrCast(doRealloc(
            allocator,
            @ptrCast(block),
            size,
        ));
    } else {
        return @ptrCast(doAlloc(
            allocator,
            size,
        ));
    }
}

fn doRealloc(
    allocator: std.mem.Allocator,
    block: [*]u8,
    size: usize,
) ?[*]u8 {
    const old_buf = zigFromRaw(block);
    const new_buf = allocator.reallocAdvanced(old_buf, size + prefix_size, @returnAddress()) catch return null;
    return rawFromZig(new_buf, size);
}

fn free(
    p_block: ?*anyopaque,
    user: ?*anyopaque,
) callconv(.C) void {
    if (user == null)
        unreachable;
    const allocator = @as(*const std.mem.Allocator, @ptrCast(@alignCast(user.?))).*;
    if (p_block) |block| {
        doFree(allocator, @ptrCast(block));
    }
}

fn doFree(
    allocator: std.mem.Allocator,
    block: [*]u8,
) void {
    const buf = zigFromRaw(block);
    allocator.free(buf);
}

/// Sets the allocator to the desired value.
/// To use the default allocator, call this function with a `null` argument.
///
/// @param zig_allocator The allocator to use at the next initialization, or
/// `null` to use the default one.
///
/// Possible errors include glfw.ErrorCode.InvalidValue.
///
/// The provided allocator pointer must stay valid until glfw is deinitialized,
/// or initAllocator is called with a new pointer while glfw is not initialized.
///
/// @thread_safety This function must only be called from the main thread.
pub inline fn initAllocator(allocator: ?*const std.mem.Allocator) void {
    if (allocator) |zig_allocator| {
        c.glfwInitAllocator(&.{
            .allocate = alloc,
            .reallocate = realloc,
            .deallocate = free,
            .user = @ptrCast(@constCast(zig_allocator)),
        });
    } else {
        c.glfwInitAllocator(null);
    }
}