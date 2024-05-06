const std = @import("std");
const net = std.net;

pub fn handleConnection(conn: net.Server.Connection, stdout: std.fs.File.Writer) !void {
    defer conn.stream.close();

    var buf: [300]u8 = undefined;

    const bytes = try conn.stream.read(&buf);
    try stdout.print("[INFO] Received {d} bytes from client - {s}\n", .{ bytes, buf[0..bytes] });

    _ = try conn.stream.write(
        \\HTTP/1.1 200 OK
        \\Content-Type: text/html; charset=UTF-8
        \\Content-Length: 2000
        \\
        \\<!DOCTYPE html>
        \\<html>
        \\    <head>
        \\        <title>Web server</title>
        \\    </head>
        \\    <body>
        \\        <h1>My Zig web server</h1>
        \\        <p>hello world!</p>
        \\    </body>
        \\</html>
    );
    // _ = try conn.stream.write("Hello from server!");
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const address = try net.Address.resolveIp("0.0.0.0", 3000);
    var server = try address.listen(.{
        .reuse_port = true,
        .reuse_address = true,
    });
    defer server.deinit();

    try stdout.print("[INFO] Server listening on {}\n", .{server.listen_address});

    while (true) {
        const conn = try server.accept();
        errdefer conn.stream.close(); // If the thread fails to be created

        _ = try std.Thread.spawn(.{}, handleConnection, .{ conn, stdout });
    }
}
