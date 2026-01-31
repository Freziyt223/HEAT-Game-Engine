const std = @import("std");
const User = @import("User");
const State = @import("State");
const ztracy = @import("ztracy");

// To optimize runtime we do checks in runtime and for while loop we select 
// while loop that has only declarated fields so it doesn't need to check
// for existance of the same value each time
pub fn main() !void {
    ztracy.SetThreadName("Main");
    // conf will run before any other code
    const ConfZone = ztracy.ZoneN(@src(), "Conf");
    if (@hasDecl(User, "conf")) User.conf();
    ConfZone.End();

    const InitZone = ztracy.ZoneN(@src(), "Init");
    if (@hasDecl(User, "init")) try User.init();
    InitZone.End();
    defer if (@hasDecl(User, "deinit")) User.deinit();

    var timer = try std.time.Timer.start();
    var last_time = timer.read();
    var tick_clock: u64 = 0;
    var frame_clock: u64 = 0;

    switch (@hasDecl(User, "update")) {
        true => switch (@hasDecl(User, "draw")) {
            true => while (State.Running) {
                const current_time = timer.read();
                const time_passed = current_time - last_time;
                tick_clock += time_passed;
                frame_clock += time_passed;
                last_time = current_time;
                if (tick_clock >= std.time.ns_per_s/State.tick_speed) {
                    const Zone = ztracy.ZoneN(@src(), "Tick");
                    try User.update();
                    tick_clock = 0;
                    Zone.End();
                }
                if (frame_clock >= std.time.ns_per_s/State.frame_speed) {
                    const Zone = ztracy.ZoneN(@src(), "Frame");
                    try User.draw();
                    frame_clock = 0;
                    Zone.End();
                }
            },
            false => while (State.Running) {
                const current_time = timer.read();
                const time_passed = current_time - last_time;
                tick_clock += time_passed;
                last_time = current_time;

                if (tick_clock >= std.time.ns_per_s/State.tick_speed) {
                    const Zone = ztracy.ZoneN(@src(), "Tick");
                    try User.update();
                    tick_clock = 0;
                    Zone.End();
                }
            }
        },
        false => switch (@hasDecl(User, "draw")) {
            true => while (State.Running) {
                const current_time = timer.read();
                const time_passed = current_time - last_time;
                frame_clock += time_passed;
                last_time = current_time;

                if (frame_clock >= std.time.ns_per_s/State.tick_speed) {
                    const Zone = ztracy.ZoneN(@src(), "Frame");
                    try User.draw();
                    frame_clock = 0;
                    Zone.End();
                }
            },
            false => {}
        }
    }
}